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
return T
