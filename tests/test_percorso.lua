local T = {}
local LEZIONE = table.concat(vim.fn.readfile(RADICE .. '/tests/fixture/js-prova/lezioni/01-somma.md'), '\n')

local function pacchetto(xdg, id, titolo, richiede, n, extra)
  local dir = xdg .. '/dattilo/pacchetti/' .. id
  vim.fn.mkdir(dir .. '/lezioni', 'p')
  local m = { id = id, titolo = titolo, versione = '1.0.0', linguaggio = 'javascript', richiede = richiede,
    esecuzione = { tipo = 'comando', comando = { 'node', '{file}' } } }
  for k, v in pairs(extra or {}) do m[k] = v end
  vim.fn.writefile({ vim.json.encode(m) }, dir .. '/pacchetto.json')
  for i = 1, n do vim.fn.writefile(vim.split(LEZIONE, '\n'), string.format('%s/lezioni/%02d-l.md', dir, i)) end
end

-- tre pacchetti a catena con i titoli in ordine alfabetico rovesciato: pa ← pb ← pc
local function tre()
  local xdg = vim.fn.tempname()
  vim.env.XDG_DATA_HOME = xdg
  pacchetto(xdg, 'pa', 'Zeta A', {}, 2)
  pacchetto(xdg, 'pb', 'Media B', { 'pa' }, 1)
  pacchetto(xdg, 'pc', 'Alfa C', { 'pb' }, 2, { percorso = 'Percorso di prova' })
  pacchetto(xdg, 'solo', 'Beta solo', {}, 1)
  require('dattilo.pacchetti').dimentica()
  return xdg
end

T['percorso: capitoli nell\'ordine delle dipendenze e titolo dal manifesto'] = function()
  tre()
  local percorsi = require('dattilo.pacchetti').percorsi()
  uguale(#percorsi, 1)
  local p = percorsi[1]
  uguale(p.titolo, 'Percorso di prova')
  uguale(vim.tbl_map(function(c) return c.id end, p.capitoli), { 'pa', 'pb', 'pc' })
  uguale(#p.lezioni, 5)
  uguale({ p.capitoli[2].primo, p.capitoli[2].ultimo }, { 3, 3 })
  uguale({ p.lezioni[4].pacchetto, p.lezioni[4].n, p.lezioni[4].capitolo }, { 'pc', 1, 3 })
end
T['pacchetti: corso C, poi il percorso in ordine, poi gli altri'] = function()
  tre()
  local ids = vim.tbl_map(function(v) return v.id end, require('dattilo.pacchetti').elenco())
  uguale(ids, { 'corso-c-antirez', 'pa', 'pb', 'pc', 'solo' })
end
T['lezioni in fila: la seconda si apre dopo la prima'] = function()
  tre()
  local progressi = require('dattilo.progressi')
  local p = require('dattilo.pacchetti').percorsi()[1]
  vero(progressi.aperta(p, 1))
  vero(not progressi.aperta(p, 2))
  progressi.registra('pa/01-l', { wpm = 30 })
  vero(progressi.aperta(p, 2))
  vero(not progressi.aperta(p, 3))
end
T['una lezione sbloccata resta aperta'] = function()
  tre()
  local progressi = require('dattilo.progressi')
  local p = require('dattilo.pacchetti').percorsi()[1]
  vero(not progressi.aperta(p, 4))
  progressi.sblocca('pc/01-l')
  vero(progressi.aperta(p, 4))
  vero(progressi.carica().sbloccate['pc/01-l'])
end
T['capitolo mancante: le lezioni dopo restano chiuse'] = function()
  local xdg = tre()
  vim.fn.delete(xdg .. '/dattilo/pacchetti/pb', 'rf')
  require('dattilo.pacchetti').dimentica()
  local progressi = require('dattilo.progressi')
  local p = require('dattilo.pacchetti').percorsi()[1]
  -- senza pb non si sa cosa c'è prima: il percorso parte da pb, che manca
  uguale(vim.tbl_map(function(c) return c.id end, p.capitoli), { 'pb', 'pc' })
  uguale(p.capitoli[1].P, nil)
  vero(not progressi.aperta(p, 1))
  vero(not progressi.aperta(p, 2))
end
T['percorso_di e posizione'] = function()
  tre()
  local pacchetti = require('dattilo.pacchetti')
  local p, k = pacchetti.percorso_di('pb')
  uguale({ p.id, k }, { 'pc', 2 })
  uguale(pacchetti.posizione(p, 'pc', '02-l'), 5)
  uguale(pacchetti.percorso_di('solo'), nil)
end
local function app()
  tre()
  require('dattilo').avvia({ radice = RADICE })
end
local function schermata() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') end

T['schermata del percorso: capitoli in ordine, lezioni aperte e chiuse'] = function()
  app()
  require('dattilo.home').percorso('pc')
  local t = schermata()
  vero(t:find('Percorso di prova', 1, true) and t:find('Zeta A → Media B → Alfa C', 1, true), t)
  vero(t:find('Zeta A', 1, true) < t:find('Media B', 1, true) and t:find('Media B', 1, true) < t:find('Alfa C', 1, true), t)
  vero(t:find('🔒', 1, true) and t:find('🔒 dopo Zeta A', 1, true), t)
end
T['Invio su una lezione chiusa non la apre'] = function()
  app()
  require('dattilo.home').percorso('pc')
  vim.api.nvim_feedkeys('j', 'xt', false)
  vim.api.nvim_feedkeys(vim.keycode('<CR>'), 'xt', false)
  uguale(require('dattilo.lezione').s, nil)
  uguale(require('dattilo.stato').schermo, 'percorso')
  vim.api.nvim_feedkeys('k', 'xt', false)
  vim.api.nvim_feedkeys(vim.keycode('<CR>'), 'xt', false)
  vero(require('dattilo.lezione').s ~= nil)
  require('dattilo.lezione').chiudi()
end
T['un pacchetto del percorso si apre nel percorso, sul suo capitolo'] = function()
  app()
  require('dattilo.home').lezioni('pb')
  uguale(require('dattilo.stato').schermo, 'percorso')
  uguale(vim.api.nvim_get_current_line():find('01', 1, true) ~= nil, true)
end
T['home: voce del percorso e prossima lezione'] = function()
  app()
  require('dattilo.home').apri()
  local t = schermata()
  vero(t:find('Percorso di prova', 1, true) and t:find('Zeta A · 01', 1, true), t)
end
T['fine capitolo: la prossima è la prima del capitolo dopo, e si sblocca'] = function()
  app()
  local progressi = require('dattilo.progressi')
  progressi.registra('pa/01-l', { wpm = 30 })
  local lezione = require('dattilo.lezione')
  lezione.apri('pa', 2)
  lezione.fine(lezione.s)
  local t = schermata()
  vero(t:find('Media B · 01', 1, true), t)
  vero(progressi.carica().sbloccate['pb/01-l'])
  vim.api.nvim_feedkeys(vim.keycode('<CR>'), 'xt', false)
  uguale(lezione.s.L.pacchetto, 'pb')
  lezione.chiudi()
end
return T
