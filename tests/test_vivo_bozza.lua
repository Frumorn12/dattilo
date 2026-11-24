-- La bozza (G8): il testo di Batti si salva in bozze/<id>.json mentre si scrive, quando si esce dalla
-- scrittura, quando si lascia la lezione e alla chiusura di Neovim, e si rimette riaprendo la lezione.
-- Nel Neovim figlio coi tasti veri.
local T = {}
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local TT = require('dattilo.guida_testi')
local uv = vim.uv

local C1 = { 'function somma(a, b) {', '    if (typeof a !== "number") return 0;', '    return a + b;', '}' }
local DUE = { 'function somma(a, b) {', '    if (ty' }

local function lezioni_dir(c) return c .. '/dati/dattilo/pacchetti/rifallo/lezioni' end
local function leggi(percorso) return table.concat(vim.fn.readfile(percorso), '\n') end
local function stato_json(c) return vim.json.decode(leggi(c .. '/stato.json'), { luanil = { object = true, array = true } }) end

local function vuoi(c, campi)
  local tmp = c .. '/vuoi.json.tmp'
  vim.fn.writefile({ vim.json.encode(vim.tbl_extend('force', { v = 1 }, campi)) }, tmp)
  assert(uv.fs_rename(tmp, c .. '/vuoi.json'))
end

local function bozza_file(c, id) return c .. '/bozze/' .. (id or '001-somma') .. '.json' end

-- La bozza com'è su disco (decodificata), o nil se non c'è.
local function bozza(c, id)
  if not uv.fs_stat(bozza_file(c, id)) then return nil end
  local ok, d = pcall(vim.json.decode, leggi(bozza_file(c, id)))
  return ok and d or nil
end

-- Le righe della bozza su disco; una prova che si aspetta una bozza e non la trova cade qui, con la sua frase.
local function righe_bozza(c, id)
  local b = bozza(c, id)
  vero(b, 'nessuna bozza in ' .. bozza_file(c, id))
  return b.righe
end

-- Le funzioni di vivo che servono alla prova ci sono (altrimenti la prova cadrebbe con «attempt to call»).
local function ha(F, nome)
  vero(F:lua('return type(require("dattilo.vivo")[...])', nome) == 'function', 'manca vivo.' .. nome)
end

local function nil_se_vuoto(r) if r == vim.NIL then return nil end return r end
local function id(F) return nil_se_vuoto(F:lua('local s = require("dattilo.lezione").s return s and s.L.id')) end
local function passo(F) return nil_se_vuoto(F:lua('local s = require("dattilo.lezione").s return s and s.passo')) end
local function titolo(F) local r = F:riquadro() return r and r.titolo end
local function cursore(F) return F:lua('return vim.api.nvim_win_get_cursor(0)') end

local function briefing(F)
  F:aspetta(function() local r = F:riquadro() return r ~= nil and r.titolo:find('^COMINCIA') ~= nil end)
end

-- Da briefing a Batti, con il testo scritto in INSERT (`finale` = '<Esc>' per uscirne).
local function in_batti(F)
  briefing(F)
  F:input('<CR>')
  uguale(passo(F), 'batti')
end

-- Si aspetta di essere in Batti con la bozza rimessa, senza passare dal briefing.
local function ripresa(F, righe)
  vero(F:aspetta(function() return passo(F) == 'batti' end), 'non in Batti: ' .. tostring(passo(F)))
  uguale(F:righe(), righe)
end

local function con(fn, prepara, o)
  local c = M.cartella()
  if prepara then prepara(c) end
  local opz = vim.tbl_extend('force', { cartella = c, vivo = true }, o or {})
  local ok, err = xpcall(M.con, debug.traceback, opz, function(F) fn(F, c) end)
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

local function con_tre(c)
  assert(uv.fs_copyfile(lezioni_dir(c) .. '/002-saluto.md', lezioni_dir(c) .. '/003-x.md'))
end

local function esce(F)
  vim.rpcnotify(F.canale, 'nvim_input', '<CR>')
  return vim.fn.jobwait({ F.canale }, 3000)[1] == 0
end

---------------------------------------------------------------- si scrive

