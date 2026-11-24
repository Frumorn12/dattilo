-- `:q` e le finestre in più (progetto, G7 e 3.4 righe 3, 12 e 12b; compito 6), nel Neovim figlio coi
-- tasti veri: `:q` chiude il posto dove si è (la finestra in più, la lezione, dattilo), `:qa` chiude
-- dattilo del tutto, e la finestra della lezione chiusa in un altro modo si rimette da sé.
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local TT = require('dattilo.guida_testi')

local function con(o, fn)
  o = vim.tbl_extend('keep', o or {}, { vivo = true })
  o.cartella = o.cartella or M.cartella()
  M.con(o, fn)
end

local function briefing(F)
  F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
end

-- Batti della prima lezione, con `func` scritto e il modo `modo` ('i' o 'n').
local function in_batti(F, modo)
  briefing(F)
  F:input('<CR>')
  uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
  F:input('ifunc')
  if modo ~= 'i' then F:input('<Esc>') end
  uguale(F:righe(), { 'func' })
end

local function atteso(nome, ...)
  local titolo, testo = TT.posto(nome, ...)
  return { titolo = titolo, testo = testo }
end

local function senza_errori(F, cosa)
  local r = F:riquadro()
  vero(not (r.sezioni.Controllo or ''):find('Errore di dattilo', 1, true), (cosa or '') .. ': ' .. tostring(r.sezioni.Controllo))
  uguale(F:lua('return require("dattilo.guida").errore_disegno()'), vim.NIL, cosa)
end

local function nel_posto(F, p, cosa)
  local r
  F:aspetta(function() r = F:riquadro() return r.titolo == p.titolo and r.sezioni.Adesso == p.testo end)
  uguale({ r.titolo, r.sezioni.Adesso }, { p.titolo, p.testo }, cosa)
  uguale(r.tipo, 'rosso', cosa)
  senza_errori(F, cosa)
end

local function fuori(F) return F:riquadro().tipo ~= 'rosso' end
local function finestre(F) return #F:lua('return vim.api.nvim_tabpage_list_wins(0)') end
local function passo(F) return F:lua('return require("dattilo.lezione").s.passo') end
local function righe_lezione(F) return F:lua('local s = require("dattilo.lezione").s return vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)') end
local function in_principale(F) return F:lua('return vim.api.nvim_get_current_win() == require("dattilo.schermo").principale') end
local function schermo(F) return F:lua('return require("dattilo.stato").schermo') end

-- Il figlio esce davvero (codice 0) quando si preme l'ultimo tasto. L'ultimo tasto va con
-- rpcnotify: dopo, il figlio non risponde più a nessuna richiesta.
local function esce(F)
  vim.rpcnotify(F.canale, 'nvim_input', '<CR>')
  return vim.fn.jobwait({ F.canale }, 3000)[1] == 0
end

-- Lo stato di tutte le finestre: tutte vedono lo stesso schermo? Il riquadro e la finestra della
-- lezione, e nient'altro (dopo che la finestra in più si è chiusa).
local function due_finestre(F)
  uguale(finestre(F), 2, vim.inspect(F:lua('return vim.tbl_map(function(w) return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)) end, vim.api.nvim_tabpage_list_wins(0))')))
  vero(F:lua('return require("dattilo.ui").tip_aperto()'), 'il riquadro non c\'è')
end

---------------------------------------------------------------- :q nella finestra in più

-- Review Focus 3: ‹F1› apre l'aiuto, e `:q` prima buttava fuori dalla lezione.
T['F1 e poi :q: si torna in Batti col testo'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<F1>')
    nel_posto(F, atteso('aiuto'))
    F:input(':q<CR>')
    F:aspetta(function() return fuori(F) end)
    uguale(passo(F), 'batti')
    uguale(F:righe(), { 'func' })
    due_finestre(F)
    uguale(in_principale(F), true)
    uguale(schermo(F), 'lezione')
    senza_errori(F, 'dopo :q')
  end)
end

-- Seguendo solo la guida (‹:q› ‹Invio›) dall'aiuto si torna al codice.
T['nell aiuto la guida dice :q, e seguirla riporta al codice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<F1>')
    nel_posto(F, atteso('aiuto'))
    uguale(F:adesso():find('‹:q› ‹Invio›', 1, true) ~= nil, true, F:adesso())
    F:segui(function() return fuori(F) end, 3)
    uguale(passo(F), 'batti')
    uguale(righe_lezione(F), { 'func' })
    due_finestre(F)
  end)
