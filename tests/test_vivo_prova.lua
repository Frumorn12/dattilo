-- dattilo vivo --prova <lezione.md>: i tasti di ogni Modifica arrivano all'obiettivo? E se sì, il par riscritto.
local T = {}
local A = dofile(RADICE .. '/tests/vivo_prova_aiuti.lua')
local USO, ORIGINALE, SOL = A.USO, A.ORIGINALE, A.SOL
local leggi_byte, scrivi_byte, cambia, ambiente, lezione = A.leggi_byte, A.scrivi_byte, A.cambia, A.ambiente, A.lezione
local con_par_zero, prova, json, modo, con_sandbox = A.con_par_zero, A.prova, A.json, A.modo, A.con_sandbox

T['tasti giusti: 0, il JSON e il par riscritto'] = function()
  for _, m in ipairs({ tonumber('600', 8), tonumber('640', 8) }) do
    local f, env, dir = lezione(con_par_zero(), m)
    local r = prova(f, env)
    uguale(r.code, 0, r.stderr .. r.stdout)
    uguale(json(r), { ok = true, modifiche = { { tasti = 41 } } })
    -- il par è tornato 41, e tutto il resto è com'era, byte per byte
    uguale(leggi_byte(f), ORIGINALE)
    uguale(modo(f), m, 'il modo del file')
    uguale(vim.fn.readdir(dir), { '003-sosia.md.4242' }, 'nessun file temporaneo resta')
  end
end

T['il par giusto già scritto: 0 e il file non si tocca'] = function()
  local f, env = lezione(ORIGINALE)
  local prima = vim.uv.fs_stat(f)
  vim.uv.sleep(20)
  local r = prova(f, env)
  uguale(r.code, 0, r.stderr)
  uguale(json(r), { ok = true, modifiche = { { tasti = 41 } } })
  uguale(leggi_byte(f), ORIGINALE)
  uguale(vim.uv.fs_stat(f).mtime, prima.mtime, 'il file non andava riscritto')
end

T['tasti sbagliati: 1 e il motivo'] = function()
  local testo = cambia(con_par_zero(), 'soluzione: ' .. SOL, 'soluzione: 3G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>')
  testo = cambia(testo, '- 2G | va alla riga 2', '- 3G | va alla riga 3')
  local f, env, dir = lezione(testo)
  local r = prova(f, env)
  uguale(r.code, 1, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('non arrivano all\'obiettivo', 1, true), d.motivo)
  uguale(d.motivo, 'modifica 1: i tasti non arrivano all\'obiettivo (riga 2 diversa)')
  uguale(leggi_byte(f), testo, 'il file è uguale a prima')
  uguale(vim.fn.readdir(dir), { '003-sosia.md.4242' })
end

T['tasti non ammessi: 1'] = function()
  local testo = cambia(con_par_zero(), 'soluzione: ' .. SOL, 'soluzione: :!ls<CR>')
  testo = testo:gsub('\n### Tasti\n.-\n\n## Spiegazione', '\n### Tasti\n- :!ls<CR> | prova a lanciare un comando\n\n## Spiegazione')
  local f, env = lezione(testo)
  local r = prova(f, env)
  uguale(r.code, 1, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('!', 1, true), d.motivo)
  uguale(leggi_byte(f), testo)
end

T['i Tasti che non fanno la soluzione: 1 col motivo del formato'] = function()
  local testo = cambia(con_par_zero(), '- 2G | va alla riga 2', '- 3G | va alla riga 3')
  local f, env = lezione(testo)
  local r = prova(f, env)
  uguale(r.code, 1, r.stderr)
  vero(json(r).motivo:find('i Tasti messi in fila non sono la soluzione', 1, true), r.stdout)
  uguale(leggi_byte(f), testo)
end

T['formato rotto: 1'] = function()
  local testo = cambia(con_par_zero(), '## Batti', '## Battuta') -- niente sezione Batti
  local f, env = lezione(testo)
  local r = prova(f, env)
  uguale(r.code, 1, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('Batti', 1, true), d.motivo)
  uguale(leggi_byte(f), testo)
end

T['tasti che non cambiano niente: 1 e la prima riga diversa'] = function()
  local testo = cambia(con_par_zero(), 'soluzione: ' .. SOL, 'soluzione: 2G')
  testo = testo:gsub('\n### Tasti\n.-\n\n## Spiegazione', '\n### Tasti\n- 2G | va alla riga 2\n\n## Spiegazione')
  local f, env = lezione(testo)
  local r = prova(f, env)
  uguale(r.code, 1, r.stderr)
  uguale(json(r), { ok = false, motivo = 'modifica 1: i tasti non arrivano all\'obiettivo (riga 2 diversa)' })
  uguale(leggi_byte(f), testo)
