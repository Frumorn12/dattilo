-- I posti sbagliati (progetto, 3.4; compito 5), nel Neovim figlio coi tasti veri. Da Batti con
-- `func` scritto, per ogni posto: ci si entra coi tasti veri, il riquadro ha il titolo e la frase
-- del posto col bordo rosso, e seguendo la frase (il primo tasto, poi quello che dice dopo) si
-- torna dove si era, col testo intatto e il riquadro com'era.
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local TT = require('dattilo.guida_testi')

local function con(o, fn)
  o = vim.tbl_extend('keep', o or {}, { vivo = true })
  o.cartella = o.cartella or M.cartella()
  M.con(o, fn)
end

-- Batti della prima lezione, con `func` scritto e il modo `modo` ('i' o 'n').
local function in_batti(F, modo)
  F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
  F:input('<CR>')
  uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
  F:input('ifunc')
  if modo == 'n' then F:input('<Esc>') end
  uguale(F:righe(), { 'func' })
end

local function atteso(nome, ...)
  local titolo, testo = TT.posto(nome, ...)
  return { titolo = titolo, testo = testo }
end

-- Nessun errore della guida: né in «Controllo» né nel disegno.
local function senza_errori(F, cosa)
  local r = F:riquadro()
  vero(not (r.sezioni.Controllo or ''):find('Errore di dattilo', 1, true), (cosa or '') .. ': ' .. tostring(r.sezioni.Controllo))
  uguale(F:lua('return require("dattilo.guida").errore_disegno()'), vim.NIL, cosa)
end

-- Il riquadro dice il posto: titolo, «Adesso», bordo rosso, e la guida non ha sbagliato niente.
local function nel_posto(F, p, cosa)
  local r
  F:aspetta(function() r = F:riquadro() return r.titolo == p.titolo and r.sezioni.Adesso == p.testo end)
  uguale({ r.titolo, r.sezioni.Adesso }, { p.titolo, p.testo }, cosa)
  uguale(r.tipo, 'rosso', cosa)
  senza_errori(F, cosa)
end

local function fuori(F) return F:riquadro().tipo ~= 'rosso' end

-- Una riga della tabella: si entra con `entra`, il riquadro dice `p`; poi si segue la guida (o si
-- premono i tasti `esci`) finché il riquadro non è più rosso; alla fine il modo è `modo_dopo`, le
-- righe sono quelle di prima e il riquadro non è rosso.
local function riga(o)
  return function()
    con({}, function(F)
      in_batti(F, o.da or 'i')
      local prima = F:righe()
      F:input(o.entra)
      nel_posto(F, o.posto, 'entrando')
      local visti
      if o.esci then
        for _, k in ipairs(o.esci) do F:input(k) end
      else
        visti = F:segui(function() return fuori(F) end, o.passi or 4)
      end
      F:aspetta(function() return fuori(F) end)
      uguale(F:modo(), o.modo_dopo, vim.inspect(visti))
      uguale(F:righe(), prima)
      vero(fuori(F), vim.inspect(F:riquadro()))
      senza_errori(F, 'uscendo')
      if o.dopo then o.dopo(F, visti) end
    end)
  end
end

local function finestre(F) return #F:lua('return vim.api.nvim_tabpage_list_wins(0)') end

---------------------------------------------------------------- la tabella del compito

T['visuale'] = riga({ entra = '<Esc>v', posto = atteso('visuale'), modo_dopo = 'n' })

T['riga dei comandi vuota'] = riga({ entra = '<Esc>:', posto = atteso('cmd_vuota'), modo_dopo = 'n' })

T['riga dei comandi con w'] = function()
  con({}, function(F)
    in_batti(F, 'i')
    F:input('<Esc>:w')
    nel_posto(F, { titolo = TT.posti.cmd_vuota.titolo, testo = TT.cmd_w })
    F:premi_primo()
    uguale(F:modo(), 'n')
    uguale(F:righe(), { 'func' })
    local r = F:riquadro()
    vero(r.tipo ~= 'rosso', vim.inspect(r))
    vero(r.sezioni.Controllo and r.sezioni.Controllo:find('^Salvato, ma il testo non è ancora uguale al grigio: mancano'), vim.inspect(r))
  end)
