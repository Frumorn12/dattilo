-- Una lezione: briefing → batti → modifica → rompi → spiegazione → fine.
local batti = require('dattilo.batti')
local compila = require('dattilo.compila')
local esercizio = require('dattilo.esercizio')
local progressi = require('dattilo.progressi')
local schermo = require('dattilo.schermo')
local stato = require('dattilo.stato')
local ui = require('dattilo.ui')

local M = {}
local PASSI = { briefing = 1, batti = 2, modifica = 3, rompi = 4, spiegazione = 5, fine = 6 }
local NOMI = { briefing = 'briefing', batti = 'batti', modifica = 'modifica', rompi = 'rompi', spiegazione = 'spiegazione', fine = 'riepilogo' }
local ns = vim.api.nvim_create_namespace('dattilo_lezione')

local function ora() return vim.uv.hrtime() / 1e6 end
local function tempo(ms) local s = math.floor(ms / 1000 + 0.5) return string.format('%d:%02d', math.floor(s / 60), s % 60) end
local function perc(p) local s = string.format('%.1f', p):gsub('%.0$', ''):gsub('%.', ',') return s .. '%' end
local function stelle(n) return string.rep('★', n) .. string.rep('☆', 3 - n) end
local function secondi(mmss) local m, s = mmss:match('(%d+):(%d+)') return tonumber(m) * 60 + tonumber(s) end
local function eco(chunks) vim.api.nvim_echo(chunks, true, {}) end

local function barre(s)
  local p = PASSI[s.passo]
  stato.titolo = 'Lezione ' .. s.L.numero .. ' · ' .. s.L.breve
  stato.destra = string.rep('●', p) .. string.rep('○', 6 - p) .. '  ' .. NOMI[s.passo]
  vim.cmd('redrawtabline')
end

local function mappa(buf, tasti, fn)
  for _, k in ipairs(type(tasti) == 'table' and tasti or { tasti }) do
    vim.keymap.set('n', k, fn, { buffer = buf, nowait = true, silent = true })
  end
end

local function apri_video(s, minuto)
  local url = 'https://www.youtube.com/watch?v=' .. s.L.video.id .. '&t=' .. secondi(minuto or s.L.video.da) .. 's'
  local ok = pcall(vim.ui.open, url)
  if not ok then eco({ { url, 'DattiloCiano' } }) end
end

function M.chiudi()
  local s = M.s
  if not s then return end
  if s.timer then s.timer:stop() s.timer:close() s.timer = nil end
  if s.e then esercizio.chiudi(s.e) s.e = nil end
  if s.buf and vim.api.nvim_buf_is_valid(s.buf) then batti.stacca(s.buf) end
  pcall(vim.api.nvim_del_augroup_by_name, 'dattilo_lezione')
  M.s = nil
end