end

T['una soluzione che dà errore in Vim: 1 col motivo, e il par non si tocca'] = function()
  local testo = A.con_soluzione(con_par_zero(), ':s/\\(/x/<CR>') -- E54: parentesi non chiusa
  local f, env = lezione(testo)
  local r = prova(f, env)
  uguale(r.code, 1, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('modifica 1: la soluzione dà errore: ', 1, true) and d.motivo:find('E54', 1, true), d.motivo)
  uguale(leggi_byte(f), testo)
end

T['una lezione senza Modifica: 0 e nessun tasto'] = function()
  local testo = ORIGINALE:gsub('\n## Modifica.-\n\n## Spiegazione', '\n## Spiegazione')
  vero(not testo:find('## Modifica', 1, true))
  local f, env = lezione(testo)
  local r = prova(f, env)
  uguale(r.code, 0, r.stderr)
  uguale(r.stdout, '{"ok":true,"modifiche":[]}\n')
  uguale(leggi_byte(f), testo)
end

T['un file con i fine riga di Windows: si cambia solo il par, i \\r\\n restano'] = function()
  local crlf = ORIGINALE:gsub('\n', '\r\n')
  local f, env = lezione((crlf:gsub('par: 41', 'par: 0')))
  local r = prova(f, env)
  uguale(r.code, 0, r.stderr)
  uguale(json(r), { ok = true, modifiche = { { tasti = 41 } } })
  uguale(leggi_byte(f), crlf)
end

T['il contratto: ok e modifiche, nell\'ordine'] = function()
  local f, env = lezione(con_par_zero())
  local r = prova(f, env)
  uguale(r.stdout, '{"ok":true,"modifiche":[{"tasti":41}]}\n')
end

T['file che non c è o nessun argomento: 2'] = function()
  local tmp, env = ambiente()
  local casi = {
    { RADICE .. '/bin/dattilo', 'vivo', '--prova' },
    { RADICE .. '/bin/dattilo', 'vivo', '--prova', tmp .. '/non-esiste.md' },
    { RADICE .. '/bin/dattilo', 'vivo', '--prova', tmp }, -- una cartella
    { RADICE .. '/bin/dattilo', 'vivo', '--prova', SOSIA, SOSIA }, -- troppi argomenti
  }
  for _, c in ipairs(casi) do
    local r = vim.system(c, { env = env, text = true }):wait()
    uguale(r.code, 2, vim.inspect(c) .. ' ' .. r.stderr)
    uguale(json(r), { ok = false, motivo = USO })
  end
end

T['un file che è un link: 2, e il link resta com\'è'] = function()
  local f, env, dir = lezione(con_par_zero())
  local link = dir .. '/004-link.md.1'
  assert(vim.uv.fs_symlink(f, link))
  local r = prova(link, env)
  uguale(r.code, 2, r.stderr)
  uguale(json(r), { ok = false, motivo = USO })
  uguale(vim.uv.fs_lstat(link).type, 'link')
  uguale(leggi_byte(f), con_par_zero())
end

-- Senza sandbox il comando non prova niente: i tasti di una lezione non fidata non girano mai fuori da bwrap.
T['senza sandbox: 2 e niente eseguito'] = function()
  local testo = con_par_zero()
  local f, env = lezione(testo)
  local finti = A.finti()
  local r = prova(f, env, vim.tbl_extend('force', finti.env, { DATTILO_SANDBOX = '0' }))
  uguale(r.code, 2, r.stderr)
  uguale(r.stdout, A.SENZA_SANDBOX)
  uguale(leggi_byte(f), testo, 'il par non si riscrive: la prova non c\'è stata')
  vero(vim.uv.fs_stat(finti.marcatore) == nil, 'è stato lanciato un nvim di prova fuori dalla sandbox')
  uguale(finti:chiamate_del_figlio(), {}, 'nessun figlio, nemmeno dentro bwrap')
end

