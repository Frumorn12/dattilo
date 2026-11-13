-- Una lezione: briefing → batti → modifica → rompi → spiegazione → fine.
local batti = require('dattilo.batti')
local compila = require('dattilo.compila')
local confronto = require('dattilo.confronto')
local esercizio = require('dattilo.esercizio')
local pacchetti = require('dattilo.pacchetti')
local progressi = require('dattilo.progressi')
local schermo = require('dattilo.schermo')
local stato = require('dattilo.stato')
local ui = require('dattilo.ui')

local M = {}
local PASSI = { briefing = 1, batti = 2, modifica = 3, rompi = 4, esegui = 4, spiegazione = 5, fine = 6 }
local NOMI = { briefing = 'briefing', batti = 'batti', modifica = 'modifica', rompi = 'rompi', esegui = 'esegui', spiegazione = 'spiegazione', fine = 'riepilogo' }
local ns = vim.api.nvim_create_namespace('dattilo_lezione')

local function ora() return vim.uv.hrtime() / 1e6 end
local function tempo(ms) local s = math.floor(ms / 1000 + 0.5) return string.format('%d:%02d', math.floor(s / 60), s % 60) end
local function perc(p) local s = string.format('%.1f', p):gsub('%.0$', ''):gsub('%.', ',') return s .. '%' end
local function stelle(n) return string.rep('★', n) .. string.rep('☆', 3 - n) end
local function secondi(mmss) local m, s = mmss:match('(%d+):(%d+)') return tonumber(m) * 60 + tonumber(s) end
local function eco(chunks) vim.api.nvim_echo(chunks, true, {}) end

local function barre(s)
  local p = PASSI[s.passo]
  stato.titolo = s.L.etichetta .. ' · ' .. s.L.breve
  stato.destra = string.rep('●', p) .. string.rep('○', 6 - p) .. '  ' .. NOMI[s.passo]
  vim.cmd('redrawtabline')
end

local function mappa(buf, tasti, fn)
  for _, k in ipairs(type(tasti) == 'table' and tasti or { tasti }) do
    vim.keymap.set('n', k, fn, { buffer = buf, nowait = true, silent = true })
  end
end

-- Testo finale della lezione: obiettivo dell'ultima modifica, o il codice di Batti.
local function finale(L)
  if L.rompi then return L.rompi.ripara end
  return #L.modifiche > 0 and L.modifiche[#L.modifiche].obiettivo or L.batti.codice
end

local function strumento(L) return L.esecuzione.tipo == 'compila' and 'gcc' or (L.esecuzione.comando and L.esecuzione.comando[1]) or 'node' end

local function apri_video(s, minuto)
  if not s.L.video then eco({ { 'Questa lezione non ha un video.', 'DattiloGiallo' } }) return end
  local url = 'https://www.youtube.com/watch?v=' .. s.L.video.id .. '&t=' .. secondi(minuto or s.L.video.da) .. 's'
  local ok = pcall(vim.ui.open, url)
  if not ok then eco({ { url, 'DattiloCiano' } }) end
end

