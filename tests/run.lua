-- Esecutore dei test: nvim --clean --headless -l tests/run.lua [filtro]
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path
_G.RADICE = root

function _G.uguale(a, b, msg)
  if not vim.deep_equal(a, b) then
    error((msg or 'valori diversi') .. '\n  atteso:  ' .. vim.inspect(b) .. '\n  trovato: ' .. vim.inspect(a), 2)
  end
end
function _G.vero(c, msg) if not c then error(msg or 'condizione falsa', 2) end end

local filtro = arg and arg[1]
local files = vim.fn.glob(root .. '/tests/test_*.lua', false, true)
local n, falliti = 0, 0
for _, f in ipairs(files) do
  if not filtro or f:find(filtro, 1, true) then
    local ok, suite = pcall(dofile, f)
    if not ok then
      falliti = falliti + 1
      print('ERRORE caricando ' .. vim.fn.fnamemodify(f, ':t') .. ': ' .. tostring(suite))
    else
      local nomi = vim.tbl_keys(suite)
      table.sort(nomi)
      for _, nome in ipairs(nomi) do
        n = n + 1
        local ok2, err = xpcall(suite[nome], debug.traceback)
        if not ok2 then
          falliti = falliti + 1
          print('FALLITO ' .. vim.fn.fnamemodify(f, ':t') .. ' :: ' .. nome .. '\n' .. err)
        end
      end
    end
  end
end
if falliti > 0 then print(falliti .. ' falliti su ' .. n) os.exit(1) end
print('OK ' .. n .. ' test')
os.exit(0)