T['senza sandbox anche i tasti sbagliati e le lezioni rotte danno 2, non un verdetto'] = function()
  local sbagliata = cambia(cambia(con_par_zero(), 'soluzione: ' .. SOL, 'soluzione: 3G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>'),
    '- 2G | va alla riga 2', '- 3G | va alla riga 3')
  local rotta = cambia(con_par_zero(), '## Batti', '## Battuta')
  for _, testo in ipairs({ sbagliata, rotta }) do
    local f, env = lezione(testo)
    local finti = A.finti()
    local r = prova(f, env, vim.tbl_extend('force', finti.env, { DATTILO_SANDBOX = '0' }))
    uguale(r.code, 2, r.stderr)
    uguale(r.stdout, A.SENZA_SANDBOX)
    uguale(leggi_byte(f), testo)
    vero(vim.uv.fs_stat(finti.marcatore) == nil, 'è stato lanciato un nvim di prova fuori dalla sandbox')
  end
end

T['un bwrap che non funziona vale come niente sandbox: 2 e niente eseguito'] = function()
  local f, env = lezione(con_par_zero())
  local finti = A.finti({ bwrap_rotto = true })
  local r = prova(f, env, finti.env)
  uguale(r.code, 2, r.stderr)
  uguale(r.stdout, A.SENZA_SANDBOX)
  uguale(leggi_byte(f), con_par_zero())
  vero(vim.uv.fs_stat(finti.marcatore) == nil, 'è stato lanciato un nvim di prova fuori dalla sandbox')
end

T['bwrap che non c è: 2 e niente eseguito'] = function()
  local f, env = lezione(con_par_zero())
  -- un PATH con solo quello che serve a bin/dattilo: bash, nvim e le due utilità; bwrap no
  local bin = vim.fn.tempname()
  vim.fn.mkdir(bin, 'p')
  for _, nome in ipairs({ 'bash', 'nvim', 'dirname', 'readlink' }) do
    assert(vim.uv.fs_symlink(vim.fn.exepath(nome), bin .. '/' .. nome))
  end
  local r = prova(f, env, { PATH = bin })
  uguale(r.code, 2, r.stderr)
  uguale(r.stdout, A.SENZA_SANDBOX)
  uguale(leggi_byte(f), con_par_zero())
end

