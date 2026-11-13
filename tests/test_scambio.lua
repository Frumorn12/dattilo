local scambio = require('dattilo.scambio')
local T = {}

local function xdg_nuovo()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo.pacchetti').dimentica()
  return vim.env.XDG_DATA_HOME
end
local function file_di(dir)
  local out = {}
  for _, f in ipairs(vim.fn.globpath(dir, '**/*', false, true)) do
    if vim.fn.isdirectory(f) == 0 then out[f:sub(#dir + 2)] = vim.fn.readfile(f) end
  end
  return out
end
local CORSO = RADICE .. '/pacchetti/corso-c-antirez'
local JS = RADICE .. '/tests/fixture/js-prova'

T['andata e ritorno: stessi file'] = function()
  local testo, nome = scambio.esporta(CORSO)
  uguale(nome, 'corso-c-antirez-1.0.0.dattilo')
  vero(testo:sub(1, 20) == 'dattilo-pacchetto 1\n', testo:sub(1, 30))
  local dati, err = scambio.leggi(testo)
  uguale(err, {})
  uguale(dati.file, file_di(CORSO))
  uguale(dati.manifesto.id, 'corso-c-antirez')
end
T['righe che sembrano intestazioni tornano identiche'] = function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/lezioni', 'p')
  vim.fn.writefile(vim.fn.readfile(JS .. '/pacchetto.json'), dir .. '/pacchetto.json')
  local lez = vim.fn.readfile(JS .. '/lezioni/01-somma.md')
  vim.list_extend(lez, { '--- file: x.md', '\\--- file: y.md', '\\\\--- file: z.md' })
  vim.fn.writefile(lez, dir .. '/lezioni/01-somma.md')
  local dati, err = scambio.leggi((scambio.esporta(dir)))
  uguale(err, {})
  uguale(dati.file['lezioni/01-somma.md'], lez)
end
local function con_file(percorso, righe)
  local testo = scambio.esporta(JS)
  return testo .. '--- file: ' .. percorso .. '\n' .. table.concat(righe or { 'x' }, '\n') .. '\n'
end
T['rifiutati: percorsi pericolosi, estensioni, dimensione, intestazione'] = function()
  for _, p in ipairs({ '../fuori.md', '/etc/x.md', 'lezioni/../../x.md', 'script.lua', 'file/a.sh' }) do
    local dati, err = scambio.leggi(con_file(p))
    vero(dati == nil and #err > 0, 'accettato: ' .. p)
  end
  local dati, err = scambio.leggi(con_file('file/grande.txt', { string.rep('a', 5 * 1024 * 1024) }))
  vero(dati == nil and #err > 0, 'accettato oltre 5 MB')
  dati = scambio.leggi('ciao\n' .. scambio.esporta(JS))
  uguale(dati, nil)
end
T['rifiutata una lezione malformata, con file e riga'] = function()
  local testo = con_file('lezioni/02-rotta.md', { '---', 'titolo: Rotta', 'file: main.js', '---', '## Briefing', 'niente' })
  local dati, err = scambio.leggi(testo)
  uguale(dati, nil)
  vero(err[1].file == 'lezioni/02-rotta.md' and err[1].riga ~= nil, vim.inspect(err))
end
T['installa: senza sostituisci il vecchio resta, con sostituisci cambia'] = function()
  local xdg = xdg_nuovo()
  local dati = scambio.leggi((scambio.esporta(JS)))
  local ok, msg = scambio.installa(dati, {})
  vero(ok, msg)
  local dest = xdg .. '/dattilo/pacchetti/js-prova'
  vero(vim.fn.filereadable(dest .. '/lezioni/01-somma.md') == 1)
  vim.fn.writefile({ 'segno' }, dest .. '/segno.txt')
  ok, msg = scambio.installa(dati, {})
  uguale(ok, false)
  vero(msg:find('0.1.0', 1, true), msg)
  vero(vim.fn.filereadable(dest .. '/segno.txt') == 1, 'il vecchio è stato toccato')
  ok = scambio.installa(dati, { sostituisci = true })
  vero(ok)
  uguale(vim.fn.filereadable(dest .. '/segno.txt'), 0)
  uguale(require('dattilo.pacchetti').carica('js-prova').m.versione, '0.1.0')
end
T['il corso C incluso non si sovrascrive'] = function()
  xdg_nuovo()
  local dati = scambio.leggi((scambio.esporta(CORSO)))
  local ok = scambio.installa(dati, { sostituisci = true })
  uguale(ok, false)
end
T['anteprima: titolo, lezioni, dipendenze mancanti'] = function()
  xdg_nuovo()
  local testo = scambio.esporta(JS):gsub('"linguaggio"', '"richiede": ["aton"],\n  "linguaggio"', 1)
  local dati = scambio.leggi(testo)
  local righe = table.concat(scambio.anteprima(dati), '\n')
  vero(righe:find('JS di prova', 1, true) and righe:find('1 lezion', 1, true) and righe:find('aton', 1, true), righe)
end
T['nuovo crea uno scheletro che passa il verificatore'] = function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local codice = require('dattilo.cli').main({ 'nuovo', dir .. '/mio-pacchetto' })
  uguale(codice, 0)
  local r = require('dattilo.controlla').pacchetto(dir .. '/mio-pacchetto')
  local errori = vim.tbl_filter(function(x) return x.stato == 'errore' end, r.righe)
  uguale(errori, {})
end
return T
