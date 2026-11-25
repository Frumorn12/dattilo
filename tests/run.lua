-- Esecutore dei test: nvim --clean --headless -l tests/run.lua [filtro]
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path
_G.RADICE = root
vim.o.showmode = false

function _G.uguale(a, b, msg)
  if not vim.deep_equal(a, b) then
    error((msg or 'valori diversi') .. '\n  atteso:  ' .. vim.inspect(b) .. '\n  trovato: ' .. vim.inspect(a), 2)
  end
end
function _G.vero(c, msg) if not c then error(msg or 'condizione falsa', 2) end end

-- I processi che le prove lanciano (dattilo vivo, nvim) hanno la loro cartella temporanea dentro quella di
-- questo lancio: va via insieme a lei, in fondo (vedi sotto).
local tmp_lancio = vim.fn.fnamemodify(vim.fn.tempname(), ':h')
vim.fn.mkdir(tmp_lancio .. '/figli', 'p', tonumber('700', 8))
vim.env.TMPDIR = tmp_lancio .. '/figli'

local corrente, finito = nil, false
vim.api.nvim_create_autocmd('VimLeavePre', { callback = function()
  if not finito then io.stdout:write('USCITA INATTESA di Neovim durante: ' .. tostring(corrente) .. '\n') end
end })

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
        corrente = vim.fn.fnamemodify(f, ':t') .. ' :: ' .. nome
        local ok2, err = xpcall(suite[nome], debug.traceback)
        if not ok2 then
          falliti = falliti + 1
          print('FALLITO ' .. vim.fn.fnamemodify(f, ':t') .. ' :: ' .. nome .. '\n' .. err)
        end
      end
    end
  end
end
finito = true
-- Con os.exit Neovim non cancella la sua cartella temporanea, e le prove ci mettono le copie delle
-- fixture e le cartelle dei figli: la cancelliamo noi (solo se è fatta come <tmp>/nvim.<utente>/<sigla>).
if tmp_lancio:match('/nvim%.[^/]+/[^/]+$') then vim.fn.delete(tmp_lancio, 'rf') end
if falliti > 0 then print(falliti .. ' falliti su ' .. n) os.exit(1) end
print('OK ' .. n .. ' test')
os.exit(0)
