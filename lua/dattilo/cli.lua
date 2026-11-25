-- Riga di comando: nvim --clean --headless -l lua/dattilo/cli.lua <comando> ...
local qui = debug.getinfo(1, 'S').source:sub(2)
local radice = vim.fn.fnamemodify(qui, ':p:h:h:h')
package.path = radice .. '/lua/?.lua;' .. radice .. '/lua/?/init.lua;' .. package.path

local M = {}
local function scrivi(s) io.stdout:write(s .. '\n') end

local MODELLO_MANIFESTO = [[{
  "id": "%s",
  "titolo": "%s",
  "versione": "0.1.0",
  "autore": "",
  "descrizione": "",
  "linguaggio": "javascript",
  "richiede": [],
  "esecuzione": { "tipo": "comando", "comando": ["node", "{file}"] }
}]]

local MODELLO_LEZIONE = [[---
titolo: La prima lezione
breve: prima lezione
file: main.js
mosse: ["ci\""]
concetti: [console.log]
tempo: circa 2 minuti
---

## Briefing
Scrivi un saluto e cambialo con ci".

## Batti
```js
const nome = "mondo";
console.log("ciao " + nome);
```

### Blocchi
1-2: Il saluto | Un nome in una costante e una riga che lo stampa. | Il programma più piccolo: un dato e una stampa.

### Suggerimenti
1: const dichiara un nome che non cambierà: qui il testo "mondo".
2: console.log stampa sul terminale; + attacca le due stringhe.

## Uscita
```text
ciao mondo
```

## Modifica
consegna: Saluta Andrea invece del mondo.
aiuto: ‹ci"› cambia il testo tra le virgolette della riga.
motivo: Il saluto dipende solo dalla costante: cambi il dato e la stampa segue.
par: 10
soluzione: ci"Andrea<Esc>
mostra: ci" · Andrea · Esc
```js
const nome = "Andrea";
console.log("ciao " + nome);
```

## Spiegazione
1: const: una variabile che non cambia.
2: console.log stampa sul terminale.
]]

local function comando_importa(args)
  local file, si, solo_anteprima = args[2], vim.tbl_contains(args, '--si'), vim.tbl_contains(args, '--anteprima')
  if not file or vim.fn.filereadable(file) == 0 then scrivi('dattilo importa: file non trovato: ' .. tostring(file)) return 1 end
  local scambio = require('dattilo.scambio')
  local dati, err = scambio.leggi(table.concat(vim.fn.readfile(file, 'b'), '\n'))
  if not dati then
    scrivi('Non importo ' .. file .. ':')
    for _, e in ipairs(err) do scrivi('  ' .. e.file .. ':' .. e.riga .. ': ' .. e.msg) end
    return 1
  end
  if not si then for _, l in ipairs(scambio.anteprima(dati)) do scrivi(l) end end
  if solo_anteprima then return 0 end
  if not si then scrivi('Aggiungi --si per installare.') return 1 end
  local ok, msg = scambio.installa(dati, { sostituisci = true })
  scrivi(msg)
  return ok and 0 or 1
end

local function comando_esporta(args)
  local chi, uscita = args[2], args[3]
  if not chi then scrivi('uso: dattilo esporta <id o cartella> [file]') return 1 end
  local cartella = chi
  if vim.fn.isdirectory(chi) == 0 then
    local P = require('dattilo.pacchetti').carica(chi)
    if not P then scrivi('pacchetto non trovato: ' .. chi) return 1 end
    cartella = P.cartella
  end
  local testo, nome = require('dattilo.scambio').esporta(vim.fn.fnamemodify(cartella, ':p'):gsub('/$', ''))
  uscita = uscita or nome
  if vim.fn.isdirectory(uscita) == 1 then uscita = uscita:gsub('/+$', '') .. '/' .. nome end
  vim.fn.writefile(vim.split(testo:gsub('\n$', ''), '\n', { plain = true }), uscita)
  scrivi('Esportato in ' .. uscita)
  return 0
end

