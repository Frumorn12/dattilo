-- Aiuti per le prove di `dattilo vivo --prova` (non è una prova: il caricatore guarda solo test_*.lua).
local A = {}

A.SOSIA = RADICE .. '/tests/fixture/rifallo-b/dati/dattilo/pacchetti/rifallo/lezioni/001-sosia.md'
A.USO = 'uso: dattilo vivo --prova <lezione.md>'
A.SENZA_SANDBOX = '{"ok":false,"motivo":"senza sandbox i tasti di una lezione non si provano"}\n'

function A.leggi_byte(p)
  local f = assert(io.open(p, 'rb'))
  local t = f:read('a')
  f:close()
  return t
end

function A.scrivi_byte(p, testo)
  local f = assert(io.open(p, 'wb'))
  f:write(testo)
  f:close()
end

A.ORIGINALE = A.leggi_byte(A.SOSIA) -- ha par: 41

-- Il codice di Batti e quello di partenza sono quelli del progetto: solo la soluzione e i Tasti cambiano.
A.SOL = '2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>'

-- Cambia una stringa che nel testo c'è una volta sola.
function A.cambia(testo, vecchio, nuovo)
  local da, a = testo:find(vecchio, 1, true)
  assert(da, 'nel testo non c\'è: ' .. vecchio)
  assert(not testo:find(vecchio, a + 1, true), 'nel testo c\'è più di una volta: ' .. vecchio)
  return testo:sub(1, da - 1) .. nuovo .. testo:sub(a + 1)
end

function A.con_par_zero() return A.cambia(A.ORIGINALE, 'par: 41', 'par: 0') end

-- La stessa lezione con un'altra soluzione, e i Tasti che la fanno.
function A.con_soluzione(testo, sol)
  testo = A.cambia(testo, 'soluzione: ' .. A.SOL, 'soluzione: ' .. sol)
  local nuovo, n = testo:gsub('\n### Tasti\n.-\n\n## Spiegazione', function() return '\n### Tasti\n- ' .. sol .. ' | prova\n\n## Spiegazione' end)
  assert(n == 1, 'i Tasti non si sono cambiati')
  return nuovo
end

-- Una casa finta con gli XDG: la prova non tocca mai i dati veri.
function A.ambiente()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp .. '/home', 'p', tonumber('700', 8))
  return tmp, {
    HOME = tmp .. '/home', XDG_DATA_HOME = tmp .. '/dati', XDG_CONFIG_HOME = tmp .. '/config',
    XDG_STATE_HOME = tmp .. '/stato', XDG_CACHE_HOME = tmp .. '/cache',
  }
end

-- Scrive la lezione in una cartella nuova, col nome che le dà la mod (non finisce in .md), e dà il percorso.
function A.lezione(testo, modo)
  local tmp, env = A.ambiente()
  local dir = tmp .. '/lezioni'
  vim.fn.mkdir(dir, 'p', tonumber('700', 8))
  local f = dir .. '/003-sosia.md.4242'
  A.scrivi_byte(f, testo)
  vim.uv.fs_chmod(f, modo or tonumber('600', 8))
  return f, env, dir
end

function A.prova(f, env, extra)
  local e = vim.tbl_extend('force', env, extra or {})
  return vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--prova', f }, { env = e, text = true, timeout = 60000 }):wait()
end

-- Lo stdout è una sola riga JSON: si decodifica tutto, così un messaggio di troppo si vede.
function A.json(r)
  vero(r.stdout:match('^[^\n]*\n$'), 'lo stdout non è una riga sola: ' .. vim.inspect(r.stdout) .. ' stderr: ' .. tostring(r.stderr))
  local ok, d = pcall(vim.json.decode, r.stdout)
  vero(ok and type(d) == 'table', 'JSON non valido: ' .. vim.inspect(r.stdout))
  return d
end

function A.modo(p) return vim.uv.fs_stat(p).mode % 4096 end

-- Senza bwrap che funziona il comando non prova niente: le prove che vogliono i tasti eseguiti non hanno cosa dire.
function A.sandbox_c_e() return require('dattilo.compila').sandbox() end

function A.con_sandbox(prova)
  return function()
    if not A.sandbox_c_e() then return end
    return prova()
  end
end

