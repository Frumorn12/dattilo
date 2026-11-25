-- Le correzioni dopo la revisione dei compiti 5 e 6 (24/11), nel Neovim figlio coi tasti veri:
-- «Comandi» non contraddice «Adesso» mentre si scrive un comando in un posto sbagliato (N1, B1),
-- uscire dalla spiegazione dice che la lezione non conta ancora come fatta (B2), `: qa` con lo spazio
-- davanti vale come `:qa` (B3), `:b 4` vale (N3), le guardie delle abbreviazioni e di `riprendi`
-- (B4), e il banco delle prove pulisce quello che crea (B10).
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

local function scrivi(F, s) F:input((s:gsub('<', '<lt>'))) end
local function codice(F) return F:lua('return require("dattilo.lezione").s.L.batti.codice') end
local function passo(F) return F:lua('return require("dattilo.lezione").s.passo') end
local function schermo(F) return F:lua('return require("dattilo.stato").schermo') end
local function finestre(F) return #F:lua('return vim.api.nvim_tabpage_list_wins(0)') end
local function buf_lezione(F) return F:lua('return require("dattilo.lezione").s.buf') end
local function righe_lezione(F) return F:lua('local s = require("dattilo.lezione").s return vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)') end
local function fuori(F) return F:riquadro().tipo ~= 'rosso' end

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

-- Il figlio esce davvero (codice 0) quando si preme l'ultimo tasto (con rpcnotify: dopo, il figlio non risponde più).
local function esce(F)
  vim.rpcnotify(F.canale, 'nvim_input', '<CR>')
  return vim.fn.jobwait({ F.canale }, 3000)[1] == 0
end

-- Il riquadro quando si è fermato: due letture uguali di fila (il ridisegno parte da un vim.schedule).
local function riquadro_fermo(F)
  local prima = F:riquadro()
  for _ = 1, 50 do
    vim.wait(15)
    local ora = F:riquadro()
    if vim.deep_equal(ora, prima) then return ora end
    prima = ora
  end
  return prima
end

local function progressi(c)
  local f = c .. '/dati/dattilo/progressi.json'
  if vim.fn.filereadable(f) == 0 then return {} end
  return vim.json.decode(table.concat(vim.fn.readfile(f), '\n')).lezioni or {}
end

---------------------------------------------------------------- N1 + B1: «Comandi» e «Adesso» d'accordo

-- Il robot di chi non sa niente, un tasto alla volta: legge «Adesso», preme i tasti della sua prima
-- fila uno per uno (‹:b4› sono tre tasti), e dopo OGNI tasto guarda «Comandi». Se «Adesso» cambia a
-- metà fila (dopo i due punti, per esempio) il suo primo tasto deve essere quello che la fila
-- prevedeva: la guida non si contraddice.