end

-- Il primo tasto di cmd_noto esegue il comando scritto (qui :q lascia la lezione, prova sotto);
-- chi l'ha scritto per sbaglio ha ‹Esc›, il secondo tasto della frase.
T['comando noto'] = riga({ entra = '<Esc>:q', posto = atteso('cmd_noto', 'q', TT.spiega_comando.q_scritto), esci = { '<Esc>' }, modo_dopo = 'n' })

T['comando ignoto'] = riga({ entra = '<Esc>:ls', posto = atteso('cmd_ignoto', 'ls'), modo_dopo = 'n' })

T['ricerca'] = riga({ entra = '<Esc>/', posto = atteso('ricerca'), modo_dopo = 'n' })

T['finestra dei comandi'] = riga({ entra = '<Esc>q:', posto = atteso('cmdwin'), modo_dopo = 'n',
  dopo = function(F, visti)
    -- ‹Ctrl-c› riporta alla riga dei comandi (vuota), che dice ‹Esc›
    uguale(visti, { TT.posti.cmdwin.testo, TT.posti.cmd_vuota.testo })
    uguale(finestre(F), 2) -- una finestra di codice, più il riquadro
    uguale(F:lua('return vim.fn.getcmdwintype()'), '')
  end })

T['registrazione'] = riga({ entra = '<Esc>qa', posto = atteso('registra_n', 'a'), modo_dopo = 'n',
  dopo = function(F) uguale(F:lua('return vim.fn.reg_recording()'), '') end })

T['registrazione scrivendo'] = riga({ entra = '<Esc>qai', posto = atteso('registra_i', 'a'), modo_dopo = 'n',
  dopo = function(F, visti)
    uguale(visti, { TT.posti.registra_i.testo:format('a'), TT.f('posti.registra_n.testo', 'a', 'a') })
    uguale(F:lua('return vim.fn.reg_recording()'), '')
  end })

T['replace'] = riga({ entra = '<Esc>R', posto = atteso('replace'), modo_dopo = 'i' })

T['Ins scrivendo'] = riga({ entra = '<Insert>', posto = atteso('replace'), modo_dopo = 'i' })

T['operatore'] = riga({ entra = '<Esc>d', posto = atteso('operatore', 'd'), modo_dopo = 'n' })

T['Ctrl-o'] = riga({ entra = '<C-o>', posto = atteso('ctrl_o'), modo_dopo = 'i' })

T['frecce'] = riga({ entra = '<Up>', posto = atteso('frecce'), modo_dopo = 'n',
  dopo = function(F)
    F:input('k')
    uguale(F:lua('return vim.api.nvim_win_get_cursor(0)[1]'), 1)
  end })

T['Ex'] = riga({ entra = '<Esc>gQ', posto = atteso('ex'), modo_dopo = 'n' })

T['Ctrl-z'] = function()
  con({}, function(F)
    in_batti(F, 'i')
    local titolo = F:riquadro().titolo
    F:input('<C-z>')
    -- il figlio risponde, si è ancora in scrittura, il titolo non cambia
    uguale(F:modo(), 'i')
    local r = F:riquadro()
    uguale(r.sezioni.Controllo, TT.ctrl_z)
    uguale(r.titolo, titolo)
    vero(r.tipo ~= 'rosso')
    uguale(F:righe(), { 'func' })
    -- anche in NORMAL e in VISUAL non sospende
    F:input('<Esc>')
    F:input('<C-z>')
    uguale(F:modo(), 'n')
    F:input('v<C-z>')
    uguale(F:modo(), 'v')
    uguale(F:lua('return vim.fn.maparg("<C-z>", "n") ~= ""'), true)
  end)
end

-- Con un operatore in attesa, Ctrl-z metteva in pausa dattilo (visto in tmux, da una shell): la
-- mappa annulla l'operatore, il testo non cambia, e la frase va in «Controllo».
T['Ctrl-z con un operatore in attesa'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('d')
    uguale(F:modo(), 'no')
    F:input('<C-z>')
    F:aspetta(function() return F:riquadro().sezioni.Controllo == TT.ctrl_z end)
    uguale(F:modo(), 'n')
    uguale(F:righe(), { 'func' })
    uguale(F:riquadro().sezioni.Controllo, TT.ctrl_z)
    vero(fuori(F), vim.inspect(F:riquadro()))
  end)
