-- Casi trovati dalla revisione finale del ramo pacchetti.
local formato = require('dattilo.formato')
local scambio = require('dattilo.scambio')
local T = {}
local JS = RADICE .. '/tests/fixture/js-prova'
local LEZ = '---\ntitolo: X\nfile: main.js\n%s---\n%s## Batti\n```js\nconsole.log(1)\n```\n%s'
local function xdg_nuovo()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo.pacchetti').dimentica()
  return vim.env.XDG_DATA_HOME
end
local function man(campi)
  local m = { id = 'prova', titolo = 'Prova', versione = '1.0.0', linguaggio = 'javascript', esecuzione = { tipo = 'comando', comando = { 'node', '{file}' } } }
  for k, v in pairs(campi) do m[k] = v end
  return vim.json.encode(m)
end

T['controlla gira in sandbox: un filtro ! nella soluzione non tocca il sistema'] = function()
  if not require('dattilo.compila').sandbox() then return end
  local segno = vim.fn.expand('~') .. '/.dattilo-segno-controlla'
  vim.fn.delete(segno)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/lezioni', 'p')
  vim.fn.writefile(vim.split(man({}), '\n'), dir .. '/pacchetto.json')
  local lez = '---\ntitolo: X\nfile: main.js\n---\n## Batti\n```js\nconsole.log(1)\nconsole.log(2)\n```\n## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: !jtouch ' .. segno .. '<CR>\n```js\nconsole.log(1)\n```\n'
  vim.fn.writefile(vim.split(lez, '\n'), dir .. '/lezioni/01-a.md')
  require('dattilo.cli').main({ 'controlla', dir })
  uguale(vim.fn.filereadable(segno), 0)
end
T['soluzione: :<C-u>! non passa'] = function()
  local L = formato.lezione(LEZ:format('', '', '## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: :<C-u>!echo x<CR>\n```js\ny\n```\n'), '01.md', 1)
  uguale(L, nil)
