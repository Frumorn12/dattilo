-- Pacchetti di lezioni: il corso C incluso nel repo e quelli installati dall'utente.
local formato = require('dattilo.formato')
local M = {}
local cache = {}

local RADICE = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
M.RADICE = RADICE

function M.cartella_interna() return RADICE .. '/pacchetti' end
function M.cartella_utente() return require('dattilo.progressi').cartella() .. '/pacchetti' end
function M.dimentica() cache = {} end

local function leggi(percorso)
  local ok, righe = pcall(vim.fn.readfile, percorso)
  if not ok then return nil end
  return table.concat(righe, '\n')
end

-- Comando predefinito quando una lezione chiede solo il tipo di esecuzione.
local function esecuzione_lezione(L, m)
  local e = L.esecuzione
  if not e then return m.esecuzione end
  if e.comando or e.tipo == m.esecuzione.tipo then return vim.tbl_extend('force', m.esecuzione, e) end
  if e.tipo == 'controllo' and m.linguaggio == 'javascript' then return { tipo = 'controllo', comando = { 'node', '--check', '{file}' } } end
  if e.tipo == 'comando' and m.linguaggio == 'javascript' then return { tipo = 'comando', comando = { 'node', '{file}' } } end
  return m.esecuzione
end

-- Legge un pacchetto da una cartella, senza cache. Le lezioni rotte finiscono in P.errori.
function M.carica_cartella(dir)
  local P = { cartella = dir, lezioni = {}, errori = {}, in_arrivo = {} }
  local testo = leggi(dir .. '/pacchetto.json')
  if not testo then
    P.errori[#P.errori + 1] = { file = 'pacchetto.json', riga = 1, msg = 'manca pacchetto.json' }
    return P
  end
  local m, err = formato.manifesto(testo, 'pacchetto.json')
  if not m then vim.list_extend(P.errori, err) return P end
  P.m, P.in_arrivo = m, m.in_arrivo
  local files = vim.fn.glob(dir .. '/lezioni/*.md', false, true)
  table.sort(files)
  for _, f in ipairs(files) do
    local nome = vim.fn.fnamemodify(f, ':t')
    local L, e = formato.lezione(leggi(f) or '', nome, #P.lezioni + 1)
    if L then
      L.pacchetto, L.linguaggio = m.id, m.linguaggio
      L.esecuzione = esecuzione_lezione(L, m)
      L.cartella_file = vim.fn.isdirectory(dir .. '/file') == 1 and (dir .. '/file') or nil
      P.lezioni[#P.lezioni + 1] = L
    else
      vim.list_extend(P.errori, e)
    end
  end
  for i, L in ipairs(P.lezioni) do L.prossima = P.lezioni[i + 1] and (i + 1) or nil end
  return P
end

local function cartelle()
  local out = {}
  for _, base in ipairs({ M.cartella_interna(), M.cartella_utente() }) do
    local dirs = vim.fn.glob(base .. '/*', false, true)
    table.sort(dirs)
    for _, d in ipairs(dirs) do if vim.fn.isdirectory(d) == 1 then out[#out + 1] = d end end
  end
  return out
end

function M.carica(id)
  if cache[id] then return cache[id] end
  for _, d in ipairs(cartelle()) do
    local testo = leggi(d .. '/pacchetto.json')
    local ok, m = pcall(vim.json.decode, testo or '')
    if ok and type(m) == 'table' and m.id == id then
      local P = M.carica_cartella(d)
      if P.m then cache[id] = P return P end
    end
  end
  return nil, 'pacchetto non trovato: ' .. id
end

function M.lezione(id, n)
  local P = M.carica(id)
  return P and P.lezioni[n]
end

function M.elenco()
  local out = {}
  for _, d in ipairs(cartelle()) do
    local P = M.carica_cartella(d)
    if P.m then cache[P.m.id] = P end
    out[#out + 1] = { id = P.m and P.m.id or vim.fn.fnamemodify(d, ':t'), titolo = P.m and P.m.titolo or vim.fn.fnamemodify(d, ':t'),
      versione = P.m and P.m.versione or '?', autore = P.m and P.m.autore or '', descrizione = P.m and P.m.descrizione or '',
      richiede = P.m and P.m.richiede or {}, cartella = d, lezioni = #P.lezioni, errori = P.errori }
  end
  table.sort(out, function(a, b)
    if (a.id == 'corso-c-antirez') ~= (b.id == 'corso-c-antirez') then return a.id == 'corso-c-antirez' end
    return a.titolo < b.titolo
  end)
  return out
end

return M