end

T['testo cambiato in NORMAL'] = function()
  con({}, function(F)
    in_batti(F, 'i')
    F:input('<Esc>x')
    uguale(F:righe(), { 'fun' })
    local r = F:riquadro()
    uguale(r.sezioni.Adesso, TT.batti_cambiato)
    vero(r.tipo ~= 'rosso')
    F:premi_primo()
    uguale(F:righe(), { 'func' })
    uguale(F:modo(), 'n')
  end)
end

T['un modo che la guida non conosce: la frase di riserva'] = function()
  local guida = require('dattilo.guida')
  local titolo, testo = TT.posto('sconosciuto', 't')
  uguale(guida.posto('t'), { titolo = titolo, testo = testo })
  uguale(guida.posto('n'), nil)
  uguale(guida.posto('i'), nil)
end

---------------------------------------------------------------- oltre la tabella

-- Prima di questo compito in REPLACE «Adesso» diceva ‹A›, che sovrascrive una lettera.
T['in REPLACE la frase non fa scrivere sopra il testo'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('R')
    nel_posto(F, atteso('replace'))
    vero(not F:adesso():find('‹A›', 1, true), F:adesso())
  end)
end

-- Il primo tasto di cmd_noto esegue il comando: :q lascia la lezione e va all'elenco.
T['comando noto: Invio fa quello che la frase dice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_scritto))
    F:premi_primo()
    vero(F:aspetta(function() return F:lua('return require("dattilo.stato").schermo') == 'home' end))
    uguale(F:lua('return require("dattilo.lezione").s'), vim.NIL)
    -- nell'elenco :q chiude dattilo, e la frase lo dice
    F:input(':q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_esci))
    F:input('<Esc>')
  end)
end

-- :salta, :ultima ed :elenco arrivano col compito 8: finché non ci sono, scriverli non promette niente.
T['un comando che non c è ancora non si promette'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    uguale(F:lua('return vim.fn.exists(":DattiloSalta")'), 0)
    F:input(':salta')
    nel_posto(F, atteso('cmd_ignoto', 'salta'))
    F:input('<Esc>')
    -- quando c'è (il compito 8 lo crea e lo scrive in «Comandi»), è un comando noto; a metà, la frase
    -- dice le lettere che mancano
    F:lua([[
      local T = require('dattilo.guida_testi')
      T.comandi_batti = T.comandi_batti .. ' · ‹:salta› ‹Invio›: passi alla prossima'
      vim.api.nvim_create_user_command('DattiloSalta', function() end, {})]])
    F:input(':sa')
    nel_posto(F, atteso('cmd_parziale', 'sa', TT.f('cmd_finisci', '‹l› ‹t› ‹a›', 'salta', TT.spiega_comando.salta)))
    F:premi_primo()
    nel_posto(F, atteso('cmd_noto', 'salta', TT.spiega_comando.salta))
    F:input('<Esc>')
    uguale(F:righe(), { 'func' })
  end)
end

-- :w non salva niente nelle schermate di testo: lì la riga dei comandi vuota non lo propone.
T['riga dei comandi nel briefing: niente :w'] = function()
  con({}, function(F)
    F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
    F:input(':')
    nel_posto(F, atteso('cmd_vuota_testo'))
    F:input('w')
    nel_posto(F, atteso('cmd_ignoto', 'w'))
    F:premi_primo()
    F:aspetta(function() return fuori(F) end)
    uguale(F:riquadro().titolo, TT.f('titoli.briefing', 'somma'))
  end)
end

T['VISUAL anche nel briefing'] = function()
  con({}, function(F)
    F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
    F:input('V')
    nel_posto(F, atteso('visuale'))
    F:premi_primo()
    F:aspetta(function() return fuori(F) end)
    uguale(F:riquadro().titolo, TT.f('titoli.briefing', 'somma'))
    uguale(F:riquadro().sezioni.Adesso, TT.briefing)
  end)
end

-- Trascinare col mouse (mouse=a) apre VISUAL senza che la persona abbia premuto v (3.4, riga 1).
T['trascinare col mouse: VISUAL, e Esc ne esce'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:trascina(1, 0, 3)
    uguale(F:modo(), 'v')
    nel_posto(F, atteso('visuale'))
    F:premi_primo()
    uguale(F:modo(), 'n')
    uguale(F:righe(), { 'func' })
    F:aspetta(function() return fuori(F) end)
    vero(fuori(F), vim.inspect(F:riquadro()))
  end)
end

T['ricerca all indietro'] = riga({ entra = '<Esc>?', posto = atteso('ricerca'), modo_dopo = 'n' })

T['Ctrl-v: selezione a blocchi'] = riga({ entra = '<Esc><C-v>', posto = atteso('visuale'), modo_dopo = 'n' })

T['operatore c'] = riga({ entra = '<Esc>c', posto = atteso('operatore', 'c'), modo_dopo = 'n' })

T['registrazione e VISUAL insieme: prima la selezione, poi la registrazione'] = riga({ entra = '<Esc>qav',
  posto = atteso('visuale'), modo_dopo = 'n',
  dopo = function(F, visti)
    uguale(visti, { TT.posti.visuale.testo, TT.f('posti.registra_n.testo', 'a') })
    uguale(F:lua('return vim.fn.reg_recording()'), '')
  end })

-- Il terminale (3.4, riga 16): la frase di riserva comincia da ‹Ctrl-\› ‹Ctrl-n›, che da un
-- terminale riporta in NORMAL (‹Esc› lì va al programma); lì ‹Ctrl-^› rimette il codice com'era.
-- Seguendo solo il primo tasto si torna in Batti col testo intatto.
T['terminale: seguendo la guida si torna al codice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':terminal<CR>')
    F:input('i')
    uguale(F:modo(), 't')
    nel_posto(F, atteso('sconosciuto', 't'))
    local visti = F:segui(function() return fuori(F) end, 4)
    uguale(visti, { select(2, TT.posto('sconosciuto', 't')), (select(2, TT.posto('terminale', F:lua('return require("dattilo.lezione").s.buf')))) })
    uguale(F:modo(), 'n')
    uguale(F:lua('return vim.api.nvim_get_current_buf() == require("dattilo.lezione").s.buf'), true)
    uguale(F:righe(), { 'func' })
    senza_errori(F, 'uscendo')
  end)
end

-- La finestra in più (3.4, riga 12), col cursore dentro: la frase dice ‹:q› ‹Invio›, che chiude solo
-- quella (compito 6; nel compito 5 era ‹Ctrl-w› ‹c›, perché :q lasciava la lezione). Le prove di
-- :q nella finestra in più sono in test_guida_finestre.lua.
T['aiuto con F1'] = riga({ entra = '<Esc><F1>', posto = atteso('aiuto'), modo_dopo = 'n',
  dopo = function(F)
    uguale(finestre(F), 2)
    uguale(F:lua('return vim.api.nvim_get_current_buf() == require("dattilo.lezione").s.buf'), true)
    uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
  end })

T['aiuto con :help'] = riga({ entra = '<Esc>:help<CR>', posto = atteso('aiuto'), modo_dopo = 'n',
  dopo = function(F) uguale(finestre(F), 2) end })

T['finestra divisa con Ctrl-w s'] = riga({ entra = '<Esc><C-w>s', posto = atteso('divisa'), modo_dopo = 'n',
  dopo = function(F)
    uguale(finestre(F), 2)
    uguale(F:lua('return vim.api.nvim_get_current_win() == require("dattilo.schermo").principale'), true)
  end })

-- Prima di questo compito, nell'aiuto la guida diceva ‹A› (la frase di Batti), che lì dà E21 e
-- lascia nell'aiuto.
T['nell aiuto la frase non è quella di Batti'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<F1>')
    nel_posto(F, atteso('aiuto'))
    vero(not F:adesso():find('‹A›', 1, true), F:adesso())
  end)
end

-- In una schermata di vivo (l'elenco) Ctrl-z scrive la frase in «Controllo».
T['Ctrl-z nell elenco'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':q<CR>')
    vero(F:aspetta(function() return F:lua('return require("dattilo.stato").schermo') == 'home' end))
    local titolo = F:riquadro().titolo
    F:input('<C-z>')
    uguale(F:riquadro().sezioni.Controllo, TT.ctrl_z)
    uguale(F:riquadro().titolo, titolo)
  end)
end

-- Spenta la guida, la mappa di Ctrl-z e gli autocomandi se ne vanno: il dattilo di sempre.
T['spegni toglie Ctrl-z e gli autocomandi'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    uguale(F:lua('return vim.fn.maparg("<C-z>", "i") ~= ""'), true)
    F:lua('require("dattilo.vivo").ferma()')
    uguale(F:lua('return { vim.fn.maparg("<C-z>", "n"), vim.fn.maparg("<C-z>", "i"), vim.fn.maparg("<C-z>", "v"), vim.fn.maparg("<C-z>", "o") }'), { '', '', '', '' })
    uguale(F:lua('return vim.fn.exists("#dattilo_guida")'), 0)
  end)
end

---------------------------------------------------------------- giro di correzione 1 (revisione del compito 5)

local function buf_lezione(F) return F:lua('return require("dattilo.lezione").s.buf') end
local function buf_corrente(F) return F:lua('return vim.api.nvim_get_current_buf()') end
local function righe_lezione(F) return F:lua('local s = require("dattilo.lezione").s return vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)') end

-- Rilievo 1: nella finestra della lezione c'è un altro buffer. Ci si arriva in tanti modi; la
-- guida se ne accorge, il riquadro è rosso, «Comandi» offre solo la strada per tornare, e seguendo
-- la guida si è di nuovo nel codice, col testo intatto.
local function altro_buffer(nome, entra, da)
  T[nome] = function()
    con({}, function(F)
      in_batti(F, 'n')
      F:input(entra)
      local n = buf_lezione(F)
      vero(buf_corrente(F) ~= n, 'non si è arrivati in un altro buffer')
      nel_posto(F, atteso('altro_buffer', n), nome)
      uguale(F:riquadro().sezioni.Comandi, TT.f('comandi_altro', n))
      local visti = F:segui(function() return fuori(F) end, 4)
      uguale(buf_corrente(F), n, vim.inspect(visti))
      uguale(righe_lezione(F), { 'func' })
      uguale(F:modo(), 'n')
      senza_errori(F, 'uscendo')
      -- dopo il ritorno si continua a scrivere sul codice
      F:input('A')
      uguale(F:adesso(), TT.batti_scrivi)
      vero(F:riquadro().tipo ~= 'rosso', vim.inspect(F:riquadro()))
    end)
  end
end

altro_buffer('un altro buffer con Ctrl-^', '<C-^>')
altro_buffer('un altro buffer con :enew', ':enew<CR>')
altro_buffer('un altro buffer con :bn', ':bn<CR>')
altro_buffer('un altro buffer con :e di un file', ':e altro.txt<CR>')
altro_buffer('un altro buffer con Ctrl-o (il salto torna al briefing)', '<C-o>')

-- Anche fuori da Batti il buffer giusto è quello della schermata (briefing, elenco).
T['un altro buffer anche nel briefing e nell elenco: la guida riporta al testo'] = function()
  con({}, function(F)
    F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
    local n = F:lua('return require("dattilo.schermo").mostrato')
    F:input(':enew<CR>')
    nel_posto(F, atteso('altro_buffer', n))
    F:segui(function() return fuori(F) end, 3)
    uguale(buf_corrente(F), n)
    uguale(F:adesso(), TT.briefing)
    -- nell'elenco
    F:input('q')
    vero(F:aspetta(function() return F:lua('return require("dattilo.stato").schermo') == 'home' end))
    n = F:lua('return require("dattilo.schermo").mostrato')
    F:input(':enew<CR>')
    nel_posto(F, atteso('altro_buffer', n))
    F:segui(function() return fuori(F) end, 3)
    uguale(buf_corrente(F), n)
    uguale(F:adesso(), TT.elenco)
  end)
end

-- Nel briefing rimasto indietro ‹Invio›, ‹l› e ‹q› non devono rifare Batti né lasciare la lezione: perderebbero il testo.
T['il briefing rimasto indietro non ricomincia Batti: il testo resta'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-o>')
    uguale(F:lua('return vim.api.nvim_buf_get_name(0)'), 'dattilo://briefing')
    nel_posto(F, atteso('altro_buffer', buf_lezione(F)))
    F:input('<CR>')
    F:input('l')
    F:input('q') -- anche ‹q› (torna alla home) non porta via il testo
    uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
    uguale(F:lua('return require("dattilo.stato").schermo'), 'lezione')
    uguale(righe_lezione(F), { 'func' })
    F:segui(function() return fuori(F) end, 4)
    uguale(F:righe(), { 'func' })
  end)
end

-- Scrivendo in un altro buffer ‹Esc› viene prima (in INSERT ‹:› è una lettera).
T['scrivendo in un altro buffer: prima Esc, poi il comando che riporta al codice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-^>i')
    uguale(F:modo(), 'i')
    local n = buf_lezione(F)
    nel_posto(F, atteso('altro_buffer_i', n))
    local visti = F:segui(function() return fuori(F) end, 4)
    uguale(visti, { select(2, TT.posto('altro_buffer_i', n)), select(2, TT.posto('altro_buffer', n)) })
    uguale(buf_corrente(F), n)
    uguale(righe_lezione(F), { 'func' })
  end)