end
T['manifesto: campi del tipo sbagliato rifiutati'] = function()
  for _, campi in ipairs({ { autore = 5 }, { descrizione = {} }, { richiede = { {} } }, { richiede = 'aton' }, { in_arrivo = { 5 } },
      { in_arrivo = { { titolo = 3 } } }, { versione = '1.0/x' }, { titolo = { 'a' } } }) do
    local m, err = formato.manifesto(man(campi), 'pacchetto.json')
    vero(m == nil and #err > 0, 'accettato: ' .. vim.inspect(campi))
  end
end
T['manifesto: null vale come campo assente'] = function()
  local m, err = formato.manifesto('{"id":"prova","titolo":"Prova","versione":"1","autore":null,"descrizione":null,"richiede":null,"esecuzione":{"tipo":"comando","comando":["node","{file}"]}}', 'p.json')
  uguale(err, {})
  uguale({ m.autore, m.descrizione, m.richiede }, { '', '', {} })
end
T['lezione: campi del tipo sbagliato rifiutati'] = function()
  for _, fm in ipairs({ 'titolo: [a, b]\n', 'breve: [x]\n', 'mosse: x\n', 'tempo: [1]\n', 'video: [x]\n', 'video: \n', 'video: abc\nvideo_da: tre\n' }) do
    local testo = ('---\nfile: main.js\n%s---\n## Batti\n```js\nx\n```\n'):format(fm:find('^titolo') and fm or ('titolo: X\n' .. fm))
    vero(formato.lezione(testo, '01.md', 1) == nil, 'accettato: ' .. fm)
  end
end
T['lezione: pos fuori dal testo di partenza rifiutato'] = function()
  local L = formato.lezione(LEZ:format('', '', '## Modifica\nconsegna: x\naiuto: x\npos: 9:1\npar: 1\nsoluzione: x\n```js\ny\n```\n'), '01.md', 1)
  uguale(L, nil)
  L = formato.lezione(LEZ:format('', '', '## Modifica\nconsegna: x\naiuto: x\npos: 1:40\npar: 1\nsoluzione: x\n```js\ny\n```\n'), '01.md', 1)
  uguale(L, nil)
end
T['lezione: Rompi senza esempio rifiutato'] = function()
  local L = formato.lezione(LEZ:format('', '', '## Rompi\nconsegna: x\nattesa: errore\n'), '01.md', 1)
  uguale(L, nil)
end
T['pacchetto: warning solo con compila'] = function()
  local xdg = xdg_nuovo()
  local dir = xdg .. '/dattilo/pacchetti/prova'
  vim.fn.mkdir(dir .. '/lezioni', 'p')
  vim.fn.writefile(vim.split(man({}), '\n'), dir .. '/pacchetto.json')
  vim.fn.writefile(vim.split(LEZ:format('', '', '## Rompi\nconsegna: x\nattesa: warning\n```js\nx(\n```\n'), '\n'), dir .. '/lezioni/01-a.md')
  local P = require('dattilo.pacchetti').carica('prova')
  uguale(#P.lezioni, 0)
  vero(P.errori[1] and P.errori[1].msg:find('warning', 1, true), vim.inspect(P.errori))
  local dati = scambio.leggi((scambio.esporta(dir)))
  uguale(dati, nil)
end
T['.dattilo con BOM si importa'] = function()
  local dati, err = scambio.leggi('\239\187\191' .. scambio.esporta(JS))
  uguale(err, {})
  vero(dati ~= nil)
end
T['lezione con BOM si legge'] = function()
  local L = formato.lezione('\239\187\191' .. LEZ:format('', '', ''), '01.md', 1)
  vero(L ~= nil)
end
T['installazione fallita a metà non lascia avanzi'] = function()
  local xdg = xdg_nuovo()
  local testo = scambio.esporta(JS) .. '--- file: lezioni/01-somma.md/x.md\nciao\n'
  local dati = scambio.leggi(testo)
  if dati then
    local ok = pcall(scambio.installa, dati, {})
    vero(ok, 'installa non deve lanciare errori')
  end
  local voci = vim.fn.glob(xdg .. '/dattilo/pacchetti/*', false, true)
  vero(#voci <= 1, vim.inspect(voci))
  for _, v in ipairs(require('dattilo.pacchetti').elenco()) do vero(not v.id:find('nuovo', 1, true), v.id) end
end
T['elenco ignora cartelle con nomi non validi'] = function()
  local xdg = xdg_nuovo()
  local dir = xdg .. '/dattilo/pacchetti/js-prova.nuovo-123'
  vim.fn.mkdir(dir .. '/lezioni', 'p')
  vim.fn.writefile(vim.fn.readfile(JS .. '/pacchetto.json'), dir .. '/pacchetto.json')
  for _, v in ipairs(require('dattilo.pacchetti').elenco()) do vero(not v.cartella:find('nuovo', 1, true), v.cartella) end
end
T['anteprima dice quale comando esegue il codice'] = function()
  xdg_nuovo()
  local righe = table.concat(scambio.anteprima((scambio.leggi((scambio.esporta(JS))))), '\n')
  vero(righe:find('node main.js', 1, true) or righe:find('node {file}', 1, true), righe)
end
local function righe_briefing(lez)
  local xdg = xdg_nuovo()
  local dir = xdg .. '/dattilo/pacchetti/prova'
  vim.fn.mkdir(dir .. '/lezioni', 'p')
  vim.fn.writefile(vim.split(man({}), '\n'), dir .. '/pacchetto.json')
  vim.fn.writefile(vim.split(lez, '\n'), dir .. '/lezioni/01-a.md')
  require('dattilo').avvia({ radice = RADICE })
  require('dattilo.lezione').apri('prova', 1)
  local r = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  require('dattilo.lezione').chiudi()
  return r
end
T['briefing: senza mosse ma con concetti mostra i concetti e niente Mosse vuote'] = function()
  local r = table.concat(righe_briefing(LEZ:format('concetti: [uno, due]\n', '## Briefing\nciao\n', '')), '\n')
  vero(r:find('uno · due', 1, true), r)
  vero(not r:find('Mosse nuove', 1, true), r)
end
T['briefing: mai due righe vuote di fila'] = function()
  local r = righe_briefing(LEZ:format('', '', ''))
  for i = 2, #r do vero(not (r[i] == '' and r[i - 1] == ''), 'righe vuote doppie alla ' .. i .. ': ' .. vim.inspect(r)) end
end
T['testi giusti per i pacchetti non C'] = function()
  local L = formato.lezione(LEZ:format('', '', ''), '01.md', 1)
  L.esecuzione, L.linguaggio, L.pacchetto = { tipo = 'comando', comando = { 'node', '{file}' } }, 'javascript', 'prova'
  local s = { L = L, st = { finito = true, metriche = require('dattilo.metriche').nuova() }, buf = 0 }
  local _, testo = require('dattilo.lezione').tip_batti(s, 'n')
  vero(not testo:find('cc', 1, true), testo)
end
T['esportare un pacchetto rotto dalla schermata non va in errore'] = function()
  local xdg = xdg_nuovo()
  vim.fn.mkdir(xdg .. '/dattilo/pacchetti/rotto', 'p')
  vim.fn.writefile({ '{rotto' }, xdg .. '/dattilo/pacchetti/rotto/pacchetto.json')
  local voce = vim.tbl_filter(function(v) return v.cartella:find('rotto', 1, true) end, require('dattilo.pacchetti').elenco())[1]
  local ok, e = pcall(require('dattilo.home').esporta, voce)
  vero(ok, tostring(e))
end
return T