-- I tasti della prima fila di una frase, uno per uno, nella notazione di Neovim.
local function tasti_prima_fila(s)
  local tasti, i = {}, s:find('‹', 1, true)
  while i do
    local _, f, k = s:find('^‹([^›]*)›', i)
    if not f then break end
    local nome = TT.neovim(k)
    if nome ~= k or vim.fn.strchars(k) == 1 then tasti[#tasti + 1] = nome
    else for _, ch in ipairs(vim.fn.split(k, '\\zs')) do tasti[#tasti + 1] = ch end end
    if s:find('^ ‹', f + 1) then i = f + 2 else break end
  end
  return tasti
end

-- Dove si è, guardando Neovim e non la guida: 'schermata' (nella finestra della lezione, col suo
-- buffer), 'altro' (nella finestra della lezione, ma con un altro buffer) o 'finestra' (in un'altra finestra).
local function luogo(F)
  return F:lua([[
    local s = require('dattilo.schermo')
    local w = vim.api.nvim_get_current_win()
    if w ~= s.principale then return 'finestra' end
    if vim.api.nvim_win_get_buf(w) ~= s.mostrato then return 'altro' end
    return 'schermata']])
end

-- Quello che «Comandi» deve dire dove si è: quello della schermata nella finestra della lezione,
-- soltanto il ritorno in un altro buffer o in un'altra finestra.
local function controlla_comandi(F, n, cosa)
  local r = riquadro_fermo(F)
  local dove = luogo(F)
  local giusto = ({ altro = TT.f('comandi_altro', n), finestra = TT.comandi_finestra, schermata = TT.comandi_batti })[dove]
  uguale(r.sezioni.Comandi, giusto, cosa .. ' [' .. dove .. '] ' .. vim.inspect(r.sezioni.Adesso))
  -- mai un comando che lì fa un'altra cosa o dà un errore
  if dove ~= 'schermata' then
    vero(not r.sezioni.Comandi:find('‹:w›', 1, true), cosa .. ': «Comandi» offre :w')
    vero(not r.sezioni.Comandi:find('lasci la lezione', 1, true), cosa .. ': «Comandi» offre di lasciare la lezione')
  end
  return r
end

-- Segue la guida finché il riquadro non è più rosso; rende le frasi lette.
local function robot(F, n, max)
  local frasi = {}
  for giro = 1, max or 8 do
    local r = riquadro_fermo(F)
    if r.tipo ~= 'rosso' then return frasi end
    local adesso = r.sezioni.Adesso
    frasi[#frasi + 1] = adesso
    local tasti = tasti_prima_fila(adesso)
    vero(#tasti > 0, 'nessun tasto in: ' .. adesso)
    for i, k in ipairs(tasti) do
      F:input(k)
      local dopo = controlla_comandi(F, n, 'dopo il tasto ' .. k .. ' (giro ' .. giro .. ')')
      -- «Adesso» è cambiata a metà fila: il suo primo tasto è il prossimo della fila
      if i < #tasti and dopo.sezioni.Adesso ~= adesso and dopo.tipo == 'rosso' then
        uguale(tasti_prima_fila(dopo.sezioni.Adesso)[1], tasti[i + 1],
          'a metà fila «Adesso» dice un altro tasto: ' .. vim.inspect(dopo.sezioni.Adesso))
      end
    end
  end
  vero(fuori(F), 'seguendo la guida non si esce: ' .. vim.inspect(frasi))
  return frasi
end

-- Alla fine si è tornati nella lezione, col testo intatto e il riquadro com'era.
local function tornati(F, n, frasi)
  local cosa = vim.inspect(frasi)
  uguale(F:lua('return vim.api.nvim_get_current_buf()'), n, cosa)
  uguale(luogo(F), 'schermata', cosa)
  uguale(righe_lezione(F), { 'func' }, cosa)
  uguale(passo(F), 'batti', cosa)
  uguale(finestre(F), 2, cosa)
  local r = riquadro_fermo(F)
  vero(r.tipo ~= 'rosso', cosa)
  uguale(r.sezioni.Comandi, TT.comandi_batti, cosa)
  senza_errori(F, cosa)
end

-- Ogni posto: ci si entra, si segue la guida un tasto alla volta e a ogni tasto «Comandi» è giusto.
local function posto(nome, entra, da)
  T[nome] = function()
    con({}, function(F)
      in_batti(F, da or 'n')
      local n = buf_lezione(F)
      F:input(entra)
      local r = riquadro_fermo(F)
      uguale(r.tipo, 'rosso', 'non si è entrati in un posto sbagliato: ' .. vim.inspect(r))
      controlla_comandi(F, n, 'appena entrati')
      tornati(F, n, robot(F, n))
    end)
  end
end

posto('N1: altro file in NORMAL (Ctrl-^), un tasto alla volta', '<C-^>')
posto('N1: altro file in INSERT, un tasto alla volta', '<C-^>i')
posto('N1: altro file con :enew, un tasto alla volta', ':enew<CR>')
posto('N1: un terminale (Ctrl-\\ Ctrl-n), un tasto alla volta', ':terminal<CR><C-\\><C-n>')
posto('N1: un terminale in INSERT, un tasto alla volta', ':terminal<CR>i')
posto('B1: l aiuto con F1, un tasto alla volta', '<F1>')
posto('B1: finestra divisa con Ctrl-w s, un tasto alla volta', '<C-w>s')
posto('B1: INSERT in una finestra divisa, un tasto alla volta', '<C-w>ni')
posto('B1: la finestra dei comandi (q:), un tasto alla volta', 'q:')

-- Dopo i due punti, in un posto sbagliato, «Adesso» dice come finire il comando che riporta al
-- codice (non ‹Esc›), e scrivendolo una lettera alla volta resta così.
T['N1: dopo i due punti in un altro file «Adesso» dice b, 4 e Invio, e «Comandi» resta quello del posto'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-^>')
    local n = buf_lezione(F)
    F:input(':')
    local finisci = TT.f('cmd_finisci', '‹b› ‹' .. n .. '›', 'b' .. n, TT.spiega_comando.b)
    nel_posto(F, atteso('cmd_vuota_ritorno', finisci))
    uguale(F:riquadro().sezioni.Comandi, TT.f('comandi_altro', n))
    F:input('b')
    nel_posto(F, atteso('cmd_parziale', 'b', TT.f('cmd_finisci', '‹' .. n .. '›', 'b' .. n, TT.spiega_comando.b)))
    uguale(F:riquadro().sezioni.Comandi, TT.f('comandi_altro', n))
    F:input(tostring(n))
    nel_posto(F, atteso('cmd_noto', 'b' .. n, TT.spiega_comando.b))
    uguale(F:riquadro().sezioni.Comandi, TT.f('comandi_altro', n))
  end)
end

T['B1: dopo i due punti in una finestra in più «Adesso» dice q e Invio, e «Comandi» resta quello della finestra'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<F1>:')
    nel_posto(F, atteso('cmd_vuota_ritorno', TT.f('cmd_finisci', '‹q›', 'q', TT.spiega_comando.q_finestra)))
    uguale(F:riquadro().sezioni.Comandi, TT.comandi_finestra)
    F:input('q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_finestra))
    uguale(F:riquadro().sezioni.Comandi, TT.comandi_finestra)
  end)
end

-- Anche gli altri modi, in un altro file, hanno il «Comandi» del posto (VISUAL: prima ‹Esc›, ma
-- «Comandi» non offre comunque ‹:w›).
T['N1: VISUAL in un altro file: «Comandi» è quello del posto'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-^>')
    local n = buf_lezione(F)
    F:input('V')
    vero(F:aspetta(function() return F:modo() == 'V' end))
    local r = riquadro_fermo(F)
    uguale(r.titolo, TT.posti.visuale.titolo)
    uguale(r.sezioni.Comandi, TT.f('comandi_altro', n))
  end)
end

---------------------------------------------------------------- N3: `:b 4` con lo spazio

T['N3: :b 4 con lo spazio è un comando noto, e porta al codice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('<C-^>')
    local n = buf_lezione(F)
    F:input(':b ' .. n)
    nel_posto(F, atteso('cmd_noto', 'b' .. n, TT.spiega_comando.b))
    F:input('<CR>')
    uguale(F:lua('return vim.api.nvim_get_current_buf()'), n)
    uguale(righe_lezione(F), { 'func' })
    -- lo spazio dopo la b, col numero ancora da scrivere: a metà, e finisce di scrivere
    F:input('<C-^>')
    F:input(':b ')
    nel_posto(F, atteso('cmd_parziale', 'b', TT.f('cmd_finisci', '‹' .. n .. '›', 'b' .. n, TT.spiega_comando.b)))
    F:input('<Esc>')
  end)
end

---------------------------------------------------------------- B3: `: qa` e `: q` con lo spazio davanti

T['B3: : qa con lo spazio davanti chiude dattilo, come la guida dice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    uguale(F:lua('return vim.bo.modified'), true)
    F:input(': qa')
    nel_posto(F, atteso('cmd_noto', 'qa', TT.spiega_comando.qa_scritto))
    vero(esce(F), 'il figlio non è uscito: Vim ha dato E37?')
  end)
end

T['B3: due spazi davanti a qa valgono lo stesso'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':  qa')
    nel_posto(F, atteso('cmd_noto', 'qa', TT.spiega_comando.qa_scritto))
    vero(esce(F), 'il figlio non è uscito')
  end)
end

-- Con la guida le abbreviazioni di :q valgono anche con lo spazio davanti: la guida dice «lasci la
-- lezione e torni all'elenco», e prima Vim chiudeva la finestra e la lezione restava.
T['B3: : q con lo spazio davanti lascia la lezione, come la guida dice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(': q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_scritto))
    F:input('<CR>')
    vero(F:aspetta(function() return schermo(F) == 'home' end), 'si è ancora nella lezione')
    uguale(F:lua('return require("dattilo.lezione").s'), vim.NIL)
  end)
end

-- Dopo l'unione col compito 8: anche :salta, :ultima ed :elenco valgono con lo spazio davanti, perché
-- la guida li riconosce (trim) e dice «‹Invio›: esegui :salta». Senza, Vim dava E492 (non è un comando).
local function id_lezione(F) return F:lua('local s = require("dattilo.lezione").s return s and s.L.id or vim.NIL') end

T['B3: : salta con lo spazio davanti apre la prossima, come la guida dice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    uguale(id_lezione(F), '001-somma')
    F:input(': salta')
    nel_posto(F, atteso('cmd_noto', 'salta', TT.spiega_comando.salta))
    F:input('<CR>')
    vero(F:aspetta(function() return id_lezione(F) == '002-saluto' end), 'lezione: ' .. tostring(id_lezione(F)) .. ' ' .. F:messaggi())
  end)
end

T['B3: : ultima con lo spazio davanti apre l\'ultima modifica, come la guida dice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':  ultima')
    nel_posto(F, atteso('cmd_noto', 'ultima', TT.spiega_comando.ultima))
    F:input('<CR>')
    vero(F:aspetta(function() return id_lezione(F) == '002-saluto' end), 'lezione: ' .. tostring(id_lezione(F)) .. ' ' .. F:messaggi())
  end)
end

-- :elenco vale dove «Comandi» lo scrive: in attesa (senza lezioni).
T['B3: : elenco con lo spazio davanti apre l\'elenco, come la guida dice'] = function()
  local c = M.cartella()
  for _, f in ipairs(vim.fn.glob(c .. '/dati/dattilo/pacchetti/rifallo/lezioni/*.md', false, true)) do vim.fn.delete(f) end
  con({ cartella = c }, function(F)
    vero(F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo == TT.titoli.attesa end), 'non è in attesa')
    F:input(': elenco')
    nel_posto(F, atteso('cmd_noto', 'elenco', TT.spiega_comando.elenco))
    F:input('<CR>')
    vero(F:aspetta(function() return F:riquadro().titolo == TT.titoli.elenco end), 'titolo: ' .. tostring(F:riquadro().titolo) .. ' ' .. F:messaggi())
  end)
  vim.fn.delete(c, 'rf')
end

-- Senza la guida niente cambia: le abbreviazioni di sempre non guardano gli spazi.
T['B3: senza la guida le abbreviazioni di :q sono quelle di sempre'] = function()
  con({ vivo = false, cartella = M.cartella() }, function(F)
    uguale(F:lua('return vim.fn.maparg("q", "c", true)'), "(getcmdtype() ==# ':' && getcmdline() ==# 'q') ? 'DattiloEsci' : 'q'")
  end)
  -- con la guida guardano la riga senza gli spazi, e spenta la guida tornano com'erano
  con({}, function(F)
    in_batti(F, 'n')
    vero(F:lua('return vim.fn.maparg("q", "c", true)'):find('trim(getcmdline())', 1, true))
    F:lua('require("dattilo.vivo").ferma()')
    uguale(F:lua('return vim.fn.maparg("q", "c", true)'), "(getcmdtype() ==# ':' && getcmdline() ==# 'q') ? 'DattiloEsci' : 'q'")
  end)
end

---------------------------------------------------------------- B4 (a): l'abbreviazione di :qa scatta solo se è il comando intero

local function riga_dei_comandi(F) return F:lua('return vim.fn.getcmdline()') end

T['B4: :s/qa/x/ resta com era'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':s/qa/x/')
    uguale(riga_dei_comandi(F), 's/qa/x/')
    F:input('<Esc>')
  end)
end

T['B4: la ricerca /qa/ e ?qa? restano come erano'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('/qa/')
    uguale(riga_dei_comandi(F), 'qa/')
    F:input('<Esc>?qa?')
    uguale(riga_dei_comandi(F), 'qa?')
    F:input('<Esc>')
  end)
end

T['B4: :echo "qa" resta com era'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':echo "qa"')
    uguale(riga_dei_comandi(F), 'echo "qa"')
    F:input('<Esc>')
  end)