end

-- Nel riquadro, «Comandi» in un altro buffer non offre ‹:w›, che lì scriverebbe sul file sbagliato.
T['in un altro buffer la riga dei comandi riconosce quello che la frase dice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-^>')
    local n = buf_lezione(F)
    local nome = 'b' .. n
    F:input(':')
    nel_posto(F, atteso('cmd_vuota_testo'))
    F:input('b')
    nel_posto(F, atteso('cmd_parziale', 'b', TT.f('cmd_finisci', '‹' .. tostring(n) .. '›', nome, TT.spiega_comando.b)))
    F:input(tostring(n))
    nel_posto(F, atteso('cmd_noto', nome, TT.spiega_comando.b))
    F:premi_primo()
    uguale(buf_corrente(F), n)
  end)
end

-- Con due terminali ‹Ctrl-^› rimbalzava fra i due: la frase ora porta al codice con :b e il numero.
T['due terminali: la guida riporta al codice, senza rimbalzare'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    local n = buf_lezione(F)
    F:input(':terminal<CR>')
    F:input('<C-\\><C-n>')
    F:input(':terminal<CR>')
    F:input('<C-\\><C-n>')
    uguale(F:modo(), 'nt')
    nel_posto(F, atteso('terminale', n))
    local visti = F:segui(function() return fuori(F) end, 4)
    vero(not table.concat(visti, ' '):find('Ctrl-^', 1, true), vim.inspect(visti))
    uguale(buf_corrente(F), n)
    uguale(righe_lezione(F), { 'func' })
    uguale(F:modo(), 'n')
  end)