end

T[':q scritto in una finestra in più dice che chiude la finestra, e «Comandi» non offre il resto'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<F1>')
    F:input(':q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_finestra))
    F:input('<Esc>')
    nel_posto(F, atteso('aiuto'))
    -- «Comandi» dice solo come chiudere: ‹:w› nell'aiuto darebbe un errore, ‹q› registrerebbe una macro
    uguale(F:riquadro().sezioni.Comandi, TT.comandi_finestra)
    F:input(':')
    nel_posto(F, atteso('cmd_vuota_testo'))
    F:input('<Esc>')
    F:input('<C-w>c')
    F:aspetta(function() return fuori(F) end)
    uguale(passo(F), 'batti')
  end)
end

T['Ctrl-w s: la frase della finestra in più, e :q la chiude'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>s')
    nel_posto(F, atteso('divisa'))
    uguale(F:riquadro().sezioni.Comandi, TT.comandi_finestra)
    F:input(':q<CR>')
    F:aspetta(function() return fuori(F) end)
    due_finestre(F)
    uguale(in_principale(F), true)
    uguale(passo(F), 'batti')
    uguale(F:righe(), { 'func' })
  end)
end

-- Scrivendo in una finestra in più, ‹Esc› e poi ‹:q› ‹Invio›.
T['scrivendo in una finestra in più: Esc, poi :q'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>ni')
    uguale(F:modo(), 'i')
    nel_posto(F, atteso('divisa_i'))
    local visti = F:segui(function() return fuori(F) end, 4)
    uguale(#visti, 2, vim.inspect(visti))
    due_finestre(F)
    uguale(righe_lezione(F), { 'func' })
  end)
end

-- Anche con un buffer che ha del testo non salvato (un [Senza nome] scritto): la finestra si chiude.
T[':q chiude una finestra in più con del testo scritto dentro'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>nitesto qualunque<Esc>')
    F:input(':q<CR>')
    F:aspetta(function() return fuori(F) end)
    due_finestre(F)
    uguale(passo(F), 'batti')
    uguale(righe_lezione(F), { 'func' })
  end)
end

-- Un terminale in una finestra in più: si chiude come ogni finestra in più.
T[':q chiude un terminale in una finestra in più'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':split<CR>:terminal<CR>')
    uguale(F:modo(), 'nt')
    nel_posto(F, atteso('divisa'))
    F:input(':q<CR>')
    F:aspetta(function() return fuori(F) end)
    due_finestre(F)
    uguale(passo(F), 'batti')
  end)
end

---------------------------------------------------------------- la finestra della lezione, con altre aperte (riga 12b)

T['dalla finestra della lezione: Ctrl-w o'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>s<C-w>p')
    uguale(in_principale(F), true)
    nel_posto(F, atteso('divisa_principale'))
    -- «Comandi» è quello della schermata: la finestra della lezione è la sua
    uguale(F:riquadro().sezioni.Comandi, TT.comandi_batti)
    F:segui(function() return fuori(F) end, 2)
    F:aspetta(function() return finestre(F) == 2 end)
    due_finestre(F)
    uguale(passo(F), 'batti')
    uguale(righe_lezione(F), { 'func' })
    uguale(in_principale(F), true)
  end)
end

-- In INSERT, nella finestra della lezione, la frase è quella di Batti anche con una finestra aperta.
T['nella finestra della lezione scrivendo: la frase è quella di Batti'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>s<C-w>pA')
    uguale(F:modo(), 'i')
    uguale(F:adesso(), TT.batti_scrivi)
    uguale(F:riquadro().tipo ~= 'rosso', true)
  end)
end

-- :w e la riga dei comandi nella finestra della lezione valgono come sempre, con la finestra aperta.
T['nella finestra della lezione con un altra aperta :w è sempre un comando noto'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>s<C-w>p')
    F:input(':')
    nel_posto(F, atteso('cmd_vuota'))
    F:input('<Esc>')
  end)
end

---------------------------------------------------------------- la finestra della lezione chiusa in un altro modo (G7)

T['Ctrl-w c sulla lezione con una divisione aperta: la lezione resta'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>s<C-w>p<C-w>c')
    F:aspetta(function() return passo(F) == 'batti' and finestre(F) == 2 and in_principale(F) end)
    uguale(passo(F), 'batti')
    uguale(schermo(F), 'lezione')
    uguale(righe_lezione(F), { 'func' })
    uguale(F:lua('return vim.api.nvim_win_is_valid(require("dattilo.schermo").principale)'), true)
    -- nella finestra che resta c'è il codice, e il riquadro è tornato
    uguale(F:lua('return vim.api.nvim_get_current_buf() == require("dattilo.lezione").s.buf'), true)
    due_finestre(F)
    F:aspetta(function() return fuori(F) end)
    senza_errori(F, 'dopo Ctrl-w c')
    -- si continua a scrivere sul codice
    F:input('Ation') -- «A» e poi «tion»: func + tion
    uguale(righe_lezione(F), { 'function' })
  end)
end

-- ‹Ctrl-w› ‹o› da una finestra in più chiude la finestra della lezione e il riquadro insieme.
T['Ctrl-w o da una finestra in più: la lezione si rimette in quella che resta'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>s')
    nel_posto(F, atteso('divisa'))
    F:input('<C-w>o')
    F:aspetta(function() return passo(F) == 'batti' and finestre(F) == 2 and in_principale(F) end)
    due_finestre(F)
    uguale(passo(F), 'batti')
    uguale(righe_lezione(F), { 'func' })
    uguale(F:lua('return vim.api.nvim_get_current_buf() == require("dattilo.lezione").s.buf'), true)
    F:aspetta(function() return fuori(F) end)
    senza_errori(F, 'dopo Ctrl-w o')
  end)
end

-- Con l'aiuto aperto, chiudere la finestra della lezione la rimette nella finestra che resta (l'aiuto).
T['Ctrl-w c sulla lezione con l aiuto aperto: il codice prende il posto dell aiuto'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<F1><C-w>p<C-w>c')
    F:aspetta(function() return passo(F) == 'batti' and finestre(F) == 2 and in_principale(F) end)
    due_finestre(F)
    uguale(F:lua('return vim.api.nvim_get_current_buf() == require("dattilo.lezione").s.buf'), true)
    uguale(F:lua('return vim.bo.buftype'), '')
    uguale(righe_lezione(F), { 'func' })
  end)
