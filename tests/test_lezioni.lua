local compila = require('dattilo.compila')
local esercizio = require('dattilo.esercizio')
local T = {}

local function compila_righe(righe, file)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile(righe, dir .. '/' .. file)
  return compila.esegui(dir, file)
end


T['progressi: registra e ricarica'] = function()
  local vecchio = vim.env.XDG_DATA_HOME
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  local progressi = require('dattilo.progressi')
  progressi.registra('corso-c-antirez/01-hello', { wpm = 41, precisione = 96.5, tempo_ms = 42000, tasti_modifica = 18 })
  progressi.registra('corso-c-antirez/01-hello', { wpm = 35, precisione = 99, tempo_ms = 50000, tasti_modifica = 20 })
  local p = progressi.carica()
  uguale({ p.lezioni['corso-c-antirez/01-hello'].volte, p.lezioni['corso-c-antirez/01-hello'].migliore_wpm, #p.sessioni }, { 2, 41, 2 })
  vero(vim.fn.filereadable(vim.env.XDG_DATA_HOME .. '/dattilo/progressi.json') == 1)
  vero(vim.fn.isdirectory(progressi.lavoro('01-hello')) == 1)
  vim.env.XDG_DATA_HOME = vecchio
end
T['progressi: file rovinato non blocca'] = function()
  local vecchio = vim.env.XDG_DATA_HOME
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  vim.fn.mkdir(vim.env.XDG_DATA_HOME .. '/dattilo', 'p')
  vim.fn.writefile({ '{rotto' }, vim.env.XDG_DATA_HOME .. '/dattilo/progressi.json')
  local p = require('dattilo.progressi').carica()
  uguale({ p.lezioni, p.sessioni }, { {}, {} })
  vim.env.XDG_DATA_HOME = vecchio
end
T[':q diventa DattiloEsci'] = function()
  require('dattilo').abbreviazioni()
  vero(vim.fn.maparg('q', 'c', true):find('DattiloEsci', 1, true), vim.fn.maparg('q', 'c', true))
  vero(vim.fn.maparg('wq', 'c', true):find('DattiloEsci', 1, true))
  vero(vim.fn.maparg('e!', 'c', true):find('DattiloRicomincia', 1, true))
end
T['DattiloEsci da una lezione torna alla home'] = function()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo').avvia({ radice = RADICE })
  require('dattilo.lezione').apri('corso-c-antirez', 1)
  uguale(require('dattilo.stato').schermo, 'lezione')
  vim.cmd('DattiloEsci')
  uguale(require('dattilo.stato').schermo, 'home')
end
T['la lezione passa dal briefing a Batti senza errori'] = function()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo').avvia({ radice = RADICE })
  local lezione = require('dattilo.lezione')
  lezione.apri('corso-c-antirez', 1)
  lezione.batti(lezione.s)
  uguale(lezione.s.passo, 'batti')
  uguale(vim.api.nvim_buf_get_lines(0, 0, -1, false), { '' })
  vero(vim.fn.expand('%:t') == 'hello.c', vim.fn.expand('%'))
  lezione.chiudi()
end
local function avvia_app()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo').avvia({ radice = RADICE })
end
T['chiudere la finestra principale riporta alla home con una finestra sola'] = function()
  avvia_app()
  local lezione = require('dattilo.lezione')
  lezione.apri('corso-c-antirez', 1)
  lezione.batti(lezione.s)
  vim.api.nvim_win_close(require('dattilo.schermo').finestra(), true)
  vim.wait(200, function() return require('dattilo.stato').schermo == 'home' end)
  uguale(require('dattilo.stato').schermo, 'home')
  uguale(#vim.api.nvim_tabpage_list_wins(0), 1)
  uguale(vim.o.cmdheight, 1)
  uguale(vim.wo.winfixheight, false)
end
T['ZZ in una lezione torna alla home'] = function()
  avvia_app()
  local lezione = require('dattilo.lezione')
  lezione.apri('corso-c-antirez', 1)
  lezione.batti(lezione.s)
  vero(vim.fn.maparg('ZZ', 'n') ~= '', 'manca ZZ')
end
T[':q! non dà E477'] = function()
  avvia_app()
  require('dattilo.lezione').apri('corso-c-antirez', 1)
  vim.cmd('DattiloEsci!')
  uguale(require('dattilo.stato').schermo, 'home')
  vim.cmd('DattiloRicomincia!')
end
T['lasciare una lezione a metà non lascia buffer modificati'] = function()
  avvia_app()
  local lezione = require('dattilo.lezione')
  lezione.apri('corso-c-antirez', 1)
  lezione.batti(lezione.s)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '#incl' })
  vim.cmd('DattiloEsci')
  require('dattilo.dojo').apri(2)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'x' })
  vim.cmd('DattiloEsci')
  local mod = vim.tbl_filter(function(b)
    local nome = vim.api.nvim_buf_get_name(b)
    return (nome:find('hello%.c$') or nome:find('dojo%.c$')) and vim.bo[b].modified
  end, vim.api.nvim_list_bufs())
  uguale(#mod, 0)
end
T['undo non torna all\'esercizio precedente'] = function()
  avvia_app()
  local dojo = require('dattilo.dojo')
  dojo.apri(3)
  vim.api.nvim_feedkeys(vim.keycode('f(ci(z<Esc>'), 'xt', false)
  dojo.apri(4)
  vim.api.nvim_feedkeys('uu', 'xt', false)
  uguale(vim.api.nvim_buf_get_lines(0, 0, -1, false), dojo.ESERCIZI[4].partenza)
  vim.cmd('DattiloEsci')
end
local function in_batti(righe, riga, col)
  avvia_app()
  local lezione = require('dattilo.lezione')
  lezione.apri('corso-c-antirez', 1)
  lezione.batti(lezione.s)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, righe)
  vim.api.nvim_win_set_cursor(0, { riga, col })
  return lezione
