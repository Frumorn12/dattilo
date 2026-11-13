local formato = require('dattilo.formato')
local T = {}
local function leggi(p) return table.concat(vim.fn.readfile(p), '\n') end
local COMPLETA = leggi(RADICE .. '/tests/fixture/lezione-completa.md')

T['lezione completa: front matter'] = function()
  local L, err = formato.lezione(COMPLETA, '01-hello.md', 1)
  uguale(err, {})
  uguale({ L.id, L.numero, L.etichetta, L.titolo, L.breve, L.file, L.tempo, L.fonte },
    { '01-hello', 1, 'L1', 'Introduzione al C e primo Hello World', 'Hello World', 'hello.c', 'circa 4 minuti', 'hello.c' })
  uguale(L.mosse, { 'i', 'Esc', ':w', 'ci"', 'gg' })
  uguale(L.concetti, { 'main', 'printf', 'return 0' })
  uguale(L.video, { id = 'HjXBXBgfKyk', durata = '22:00', da = '05:26' })
end
T['lezione completa: briefing, passi, batti, uscita'] = function()
  local L = formato.lezione(COMPLETA, '01-hello.md', 1)
  uguale(L.briefing, 'antirez scrive Hello World e lo compila con cc.')
  uguale(L.passi, { { 'Batti il programma', 'il codice è in grigio' }, { 'Cambialo', 'Hello World diventa Ciao mondo' } })
  uguale(L.batti.codice, { '#include <stdio.h>', '', 'int main(void) {', '    printf("Hello World\\n");', '    return 0;', '}' })
  uguale(L.batti.suggerimenti, { [4] = 'printf stampa.', [5] = 'return 0 vuol dire tutto bene.' })
  uguale(L.esegui.atteso, 'Hello World\n')
end
T['lezione completa: modifiche a catena'] = function()
  local L = formato.lezione(COMPLETA, '01-hello.md', 1)
  local m1, m2 = L.modifiche[1], L.modifiche[2]
  uguale({ m1.titolo, m1.consegna, m1.par, m1.soluzione, m1.pos }, { 'Modifica 1/2', 'Fallo parlare italiano.', 18, '3jci"Ciao mondo\\n<Esc>', { 0, 0 } })
  uguale(m1.mostra, { '3j', 'ci"', 'Ciao mondo\\n', 'Esc' })
  uguale(m1.partenza, L.batti.codice)
  uguale(m2.titolo, 'Modifica 2/2')
  uguale(m2.partenza, m1.obiettivo)
  uguale(m2.pos, { 4, 11 })
  uguale(m2.obiettivo[5], '    return 1;')
end
T['lezione completa: rompi e spiegazione'] = function()
  local L = formato.lezione(COMPLETA, '01-hello.md', 1)
  uguale({ L.rompi.titolo, L.rompi.attesa, L.rompi.cerca }, { 'Rompilo', 'errore', 'implicit declaration' })
  uguale(L.rompi.ripara, L.modifiche[2].obiettivo)
  uguale(L.rompi.esempio[1], '')
  uguale(L.spiegazione.note[1], { 'Il preprocessore', 'incolla stdio.h' })
  uguale(L.spiegazione.note[3], { 'Il programma parte da main.' })
  uguale(L.spiegazione.momenti, { { '05:26', 'scrive il primo Hello World' }, { '10:40', 'con -O2 printf diventa puts' } })
  uguale({ L.spiegazione.trappola, L.spiegazione.prova }, { 'Senza include niente printf.', 'cc -O2 -S hello.c' })
end
T['lezione minima: niente video, niente rompi, passi generati'] = function()
  local L, err = formato.lezione('---\ntitolo: Variabili\nfile: main.js\n---\n## Batti\n```js\nlet x = 1;\n```\n## Modifica\nconsegna: Diventa const.\naiuto: ‹ciw›\npar: 9\nsoluzione: ciwconst<Esc>\nmostra: ciw · const · Esc\n```js\nconst x = 1;\n```\n', '03-variabili.md', 3)
  uguale(err, {})
  uguale({ L.video, L.rompi, L.esegui.atteso, L.etichetta, L.breve }, { nil, nil, nil, '03', 'Variabili' })
  uguale(#L.passi, 3)
  uguale(L.passi[1][1], 'Batti il codice')
  uguale(L.passi[2][1], 'Modifica 1/1')
  uguale(L.passi[3][1], 'Capisci')
  uguale(L.rompi, nil)
end
T['lezione senza Batti: errore con riga'] = function()
  local L, err = formato.lezione('---\ntitolo: X\nfile: a.js\n---\n## Briefing\nciao\n', 'x.md', 1)
  uguale(L, nil)
  vero(#err >= 1 and err[1].file == 'x.md' and err[1].msg:find('Batti', 1, true), vim.inspect(err))
end
T['par non numerico: errore sulla sua riga'] = function()
  local _, err = formato.lezione('---\ntitolo: X\nfile: a.js\n---\n## Batti\n```js\nx\n```\n## Modifica\npar: dieci\nsoluzione: x\n```js\ny\n```\n', 'x.md', 1)
  local e = vim.tbl_filter(function(e) return e.msg:find('par', 1, true) end, err)[1]
  vero(e ~= nil, vim.inspect(err))
  uguale(e.riga, 10)
end
T['un blocco ``` dentro un blocco ```` resta testo'] = function()
  local L = formato.lezione('---\ntitolo: X\nfile: a.md\n---\n## Batti\n````md\n```js\nx\n```\n````\n', 'x.md', 1)
  uguale(L.batti.codice, { '```js', 'x', '```' })
end
T['manifesto valido'] = function()
  local m, err = formato.manifesto('{"id":"javascript","titolo":"JS","versione":"0.1.0","autore":"Andrea","linguaggio":"javascript","richiede":[],"esecuzione":{"tipo":"comando","comando":["node","{file}"]}}', 'pacchetto.json')
  uguale(err, {})
  uguale({ m.id, m.esecuzione.tipo, m.in_arrivo, m.richiede }, { 'javascript', 'comando', {}, {} })
end
T['manifesto senza id, con id brutto o tipo sconosciuto'] = function()
  local _, e1 = formato.manifesto('{"titolo":"x","versione":"1","esecuzione":{"tipo":"comando","comando":["node"]}}', 'p.json')
  local _, e2 = formato.manifesto('{"id":"Bad Id","titolo":"x","versione":"1","esecuzione":{"tipo":"comando","comando":["node"]}}', 'p.json')
  local _, e3 = formato.manifesto('{"id":"ok","titolo":"x","versione":"1","esecuzione":{"tipo":"magia"}}', 'p.json')
  local _, e4 = formato.manifesto('{rotto', 'p.json')
  vero(#e1 > 0 and #e2 > 0 and #e3 > 0 and #e4 > 0)
end
return T
