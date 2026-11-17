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

function M.main(args)
  local c = args[1]
  if c == 'importa' then return comando_importa(args)
  elseif c == 'esporta' then return comando_esporta(args)
  elseif c == 'pacchetti' then return comando_pacchetti()
  elseif c == 'nuovo' then return comando_nuovo(args)
  elseif c == 'controlla' then return comando_controlla(args) end
  scrivi('uso: dattilo [importa <file> | esporta <id> [file] | pacchetti | nuovo <cartella> | controlla [--tip] <cartella> [lezione]]')
  return c and 1 or 0
end

-- eseguito come script (nvim -l): non quando lo carica un test con require
if arg and arg[0] and vim.fn.fnamemodify(arg[0], ':p') == vim.fn.fnamemodify(qui, ':p') then
  vim.o.showmode = false
  os.exit(M.main(arg))
end

return M
