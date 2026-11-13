local formato = require('dattilo.formato')
local compila = require('dattilo.compila')
local T = {}

local function manifesto(es)
  return vim.json.encode({ id = 'prova', titolo = 'Prova', versione = '1', linguaggio = 'javascript', esecuzione = es })
end
local function rifiutato(es)
  local m, err = formato.manifesto(manifesto(es), 'pacchetto.json')
  return m == nil and #err > 0
end
local LEZ = '---\ntitolo: X\nfile: %s\n%s---\n## Batti\n```js\nx\n```\n%s'

T['manifesto: comandi permessi'] = function()
  vero(not rifiutato({ tipo = 'comando', comando = { 'node', '{file}' } }))
  vero(not rifiutato({ tipo = 'controllo', comando = { 'node', '--check', '{file}' } }))
  vero(not rifiutato({ tipo = 'compila', compila = { 'cc', '-Wall', '-Wextra', '-O2', '-fdiagnostics-color=never', '-o', '{nome}', '{file}' }, esegui = { './{nome}' } }))
  vero(not rifiutato({ tipo = 'compila', compila = { 'gcc', '-std=c11', '-g', '-fsanitize=address,undefined', '-o', '{nome}', '{file}', '-lm' }, esegui = { './{nome}' } }))
end
T['manifesto: programmi e argomenti pericolosi rifiutati'] = function()
  vero(rifiutato({ tipo = 'comando', comando = { 'bash', '-c', 'touch /tmp/x' } }), 'bash')
  vero(rifiutato({ tipo = 'comando', comando = { 'node', '-e', 'require("fs")' } }), 'node -e')
  vero(rifiutato({ tipo = 'comando', comando = { '/usr/bin/node', '{file}' } }), 'percorso assoluto')
  vero(rifiutato({ tipo = 'controllo', comando = { 'node', '--require', '/tmp/x.js', '{file}' } }), 'node --require')
  vero(rifiutato({ tipo = 'compila', compila = { 'cc', '-fplugin=/tmp/x.so', '{file}' }, esegui = { './{nome}' } }), '-fplugin')
  vero(rifiutato({ tipo = 'compila', compila = { 'cc', '-Wl,-rpath,/x', '{file}' }, esegui = { './{nome}' } }), '-Wl')
  vero(rifiutato({ tipo = 'compila', compila = { 'cc', '-o', '/tmp/x', '{file}' }, esegui = { './{nome}' } }), '-o fuori')
  vero(rifiutato({ tipo = 'compila', compila = { 'cc', '{file}' }, esegui = { 'sh', '-c', 'x' } }), 'esegui sh')
  vero(rifiutato({ tipo = 'compila', compila = { 'cc', '@/tmp/opzioni', '{file}' }, esegui = { './{nome}' } }), '@file')
end
T['lezione: nome del file solo semplice'] = function()
  for _, f in ipairs({ '../../.bashrc', 'sub/main.js', '/tmp/main.js', '.bashrc', 'main', 'main.sh' }) do
    local L = formato.lezione(LEZ:format(f, '', ''), '01.md', 1)
    vero(L == nil, 'accettato file: ' .. f)
  end
  vero(formato.lezione(LEZ:format('main.js', '', ''), '01.md', 1) ~= nil)
  vero(formato.lezione(LEZ:format('hello.c', '', ''), '01.md', 1) ~= nil)
end
T['lezione: override di esecuzione con un comando pericoloso rifiutato'] = function()
  local L = formato.lezione(LEZ:format('main.js', 'esecuzione: comando\ncomando: [bash, -c, "touch /tmp/x"]\n', ''), '01.md', 1)
  vero(L == nil)
