-- Il canale di «Rifallo tu»: vuoi.json (cosa chiede l'app), stato.json (cosa risponde dattilo), la
-- coda delle lezioni e il controllo della cartella ogni 500 ms. Le prove girano con `nvim -l`, tranne
-- l'ultima, che usa un Neovim figlio per vedere il timer vero.
local T = {}
local vivo = require('dattilo.vivo')
local lezione = require('dattilo.lezione')
local pacchetti = require('dattilo.pacchetti')
local guida = require('dattilo.guida')
local M = dofile(RADICE .. '/tests/vivo_figlio.lua')
local uv = vim.uv

local function lezioni_dir(c) return c .. '/dati/dattilo/pacchetti/rifallo/lezioni' end

local function scrivi(percorso, testo) vim.fn.writefile({ testo }, percorso) end

local function leggi(percorso) return table.concat(vim.fn.readfile(percorso), '\n') end

-- vuoi.json come lo scrive la mod: un file nuovo e poi il rename
local function vuoi(c, campi)
  local tmp = c .. '/vuoi.json.tmp'
  scrivi(tmp, vim.json.encode(vim.tbl_extend('force', { v = 1 }, campi)))
  assert(uv.fs_rename(tmp, c .. '/vuoi.json'))
end

local function stato_json(c)
  return vim.json.decode(leggi(c .. '/stato.json'), { luanil = { object = true, array = true } })
end

local function copia_lezione(c, da, a) assert(uv.fs_copyfile(lezioni_dir(c) .. '/' .. da, lezioni_dir(c) .. '/' .. a)) end

local function aperta() return lezione.s and lezione.s.L.id end

-- Il testo di una sezione dell'ultimo riquadro della guida.
local function sezione(etichetta)
  local r = guida.ultimo()
  for _, sz in ipairs(r and r.sezioni or {}) do if sz.etichetta == etichetta then return sz.testo end end
end

-- Una cartella finta (due lezioni lette senza errori) con l'ambiente di dattilo puntato su `dati`.
-- `prepara(c)` la cambia prima di cominciare e può rendere altre cartelle da cancellare alla fine.
-- Alla fine, anche se la prova fallisce, rimette tutto com'era: la guida spenta, il timer fermo,
-- la lezione chiusa, le spie tolte.
local function con(fn, prepara)
  local c = M.cartella()
  local altre = prepara and prepara(c) or {}
  local stato = require('dattilo.stato')
  local prima = { xdg = vim.env.XDG_DATA_HOME, stato = vim.deepcopy(stato), apri = lezione.apri, open = uv.fs_open }
  vim.env.XDG_DATA_HOME = c .. '/dati'
  pacchetti.dimentica()
  local ok, err = xpcall(fn, debug.traceback, c)
  vivo.ferma()
  lezione.chiudi()
  require('dattilo.ui').chiudi_tip()
  lezione.apri, uv.fs_open = prima.apri, prima.open
  vim.env.XDG_DATA_HOME = prima.xdg
  for k in pairs(stato) do stato[k] = nil end
  for k, v in pairs(prima.stato) do stato[k] = v end
  pacchetti.dimentica()
  vim.fn.delete(c, 'rf')
  for _, d in ipairs(altre) do vim.fn.delete(d, 'rf') end
  if not ok then error(err, 0) end
end

local function lezioni(ids)
  local l = {}
  for _, id in ipairs(ids) do l[#l + 1] = { id = id } end
  return { lezioni = l }
end

---------------------------------------------------------------- la coda

local IDS = { '001-somma', '002-saluto', '003-nome', '004-file', '005-azioni' }

T['coda: nuove dopo la corrente, senza fatte e saltate'] = function()
  uguale(vivo.coda(lezioni(IDS), '003-nome', { ['001-somma'] = true }, { ['004-file'] = true }),
    { nuove = 1, prossima = '005-azioni', ultima = '005-azioni' })
  uguale(vivo.coda(lezioni(IDS), nil, { ['001-somma'] = true }, { ['004-file'] = true }),
    { nuove = 3, prossima = '002-saluto', ultima = '005-azioni' })
end

T['coda: la corrente sparita, gli id fuori modello e le lezioni finite'] = function()
  -- il file della corrente non c'è più: «dopo» vale per il suo id
  uguale(vivo.coda(lezioni({ '001-a', '003-c', '004-d' }), '002-b', {}, {}), { nuove = 2, prossima = '003-c', ultima = '004-d' })
  -- un id fuori dal modello non entra mai in coda
  uguale(vivo.coda(lezioni({ '001-a', 'nota', '../x', '002-b' }), nil, {}, {}), { nuove = 2, prossima = '001-a', ultima = '002-b' })
  -- tutte fatte: niente da fare
  uguale(vivo.coda(lezioni({ '001-a', '002-b' }), '002-b', { ['001-a'] = true, ['002-b'] = true }, {}), { nuove = 0 })
  -- una saltata e non fatta è ancora «l'ultima» di :ultima
  uguale(vivo.coda(lezioni({ '001-a', '002-b', '003-c' }), nil, { ['001-a'] = true, ['003-c'] = true }, { ['002-b'] = true }),
    { nuove = 0, ultima = '002-b' })
  -- senza pacchetto: niente, senza errori
  uguale(vivo.coda(nil, nil, {}, {}), { nuove = 0 })
end

---------------------------------------------------------------- vuoi.json

T['vuoi apri: si esegue una volta sola'] = function()
  con(function(c)
    vivo.avvia(c)
    uguale(aperta(), '001-somma')
    local aperture, orig = 0, lezione.apri
    lezione.apri = function(...) aperture = aperture + 1 return orig(...) end
    vuoi(c, { t = 100, azione = 'apri', lezione = '002-saluto', dalvivo = 'acceso' })
    vivo.controlla()
    uguale(aperta(), '002-saluto')
    uguale(aperture, 1)
    vivo.controlla()
    uguale(aperture, 1, 'lo stesso file non si riesegue')
    -- riscritto con lo stesso t: la richiesta non è più nuova
    vuoi(c, { t = 100, azione = 'apri', lezione = '001-somma', dalvivo = 'acceso' })
    vivo.controlla()
    -- con un t più vecchio, niente
    vuoi(c, { t = 50, azione = 'apri', lezione = '001-somma', dalvivo = 'acceso' })
    vivo.controlla()
    uguale(aperta(), '002-saluto')
    uguale(aperture, 1)
    uguale(stato_json(c).eseguita, 100)
    -- uno più nuovo sì
    vuoi(c, { t = 101, azione = 'apri', lezione = '001-somma', dalvivo = 'acceso' })
    vivo.controlla()
    uguale(aperta(), '001-somma')
    uguale(aperture, 2)
    uguale(stato_json(c).eseguita, 101)
  end)
end

T['vuoi a metà, poi intero'] = function()
  con(function(c)
    vivo.avvia(c)
    local letture, orig = 0, uv.fs_open
    uv.fs_open = function(p, ...)
      if tostring(p):find('vuoi.json', 1, true) then letture = letture + 1 end
      return orig(p, ...)
    end
    local messaggi = vim.api.nvim_exec2('messages', { output = true }).output
    -- il file scritto a pezzi: la mod lo scrive con un rename, ma dattilo non deve fidarsene
    scrivi(c .. '/vuoi.json', '{"v":1,"t":')
    vivo.controlla()
    uguale(aperta(), '001-somma')
    vivo.controlla()
    uguale(letture, 2, 'il file rotto si rilegge al giro dopo anche se non cambia')
    vero(not vim.inspect(guida.ultimo()):find('Errore di dattilo', 1, true), vim.inspect(guida.ultimo()))
    uguale(vim.api.nvim_exec2('messages', { output = true }).output, messaggi, 'niente errori a schermo')
    vuoi(c, { t = 100, azione = 'apri', lezione = '002-saluto' })
    vivo.controlla()
    uguale(aperta(), '002-saluto')
    uguale(letture, 3)
    vivo.controlla()
    uguale(letture, 3, 'il file letto bene non si rilegge finché non cambia')
  end)
end

T['vuoi con campi sbagliati: si ignora e si rilegge'] = function()
  con(function(c)
    vivo.avvia(c)
    local cattivi = {
      '{"v":2,"t":100,"azione":"apri","lezione":"002-saluto"}',
      '{"v":1,"t":"100","azione":"apri","lezione":"002-saluto"}',
      '{"v":1,"t":100.5,"azione":"apri","lezione":"002-saluto"}',
      '{"v":1,"t":100,"azione":7,"lezione":"002-saluto"}',
      '{"v":1,"t":100,"azione":"apri","lezione":7}',
      '{"v":1,"t":100,"azione":"apri"}',
      '{"v":1,"azione":"apri","lezione":"002-saluto"}',
      '{"v":1,"t":100,"azione":"ultima","dalvivo":3}',
      '[1,2]', '"testo"', 'null', '', '{}',
    }
    local messaggi = vim.api.nvim_exec2('messages', { output = true }).output
    for _, testo in ipairs(cattivi) do
      scrivi(c .. '/vuoi.json', testo)
      vivo.controlla()
      uguale(aperta(), '001-somma', testo)
      uguale(stato_json(c).eseguita, 0, testo)
    end
    uguale(vim.api.nvim_exec2('messages', { output = true }).output, messaggi)
    vero(not vim.inspect(guida.ultimo()):find('Errore di dattilo', 1, true))
    -- lo stesso file, giusto, funziona: era il campo a fermarlo
    scrivi(c .. '/vuoi.json', '{"v":1,"t":100,"azione":"apri","lezione":"002-saluto"}')
    vivo.controlla()
    uguale(aperta(), '002-saluto')
  end)
end

T['id fuori modello e link: si ignorano'] = function()
  con(function(c)
    vivo.avvia(c)
    for i, id in ipairs({ '../x', '002-saluto/../001-somma', '002-SALUTO', '2-saluto', '002-saluto.md', '002_saluto', '' }) do
      vuoi(c, { t = 100 + i, azione = 'apri', lezione = id })
      vivo.controlla()
      uguale(aperta(), '001-somma', 'id: ' .. id)
    end
    -- un id fatto bene ma che non c'è: niente, e nessuno è buttato fuori dalla sua lezione
    vuoi(c, { t = 200, azione = 'apri', lezione = '099-manca' })
    vivo.controlla()
    uguale(aperta(), '001-somma')

    -- vuoi.json è un collegamento a un file fuori dalla cartella, con una richiesta valida
    local fuori = vim.fn.tempname() .. '.json'
    local richiesta = vim.json.encode({ v = 1, t = 999, azione = 'apri', lezione = '002-saluto' })
    scrivi(fuori, richiesta)
    uv.fs_unlink(c .. '/vuoi.json')
    assert(uv.fs_symlink(fuori, c .. '/vuoi.json'))
    vivo.controlla()
    uguale(aperta(), '001-somma', 'un collegamento non si segue')
    -- la stessa richiesta come file vero si esegue: era il collegamento a fermarla
    uv.fs_unlink(c .. '/vuoi.json')
    scrivi(c .. '/vuoi.json', richiesta)
    vivo.controlla()
    uguale(aperta(), '002-saluto')
    vim.fn.delete(fuori)

    -- bozze è un collegamento a una cartella fuori: non si scrive lì
    local altro = vim.fn.tempname()
    vim.fn.mkdir(altro, 'p')
    assert(uv.fs_symlink(altro, c .. '/bozze'))
    uguale(vivo.dir_bozze(), nil)
    uguale(vim.fn.readdir(altro), {})
    -- e se è un file qualunque, lo stesso
    uv.fs_unlink(c .. '/bozze')
    scrivi(c .. '/bozze', 'non sono una cartella')
    uguale(vivo.dir_bozze(), nil)
    uv.fs_unlink(c .. '/bozze')
    -- senza il collegamento la cartella si crea, a 0700
    local d = vivo.dir_bozze()
    uguale(d, c .. '/bozze')
    uguale(uv.fs_stat(d).mode % 512, 448)
    vim.fn.delete(altro, 'rf')

    -- un file di bozza che è un collegamento: non si legge, e scrivendo lo si sostituisce senza seguirlo
    local bersaglio = vim.fn.tempname()
    scrivi(bersaglio, 'originale')
    assert(uv.fs_symlink(bersaglio, d .. '/001-somma.json'))
    uguale(vivo.leggi_sicuro(d .. '/001-somma.json', 1000), nil)
    vero(vivo.scrivi_atomico(d .. '/001-somma.json', 'nuovo'))
    uguale(leggi(bersaglio), 'originale', 'il bersaglio del collegamento non si tocca')
    uguale(uv.fs_lstat(d .. '/001-somma.json').type, 'file')
    uguale(uv.fs_stat(d .. '/001-somma.json').mode % 512, 384)
    uguale(vivo.leggi_sicuro(d .. '/001-somma.json', 1000), 'nuovo')
    vim.fn.delete(bersaglio)
  end)
end

T['vuoi.json: una cartella o un file enorme si ignorano'] = function()
  con(function(c)
    vivo.avvia(c)
    local richiesta = vim.json.encode({ v = 1, t = 100, azione = 'apri', lezione = '002-saluto' })
    vim.fn.mkdir(c .. '/vuoi.json')
    vivo.controlla()
    uguale(aperta(), '001-somma')
    vim.fn.delete(c .. '/vuoi.json', 'd')
    -- la richiesta buona, ma in un file di 200 mila spazi
    scrivi(c .. '/vuoi.json', string.rep(' ', 200000) .. richiesta)
    vivo.controlla()
    uguale(aperta(), '001-somma', 'un file troppo grande non si legge')
    scrivi(c .. '/vuoi.json', richiesta)
    vivo.controlla()
    uguale(aperta(), '002-saluto')
  end)
end

T['vuoi ultima: apre l\'ultima non fatta, e non rifà quella aperta'] = function()
  con(function(c)
    vivo.avvia(c)
    require('dattilo.progressi').registra('rifallo/001-somma', { wpm = 10 })
    local aperture, orig = 0, lezione.apri
    lezione.apri = function(...) aperture = aperture + 1 return orig(...) end
    vuoi(c, { t = 10, azione = 'ultima' })
    vivo.controlla()
    uguale(aperta(), '002-saluto')
    uguale(aperture, 1)
    uguale(stato_json(c).fatte, { '001-somma' })
    -- l'ultima è già quella aperta: non si ricomincia da capo
    vuoi(c, { t = 11, azione = 'ultima' })
    vivo.controlla()
    uguale(aperture, 1)
    uguale(stato_json(c).eseguita, 11)
  end)
end

---------------------------------------------------------------- la cartella delle lezioni

T['lezione nuova durante Batti: nuove sale, la corrente non si tocca'] = function()
  con(function(c)
    vivo.avvia(c)
    local s = lezione.s
    lezione.batti(s)
    vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, { 'func' })
    uguale(stato_json(c).nuove, 1)
    copia_lezione(c, '002-saluto.md', '003-x.md')
    vivo.controlla()
    local st = stato_json(c)
    uguale({ st.nuove, st.lezione, st.schermo, st.prossima, st.ultima }, { 2, '001-somma', 'batti', '002-saluto', '003-x' })
    uguale(vim.api.nvim_buf_get_lines(s.buf, 0, -1, false), { 'func' })
    vero(lezione.s == s, 'la lezione aperta è la stessa')
    vero(vim.endswith(require('dattilo.stato').destra, ' · 2 nuove'), require('dattilo.stato').destra)
  end)
end

T['lezione rotta in mezzo: non conta e non sposta gli id'] = function()
  con(function(c)
    vivo.avvia(c)
    -- 002-rotta: l'intestazione c'è, il blocco Batti no
    vim.fn.writefile({ '---', 'titolo: "Rotta"', 'breve: "rotta"', 'etichetta: "Rifallo tu"', 'file: "r.js"', 'fonte: "x"', 'tempo: "1 minuto"', '---', '',
      '## Spiegazione', '1: Niente. | Niente.' }, lezioni_dir(c) .. '/002-rotta.md')
    copia_lezione(c, '001-somma.md', '003-x.md')
    vivo.controlla()
    local st = stato_json(c)
    uguale({ st.nuove, st.prossima, st.ultima }, { 2, '002-saluto', '003-x' })
    vuoi(c, { t = 1, azione = 'apri', lezione = '003-x' })
    vivo.controlla()
    uguale(aperta(), '003-x')
    -- le lezioni vive sono 001, 002-saluto, 003-x: la rotta non è una di loro
    uguale({ stato_json(c).nuove, stato_json(c).prossima }, { 0, nil })
  end)
end

T['una lezione che è un collegamento non entra in coda e non si apre'] = function()
  con(function(c)
    vivo.avvia(c)
    local fuori = vim.fn.tempname() .. '.md'
    assert(uv.fs_copyfile(lezioni_dir(c) .. '/002-saluto.md', fuori))
    assert(uv.fs_symlink(fuori, lezioni_dir(c) .. '/003-link.md'))
    vivo.controlla()
    local st = stato_json(c)
    uguale({ st.nuove, st.prossima, st.ultima }, { 1, '002-saluto', '002-saluto' })
    vuoi(c, { t = 1, azione = 'apri', lezione = '003-link' })
    vivo.controlla()
    uguale(aperta(), '001-somma')
    -- chiamata a mano, `apri` lo rifiuta lo stesso: dice che non si apre e va all'elenco
    vivo.apri('003-link')
    uguale(aperta(), nil)
    vero(sezione('Controllo'):find('Questa lezione non si apre', 1, true), tostring(sezione('Controllo')))
    vim.fn.delete(fuori)
  end)
end

T['lezione rotta chiesta per id: dice perché e va all\'elenco'] = function()
  con(function(c)
    vivo.avvia(c)
    vim.fn.writefile({ '---', 'titolo: "Rotta"', 'breve: "rotta"', 'etichetta: "Rifallo tu"', 'file: "r.js"', 'fonte: "x"', 'tempo: "1 minuto"', '---', '',
      '## Spiegazione', '1: Niente. | Niente.' }, lezioni_dir(c) .. '/002-rotta.md')
    vivo.controlla()
    local P = pacchetti.carica_cartella(c .. '/dati/dattilo/pacchetti/rifallo')
    local errore = assert(P.errori[1], 'la lezione rotta non ha dato un errore').msg:gsub('%.$', '')
    vuoi(c, { t = 5, azione = 'apri', lezione = '002-rotta' })
    vivo.controlla()
    uguale(aperta(), nil)
    uguale(sezione('Controllo'), 'Questa lezione non si apre: ' .. errore .. '.')
    uguale(stato_json(c).schermo, 'elenco')
  end)
end

T['avvio con la richiesta di una lezione rotta: l\'elenco con l\'avviso, non la prima lezione'] = function()
  con(function(c)
    vuoi(c, { t = 5, azione = 'apri', lezione = '002-rotta' })
    vivo.avvia(c)
    uguale(aperta(), nil)
    vero(sezione('Controllo'):find('Questa lezione non si apre', 1, true), tostring(sezione('Controllo')))
    uguale(stato_json(c).schermo, 'elenco')
  end, function(c)
    vim.fn.writefile({ '---', 'titolo: "Rotta"', 'breve: "rotta"', 'etichetta: "Rifallo tu"', 'file: "r.js"', 'fonte: "x"', 'tempo: "1 minuto"', '---', '',
      '## Spiegazione', '1: Niente. | Niente.' }, lezioni_dir(c) .. '/002-rotta.md')
  end)
end

T['cartella vuota: attesa, e la prima lezione che arriva si apre da sola'] = function()
  con(function(c)
    vivo.avvia(c)
    uguale(aperta(), nil)
    uguale(require('dattilo.stato').file, 'attesa')
    local st = stato_json(c)
    uguale({ st.lezione, st.schermo, st.nuove, st.prossima, st.ultima }, { nil, 'attesa', 0, nil, nil })
    uguale(st.aperte, {})
    vero(not vim.inspect(guida.ultimo()):find('Errore di dattilo', 1, true))
    -- la lezione arriva: si apre da sola
    assert(uv.fs_copyfile(c .. '/pronte/001-somma.md', lezioni_dir(c) .. '/001-somma.md'))
    vivo.controlla()
    uguale(aperta(), '001-somma')
    st = stato_json(c)
    uguale({ st.lezione, st.schermo, st.nuove, st.aperte }, { '001-somma', 'briefing', 0, { '001-somma' } })
  end, function(c)
    vim.fn.mkdir(c .. '/pronte')
    for _, nome in ipairs({ '001-somma.md', '002-saluto.md' }) do
      assert(uv.fs_rename(lezioni_dir(c) .. '/' .. nome, c .. '/pronte/' .. nome))
    end
  end)
end

T['senza pacchetto né lezioni: coda vuota senza errori, poi la prima si apre da sola'] = function()
  con(function(c)
    vivo.avvia(c)
    vivo.controlla()
    uguale(aperta(), nil)
    uguale(stato_json(c).schermo, 'attesa')
    vero(not vim.inspect(guida.ultimo()):find('Errore di dattilo', 1, true))
    -- la mod prepara il pacchetto e la prima lezione
    vim.fn.mkdir(c .. '/dati/dattilo/pacchetti/rifallo/lezioni', 'p')
    assert(uv.fs_copyfile(c .. '/pronto/pacchetto.json', c .. '/dati/dattilo/pacchetti/rifallo/pacchetto.json'))
    assert(uv.fs_copyfile(c .. '/pronto/001-somma.md', lezioni_dir(c) .. '/001-somma.md'))
    vivo.controlla()
    uguale(aperta(), '001-somma')
  end, function(c)
    vim.fn.mkdir(c .. '/pronto')
    local d = c .. '/dati/dattilo/pacchetti/rifallo'
    assert(uv.fs_rename(d .. '/pacchetto.json', c .. '/pronto/pacchetto.json'))
    assert(uv.fs_rename(d .. '/lezioni/001-somma.md', c .. '/pronto/001-somma.md'))
    vim.fn.delete(c .. '/dati', 'rf')
  end)
end

T['dati fuori dalla cartella: attesa con l\'avviso'] = function()
  con(function(c)
    vivo.avvia(c)
    uguale(aperta(), nil)
    vero(sezione('Controllo'):find('la cartella dei dati non è dentro quella di Rifallo tu', 1, true), tostring(sezione('Controllo')))
    local st = stato_json(c)
    uguale({ st.lezione, st.schermo, st.nuove }, { nil, 'attesa', 0 })
    -- nemmeno una richiesta apre qualcosa
    vuoi(c, { t = 1, azione = 'apri', lezione = '001-somma' })
    vivo.controlla()
    vivo.controlla()
    uguale(aperta(), nil)
    -- il pacchetto di là c'è davvero: è la guardia a non aprirlo
    local P = pacchetti.carica_cartella(c .. '/dati/dattilo/pacchetti/rifallo')
    uguale(#P.lezioni, 2)
  end, function(c)
    local altro = vim.fn.tempname()
    vim.fn.mkdir(altro, 'p')
    assert(uv.fs_rename(c .. '/dati', altro .. '/dati'))
    assert(uv.fs_symlink(altro .. '/dati', c .. '/dati'))
    return { altro }
  end)
end

T['dati fuori: anche una cartella dattilo che è un collegamento'] = function()
  con(function(c)
    vivo.avvia(c)
    uguale(aperta(), nil)
    vero(sezione('Controllo'):find('la cartella dei dati non è dentro quella di Rifallo tu', 1, true), tostring(sezione('Controllo')))
  end, function(c)
    local altro = vim.fn.tempname()
    vim.fn.mkdir(altro, 'p')
    assert(uv.fs_rename(c .. '/dati/dattilo', altro .. '/dattilo'))
    assert(uv.fs_symlink(altro .. '/dattilo', c .. '/dati/dattilo'))
    return { altro }
  end)
end

---------------------------------------------------------------- stato.json

T['stato.json: 0600, atomico, riscritto solo se cambia'] = function()
  con(function(c)
    vivo.avvia(c)
    local prima = uv.fs_stat(c .. '/stato.json')
    uguale(prima.mode % 512, 384)
    local primo = stato_json(c)
    vim.wait(30)
    vivo.controlla()
    vivo.controlla()
    local dopo = uv.fs_stat(c .. '/stato.json')
    uguale({ dopo.ino, dopo.mtime.sec, dopo.mtime.nsec }, { prima.ino, prima.mtime.sec, prima.mtime.nsec }, 'senza novità non si riscrive')
    for nome in vim.fs.dir(c) do vero(not nome:find('^stato%.json%.'), 'è rimasto ' .. nome) end
    -- i campi, nell'ordine del contratto
    local chiavi = vim.tbl_keys(primo)
    table.sort(chiavi)
    uguale(chiavi, { 'aperte', 'eseguita', 'fatte', 'lezione', 'nuove', 'prossima', 'saltate', 'schermo', 't', 'ultima', 'v' })
    uguale({ primo.v, primo.lezione, primo.schermo, primo.nuove, primo.prossima, primo.ultima, primo.aperte, primo.fatte, primo.saltate, primo.eseguita },
      { 1, '001-somma', 'briefing', 1, '002-saluto', '002-saluto', { '001-somma' }, {}, {}, 0 })
    vero(leggi(c .. '/stato.json'):find('"fatte":[]', 1, true), 'le liste vuote sono [] e non {}')
    -- una lezione nuova: si riscrive, con un t più grande
    copia_lezione(c, '002-saluto.md', '003-x.md')
    vivo.controlla()
    local poi = uv.fs_stat(c .. '/stato.json')
    vero(poi.ino ~= prima.ino, 'cambiato qualcosa: si riscrive')
    vero(stato_json(c).t >= primo.t)
    uguale(stato_json(c).nuove, 2)
    for nome in vim.fs.dir(c) do vero(not nome:find('^stato%.json%.'), 'è rimasto ' .. nome) end
  end)
end

T['stato.json: un collegamento al suo posto si sostituisce senza seguirlo'] = function()
  con(function(c)
    local bersaglio = vim.fn.tempname()
    scrivi(bersaglio, 'non toccare')
    assert(uv.fs_symlink(bersaglio, c .. '/stato.json'))
    vivo.avvia(c)
    uguale(leggi(bersaglio), 'non toccare')
    uguale(uv.fs_lstat(c .. '/stato.json').type, 'file')
    uguale(stato_json(c).lezione, '001-somma')
    vim.fn.delete(bersaglio)
  end)
end

T['stato.json: lo schermo dice dove è la persona'] = function()
  con(function(c)
    vivo.avvia(c)
    uguale(stato_json(c).schermo, 'briefing')
    lezione.batti(lezione.s)
    vivo.controlla()
    uguale(stato_json(c).schermo, 'batti')
    for passo, schermo in pairs({ modifica = 'modifica', esegui = 'modifica', rompi = 'modifica', spiegazione = 'spiegazione', fine = 'fatto' }) do
      lezione.s.passo = passo
      vivo.controlla()
      uguale(stato_json(c).schermo, schermo, passo)
    end
    vivo.elenco()
    vivo.controlla()
    local st = stato_json(c)
    uguale({ st.schermo, st.lezione }, { 'elenco', nil })
  end)
end

T['stato.json: le fatte sono quelle di progressi.json'] = function()
  con(function(c)
    vivo.avvia(c)
    uguale(stato_json(c).fatte, {})
    require('dattilo.progressi').registra('rifallo/002-saluto', { wpm = 10 })
    require('dattilo.progressi').registra('rifallo/001-somma', { wpm = 10 })
    require('dattilo.progressi').registra('altro/009-x', { wpm = 10 })
    vivo.controlla()
    local st = stato_json(c)
    uguale({ st.fatte, st.nuove, st.prossima, st.ultima }, { { '001-somma', '002-saluto' }, 0, nil, nil })
  end)
end

T['aperte e saltate sopravvivono alla chiusura'] = function()
  con(function(c)
    vivo.avvia(c)
    vuoi(c, { t = 10, azione = 'apri', lezione = '002-saluto' })
    vivo.controlla()
    vivo.segna_saltata('001-somma')
    vivo.segna_saltata('../x')
    local prima = stato_json(c)
    uguale({ prima.aperte, prima.saltate }, { { '001-somma', '002-saluto' }, { '001-somma' } })
    vivo.ferma()
    lezione.chiudi()
    vivo.avvia(c)
    -- la prima non fatta e non saltata: la 002, già aperta
    uguale(aperta(), '002-saluto')
    local dopo = stato_json(c)
    uguale({ dopo.aperte, dopo.saltate, dopo.eseguita }, { { '001-somma', '002-saluto' }, { '001-somma' }, 10 })
    -- il file di una sessione di prima si legge davvero: un'altra lista, con un id fuori modello che si scarta
    vivo.ferma()
    lezione.chiudi()
    scrivi(c .. '/stato.json', vim.json.encode({ v = 1, t = 1, eseguita = 77, aperte = { '002-saluto', '../x', '001-somma', '002-saluto' }, saltate = { '002-saluto' }, fatte = {} }))
    vivo.avvia(c)
    dopo = stato_json(c)
    uguale({ dopo.aperte, dopo.saltate, dopo.eseguita }, { { '002-saluto', '001-somma' }, { '002-saluto' }, 77 })
    uguale(aperta(), '001-somma')
  end)
end

T['stato.json fatto di niente o di roba strana: si riparte da zero'] = function()
  for _, testo in ipairs({ '', 'non json', '[1,2]', '{"aperte":"x","saltate":7,"eseguita":"a"}', '{"aperte":[1,{},"001-somma"]}' }) do
    con(function(c)
      scrivi(c .. '/stato.json', testo)
      vivo.avvia(c)
      uguale(aperta(), '001-somma', testo)
      vero(not vim.inspect(guida.ultimo()):find('Errore di dattilo', 1, true), testo)
      uguale(stato_json(c).eseguita, 0, testo)
    end)
  end
end

T['avvio: una richiesta più nuova di quella eseguita si esegue, una vecchia no'] = function()
  -- eseguita 100 e una richiesta con t = 100: già fatta, si parte dalla prima
  con(function(c)
    scrivi(c .. '/stato.json', vim.json.encode({ v = 1, t = 1, eseguita = 100 }))
    vuoi(c, { t = 100, azione = 'apri', lezione = '002-saluto' })
    vivo.avvia(c)
    uguale(aperta(), '001-somma')
    uguale(stato_json(c).aperte, { '001-somma' })
  end)
  -- t = 101: nuova, e la prima lezione non si apre nemmeno
  con(function(c)
    scrivi(c .. '/stato.json', vim.json.encode({ v = 1, t = 1, eseguita = 100 }))
    vuoi(c, { t = 101, azione = 'apri', lezione = '002-saluto' })
    vivo.avvia(c)
    uguale(aperta(), '002-saluto')
    uguale({ stato_json(c).aperte, stato_json(c).eseguita }, { { '002-saluto' }, 101 })
  end)
end

---------------------------------------------------------------- la barra

T['dalvivo finita: la barra lo dice'] = function()
  con(function(c)
    vivo.avvia(c)
    local stato = require('dattilo.stato')
    vero(vim.endswith(stato.destra, ' · 1 nuova'), stato.destra)
    uguale(vivo.destra(), ' · 1 nuova')
    local base = stato.destra:gsub(' · 1 nuova$', '')
    vuoi(c, { t = 5, azione = 'apri', lezione = '001-somma', dalvivo = 'finita' })
    vivo.controlla()
    vero(vim.endswith(stato.destra, 'sessione finita: niente lezioni nuove'), stato.destra)
    uguale(stato.destra, base .. ' · sessione finita: niente lezioni nuove')
    uguale(vivo.destra(), ' · sessione finita: niente lezioni nuove')
    -- «Dal vivo» spento, con lo stesso t: la richiesta non si rifà, ma la barra cambia
    local aperture, orig = 0, lezione.apri
    lezione.apri = function(...) aperture = aperture + 1 return orig(...) end
    vuoi(c, { t = 5, azione = 'apri', lezione = '002-saluto', dalvivo = 'spento' })
    vivo.controlla()
    uguale(aperture, 0)
    uguale(stato.destra, base .. ' · Dal vivo spento: niente lezioni nuove')
    -- di nuovo acceso: torna «N nuove»
    vuoi(c, { t = 5, azione = 'apri', lezione = '002-saluto', dalvivo = 'acceso' })
    vivo.controlla()
    uguale(stato.destra, base .. ' · 1 nuova')
    copia_lezione(c, '002-saluto.md', '003-x.md')
    vivo.controlla()
    uguale(stato.destra, base .. ' · 2 nuove')
  end)
end

T['la barra di una lezione appena aperta ha già il numero giusto'] = function()
  con(function(c)
    vivo.avvia(c)
    local stato = require('dattilo.stato')
    vero(vim.endswith(stato.destra, ' · 1 nuova'), stato.destra)
    -- niente controlla di mezzo: aprendo l'ultima, di nuove non ne restano
    vivo.apri('002-saluto')
    vero(not stato.destra:find('nuov', 1, true), stato.destra)
    vivo.apri('001-somma')
    vero(vim.endswith(stato.destra, ' · 1 nuova'), stato.destra)
  end)
end

T['la barra senza lezione aperta non comincia con il separatore'] = function()
  con(function(c)
    vivo.avvia(c)
    vuoi(c, { t = 5, dalvivo = 'finita' })
    vivo.controlla()
    vivo.elenco()
    vivo.controlla()
    uguale(require('dattilo.stato').destra, 'sessione finita: niente lezioni nuove')
  end)
end

---------------------------------------------------------------- il timer

T['ferma ferma anche il timer, e il timer vero ripete controlla'] = function()
  con(function(c)
    local creati, nuovo_timer = {}, uv.new_timer
    uv.new_timer = function() local t = nuovo_timer() creati[#creati + 1] = t return t end
    local ok, err = pcall(vivo.avvia, c)
    uv.new_timer = nuovo_timer
    assert(ok, err)
    uguale(#creati, 1, 'un timer solo')
    vero(not creati[1]:is_closing())
    copia_lezione(c, '002-saluto.md', '003-x.md')
    vero(vim.wait(1500, function() return stato_json(c).nuove == 2 end, 20), 'il timer non ha riletto la cartella')
    vivo.ferma()
    vero(creati[1]:is_closing(), 'il timer non è stato chiuso')
    copia_lezione(c, '002-saluto.md', '004-y.md')
    vim.wait(900)
    uguale(stato_json(c).nuove, 2, 'dopo ferma il timer gira ancora')
  end)
end

T['il timer vede una lezione nuova entro un secondo'] = function()
  local c = M.cartella()
  M.con({ cartella = c, vivo = true }, function(F)
    local function stato()
      local ok, d = pcall(function() return vim.json.decode(leggi(c .. '/stato.json')) end)
      return ok and d or nil
    end
    vero(F:aspetta(function() local s = stato() return s ~= nil and s.nuove == 1 end, 4000), 'il figlio non ha scritto stato.json')
    copia_lezione(c, '002-saluto.md', '003-x.md')
    vero(F:aspetta(function() local s = stato() return s ~= nil and s.nuove == 2 end, 1500), 'nuove non è salita a 2 entro 1500 ms: ' .. vim.inspect(stato()))
    uguale(stato().lezione, '001-somma')
  end)
  vim.fn.delete(c, 'rf')
end

T['il timer esegue una richiesta di vuoi.json entro un secondo'] = function()
  local c = M.cartella()
  M.con({ cartella = c, vivo = true }, function(F)
    local function stato()
      local ok, d = pcall(function() return vim.json.decode(leggi(c .. '/stato.json')) end)
      return ok and d or nil
    end
    vero(F:aspetta(function() local s = stato() return s ~= nil and s.lezione == '001-somma' end, 4000), 'il figlio non ha aperto la prima lezione')
    vuoi(c, { t = 1, azione = 'apri', lezione = '002-saluto', dalvivo = 'acceso' })
    vero(F:aspetta(function() local s = stato() return s ~= nil and s.lezione == '002-saluto' end, 1500), 'la richiesta non è stata eseguita: ' .. vim.inspect(stato()))
    uguale(stato().eseguita, 1)
    uguale(stato().aperte, { '001-somma', '002-saluto' })
    uguale(F:lua('return require("dattilo.lezione").s.L.id'), '002-saluto')
    -- niente ha scritto nella riga dei messaggi
    vero(not F:messaggi():find('rror', 1, true), F:messaggi())
  end)
  vim.fn.delete(c, 'rf')
end

-- Il caso che capita davvero: la persona scrive in Batti, e dall'app chiede un'altra lezione. Neovim
-- non deve restare in INSERT in una schermata che non si scrive.
T['una richiesta mentre si scrive in INSERT: la nuova lezione si apre in NORMAL'] = function()
  local c = M.cartella()
  M.con({ cartella = c, vivo = true }, function(F)
    local function stato()
      local ok, d = pcall(function() return vim.json.decode(leggi(c .. '/stato.json')) end)
      return ok and d or nil
    end
    vero(F:aspetta(function() local s = stato() return s ~= nil and s.lezione == '001-somma' end, 4000), 'il figlio non ha aperto la prima lezione')
    F:input('<CR>')
    F:input('ifunc')
    uguale(F:modo(), 'i')
    vuoi(c, { t = 1, azione = 'apri', lezione = '002-saluto' })
    vero(F:aspetta(function() local s = stato() return s ~= nil and s.lezione == '002-saluto' end, 1500), 'la richiesta non è stata eseguita: ' .. vim.inspect(stato()))
    uguale(F:modo(), 'n')
    -- e il tasto che la guida dice funziona: ‹Invio› porta in Batti, senza errori
    F:input('<CR>')
    uguale(F:lua('return require("dattilo.lezione").s.passo'), 'batti')
    vero(not F:messaggi():find('E21', 1, true), F:messaggi())
  end)
  vim.fn.delete(c, 'rf')
end

return T
