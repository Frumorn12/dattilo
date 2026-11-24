-- Verifica un pacchetto: il codice gira, le soluzioni arrivano all'obiettivo nel par, Rompi rompe davvero.
local compila = require('dattilo.compila')
local esercizio = require('dattilo.esercizio')
local pacchetti = require('dattilo.pacchetti')
local M = {}

local function cartella_lavoro(L)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  if L.cartella_file then
    for _, f in ipairs(vim.fn.readdir(L.cartella_file)) do vim.uv.fs_copyfile(L.cartella_file .. '/' .. f, dir .. '/' .. f) end
  end
  return dir
end

local function gira(L, righe)
  local dir = cartella_lavoro(L)
  vim.fn.writefile(righe, dir .. '/' .. L.file)
  return compila.lancia(dir, L.file, L.esecuzione)
end

local function prima_riga(r)
  local d = (r.diagnostica or '') .. (r.errori or '')
  return (d:match('[^\n]*SyntaxError[^\n]*') or d:match('[^\n]*[Ee]rror[^\n]*') or d:match('[^\n]+') or ('codice ' .. tostring(r.codice)))
end

-- Rifà i tasti di una modifica sul testo di partenza: ritorna le righe che ne escono, o nil e l'errore.
function M.prova_soluzione(m)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(buf)
  require('dattilo.batti').opzioni(buf) -- le stesse opzioni del buffer della lezione
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, m.partenza)
  pcall(vim.api.nvim_win_set_cursor, 0, { m.pos[1] + 1, m.pos[2] })
  -- feedkeys con "t" si comporta come tasti battuti (anche le macro); :silent zittisce ricerche e messaggi
  vim.g.dattilo_tasti = vim.keycode(m.soluzione)
  local ok, e = pcall(vim.cmd, 'silent call feedkeys(g:dattilo_tasti, "xt")')
  vim.cmd('stopinsert')
  local righe = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_delete(buf, { force = true })
  return ok and righe or nil, e
end

