-- Le schermate di «Rifallo tu» (riepilogo, elenco, attesa) e i comandi :salta, :ultima ed :elenco,
-- nel Neovim figlio coi tasti veri. Tranne le ultime due prove, che girano con `nvim -l`.
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local TT = require('dattilo.guida_testi')
local uv = vim.uv

local C1 = { 'function somma(a, b) {', '    if (typeof a !== "number") return 0;', '    return a + b;', '}' }
local C2 = { 'function saluta(nome) {', '    return "«" + nome + "»";', '}' }

local function lezioni_dir(c) return c .. '/dati/dattilo/pacchetti/rifallo/lezioni' end

local function scrivi(F, s) F:input((s:gsub('<', '<lt>'))) end

local function leggi(percorso) return table.concat(vim.fn.readfile(percorso), '\n') end

local function stato_json(c)
  return vim.json.decode(leggi(c .. '/stato.json'), { luanil = { object = true, array = true } })
end

local function progressi_json(c)
  return vim.json.decode(leggi(c .. '/dati/dattilo/progressi.json'))
end

-- Il figlio con vivo acceso su una cartella copiata dalla fixture; `prepara(c)` la cambia prima di partire.
-- `fn(F, c)`. La cartella si cancella sempre.
local function con(fn, prepara)
  local c = M.cartella()
  if prepara then prepara(c) end
  local ok, err = xpcall(M.con, debug.traceback, { cartella = c, vivo = true }, function(F) fn(F, c) end)
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

-- Una terza lezione, la 003-x, copia della 002.
local function con_tre(c)
  assert(uv.fs_copyfile(lezioni_dir(c) .. '/002-saluto.md', lezioni_dir(c) .. '/003-x.md'))
end

local function senza_lezioni(c)
  for _, f in ipairs(vim.fn.glob(lezioni_dir(c) .. '/*.md', false, true)) do vim.fn.delete(f) end
end

local function nil_se_vuoto(r) if r == vim.NIL then return nil end return r end
local function id(F) return nil_se_vuoto(F:lua('local s = require("dattilo.lezione").s return s and s.L.id')) end
local function passo(F) return nil_se_vuoto(F:lua('local s = require("dattilo.lezione").s return s and s.passo')) end
local function schermo(F) return F:lua('return require("dattilo.stato").schermo') end
local function titolo(F) local r = F:riquadro() return r and r.titolo end
local function codice(F) return F:lua('return require("dattilo.lezione").s.L.batti.codice') end

local function briefing(F)
  F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
end

local function batti_tutto(F, righe)
  F:input('i')
  for i, l in ipairs(righe) do
    scrivi(F, vim.trim(l))
    if i < #righe then F:input('<CR>') end
  end
end

-- Dal briefing alla spiegazione (battendo tutto il codice e salvando), e poi al riepilogo.
local function alla_spiegazione(F)
  briefing(F)
  F:input('<CR>')
  batti_tutto(F, codice(F))
  F:input('<Esc>:w<CR>')
  vero(F:aspetta(function() return passo(F) == 'spiegazione' end), 'passo: ' .. tostring(passo(F)))
end

local function al_riepilogo(F)
  alla_spiegazione(F)
  F:input('<CR>')
  vero(F:aspetta(function() return passo(F) == 'fine' end), 'passo: ' .. tostring(passo(F)))
end

local function esce(F)
  vim.rpcnotify(F.canale, 'nvim_input', '<CR>')
  return vim.fn.jobwait({ F.canale }, 3000)[1] == 0
end

local function testo(F) return table.concat(F:righe(), '\n') end

---------------------------------------------------------------- il riepilogo

