-- Formato: la Modifica che parte da un codice suo (```js partenza), i Tasti spiegati uno per uno,
-- e le lezioni di oggi che si devono leggere identiche a prima.
local formato = require('dattilo.formato')
local controlla = require('dattilo.controlla')
local T = {}

local function leggi(p) return table.concat(vim.fn.readfile(p), '\n') end
local FIXTURE = RADICE .. '/tests/fixture/rifallo-b/dati/dattilo/pacchetti/rifallo'
local SOSIA = leggi(FIXTURE .. '/lezioni/001-sosia.md')
local COMPLETA = leggi(RADICE .. '/tests/fixture/lezione-completa.md')

-- Sostituisce una stringa che nel testo c'è una volta sola.
local function cambia(testo, vecchio, nuovo)
  local da, a = testo:find(vecchio, 1, true)
  assert(da, 'nel testo non c\'è: ' .. vecchio)
  assert(not testo:find(vecchio, a + 1, true), 'nel testo c\'è più di una volta: ' .. vecchio)
  return testo:sub(1, da - 1) .. nuovo .. testo:sub(a + 1)
end

-- Rimpiazza tutto il blocco ### Tasti della lezione con le righe date.
local function con_tasti(testo, righe)
  local nuovo, n = testo:gsub('\n### Tasti\n.-\n\n## Spiegazione', function() return '\n### Tasti\n' .. table.concat(righe, '\n') .. '\n\n## Spiegazione' end)
  assert(n == 1, 'il blocco ### Tasti non si è trovato')
  return nuovo
end

local PARTENZA = {
  'export function codicePulito(t) {',
  '  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");',
  '  if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;',
  '  return `${c.slice(0, 4)}-${c.slice(4)}`;',
  '}',
}
local OBIETTIVO = vim.deepcopy(PARTENZA)
OBIETTIVO[2] = '  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/[O0U]/g, (x) => SIMILI[x]);'

---------------------------------------------------------------- come si leggono oggi le lezioni
-- Queste prove fissano la lettura di una Modifica senza blocco partenza e senza Tasti:
-- c'erano prima del codice nuovo e devono restare verdi.
T['oggi: una Modifica senza partenza propria si legge campo per campo come prima'] = function()
  local L, err = formato.lezione(COMPLETA, '01-hello.md', 1)
  uguale(err, {})
  uguale(#L.modifiche, 2)
  local m1, m2 = L.modifiche[1], L.modifiche[2]
  local function senza_testi(m)
    local c = vim.deepcopy(m)
    c.partenza, c.obiettivo = nil, nil
    return c
  end
  uguale(senza_testi(m1), {
    titolo = 'Modifica 1/2', consegna = 'Fallo parlare italiano.', aiuto = '‹3j› scende di tre righe.',
    soluzione = '3jci"Ciao mondo\\n<Esc>', pos = { 0, 0 }, par = 18, par_riga = 45,
    blocco = { riga = 48, n = 6 }, mostra = { '3j', 'ci"', 'Ciao mondo\\n', 'Esc' },
  })
  uguale(senza_testi(m2), {
    titolo = 'Modifica 2/2', consegna = 'Ritorna uno.', aiuto = '‹r1›.', soluzione = 'r1', pos = { 4, 11 }, pos_riga = 60,
    par = 2, par_riga = 61, blocco = { riga = 64, n = 6 }, mostra = { 'r1' },
  })
  uguale(m1.partenza, L.batti.codice)
  uguale(m1.obiettivo, { '#include <stdio.h>', '', 'int main(void) {', '    printf("Ciao mondo\\n");', '    return 0;', '}' })
  uguale(m2.partenza, m1.obiettivo)
  uguale(m2.obiettivo[5], '    return 1;')
  uguale({ m1.partenza_propria, m1.tasti, m2.partenza_propria, m2.tasti }, {})
end

T['oggi: senza blocco partenza e senza Tasti il pos si controlla sul testo della catena'] = function()
  local base = '---\ntitolo: X\nfile: a.js\n---\n## Batti\n```js\nlet x = 1;\n```\n## Modifica\nconsegna: c\npar: 9\nsoluzione: ciwconst<Esc>\n%s```js\nconst x = 1;\n```\n'
  local L = formato.lezione(base:format(''), 'x.md', 1)
  uguale(L.modifiche[1].mostra, { 'ciwconst<Esc>' })
  local _, err = formato.lezione(base:format('pos: 1:99\n'), 'x.md', 1)
  uguale(#err, 1)
  uguale(err[1].msg, 'pos fuori dal testo di partenza')
end

T['le lezioni di oggi si leggono come prima'] = function()
  local files = vim.fn.glob(RADICE .. '/pacchetti/**/*.md', false, true)
  vim.list_extend(files, vim.fn.glob(RADICE .. '/tests/fixture/**/*.md', false, true))
  files = vim.tbl_filter(function(f) return not f:find('/rifallo-b/', 1, true) end, files)
  vero(#files >= 8, 'mi aspettavo almeno 8 lezioni, ne ho trovate ' .. #files)
  local verificate = 0
  for _, f in ipairs(files) do
    local L, err = formato.lezione(leggi(f), vim.fn.fnamemodify(f, ':t'), 1)
    vero(L, f .. ': ' .. vim.inspect(err))
    local partenza = L.batti.codice
    for i, m in ipairs(L.modifiche) do
      uguale(m.partenza_propria, nil, f .. ' modifica ' .. i)
      uguale(m.tasti, nil, f .. ' modifica ' .. i)
      uguale(m.partenza, partenza, f .. ' modifica ' .. i .. ': non parte dal codice di prima')
      partenza = m.obiettivo
      verificate = verificate + 1
    end
  end
  vero(verificate >= 5, 'ho verificato solo ' .. verificate .. ' modifiche')
end

---------------------------------------------------------------- la Modifica con partenza e Tasti
T['Modifica col blocco partenza e i Tasti'] = function()
  local L, err = formato.lezione(SOSIA, '001-sosia.md', 1)
  uguale(err, {})
  uguale(#L.modifiche, 1)
  local m = L.modifiche[1]
  uguale(m.titolo, 'Rifai la modifica di Claude')
  uguale(m.partenza_propria, PARTENZA)
  uguale(m.partenza, PARTENZA)
  uguale(m.partenza[2], '  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");')
  uguale(m.obiettivo, OBIETTIVO)
  uguale(m.obiettivo[2], '  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/[O0U]/g, (x) => SIMILI[x]);')
  uguale(#m.tasti, 5)
  uguale(m.tasti[1], { tasti = '2G', cosa = 'va alla riga 2' })
  uguale(m.tasti[2], { tasti = '$', cosa = 'va in fondo alla riga, sul punto e virgola' })
  uguale(m.tasti[4], { tasti = '.replace(/[O0U]/g, (x) => SIMILI[x])', cosa = 'scrive il pezzo nuovo' })
  uguale(m.mostra, { '2G', '$', 'i', '.replace(/[O0U]/g, (x) => SIMILI[x])', '<Esc>' })
  uguale(m.soluzione, '2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>')
  uguale(m.par, 41)
  uguale(m.pos, { 0, 0 })
end

T['il blocco obiettivo è quello senza partenza e m.blocco punta a lui'] = function()
  local L = formato.lezione(SOSIA, '001-sosia.md', 1)
  local m = L.modifiche[1]
  local righe = vim.split(SOSIA, '\n', { plain = true })
  uguale(righe[m.blocco.riga], '```js')
  uguale(righe[m.blocco.riga + 1], OBIETTIVO[1])
  uguale(m.blocco.n, #OBIETTIVO)
  vero(righe[m.blocco.riga - 1 - #PARTENZA - 1]:find('partenza', 1, true), 'prima dell\'obiettivo c\'è il blocco partenza')
end

T['il blocco partenza può stare anche dopo l\'obiettivo'] = function()
  -- il progetto lo mette prima, ma chi legge non dipende dall'ordine
  local partenza = table.concat(PARTENZA, '\n')
  local obiettivo = table.concat(OBIETTIVO, '\n')
  local testo = cambia(SOSIA, '```js partenza\n' .. partenza .. '\n```\n```js\n' .. obiettivo .. '\n```',
    '```js\n' .. obiettivo .. '\n```\n```js partenza\n' .. partenza .. '\n```')
  local L, err = formato.lezione(testo, '001-sosia.md', 1)
  uguale(err, {})
  local m = L.modifiche[1]
  uguale(m.partenza, PARTENZA)
  uguale(m.obiettivo, OBIETTIVO)
  local righe = vim.split(testo, '\n', { plain = true })
  uguale(righe[m.blocco.riga + 1], OBIETTIVO[1])
end

T['la partenza propria vale solo per la sua Modifica: la prossima parte dall\'obiettivo di questa'] = function()
  local due = SOSIA:gsub('\n## Spiegazione', [[

## Modifica
consegna: Metti un a capo in fondo.
par: 2
soluzione: GA<CR><Esc>
```js
export function codicePulito(t) {
}
```

## Spiegazione]])
  local L, err = formato.lezione(due, '001-sosia.md', 1)
  uguale(err, {})
  uguale(#L.modifiche, 2)
  uguale(L.modifiche[2].partenza, L.modifiche[1].obiettivo)
  uguale(L.modifiche[2].partenza_propria, nil)
  uguale(L.modifiche[2].tasti, nil)
end

T['il pos si controlla sulla partenza propria, non sul codice di Batti'] = function()
  -- la partenza propria ha 4 righe, il Batti una sola
  local testo = table.concat({ '---', 'titolo: X', 'file: a.js', '---', '## Batti', '```js', 'let x = 1;', '```',
    '## Modifica', 'consegna: c', 'pos: 4:3', 'par: 3', 'soluzione: x', '```js partenza', 'a', 'b', 'c', '  d', '```',
    '```js', 'a', '```' }, '\n')
  local L, err = formato.lezione(testo, 'x.md', 1)
  uguale(err, {})
  uguale(L.modifiche[1].pos, { 3, 2 })
  -- una riga che nella partenza propria non c'è
  local _, err2 = formato.lezione((testo:gsub('pos: 4:3', 'pos: 5:1')), 'x.md', 1)
  uguale(#err2, 1)
  uguale(err2[1].msg, 'pos fuori dal testo di partenza')
  -- una colonna oltre la riga della partenza propria
  local _, err3 = formato.lezione((testo:gsub('pos: 4:3', 'pos: 4:9')), 'x.md', 1)
  uguale(err3[1].msg, 'pos fuori dal testo di partenza')
end

T['con ### Tasti i pezzi sono mostra, anche se c\'è mostra:'] = function()
  local testo = cambia(SOSIA, 'par: 41\n', 'par: 41\nmostra: a · b\n')
  local L, err = formato.lezione(testo, '001-sosia.md', 1)
  uguale(err, {})
  uguale(L.modifiche[1].mostra, { '2G', '$', 'i', '.replace(/[O0U]/g, (x) => SIMILI[x])', '<Esc>' })
end

T['senza ### Tasti ma con la partenza: mostra è quello di sempre'] = function()
  local testo = SOSIA:gsub('\n### Tasti.-\n\n## Spiegazione', '\n## Spiegazione')
  vero(not testo:find('### Tasti', 1, true))
  local L, err = formato.lezione(testo, '001-sosia.md', 1)
  uguale(err, {})
  uguale(L.modifiche[1].tasti, nil)
  uguale(L.modifiche[1].partenza_propria, PARTENZA)
  uguale(L.modifiche[1].mostra, { '2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>' })
end

T['i Tasti: righe vuote saltate, spazi del pezzo conservati, la cosa ripulita'] = function()
  -- il pezzo " b" ha uno spazio davanti: va tenuto, perché fa parte dei tasti
  local testo = [[
---
titolo: X
file: a.js
---
## Batti
```js
x
```
## Modifica
consegna: c
par: 5
soluzione: a b<Esc>
```js
y
```

### Tasti
- a | scrive a

-  b | scrive b
- <Esc> | esce
]]
  local L, err = formato.lezione(testo, 'x.md', 1)
  uguale(err, {})
  uguale(L.modifiche[1].tasti, { { tasti = 'a', cosa = 'scrive a' }, { tasti = ' b', cosa = 'scrive b' }, { tasti = '<Esc>', cosa = 'esce' } })
end

T['i Tasti: si divide al primo " | " e i pezzi con <Bar> restano scritti così'] = function()
  local testo = [[
---
titolo: X
file: a.js
---
## Batti
```js
x
```
## Modifica
consegna: c
par: 5
soluzione: a<Bar>b<Esc>
```js
y
```
### Tasti
- a<Bar>b | scrive a | b e va avanti
- <Esc> | esce
]]
  local L, err = formato.lezione(testo, 'x.md', 1)
  uguale(err, {})
  uguale(L.modifiche[1].tasti[1], { tasti = 'a<Bar>b', cosa = 'scrive a | b e va avanti' })
end

---------------------------------------------------------------- gli errori
local function errori(testo)
  local L, err = formato.lezione(testo, '001-sosia.md', 1)
  uguale(L, nil)
  return err
end

T['due blocchi partenza: errore'] = function()
  local blocco = '```js partenza\n' .. table.concat(PARTENZA, '\n') .. '\n```\n'
  local err = errori(cambia(SOSIA, blocco, blocco .. blocco))
  uguale(#err, 1)
  uguale(err[1].msg, 'la Modifica ha due blocchi partenza')
  vero(err[1].riga > 1, 'la riga dell\'errore')
end

T['una riga dei Tasti senza " | ": errore, uno solo'] = function()
  local err = errori(cambia(SOSIA, '- 2G | va alla riga 2', '- 2G va alla riga 2'))
  uguale(#err, 1)
  uguale(err[1].msg, 'riga non valida nei Tasti: scrivi - tasti | cosa fanno')
  -- l'errore ha la riga di quella riga
  local righe = vim.split(SOSIA, '\n', { plain = true })
  for i, r in ipairs(righe) do if r == '- 2G | va alla riga 2' then uguale(err[1].riga, i) end end
end

T['una riga dei Tasti con tasti o cosa vuoti: errore'] = function()
  for _, sbagliata in ipairs({ '-  | va alla riga 2', '- 2G | ', '- 2G |', 'testo senza il trattino | va alla riga 2' }) do
    local err = errori(cambia(SOSIA, '- 2G | va alla riga 2', sbagliata))
    uguale(err[1].msg, 'riga non valida nei Tasti: scrivi - tasti | cosa fanno', sbagliata)
  end
end

T['i Tasti che non fanno la soluzione: errore'] = function()
  local err = errori(cambia(SOSIA, '- 2G | va alla riga 2', '- 3G | va alla riga 3'))
  uguale(#err, 1)
  uguale(err[1].msg, 'i Tasti messi in fila non sono la soluzione')
  -- anche se mancano dei pezzi
  err = errori(cambia(SOSIA, '- <Esc> | esce dalla scrittura\n', ''))
  uguale(err[1].msg, 'i Tasti messi in fila non sono la soluzione')
end

T['con una riga dei Tasti non valida non esce anche l\'errore della fila'] = function()
  local err = errori(cambia(cambia(SOSIA, '- 2G | va alla riga 2', '- 2G va alla riga 2'), '- i | entra', '- 3 | entra'))
  for _, e in ipairs(err) do vero(e.msg ~= 'i Tasti messi in fila non sono la soluzione', vim.inspect(err)) end
end

T['### Tasti vuoto: errore, i pezzi non sono la soluzione'] = function()
  local err = errori(con_tasti(SOSIA, {}))
  uguale(err[1].msg, 'i Tasti messi in fila non sono la soluzione')
end

T['solo il blocco partenza, senza obiettivo: errore'] = function()
  local partenza = '```js partenza\n' .. table.concat(PARTENZA, '\n') .. '\n```\n'
  local err = errori(cambia(SOSIA, partenza .. '```js\n' .. table.concat(OBIETTIVO, '\n') .. '\n```\n', partenza))
  uguale(#err, 1)
  uguale(err[1].msg, 'la Modifica non ha il blocco con il testo obiettivo')
end

T['i comandi non ammessi nella soluzione restano un errore anche con i Tasti'] = function()
  local testo = con_tasti(cambia(SOSIA, 'soluzione: 2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>', 'soluzione: :!ls<CR>'),
    { '- :!ls<CR> | esegue' })
  local err = errori(testo)
  uguale(#err, 1)
  vero(err[1].msg:find('!', 1, true), vim.inspect(err))
end

---------------------------------------------------------------- controlla e riempi
T['controlla e riempi funzionano con la partenza'] = function()
  local r = controlla.pacchetto(FIXTURE, '001-sosia')
  local sul_sosia = vim.tbl_filter(function(x) return x.testo:find('modifica', 1, true) end, r.righe)
  uguale(sul_sosia, { { stato = 'ok', testo = '001-sosia: modifica 1 in 41 tasti' } })
  for _, x in ipairs(r.righe) do
    vero(not (x.stato == 'errore' and x.testo:find('soluzione', 1, true)), x.testo)
  end

  -- riempi parte da un obiettivo sbagliato e da par: 0, e riscrive l'obiettivo dalla partenza
  local testo = cambia(cambia(SOSIA, 'par: 41', 'par: 0'),
    table.concat(OBIETTIVO, '\n') .. '\n```\n\n### Tasti', 'sbagliato\n```\n\n### Tasti')
  local nuovo, resoconto = controlla.riempi(testo, '001-sosia.md')
  vero(nuovo, vim.inspect(resoconto))
  uguale(nuovo, SOSIA)
  local L = formato.lezione(nuovo, '001-sosia.md', 1)
  uguale(L.modifiche[1].obiettivo, OBIETTIVO)
  uguale(L.modifiche[1].partenza_propria, PARTENZA)
  uguale(L.modifiche[1].par, 41)
  vero(resoconto[1]:find('41 tasti', 1, true), resoconto[1])
end

return T
