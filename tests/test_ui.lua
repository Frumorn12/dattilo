local ui = require('dattilo.ui')
local stato = require('dattilo.stato')
local T = {}
local dw = vim.fn.strdisplaywidth

T['a capo a parole intere'] = function()
  uguale(ui.a_capo('aa bb cc', 5), { 'aa bb', 'cc' })
end
T['a capo non spezza un tasto'] = function()
  uguale(ui.a_capo('premi ‹:w› ora', 8), { 'premi', '‹:w› ora' })
end
T['a capo: un tasto con spazi resta intero'] = function()
  uguale(ui.a_capo('premi ‹int x, int y› ora', 40), { 'premi ‹int x, int y› ora' })
  uguale(ui.a_capo('premi ‹int x, int y› ora', 16), { 'premi', '‹int x, int y›', 'ora' })
end
T['a capo forzato con \\n'] = function()
  uguale(ui.a_capo('uno\ndue', 20), { 'uno', 'due' })
end
T['segmenti: i tasti diventano evidenziati'] = function()
  uguale(ui.segmenti('premi ‹i›', 'X'), { { 'premi ', 'X' }, { ' i ', 'DattiloTasto' } })
end
T['riquadro: bordo, titolo e larghezza costante'] = function()
  local righe, segni = ui.riquadro('TIP', 'ciao ‹i›', 20, 2)
  uguale(#righe, 4)
  vero(righe[1]:find('^╭─ TIP ') ~= nil, righe[1])
  for _, r in ipairs(righe) do uguale(dw(r), 20, r) end
  local tasto = vim.tbl_filter(function(s) return s.hl == 'DattiloTasto' end, segni)[1]
  uguale(righe[2]:sub(tasto.da + 1, tasto.a), ' i ')
end
T['riquadro: tipo rosso usa il bordo rosso'] = function()
  local _, segni = ui.riquadro('ERRORE', 'x', 30, 1, 'rosso')
  vero(vim.tbl_contains(vim.tbl_map(function(s) return s.hl end, segni), 'DattiloBordoRosso'))
end
T['tabline con nome dell\'app e titolo'] = function()
  stato.titolo, stato.destra = 'Lezione 1 · Hello World', '2/6 batti'
  local s = ui.tabline()
  vero(s:find('dattilo', 1, true) and s:find('Lezione 1', 1, true) and s:find('2/6 batti', 1, true), s)
end
T['statusline con modo, file e metriche, % protetti'] = function()
  stato.file = 'hello.c'
  stato.metriche = function() return { '42 wpm', '97,5%' } end
  local s = ui.statusline()
  vero(s:find('NORMAL', 1, true) and s:find('hello.c', 1, true) and s:find('42 wpm', 1, true) and s:find('97,5%%', 1, true), s)
  stato.metriche = nil
end
T['il suggerimento segue la larghezza del terminale'] = function()
  vim.o.columns = 90
  ui.colori()
  ui.tip('TIP', 'premi ‹i› per scrivere', nil)
  local buf = vim.api.nvim_win_get_buf(ui.finestra_tip())
  uguale(dw(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]), 90)
  vim.o.columns = 60
  vim.api.nvim_exec_autocmds('VimResized', {})
  uguale(dw(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]), 60)
  uguale(vim.api.nvim_win_get_height(ui.finestra_tip()), 5)
  uguale(#vim.api.nvim_buf_get_lines(buf, 0, -1, false), 5)
end
T['la finestra del suggerimento non tiene il fuoco'] = function()
  local tip = ui.finestra_tip()
  vim.api.nvim_set_current_win(tip)
  vim.wait(50, function() return vim.api.nvim_get_current_win() ~= tip end)
  vero(vim.api.nvim_get_current_win() ~= tip)
end
return T