T['riepilogo con la coda'] = function()
  con(function(F, c)
    al_riepilogo(F)
    uguale(titolo(F), TT.f('titoli.fatto', 'somma'))
    uguale(titolo(F), 'FATTO · somma')
    local r = F:riquadro()
    uguale(r.sezioni.Adesso, TT.f('fatto_coda', 'Il saluto', ' (1 nuova)'))
    uguale(r.sezioni.Comandi, TT.comandi_fatto)
    -- i numeri, senza il ripasso né par né stelle
    local t = testo(F)
    vero(t:find('Batti', 1, true) and t:find('4 righe in', 1, true), t)
    vero(t:find('parole al minuto', 1, true) and t:find('di precisione', 1, true), t)
    vero(t:find('Prossima', 1, true) and t:find('“Il saluto”', 1, true), t)
    vero(not t:find('Ripasso', 1, true), t)
    vero(not t:find('par ', 1, true) and not t:find('★', 1, true), t)
    -- registrata, e la barra e lo stato lo sanno
    local l = progressi_json(c).lezioni['rifallo/001-somma']
    vero(l and l.completata and l.volte == 1, vim.inspect(l))
    vero(l.ultima.wpm ~= nil and l.ultima.precisione ~= nil and l.ultima.tempo_ms ~= nil, vim.inspect(l))
    vero(F:aspetta(function() return stato_json(c).schermo == 'fatto' end, 2000), leggi(c .. '/stato.json'))
    local st = stato_json(c)
    uguale({ st.lezione, st.fatte, st.nuove, st.prossima }, { '001-somma', { '001-somma' }, 1, '002-saluto' })
    vero(F:lua('return require("dattilo.stato").destra'):find(' · 1 nuova', 1, true), F:lua('return require("dattilo.stato").destra'))
    uguale(schermo(F), 'lezione')
    vero(not F:messaggi():find('Premi', 1, true) and not F:messaggi():find('INVIO', 1, true), F:messaggi())
  end)
end

T['Invio nel riepilogo apre la prossima'] = function()
  con(function(F)
    al_riepilogo(F)
    F:input('<CR>')
    vero(F:aspetta(function() return id(F) == '002-saluto' end), tostring(id(F)))
    uguale(passo(F), 'briefing')
    uguale(titolo(F), TT.f('titoli.briefing', 'saluta'))
  end)
end

T['riepilogo senza coda e attesa'] = function()
  con(function(F, c)
    al_riepilogo(F)
    F:input('<CR>')
    briefing(F)
    F:input('<CR>')
    batti_tutto(F, C2)
    F:input('<Esc>:w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end))
    F:input('<CR>')
    vero(F:aspetta(function() return passo(F) == 'fine' end))
    uguale(titolo(F), 'FATTO · saluta')
    uguale(F:riquadro().sezioni.Adesso, TT.fatto_vuota)
    vero(testo(F):find('arriva con la prossima modifica di Claude', 1, true), testo(F))
    F:input('<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.attesa end), tostring(titolo(F)))
    uguale(titolo(F), 'ASPETTO CLAUDE')
    local r = F:riquadro()
    uguale(r.sezioni.Adesso, TT.attesa)
    uguale(r.sezioni.Comandi, TT.comandi_attesa)
    uguale(schermo(F), 'home')
    vero(testo(F):find(TT.canale.attesa, 1, true), testo(F))
    vero(F:aspetta(function() return stato_json(c).schermo == 'attesa' end, 2000), leggi(c .. '/stato.json'))
    -- arriva una lezione: si apre da sola, al briefing
    assert(uv.fs_copyfile(lezioni_dir(c) .. '/002-saluto.md', lezioni_dir(c) .. '/003-x.md'))
    vero(F:aspetta(function() return id(F) == '003-x' end, 1500), 'la 003-x non si è aperta: ' .. tostring(id(F)))
    uguale(passo(F), 'briefing')
  end)
end

T['r nel riepilogo rifà la lezione, q porta all elenco'] = function()
  con(function(F, c)
    al_riepilogo(F)
    F:input('r')
    vero(F:aspetta(function() return id(F) == '001-somma' and passo(F) == 'briefing' end), tostring(id(F)) .. ' ' .. tostring(passo(F)))
    uguale(titolo(F), 'COMINCIA · somma')
    F:input('<CR>')
    batti_tutto(F, C1)
    F:input('<Esc>:w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end))
    F:input('<CR>')
    vero(F:aspetta(function() return passo(F) == 'fine' end))
    uguale(progressi_json(c).lezioni['rifallo/001-somma'].volte, 2)
    F:input('q')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F)))
    uguale(id(F), nil)
    uguale(schermo(F), 'home')
  end)
end