-- I PID dei processi vivi (zombie esclusi) che nella riga di comando hanno `testo`: si guarda in /proc.
function A.processi_con(testo)
  local trovati = {}
  for _, d in ipairs(vim.fn.glob('/proc/[0-9]*', false, true)) do
    local pid = tonumber(d:match('(%d+)$'))
    if pid and pid ~= vim.uv.os_getpid() then
      local f = io.open(d .. '/cmdline', 'rb')
      local riga = f and f:read('a')
      if f then f:close() end
      if riga and riga:gsub('%z', ' '):find(testo, 1, true) then
        local st = io.open(d .. '/stat', 'rb')
        local s = st and st:read('a') or ''
        if st then st:close() end
        if not s:match('^%d+ %b() Z') then trovati[#trovati + 1] = pid end
      end
    end
  end
  return trovati
end

-- Aspetta (al massimo `ms`) che non resti vivo nessun processo con `testo` nella riga di comando.
function A.aspetta_senza_processi(testo, ms)
  vim.wait(ms or 3000, function() return #A.processi_con(testo) == 0 end, 50)
  return A.processi_con(testo)
end

local BWRAP_FINTO = [=[#!/bin/bash
# bwrap di prova: registra ogni chiamata e poi lancia quello vero. Per il figlio della prova (vivo-prova-figlio):
#   PROVA_APPUNTI  una cartella in più, scrivibile dentro la sandbox
#   PROVA_COPIONE  un copione al posto del comando del figlio: lo riceve come argomenti, e può lanciarlo con exec "$@"
#   PROVA_ORFANO   non lancia la sandbox: lascia un discendente staccato che tiene aperto lo stderr e non finisce mai
#   PROVA_BWRAP_ERRORE  bwrap si rompe all'avvio del figlio, con questo messaggio
real=@REALE@
printf '%s\n' "$*" >> "$PROVA_REGISTRO"
if [[ " $* " == *" vivo-prova-figlio "* ]]; then
  if [ -n "$PROVA_BWRAP_ERRORE" ]; then echo "bwrap: $PROVA_BWRAP_ERRORE" >&2; exit 1; fi
  if [ -n "$PROVA_ORFANO" ]; then
    setsid sleep "$PROVA_ORFANO" <&- >/dev/null &
    echo $! > "$PROVA_APPUNTI/orfano"
    exec sleep "$PROVA_ORFANO.1"
  fi
  opz=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do opz+=("$1"); shift; done
  shift
  [ -n "$PROVA_APPUNTI" ] && opz+=(--bind "$PROVA_APPUNTI" "$PROVA_APPUNTI")
  if [ -n "$PROVA_COPIONE" ]; then exec "$real" "${opz[@]}" -- sh "$PROVA_COPIONE" "$@"; fi
  exec "$real" "${opz[@]}" -- "$@"
fi
exec "$real" "$@"
]=]

local NVIM_FINTO = [=[#!/bin/bash
# nvim di prova: se qualcuno lancia il figlio della prova (fuori dalla sandbox, perché dentro non si vede questa cartella)
# lascia un marcatore e non fa niente
if [[ " $* " == *" vivo-prova-figlio "* ]]; then touch "$PROVA_MARCATORE"; exit 99; fi
exec @NVIM@ "$@"
]=]

-- Un nome di cartella temporanea senza «q» davanti a «/» o «:»: i vettori delle prove scrivono il percorso del marcatore
-- dentro i tasti, e la lista rifiuta q/ e q: (la finestra dei comandi) anche dentro un percorso.
function A.tempname_pulita()
  local t = vim.fn.tempname()
  while t:find('q[/:?]') do t = vim.fn.tempname() end
  return t
end

-- Una cartella di appunti e un PATH con un bwrap e un nvim finti in testa. Dà le variabili d'ambiente da aggiungere.
function A.finti(opzioni)
  opzioni = opzioni or {}
  local base = A.tempname_pulita()
  vim.fn.mkdir(base .. '/bin', 'p')
  vim.fn.mkdir(base .. '/appunti', 'p')
  local reale = vim.fn.exepath('bwrap')
  local function eseguibile(nome, testo)
    A.scrivi_byte(base .. '/bin/' .. nome, testo)
    vim.uv.fs_chmod(base .. '/bin/' .. nome, tonumber('755', 8))
  end
  if opzioni.bwrap_rotto then eseguibile('bwrap', '#!/bin/sh\nprintf "%s\\n" "$*" >> "$PROVA_REGISTRO"\nexit 1\n')
  else eseguibile('bwrap', (BWRAP_FINTO:gsub('@REALE@', function() return reale end))) end
  eseguibile('nvim', (NVIM_FINTO:gsub('@NVIM@', function() return vim.fn.exepath('nvim') end)))
  local copione
  if opzioni.copione then
    copione = base .. '/appunti/copione.sh' -- negli appunti: dentro la sandbox si vede solo quella cartella
    A.scrivi_byte(copione, opzioni.copione)
  end
  return {
    base = base, appunti = base .. '/appunti', registro = base .. '/registro', marcatore = base .. '/marcatore',
    env = {
      PATH = base .. '/bin:' .. vim.env.PATH, PROVA_REGISTRO = base .. '/registro', PROVA_APPUNTI = base .. '/appunti',
      PROVA_MARCATORE = base .. '/marcatore', PROVA_COPIONE = copione,
    },
    chiamate = function(self)
      local f = io.open(self.registro, 'rb')
      if not f then return {} end
      local t = f:read('a')
      f:close()
      return vim.split(t, '\n', { plain = true, trimempty = true })
    end,
    chiamate_del_figlio = function(self)
      return vim.tbl_filter(function(l) return l:find('vivo-prova-figlio', 1, true) end, self:chiamate())
    end,
  }
end

return A
