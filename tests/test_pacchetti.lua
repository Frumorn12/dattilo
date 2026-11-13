local T = {}

local function xdg_nuovo()
  vim.env.XDG_DATA_HOME = vim.fn.tempname()
  require('dattilo.pacchetti').dimentica()
  return vim.env.XDG_DATA_HOME
end
local function scrivi(percorso, testo)
  vim.fn.mkdir(vim.fn.fnamemodify(percorso, ':h'), 'p')
  vim.fn.writefile(vim.split(testo, '\n', { plain = true }), percorso)
end

T['il corso C passa il verificatore'] = function()
  local r = require('dattilo.controlla').pacchetto(RADICE .. '/pacchetti/corso-c-antirez')
  local errori = vim.tbl_filter(function(x) return x.stato == 'errore' end, r.righe)
  uguale(errori, {})
  uguale(r.ok, true)
  vero(#r.righe >= 6, 'troppe poche verifiche: ' .. #r.righe)
end
T['il corso C si carica dal pacchetto'] = function()
  xdg_nuovo()
  local P = require('dattilo.pacchetti').carica('corso-c-antirez')
  uguale({ #P.lezioni, #P.in_arrivo }, { 2, 36 })
  uguale(P.lezioni[1].video.id, 'HjXBXBgfKyk')
  vero(P.lezioni[1].batti.suggerimenti[4] ~= nil)
  uguale({ P.lezioni[1].pacchetto, P.lezioni[1].prossima, P.lezioni[2].prossima }, { 'corso-c-antirez', 2, nil })
  uguale(P.lezioni[1].esecuzione.tipo, 'compila')
  uguale(require('dattilo.pacchetti').lezione('corso-c-antirez', 2).id, '02-sum')
end
T['pacchetto utente: le lezioni rotte non bloccano le altre'] = function()
  local xdg = xdg_nuovo()
  local dir = xdg .. '/dattilo/pacchetti/prova'
  scrivi(dir .. '/pacchetto.json', '{"id":"prova","titolo":"Prova","versione":"0.1.0","linguaggio":"javascript","esecuzione":{"tipo":"comando","comando":["node","{file}"]}}')
  scrivi(dir .. '/lezioni/01-buona.md', '---\ntitolo: Buona\nfile: main.js\n---\n## Batti\n```js\nconsole.log(1)\n```\n')
  scrivi(dir .. '/lezioni/02-rotta.md', '---\ntitolo: Rotta\nfile: main.js\n---\n## Briefing\nniente\n')
  local pacchetti = require('dattilo.pacchetti')
  local P = pacchetti.carica('prova')
  uguale(#P.lezioni, 1)
  uguale(#P.errori, 1)
  uguale(P.errori[1].file, '02-rotta.md')
  vero(P.errori[1].riga ~= nil)
  local voce = vim.tbl_filter(function(x) return x.id == 'prova' end, pacchetti.elenco())[1]
  uguale({ voce.lezioni, #voce.errori }, { 1, 1 })
  uguale(pacchetti.elenco()[1].id, 'corso-c-antirez')
end
T['pacchetto con manifesto rotto: nell\'elenco con errore, non carica'] = function()
  local xdg = xdg_nuovo()
  scrivi(xdg .. '/dattilo/pacchetti/rotto/pacchetto.json', '{rotto')
  local pacchetti = require('dattilo.pacchetti')
  local ok, el = pcall(pacchetti.elenco)
  vero(ok, tostring(el))
  local voce = vim.tbl_filter(function(x) return x.cartella:find('rotto', 1, true) end, el)[1]
  vero(voce and #voce.errori > 0)
end
T['progressi: le chiavi vecchie del corso C migrano una volta'] = function()
  local xdg = xdg_nuovo()
  scrivi(xdg .. '/dattilo/progressi.json', '{"lezioni":{"01-hello":{"volte":1,"migliore_wpm":40}},"sessioni":[{"id":"01-hello","wpm":40}]}')
  local p = require('dattilo.progressi').carica()
  uguale(p.lezioni['01-hello'], nil)
  uguale(p.lezioni['corso-c-antirez/01-hello'].migliore_wpm, 40)
  uguale(p.sessioni[1].id, 'corso-c-antirez/01-hello')
  local salvato = vim.json.decode(table.concat(vim.fn.readfile(xdg .. '/dattilo/progressi.json'), '\n'))
  vero(salvato.lezioni['corso-c-antirez/01-hello'] ~= nil)
end
T['il verificatore usa le opzioni della lezione (niente rientro automatico)'] = function()
  local r = require('dattilo.controlla').pacchetto(RADICE .. '/tests/fixture/rientro')
  local errori = vim.tbl_filter(function(x) return x.stato == 'errore' end, r.righe)
  uguale(errori, {})
end
return T