T['il riepilogo non perde il riquadro con Ctrl-z'] = function()
  con(function(F)
    al_riepilogo(F)
    F:input('<C-z>')
    local r = F:riquadro()
    uguale(r.titolo, 'FATTO · somma')
    uguale(r.sezioni.Adesso, TT.f('fatto_coda', 'Il saluto', ' (1 nuova)'))
    uguale(r.sezioni.Controllo, TT.ctrl_z)
    uguale(r.sezioni.Comandi, TT.comandi_fatto)
    uguale(F:modo(), 'n')
  end)
end

---------------------------------------------------------------- :salta e :ultima

T[':salta e :ultima'] = function()
  con(function(F, c)
    briefing(F)
    F:input('<CR>')
    uguale(passo(F), 'batti')
    F:input(':salta<CR>')
    vero(F:aspetta(function() return id(F) == '002-saluto' end), tostring(id(F)))
    uguale(passo(F), 'briefing')
    vero(F:aspetta(function() return vim.deep_equal(stato_json(c).saltate, { '001-somma' }) end, 2000), leggi(c .. '/stato.json'))
    uguale(stato_json(c).ultima, '003-x')
    -- ‹:ultima›: la più recente non fatta
    F:input(':ultima<CR>')
    vero(F:aspetta(function() return id(F) == '003-x' end), tostring(id(F)))
    uguale(titolo(F), TT.f('titoli.briefing', 'saluta'))
    -- già lì: non succede niente, e lo dice
    F:input(':ultima<CR>')
    uguale(id(F), '003-x')
    uguale(F:riquadro().sezioni.Controllo, TT.ultima_gia)
  end, con_tre)
end

