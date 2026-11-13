-- Lezione 1 del corso di antirez: "Introduzione al C e primo Hello World".
local HELLO = { '#include <stdio.h>', '', 'int main(void) {', '    printf("Hello World\\n");', '    return 0;', '}' }
local CIAO = vim.tbl_map(function(l) return (l:gsub('Hello World', 'Ciao mondo')) end, HELLO)

return {
  id = '01-hello', numero = 1, etichetta = 'L1',
  titolo = 'Introduzione al C e primo Hello World',
  breve = 'Hello World',
  video = { id = 'HjXBXBgfKyk', durata = '22:00', da = '05:26' },
  briefing = 'Nel video antirez scrive Hello World, lo compila con cc, guarda l\'assembly con -S e scopre che con -O2 il compilatore cambia printf in puts.',
  passi = {
    { 'Batti il programma', 'il codice è in grigio, lo copri scrivendo' },
    { 'Cambialo', 'Hello World diventa Ciao mondo' },
    { 'Rompilo', 'togli l\'#include e leggi l\'errore di gcc' },
    { 'Capisci', 'riga per riga, con i minuti del video' },
  },
  mosse = { 'i', 'Esc', ':w', '3j', 'ci"', 'gg', 'dd', 'u' },
  concetti = { '#include', 'main', 'printf', '\\n', 'return 0', 'cc -Wall' },
  tempo = 'circa 4 minuti',
  file = 'hello.c',
  batti = {
    codice = HELLO,
    suggerimenti = {
      [1] = 'Scrivi quello che vedi in grigio. Dopo ‹Invio› il rientro lo mette dattilo: non battere gli spazi iniziali.',
      [3] = 'main è la funzione da cui parte ogni programma C. Le graffe aprono e chiudono il suo corpo.',
      [4] = 'printf stampa. \\n vuol dire "vai a capo": printf non lo aggiunge da sola.',
      [5] = 'Il ; chiude ogni istruzione. return 0 dice al sistema che è andato tutto bene.',
    },
  },
  esegui = { atteso = 'Hello World\n' },
  modifiche = {
    { titolo = 'Modifica 1/2', consegna = 'Fallo parlare italiano: Hello World diventa Ciao mondo.',
      aiuto = '‹3j› scende di tre righe, ‹ci"› cancella dentro le virgolette e ti mette in INSERT.',
      pos = { 0, 0 }, obiettivo = CIAO, par = 18, soluzione = '3jci"Ciao mondo\\n<Esc>', mostra = { '3j', 'ci"', 'Ciao mondo\\n', 'Esc' } },
  },
  rompi = {
    titolo = 'Modifica 2/2',
    consegna = 'Ora rompilo apposta: ‹gg› va in cima, ‹dd› cancella la riga dell\'#include. Poi ‹:w› e leggi cosa dice gcc.',
    rotto = function(righe)
      for _, l in ipairs(righe) do if l:find('#include', 1, true) then return false end end
      return true
    end,
    esempio = function(righe) table.remove(righe, 1) return righe end,
    attesa = 'errore',
    dopo = 'Senza stdio.h il compilatore non sa chi è printf, e dal GCC 14 è un errore. ‹u› annulla la cancellazione, poi ‹:w›.',
    ripara = CIAO,
    atteso = 'Ciao mondo\n',
  },
  spiegazione = {
    note = {
      [1] = { 'Il preprocessore incolla qui le dichiarazioni', 'di stdio.h, tra cui quella di printf.' },
      [3] = { 'Il programma parte da main.', 'void: niente argomenti.' },
      [4] = { 'printf è della libreria standard, non del C.', '\\n va a capo: printf non lo aggiunge, puts sì.' },
      [5] = { 'Zero al sistema vuol dire tutto bene.', 'Provalo con: ./hello; echo $?' },
    },
    momenti = {
      { '05:26', 'scrive il primo Hello World' },
      { '08:34', 'cc -S hello.c mostra l\'assembly: dentro c\'è la chiamata a printf' },
      { '10:40', 'con -O2 il compilatore sostituisce printf con puts e toglie il \\n' },
      { '11:43', 'man 3 printf, perché man printf apre il comando della shell' },
    },
    trappola = 'senza #include il compilatore rifiuta printf. L\'hai appena visto.',
    prova = 'cc -O2 -S hello.c e cerca puts nel file hello.s',
  },
  prossima = 2,
}
