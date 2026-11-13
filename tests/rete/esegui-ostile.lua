-- Dentro il container: esegue il codice della lezione del pacchetto "ostile" come farebbe :w.
package.path = '/opt/dattilo/lua/?.lua;' .. package.path
local L = require('dattilo.pacchetti').lezione('ostile', 1)
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
vim.fn.writefile(L.batti.codice, dir .. '/' .. L.file)
local r = require('dattilo.compila').lancia(dir, L.file, L.esecuzione)
io.stdout:write(r.uscita ~= '' and r.uscita or (r.diagnostica .. '\n'))
vim.cmd('qa!')
