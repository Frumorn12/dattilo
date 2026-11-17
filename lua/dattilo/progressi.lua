-- Progressi in ${XDG_DATA_HOME:-~/.local/share}/dattilo/progressi.json e cartelle di lavoro.
local M = {}

function M.cartella()
  local base = vim.env.XDG_DATA_HOME
  if not base or base == '' then base = vim.fn.expand('~/.local/share') end
  return base .. '/dattilo'
end

local function file() return M.cartella() .. '/progressi.json' end

function M.carica()
  local vuoto = { lezioni = {}, sessioni = {}, sbloccate = {} }
  if vim.fn.filereadable(file()) == 0 then return vuoto end
  local ok, dati = pcall(vim.json.decode, table.concat(vim.fn.readfile(file()), '\n'))
  if not ok or type(dati) ~= 'table' then return vuoto end
  dati.lezioni = type(dati.lezioni) == 'table' and dati.lezioni or {}
  dati.sessioni = type(dati.sessioni) == 'table' and dati.sessioni or {}
  dati.sbloccate = type(dati.sbloccate) == 'table' and dati.sbloccate or {}
  if vim.tbl_isempty(dati.lezioni) then dati.lezioni = {} end
  if vim.tbl_isempty(dati.sbloccate) then dati.sbloccate = {} end
  -- una volta sola: le lezioni del corso C avevano chiavi senza pacchetto
  local VECCHIE = { ['01-hello'] = true, ['02-sum'] = true }
  local migrato = false
  for k in pairs(VECCHIE) do
    if dati.lezioni[k] then
      dati.lezioni['corso-c-antirez/' .. k] = dati.lezioni['corso-c-antirez/' .. k] or dati.lezioni[k]
      dati.lezioni[k] = nil
      migrato = true
    end
  end
  for _, s in ipairs(dati.sessioni) do
    if VECCHIE[s.id] then s.id = 'corso-c-antirez/' .. s.id migrato = true end
  end
  if migrato then M.salva(dati) end
  return dati
end

function M.salva(dati)
  vim.fn.mkdir(M.cartella(), 'p')
  local lezioni = vim.tbl_isempty(dati.lezioni) and vim.empty_dict() or dati.lezioni
  local sbloccate = (not dati.sbloccate or vim.tbl_isempty(dati.sbloccate)) and vim.empty_dict() or dati.sbloccate
  vim.fn.writefile({ vim.json.encode({ lezioni = lezioni, sessioni = dati.sessioni, sbloccate = sbloccate }) }, file())
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

-- Una lezione sbloccata resta aperta anche se più avanti se ne aggiungono altre prima di lei.
function M.sblocca(chiave)
  local dati = M.carica()
  if dati.sbloccate[chiave] then return end
  dati.sbloccate[chiave] = true
  M.salva(dati)
end

-- La lezione i di un percorso è aperta se è fatta o sbloccata, se è la prima, o se è fatta
-- quella prima; dopo un capitolo mancante resta chiusa.
function M.aperta(perc, i, dati)
  dati = dati or M.carica()
  local v = perc.lezioni[i]
  if not v then return false end
  local chiave = v.pacchetto .. '/' .. v.L.id
  if dati.lezioni[chiave] or dati.sbloccate[chiave] then return true end
  if v.dopo_mancante then return false end
  if i == 1 then return true end
  local p = perc.lezioni[i - 1]
  return dati.lezioni[p.pacchetto .. '/' .. p.L.id] ~= nil
end

function M.lavoro(id)
  local dir = M.cartella() .. '/lavoro/' .. id
  vim.fn.mkdir(dir, 'p')
  return dir
end

return M
