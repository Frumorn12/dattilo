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
function M.esecuzione_lezione(L, m)
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
      L.esecuzione = M.esecuzione_lezione(L, m)
      L.cartella_file = vim.fn.isdirectory(dir .. '/file') == 1 and (dir .. '/file') or nil
      local motivo = formato.coerenza(L)
      if motivo then P.errori[#P.errori + 1] = { file = nome, riga = 1, msg = motivo }
      else P.lezioni[#P.lezioni + 1] = L end
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
    for _, d in ipairs(dirs) do
      -- solo cartelle con un nome da id: niente avanzi di installazioni o cartelle estranee
      if vim.fn.isdirectory(d) == 1 and vim.fn.fnamemodify(d, ':t'):match('^[a-z0-9%-]+$') then out[#out + 1] = d end
    end
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

-- Catene di pacchetti legate da `richiede`: per ogni pacchetto che nessuno richiede e che
-- richiede qualcosa, l'elenco dei suoi id dalle dipendenze più profonde fino a lui.
local function catene(voci)
  local per_id, richiesto = {}, {}
  for _, v in ipairs(voci) do per_id[v.id] = v end
  for _, v in ipairs(voci) do for _, d in ipairs(v.richiede or {}) do richiesto[d] = true end end
  local out = {}
  for _, v in ipairs(voci) do
    if not richiesto[v.id] and #(v.richiede or {}) > 0 then
      local ordine, visto = {}, {}
      local function visita(id)
        if visto[id] then return end
        visto[id] = true
        for _, d in ipairs(per_id[id] and per_id[id].richiede or {}) do visita(d) end
        ordine[#ordine + 1] = id
      end
      visita(v.id)
      out[#out + 1] = ordine
    end
  end
  return out
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
  -- prima il corso C, poi i pacchetti dei percorsi nel loro ordine, poi gli altri per titolo
  local posto = {}
  for ci, c in ipairs(catene(out)) do
    for k, id in ipairs(c) do if not posto[id] then posto[id] = ci * 1000 + k end end
  end
  local function chiave(v)
    if v.id == 'corso-c-antirez' then return 0 end
    return posto[v.id] or math.huge
  end
  table.sort(out, function(a, b)
    local ka, kb = chiave(a), chiave(b)
    if ka ~= kb then return ka < kb end
    return a.titolo < b.titolo
  end)
  return out
end

-- Percorsi: { id, titolo, capitoli = { {id, titolo, P, primo, ultimo} }, lezioni = { {pacchetto, n, L, capitolo, dopo_mancante} } }.
-- Un capitolo senza P è un pacchetto richiesto ma non installato: le lezioni dopo restano bloccate.
function M.percorsi()
  local voci = M.elenco()
  local out = {}
  for _, c in ipairs(catene(voci)) do
    local fine = M.carica(c[#c])
    local perc = { id = c[#c], titolo = fine and fine.m.percorso or ('Percorso ' .. (fine and fine.m.titolo or c[#c])), capitoli = {}, lezioni = {} }
    local mancante = false
    for _, id in ipairs(c) do
      local P = M.carica(id)
      local cap = { id = id, P = P, titolo = P and P.m.titolo or id, primo = #perc.lezioni + 1 }
      perc.capitoli[#perc.capitoli + 1] = cap
      if P then
        for n, L in ipairs(P.lezioni) do
          perc.lezioni[#perc.lezioni + 1] = { pacchetto = id, n = n, L = L, capitolo = #perc.capitoli, dopo_mancante = mancante }
        end
      else
        mancante = true
      end
      cap.ultimo = #perc.lezioni
    end
    out[#out + 1] = perc
  end
  return out
end

-- Il percorso che contiene il pacchetto `id`, e l'indice del suo capitolo.
function M.percorso_di(id)
  for _, perc in ipairs(M.percorsi()) do
    for k, cap in ipairs(perc.capitoli) do if cap.id == id then return perc, k end end
  end
  return nil
end

-- Posizione di una lezione nella lista piatta del percorso.
function M.posizione(perc, pacchetto, lezione_id)
  for i, v in ipairs(perc.lezioni) do
    if v.pacchetto == pacchetto and v.L.id == lezione_id then return i end
  end
  return nil
end

return M