end

-- E scritto da solo, `qa` diventa il comando di dattilo (la guida e l'abbreviazione dicono la stessa cosa).
T['B4: qa da solo diventa DattiloEsciTutto, anche con lo spazio davanti'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input(':qa ')
    uguale(riga_dei_comandi(F), 'DattiloEsciTutto ')
    F:input('<Esc>: qa ')
    uguale(riga_dei_comandi(F), ' DattiloEsciTutto ')
    F:input('<Esc>')
  end)
end

---------------------------------------------------------------- B4 (b): :q dentro la finestra dei comandi

T['B4: :q dentro la finestra dei comandi la chiude e riporta al codice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    F:input('q:')
    uguale(F:lua('return vim.fn.getcmdwintype()'), ':')
    nel_posto(F, atteso('cmdwin'))
    F:input(':q<CR>')
    vero(F:aspetta(function() return F:lua('return vim.fn.getcmdwintype()') == '' end), 'la finestra dei comandi è ancora aperta')
    uguale(schermo(F), 'lezione', ':q nella finestra dei comandi ha lasciato la lezione')
    uguale(luogo(F), 'schermata')
    uguale(passo(F), 'batti')
    uguale(righe_lezione(F), { 'func' })
    uguale(finestre(F), 2)
    vero(F:aspetta(function() return fuori(F) end), vim.inspect(F:riquadro()))
    senza_errori(F, 'dopo :q nella finestra dei comandi')
  end)
end

---------------------------------------------------------------- B4 (c): riprendi rimette il buffer della lezione

-- La finestra della lezione, con un altro buffer dentro, viene chiusa: nella finestra che resta
-- (l'aiuto) va il codice della lezione, non il buffer della finestra chiusa.
T['B4: Ctrl-w c dalla lezione con un altro buffer: nella finestra che resta c è il codice'] = function()
  con({}, function(F)
    in_batti(F, 'n')
    local n = buf_lezione(F)
    F:input('<F1><C-w>p:enew<CR>')
    uguale(luogo(F), 'altro')
    vero(F:lua('return vim.api.nvim_get_current_buf()') ~= n)
    F:input('<C-w>c')
    F:aspetta(function() return finestre(F) == 2 and luogo(F) == 'schermata' end)
    uguale(F:lua('return vim.api.nvim_get_current_buf()'), n, 'nella finestra che resta non c\'è il codice')
    uguale(F:lua('return vim.bo.buftype'), '')
    uguale(passo(F), 'batti')
    uguale(righe_lezione(F), { 'func' })
    vero(F:aspetta(function() return fuori(F) end), vim.inspect(F:riquadro()))
    senza_errori(F, 'dopo Ctrl-w c')
  end)
end

---------------------------------------------------------------- B2: uscire dalla spiegazione non segna la lezione

-- Dopo aver battuto tutto e passato il controllo si è nella spiegazione. La lezione si segna solo
-- al riepilogo: uscire da qui non la segna, e la guida lo dice prima dell'Invio.
local function alla_spiegazione(F)
  briefing(F)
  F:input('<CR>')
  F:input('i')
  local righe = codice(F)
  for i, l in ipairs(righe) do
    scrivi(F, vim.trim(l))
    if i < #righe then F:input('<CR>') end
  end
  F:input('<Esc>:w<CR>')
  vero(F:aspetta(function() return passo(F) == 'spiegazione' end), 'passo: ' .. passo(F))
end

T['B2: nella spiegazione :q dice che la lezione non conta come fatta, e uscendo non si segna'] = function()
  local c = M.cartella()
  con({ cartella = c }, function(F)
    alla_spiegazione(F)
    F:input(':q')
    nel_posto(F, atteso('cmd_noto_spiegazione', 'q', TT.spiega_comando.q))
    -- ‹Esc› resta, e ‹Invio› finisce la lezione: la guida dice la strada
    F:input('<Esc>')
    F:aspetta(function() return F:adesso() == TT.spiegazione end)
    uguale(F:adesso(), TT.spiegazione)
    uguale(passo(F), 'spiegazione')
    F:input(':q<CR>')
    vero(F:aspetta(function() return schermo(F) == 'home' end))
    -- comportamento dichiarato: la lezione non è segnata
    uguale(progressi(c)['rifallo/001-somma'], nil)
  end)
end

T['B2: nella spiegazione :qa dice lo stesso, e chiudendo dattilo non si segna'] = function()
  local c = M.cartella()
  con({ cartella = c }, function(F)
    alla_spiegazione(F)
    F:input(':qa')
    nel_posto(F, atteso('cmd_noto_spiegazione', 'qa', TT.spiega_comando.qa))
    vero(esce(F), 'il figlio non è uscito')
    uguale(progressi(c)['rifallo/001-somma'], nil)
  end)
end

T['B2: nella spiegazione «Comandi» dice che il tasto q non segna la lezione'] = function()
  local c = M.cartella()
  con({ cartella = c }, function(F)
    alla_spiegazione(F)
    local r = riquadro_fermo(F)
    uguale(r.sezioni.Comandi, TT.comandi_spiegazione)
    vero(r.sezioni.Comandi:find('non conta come fatta', 1, true), r.sezioni.Comandi)
    F:input('q')
    vero(F:aspetta(function() return schermo(F) == 'home' end))
    uguale(progressi(c)['rifallo/001-somma'], nil)
  end)
end

-- Dopo l'unione col compito 8: «Comandi» della spiegazione è comandi_spiegazione, non più comandi_testo, e
-- scrive anche :salta e :ultima (la guida riconosce i comandi che «Comandi» scrive).
T['la spiegazione: :salta e :ultima sono comandi noti e «Comandi» li scrive'] = function()
  con({}, function(F)
    alla_spiegazione(F)
    local C = riquadro_fermo(F).sezioni.Comandi
    uguale(C, TT.comandi_spiegazione)
    vero(C:find('‹:salta› ‹Invio›', 1, true) and C:find('‹:ultima› ‹Invio›', 1, true), C)
    -- comandi noti (con la frase di B2: dalla spiegazione la lezione non conta come fatta, vedi sotto)
    F:input(':salta')
    nel_posto(F, atteso('cmd_noto_spiegazione', 'salta', TT.spiega_comando.salta))
    F:input('<Esc>:ultima')
    nel_posto(F, atteso('cmd_noto_spiegazione', 'ultima', TT.spiega_comando.ultima))
    F:input('<Esc>')
    uguale(passo(F), 'spiegazione')
  end)
end

-- Anche :salta e :ultima lasciano la lezione (:salta la segna «saltata», non fatta): dalla spiegazione la
-- frase lo dice prima dell'Invio, come per :q e :qa.
T['B2: nella spiegazione :salta e :ultima dicono che la lezione non conta come fatta'] = function()
  local c = M.cartella()
  con({ cartella = c }, function(F)
    alla_spiegazione(F)
    F:input(':salta')
    nel_posto(F, atteso('cmd_noto_spiegazione', 'salta', TT.spiega_comando.salta))
    -- a 80×24 la frase sta intera nel riquadro, senza «…»
    F:lua('vim.o.columns, vim.o.lines = ...', 80, 24)
    F:aspetta(function() local A = F:a_schermo() return A ~= nil and A.finisce.Adesso ~= nil and A.finisce.Adesso:find('la finisci', 1, true) ~= nil end)
    local A = F:a_schermo()
    vero(A.finisce.Adesso:sub(-3) ~= '…' and A.finisce.Comandi:sub(-3) ~= '…', vim.inspect(A.righe))
    uguale(A.alto, #A.righe, 'la finestra non mostra tutto il riquadro')
    F:input('<Esc>')
    F:aspetta(function() return F:adesso() == TT.spiegazione end)
    uguale(F:adesso(), TT.spiegazione)
    F:input(':ultima')
    nel_posto(F, atteso('cmd_noto_spiegazione', 'ultima', TT.spiega_comando.ultima))
    F:input('<Esc>')
    F:aspetta(function() return F:adesso() == TT.spiegazione end)
    uguale(passo(F), 'spiegazione')
    -- scritto per intero e con l'Invio fa quello che dice: apre la prossima, e la prima non è segnata come fatta
    F:input(':salta<CR>')
    vero(F:aspetta(function() return F:lua('local s = require("dattilo.lezione").s return s and s.L.id') == '002-saluto' end),
      'lezione: ' .. tostring(F:lua('local s = require("dattilo.lezione").s return s and s.L.id')))
    uguale(progressi(c)['rifallo/001-somma'], nil)
  end)
end

T['B2: arrivando al riepilogo la lezione si segna'] = function()
  local c = M.cartella()
  con({ cartella = c }, function(F)
    alla_spiegazione(F)
    uguale(progressi(c)['rifallo/001-somma'], nil)
    F:input('<CR>')
    vero(F:aspetta(function() return passo(F) == 'fine' end), 'passo: ' .. passo(F))
    vero(progressi(c)['rifallo/001-somma'] ~= nil, vim.inspect(progressi(c)))
  end)
end

-- Fuori dalla spiegazione `:q` e `:qa` non dicono niente in più (qui nel briefing).
T['B2: fuori dalla spiegazione :q e :qa non hanno la frase in più'] = function()
  con({}, function(F)
    briefing(F)
    F:input(':q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q))
    F:input('<Esc>:qa')
    nel_posto(F, atteso('cmd_noto', 'qa', TT.spiega_comando.qa))
    F:input('<Esc>')
    uguale(riquadro_fermo(F).sezioni.Comandi, TT.comandi_testo)
  end)
end

-- In una finestra in più, dalla spiegazione, `:q` chiude solo la finestra: niente frase sulla lezione.
T['B2: nella spiegazione, in una finestra in più, :q chiude solo la finestra'] = function()
  con({}, function(F)
    alla_spiegazione(F)
    F:input('<F1>:q')
    nel_posto(F, atteso('cmd_noto', 'q', TT.spiega_comando.q_finestra))
    F:input('<Esc>')
  end)
end

-- Ma `:qa` chiude dattilo anche da una finestra in più: la frase c'è anche lì.
T['B2: nella spiegazione, in una finestra in più, :qa dice che la lezione non conta, e non la segna'] = function()
  local c = M.cartella()
  con({ cartella = c }, function(F)
    alla_spiegazione(F)
    F:input('<F1>:qa')
    nel_posto(F, atteso('cmd_noto_spiegazione', 'qa', TT.spiega_comando.qa))
    vero(esce(F), 'il figlio non è uscito')
    uguale(progressi(c)['rifallo/001-somma'], nil)
  end)
end

---------------------------------------------------------------- B10: il banco pulisce quello che crea

T['B10: chiudendo il figlio la sua cartella temporanea sparisce'] = function()
  local F = M.avvia({ cartella = M.cartella(), vivo = true })
  local tmp = F.tmp
  vero(vim.uv.fs_stat(tmp), 'la cartella del figlio non c\'è mentre è aperto')
  -- anche la cartella temporanea di Neovim stesso (il figlio la crea) sta lì dentro
  local sua = F:lua('return vim.fn.tempname()')
  vero(vim.startswith(sua, tmp .. '/'), 'il figlio lavora fuori dalla sua cartella: ' .. sua)
  F:chiudi()
  uguale(vim.uv.fs_stat(tmp), nil, 'la cartella del figlio è rimasta')
end

return T
