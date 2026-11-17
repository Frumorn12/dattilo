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
T['riquadro a sezioni: etichette in colonna e testo che va a capo sotto di sé'] = function()
  local righe = ui.riquadro('RIGA 2', {
    { etichetta = 'Riga', testo = 'uno due tre quattro cinque sei sette otto', priorita = 3 },
    { etichetta = 'Blocco', testo = 'blocco', priorita = 2 },
  }, 40, 4)
  uguale(#righe, 6)
  for _, r in ipairs(righe) do uguale(dw(r), 40, r) end
  vero(righe[2]:find('^│ Riga     uno') ~= nil, righe[2])
  vero(righe[3]:find('^│          %S') ~= nil, righe[3])
  vero(righe[4]:find('^│ Blocco   blocco') ~= nil, righe[4])
end
T['riquadro a sezioni: con poco spazio si accorcia la meno importante, con …'] = function()
  local lungo = string.rep('parola ', 30)
  local righe = ui.riquadro('X', {
    { testo = 'avviso', priorita = 5 },
    { etichetta = 'Riga', testo = 'riga corta', priorita = 4 },
    { etichetta = 'Blocco', testo = lungo, priorita = 1 },
    { etichetta = 'Fin qui', testo = lungo, priorita = 3 },
  }, 50, 5)
  uguale(#righe, 7)
  for _, r in ipairs(righe) do uguale(dw(r), 50, r) end
  vero(righe[2]:find('avviso', 1, true), righe[2])
  vero(righe[4]:find('Blocco', 1, true) and righe[4]:find('…', 1, true), righe[4])
  vero(righe[5]:find('Fin qui', 1, true), righe[5])
  vero(righe[6]:find('…', 1, true), righe[6])
end
T['riquadro a sezioni: più sezioni che righe, restano le più importanti'] = function()
  local righe = ui.riquadro('X', {
    { etichetta = 'A', testo = 'a', priorita = 1 }, { etichetta = 'B', testo = 'b', priorita = 3 }, { etichetta = 'C', testo = 'c', priorita = 2 },
  }, 30, 2)
  vero(righe[2]:find('B', 1, true) and righe[3]:find('C', 1, true), vim.inspect(righe))
end
T['altezza del riquadro: 8 righe in lezione, poi di nuovo 3'] = function()
  vim.o.columns = 80
  ui.tip('TIP', 'ciao', nil)
  ui.altezza_tip(8)
  uguale(vim.api.nvim_win_get_height(ui.finestra_tip()), 10)
  local buf = vim.api.nvim_win_get_buf(ui.finestra_tip())
  uguale(#vim.api.nvim_buf_get_lines(buf, 0, -1, false), 10)
  ui.altezza_tip(nil)
  uguale(vim.api.nvim_win_get_height(ui.finestra_tip()), 5)
end
return T
