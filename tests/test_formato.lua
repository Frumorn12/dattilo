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
  local L = formato.lezione('---\ntitolo: X\nfile: a.js\n---\n## Batti\n````md\n```js\nx\n```\n````\n', 'x.md', 1)
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
local function con_blocchi(blocchi, sugg)
  return table.concat({ '---', 'titolo: t', 'file: main.js', '---', '## Batti', '```js', 'const a = 1;', 'const b = 2;', '',
    'console.log(a + b);', '```', '', '### Blocchi', blocchi, '', '### Suggerimenti', sugg or '1: a vale uno.',
    '', '## Modifica', 'consegna: c', 'aiuto: x', 'motivo: Perché sì.', 'par: 1', 'soluzione: x', '```js', 'onst a = 1;', 'const b = 2;', '',
    'console.log(a + b);', '```' }, '\n')
end
T['blocchi: titolo, cosa e quadro'] = function()
  local L, err = formato.lezione(con_blocchi('1-2: Dati | Due numeri. | Si parte dai dati.\n4-4: Stampa | La somma.'), '01-x.md', 1)
  uguale(err, {})
  uguale(L.batti.blocchi, { { da = 1, a = 2, titolo = 'Dati', cosa = 'Due numeri.', quadro = 'Si parte dai dati.' },
    { da = 4, a = 4, titolo = 'Stampa', cosa = 'La somma.' } })
  uguale(L.modifiche[1].motivo, 'Perché sì.')
end
T['blocchi: una riga sola con N:'] = function()
  local L = formato.lezione(con_blocchi('1-2: Dati | x\n4: Stampa | y'), '01-x.md', 1)
  uguale(L.batti.blocchi[2].da, 4)
  uguale(L.batti.blocchi[2].a, 4)
end
T['blocchi non validi: rovesciato, fuori, sovrapposto, senza titolo'] = function()
  for _, b in ipairs({ '2-1: X | y', '1-9: X | y', '1-2: X | y\n2-4: Z | w', '1-2:  | y', 'boh' }) do
    local L, err = formato.lezione(con_blocchi(b), '01-x.md', 1)
    vero(L == nil and #err > 0, b)
  end
end
T['suggerimenti fuori dal codice o su una riga vuota'] = function()
  local _, e1 = formato.lezione(con_blocchi('1-2: X | y', '3: vuota'), '01-x.md', 1)
  vero(e1[1].msg:find('vuota'), vim.inspect(e1))
  local _, e2 = formato.lezione(con_blocchi('1-2: X | y', '9: oltre'), '01-x.md', 1)
  vero(e2[1].msg:find('fuori dal codice'), vim.inspect(e2))
end
T['completezza: righe senza suggerimento, fuori dai blocchi, modifica senza motivo'] = function()
  local controlla = require('dattilo.controlla')
  local L = formato.lezione(con_blocchi('1-2: Dati | x'), '01-x.md', 1)
  local c = controlla.completezza(L)
  uguale(c, { 'righe senza suggerimento: 2, 4', 'righe fuori dai blocchi: 4' })
  L.modifiche[1].motivo = nil
  L.batti.blocchi = {}
  c = controlla.completezza(L)
  vero(vim.tbl_contains(c, 'nessun blocco: aggiungi ### Blocchi in Batti') and vim.tbl_contains(c, 'modifica 1 senza motivo'), vim.inspect(c))
end
T['tip: ogni riga con blocco e suggerimento'] = function()
  local L = formato.lezione(con_blocchi('1-2: Dati | x | q'), '01-x.md', 1)
  local t = require('dattilo.controlla').tip(L)
  uguale(t[2], '== 1-2 Dati | x | q')
  uguale(t[3], '  1  const a = 1;')
  uguale(t[4], '       ↳ a vale uno.')
end
T['manifesto: percorso facoltativo'] = function()
  local m = formato.manifesto('{"id":"ok","titolo":"x","versione":"1","percorso":"Percorso X","esecuzione":{"tipo":"comando","comando":["node","{file}"]}}', 'p.json')
  uguale(m.percorso, 'Percorso X')
end
T['riempi: le soluzioni scrivono i blocchi obiettivo e il par'] = function()
  local testo = table.concat({ '---', 'titolo: t', 'file: main.js', '---', '## Batti', '```js', 'const a = 1;', 'console.log(a);', '```',
    '', '## Modifica: Uno', 'consegna: c', 'par: 0', 'soluzione: f1r2', '```js', '```',
    '', '## Modifica: Due', 'consegna: c', 'par: 0', 'soluzione: jdd', '```js', 'vecchio', 'testo', '```', '', '## Spiegazione', '1: x' }, '\n')
  local nuovo, r = require('dattilo.controlla').riempi(testo, '01-x.md')
  vero(nuovo, vim.inspect(r))
  local L = formato.lezione(nuovo, '01-x.md', 1)
  uguale(L.modifiche[1].obiettivo, { 'const a = 2;', 'console.log(a);' })
  uguale(L.modifiche[1].par, 4)
  uguale(L.modifiche[2].obiettivo, { 'const a = 2;' })
  uguale(L.modifiche[2].par, 3)
  vero(r[1]:find('cambiate: 1', 1, true), r[1])
  vero(nuovo:find('## Spiegazione\n1: x', 1, true))
end
return T
