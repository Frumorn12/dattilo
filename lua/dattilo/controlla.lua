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

local function prova_soluzione(m)
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

function M.pacchetto(dir)
  local out = { ok = true, righe = {} }
  local function riga(stato, testo)
    out.righe[#out.righe + 1] = { stato = stato, testo = testo }
    if stato == 'errore' then out.ok = false end
  end
  local P = pacchetti.carica_cartella(dir)
  for _, e in ipairs(P.errori) do riga('errore', e.file .. ':' .. e.riga .. ': ' .. e.msg) end
  if not P.m then return out end
  riga('ok', 'manifesto ' .. P.m.id .. ' ' .. P.m.versione .. ', ' .. #P.lezioni .. ' lezioni')
  for _, L in ipairs(P.lezioni) do
    local nome = L.id
    local r = gira(L, L.batti.codice)
    if not r.ok then riga('errore', nome .. ': il codice di Batti non gira: ' .. prima_riga(r))
    elseif L.esegui.atteso and r.uscita ~= L.esegui.atteso then
      riga('errore', nome .. ': uscita diversa da quella attesa: ' .. vim.inspect(r.uscita))
    else riga('ok', nome .. ': Batti gira') end
    for i, m in ipairs(L.modifiche) do
      local righe, e = prova_soluzione(m)
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
  return out
end

return M
