local compila = require('dattilo.compila')
local esercizio = require('dattilo.esercizio')
local T = {}

local function compila_righe(righe, file)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile(righe, dir .. '/' .. file)
  return compila.esegui(dir, file)
end

local function lezione(n) return require('dattilo.lezioni.' .. string.format('%02d', n)) end

T['indice: 38 puntate, le prime due giocabili'] = function()
  local indice = require('dattilo.lezioni.indice')
  uguale(#indice, 38)
  uguale({ indice[1].file, indice[2].file, indice[3].file }, { '01', '02', nil })
  uguale(indice[1].video, 'HjXBXBgfKyk')
end

for _, n in ipairs({ 1, 2 }) do
  T['lezione ' .. n .. ': il codice da battere compila e stampa'] = function()
    local L = lezione(n)
    local r = compila_righe(L.batti.codice, L.file)
    uguale({ r.ok, r.warning, r.uscita }, { true, false, L.esegui.atteso })
  end
  T['lezione ' .. n .. ': le modifiche si fanno in par tasti'] = function()
    local L = lezione(n)
    for _, m in ipairs(L.modifiche) do
      local buf = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, m.partenza or L.batti.codice)
      vim.api.nvim_win_set_cursor(0, { m.pos[1] + 1, m.pos[2] })
      vim.api.nvim_feedkeys(vim.keycode(m.soluzione), 'xt', false)
      uguale(vim.api.nvim_buf_get_lines(buf, 0, -1, false), m.obiettivo, m.consegna)
      uguale(esercizio.conta_tasti(m.soluzione), m.par)
    end
  end
  T['lezione ' .. n .. ': la versione riparata compila senza warning'] = function()
    local L = lezione(n)
    uguale(L.rompi.ripara, L.modifiche[#L.modifiche].obiettivo)
    local r = compila_righe(L.rompi.ripara, L.file)
    uguale({ r.ok, r.warning, r.uscita }, { true, false, L.rompi.atteso })
  end
  T['lezione ' .. n .. ': rompilo dà il problema atteso'] = function()
    local L = lezione(n)
    uguale(L.rompi.rotto(L.rompi.ripara), false)
    local rotte = L.rompi.esempio(vim.deepcopy(L.rompi.ripara))
    uguale(L.rompi.rotto(rotte), true)
    local r = compila_righe(rotte, L.file)
    if L.rompi.attesa == 'errore' then uguale(r.compilato, false) else uguale({ r.compilato, r.warning }, { true, true }) end
  end
  T['lezione ' .. n .. ': note della spiegazione su righe esistenti'] = function()
    local L = lezione(n)
    for riga in pairs(L.spiegazione.note) do vero(L.rompi.ripara[riga] ~= nil, 'riga ' .. riga) end
    vero(#L.spiegazione.momenti >= 2)
  end
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
  require('dattilo.lezione').apri(1)
  uguale(require('dattilo.stato').schermo, 'lezione')
  vim.cmd('DattiloEsci')
  uguale(require('dattilo.stato').schermo, 'home')
end
T['la lezione passa dal briefing a Batti senza errori'] = function()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo').avvia({ radice = RADICE })
  local lezione = require('dattilo.lezione')
  lezione.apri(1)
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
  lezione.apri(1)
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
  lezione.apri(1)
  lezione.batti(lezione.s)
  vero(vim.fn.maparg('ZZ', 'n') ~= '', 'manca ZZ')
end
T[':q! non dà E477'] = function()
  avvia_app()
  require('dattilo.lezione').apri(1)
  vim.cmd('DattiloEsci!')
  uguale(require('dattilo.stato').schermo, 'home')
  vim.cmd('DattiloRicomincia!')
end
T['lasciare una lezione a metà non lascia buffer modificati'] = function()
  avvia_app()
  local lezione = require('dattilo.lezione')
  lezione.apri(1)
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
  lezione.apri(1)
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
return T