---------------------------------------------------------------- briefing
local function briefing(s)
  s.passo = 'briefing'
  barre(s)
  ui.chiudi_tip()
  stato.file, stato.metriche = 'lezione ' .. s.L.numero, nil
  local L = s.L
  local r = {
    {},
    { { '   ' .. L.titolo, 'DattiloForte' } },
    { { '   antirez · ' .. L.video.durata .. ' · youtu.be/' .. L.video.id, 'DattiloMuto' } },
    {},
  }
  for _, l in ipairs(ui.a_capo(L.briefing, math.min(76, vim.o.columns - 6))) do r[#r + 1] = { { '   ' .. l, 'DattiloTesto' } } end
  r[#r + 1] = {}
  r[#r + 1] = { { '   Tu adesso', 'DattiloAccento' } }
  for i, p in ipairs(L.passi) do
    r[#r + 1] = { { '   ' .. i .. '  ', 'DattiloAccento' }, { string.format('%-24s', p[1]), 'DattiloForte' }, { p[2], 'DattiloMuto' } }
  end
  r[#r + 1] = {}
  local mosse = table.concat(vim.tbl_map(function(k) return '‹' .. k .. '›' end, L.mosse), ' ')
  r[#r + 1] = schermo.con_tasti('   Mosse nuove   ', mosse)
  r[#r + 1] = { { '   Concetti      ', 'DattiloTesto' }, { table.concat(L.concetti, ' · '), 'DattiloForte' } }
  r[#r + 1] = { { '   Tempo         ', 'DattiloTesto' }, { L.tempo, 'DattiloForte' } }
  r[#r + 1] = {}
  r[#r + 1] = schermo.con_tasti('   ', '‹Invio› inizia   ‹v› apre il video al minuto ' .. L.video.da .. '   ‹q› torna alla home', 'DattiloMuto')
  local buf = schermo.buffer('briefing')
  schermo.scrivi(buf, r)
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  mappa(buf, { '<CR>', 'l' }, function() if M.s == s then M.batti(s) end end)
  mappa(buf, 'v', function() apri_video(s) end)
  mappa(buf, 'q', function() require('dattilo.home').apri() end)
end

---------------------------------------------------------------- batti
local function tip_batti(s)
  local st, modo = s.st, vim.api.nvim_get_mode().mode:sub(1, 1)
  if s.frecce then return 'FRECCE', 'Qui le frecce non valgono: in NORMAL ti muovi con ‹h› ‹j› ‹k› ‹l›. Le dita restano sulla riga centrale.', 'rosso' end
  if modo == 'c' then return 'COMANDO', 'Stai scrivendo un comando. ‹Invio› lo esegue, ‹Esc› annulla.' end
  if st.finito and modo == 'i' then
    return 'FATTO', 'Scritto in ' .. tempo(st.metriche:tempo(ora())) .. ' a ' .. st.metriche:wpm(ora()) .. ' parole al minuto. Ora ‹Esc› per tornare in NORMAL.', 'verde'
  end
  if st.finito then return 'SALVA', 'Salva e compila: scrivi ‹:w› e premi ‹Invio›. dattilo lancia cc con i warning accesi.', 'verde' end
  if modo ~= 'i' then
    if not st.metriche.inizio then return 'TIP', 'Sei in NORMAL: qui i tasti sono comandi, non lettere. Premi ‹i› per entrare in INSERT e scrivere il codice in grigio.' end
    return 'TIP', 'Sei in NORMAL. ‹i› torna a scrivere, ‹x› cancella il carattere sotto il cursore, ‹u› annulla.'
  end
  local r = vim.api.nvim_win_get_cursor(0)[1]
  local riga, t = vim.api.nvim_buf_get_lines(s.buf, r - 1, r, false)[1] or '', s.L.batti.codice[r] or ''
  if riga ~= t:sub(1, #riga) then
    return 'ERRORE', 'Il rosso è un errore. ‹Backspace› e riscrivi: in C basta un carattere sbagliato per non compilare.', 'rosso'
  end
  local sugg = s.L.batti.suggerimenti[r]
  if sugg then return 'TIP', sugg end
  return 'TIP', 'Vai avanti a scrivere. Velocità e precisione sono in basso a destra.'
end

local function tip(s)
  if not M.s or M.s ~= s then return end
  if s.passo == 'batti' then
    if s.st then ui.tip(tip_batti(s)) end
  elseif s.passo == 'modifica' and s.e then ui.tip(esercizio.testo_tip(s.e))
  elseif s.passo == 'rompi' then
    local modo = vim.api.nvim_get_mode().mode:sub(1, 1)
    local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
    if modo == 'i' then ui.tip('TIP', '‹Esc› per tornare in NORMAL.')
    elseif s.rotto and not s.L.rompi.rotto(righe) then ui.tip('RIPARATO', 'Ora ‹:w› per ricompilare.', 'verde')
    elseif s.rotto then ui.tip('CAPITO?', s.L.rompi.dopo)
    else ui.tip(s.L.rompi.titolo:upper(), s.L.rompi.consegna) end
  end
end

local function salvato(s)
  local L = s.L
  local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  local dir = vim.fn.fnamemodify(s.percorso, ':h')
  if s.passo == 'batti' then
    if not vim.deep_equal(righe, L.batti.codice) then
      local mancano = #table.concat(L.batti.codice, '\n') - #table.concat(righe, '\n')
      eco({ { mancano > 0 and ('"' .. L.file .. '" salvato. Mancano ancora ' .. mancano .. ' caratteri prima di compilare.')
        or ('"' .. L.file .. '" salvato, ma qualcosa non torna: cerca il rosso.'), 'DattiloGiallo' } })
      return
    end
    local r = compila.esegui(dir, L.file)
    eco(compila.messaggio(r))
    if r.ok and r.uscita == L.esegui.atteso then
      local m = s.st.metriche
      s.risultato = { wpm = m:wpm(ora()), precisione = m:precisione(), tempo_ms = m:tempo(ora()) }
      vim.schedule(function() M.modifica(s, 1) end)
    end
  elseif s.passo == 'modifica' then
    eco({ { 'Prima finisci la modifica: ' .. L.modifiche[s.mi].consegna, 'DattiloGiallo' } })
  elseif s.passo == 'rompi' then
    local r = compila.esegui(dir, L.file)
    local chunks = compila.messaggio(r)
    if L.rompi.rotto(righe) then
      if (L.rompi.attesa == 'errore' and not r.compilato) or (L.rompi.attesa == 'warning' and r.warning) then s.rotto = true end
      eco(chunks)
    elseif vim.deep_equal(righe, L.rompi.ripara) then
      if not s.rotto then
        chunks[#chunks + 1] = { '\nFunziona. Ma prima rompilo, come dice il suggerimento in alto.', 'DattiloGiallo' }
        eco(chunks)
      else
        eco(chunks)
        if r.ok then vim.schedule(function() M.spiegazione(s) end) end
      end
    else
      chunks[#chunks + 1] = { '\nIl codice non è quello atteso: :e! riparte dalla versione giusta.', 'DattiloGiallo' }
      eco(chunks)
    end
    tip(s)
  end
end

function M.batti(s)
  s.passo = 'batti'
  barre(s)
  local L = s.L
  s.percorso = progressi.lavoro(L.id) .. '/' .. L.file
  vim.fn.writefile({}, s.percorso)
  vim.api.nvim_set_current_win(schermo.finestra())
  vim.cmd('silent! keepalt edit! ' .. vim.fn.fnameescape(s.percorso))
  s.buf = vim.api.nvim_get_current_buf()
  vim.bo[s.buf].swapfile = false
  schermo.mostra(s.buf, 'editor')
  pcall(vim.treesitter.start, s.buf, 'c')
  s.frecce = false
  s.st = batti.avvia(s.buf, L.batti.codice, {
    su_cambio = function() tip(s) end,
    su_finito = function() tip(s) vim.cmd('redrawstatus') end,
  })
  stato.file = L.file
  stato.metriche = function()
    if s.passo == 'batti' then
      local m = s.st.metriche
      return { m:wpm(ora()) .. ' wpm', perc(m:precisione()), tempo(m:tempo(ora())) }
    elseif s.passo == 'modifica' and s.e then
      return { 'tasti ' .. s.e.tasti, 'par ' .. L.modifiche[s.mi].par }
    end
    return { NOMI[s.passo] }
  end
  local g = vim.api.nvim_create_augroup('dattilo_lezione', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePost', { group = g, buffer = s.buf, callback = function() if M.s == s then salvato(s) end end })
  vim.api.nvim_create_autocmd({ 'ModeChanged', 'CursorMovedI', 'TextChanged', 'TextChangedI' }, { group = g, buffer = s.buf, callback = function()
    if M.s == s and s.frecce then s.frecce = false end
    tip(s)
  end })
  vim.api.nvim_create_autocmd('ModeChanged', { group = g, callback = function() if M.s == s then tip(s) end end })
  for _, k in ipairs({ '<Left>', '<Right>', '<Up>', '<Down>' }) do
    vim.keymap.set({ 'n', 'i' }, k, function() s.frecce = true tip(s) end, { buffer = s.buf })
  end
  s.timer = vim.uv.new_timer()
  s.timer:start(500, 500, vim.schedule_wrap(function()
    if M.s == s and s.passo == 'batti' and s.st.metriche.inizio and not s.st.finito then vim.cmd('redrawstatus') end
  end))
  tip(s)
end

---------------------------------------------------------------- modifica
function M.modifica(s, i)
  if M.s ~= s then return end
  local L = s.L
  local m = L.modifiche[i]
  s.passo, s.mi = 'modifica', i
  barre(s)
  batti.stacca(s.buf)
  if s.e then esercizio.chiudi(s.e) end
  vim.api.nvim_set_current_win(schermo.finestra())
  s.e = esercizio.avvia(vim.tbl_extend('force', m, {
    buf = s.buf,
    partenza = m.partenza or L.batti.codice,
    su_aggiorna = function() tip(s) vim.cmd('redrawstatus') end,
    su_fatto = function(tasti, n)
      s.tasti_modifica = (s.tasti_modifica or 0) + tasti
      s.par_modifica = (s.par_modifica or 0) + m.par
      eco({ { 'Fatto in ' .. tasti .. ' tasti. Par ' .. m.par .. ' ' .. stelle(n), 'DattiloVerde' },
        { '\nLa via corta: ' .. table.concat(m.mostra, '  '), 'DattiloTesto' } })
      vim.schedule(function()
        if M.s ~= s then return end
        esercizio.chiudi(s.e)
        s.e = nil
        if i < #L.modifiche then M.modifica(s, i + 1) else M.rompi(s) end
      end)
    end,
  }))
  tip(s)
end

---------------------------------------------------------------- rompi
function M.rompi(s)
  s.passo, s.rotto = 'rompi', false
  barre(s)
  vim.api.nvim_set_current_win(schermo.finestra())
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  tip(s)
end

function M.ricomincia()
  local s = M.s
  if not s then return end
  if s.passo == 'batti' then M.batti(s)
  elseif s.passo == 'modifica' and s.e then esercizio.ricomincia(s.e)
  elseif s.passo == 'rompi' then
    vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, s.L.rompi.ripara)
    s.rotto = false
    tip(s)
  end
end

---------------------------------------------------------------- spiegazione
function M.spiegazione(s)
  if M.s ~= s then return end
  s.passo = 'spiegazione'
  barre(s)
  batti.stacca(s.buf)
  ui.chiudi_tip()
  local L, sp = s.L, s.L.spiegazione
  stato.file, stato.metriche = L.file, function() return { 'sola lettura' } end
  local buf = schermo.buffer('spiegazione')
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, L.rompi.ripara)
  vim.bo[buf].modifiable, vim.bo[buf].modified = false, false
  pcall(vim.treesitter.start, buf, 'c')
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local largo = 0
  for _, l in ipairs(L.rompi.ripara) do largo = math.max(largo, vim.fn.strdisplaywidth(l)) end
  local col = largo + 4
  for riga, note in pairs(sp.note) do
    local altre = {}
    for k = 2, #note do altre[#altre + 1] = { { string.rep(' ', col) .. note[k], 'DattiloTesto' } } end
    vim.api.nvim_buf_set_extmark(buf, ns, riga - 1, 0, { virt_text = { { note[1], 'DattiloTesto' } }, virt_text_win_col = col, virt_lines = #altre > 0 and altre or nil })
  end
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { virt_lines_above = true, virt_lines = { { { 'Cosa hai scritto', 'DattiloAccento' } }, { { '' } } } })
  local sotto = { { { '' } }, { { 'Da antirez', 'DattiloAccento' } } }
  for _, m in ipairs(sp.momenti) do sotto[#sotto + 1] = { { '┃ ', 'DattiloMuto' }, { m[1] .. '  ', 'DattiloCiano' }, { m[2], 'DattiloTesto' } } end
  sotto[#sotto + 1] = { { '' } }
  sotto[#sotto + 1] = { { 'Trappola  ', 'DattiloRosso' }, { sp.trappola, 'DattiloTesto' } }
  sotto[#sotto + 1] = { { 'Prova     ', 'DattiloVerde' }, { sp.prova, 'DattiloTesto' } }
  sotto[#sotto + 1] = { { '' } }
  sotto[#sotto + 1] = ui.segmenti('‹Invio› continua   ‹v› apre il video al primo momento   ‹q› torna alla home', 'DattiloMuto')
  vim.api.nvim_buf_set_extmark(buf, ns, #L.rompi.ripara - 1, 0, { virt_lines = sotto })
  schermo.mostra(buf, 'testo')
  vim.wo.number = true
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.fn.winrestview({ topfill = 2 })
  mappa(buf, { '<CR>', 'l' }, function() if M.s == s then M.fine(s) end end)
  mappa(buf, 'v', function() apri_video(s, sp.momenti[1][1]) end)
  mappa(buf, 'q', function() require('dattilo.home').apri() end)
end

---------------------------------------------------------------- fine
function M.fine(s)
  s.passo = 'fine'
  barre(s)
  local L, ris = s.L, s.risultato or { wpm = 0, precisione = 100, tempo_ms = 0 }
  ris.tasti_modifica = s.tasti_modifica
  progressi.registra(L.id, ris)
  stato.file, stato.metriche = 'lezione ' .. L.numero, function() return { 'completata' } end
  local tasti, par = s.tasti_modifica or 0, s.par_modifica or 0
  local indice = require('dattilo.lezioni.indice')
  local pros = L.prossima and indice[L.prossima]
  local mosse = table.concat(vim.tbl_map(function(k) return '‹' .. k .. '›' end, L.mosse), ' ')
  local r = {
    {},
    { { '   Batti      ', 'DattiloTesto' }, { #L.batti.codice .. ' righe in ' .. tempo(ris.tempo_ms), 'DattiloForte' },
      { '   ' .. ris.wpm .. ' parole al minuto · ' .. perc(ris.precisione) .. ' di precisione', 'DattiloVerde' } },
    { { '   Modifica   ', 'DattiloTesto' }, { tasti .. ' tasti, par ' .. par .. ' ', 'DattiloForte' }, { stelle(esercizio.stelle(tasti, par)), 'DattiloStella' } },
    { { '   Rompi      ', 'DattiloTesto' }, { L.rompi.attesa == 'errore' and 'hai letto un errore vero di gcc' or 'hai letto un warning vero di gcc', 'DattiloForte' } },
    {},
    schermo.con_tasti('   Mosse      ', mosse),
    { { '   Concetti   ', 'DattiloTesto' }, { table.concat(L.concetti, ' · '), 'DattiloForte' } },
    {},
    { { '   Ripasso    ', 'DattiloTesto' }, { 'domani, poi tra 3 e 7 giorni (arriva con il passo 5)', 'DattiloForte' } },
  }
  if pros then
    r[#r + 1] = { { '   Prossima   ', 'DattiloTesto' }, { pros.etichetta .. ' · ' .. pros.titolo, 'DattiloCiano' } }
  end
  r[#r + 1] = {}
  r[#r + 1] = schermo.con_tasti('   ', (pros and pros.file and '‹Invio› prossima lezione   ' or '‹Invio› torna alla home   ') .. '‹r› rifai questa   ‹q› home', 'DattiloMuto')
  local buf = schermo.buffer('fine')
  schermo.scrivi(buf, r)
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  mappa(buf, { '<CR>', 'l' }, function()
    if pros and pros.file then M.apri(L.prossima) else require('dattilo.home').apri() end
  end)
  mappa(buf, 'r', function() M.apri(L.numero) end)
  mappa(buf, 'q', function() require('dattilo.home').apri() end)
end

---------------------------------------------------------------- apertura
function M.apri(n)
  M.chiudi()
  require('dattilo.dojo').chiudi()
  local L = require('dattilo.lezioni.' .. string.format('%02d', n))
  local s = { L = L, passo = 'briefing' }
  M.s = s
  stato.schermo = 'lezione'
  briefing(s)
end

return M