end

-- Scrivendo in una finestra in più (‹Ctrl-w› ‹n› poi ‹i›) la frase non è quella di Batti: ‹Esc› viene
-- prima, perché in INSERT ‹Ctrl-w› cancella una parola.
T['scrivendo in una finestra in più: prima Esc, poi si chiude la finestra'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>n')
    nel_posto(F, atteso('divisa'))
    F:input('i')
    uguale(F:modo(), 'i')
    nel_posto(F, atteso('divisa_i'))
    F:segui(function() return fuori(F) end, 4)
    uguale(finestre(F), 2)
    uguale(F:lua('return vim.api.nvim_get_current_win() == require("dattilo.schermo").principale'), true)
    uguale(righe_lezione(F), { 'func' })
  end)
end

-- Rilievo 2: in esegui la frase dice ‹:e!›, e battendolo una lettera alla volta la riga dei comandi
-- lo riconosce (prima diceva «che qui non serve»).
T['in esegui :e! scritto una lettera alla volta è un comando noto'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:lua('local L = require("dattilo.lezione") L.esegui(L.s)')
    F:input('Ax( {<Esc>')
    F:input(':w<CR>')
    uguale(F:adesso(), TT.esegui_cambiato)
    F:input(':')
    F:input('e')
    nel_posto(F, atteso('cmd_parziale', 'e', TT.f('cmd_finisci', '‹!›', 'e!', TT.spiega_comando['e!'])))
    F:input('!')
    nel_posto(F, atteso('cmd_noto', 'e!', TT.spiega_comando['e!']))
    F:premi_primo()
    uguale(F:righe(), F:lua('return require("dattilo.lezione").s.L.batti.codice'))
    F:aspetta(function() return fuori(F) end)
    vero(fuori(F), vim.inspect(F:riquadro()))
  end)
