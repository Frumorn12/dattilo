-- Home e elenco del corso.
local schermo = require('dattilo.schermo')
local stato = require('dattilo.stato')
local ui = require('dattilo.ui')
local progressi = require('dattilo.progressi')

local M = { sel = 1, sel_corso = 1 }
local LOGO = { '╺┳┓┏━┓╺┳╸╺┳╸╻╻  ┏━┓', ' ┃┃┣━┫ ┃  ┃ ┃┃  ┃ ┃', '╺┻┛╹ ╹ ╹  ╹ ╹┗━╸┗━┛' }
local GIORNI = { 'domenica', 'lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato' }
local MESI = { 'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre' }

local function oggi()
  local d = os.date('*t')
  return GIORNI[d.wday] .. ' ' .. d.day .. ' ' .. MESI[d.month]
end

local function chiudi_altro()
  require('dattilo.lezione').chiudi()
  require('dattilo.dojo').chiudi()
  ui.chiudi_tip()
end

local function prossima_lezione(p)
  local indice = require('dattilo.lezioni.indice')
  for i, l in ipairs(indice) do
    if l.file and not p.lezioni[require('dattilo.lezioni.' .. l.file).id] then return i, l end
  end
  for i, l in ipairs(indice) do if not l.file then return i, l end end
  return 1, indice[1]
end

local function mappa(buf, tasti, fn)
  for _, k in ipairs(type(tasti) == 'table' and tasti or { tasti }) do
    vim.keymap.set('n', k, fn, { buffer = buf, nowait = true, silent = true })
  end
end

local function voci()
  return {
    { 'Corso C', 'le lezioni di antirez, una alla volta', 'c', function() M.corso() end },
    { 'Dojo Vim', 'cintura bianca · 7 esercizi', 'd', function() require('dattilo.dojo').apri(1) end },
    { 'Endless', 'arriva con il passo 4', 'e', nil },
    { 'Statistiche', 'arriva con il passo 4', 's', nil },
    { 'Esci', 'chiude dattilo', 'q', function() vim.cmd('qa!') end },
  }
end

