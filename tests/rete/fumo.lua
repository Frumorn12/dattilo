-- Dentro il container: apre la lezione 1 di ogni pacchetto installato, la scrive e la esegue.
package.path = '/opt/dattilo/lua/?.lua;' .. package.path
vim.opt.runtimepath:prepend('/opt/dattilo')
vim.o.showmode = false
require('dattilo').avvia({ radice = '/opt/dattilo' })
local lezione = require('dattilo.lezione')
local esito = {}
for _, v in ipairs(require('dattilo.pacchetti').elenco()) do
  if v.lezioni > 0 then
    lezione.apri(v.id, 1)
    local s = lezione.s
    lezione.batti(s)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, s.L.batti.codice)
    vim.cmd('silent write')
    local ok = vim.wait(10000, function() return s.passo ~= 'batti' end)
    esito[#esito + 1] = string.format('%-18s %s (%s)', v.id, ok and 'ok' or 'FERMO', s.passo)
    lezione.chiudi()
  end
end
io.stdout:write(table.concat(esito, '\n') .. '\n')
vim.cmd('qa!')