end

-- Rilievo 3: la guida non nomina un comando che non c'è. Ogni ‹:nome› di ogni testo è un comando
-- che esiste adesso (nel figlio, con la guida accesa); :salta, :ultima ed :elenco arrivano col
-- compito 8 e, quando ci sono, la prova passa da sola. ‹:b4› è il comando :b col numero del buffer.
T['ogni comando scritto nei testi della guida esiste'] = function()
  con({}, function(F)
    local trovati = {}
    local function visita(nome, v)
      if type(v) == 'string' then
        for c in v:gmatch('‹:([^›]+)›') do trovati[#trovati + 1] = { nome, c } end
      elseif type(v) == 'table' then
        for k, x in pairs(v) do visita(nome .. '.' .. tostring(k), x) end
      end
    end
    visita('T', TT)
    vero(#trovati > 15, 'pochi comandi trovati: ' .. #trovati)
    local inesistenti = {}
    for _, t in ipairs(trovati) do
      local c = t[2]:gsub('!$', ''):gsub('%%d$', ''):gsub('%d+$', '')
      local esiste = F:lua('return vim.fn.exists(":" .. ...) > 0', c)
      if not esiste then
        local cmd = 'Dattilo' .. c:sub(1, 1):upper() .. c:sub(2)
        esiste = F:lua('return vim.fn.exists(":" .. ...) == 2', cmd)
      end
      if not esiste then inesistenti[#inesistenti + 1] = t[1] .. ' → :' .. t[2] end
    end
    uguale(inesistenti, {})
  end)
end

-- Rilievo 3: nessuna frase promette una bozza che non c'è (arriva col compito 9).
T['nessun testo promette quello che il compito 9 non ha ancora fatto'] = function()
  local vietate = { 'resta salvata', 'è salvato', 'quello che hai scritto resta', 'lo riapre' }
  local male = {}
  local function visita(nome, v)
    if type(v) == 'string' then
      for _, x in ipairs(vietate) do
        if v:find(x, 1, true) then male[#male + 1] = nome .. ': «' .. x .. '»' end
      end
    elseif type(v) == 'table' then
      for k, y in pairs(v) do visita(nome .. '.' .. tostring(k), y) end
    end
  end
  visita('T', TT)
  uguale(male, {})
end

-- Rilievo 3: un controllo che non passa non è un vicolo cieco: la frase propone ‹:q›, che c'è, e
-- seguendola si è nell'elenco.
T['il controllo che non passa: seguendo la guida si esce dalla lezione'] = function()
  con({ cartella = M.cartella('rifallo-rotta') }, function(F)
    F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
    F:input('<CR>')
    local codice = F:lua('return require("dattilo.lezione").s.L.batti.codice')
    F:input('i')
    for i, l in ipairs(codice) do
      F:input((vim.trim(l):gsub('<', '<lt>')))
      if i < #codice then F:input('<CR>') end
    end
    F:input('<Esc>:w<CR>')
    uguale(F:riquadro().titolo, TT.titoli.ko)
    vero(F:adesso():find('‹:q› ‹Invio›', 1, true), F:adesso())
    F:premi_primo()
    vero(F:aspetta(function() return F:lua('return require("dattilo.stato").schermo') == 'home' end))
    uguale(F:lua('return require("dattilo.lezione").s'), vim.NIL)
  end)
end

return T
