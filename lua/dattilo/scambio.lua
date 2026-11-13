-- File .dattilo: un pacchetto intero in un solo file di testo, da esportare e importare.
local formato = require('dattilo.formato')
local pacchetti = require('dattilo.pacchetti')
local M = {}

local INTESTAZIONE = 'dattilo-pacchetto 1'
local ESTENSIONI = { json = true, md = true, html = true, js = true, css = true, txt = true, c = true }
local MASSIMO = 5 * 1024 * 1024

local function ammesso(percorso)
  if percorso == '' or percorso:sub(1, 1) == '/' or percorso:find('\\', 1, true) then return false, 'percorso non valido' end
  for parte in percorso:gmatch('[^/]+') do
    if parte == '..' or parte == '.' then return false, 'percorso fuori dal pacchetto' end
  end
  local ext = percorso:match('%.([%w]+)$')
  if not ext or not ESTENSIONI[ext] then return false, 'estensione non ammessa' end
  return true
end

function M.esporta(cartella)
  local file = {}
  for _, f in ipairs(vim.fn.globpath(cartella, '**/*', false, true)) do
    local rel = f:sub(#cartella + 2)
    if vim.fn.isdirectory(f) == 0 and ammesso(rel) then file[#file + 1] = rel end
  end
  table.sort(file)
  local m = vim.json.decode(table.concat(vim.fn.readfile(cartella .. '/pacchetto.json'), '\n'))
  local out = { INTESTAZIONE, 'id: ' .. m.id, 'versione: ' .. m.versione }
  for _, rel in ipairs(file) do
    out[#out + 1] = '--- file: ' .. rel
    for _, l in ipairs(vim.fn.readfile(cartella .. '/' .. rel)) do
      if l:match('^\\*%-%-%- file:') then l = '\\' .. l end
      out[#out + 1] = l
    end
  end
  return table.concat(out, '\n') .. '\n', m.id .. '-' .. m.versione .. '.dattilo'
end

function M.leggi(testo)
  local err = {}
  local function e(file, riga, msg) err[#err + 1] = { file = file, riga = riga, msg = msg } end
  if #testo > MASSIMO then e('', 1, 'il file supera 5 MB') return nil, err end
  testo = testo:gsub('\r\n', '\n') -- passato da Windows o da una mail
  local righe = vim.split(testo, '\n', { plain = true })
  if righe[#righe] == '' then table.remove(righe) end
  if righe[1] ~= INTESTAZIONE then e('', 1, 'non è un file .dattilo (prima riga: ' .. INTESTAZIONE .. ')') return nil, err end
  local file, corrente = {}, nil
  for i = 2, #righe do
    local l = righe[i]
    local p = l:match('^%-%-%- file: (.*)$')
    if p then
      local ok, msg = ammesso(p)
      if not ok then e(p, i, msg) corrente = nil
      else file[p] = {} corrente = file[p] end
    elseif corrente then
      if l:match('^\\+%-%-%- file:') then l = l:sub(2) end
      corrente[#corrente + 1] = l
    end
  end
  if #err > 0 then return nil, err end
  if not file['pacchetto.json'] then e('pacchetto.json', 1, 'manca pacchetto.json') return nil, err end
  local m, em = formato.manifesto(table.concat(file['pacchetto.json'], '\n'), 'pacchetto.json')
  if not m then return nil, em end
  local lezioni = {}
  for p in pairs(file) do if p:match('^lezioni/[^/]+%.md$') then lezioni[#lezioni + 1] = p end end
  table.sort(lezioni)
  for i, p in ipairs(lezioni) do
    local L, el = formato.lezione(table.concat(file[p], '\n'), vim.fn.fnamemodify(p, ':t'), i)
    if not L then for _, x in ipairs(el) do e(p, x.riga, x.msg) end end
  end
  if #lezioni == 0 then e('lezioni/', 1, 'il pacchetto non ha lezioni') end
  if #err > 0 then return nil, err end
  return { manifesto = m, file = file, lezioni = #lezioni }, err
end

function M.anteprima(dati)
  local m = dati.manifesto
  local out = { m.titolo .. ' · versione ' .. m.versione .. (m.autore ~= '' and (' · di ' .. m.autore) or ''),
    dati.lezioni .. (dati.lezioni == 1 and ' lezione' or ' lezioni') }
  if m.descrizione ~= '' then table.insert(out, 2, m.descrizione) end
  local mancano = {}
  for _, d in ipairs(m.richiede) do if not pacchetti.carica(d) then mancano[#mancano + 1] = d end end
  if #mancano > 0 then out[#out + 1] = 'Richiede anche: ' .. table.concat(mancano, ', ') .. ' (non installati)' end
  local gia = pacchetti.carica(m.id)
  if gia then out[#out + 1] = 'Già installato: versione ' .. gia.m.versione .. ', verrà sostituito' end
  return out
end

function M.installa(dati, o)
  o = o or {}
  local m = dati.manifesto
  if vim.fn.isdirectory(pacchetti.cartella_interna() .. '/' .. m.id) == 1 then
    return false, m.id .. ' è incluso in dattilo e non si sostituisce'
  end
  local dest = pacchetti.cartella_utente() .. '/' .. m.id
  if vim.fn.isdirectory(dest) == 1 and not o.sostituisci then
    local vecchio = pacchetti.carica_cartella(dest)
    return false, m.id .. ' è già installato (versione ' .. (vecchio.m and vecchio.m.versione or '?') .. ')'
  end
  local tmp = dest .. '.nuovo-' .. vim.uv.hrtime()
  for p, righe in pairs(dati.file) do
    vim.fn.mkdir(vim.fn.fnamemodify(tmp .. '/' .. p, ':h'), 'p')
    vim.fn.writefile(righe, tmp .. '/' .. p)
  end
  if vim.fn.isdirectory(dest) == 1 then vim.fn.delete(dest, 'rf') end
  vim.fn.mkdir(vim.fn.fnamemodify(dest, ':h'), 'p')
  local ok, e = vim.uv.fs_rename(tmp, dest)
  pacchetti.dimentica()
  if not ok then return false, 'non riesco a installare: ' .. tostring(e) end
  return true, m.titolo .. ' ' .. m.versione .. ' installato'
end

return M
