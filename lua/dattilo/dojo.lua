-- Dojo Vim: esercizi brevi di trasformazione sul C, con il par.
local M = {}

local SUM = { 'int sum(int a, int b) {', '    int c = a + b;', '    return c;', '}' }
local function con(righe, i, nuova) local t = vim.deepcopy(righe) t[i] = nuova return t end

M.ESERCIZI = {
  { titolo = 'Muoviti senza frecce', consegna = 'Porta il cursore sul + della seconda riga.', aiuto = '‹j› scende di una riga, ‹f+› salta al prossimo +.',
    partenza = SUM, pos = { 0, 0 }, cursore_obiettivo = { 1, 14 }, par = 3, soluzione = 'jf+', mostra = { 'j', 'f+' } },
  { titolo = 'Cambia una parola', consegna = 'Rinomina la funzione: sum diventa somma.', aiuto = '‹w› va alla parola dopo, ‹ciw› la cancella e ti mette in INSERT.',
    partenza = SUM, pos = { 0, 0 }, obiettivo = con(SUM, 1, 'int somma(int a, int b) {'), par = 10, soluzione = 'wciwsomma<Esc>', mostra = { 'w', 'ciw', 'somma', 'Esc' } },
  { titolo = 'Dentro le parentesi', consegna = 'Gli argomenti diventano (int x, int y).', aiuto = '‹f(› salta alla parentesi, ‹ci(› cambia tutto quello che c\'è dentro.',
    partenza = SUM, pos = { 0, 0 }, obiettivo = con(SUM, 1, 'int sum(int x, int y) {'), par = 18, soluzione = 'f(ci(int x, int y<Esc>', mostra = { 'f(', 'ci(', 'int x, int y', 'Esc' } },
  { titolo = 'Ripeti con il punto', consegna = 'Metti il ; mancante alla fine delle tre righe.', aiuto = '‹A› scrive a fine riga. Poi ‹j› scende e ‹.› ripete l\'ultima modifica.',
    partenza = { 'int a = 10', 'int b = 20', 'int c = a + b' }, pos = { 0, 0 }, obiettivo = { 'int a = 10;', 'int b = 20;', 'int c = a + b;' },
    par = 7, soluzione = 'A;<Esc>j.j.', mostra = { 'A', ';', 'Esc', 'j', '.', 'j', '.' } },
  { titolo = 'Scambia due righe', consegna = 'stdio.h deve venire prima di stdlib.h.', aiuto = '‹dd› taglia la riga, ‹p› la incolla sotto quella dove finisci.',
    partenza = { '#include <stdlib.h>', '#include <stdio.h>' }, pos = { 0, 0 }, obiettivo = { '#include <stdio.h>', '#include <stdlib.h>' },
    par = 3, soluzione = 'ddp', mostra = { 'dd', 'p' } },
  { titolo = 'Taglia la coda', consegna = 'Togli il commento alla fine del return.', aiuto = '‹f;› salta al punto e virgola, ‹l› uno a destra, ‹D› cancella fino a fine riga.',
    partenza = con(SUM, 3, '    return c; // la somma'), pos = { 2, 0 }, obiettivo = SUM, par = 4, soluzione = 'f;lD', mostra = { 'f;', 'l', 'D' } },
  { titolo = 'Duplica e cambia', consegna = 'Aggiungi sotto una seconda printf che stampa Bau.', aiuto = '‹yy› copia la riga, ‹p› la incolla sotto, ‹ci"› cambia il testo tra virgolette.',
    partenza = { 'int main(void) {', '    printf("Ciao\\n");', '    return 0;', '}' }, pos = { 0, 0 },
    obiettivo = { 'int main(void) {', '    printf("Ciao\\n");', '    printf("Bau\\n");', '    return 0;', '}' },
    par = 13, soluzione = 'jyypci"Bau\\n<Esc>', mostra = { 'j', 'yy', 'p', 'ci"', 'Bau\\n', 'Esc' } },
}

return M