T['la bozza si scrive mentre si scrive'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunction somma(a, b) {<CR>if (ty')
    vero(F:aspetta(function() return bozza(c) ~= nil end, 2500), 'nessuna bozza dopo 2500 ms')
    uguale(bozza(c), { v = 1, passo = 'batti', righe = DUE })
    uguale(uv.fs_stat(bozza_file(c)).mode % 512, 384, 'il file non è a 0600')
    uguale(uv.fs_stat(c .. '/bozze').mode % 512, 448, 'bozze/ non è a 0700')
    -- ancora in INSERT: il testo è quello, e nessun file temporaneo resta
    uguale(F:modo(), 'i')
    uguale(vim.fn.readdir(c .. '/bozze'), { '001-somma.json' })
  end)
end

T['una bozza si salva solo se le righe sono cambiate, e non più di una ogni 2 secondi'] = function()
  con(function(F, c)
    in_batti(F)
    F:lua([[
      _G.scritture = 0
      local orig = vim.uv.fs_rename
      vim.uv.fs_rename = function(da, a)
        if a:find('bozze/001-somma.json', 1, true) then _G.scritture = _G.scritture + 1 end
        return orig(da, a)
      end]])
    F:input('ifunc')
    -- si continua a scrivere per più di un secondo: una sola scrittura
    for _, pezzo in ipairs({ 't', 'i', 'o', 'n' }) do
      vim.wait(350)
      F:input(pezzo)
    end
    uguale(F:lua('return _G.scritture'), 1)
    -- ferma, senza cambiare niente: non si riscrive
    vero(F:aspetta(function() return bozza(c) ~= nil and righe_bozza(c)[1] == 'function' end, 3500), vim.inspect(bozza(c)))
    local n = F:lua('return _G.scritture')
    vim.wait(2700)
    uguale(F:lua('return _G.scritture'), n, 'riscritta senza cambiamenti')
    -- un cambiamento: si riscrive entro 2 s
    F:input(' ')
    vero(F:aspetta(function() return F:lua('return _G.scritture') == n + 1 end, 2700), 'non riscritta')
  end)
end

T['uscendo dalla scrittura si salva subito, anche con Ctrl-c'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunc<Esc>')
    uguale(righe_bozza(c), { 'func' })
    F:input('A')
    F:input('t')
    -- (Ctrl-c in un colpo solo con le lettere scarterebbe i tasti già in coda)
    F:input('<C-c>')
    uguale(F:modo(), 'n')
    uguale(righe_bozza(c), { 'funct' })
  end)
end

T['lasciando la lezione si salva subito'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunction somma(a, b) {<CR>if (ty<Esc>')
    uguale(righe_bozza(c), DUE)
    -- un cambiamento in NORMAL non cambia il modo: ci pensa lasciare la lezione (:ultima)
    F:input('x')
    uguale(F:righe()[2], '    if (t')
    F:input(':ultima<CR>')
    vero(F:aspetta(function() return id(F) == '003-x' end), tostring(id(F)))
    uguale(righe_bozza(c), { 'function somma(a, b) {', '    if (t' })
  end, con_tre)
end

---------------------------------------------------------------- si rimette

-- Review Focus 5: il pannello chiuso di colpo a metà riga. Le prove ovvie escono con :q.
T['chiuso di colpo a metà: riaprendo il testo c è'] = function()
  local c = M.cartella()
  local ok, err = xpcall(function()
    local F = M.avvia({ cartella = c, vivo = true })
    in_batti(F)
    F:input('ifunction somma(a, b) {<CR>if (ty')
    -- la bozza di adesso, scritta dal tempo
    vero(F:aspetta(function() return bozza(c) ~= nil end, 2500))
    uguale(righe_bozza(c), DUE)
    -- altro testo, e subito la chiusura: ci pensa VimLeavePre (il tempo non riscrive prima di 2 s)
    F:input('peof a')
    F:chiudi()
    uguale(righe_bozza(c), { 'function somma(a, b) {', '    if (typeof a' })
    -- un figlio nuovo sulla stessa cartella: dritto a Batti, senza briefing, col testo di prima
    M.con({ cartella = c, vivo = true }, function(F2)
      ripresa(F2, { 'function somma(a, b) {', '    if (typeof a' })
      uguale(passo(F2), 'batti')
      uguale(F2:modo(), 'n')
      uguale(cursore(F2), { 2, #'    if (typeof a' - 1 })
      local r = F2:riquadro()
      uguale(r.sezioni.Controllo, TT.ripreso)
      uguale(r.sezioni.Adesso, TT.batti_riprendi)
      uguale(r.titolo:sub(1, #'SCRIVI · '), 'SCRIVI · ')
      -- è davvero il testo: ‹A› e si continua senza rosso
      F2:input('A')
      F2:input(' !== "number") return 0;')
      uguale(F2:righe()[2], C1[2])
      uguale(F2:lua('return require("dattilo.batti").stato(require("dattilo.lezione").s.buf).errori'), 0)
      -- «Ripreso» vale solo finché non si scrive
      uguale(F2:riquadro().sezioni.Controllo, nil)
      -- e lo stato dice Batti
      vero(F2:aspetta(function() return stato_json(c).schermo == 'batti' end, 2000), leggi(c .. '/stato.json'))
    end)
  end, debug.traceback)
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

T[':ultima e ritorno: il testo resta'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunction somma(a, b) {<CR>if (ty<Esc>')
    F:input(':ultima<CR>')
    vero(F:aspetta(function() return id(F) == '003-x' and passo(F) == 'briefing' end), tostring(id(F)))
    -- dall'elenco, la prima: la 001
    F:input(':elenco<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
    F:input('<CR>')
    vero(F:aspetta(function() return id(F) == '001-somma' end))
    ripresa(F, DUE)
    uguale(F:riquadro().sezioni.Controllo, TT.ripreso)
    uguale(F:riquadro().sezioni.Adesso, TT.batti_riprendi)
  end, con_tre)
end

T[':q e ritorno: il testo resta, e :qa non lo perde'] = function()
  local c = M.cartella()
  local ok, err = xpcall(function()
    M.con({ cartella = c, vivo = true }, function(F)
      in_batti(F)
      F:input('ifunction somma(a, b) {<CR>if (ty<Esc>x')
      F:input(':q<CR>')
      vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
      uguale(righe_bozza(c), { 'function somma(a, b) {', '    if (t' })
      F:input('<CR>')
      vero(F:aspetta(function() return id(F) == '001-somma' end))
      ripresa(F, { 'function somma(a, b) {', '    if (t' })
      -- :qa chiude dattilo del tutto, e il testo c'è lo stesso
      F:input('A')
      F:input('ypeof a<Esc>:qa')
      vero(esce(F), 'il figlio non è uscito')
    end)
    M.con({ cartella = c, vivo = true }, function(F)
      ripresa(F, { 'function somma(a, b) {', '    if (typeof a' })
    end)
  end, debug.traceback)
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

-- Il caso lasciato dal compito 7 (bloccante per il rilascio): una richiesta della mod cambia lezione
-- mentre si scrive. Il testo non si perde: riaprendo la lezione c'è.
T['richiesta apri da vuoi.json con testo in Batti: riaprendo la lezione, il testo c è'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunction somma(a, b) {<CR>if (ty<Esc>')
    vuoi(c, { t = 10, azione = 'apri', lezione = '002-saluto' })
    vero(F:aspetta(function() return id(F) == '002-saluto' end, 1500), tostring(id(F)))
    uguale(righe_bozza(c), DUE)
    vuoi(c, { t = 11, azione = 'apri', lezione = '001-somma' })
    vero(F:aspetta(function() return id(F) == '001-somma' end, 1500), tostring(id(F)))
    ripresa(F, DUE)
  end)
end

T['richiesta ultima da vuoi.json mentre si scrive in INSERT: il testo c è'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunction somma(a, b) {<CR>if (ty')
    uguale(F:modo(), 'i')
    vuoi(c, { t = 10, azione = 'ultima' })
    vero(F:aspetta(function() return id(F) == '003-x' end, 1500), tostring(id(F)))
    uguale(F:modo(), 'n')
    uguale(righe_bozza(c), DUE)
    vuoi(c, { t = 11, azione = 'apri', lezione = '001-somma' })
    vero(F:aspetta(function() return id(F) == '001-somma' end, 1500), tostring(id(F)))
    ripresa(F, DUE)
  end, con_tre)
end

T[':e! ricomincia da capo e non rimette la bozza'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunction somma(a, b) {<CR>if (ty<Esc>:q<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
    F:input('<CR>')
    ripresa(F, DUE)
    F:input(':e!<CR>')
    uguale(passo(F), 'batti')
    uguale(F:righe(), { '' })
    -- il buffer è vuoto: lasciando la lezione la bozza si toglie, e riaprendo si ricomincia dal briefing
    F:input(':q<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
    uguale(bozza(c), nil)
    F:input('<CR>')
    vero(F:aspetta(function() return id(F) == '001-somma' end))
    uguale(passo(F), 'briefing')
  end)
end

T['un buffer tornato vuoto non lascia una bozza vecchia'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('ifunc<Esc>')
    uguale(righe_bozza(c), { 'func' })
    F:input('dd')
    F:input(':q<CR>')
    vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
    uguale(bozza(c), nil)
  end)
end

T['lezione fatta: la bozza sparisce'] = function()
  con(function(F, c)
    in_batti(F)
    F:input('i')
    for i, l in ipairs(C1) do
      F:input((vim.trim(l):gsub('<', '<lt>')))
      if i < #C1 then F:input('<CR>') end
    end
    F:input('<Esc>')
    uguale(righe_bozza(c), C1)
    F:input(':w<CR>')
    vero(F:aspetta(function() return passo(F) == 'spiegazione' end))
    F:input('<CR>')
    vero(F:aspetta(function() return passo(F) == 'fine' end))
    uguale(bozza(c), nil)
    -- il tempo non la rimette: non si è più in Batti
    vim.wait(2700)
    uguale(bozza(c), nil)
  end)
end

T['alla chiusura anche stato.json è aggiornato'] = function()
  local c = M.cartella()
  local ok, err = xpcall(function()
    con_tre(c)
    local F = M.avvia({ cartella = c, vivo = true })
    briefing(F)
    F:input(':ultima<CR>')
    -- subito, prima che giri il tempo: aperte dice la 003 solo se la chiusura riscrive stato.json
    F:chiudi()
    uguale(stato_json(c).aperte, { '001-somma', '003-x' })
  end, debug.traceback)
  vim.fn.delete(c, 'rf')
  if not ok then error(err, 0) end
end

---------------------------------------------------------------- bozze rovinate e collegamenti

-- Una bozza che non è fatta bene non si legge: si parte dal briefing, senza errori.
T['una bozza rovinata non si legge'] = function()
  local casi = {
    ['non è JSON'] = 'qui non c\'è niente',
    ['v diversa'] = '{"v":2,"passo":"batti","righe":["func"]}',
    ['righe non è una lista'] = '{"v":1,"passo":"batti","righe":"func"}',
    ['una riga non è una stringa'] = '{"v":1,"passo":"batti","righe":["func",5]}',
    ['una riga con un a capo'] = '{"v":1,"passo":"batti","righe":["fu\\nnc"]}',
    ['nessuna riga'] = '{"v":1,"passo":"batti","righe":[]}',
    ['una riga vuota sola'] = '{"v":1,"passo":"batti","righe":[""]}',
    ['passo sconosciuto'] = '{"v":1,"passo":"altro","righe":["func"]}',
  }
  for nome, testo in pairs(casi) do
    con(function(F)
      ha(F, 'bozza_leggi')
      briefing(F)
      uguale(titolo(F), 'COMINCIA · somma', nome)
      uguale(passo(F), 'briefing', nome)
      uguale(F:lua('return require("dattilo.vivo").bozza_leggi("001-somma")') == vim.NIL, true, nome)
      uguale(F:messaggi():find('E%d+'), nil, nome)
    end, function(c)
      vim.fn.mkdir(c .. '/bozze', 'p', tonumber('700', 8))
      vim.fn.writefile({ testo }, bozza_file(c))
    end)
  end
end

-- La Modifica è del tempo B: oggi una bozza della Modifica non si riprende, si parte dal briefing.
T['una bozza della Modifica oggi non si riprende'] = function()
  con(function(F)
    briefing(F)
    uguale(passo(F), 'briefing')
  end, function(c)
    vim.fn.mkdir(c .. '/bozze', 'p', tonumber('700', 8))
    vim.fn.writefile({ '{"v":1,"passo":"modifica","righe":["func"]}' }, bozza_file(c))
  end)
end

T['bozza troppo grande non si legge'] = function()
  con(function(F)
    briefing(F)
    uguale(passo(F), 'briefing')
  end, function(c)
    vim.fn.mkdir(c .. '/bozze', 'p', tonumber('700', 8))
    local riga = string.rep('x', 1000)
    local righe = {}
    for i = 1, 400 do righe[i] = riga end
    vim.fn.writefile({ vim.json.encode({ v = 1, passo = 'batti', righe = righe }) }, bozza_file(c))
  end)
end

-- Il file della bozza è un collegamento a un file fuori: non si legge (anche se è una bozza giusta),
-- e scrivendo si sostituisce il collegamento senza seguirlo.
T['bozza col file link: non si legge e non si scrive'] = function()
  local fuori = vim.fn.tempname()
  vim.fn.mkdir(fuori, 'p', tonumber('700', 8))
  local bersaglio = fuori .. '/bozza.json'
  local ok, err = xpcall(function()
    con(function(F, c)
      ha(F, 'bozza_leggi')
      -- non si legge: briefing e non Batti col testo del bersaglio
      briefing(F)
      uguale(passo(F), 'briefing')
      uguale(F:lua('return require("dattilo.vivo").bozza_leggi("001-somma")') == vim.NIL, true)
      -- non si scrive nel bersaglio: scrivendo, il collegamento è sostituito da un file vero
      F:input('<CR>')
      F:input('ifunc<Esc>')
      uguale(uv.fs_lstat(bozza_file(c)).type, 'file')
      uguale(righe_bozza(c), { 'func' })
      uguale(leggi(bersaglio), vim.json.encode({ v = 1, passo = 'batti', righe = { 'testo del bersaglio' } }))
    end, function(c)
      vim.fn.writefile({ vim.json.encode({ v = 1, passo = 'batti', righe = { 'testo del bersaglio' } }) }, bersaglio)
      vim.fn.mkdir(c .. '/bozze', 'p', tonumber('700', 8))
      assert(uv.fs_symlink(bersaglio, bozza_file(c)))
    end)
  end, debug.traceback)
  vim.fn.delete(fuori, 'rf')
  if not ok then error(err, 0) end
end

T['bozze/ collegamento a una cartella fuori: bozza_salva non scrive'] = function()
  local fuori = vim.fn.tempname()
  vim.fn.mkdir(fuori, 'p', tonumber('700', 8))
  local ok, err = xpcall(function()
    con(function(F, c)
      ha(F, 'bozza_salva')
      briefing(F)
      F:input('<CR>')
      F:input('ifunc<Esc>')
      F:lua('require("dattilo.vivo").bozza_salva("001-somma")')
      vim.wait(2700)
      uguale(vim.fn.readdir(fuori), {})
      uguale(F:lua('return require("dattilo.vivo").dir_bozze()') == vim.NIL, true)
      -- e si può continuare: nessun errore, il testo è lì
      uguale(F:righe(), { 'func' })
      uguale(F:messaggi():find('E%d+'), nil)
      -- e senza bozza non si riprende: lasciata e riaperta, la lezione riparte dal briefing
      F:input(':q<CR>')
      vero(F:aspetta(function() return titolo(F) == TT.titoli.elenco end))
      F:input('<CR>')
      vero(F:aspetta(function() return id(F) == '001-somma' end))
      uguale(passo(F), 'briefing')
    end, function(c) assert(uv.fs_symlink(fuori, c .. '/bozze')) end)
  end, debug.traceback)
  vim.fn.delete(fuori, 'rf')
  if not ok then error(err, 0) end
end

T['bozza_togli su un collegamento toglie il collegamento, non il bersaglio'] = function()
  local fuori = vim.fn.tempname()
  vim.fn.mkdir(fuori, 'p', tonumber('700', 8))
  local bersaglio = fuori .. '/bozza.json'
  local ok, err = xpcall(function()
    con(function(F, c)
      ha(F, 'bozza_togli')
      briefing(F)
      F:lua('require("dattilo.vivo").bozza_togli("001-somma")')
      uguale(uv.fs_lstat(bozza_file(c)), nil)
      uguale(vim.fn.filereadable(bersaglio), 1)
    end, function(c)
      vim.fn.writefile({ 'bersaglio' }, bersaglio)
      vim.fn.mkdir(c .. '/bozze', 'p', tonumber('700', 8))
      assert(uv.fs_symlink(bersaglio, bozza_file(c)))
    end)
  end, debug.traceback)
  vim.fn.delete(fuori, 'rf')
  if not ok then error(err, 0) end
end

T['id fuori dal modello: la bozza non si legge né si toglie'] = function()
  con(function(F)
    ha(F, 'bozza_leggi')
    briefing(F)
    for _, x in ipairs({ '../x', 'x', '001-a/../../x' }) do
      uguale(F:lua('return require("dattilo.vivo").bozza_leggi(...)', x) == vim.NIL, true, x)
    end
  end)
end

---------------------------------------------------------------- i testi dicono la verità

-- La bozza c'è: ora :q e :qa dicono che il testo resta, e lo fa.
T['i testi di :q e :qa dicono che il testo resta'] = function()
  local S = TT.spiega_comando
  vero(S.q_scritto:find('resta salvata', 1, true), S.q_scritto)
  vero(S.q_esci:find('quello che hai scritto resta', 1, true), S.q_esci)
  vero(S.qa_scritto:find('resta salvato', 1, true), S.qa_scritto)
  vero(TT.comandi_batti:find('resta salvata', 1, true), TT.comandi_batti)
  vero(TT.comandi_elenco:find('quello che hai scritto resta', 1, true) and TT.comandi_elenco:find('lo riapre', 1, true), TT.comandi_elenco)
  vero(TT.errore_dattilo:find('è salvato', 1, true), TT.errore_dattilo)
  for nome, v in pairs(S) do vero(not v:find('non si conserva', 1, true), nome .. ': ' .. v) end
  vero(not TT.comandi_batti:find('non si conserva', 1, true), TT.comandi_batti)
end

return T