-- Completezza per gli autori: ogni riga non vuota di Batti ha un suggerimento ed è dentro un blocco.
function M.completezza(L)
  local out = {}
  local codice, bl = L.batti.codice, L.batti.blocchi or {}
  local senza_tip, fuori = {}, {}
  for i, l in ipairs(codice) do
    if l:match('%S') then
      if not L.batti.suggerimenti[i] then senza_tip[#senza_tip + 1] = i end
      if #bl > 0 then
        local dentro = false
        for _, b in ipairs(bl) do if i >= b.da and i <= b.a then dentro = true break end end
        if not dentro then fuori[#fuori + 1] = i end
      end
    end
  end
  if #senza_tip > 0 then out[#out + 1] = 'righe senza suggerimento: ' .. table.concat(senza_tip, ', ') end
  if #bl == 0 then out[#out + 1] = 'nessun blocco: aggiungi ### Blocchi in Batti'
  elseif #fuori > 0 then out[#out + 1] = 'righe fuori dai blocchi: ' .. table.concat(fuori, ', ') end
  for i, m in ipairs(L.modifiche) do
    if not m.motivo then out[#out + 1] = 'modifica ' .. i .. ' senza motivo' end
  end
  return out
end

-- Ogni riga di Batti con il suo blocco e il suo suggerimento, per controllare l'allineamento.
function M.tip(L)
  local out, bl = {}, L.batti.blocchi or {}
  local k = 1
  for i, l in ipairs(L.batti.codice) do
    local b = bl[k]
    if b and i == b.da then
      out[#out + 1] = ''
      out[#out + 1] = string.format('== %d-%d %s | %s | %s', b.da, b.a, b.titolo, b.cosa or '', b.quadro or '')
    end
    out[#out + 1] = string.format('%3d  %s', i, l)
    if L.batti.suggerimenti[i] then out[#out + 1] = '       ↳ ' .. L.batti.suggerimenti[i] end
    if b and i == b.a then k = k + 1 end
  end
  return out
end

local function stessa(L, solo) return not solo or L.id == solo or L.id == solo:gsub('%.md$', '') end

-- Per gli autori: esegue le soluzioni delle modifiche, una dopo l'altra, e riscrive nel testo
-- della lezione i blocchi obiettivo e il par. Ritorna il testo nuovo e un resoconto.
function M.riempi(testo, nome)
  local formato = require('dattilo.formato')
  local righe = vim.split(testo, '\n', { plain = true })
  local resoconto, k = {}, 1
  while true do
    local L, err = formato.lezione(table.concat(righe, '\n'), nome, 1, { riempi = true })
    if not L then return nil, err end
    local m = L.modifiche[k]
    if not m then break end
    if not m.blocco or not m.par_riga then return nil, { { file = nome, riga = 1, msg = 'modifica ' .. k .. ': servono il blocco ``` e la riga par: (anche par: 0)' } } end
    local risultato, e = M.prova_soluzione(m)
    if not risultato then return nil, { { file = nome, riga = m.par_riga, msg = 'modifica ' .. k .. ': la soluzione dà errore: ' .. tostring(e) } } end
    local cambiate = {}
    for i = 1, math.max(#risultato, #m.partenza) do
      if risultato[i] ~= m.partenza[i] then cambiate[#cambiate + 1] = i end
    end
    local tasti = esercizio.conta_tasti(m.soluzione)
    righe[m.par_riga] = 'par: ' .. tasti
    local nuove = vim.list_slice(righe, 1, m.blocco.riga)
    vim.list_extend(nuove, risultato)
    vim.list_extend(nuove, vim.list_slice(righe, m.blocco.riga + m.blocco.n + 1))
    righe = nuove
    resoconto[#resoconto + 1] = string.format('modifica %d (%s): %d tasti, %d righe (%+d), cambiate: %s', k, m.titolo, tasti, #risultato,
      #risultato - #m.partenza, #cambiate > 12 and (table.concat(vim.list_slice(cambiate, 1, 12), ', ') .. '…') or table.concat(cambiate, ', '))
    k = k + 1
  end
  local L = formato.lezione(table.concat(righe, '\n'), nome, 1, { riempi = true })
  if L and L.rompi and L.rompi.soluzione and L.rompi.blocco then
    local rotto, e = M.prova_soluzione({ partenza = L.rompi.ripara, pos = { 0, 0 }, soluzione = L.rompi.soluzione })
    if not rotto then return nil, { { file = nome, riga = L.rompi.blocco.riga, msg = 'Rompi: la soluzione dà errore: ' .. tostring(e) } } end
    local nuove = vim.list_slice(righe, 1, L.rompi.blocco.riga)
    vim.list_extend(nuove, rotto)
    vim.list_extend(nuove, vim.list_slice(righe, L.rompi.blocco.riga + L.rompi.blocco.n + 1))
    righe = nuove
    resoconto[#resoconto + 1] = 'rompi: esempio scritto dai tasti ' .. L.rompi.soluzione
  end
  return table.concat(righe, '\n'), resoconto
end

function M.pacchetto(dir, solo)
  local out = { ok = true, righe = {} }
  local function riga(stato, testo)
    out.righe[#out.righe + 1] = { stato = stato, testo = testo }
    if stato == 'errore' then out.ok = false end
  end
  local P = pacchetti.carica_cartella(dir)
  for _, e in ipairs(P.errori) do
    if not solo or e.file:gsub('%.md$', '') == solo:gsub('%.md$', '') or e.file == 'pacchetto.json' then riga('errore', e.file .. ':' .. e.riga .. ': ' .. e.msg) end
  end
  if not P.m then return out end
  riga('ok', 'manifesto ' .. P.m.id .. ' ' .. P.m.versione .. ', ' .. #P.lezioni .. ' lezioni')
  for _, L in ipairs(P.lezioni) do
   if stessa(L, solo) then
    local nome = L.id
    for _, msg in ipairs(M.completezza(L)) do riga('errore', nome .. ': ' .. msg) end
    local r = gira(L, L.batti.codice)
    if not r.ok then riga('errore', nome .. ': il codice di Batti non gira: ' .. prima_riga(r))
    elseif L.esegui.atteso and r.uscita ~= L.esegui.atteso then
      riga('errore', nome .. ': uscita diversa da quella attesa: ' .. vim.inspect(r.uscita))
    else riga('ok', nome .. ': Batti gira') end
    for i, m in ipairs(L.modifiche) do
      local righe, e = M.prova_soluzione(m)
      local tasti = esercizio.conta_tasti(m.soluzione)
      if not righe then riga('errore', nome .. ': modifica ' .. i .. ': la soluzione dà errore: ' .. tostring(e))
      elseif not vim.deep_equal(righe, m.obiettivo) then riga('errore', nome .. ': modifica ' .. i .. ': la soluzione non arriva all\'obiettivo')
      elseif tasti ~= m.par then riga('errore', nome .. ': modifica ' .. i .. ': la soluzione ha ' .. tasti .. ' tasti ma il par è ' .. m.par)
      else riga('ok', nome .. ': modifica ' .. i .. ' in ' .. m.par .. ' tasti') end
    end
    local finale = #L.modifiche > 0 and L.modifiche[#L.modifiche].obiettivo or L.batti.codice
    local rf = gira(L, finale)
    if not rf.ok then riga('errore', nome .. ': il testo finale non gira: ' .. prima_riga(rf)) end
    if L.rompi and L.rompi.esempio then
      local rr = gira(L, L.rompi.esempio)
      if compila.fallito(rr, L.rompi.attesa, L.rompi.cerca) then riga('ok', nome .. ': Rompi dà ' .. L.rompi.attesa)
      else riga('errore', nome .. ': l\'esempio di Rompi non dà ' .. L.rompi.attesa .. (L.rompi.cerca and (' con "' .. L.rompi.cerca .. '"') or '')) end
    end
   end
  end
  return out
end

return M