function M.chiudi()
  local s = M.s
  if not s then return end
  if s.timer then s.timer:stop() s.timer:close() s.timer = nil end
  if s.e then esercizio.chiudi(s.e) s.e = nil end
  if s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    batti.stacca(s.buf)
    vim.bo[s.buf].modified = false -- il file di lavoro non deve bloccare :qa
  end
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
    L.video and { { '   antirez · ' .. (L.video.durata or '') .. ' · youtu.be/' .. L.video.id, 'DattiloMuto' } }
      or { { '   ' .. (L.fonte and ('da ' .. L.fonte) or (pacchetti.carica(L.pacchetto) or { m = { titolo = '' } }).m.titolo), 'DattiloMuto' } },
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
  if #L.mosse == 0 then table.remove(r) end
  if #L.concetti == 0 then table.remove(r) end
  if L.tempo then r[#r + 1] = { { '   Tempo         ', 'DattiloTesto' }, { L.tempo, 'DattiloForte' } } end
  r[#r + 1] = {}
  r[#r + 1] = schermo.con_tasti('   ', '‹Invio› inizia   ' .. (L.video and ('‹v› apre il video al minuto ' .. L.video.da .. '   ') or '') .. '‹q› torna alla home', 'DattiloMuto')
  local buf = schermo.buffer('briefing')
  schermo.scrivi(buf, r)
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  mappa(buf, { '<CR>', 'l' }, function() if M.s == s then M.batti(s) end end)
  mappa(buf, 'v', function() apri_video(s) end)
  mappa(buf, 'q', function() require('dattilo.home').apri() end)
end

---------------------------------------------------------------- batti
-- Suggerimento della schermata Batti; `modo` è la prima lettera della modalità di Neovim.
function M.tip_batti(s, modo)
  local st = s.st
  if s.frecce then
    if modo == 'i' then
      return 'FRECCE', 'Sei in INSERT: qui ogni tasto scrive, anche h j k l. Per spostarti premi ‹Esc›, poi ‹h› ‹j› ‹k› ‹l›, poi ‹i› per tornare a scrivere. Sulla stessa riga basta ‹Backspace›.', 'rosso'
    end
    return 'FRECCE', 'Le frecce qui non valgono: ti muovi con ‹h› ‹j› ‹k› ‹l›, senza staccare le dita dalla riga centrale. Poi ‹i› per scrivere.', 'rosso'
  end
  if modo == 'c' then return 'COMANDO', 'Stai scrivendo un comando. ‹Invio› lo esegue, ‹Esc› annulla.' end
  if st.finito and modo == 'i' then
    return 'FATTO', 'Scritto in ' .. tempo(st.metriche:tempo(ora())) .. ' a ' .. st.metriche:wpm(ora()) .. ' parole al minuto. Ora ‹Esc› per tornare in NORMAL.', 'verde'
  end
  if st.finito then return 'SALVA', 'Salva e compila: scrivi ‹:w› e premi ‹Invio›. dattilo lancia cc con i warning accesi.', 'verde' end
  local r = vim.api.nvim_win_get_cursor(0)[1]
  local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  local codice = s.L.batti.codice
  local riga, t = righe[r] or '', codice[r] or ''
  if modo == 'i' and riga ~= t:sub(1, #riga) then
    return 'ERRORE', 'Il rosso è un errore. ‹Backspace› e riscrivi: in C basta un carattere sbagliato per non compilare.', 'rosso'
  end
  -- una riga sopra il cursore è rimasta a metà (di solito un Invio di troppo presto)
  for i = 1, r - 1 do
    if righe[i] ~= codice[i] then
      if modo == 'i' then
        return 'RIGA ' .. i, 'La riga ' .. i .. ' non è finita. ‹Backspace› a inizio riga la riunisce a quella sopra; oppure ‹Esc›, sali con ‹k›, poi ‹A› per scrivere a fine riga.'
      end
      return 'RIGA ' .. i, 'La riga ' .. i .. ' non è finita: sali con ‹k›, poi ‹A› per scrivere a fine riga. Con ‹j› torni giù.'
    end
  end
  if modo ~= 'i' then
    if not st.metriche.inizio then return 'TIP', 'Sei in NORMAL: qui i tasti sono comandi, non lettere. Premi ‹i› per entrare in INSERT e scrivere il codice in grigio.' end
    return 'TIP', 'Sei in NORMAL: ‹h› ‹j› ‹k› ‹l› ti spostano, ‹i› torna a scrivere, ‹x› cancella il carattere sotto il cursore, ‹u› annulla.'
  end
  local sugg = s.L.batti.suggerimenti[r]
  if sugg then return 'TIP', sugg end
  return 'TIP', 'Vai avanti a scrivere. Per spostarti: ‹Esc›, poi ‹h› ‹j› ‹k› ‹l›, poi ‹i›.'
end

local function tip(s)
  if not M.s or M.s ~= s then return end
  if s.passo == 'batti' then
    if s.st then ui.tip(M.tip_batti(s, vim.api.nvim_get_mode().mode:sub(1, 1))) end
  elseif s.passo == 'modifica' and s.e then ui.tip(esercizio.testo_tip(s.e))
  elseif s.passo == 'rompi' then
    local modo = vim.api.nvim_get_mode().mode:sub(1, 1)
    local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
    if modo == 'i' then ui.tip('TIP', '‹Esc› per tornare in NORMAL.')
    elseif s.rotto and confronto.confronta(righe, s.L.rompi.ripara).finito then ui.tip('RIPARATO', 'Ora ‹:w› per ricontrollare.', 'verde')
    elseif s.rotto then ui.tip('CAPITO?', s.L.rompi.dopo)
    else ui.tip(s.L.rompi.titolo:upper(), s.L.rompi.consegna) end
  elseif s.passo == 'esegui' then
    if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then ui.tip('TIP', '‹Esc› per tornare in NORMAL.')
    else ui.tip('ESEGUI', 'Ora ‹:w›: dattilo salva ed esegue il codice. Se gira pulito, si passa alla spiegazione.') end
  end
end

local function salvato(s)
  local L = s.L
  local righe = vim.api.nvim_buf_get_lines(s.buf, 0, -1, false)
  local dir = vim.fn.fnamemodify(s.percorso, ':h')
  local function lancia() return compila.lancia(dir, L.file, L.esecuzione) end
  if s.passo == 'batti' then
    if not confronto.confronta(righe, L.batti.codice).finito then
      local mancano = #table.concat(L.batti.codice, '\n') - #table.concat(righe, '\n')
      eco({ { mancano > 0 and ('"' .. L.file .. '" salvato. Mancano ancora ' .. mancano .. ' caratteri prima di eseguire.')
        or ('"' .. L.file .. '" salvato, ma qualcosa non torna: cerca il rosso.'), 'DattiloGiallo' } })
      return
    end
    local r = lancia()
    eco(compila.messaggio(r))
    if r.ok and (not L.esegui.atteso or r.uscita == L.esegui.atteso) then
      local m = s.st.metriche
      s.risultato = { wpm = m:wpm(ora()), precisione = m:precisione(), tempo_ms = m:tempo(ora()) }
      vim.schedule(function() M.dopo_modifica(s, 0) end)
    end
  elseif s.passo == 'modifica' then
    eco({ { 'Prima finisci la modifica: ' .. L.modifiche[s.mi].consegna, 'DattiloGiallo' } })
  elseif s.passo == 'rompi' then
    local r = lancia()
    local chunks = compila.messaggio(r)
    if compila.fallito(r, L.rompi.attesa, L.rompi.cerca) then
      s.rotto = true
      eco(chunks)
    elseif confronto.confronta(righe, L.rompi.ripara).finito then
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
  elseif s.passo == 'esegui' then
    local r = lancia()
    eco(compila.messaggio(r))
    if r.ok then vim.schedule(function() M.spiegazione(s) end) end
  end
end

-- Dopo la modifica i (0 = dopo Batti): la prossima modifica, Rompi o il passo esegui.
function M.dopo_modifica(s, i)
  if M.s ~= s then return end
  local L = s.L
  if i < #L.modifiche then M.modifica(s, i + 1)
  elseif L.rompi then M.rompi(s)
  else M.esegui(s) end
end

function M.batti(s)
  s.passo = 'batti'
  barre(s)
  local L = s.L
  local dir = progressi.lavoro(L.pacchetto .. '/' .. L.id)
  if L.cartella_file then
    for _, f in ipairs(vim.fn.readdir(L.cartella_file)) do vim.uv.fs_copyfile(L.cartella_file .. '/' .. f, dir .. '/' .. f) end
  end
  s.percorso = dir .. '/' .. L.file
  vim.fn.writefile({}, s.percorso)
  vim.api.nvim_set_current_win(schermo.finestra())
  vim.cmd('silent! keepalt edit! ' .. vim.fn.fnameescape(s.percorso))
  s.buf = vim.api.nvim_get_current_buf()
  vim.bo[s.buf].swapfile = false
  schermo.mostra(s.buf, 'editor')
  pcall(vim.treesitter.start, s.buf, L.linguaggio or 'c')
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
  vim.keymap.set('n', 'ZZ', '<Cmd>DattiloEsci<CR>', { buffer = s.buf })
  vim.keymap.set('n', 'ZQ', '<Cmd>DattiloEsci<CR>', { buffer = s.buf })
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
        M.dopo_modifica(s, i)
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

function M.esegui(s)
  s.passo = 'esegui'
  barre(s)
  vim.api.nvim_set_current_win(schermo.finestra())
  tip(s)
end

function M.tip() if M.s then tip(M.s) end end

function M.ricomincia()
  local s = M.s
  if not s then return end
  if s.passo == 'batti' then M.batti(s)
  elseif s.passo == 'modifica' and s.e then esercizio.ricomincia(s.e)
  elseif s.passo == 'rompi' then
    vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, s.L.rompi.ripara)
    s.rotto = false
    tip(s)
  elseif s.passo == 'esegui' then
    vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, finale(s.L))
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
  local codice = finale(L)
  stato.file, stato.metriche = L.file, function() return { 'sola lettura' } end
  local buf = schermo.buffer('spiegazione')
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, codice)
  vim.bo[buf].modifiable, vim.bo[buf].modified = false, false
  pcall(vim.treesitter.start, buf, L.linguaggio or 'c')
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local largo = 0
  for _, l in ipairs(codice) do largo = math.max(largo, vim.fn.strdisplaywidth(l)) end
  local col = largo + 4
  for riga, note in pairs(sp.note) do
    if riga >= 1 and riga <= #codice then
      local altre = {}
      for k = 2, #note do altre[#altre + 1] = { { string.rep(' ', col) .. note[k], 'DattiloTesto' } } end
      vim.api.nvim_buf_set_extmark(buf, ns, riga - 1, 0, { virt_text = { { note[1], 'DattiloTesto' } }, virt_text_win_col = col, virt_lines = #altre > 0 and altre or nil })
    end
  end
  local testa = { { { 'Cosa hai scritto', 'DattiloAccento' } } }
  if L.fonte then testa[#testa + 1] = { { 'da ' .. L.fonte, 'DattiloMuto' } } end
  testa[#testa + 1] = { { '' } }
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { virt_lines_above = true, virt_lines = testa })
  local sotto = {}
  if #sp.momenti > 0 then
    sotto[#sotto + 1] = { { '' } }
    sotto[#sotto + 1] = { { L.video and 'Dal video' or 'Momenti', 'DattiloAccento' } }
    for _, m in ipairs(sp.momenti) do sotto[#sotto + 1] = { { '┃ ', 'DattiloMuto' }, { m[1] .. '  ', 'DattiloCiano' }, { m[2], 'DattiloTesto' } } end
  end
  if sp.trappola or sp.prova then sotto[#sotto + 1] = { { '' } } end
  if sp.trappola then sotto[#sotto + 1] = { { 'Trappola  ', 'DattiloRosso' }, { sp.trappola, 'DattiloTesto' } } end
  if sp.prova then sotto[#sotto + 1] = { { 'Prova     ', 'DattiloVerde' }, { sp.prova, 'DattiloTesto' } } end
  sotto[#sotto + 1] = { { '' } }
  sotto[#sotto + 1] = ui.segmenti('‹Invio› continua   ' .. ((L.video and #sp.momenti > 0) and '‹v› apre il video al primo momento   ' or '') .. '‹q› torna alla home', 'DattiloMuto')
  vim.api.nvim_buf_set_extmark(buf, ns, #codice - 1, 0, { virt_lines = sotto })
  schermo.mostra(buf, 'testo')
  vim.wo.number = true
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.fn.winrestview({ topfill = #testa })
  mappa(buf, { '<CR>', 'l' }, function() if M.s == s then M.fine(s) end end)
  mappa(buf, 'v', function() apri_video(s, sp.momenti[1] and sp.momenti[1][1]) end)
  mappa(buf, 'q', function() require('dattilo.home').apri() end)
end

---------------------------------------------------------------- fine
function M.fine(s)
  s.passo = 'fine'
  barre(s)
  local L, ris = s.L, s.risultato or { wpm = 0, precisione = 100, tempo_ms = 0 }
  ris.tasti_modifica = s.tasti_modifica
  progressi.registra(L.pacchetto .. '/' .. L.id, ris)
  stato.file, stato.metriche = 'lezione ' .. L.numero, function() return { 'completata' } end
  local tasti, par = s.tasti_modifica or 0, s.par_modifica or 0
  local P = pacchetti.carica(L.pacchetto)
  local pros = L.prossima and P and P.lezioni[L.prossima]
  local futura = not pros and P and P.in_arrivo[1]
  local mosse = table.concat(vim.tbl_map(function(k) return '‹' .. k .. '›' end, L.mosse), ' ')
  local r = {
    {},
    { { '   Batti      ', 'DattiloTesto' }, { #L.batti.codice .. ' righe in ' .. tempo(ris.tempo_ms), 'DattiloForte' },
      { '   ' .. ris.wpm .. ' parole al minuto · ' .. perc(ris.precisione) .. ' di precisione', 'DattiloVerde' } },
  }
  if #L.modifiche > 0 then
    r[#r + 1] = { { '   Modifica   ', 'DattiloTesto' }, { tasti .. ' tasti, par ' .. par .. ' ', 'DattiloForte' }, { stelle(esercizio.stelle(tasti, par)), 'DattiloStella' } }
  end
  if L.rompi then
    r[#r + 1] = { { '   Rompi      ', 'DattiloTesto' }, { 'hai letto ' .. (L.rompi.attesa == 'errore' and 'un errore vero' or 'un warning vero') .. ' di ' .. strumento(L), 'DattiloForte' } }
  end
  r[#r + 1] = {}
  if #L.mosse > 0 then r[#r + 1] = schermo.con_tasti('   Mosse      ', mosse) end
  if #L.concetti > 0 then r[#r + 1] = { { '   Concetti   ', 'DattiloTesto' }, { table.concat(L.concetti, ' · '), 'DattiloForte' } } end
  r[#r + 1] = {}
  r[#r + 1] = { { '   Ripasso    ', 'DattiloTesto' }, { 'domani, poi tra 3 e 7 giorni (arriva con il ripasso)', 'DattiloForte' } }
  if pros then r[#r + 1] = { { '   Prossima   ', 'DattiloTesto' }, { pros.etichetta .. ' · ' .. pros.titolo, 'DattiloCiano' } }
  elseif futura then r[#r + 1] = { { '   Prossima   ', 'DattiloTesto' }, { (futura.etichetta or '') .. ' · ' .. (futura.titolo or '') .. ' (in arrivo)', 'DattiloMuto' } } end
  r[#r + 1] = {}
  r[#r + 1] = schermo.con_tasti('   ', (pros and '‹Invio› prossima lezione   ' or '‹Invio› torna all\'elenco   ') .. '‹r› rifai questa   ‹q› home', 'DattiloMuto')
  local buf = schermo.buffer('fine')
  schermo.scrivi(buf, r)
  schermo.mostra(buf, 'testo')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  mappa(buf, { '<CR>', 'l' }, function()
    if pros then M.apri(L.pacchetto, L.prossima) else require('dattilo.home').lezioni(L.pacchetto) end
  end)
  mappa(buf, 'r', function() M.apri(L.pacchetto, L.numero) end)
  mappa(buf, 'q', function() require('dattilo.home').apri() end)
end

---------------------------------------------------------------- apertura
function M.apri(pacchetto, n)
  M.chiudi()
  require('dattilo.dojo').chiudi()
  local L = pacchetti.lezione(pacchetto, n)
  if not L then
    vim.api.nvim_echo({ { 'Lezione non trovata: ' .. tostring(pacchetto) .. ' ' .. tostring(n), 'DattiloRosso' } }, true, {})
    return
  end
  local s = { L = L, passo = 'briefing' }
  M.s = s
  stato.schermo = 'lezione'
  briefing(s)
end

return M