end
T['lezione: soluzioni che escono verso la shell o Lua rifiutate'] = function()
  for _, sol in ipairs({ ':!touch /tmp/x<CR>', ':lua os.exit()<CR>', 'i<C-r>=system("id")<CR><Esc>', ':call system("id")<CR>', ':exe "!id"<CR>', ':term<CR>', ':so /tmp/x<CR>', ':r !id<CR>', ':w /tmp/x<CR>', '!!id<CR>', ':sh<CR>' }) do
    local mod = '## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: ' .. sol .. '\n```js\ny\n```\n'
    local L = formato.lezione(LEZ:format('main.js', '', mod), '01.md', 1)
    vero(L == nil, 'accettata soluzione: ' .. sol)
  end
  local ok = formato.lezione(LEZ:format('main.js', '', '## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: :%s/a/b/g<CR>\n```js\ny\n```\n'), '01.md', 1)
  vero(ok ~= nil, ':%s deve restare permesso')
  for _, sol in ipairs({ 'ci{ color: 0x888888 <Esc>', 'A // nota: x<Esc>' }) do
    local L = formato.lezione(LEZ:format('main.js', '', '## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: ' .. sol .. '\n```js\ny\n```\n'), '01.md', 1)
    vero(L ~= nil, 'rifiutato testo innocuo: ' .. sol)
  end
  for _, sol in ipairs({ ':12<CR>', ':sort<CR>', ':noh<CR>', ':s/a/b/<CR>' }) do
    local L = formato.lezione(LEZ:format('main.js', '', '## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: ' .. sol .. '\n```js\ny\n```\n'), '01.md', 1)
    vero(L ~= nil, 'rifiutato comando innocuo: ' .. sol)
  end
  for _, sol in ipairs({ ':!id<Enter>', ':w /tmp/x<C-m>', ':lua x()<NL>', ':g/./call system("id")<CR>', ':bufdo call x()<CR>', ':argdo norm x<CR>' }) do
    local L = formato.lezione(LEZ:format('main.js', '', '## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: ' .. sol .. '\n```js\ny\n```\n'), '01.md', 1)
    vero(L == nil, 'accettato con un altro Invio: ' .. sol)
  end
end
T['il codice eseguito non scrive nella home vera'] = function()
  if not compila.sandbox() then return end -- senza bwrap non si può provare
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local bersaglio = vim.fn.expand('~') .. '/.dattilo-prova-sandbox'
  vim.fn.delete(bersaglio)
  vim.fn.writefile({ "require('fs').writeFileSync(require('os').homedir() + '/.dattilo-prova-sandbox', 'x'); console.log('scritto')" }, dir .. '/main.js')
  local r = compila.lancia(dir, 'main.js', { tipo = 'comando', comando = { 'node', '{file}' } })
  uguale(vim.fn.filereadable(bersaglio), 0)
  vero(r.ok, r.diagnostica)
end
T['il codice eseguito non vede la rete'] = function()
  if not compila.sandbox() then return end
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile({ "require('net').connect(53, '1.1.1.1').on('error', e => { console.log('niente rete'); process.exit(0) }).on('connect', () => { console.log('rete!'); process.exit(0) })" }, dir .. '/main.js')
  local r = compila.lancia(dir, 'main.js', { tipo = 'comando', comando = { 'node', '{file}' } })
  uguale(r.uscita, 'niente rete\n')
end
T['il codice eseguito scrive nella sua cartella di lavoro'] = function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile({ "require('fs').writeFileSync('uscita.txt', 'ok')" }, dir .. '/main.js')
  local r = compila.lancia(dir, 'main.js', { tipo = 'comando', comando = { 'node', '{file}' } })
  vero(r.ok, r.diagnostica)
  uguale(vim.fn.readfile(dir .. '/uscita.txt'), { 'ok' })
end
T['file con fine riga CRLF: si legge e un \\r non fa da Invio'] = function()
  local testo = (LEZ:format('main.js', '', '## Modifica\nconsegna: x\naiuto: x\npar: 2\nsoluzione: dd\n```js\ny\n```\n')):gsub('\n', '\r\n')
  local L, err = formato.lezione(testo, '01.md', 1)
  uguale(err, {})
  uguale({ L.titolo, L.file, L.modifiche[1].soluzione, L.batti.codice }, { 'X', 'main.js', 'dd', { 'x' } })
  local rotta = formato.lezione(LEZ:format('main.js', '', '## Modifica\nconsegna: x\naiuto: x\npar: 1\nsoluzione: :!id\rdd\n```js\ny\n```\n'), '01.md', 1)
  vero(rotta == nil, 'un \\r in mezzo alla soluzione deve essere rifiutato')
end
return T
