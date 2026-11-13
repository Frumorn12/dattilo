-- Punto d'ingresso: bin/dattilo esegue `nvim --clean -u init.lua`.
local radice = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
vim.opt.runtimepath:prepend(radice)
require('dattilo').avvia({ radice = radice })