T['con bwrap i tasti girano dentro la sandbox: la cartella della lezione in sola lettura, una cartella sua per scrivere'] = con_sandbox(function()
  local f, env, dir = lezione(con_par_zero())
  local finti = A.finti()
  local r = prova(f, env, vim.tbl_extend('force', finti.env, { PROVA_APPUNTI = '' }))
  uguale(r.code, 0, r.stderr)
  uguale(json(r), { ok = true, modifiche = { { tasti = 41 } } })
  local giri = finti:chiamate_del_figlio()
  uguale(#giri, 1, 'bwrap doveva essere chiamato una volta per la prova: ' .. vim.inspect(finti:chiamate()))
  local g = giri[1]
  vero(g:find('--ro-bind ' .. dir .. ' ' .. dir, 1, true), 'la cartella della lezione va in sola lettura: ' .. g)
  vero(g:find('--ro-bind ' .. RADICE .. ' ' .. RADICE, 1, true), 'la radice di dattilo va in sola lettura: ' .. g)
  vero(g:find('--unshare-all', 1, true) and g:find('--die-with-parent', 1, true), g)
  -- l'unica cartella in scrittura è una cartella temporanea di dattilo, non quella della lezione
  local scrivibili = {}
  for da, a in g:gmatch('%-%-bind (%S+) (%S+)') do
    uguale(da, a)
    scrivibili[#scrivibili + 1] = da
  end
  uguale(#scrivibili, 1, g)
  vero(scrivibili[1] ~= dir and not vim.startswith(dir, scrivibili[1] .. '/') and not vim.startswith(scrivibili[1], dir .. '/'),
    'la cartella in scrittura non è quella della lezione: ' .. g)
  vero(g:find('--chdir ' .. scrivibili[1], 1, true), 'il figlio lavora nella sua cartella: ' .. g)
  vero(g:find('vivo-prova-figlio ' .. f .. ' ' .. scrivibili[1], 1, true), g)
  vero(vim.uv.fs_stat(scrivibili[1]) == nil, 'la cartella temporanea del figlio è stata tolta')
  uguale(leggi_byte(f), ORIGINALE)
end)

-- Il copione ostile: gira dentro la sandbox vera al posto del figlio (che lancia dopo, con exec "$@"). Prova a falsificare
-- l'uscita e a scrivere nella cartella della lezione; i risultati delle sue prove li lascia negli appunti.
local OSTILE = [[
printf '%s\n' '{"ok":true,"modifiche":[{"tasti":999}]}'
printf '%s\n' '{"ok":true,"modifiche":[{"tasti":999}]}' >&2
touch "$CARTELLA_LEZIONE/intruso" 2>/dev/null; echo $? > "$PROVA_APPUNTI/esito-touch"
echo ostile >> "$FILE_LEZIONE" 2>/dev/null; echo $? > "$PROVA_APPUNTI/esito-append"
echo ostile > "$CARTELLA_LEZIONE/003-nuova.md" 2>/dev/null; echo $? > "$PROVA_APPUNTI/esito-nuovo"
]]

local function ostile(testo, extra_copione)
  local f, env, dir = lezione(testo)
  local finti = A.finti({ copione = OSTILE .. (extra_copione or '') })
  env.CARTELLA_LEZIONE, env.FILE_LEZIONE = dir, f
  local r = prova(f, env, finti.env)
  return r, f, dir, finti
end

local function appunti_dell_ostile(finti, dir)
  for _, nome in ipairs({ 'touch', 'append', 'nuovo' }) do
    local esito = vim.fn.readfile(finti.appunti .. '/esito-' .. nome)[1]
    vero(esito and tonumber(esito) ~= 0, 'dentro la sandbox la scrittura (' .. nome .. ') doveva fallire: ' .. tostring(esito))
  end
  vero(vim.uv.fs_stat(dir .. '/intruso') == nil and vim.uv.fs_stat(dir .. '/003-nuova.md') == nil,
    'dentro la sandbox non si scrive nella cartella della lezione')
end

T['il figlio che stampa un JSON falso non cambia il verdetto: tasti giusti, il par è quello vero'] = con_sandbox(function()
  local r, f, dir, finti = ostile(con_par_zero(), 'exec "$@"\n')
  uguale(r.code, 0, r.stderr)
  uguale(r.stdout, '{"ok":true,"modifiche":[{"tasti":41}]}\n')
  uguale(leggi_byte(f), ORIGINALE, 'il par è 41, non 999, e la lezione non è stata toccata dal figlio')
  appunti_dell_ostile(finti, dir)
  uguale(vim.fn.readdir(dir), { '003-sosia.md.4242' })
end)

T['il figlio che stampa un JSON falso non cambia il verdetto: tasti sbagliati, resta 1'] = con_sandbox(function()
  local testo = cambia(cambia(con_par_zero(), 'soluzione: ' .. SOL, 'soluzione: 3G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>'),
    '- 2G | va alla riga 2', '- 3G | va alla riga 3')
  local r, f, dir, finti = ostile(testo, 'exec "$@"\n')
  uguale(r.code, 1, r.stderr)
  uguale(r.stdout, '{"ok":false,"motivo":"modifica 1: i tasti non arrivano all\'obiettivo (riga 2 diversa)"}\n')
  uguale(leggi_byte(f), testo)
  appunti_dell_ostile(finti, dir)
end)

T['il figlio che dice ok senza aver provato niente: 1, e il par non si tocca'] = con_sandbox(function()
  local testo = con_par_zero()
  local r, f, dir, finti = ostile(testo) -- il copione non lancia il figlio
  uguale(r.code, 1, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('non è riuscita', 1, true), d.motivo)
  uguale(leggi_byte(f), testo)
  appunti_dell_ostile(finti, dir)
end)

T['la prova ha un tetto: un figlio con discendenti che non finisce mai muore con tutti i suoi, e esce il JSON'] = con_sandbox(function()
  local unico = tostring(vim.uv.hrtime())
  local testo = con_par_zero()
  local f, env = lezione(testo)
  local finti = A.finti({ copione = 'sleep 31.' .. unico .. ' &\nsleep 32.' .. unico .. ' &\nexec sleep 33.' .. unico .. '\n' })
  finti.env.DATTILO_PROVA_TETTO = '1000'
  local t0 = vim.uv.now()
  local r = prova(f, env, finti.env)
  local durata = vim.uv.now() - t0
  uguale(r.code, 1, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('tempo', 1, true), d.motivo)
  vero(durata < 6000, 'ci ha messo ' .. durata .. ' ms')
  uguale(A.aspetta_senza_processi('.' .. unico, 3000), {}, 'sono rimasti dei processi della prova')
  uguale(leggi_byte(f), testo)
end)

T['un figlio che finisce lasciando un discendente: muore anche lui, e non si aspetta'] = con_sandbox(function()
  local unico = tostring(vim.uv.hrtime())
  local testo = con_par_zero()
  local f, env = lezione(testo)
  local finti = A.finti({ copione = 'sleep 31.' .. unico .. ' &\nexit 0\n' })
  local t0 = vim.uv.now()
  local r = prova(f, env, finti.env)
  local durata = vim.uv.now() - t0
  uguale(r.code, 1, r.stderr)
  vero(json(r).motivo:find('non è riuscita', 1, true), r.stdout)
  vero(durata < 6000, 'ci ha messo ' .. durata .. ' ms: ha aspettato il discendente?')
  uguale(A.aspetta_senza_processi('31.' .. unico, 3000), {}, 'il discendente è rimasto vivo')
end)

T['un processo staccato che tiene aperto lo stderr: niente errore Lua, un JSON e uscita 1 dentro il tetto'] = con_sandbox(function()
  local unico = '31.' .. tostring(vim.uv.hrtime() % 100000)
  local testo = con_par_zero()
  local f, env = lezione(testo)
  local finti = A.finti()
  finti.env.PROVA_ORFANO = unico
  finti.env.DATTILO_PROVA_TETTO = '1000'
  local t0 = vim.uv.now()
  local r = prova(f, env, finti.env)
  local durata = vim.uv.now() - t0
  -- l'orfano sta fuori da bwrap e non lo ferma nessuno: lo si ferma qui, per PID
  for _, pid in ipairs(A.processi_con('sleep ' .. unico)) do vim.uv.kill(pid, 'sigkill') end
  uguale(r.code, 1, r.stderr)
  uguale(r.stderr, '', 'nessun errore Lua su stderr')
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('tempo', 1, true), d.motivo)
  vero(durata < 5000, 'ci ha messo ' .. durata .. ' ms')
  uguale(leggi_byte(f), testo)
end)

T['bwrap che si rompe mentre parte il figlio: 2, è un problema dell\'ambiente, non della lezione'] = con_sandbox(function()
  local testo = con_par_zero()
  local f, env = lezione(testo)
  local finti = A.finti()
  finti.env.PROVA_BWRAP_ERRORE = 'Creating new namespace failed: Operation not permitted'
  local r = prova(f, env, finti.env)
  uguale(r.code, 2, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('bwrap', 1, true) and d.motivo:find('Operation not permitted', 1, true), d.motivo)
  uguale(leggi_byte(f), testo)
end)

T['una soluzione che non finisce mai viene fermata dal tetto'] = con_sandbox(function()
  -- una macro ricorsiva: scrive x e si richiama, senza fermarsi mai
  local testo = A.con_soluzione(con_par_zero(), 'qqqqqix<Esc>@qq@q')
  local f, env = lezione(testo)
  local t0 = vim.uv.now()
  local r = prova(f, env, { DATTILO_PROVA_TETTO = '1500' })
  local durata = vim.uv.now() - t0
  uguale(r.code, 1, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('tempo', 1, true), d.motivo)
  vero(durata < 8000, 'ci ha messo ' .. durata .. ' ms')
  uguale(leggi_byte(f), testo)
end)

T['vivo --dove dice 1 finché la Modifica non ha la sua guida'] = function()
  local _, env = ambiente()
  local r = vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--dove' }, { env = env, text = true }):wait()
  uguale(r.code, 0, r.stderr)
  uguale(vim.json.decode(r.stdout), { vivo = 1, radice = RADICE })
end

T['la riscrittura del par è atomica: un file nuovo che prende il posto, non un file riscritto sul posto'] = function()
  local f, env, dir = lezione(con_par_zero())
  local prima = vim.uv.fs_stat(f)
  local r = prova(f, env)
  uguale(r.code, 0, r.stderr)
  local dopo = vim.uv.fs_stat(f)
  vero(dopo.ino ~= prima.ino, 'l\'inode è lo stesso: il file è stato riscritto sul posto, non rinominato')
  uguale(dopo.nlink, 1)
  uguale(leggi_byte(f), ORIGINALE)
  uguale(vim.fn.readdir(dir), { '003-sosia.md.4242' })
end

T['una cartella che non si può scrivere: 2 (è l\'ambiente, non la lezione), e il file resta com\'è'] = function()
  local testo = con_par_zero()
  local f, env, dir = lezione(testo)
  vim.uv.fs_chmod(dir, tonumber('555', 8))
  local scrivibile = vim.uv.fs_access(dir, 'W') -- chi è root la scrive lo stesso: la prova non ha niente da dire
  local r = scrivibile and { code = 2, stdout = '{}' } or prova(f, env)
  vim.uv.fs_chmod(dir, tonumber('755', 8))
  if scrivibile then return end
  uguale(r.code, 2, r.stderr)
  local d = json(r)
  uguale(d.ok, false)
  vero(d.motivo:find('par', 1, true), d.motivo)
  uguale(leggi_byte(f), testo)
  uguale(vim.fn.readdir(dir), { '003-sosia.md.4242' })
end

-- Il figlio lavora solo dentro la sandbox: lanciato a mano non fa niente, nemmeno con la variabile che dice «sono dentro».
T['vivo-prova-figlio a mano, fuori dalla sandbox: si rifiuta e non fa niente'] = function()
  local f, env, dir = lezione(con_par_zero())
  local lavoro = vim.fn.tempname()
  vim.fn.mkdir(lavoro, 'p')
  for _, extra in ipairs({ {}, { DATTILO_IN_SANDBOX = '1' } }) do -- la seconda: la cartella della lezione si scrive, quindi non è la sandbox
    local e = vim.tbl_extend('force', env, extra)
    local r = vim.system({ 'nvim', '--clean', '--headless', '-l', RADICE .. '/lua/dattilo/cli.lua', 'vivo-prova-figlio', f, lavoro },
      { env = e, text = true, timeout = 30000 }):wait()
    uguale(r.code, 2, r.stderr)
    uguale(r.stdout, '')
    vero(r.stderr:find('sandbox', 1, true), r.stderr)
    uguale(vim.fn.readdir(lavoro), {}, 'il figlio non doveva lasciare niente')
  end
  uguale(leggi_byte(f), con_par_zero())
end

T['bin/dattilo lancia nvim con exec: un segnale arriva a Neovim e la prova muore con tutto quello che ha lanciato'] = con_sandbox(function()
  local testo = A.con_soluzione(con_par_zero(), 'qqqqqix<Esc>@qq@q') -- non finisce mai: il tetto è lontano
  local f, env, dir = lezione(testo)
  local e = vim.tbl_extend('force', env, { DATTILO_PROVA_TETTO = '30000' })
  local proc = vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--prova', f }, { env = e, text = true })
  vero(vim.wait(5000, function() return #A.processi_con('vivo-prova-figlio ' .. f) > 0 end, 20), 'il figlio non è partito')
  local comm = vim.fn.readfile('/proc/' .. proc.pid .. '/comm')[1]
  proc:kill(15)
  proc:wait()
  local rimasti = A.aspetta_senza_processi(dir, 3000)
  for _, pid in ipairs(rimasti) do vim.uv.kill(pid, 'sigkill') end -- se la prova fallisce non lascia processi in giro
  uguale(comm, 'nvim', 'il processo di bin/dattilo è ' .. tostring(comm) .. ': senza exec il segnale si ferma a bash')
  uguale(rimasti, {}, 'dopo il SIGTERM è rimasto vivo qualcosa della prova')
  uguale(leggi_byte(f), testo)
end)

T['dopo il tetto non resta nessun nvim vivo'] = con_sandbox(function()
  local testo = A.con_soluzione(con_par_zero(), 'qqqqqix<Esc>@qq@q')
  local f, env, dir = lezione(testo)
  local r = prova(f, env, { DATTILO_PROVA_TETTO = '1200' })
  uguale(r.code, 1, r.stderr)
  vero(json(r).motivo:find('tempo', 1, true), r.stdout)
  uguale(A.aspetta_senza_processi(dir, 3000), {}, 'dopo il tetto è rimasto vivo qualcosa della prova')
  uguale(leggi_byte(f), testo)
end)

-- Le prove che hanno bisogno dei tasti eseguiti saltano dove bwrap non c'è; quelle sull'uso e sul rifiuto no.
local SENZA = {
  ['file che non c è o nessun argomento: 2'] = true, ['un file che è un link: 2, e il link resta com\'è'] = true,
  ['vivo --dove dice 1 finché la Modifica non ha la sua guida'] = true, ['vivo-prova-figlio a mano, fuori dalla sandbox: si rifiuta e non fa niente'] = true, ['senza sandbox: 2 e niente eseguito'] = true,
  ['senza sandbox anche i tasti sbagliati e le lezioni rotte danno 2, non un verdetto'] = true,
  ['un bwrap che non funziona vale come niente sandbox: 2 e niente eseguito'] = true, ['bwrap che non c è: 2 e niente eseguito'] = true,
}
for nome, prova_ in pairs(T) do
  if not SENZA[nome] then T[nome] = con_sandbox(prova_) end
end

return T