end

-- Con solo il riquadro accanto, chiudere la finestra della lezione non porta più alla home: la
-- lezione si rimette nella finestra che resta, e il riquadro si rifà.
T['Ctrl-w c sulla lezione senza altre finestre: la lezione resta'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-w>c')
    F:aspetta(function() return passo(F) == 'batti' and finestre(F) == 2 and in_principale(F) end)
    due_finestre(F)
    uguale(schermo(F), 'lezione')
    uguale(righe_lezione(F), { 'func' })
    F:aspetta(function() return fuori(F) end)
    senza_errori(F, 'dopo Ctrl-w c')
    F:input('Ax')
    uguale(righe_lezione(F), { 'funcx' })
  end)
end

-- Anche il briefing (una schermata di testo) torna dov'era.
T['Ctrl-w c sul briefing: il briefing resta'] = function()
  con({}, function(F)
    briefing(F)
    F:input('<C-w>c')
    F:aspetta(function() return finestre(F) == 2 and in_principale(F) end)
    uguale(passo(F), 'briefing')
    due_finestre(F)
    F:aspetta(function() local r = F:riquadro() return r.titolo:find('^COMINCIA') ~= nil end)
    uguale(F:adesso(), TT.briefing)
  end)
end

-- Senza la guida la finestra chiusa porta alla home, come sempre (la prova di oggi in test_lezioni).
-- Nell'elenco la finestra chiusa lo ridisegna.
T['Ctrl-w c nell elenco: l elenco resta'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':q<CR>')
    vero(F:aspetta(function() return schermo(F) == 'home' end))
    F:input('<C-w>c')
    F:aspetta(function() return finestre(F) == 2 and in_principale(F) end)
    due_finestre(F)
    uguale(schermo(F), 'home')
    F:aspetta(function() return F:riquadro().titolo == TT.titoli.elenco end)
    uguale(F:riquadro().titolo, TT.titoli.elenco)
  end)