local function comando_pacchetti()
  for _, v in ipairs(require('dattilo.pacchetti').elenco()) do
    scrivi(string.format('%-22s %-10s %3d lezioni  %s%s', v.id, v.versione, v.lezioni, v.titolo, #v.errori > 0 and ('  (' .. #v.errori .. ' problemi)') or ''))
  end
  return 0
end

local function comando_nuovo(args)
  local dir = args[2]
  if not dir then scrivi('uso: dattilo nuovo <cartella>') return 1 end
  local id = vim.fn.fnamemodify(dir, ':t')
  if not id:match('^[a-z0-9%-]+$') then scrivi('il nome deve avere solo minuscole, cifre e trattini') return 1 end
  if vim.fn.isdirectory(dir) == 1 then scrivi('la cartella esiste già: ' .. dir) return 1 end
  vim.fn.mkdir(dir .. '/lezioni', 'p')
  vim.fn.writefile(vim.split(string.format(MODELLO_MANIFESTO, id, id), '\n'), dir .. '/pacchetto.json')
  vim.fn.writefile(vim.split(MODELLO_LEZIONE, '\n'), dir .. '/lezioni/01-prima.md')
  scrivi('Creato ' .. dir .. ': modifica pacchetto.json e scrivi le lezioni in lezioni/. Poi: dattilo controlla ' .. dir)
  return 0
end

local function comando_controlla(args)
  local tip, pos = false, {}
  for i = 2, #args do
    if args[i] == '--tip' then tip = true else pos[#pos + 1] = args[i] end
  end
  local dir, solo = pos[1], pos[2]
  if not dir or vim.fn.isdirectory(dir) == 0 or (tip and not solo) then
    scrivi('uso: dattilo controlla <cartella del pacchetto> [lezione]\n     dattilo controlla --tip <cartella> <lezione>')
    return 1
  end
  local assoluta = vim.fn.fnamemodify(dir, ':p'):gsub('/$', '')
  if tip then
    local P = require('dattilo.pacchetti').carica_cartella(assoluta)
    for _, e in ipairs(P.errori) do scrivi('✗ ' .. e.file .. ':' .. e.riga .. ': ' .. e.msg) end
    for _, L in ipairs(P.lezioni) do
      if L.id == solo or L.id == solo:gsub('%.md$', '') then
        for _, l in ipairs(require('dattilo.controlla').tip(L)) do scrivi(l) end
        return 0
      end
    end
    scrivi('lezione non trovata: ' .. solo)
    return 1
  end
  -- il verificatore esegue codice e soluzioni del pacchetto: se si può, lo fa dentro la sandbox
  local compila = require('dattilo.compila')
  if compila.sandbox() then
    local a = compila.argomenti_sandbox({}, { radice, assoluta }, { 'nvim', 'node', 'cc' })
    vim.list_extend(a, { '--', 'nvim', '--clean', '--headless', '-l', radice .. '/lua/dattilo/cli.lua', 'controlla', assoluta, solo })
    local esito = vim.system(a, { text = true }):wait()
    io.stdout:write(esito.stdout or '')
    if esito.code ~= 0 and not (esito.stdout or ''):find('problemi', 1, true) then io.stdout:write(esito.stderr or '') end
    return esito.code
  end
  local r = require('dattilo.controlla').pacchetto(assoluta, solo)
  for _, x in ipairs(r.righe) do scrivi((x.stato == 'ok' and '  ✓ ' or '  ✗ ') .. x.testo) end
  scrivi(r.ok and 'Tutto a posto.' or 'Ci sono problemi.')
  return r.ok and 0 or 1
end

local function comando_riempi(args)
  local file = args[2]
  if not file or vim.fn.filereadable(file) == 0 then scrivi('uso: dattilo riempi <lezione.md>') return 1 end
  local testo = table.concat(vim.fn.readfile(file), '\n')
  local nuovo, r = require('dattilo.controlla').riempi(testo, vim.fn.fnamemodify(file, ':t'))
  if not nuovo then
    for _, e in ipairs(r) do scrivi('✗ ' .. e.file .. ':' .. e.riga .. ': ' .. e.msg) end
    return 1
  end
  vim.fn.writefile(vim.split(nuovo, '\n', { plain = true }), file)
  for _, l in ipairs(r) do scrivi('  ' .. l) end
  scrivi('Riscritti i blocchi obiettivo e il par in ' .. file)
  return 0
end

-- dattilo vivo --prova <lezione.md>: i tasti di ogni Modifica arrivano all'obiettivo? Se sì, riscrive le righe par:.
-- La lezione la scrive un modello a partire da un codice qualunque: è un testo non fidato e i suoi tasti possono essere
-- ostili. Per questo i tasti girano solo dentro bwrap (senza, il comando non prova niente), in un Neovim figlio con la
-- cartella della lezione in sola lettura e una cartella temporanea sua dove scrivere. Il verdetto lo decide questo
-- processo, fuori dalla sandbox: del figlio guarda soltanto il testo che il buffer ha alla fine (un file nella cartella
-- temporanea), conta i tasti dal testo della lezione e riscrive il par. Quello che il figlio stampa non conta.
-- Scrive una riga JSON e esce con 0 (tutto va), 1 (lezione rifiutata) o 2 (uso sbagliato, file illeggibile, o un problema
-- dell'ambiente: niente sandbox, bwrap che non parte, il par che non si riesce a scrivere).
local USO_PROVA = 'uso: dattilo vivo --prova <lezione.md>'
local MOTIVO_SENZA_SANDBOX = 'senza sandbox i tasti di una lezione non si provano'
-- Un byte che UTF-8 non ha (0x80 0xFD 0x68 è <Cmd>) in una riga di codice, eseguita da un registro, torna tasto speciale
local MOTIVO_NON_UTF8 = 'la lezione contiene byte che non sono UTF-8 valido: non si prova (in un registro potrebbero tornare tasti speciali di Neovim)'
local TETTO_PROVA = 9000 -- ms: la mod aspetta al massimo 10 s, e una soluzione che non finisce va fermata prima
local ATTESA_DOPO_IL_TETTO = 500 -- ms: dopo il SIGKILL, quanto aspettare che il sistema chiuda il processo
local MAX_RISULTATO = 4 * 1024 * 1024 -- byte: quanto può essere grande il file che il figlio lascia
local MAX_STDERR = 4096 -- byte dello stderr del figlio che si tengono, per dire cosa non è andato

-- Le chiavi stanno nell'ordine del contratto: vim.json.encode non lo garantisce.
local function json_si(tasti)
  local modifiche = {}
  for i, n in ipairs(tasti) do modifiche[i] = vim.json.encode({ tasti = n }) end
  return '{"ok":true,"modifiche":[' .. table.concat(modifiche, ',') .. ']}'
end

-- Il motivo può contenere testo della lezione o del figlio: strtrans lo rende sempre testo stampabile e UTF-8 valido.
local function json_no(motivo)
  local ok, pulito = pcall(vim.fn.strtrans, motivo)
  if not ok then pulito = motivo:gsub('[^\32-\126]', '?') end
  return '{"ok":false,"motivo":' .. vim.json.encode(pulito) .. '}'
end

-- Il testo del file e le sue informazioni, o nil se non è un file normale che si legge (un link non si segue).
local function leggi_lezione(file)
  local st = vim.uv.fs_lstat(file)
  if not st or st.type ~= 'file' then return nil end
  local f = io.open(file, 'rb')
  if not f then return nil end
  local testo = f:read('*a')
  f:close()
  return testo, st
end

-- Riscrive le righe par: in modo atomico: un file nuovo nella stessa cartella (il nome non finisce in .md, perché
-- dattilo vivo legge lezioni/*.md), con il modo di prima, e poi fs_rename. Ritorna true, o false e il motivo; se non si
-- riesce a scrivere (cartella non scrivibile, disco pieno) il terzo valore è true: è l'ambiente, non la lezione.
local function riscrivi_par(file, testo, st, L, tasti)
  local righe = vim.split(testo, '\n', { plain = true })
  local cambiato = false
  for i, m in ipairs(L.modifiche) do
    local vecchia = righe[m.par_riga]
    if not vecchia or not vecchia:match('^par:') then return false, 'modifica ' .. i .. ': non trovo la riga par: da riscrivere' end
    local nuova = 'par: ' .. tasti[i] .. (vecchia:match('\r$') or '')
    if nuova ~= vecchia then righe[m.par_riga] = nuova cambiato = true end
  end
  if not cambiato then return true end
  local contenuto = table.concat(righe, '\n')
  local tmp = string.format('%s.par-%d-%d', file, vim.uv.os_getpid(), vim.uv.hrtime() % 1000000000)
  local fd, e = vim.uv.fs_open(tmp, 'wx', tonumber('600', 8))
  if not fd then return false, 'non riesco a riscrivere il par: ' .. tostring(e), true end
  local scritti, e2 = vim.uv.fs_write(fd, contenuto)
  vim.uv.fs_close(fd)
  local ok, e3 = scritti == #contenuto, e2
  if ok then ok, e3 = vim.uv.fs_chmod(tmp, st.mode % 4096) end
  if ok then ok, e3 = vim.uv.fs_rename(tmp, file) end
  if not ok then
    vim.uv.fs_unlink(tmp)
    return false, 'non riesco a riscrivere il par: ' .. tostring(e3), true
  end
  return true
end

-- Cosa ha lasciato il figlio nella sua cartella: per ogni Modifica le righe del buffer alla fine, o l'errore dei tasti.
-- È un file scritto da codice non fidato: si legge solo se è un file normale e non enorme, e si controlla il tipo di tutto.
local function leggi_risultato(cartella, quante)
  local file = cartella .. '/risultato.json'
  local st = vim.uv.fs_lstat(file)
  if not st or st.type ~= 'file' or st.size > MAX_RISULTATO then return nil end
  local f = io.open(file, 'rb')
  if not f then return nil end
  local testo = f:read('*a')
  f:close()
  local ok, d = pcall(vim.json.decode, testo)
  if not ok or type(d) ~= 'table' or #d ~= quante then return nil end
  for i = 1, quante do
    local v = d[i]
    if type(v) ~= 'table' then return nil end
    if type(v.errore) ~= 'string' then
      if type(v.righe) ~= 'table' then return nil end
      for _, riga in ipairs(v.righe) do if type(riga) ~= 'string' then return nil end end
    end
  end
  return d
end

-- Lancia il figlio con un tetto di tempo. Dello stdout non si prende niente; dello stderr un pezzo, per i messaggi.
-- Ritorna il risultato di vim.system (code, signal), o nil se è scaduto il tempo, e lo stderr.
-- Non si usa wait(): se un discendente tiene aperto lo stderr dopo la morte del figlio, wait() ritorna nil dopo il doppio del tetto.
local function lancia_figlio(cmd, tetto)
  local pezzi, tot, risultato = {}, 0, nil
  local ok, proc = pcall(vim.system, cmd, {
    stdout = false,
    stderr = function(_, dati)
      if dati and tot < MAX_STDERR then pezzi[#pezzi + 1] = dati:sub(1, MAX_STDERR - tot) tot = tot + #dati end
    end,
  }, function(r) risultato = r end)
  if not ok then return nil, 'non riesco a lanciare la prova: ' .. tostring(proc) end
  if not vim.wait(tetto, function() return risultato ~= nil end, 10) then
    -- bwrap muore, e con lui il namespace dei pid: nessun discendente resta vivo
    pcall(proc.kill, proc, 9)
    vim.wait(ATTESA_DOPO_IL_TETTO, function() return risultato ~= nil end, 10)
    return nil, nil, true
  end
  return risultato, table.concat(pezzi)
end

local function prima_riga(testo, max)
  local r = (testo or ''):match('[^\n]+')
  return r and r:sub(1, max or 200)
end

-- Il lavoro di fuori: formato, figlio nella sandbox, verdetto, par. `cartella` è la cartella temporanea del figlio.
-- Ritorna l'uscita e la riga JSON.
local function giudica(assoluto, testo, st, L, cartella)
  local compila = require('dattilo.compila')
  local dir = vim.fs.dirname(assoluto)
  local cmd = compila.argomenti_sandbox({ cartella }, { radice, dir }, { 'nvim' })
  vim.list_extend(cmd, { '--chdir', cartella, '--', 'nvim', '--clean', '--headless', '-l', radice .. '/lua/dattilo/cli.lua',
    'vivo-prova-figlio', assoluto, cartella })
  local tetto = tonumber(vim.env.DATTILO_PROVA_TETTO) or TETTO_PROVA
  local r, detto, scaduto = lancia_figlio(cmd, tetto)
  if scaduto then
    return 1, json_no('la prova ha superato il tempo massimo di ' .. string.format('%g', tetto / 1000) .. ' secondi ed è stata fermata')
  end
  if not r then return 1, json_no(detto) end
  local d = r.code == 0 and leggi_risultato(cartella, #L.modifiche)
  if not d then
    local riga = prima_riga(detto)
    -- bwrap che non parte è un problema dell'ambiente, non della lezione
    if riga and riga:find('^bwrap:') then return 2, json_no('la sandbox non è partita: ' .. riga) end
    return 1, json_no('la prova non è riuscita (uscita ' .. tostring(r.code) .. (r.signal ~= 0 and (', segnale ' .. r.signal) or '')
      .. ')' .. (riga and (': ' .. riga) or ''))
  end
  local esercizio = require('dattilo.esercizio')
  local tasti = {}
  for i, m in ipairs(L.modifiche) do
    if d[i].errore then return 1, json_no('modifica ' .. i .. ': la soluzione dà errore: ' .. (prima_riga(d[i].errore, 300) or '')) end
    local righe = d[i].righe
    if not vim.deep_equal(righe, m.obiettivo) then
      local n = 1
      while n <= math.max(#righe, #m.obiettivo) and righe[n] == m.obiettivo[n] do n = n + 1 end
      return 1, json_no('modifica ' .. i .. ': i tasti non arrivano all\'obiettivo (riga ' .. n .. ' diversa)')
    end
    tasti[i] = esercizio.conta_tasti(m.soluzione)
  end
  local ok, motivo, ambiente = riscrivi_par(assoluto, testo, st, L, tasti)
  if not ok then return ambiente and 2 or 1, json_no(motivo) end
  return 0, json_si(tasti)
end

local function prova_lezione(assoluto, testo, st)
  if not require('dattilo.formato').utf8_valido(testo) then return 1, json_no(MOTIVO_NON_UTF8) end
  local L, err = require('dattilo.formato').lezione(testo, vim.fn.fnamemodify(assoluto, ':t'), 1)
  if not L then
    local parti = {}
    for _, x in ipairs(err) do parti[#parti + 1] = 'riga ' .. tostring(x.riga) .. ': ' .. x.msg end
    return 1, json_no(table.concat(parti, '; '))
  end
  if #L.modifiche == 0 then return 0, json_si({}) end
  local cartella = vim.fn.tempname()
  local ok, e = vim.uv.fs_mkdir(cartella, tonumber('700', 8))
  if not ok then return 2, json_no('non riesco a creare la cartella temporanea della prova: ' .. tostring(e)) end
  local fatto, code, riga = pcall(giudica, assoluto, testo, st, L, cartella)
  vim.fn.delete(cartella, 'rf')
  if not fatto then return 1, json_no('la prova si è fermata: ' .. tostring(code)) end
  return code, riga
end

-- La guardia del figlio, messa prima dei tasti: la lista di formato.lua guarda il testo dei tasti, ma un comando può nascere
-- da un registro (@a dopo yy, @.), da !{movimento} o da una mappatura di Neovim, e lì nei tasti non c'è nessun «:».
-- Ogni riga dei comandi che sta per partire passa dalla stessa lista (più stretta, vedi comando_che_parte_non_ammesso) e
-- se non la passa si annulla; le righe di tipo = @ > - (espressioni, input, debug) si annullano sempre (tranne
-- reg_recorded(), che è di Neovim per Q in Visual-linea). K e gx lanciano programmi, gf apre il file sotto il cursore
-- (magari la lezione stessa: ci si copierebbe l'obiettivo): in Normal e Visual non fanno niente.
-- Ritorna la lista dei comandi fermati.
function M.proteggi_figlio()
  local formato = require('dattilo.formato')
  local fermati = {}
  vim.api.nvim_create_autocmd('CmdlineLeave', {
    callback = function()
      if vim.v.event.abort then return end
      local tipo, riga = vim.fn.getcmdtype(), vim.fn.getcmdline()
      local motivo
      if tipo == ':' then motivo = formato.comando_che_parte_non_ammesso(riga)
      elseif tipo == '=' then -- l'unica espressione ammessa è quella della mappatura di Neovim per Q in Visual-linea
        if riga ~= 'reg_recorded()' then motivo = 'espressione' end
      elseif tipo ~= '/' and tipo ~= '?' then motivo = 'riga dei comandi di tipo ' .. tipo end
      if motivo then
        fermati[#fermati + 1] = tipo .. riga
        vim.cmd('let v:event.abort = v:true')
      end
    end,
  })
  for _, modo in ipairs({ 'n', 'x' }) do
    for _, tasto in ipairs({ 'K', 'gx', 'gf', 'gF', '<C-w>f', '<C-w><C-f>', '<C-w>F', '<C-w>gf', '<C-w>gF' }) do
      vim.keymap.set(modo, tasto, '<Nop>')
    end
  end
  return fermati
end

-- Il figlio: gira dentro la sandbox, rifà i tasti di ogni Modifica e lascia in `cartella` il testo che il buffer ha alla fine.
-- Non decide niente e non stampa niente sullo stdout.
local function comando_figlio(args)
  local file, cartella = args[2], args[3]
  local testo = file and cartella and leggi_lezione(file)
  if not testo then io.stderr:write('vivo-prova-figlio: uso: <lezione> <cartella>\n') return 2 end
  -- Solo dentro la sandbox: bwrap mette DATTILO_IN_SANDBOX e la cartella della lezione in sola lettura. Una variabile
  -- messa a mano non basta: fuori da bwrap quella cartella si scrive.
  if vim.env.DATTILO_IN_SANDBOX ~= '1' or vim.uv.fs_access(vim.fs.dirname(file), 'W') or not vim.uv.fs_access(cartella, 'W') then
    io.stderr:write('vivo-prova-figlio: si lancia solo da dattilo vivo --prova, dentro la sandbox\n')
    return 2
  end
  -- ricontrollato qui: il file può essere cambiato fra la lettura del padre e questa
  if not require('dattilo.formato').utf8_valido(testo) then io.stderr:write('vivo-prova-figlio: la lezione non è UTF-8 valido\n') return 1 end
  local L = require('dattilo.formato').lezione(testo, vim.fn.fnamemodify(file, ':t'), 1)
  if not L then io.stderr:write('vivo-prova-figlio: la lezione non si legge\n') return 1 end
  local controlla = require('dattilo.controlla')
  local risultati = {}
  local fermati = M.proteggi_figlio()
  for i, m in ipairs(L.modifiche) do
    local prima = #fermati
    local righe, e = controlla.prova_soluzione(m)
    if #fermati > prima then
      -- un comando fuori lista è stato annullato: la soluzione non è quella che la lista ammette, qualunque cosa sia uscita
      risultati[i] = { errore = 'un comando non ammesso è stato fermato mentre giravano i tasti: ' .. fermati[prima + 1] }
    else
      risultati[i] = righe and { righe = righe } or { errore = tostring(e) }
    end
  end
  local f = assert(io.open(cartella .. '/risultato.json', 'wb'))
  f:write(vim.json.encode(risultati))
  f:close()
  return 0
end

-- vivo-prova: controlla l'uso e il file, e che ci sia la sandbox. vivo-prova-figlio: il lavoro dentro la sandbox.
local function comando_vivo_prova(args)
  local function esci(code, riga) scrivi(riga) return code end
  local file = args[2]
  if args[3] or not file or file == '' then return esci(2, json_no(USO_PROVA)) end
  local testo, st = leggi_lezione(file)
  if not testo then return esci(2, json_no(USO_PROVA)) end
  if not require('dattilo.compila').sandbox() then return esci(2, json_no(MOTIVO_SENZA_SANDBOX)) end
  return esci(prova_lezione(vim.fn.fnamemodify(file, ':p'), testo, st))
end

-- dattilo vivo --dove: la mod chiede se c'è, e dove sta. vivo = 2: sa anche fare --prova
local function comando_vivo_dove()
  scrivi(vim.json.encode({ vivo = 2, radice = radice }))
  return 0
end

function M.main(args)
  local c = args[1]
  if c == 'importa' then return comando_importa(args)
  elseif c == 'esporta' then return comando_esporta(args)
  elseif c == 'pacchetti' then return comando_pacchetti()
  elseif c == 'nuovo' then return comando_nuovo(args)
  elseif c == 'controlla' then return comando_controlla(args)
  elseif c == 'vivo-prova' then return comando_vivo_prova(args)
  elseif c == 'vivo-prova-figlio' then return comando_figlio(args)
  elseif c == 'riempi' then return comando_riempi(args)
  elseif c == 'vivo-dove' then return comando_vivo_dove() end
  scrivi('uso: dattilo [importa <file> | esporta <id> [file] | pacchetti | nuovo <cartella> | controlla [--tip] <cartella> [lezione] | riempi <lezione.md>]')
  return c and 1 or 0
end

-- eseguito come script (nvim -l): non quando lo carica un test con require
if arg and arg[0] and vim.fn.fnamemodify(arg[0], ':p') == vim.fn.fnamemodify(qui, ':p') then
  vim.o.showmode = false
  os.exit(M.main(arg))
end

return M
