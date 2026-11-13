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
  local P = require('dattilo.pacchetti').carica('corso-c-antirez')
  if not P then return nil end
  for _, L in ipairs(P.lezioni) do
    if not p.lezioni['corso-c-antirez/' .. L.id] then return { etichetta = L.etichetta, titolo = L.titolo, durata = L.video and L.video.durata or '' } end
  end
  return P.in_arrivo[1]
end

local function mappa(buf, tasti, fn)
  for _, k in ipairs(type(tasti) == 'table' and tasti or { tasti }) do
    vim.keymap.set('n', k, fn, { buffer = buf, nowait = true, silent = true })
  end
end

local function voci()
  return {
    { 'Corso C', 'le lezioni di antirez, una alla volta', 'c', function() M.lezioni('corso-c-antirez') end },
    { 'Pacchetti', 'JavaScript, Three.js, ATON, SmartExploration…', 'p', function() M.pacchetti() end },
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
  local l = prossima_lezione(p)
  if l then
    r[#r + 1] = {}
    r[#r + 1] = { { '    Prossima lezione del corso C', 'DattiloTesto' } }
    r[#r + 1] = { { '    ┃ ', 'DattiloAccento' }, { (l.etichetta or '') .. ' · ' .. (l.titolo or ''), 'DattiloForte' }, { '  ' .. (l.durata or ''), 'DattiloMuto' } }
  end
  r[#r + 1] = {}
  r[#r + 1] = schermo.con_tasti('    ', '‹j› ‹k› muovi   ‹Invio› apri   ‹c› ‹p› ‹d› scorciatoie   ‹q› esci', 'DattiloMuto')
  schermo.scrivi(buf, r)
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

-- Lezioni di un pacchetto: quelle vere, poi quelle in arrivo in grigio.
function M.lezioni(id)
  chiudi_altro()
  local pacchetti = require('dattilo.pacchetti')
  local P = pacchetti.carica(id)
  if not P then vim.api.nvim_echo({ { 'Pacchetto non trovato: ' .. id, 'DattiloRosso' } }, true, {}) return end
  local tot = #P.lezioni + #P.in_arrivo
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'corso', P.m.titolo, tot .. ' lezioni', id, nil
  vim.cmd('redrawtabline')
  local p = progressi.carica()
  local buf = schermo.buffer('lezioni')
  M.sel_lezioni = M.sel_lezioni or {}
  local sel = math.min(M.sel_lezioni[id] or 1, math.max(1, tot))
  local function voce(i)
    if i <= #P.lezioni then return P.lezioni[i], true end
    return P.in_arrivo[i - #P.lezioni], false
  end
  local function disegna_lezioni()
    local r = { {}, { { '   ' .. P.m.titolo, 'DattiloForte' } } }
    r[#r + 1] = { { '   ' .. (P.m.descrizione ~= '' and P.m.descrizione or ('versione ' .. P.m.versione)), 'DattiloMuto' } }
    r[#r + 1] = {}
    for i = 1, tot do
      local l, vera = voce(i)
      local on = i == sel
      local fatta = vera and p.lezioni[id .. '/' .. l.id] ~= nil
      local segno = fatta and '✓' or vera and '▸' or '·'
      local hl = on and 'DattiloSelezione' or (vera and 'DattiloForte' or 'DattiloMuto')
      local durata = vera and (l.video and l.video.durata or l.tempo or '') or (l.durata or '')
      r[#r + 1] = { { on and ' ▸ ' or '   ', 'DattiloAccento' }, { segno .. ' ', fatta and 'DattiloVerde' or 'DattiloAccento' },
        { string.format('%-9s', l.etichetta or ''), hl }, { string.format('%-62s', l.titolo or ''), hl }, { string.format('%15s', durata), 'DattiloMuto' } }
    end
    if #P.errori > 0 then
      r[#r + 1] = {}
      r[#r + 1] = { { '   ' .. #P.errori .. ' problemi nel pacchetto: ', 'DattiloRosso' }, { P.errori[1].file .. ':' .. P.errori[1].riga .. ' ' .. P.errori[1].msg, 'DattiloTesto' } }
    end
    r[#r + 1] = {}
    r[#r + 1] = schermo.con_tasti('   ', '‹j› ‹k› muovi   ‹Invio› apri   ‹q› indietro', 'DattiloMuto')
    schermo.scrivi(buf, r)
  end
  disegna_lezioni()
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { 4 + sel, 0 })
  local function sposta(d)
    sel = math.max(1, math.min(tot, sel + d))
    M.sel_lezioni[id] = sel
    disegna_lezioni()
    vim.api.nvim_win_set_cursor(0, { 4 + sel, 0 })
  end
  mappa(buf, { 'j', '<Down>' }, function() sposta(1) end)
  mappa(buf, { 'k', '<Up>' }, function() sposta(-1) end)
  mappa(buf, 'G', function() sposta(tot) end)
  mappa(buf, 'gg', function() sposta(-tot) end)
  mappa(buf, { '<CR>', 'l' }, function()
    local l, vera = voce(sel)
    if vera then require('dattilo.lezione').apri(id, sel)
    else vim.api.nvim_echo({ { (l.etichetta or '') .. ' non è ancora scritta.', 'DattiloGiallo' } }, false, {}) end
  end)
  mappa(buf, 'q', function() if id == 'corso-c-antirez' then M.apri() else M.pacchetti() end end)
end

-- Pacchetti installati.
function M.pacchetti()
  chiudi_altro()
  local pacchetti = require('dattilo.pacchetti')
  local elenco = pacchetti.elenco()
  local presenti = {}
  for _, v in ipairs(elenco) do presenti[v.id] = true end
  stato.schermo, stato.titolo, stato.destra, stato.file, stato.metriche = 'pacchetti', 'Pacchetti', #elenco .. ' installati', 'pacchetti', nil
  vim.cmd('redrawtabline')
  local buf = schermo.buffer('pacchetti')
  M.sel_pacchetto = math.min(M.sel_pacchetto or 1, math.max(1, #elenco))
  local function disegna_pacchetti()
    local r = { {}, { { '   Pacchetti di lezioni', 'DattiloForte' } }, { { '   Si scambiano come file .dattilo: ‹i› importa, ‹e› esporta quello selezionato.', 'DattiloMuto' } }, {} }
    r[3] = schermo.con_tasti('   ', 'Si scambiano come file .dattilo: ‹i› importa, ‹e› esporta quello selezionato.', 'DattiloMuto')
    for i, v in ipairs(elenco) do
      local on = i == M.sel_pacchetto
      local hl = on and 'DattiloSelezione' or 'DattiloForte'
      r[#r + 1] = { { on and ' ▸ ' or '   ', 'DattiloAccento' }, { string.format('%-36s', v.titolo), hl },
        { string.format('%-10s', 'v' .. v.versione), 'DattiloMuto' }, { string.format('%3d lezioni   ', v.lezioni), 'DattiloTesto' }, { v.autore, 'DattiloMuto' } }
      local mancano = vim.tbl_filter(function(d) return not presenti[d] end, v.richiede or {})
      if #mancano > 0 then r[#r + 1] = { { '       richiede anche: ' .. table.concat(mancano, ', '), 'DattiloGiallo' } } end
      if #v.errori > 0 then r[#r + 1] = { { '       ' .. #v.errori .. ' problemi: ' .. v.errori[1].file .. ':' .. v.errori[1].riga .. ' ' .. v.errori[1].msg, 'DattiloRosso' } } end
    end
    r[#r + 1] = {}
    r[#r + 1] = schermo.con_tasti('   ', '‹j› ‹k› muovi   ‹Invio› apri   ‹i› importa   ‹e› esporta   ‹q› home', 'DattiloMuto')
    schermo.scrivi(buf, r)
  end
  local function riga_di(i)
    local n = 4
    for k = 1, i do
      n = n + 1
      if k < i then
        local v = elenco[k]
        local mancano = vim.tbl_filter(function(d) return not presenti[d] end, v.richiede or {})
        if #mancano > 0 then n = n + 1 end
        if #v.errori > 0 then n = n + 1 end
      end
    end
    return n
  end
  disegna_pacchetti()
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { riga_di(M.sel_pacchetto), 0 })
  local function sposta(d)
    M.sel_pacchetto = math.max(1, math.min(#elenco, M.sel_pacchetto + d))
    disegna_pacchetti()
    vim.api.nvim_win_set_cursor(0, { riga_di(M.sel_pacchetto), 0 })
  end
  mappa(buf, { 'j', '<Down>' }, function() sposta(1) end)
  mappa(buf, { 'k', '<Up>' }, function() sposta(-1) end)
  mappa(buf, { '<CR>', 'l' }, function() local v = elenco[M.sel_pacchetto] if v then M.lezioni(v.id) end end)
  mappa(buf, 'i', function() if M.importa then M.importa() end end)
  mappa(buf, 'e', function() if M.esporta and elenco[M.sel_pacchetto] then M.esporta(elenco[M.sel_pacchetto]) end end)
  mappa(buf, 'q', function() M.apri() end)
end

-- Importa un file .dattilo dall'app: percorso, anteprima, conferma.
function M.importa()
  vim.ui.input({ prompt = 'File .dattilo da importare: ', completion = 'file', default = vim.fn.expand('~/') }, function(percorso)
    if not percorso or percorso == '' then return end
    percorso = vim.fn.expand(percorso)
    if vim.fn.filereadable(percorso) == 0 then
      vim.api.nvim_echo({ { 'File non trovato: ' .. percorso, 'DattiloRosso' } }, true, {})
      return
    end
    local scambio = require('dattilo.scambio')
    local dati, err = scambio.leggi(table.concat(vim.fn.readfile(percorso, 'b'), '\n'))
    if not dati then
      local chunks = { { 'Non importo il file:\n', 'DattiloRosso' } }
      for _, e in ipairs(err) do chunks[#chunks + 1] = { '  ' .. e.file .. ':' .. e.riga .. ': ' .. e.msg .. '\n', 'DattiloTesto' } end
      vim.api.nvim_echo(chunks, true, {})
      return
    end
    local scelta = vim.fn.confirm(table.concat(scambio.anteprima(dati), '\n') .. '\n\nInstallare?', '&Sì\n&No', 2)
    if scelta ~= 1 then return end
    local ok, msg = scambio.installa(dati, { sostituisci = true })
    M.pacchetti()
    vim.api.nvim_echo({ { msg, ok and 'DattiloVerde' or 'DattiloRosso' } }, true, {})
  end)
end

-- Esporta il pacchetto nella home: ~/<id>-<versione>.dattilo
function M.esporta(v)
  local ok, testo, nome = pcall(require('dattilo.scambio').esporta, v.cartella)
  if not ok or not nome then
    vim.api.nvim_echo({ { 'Non riesco a esportare ' .. v.titolo .. ': ' .. (v.errori[1] and v.errori[1].msg or tostring(testo)), 'DattiloRosso' } }, true, {})
    return
  end
  local dest = vim.fn.expand('~/') .. nome
  vim.fn.writefile(vim.split(testo:gsub('\n$', ''), '\n', { plain = true }), dest)
  vim.api.nvim_echo({ { 'Esportato in ' .. dest .. ': mandalo a chi vuoi, si importa con dattilo importa.', 'DattiloVerde' } }, true, {})
end

return M
