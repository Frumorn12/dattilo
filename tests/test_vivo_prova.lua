-- dattilo vivo --prova <lezione.md>: i tasti di ogni Modifica arrivano all'obiettivo? E se sì, il par riscritto.
local T = {}

local SOSIA = RADICE .. '/tests/fixture/rifallo-b/dati/dattilo/pacchetti/rifallo/lezioni/001-sosia.md'
local USO = 'uso: dattilo vivo --prova <lezione.md>'

local function leggi_byte(p)
  local f = assert(io.open(p, 'rb'))
  local t = f:read('a')
  f:close()
  return t
end

local function scrivi_byte(p, testo)
  local f = assert(io.open(p, 'wb'))
  f:write(testo)
  f:close()
end

local ORIGINALE = leggi_byte(SOSIA) -- ha par: 41

-- Cambia una stringa che nel testo c'è una volta sola.
local function cambia(testo, vecchio, nuovo)
  local da, a = testo:find(vecchio, 1, true)
  assert(da, 'nel testo non c\'è: ' .. vecchio)
  assert(not testo:find(vecchio, a + 1, true), 'nel testo c\'è più di una volta: ' .. vecchio)
  return testo:sub(1, da - 1) .. nuovo .. testo:sub(a + 1)
end

-- Una casa finta con gli XDG: la prova non tocca mai i dati veri.
local function ambiente()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp .. '/home', 'p', tonumber('700', 8))
  return tmp, {
    HOME = tmp .. '/home', XDG_DATA_HOME = tmp .. '/dati', XDG_CONFIG_HOME = tmp .. '/config',
    XDG_STATE_HOME = tmp .. '/stato', XDG_CACHE_HOME = tmp .. '/cache',
  }
end

-- Scrive la lezione in una cartella nuova, col nome che le dà la mod (non finisce in .md), e dà il percorso.
local function lezione(testo, modo)
  local tmp, env = ambiente()
  local dir = tmp .. '/lezioni'
  vim.fn.mkdir(dir, 'p', tonumber('700', 8))
  local f = dir .. '/003-sosia.md.4242'
  scrivi_byte(f, testo)
  vim.uv.fs_chmod(f, modo or tonumber('600', 8))
  return f, env, dir
end

local function con_par_zero() return cambia(ORIGINALE, 'par: 41', 'par: 0') end

local function prova(f, env, extra)
  local e = vim.tbl_extend('force', env, extra or {})
  return vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--prova', f }, { env = e, text = true, timeout = 60000 }):wait()
end

-- Lo stdout è una sola riga JSON: si decodifica tutto, così un messaggio di troppo si vede.
local function json(r)
  vero(r.stdout:match('^[^\n]*\n$'), 'lo stdout non è una riga sola: ' .. vim.inspect(r.stdout) .. ' stderr: ' .. tostring(r.stderr))
  local ok, d = pcall(vim.json.decode, r.stdout)
  vero(ok and type(d) == 'table', 'JSON non valido: ' .. vim.inspect(r.stdout))
  return d
end

local function modo(p) return vim.uv.fs_stat(p).mode % 4096 end

-- Il codice di Batti e quello di partenza sono quelli del progetto: solo la soluzione e i Tasti cambiano.
local SOL = '2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>'

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

T['senza bwrap va lo stesso'] = function()
  local f, env = lezione(con_par_zero())
  local r = prova(f, env, { DATTILO_SANDBOX = '0' })
  uguale(r.code, 0, r.stderr)
  uguale(json(r), { ok = true, modifiche = { { tasti = 41 } } })
  uguale(leggi_byte(f), ORIGINALE)
end

T['senza bwrap i tasti sbagliati dicono di no lo stesso'] = function()
  local testo = cambia(cambia(con_par_zero(), 'soluzione: ' .. SOL, 'soluzione: 3G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>'),
    '- 2G | va alla riga 2', '- 3G | va alla riga 3')
  local f, env = lezione(testo)
  local r = prova(f, env, { DATTILO_SANDBOX = '0' })
  uguale(r.code, 1, r.stderr)
  vero(json(r).motivo:find('non arrivano all\'obiettivo', 1, true))
  uguale(leggi_byte(f), testo)
end

T['con bwrap i tasti girano dentro la sandbox, con la cartella del file scrivibile'] = function()
  local compila = require('dattilo.compila')
  if not compila.sandbox() then return end -- senza bwrap questa prova non ha niente da dire
  local f, env, dir = lezione(con_par_zero())
  -- un bwrap finto in testa al PATH: scrive come l'hanno chiamato e poi lancia quello vero
  local finto = vim.fn.tempname()
  vim.fn.mkdir(finto, 'p')
  local registro = finto .. '/chiamate'
  scrivi_byte(finto .. '/bwrap', '#!/bin/sh\nprintf \'%s\\n\' "$*" >> ' .. registro .. '\nexec ' .. vim.fn.exepath('bwrap') .. ' "$@"\n')
  vim.uv.fs_chmod(finto .. '/bwrap', tonumber('755', 8))
  local r = prova(f, env, { PATH = finto .. ':' .. vim.env.PATH })
  uguale(r.code, 0, r.stderr)
  uguale(json(r), { ok = true, modifiche = { { tasti = 41 } } })
  local giri = vim.tbl_filter(function(l) return l:find('vivo-prova', 1, true) end, vim.fn.readfile(registro))
  uguale(#giri, 1, 'bwrap doveva essere chiamato una volta per la prova: ' .. vim.inspect(vim.fn.readfile(registro)))
  vero(giri[1]:find('--bind ' .. dir .. ' ' .. dir, 1, true), 'la cartella del file va in scrittura: ' .. giri[1])
  vero(giri[1]:find('--ro-bind ' .. RADICE .. ' ' .. RADICE, 1, true), 'la radice di dattilo va in sola lettura: ' .. giri[1])
  vero(giri[1]:find('--unshare-all', 1, true) and giri[1]:find('--die-with-parent', 1, true), giri[1])
  uguale(leggi_byte(f), ORIGINALE)
end

T['una soluzione che non finisce mai viene fermata dal tetto'] = function()
  -- una macro ricorsiva: scrive x e si richiama, senza fermarsi mai
  local testo = cambia(con_par_zero(), 'soluzione: ' .. SOL, 'soluzione: qqqqqix<Esc>@qq@q')
  testo = testo:gsub('\n### Tasti\n.-\n\n## Spiegazione', '\n### Tasti\n- qqqqqix<Esc>@qq@q | ricorsione\n\n## Spiegazione')
  for _, extra in ipairs({ {}, { DATTILO_SANDBOX = '0' } }) do
    local f, env = lezione(testo)
    extra.DATTILO_PROVA_TETTO = '1500'
    local t0 = vim.uv.now()
    local r = prova(f, env, extra)
    local durata = vim.uv.now() - t0
    uguale(r.code, 1, r.stderr)
    local d = json(r)
    uguale(d.ok, false)
    vero(d.motivo:find('tempo', 1, true), d.motivo)
    vero(durata < 8000, 'ci ha messo ' .. durata .. ' ms')
    uguale(leggi_byte(f), testo)
  end
end

T['vivo --dove ora dice 2'] = function()
  local _, env = ambiente()
  local r = vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--dove' }, { env = env, text = true }):wait()
  uguale(r.code, 0, r.stderr)
  uguale(vim.json.decode(r.stdout), { vivo = 2, radice = RADICE })
end

return T