end

---------------------------------------------------------------- :q lascia la lezione, :qa chiude dattilo

T[':q nella lezione va all elenco; :q nell elenco esce'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':q<CR>')
    vero(F:aspetta(function() return schermo(F) == 'home' end))
    uguale(F:lua('return require("dattilo.lezione").s'), vim.NIL)
    uguale(F:riquadro().titolo, TT.titoli.elenco)
    -- nell'elenco la frase dice che chiude dattilo, e lo fa
    F:input(':q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_esci))
    vero(esce(F), 'il figlio non è uscito')
  end)
end

-- ‹:q› con del testo scritto: la frase lo dice prima dell'Invio. Senza testo, no.
T[':q nella lezione dice cosa succede al testo scritto'] = function()
  con({}, function(F)
    briefing(F)
    F:input('<CR>')
    F:input(':q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q))
    F:input('<Esc>')
    F:input('ifunc<Esc>:q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_scritto))
    F:input('<Esc>')
  end)
end

-- ‹:qa› chiude dattilo del tutto, anche con del testo non salvato (Vim dà E37 e E162 su due righe,
-- e resta un «Premi INVIO»). La frase dice cosa succede prima dell'Invio.
T[':qa chiude dattilo del tutto, anche col testo non salvato'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    uguale(F:lua('return vim.bo.modified'), true)
    F:input(':qa')
    nel_posto(F, atteso('cmd_noto', 'qa', TT.spiega_comando.qa_scritto))
    vero(esce(F), 'il figlio non è uscito: Vim ha dato E37?')
  end)
end

T[':qa dal briefing, senza niente scritto, chiude dattilo'] = function()
  con({}, function(F)
    briefing(F)
    F:input(':qa')
    nel_posto(F, atteso('cmd_noto', 'qa', TT.spiega_comando.qa))
    vero(esce(F), 'il figlio non è uscito')
  end)
end

-- Tutti i modi di scrivere «esci da tutto» che la guida spiega chiudono dattilo. Con `!` Neovim
-- espande `qa` appena si preme il `!`: la riga dei comandi diventa `DattiloEsciTutto!`, e la guida dice `:qa`.
for _, c in ipairs({ { 'qa!', 'qa' }, { 'qall', 'qall' }, { 'quitall', 'quitall' }, { 'wqa', 'wqa' }, { 'xa', 'xa' } }) do
  T[':' .. c[1] .. ' chiude dattilo, con una finestra in più e del testo non salvato'] = function()
    con({}, function(F)
      in_batti(F, 'n')
      F:input('<C-w>nitesto in un altro file<Esc>')
      F:input(':' .. c[1])
      nel_posto(F, atteso('cmd_noto', c[2], TT.spiega_comando.qa_scritto))
      vero(esce(F), 'il figlio non è uscito')
    end)
  end
end

-- Con un terminale ancora acceso `:qa` di Vim dà un errore («Job ancora in esecuzione»): `:qa` di
-- dattilo chiude lo stesso.
T[':qa chiude dattilo anche con un terminale acceso'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':terminal<CR>')
    uguale(F:modo(), 'nt')
    F:input('<C-\\><C-n>')
    F:input(':qa')
    nel_posto(F, atteso('cmd_noto', 'qa', TT.spiega_comando.qa_scritto))
    vero(esce(F), 'il figlio non è uscito')
  end)
end

-- Il comando e le abbreviazioni ci sono solo con la guida accesa: il dattilo di sempre non cambia.
T[':qa è di dattilo solo con la guida accesa'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    uguale(F:lua('return vim.fn.exists(":DattiloEsciTutto")'), 2)
    uguale(F:lua('return vim.fn.maparg("qa", "c", true) ~= ""'), true)
    F:lua('require("dattilo.vivo").ferma()')
    uguale(F:lua('return vim.fn.exists(":DattiloEsciTutto")'), 0)
    uguale(F:lua('return vim.fn.maparg("qa", "c", true)'), '')
  end)
  -- senza la guida (il dattilo di sempre) non ci sono
  con({ vivo = false, cartella = M.cartella() }, function(F)
    uguale(F:lua('return vim.fn.exists(":DattiloEsciTutto")'), 0)
    uguale(F:lua('return vim.fn.maparg("qa", "c", true)'), '')
  end)
end

return T
