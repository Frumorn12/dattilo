-- Progressi in ${XDG_DATA_HOME:-~/.local/share}/dattilo/progressi.json e cartelle di lavoro.
local M = {}

function M.cartella()
  local base = vim.env.XDG_DATA_HOME
  if not base or base == '' then base = vim.fn.expand('~/.local/share') end
  return base .. '/dattilo'
end

local function file() return M.cartella() .. '/progressi.json' end

function M.carica()
  local vuoto = { lezioni = {}, sessioni = {} }
  if vim.fn.filereadable(file()) == 0 then return vuoto end
  local ok, dati = pcall(vim.json.decode, table.concat(vim.fn.readfile(file()), '\n'))
  if not ok or type(dati) ~= 'table' then return vuoto end
  dati.lezioni = type(dati.lezioni) == 'table' and dati.lezioni or {}
  dati.sessioni = type(dati.sessioni) == 'table' and dati.sessioni or {}
  if vim.tbl_isempty(dati.lezioni) then dati.lezioni = {} end
  return dati
end

function M.salva(dati)
  vim.fn.mkdir(M.cartella(), 'p')
  local lezioni = vim.tbl_isempty(dati.lezioni) and vim.empty_dict() or dati.lezioni
  vim.fn.writefile({ vim.json.encode({ lezioni = lezioni, sessioni = dati.sessioni }) }, file())
end

function M.registra(id, r)
  local dati = M.carica()
  local l = dati.lezioni[id] or { volte = 0, migliore_wpm = 0 }
  l.volte = l.volte + 1
  l.completata = true
  l.migliore_wpm = math.max(l.migliore_wpm or 0, r.wpm or 0)
  l.ultima = r
  dati.lezioni[id] = l
  table.insert(dati.sessioni, vim.tbl_extend('force', { id = id, data = os.date('%Y-%m-%d %H:%M') }, r))
  M.salva(dati)
end

function M.lavoro(id)
  local dir = M.cartella() .. '/lavoro/' .. id
  vim.fn.mkdir(dir, 'p')
  return dir
end

return M