local function disegna(buf)
  local p = progressi.carica()
  local fatte = vim.tbl_count(p.lezioni)
  local ultima = p.sessioni[#p.sessioni]
  local r = { {} }
  for _, l in ipairs(LOGO) do r[#r + 1] = { { '    ' .. l, 'DattiloAccento' } } end
  r[#r + 1] = { { '    scrivi C alla velocità delle mani', 'DattiloMuto' } }
  r[#r + 1] = {}
  r[#r + 1] = { { '    Ciao Andrea.  ', 'DattiloForte' }, { fatte .. (fatte == 1 and ' lezione fatta' or ' lezioni fatte'), 'DattiloGiallo' },
    { ultima and ('  ·  ultima volta ' .. ultima.wpm .. ' parole al minuto') or '  ·  si comincia dalla lezione 1', 'DattiloTesto' } }
  r[#r + 1] = {}
  for i, v in ipairs(voci()) do
    local on = i == M.sel
    r[#r + 1] = { { on and '  ▸ ' or '    ', on and 'DattiloAccento' or nil }, { string.format('%-16s', v[1]), on and 'DattiloSelezione' or 'DattiloForte' },
      { string.format('%-44s', v[2]), on and 'DattiloSelezione' or 'DattiloMuto' }, { '  ' .. v[3], 'DattiloAccento' } }
  end
  local i, l = prossima_lezione(p)
  r[#r + 1] = {}
  r[#r + 1] = { { '    Prossima lezione', 'DattiloTesto' } }
  r[#r + 1] = { { '    ┃ ', 'DattiloAccento' }, { l.etichetta .. ' · ' .. l.titolo, 'DattiloForte' }, { '  ' .. l.durata, 'DattiloMuto' } }
  r[#r + 1] = {}
  r[#r + 1] = schermo.con_tasti('    ', '‹j› ‹k› muovi   ‹Invio› apri   ‹c› ‹d› scorciatoie   ‹q› esci', 'DattiloMuto')
  schermo.scrivi(buf, r)
  return i
end

function M.apri()
  chiudi_altro()
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'home', 'Home', oggi(), 'home', nil
  vim.cmd('redrawtabline')
  local buf = schermo.buffer('home')
  disegna(buf)
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { 7 + M.sel, 0 })
  local function sposta(d)
    M.sel = (M.sel - 1 + d) % #voci() + 1
    disegna(buf)
    vim.api.nvim_win_set_cursor(0, { 7 + M.sel, 0 })
  end
  local function apri_voce(v)
    if v[4] then v[4]() else vim.api.nvim_echo({ { v[1] .. ': ' .. v[2] .. '.', 'DattiloGiallo' } }, false, {}) end
  end
  mappa(buf, { 'j', '<Down>' }, function() sposta(1) end)
  mappa(buf, { 'k', '<Up>' }, function() sposta(-1) end)
  mappa(buf, { '<CR>', 'l' }, function() apri_voce(voci()[M.sel]) end)
  for _, v in ipairs(voci()) do mappa(buf, v[3], function() apri_voce(v) end) end
end

-- Elenco delle 38 puntate: le prime giocabili, le altre in arrivo.
function M.corso()
  chiudi_altro()
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'corso', 'Corso C · antirez', '38 puntate', 'corso', nil
  vim.cmd('redrawtabline')
  local indice = require('dattilo.lezioni.indice')
  local p = progressi.carica()
  local buf = schermo.buffer('corso')
  local function fatta(i)
    local L = indice[i].file and require('dattilo.lezioni.' .. indice[i].file)
    return L and p.lezioni[L.id] ~= nil
  end
  local function disegna_corso()
    local r = { {}, { { '   Impariamo il C, di Salvatore Sanfilippo', 'DattiloForte' } }, { { '   Le lezioni in grigio arrivano con i prossimi passi.', 'DattiloMuto' } }, {} }
    for i, l in ipairs(indice) do
      local on = i == M.sel_corso
      local segno = fatta(i) and '✓' or l.file and '▸' or '·'
      local hl = on and 'DattiloSelezione' or (l.file and 'DattiloForte' or 'DattiloMuto')
      r[#r + 1] = { { on and ' ▸ ' or '   ', 'DattiloAccento' }, { segno .. ' ', fatta(i) and 'DattiloVerde' or 'DattiloAccento' },
        { string.format('%-9s', l.etichetta), hl }, { string.format('%-62s', l.titolo), hl }, { string.format('%8s', l.durata), 'DattiloMuto' } }
    end
    r[#r + 1] = {}
    r[#r + 1] = schermo.con_tasti('   ', '‹j› ‹k› muovi   ‹Invio› apri   ‹q› home', 'DattiloMuto')
    schermo.scrivi(buf, r)
  end
  disegna_corso()
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { 4 + M.sel_corso, 0 })
  local function sposta(d)
    M.sel_corso = math.max(1, math.min(#indice, M.sel_corso + d))
    disegna_corso()
    vim.api.nvim_win_set_cursor(0, { 4 + M.sel_corso, 0 })
  end
  mappa(buf, { 'j', '<Down>' }, function() sposta(1) end)
  mappa(buf, { 'k', '<Up>' }, function() sposta(-1) end)
  mappa(buf, 'G', function() sposta(#indice) end)
  mappa(buf, 'gg', function() sposta(-#indice) end)
  mappa(buf, { '<CR>', 'l' }, function()
    local l = indice[M.sel_corso]
    if l.file then require('dattilo.lezione').apri(M.sel_corso)
    else vim.api.nvim_echo({ { l.etichetta .. ' arriva con il passo 3 o 5 del progetto.', 'DattiloGiallo' } }, false, {}) end
  end)
  mappa(buf, 'q', function() M.apri() end)
end

return M