end
local QUASI = { '#include <stdio.h>', '', 'int main(void) {', '    printf("Hello World', '    ' }

T['frecce in INSERT: spiega Esc, hjkl e i'] = function()
  local lezione = in_batti({ '#incl' }, 1, 5)
  lezione.s.frecce = true
  local titolo, testo = lezione.tip_batti(lezione.s, 'i')
  uguale(titolo, 'FRECCE')
  vero(testo:find('INSERT', 1, true) and testo:find('‹Esc›', 1, true) and testo:find('‹i›', 1, true), testo)
  lezione.chiudi()
end
T['frecce in NORMAL: hjkl'] = function()
  local lezione = in_batti({ '#incl' }, 1, 0)
  lezione.s.frecce = true
  local titolo, testo = lezione.tip_batti(lezione.s, 'n')
  uguale(titolo, 'FRECCE')
  vero(testo:find('‹h› ‹j› ‹k› ‹l›', 1, true) and not testo:find('INSERT', 1, true), testo)
  lezione.chiudi()
end
T['riga lasciata a metà: dice come tornarci'] = function()
  local lezione = in_batti(QUASI, 5, 4)
  local titolo, testo = lezione.tip_batti(lezione.s, 'i')
  uguale(titolo, 'RIGA 4')
  vero(testo:find('‹Backspace›', 1, true) and testo:find('‹A›', 1, true), testo)
  local t2, testo2 = lezione.tip_batti(lezione.s, 'n')
  uguale(t2, 'RIGA 4')
  vero(testo2:find('‹k›', 1, true) and testo2:find('‹A›', 1, true), testo2)
  lezione.chiudi()
end
local function con_js_prova()
  avvia_app()
  local dest = vim.env.XDG_DATA_HOME .. '/dattilo/pacchetti/js-prova'
  vim.fn.mkdir(dest .. '/lezioni', 'p')
  for _, f in ipairs({ 'pacchetto.json', 'lezioni/01-somma.md' }) do
    vim.uv.fs_copyfile(RADICE .. '/tests/fixture/js-prova/' .. f, dest .. '/' .. f)
  end
  require('dattilo.pacchetti').dimentica()
end
T['lezione JS senza video e senza Rompi: dal briefing alla spiegazione'] = function()
  con_js_prova()
  local lezione = require('dattilo.lezione')
  lezione.apri('js-prova', 1)
  local testo = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  vero(not testo:find('youtu', 1, true) and not testo:find('antirez', 1, true), testo)
  vero(testo:find('esempio', 1, true), 'manca la fonte')
  local s = lezione.s
  lezione.batti(s)
  uguale({ vim.fn.expand('%:t'), vim.bo.filetype }, { 'main.js', 'javascript' })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'const somma = (a, b) => a + b;', 'console.log(somma(2, 3));' })
  vim.cmd('silent write')
  vero(vim.wait(3000, function() return s.passo == 'modifica' end), 'non passa a modifica: ' .. s.passo)
  vim.api.nvim_feedkeys(vim.keycode('jf2r4f3r5'), 'xt', false)
  vim.api.nvim_exec_autocmds('TextChanged', { buffer = s.buf })
  vero(vim.wait(3000, function() return s.passo == 'esegui' end), 'non passa a esegui: ' .. s.passo)
  vim.cmd('silent write')
  vero(vim.wait(3000, function() return s.passo == 'spiegazione' end), 'non passa a spiegazione: ' .. s.passo)
  local sp = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  vero(sp:find('somma(4, 5)', 1, true), sp)
  lezione.chiudi()
end
T['elenco lezioni del corso C: 2 vere e 36 in arrivo'] = function()
  avvia_app()
  require('dattilo.home').lezioni('corso-c-antirez')
  local righe = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local voci = vim.tbl_filter(function(l) return vim.tbl_contains({ '✓', '▸', '·' }, vim.fn.strcharpart(l, 3, 1)) end, righe)
  uguale(#voci, 38)
end
T['schermata pacchetti: corso C e pacchetto utente'] = function()
  con_js_prova()
  require('dattilo.home').pacchetti()
  local testo = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  vero(testo:find('Impariamo il C', 1, true) and testo:find('JS di prova', 1, true), testo)
end
return T