T[':salta dall ultima lezione va a quelle lasciate, poi in attesa'] = function()
  con(function(F, c)
    briefing(F)
    -- la 001 resta lasciata a metà (né fatta né saltata), e si va alla più recente, la 002
    F:input(':ultima<CR>')
    vero(F:aspetta(function() return id(F) == '002-saluto' end), tostring(id(F)))
    F:input(':salta<CR>')
    vero(F:aspetta(function() return id(F) == '001-somma' end), 'dopo :salta: ' .. tostring(id(F)))
    uguale(passo(F), 'briefing')
    F:input(':salta<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.attesa end), tostring(titolo(F)))
    uguale(id(F), nil)
    vero(F:aspetta(function() return vim.deep_equal(stato_json(c).saltate, { '002-saluto', '001-somma' }) end, 2000), leggi(c .. '/stato.json'))
    -- in attesa nessuna delle due si riapre da sola, perché sono saltate
    vim.wait(1200)
    uguale(id(F), nil)
    uguale(stato_json(c).schermo, 'attesa')
  end)
end

T[':salta e :ultima fuori da una lezione non fanno niente'] = function()
  con(function(F)
    briefing(F)
    F:input(':elenco<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
    F:input(':salta<CR>')
    uguale(titolo(F), TT.titoli.elenco)
    uguale(id(F), nil)
    local m = F:messaggi()
    vero(not m:find('E492', 1, true) and not m:find('Premi', 1, true), m)
  end)
end

T[':ultima con tutto fatto lo dice'] = function()
  con(function(F)
    al_riepilogo(F)
    F:input('<CR>')
    briefing(F)
    F:input('<CR>')
    batti_tutto(F, C2)
    F:input('<Esc>:w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end))
    F:input('<CR>')
    vero(F:aspetta(function() return passo(F) == 'fine' end))
    F:input(':ultima<CR>')
    uguale(passo(F), 'fine')
    uguale(F:riquadro().sezioni.Controllo, TT.ultima_niente)
    uguale(F:riquadro().sezioni.Adesso, TT.fatto_vuota)
  end)
end

-- Riepilogo e attesa dicono la stessa cosa: quello che ‹Invio› promette è quello che si apre.
-- La 001 lasciata a metà c'è ancora, e l'attesa la riaprirebbe: il riepilogo la annuncia.
T['il riepilogo annuncia la lezione lasciata a metà, la stessa che aprirebbe l attesa'] = function()
  con(function(F)
    briefing(F)
    F:input(':ultima<CR>')
    vero(F:aspetta(function() return id(F) == '002-saluto' end))
    F:input('<CR>')
    batti_tutto(F, C2)
    F:input('<Esc>:w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end))
    F:input('<CR>')
    vero(F:aspetta(function() return passo(F) == 'fine' end))
    uguale(F:riquadro().sezioni.Adesso, TT.f('fatto_coda', 'La somma', ' (1 nuova)'))
    F:input('<CR>')
    vero(F:aspetta(function() return id(F) == '001-somma' end), tostring(id(F)))
    uguale(passo(F), 'briefing')
  end)
end

T['i comandi si scrivono anche con lo spazio: la guida li riconosce'] = function()
  con(function(F)
    briefing(F)
    F:input('<CR>')
    F:input(':salta ')
    local r = F:riquadro()
    uguale(r.titolo, 'RIGA DEI COMANDI')
    uguale(r.sezioni.Adesso, TT.f('posti.cmd_noto.testo', 'salta', TT.spiega_comando.salta))
    F:input('<Esc>')
  end)
end

---------------------------------------------------------------- l'elenco

-- Una fatta, una saltata e una nuova: la 001 con le sue prove nei progressi, la 002 nel stato.json di prima.
local function tre_diverse(c)
  con_tre(c)
  vim.fn.mkdir(c .. '/dati/dattilo', 'p')
  vim.fn.writefile({ vim.json.encode({ lezioni = { ['rifallo/001-somma'] = { volte = 1, completata = true, migliore_wpm = 10,
    ultima = { wpm = 10, precisione = 100, tempo_ms = 5000 } } }, sessioni = {}, sbloccate = vim.empty_dict() }) }, c .. '/dati/dattilo/progressi.json')
  vim.fn.writefile({ vim.json.encode({ v = 1, t = 1, aperte = { '001-somma', '002-saluto' }, saltate = { '002-saluto' }, eseguita = 0 }) },
    c .. '/stato.json')
end

T['elenco: segni e comandi'] = function()
  con(function(F, c)
    briefing(F)
    uguale(id(F), '003-x', 'all\'avvio si apre la prima non fatta e non saltata')
    F:input(':elenco<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F)))
    local r = F:riquadro()
    uguale(r.sezioni.Adesso, TT.elenco)
    uguale(r.sezioni.Comandi, TT.comandi_elenco)
    uguale(schermo(F), 'home')
    local righe = F:righe()
    local di = {}
    for _, l in ipairs(righe) do
      if l:find('La somma', 1, true) then di.somma = l end
      if l:find('Il saluto', 1, true) then di[#di + 1] = l end
    end
    vero(di.somma and di.somma:find('✓', 1, true) and not di.somma:find('▸', 1, true), vim.inspect(righe))
    vero(not di.somma:find('saltata', 1, true) and not di.somma:find('nuova', 1, true), di.somma)
    -- la 002 (saltata) e la 003 (nuova) hanno lo stesso titolo
    vero(#di == 2, vim.inspect(righe))
    vero(di[1]:find('▸', 1, true) and di[1]:find('saltata', 1, true) and not di[1]:find('✓', 1, true), di[1])
    vero(di[2]:find('▸', 1, true) and di[2]:find('nuova', 1, true) and not di[2]:find('✓', 1, true), di[2])
    uguale(id(F), nil)
    -- ‹j› scende, ‹Invio› apre: la seconda
    F:input('j')
    F:input('<CR>')
    vero(F:aspetta(function() return id(F) == '002-saluto' end), tostring(id(F)))
    uguale(passo(F), 'briefing')
  end, tre_diverse)
end

T['elenco: j, k, le frecce e un clic scelgono la lezione, Invio apre quella'] = function()
  con(function(F)
    briefing(F)
    F:input(':elenco<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
    local function riga() return F:lua('return vim.api.nvim_win_get_cursor(0)[1]') end
    uguale(riga(), 2)
    F:input('k')
    uguale(riga(), 2, 'sopra la prima non si sale')
    F:input('j')
    uguale(riga(), 3)
    F:input('<Down>')
    uguale(riga(), 4)
    F:input('<Down>')
    uguale(riga(), 4, 'sotto l\'ultima non si scende')
    F:input('<Up>')
    uguale(riga(), 3)
    F:input('k')
    uguale(riga(), 2)
    -- un clic sposta il cursore senza passare da j e k: ‹Invio› apre la riga del cursore
    F:clic(4, 5)
    F:input('<CR>')
    vero(F:aspetta(function() return id(F) == '003-x' end), tostring(id(F)))
  end, con_tre)
end

T['elenco: la riga scelta si vede, e non è il segno delle lezioni da fare'] = function()
  con(function(F)
    briefing(F)
    F:input(':elenco<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
    local function scelta()
      return F:lua([[
        local r = vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })
        for _, m in ipairs(r) do
          if m[4].line_hl_group == 'DattiloSelezione' then return m[2] + 1 end
        end]])
    end
    uguale(scelta(), 2)
    F:input('j')
    uguale(scelta(), 3)
    F:input('<Up>')
    uguale(scelta(), 2)
  end)
end

T[':elenco senza lezioni lo dice'] = function()
  con(function(F, c)
    F:aspetta(function() return titolo(F) == TT.titoli.attesa end)
    F:input(':elenco<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F)))
    uguale(F:riquadro().sezioni.Adesso, TT.elenco_vuoto)
    uguale(F:riquadro().sezioni.Comandi, TT.comandi_elenco)
  end, senza_lezioni)
end

---------------------------------------------------------------- l'attesa

T['attesa: la frase cambia se la sessione finisce o Dal vivo si spegne'] = function()
  con(function(F, c)
    F:aspetta(function() return titolo(F) == TT.titoli.attesa end)
    uguale(F:riquadro().sezioni.Adesso, TT.attesa)
    local function vuoi(campi)
      local tmp = c .. '/vuoi.json.tmp'
      vim.fn.writefile({ vim.json.encode(vim.tbl_extend('force', { v = 1 }, campi)) }, tmp)
      assert(uv.fs_rename(tmp, c .. '/vuoi.json'))
    end
    vuoi({ t = 10, dalvivo = 'finita' })
    vero(F:aspetta(function() return F:riquadro().sezioni.Adesso == TT.attesa_finita end, 1500), F:riquadro().sezioni.Adesso)
    vero(TT.attesa_finita:find('‹:elenco› ‹Invio›', 1, true), TT.attesa_finita)
    uguale(F:riquadro().sezioni.Comandi, TT.comandi_attesa)
    vuoi({ t = 11, dalvivo = 'spento' })
    vero(F:aspetta(function() return F:riquadro().sezioni.Adesso == TT.attesa_spento end, 1500), F:riquadro().sezioni.Adesso)
    vuoi({ t = 12, dalvivo = 'acceso' })
    vero(F:aspetta(function() return F:riquadro().sezioni.Adesso == TT.attesa end, 1500), F:riquadro().sezioni.Adesso)
  end, senza_lezioni)
end

---------------------------------------------------------------- G1: le schermate stanno intere

for _, d in ipairs({ { 80, 24 }, { 120, 40 } }) do
  T[string.format('a %dx%d riepilogo, elenco e attesa hanno Adesso e Comandi interi', d[1], d[2])] = function()
    local function intero(F, titolo_atteso, adesso, comandi)
      local A = F:a_schermo()
      uguale(F:riquadro().titolo, titolo_atteso)
      uguale(A.sezioni.Adesso, M.a_schermo(adesso))
      uguale(A.sezioni.Comandi, M.a_schermo(comandi))
      vero(A.finisce.Adesso:sub(-3) ~= '…' and A.finisce.Comandi:sub(-3) ~= '…', vim.inspect(A.righe))
      uguale(A.alto, #A.righe, 'la finestra non mostra tutto il riquadro')
      for _, r in ipairs(A.righe) do uguale(vim.fn.strdisplaywidth(r), d[1], r) end
    end
    con(function(F)
      briefing(F)
      F:lua('vim.o.columns, vim.o.lines = ...', d[1], d[2])
      al_riepilogo(F)
      intero(F, 'FATTO · somma', TT.f('fatto_coda', 'Il saluto', ' (1 nuova)'), TT.comandi_fatto)
      F:input(':elenco<CR>')
      vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
      intero(F, TT.titoli.elenco, TT.elenco, TT.comandi_elenco)
      F:input(':salta<CR>') -- non fa niente fuori da una lezione
      F:input('<CR>')
      vero(F:aspetta(function() return id(F) == '001-somma' end))
    end)
    con(function(F)
      F:aspetta(function() return titolo(F) == TT.titoli.attesa end)
      F:lua('vim.o.columns, vim.o.lines = ...', d[1], d[2])
      intero(F, TT.titoli.attesa, TT.attesa, TT.comandi_attesa)
    end, senza_lezioni)
  end
end

---------------------------------------------------------------- G6: ogni comando scritto fa quello che dice

-- Le voci di una sezione «Comandi»: { tasti = 'nel linguaggio di Neovim', testo = 'la voce' }.
local function voci(frase)
  local out = {}
  for _, v in ipairs(vim.split(frase, ' · ', { plain = true })) do
    local tasti, i = {}, 1
    while true do
      local a, b, k = v:find('^%s*‹([^›]*)›', i)
      if not a then break end
      tasti[#tasti + 1] = TT.neovim(k)
      i = b + 1
    end
    out[#out + 1] = { tasti = table.concat(tasti), testo = v }
  end
  return out
end

-- Per ogni schermata: come ci si arriva (con tre lezioni, la 001 aperta) e cosa succede premendo
-- ogni voce. Chi non ha una voce nella tabella di sotto fa fallire la prova: «Comandi» non può
-- scrivere un comando che nessuno ha provato.
local SCHERMATE = {
  batti = {
    comandi = 'comandi_batti',
    entra = function(F) briefing(F) F:input('<CR>') F:input('ifunc<Esc>') end,
    voce = {
      [':w<CR>'] = function(F)
        uguale(passo(F), 'batti')
        local N = #table.concat(codice(F), '\n') - #table.concat(F:righe(), '\n')
        uguale(F:riquadro().sezioni.Controllo, TT.f('controllo_mancano', N))
      end,
      [':q<CR>'] = function(F) vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F))) uguale(id(F), nil) end,
      [':salta<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '002-saluto' and passo(F) == 'briefing' end), tostring(id(F))) end,
      [':ultima<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '003-x' and passo(F) == 'briefing' end), tostring(id(F))) end,
    },
  },
  briefing = {
    comandi = 'comandi_testo',
    entra = function(F) briefing(F) end,
    voce = {
      q = function(F) vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F))) end,
      [':salta<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '002-saluto' end), tostring(id(F))) end,
      [':ultima<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '003-x' end), tostring(id(F))) end,
    },
  },
  spiegazione = {
    comandi = 'comandi_spiegazione',
    entra = alla_spiegazione,
    voce = {
      q = function(F) vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F))) end,
      ['<CR>'] = function(F) vero(F:aspetta(function() return passo(F) == 'fine' end), 'passo: ' .. tostring(passo(F))) end,
      [':salta<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '002-saluto' end), tostring(id(F))) end,
      [':ultima<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '003-x' end), tostring(id(F))) end,
    },
  },
  fatto = {
    comandi = 'comandi_fatto',
    entra = al_riepilogo,
    voce = {
      r = function(F) vero(F:aspetta(function() return id(F) == '001-somma' and passo(F) == 'briefing' end), tostring(id(F))) end,
      q = function(F) vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F))) end,
      [':ultima<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '003-x' end), tostring(id(F))) end,
    },
  },
  elenco = {
    comandi = 'comandi_elenco',
    entra = function(F) briefing(F) F:input(':elenco<CR>') vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end)) end,
    voce = {
      [':ultima<CR>'] = function(F) vero(F:aspetta(function() return id(F) == '003-x' end), tostring(id(F))) end,
      [':q<CR>'] = 'esce',
    },
  },
  attesa = {
    comandi = 'comandi_attesa',
    entra = function(F) F:aspetta(function() return titolo(F) == TT.titoli.attesa end) end,
    prepara = senza_lezioni,
    voce = {
      [':elenco<CR>'] = function(F) vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end), tostring(titolo(F))) end,
      [':q<CR>'] = 'esce',
    },
  },
}

T['ogni comando scritto fa quello che dice'] = function()
  -- (la schermata della Modifica, col suo ‹:e!›, arriva col tempo B: qui non c'è una lezione con la Modifica)
  local provati = 0
  for nome, S in pairs(SCHERMATE) do
    local frase = TT[S.comandi]
    vero(frase, S.comandi)
    local V = voci(frase)
    vero(#V >= 2, nome .. ': poche voci in «' .. frase .. '»')
    for _, v in ipairs(V) do
      local atteso = S.voce[v.tasti]
      vero(atteso, string.format('%s: «Comandi» scrive «%s» e nessuna prova lo fa', nome, v.testo))
      con(function(F)
        S.entra(F)
        if atteso == 'esce' then
          -- l'ultimo tasto parte con rpcnotify: il figlio esce prima di rispondere
          F:input((v.tasti:gsub('<CR>$', '')))
          vero(esce(F), nome .. ' ' .. v.tasti .. ': il figlio non è uscito')
        else
          F:input(v.tasti)
          atteso(F)
        end
        local m = not F.chiuso and atteso ~= 'esce' and F:messaggi() or ''
        vero(not m:find('Premi', 1, true), nome .. ' ' .. v.tasti .. ': ' .. m)
      end, S.prepara or con_tre)
      provati = provati + 1
    end
    -- e la tabella non ha voci che «Comandi» non scrive più
    local scritte = {}
    for _, v in ipairs(V) do scritte[v.tasti] = true end
    for k in pairs(S.voce) do vero(scritte[k], nome .. ': la prova ' .. k .. ' non è più in «Comandi»') end
  end
  vero(provati >= 17, 'comandi provati: ' .. provati)
end

---------------------------------------------------------------- senza vivo

T['i testi del canale stanno in guida_testi'] = function()
  uguale(TT.canale.nuova, ' · 1 nuova')
  uguale(TT.f('canale.nuove', 3), ' · 3 nuove')
  uguale(TT.canale.finita, ' · sessione finita: niente lezioni nuove')
  uguale(TT.canale.spenta, ' · Dal vivo spento: niente lezioni nuove')
  uguale(TT.canale.dati_fuori, 'la cartella dei dati non è dentro quella di Rifallo tu')
  uguale(TT.canale.assente, 'il file non c\'è più')
  uguale(TT.canale.attesa, 'Aspetto la prossima modifica di Claude a un file JavaScript…')
end

T['senza vivo i comandi non ci sono'] = function()
  for _, c in ipairs({ 'DattiloSalta', 'DattiloUltima', 'DattiloElenco' }) do
    uguale(vim.fn.exists(':' .. c), 0, c)
  end
  for _, a in ipairs({ 'salta', 'ultima', 'elenco' }) do
    uguale(vim.fn.maparg(a, 'c', true, true).rhs, nil, 'abbreviazione ' .. a)
  end
end

T['con vivo i comandi ci sono, e ferma li toglie'] = function()
  local vivo = require('dattilo.vivo')
  local lezione, pacchetti = require('dattilo.lezione'), require('dattilo.pacchetti')
  local stato = require('dattilo.stato')
  local c = M.cartella()
  local prima = { xdg = vim.env.XDG_DATA_HOME, stato = vim.deepcopy(stato) }
  vim.env.XDG_DATA_HOME = c .. '/dati'
  pacchetti.dimentica()
  local ok, err = xpcall(function()
    vivo.avvia(c)
    for _, n in ipairs({ 'DattiloSalta', 'DattiloUltima', 'DattiloElenco' }) do uguale(vim.fn.exists(':' .. n), 2, n) end
    for a, cmd in pairs({ salta = 'DattiloSalta', ultima = 'DattiloUltima', elenco = 'DattiloElenco' }) do
      uguale(vim.fn.maparg(a, 'c', true, true).rhs:find(cmd, 1, true) ~= nil, true, 'abbreviazione ' .. a)
    end
    vivo.ferma()
    for _, n in ipairs({ 'DattiloSalta', 'DattiloUltima', 'DattiloElenco' }) do uguale(vim.fn.exists(':' .. n), 0, n) end
    for _, a in ipairs({ 'salta', 'ultima', 'elenco' }) do
      uguale(vim.fn.maparg(a, 'c', true, true).rhs, nil, 'abbreviazione ' .. a)
    end
  end, debug.traceback)
  vivo.ferma()
  lezione.chiudi()
  require('dattilo.ui').chiudi_tip()
  vim.env.XDG_DATA_HOME = prima.xdg
  for k in pairs(stato) do stato[k] = nil end
  for k, v in pairs(prima.stato) do stato[k] = v end
  pacchetti.dimentica()
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

return T
