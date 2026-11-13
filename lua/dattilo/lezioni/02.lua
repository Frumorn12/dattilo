-- Lezione 2 del corso di antirez: "main, funzioni, variabili locali e valore di ritorno".
local SUM = {
  '#include <stdio.h>',
  '',
  'int sum(int a, int b) {',
  '    int c = a + b;',
  '    return c;',
  '}',
  '',
  'int main(void) {',
  '    printf("Hello World %d\\n", sum(10, 20));',
  '    return 0;',
  '}',
}
local SUM57 = vim.deepcopy(SUM)
SUM57[9] = '    printf("Hello World %d\\n", sum(5, 7));'

return {
  id = '02-sum', numero = 2, etichetta = 'L2',
  titolo = 'main, funzioni, variabili locali e valore di ritorno',
  breve = 'funzioni e printf',
  video = { id = 'Z84vlG1RRtg', durata = '20:40', da = '03:09' },
  briefing = 'antirez scrive la sua prima funzione, sum, la chiama dentro printf con %d e mostra cosa succede quando gli argomenti di printf non tornano. Poi spiega il valore di ritorno di main.',
  passi = {
    { 'Batti il programma', 'una funzione sum e una printf con %d' },
    { 'Cambialo', 'fagli sommare 5 e 7' },
    { 'Rompilo', 'due %d e un solo numero: il warning di gcc' },
    { 'Capisci', 'variabili locali, tipi, return' },
  },
  mosse = { '9G', 'f1', 'ci(', 'f\\', 'i', 'u' },
  concetti = { 'funzioni', 'parametri tipizzati', 'variabili locali', 'printf e %d', 'warning', 'return di main' },
  tempo = 'circa 5 minuti',
  file = 'sum.c',
  batti = {
    codice = SUM,
    suggerimenti = {
      [3] = 'Una funzione: tipo di ritorno, nome, parametri con il loro tipo. In C il tipo si scrive sempre.',
      [4] = 'c è una variabile locale: nasce quando sum viene chiamata e sparisce al return.',
      [9] = '%d dentro la stringa viene sostituito dal numero che passi dopo la virgola.',
      [10] = 'Il valore di ritorno di main arriva alla shell: ./sum; echo $?',
    },
  },
  esegui = { atteso = 'Hello World 30\n' },
  modifiche = {
    { titolo = 'Modifica 1/2', consegna = 'Fagli sommare 5 e 7.',
      aiuto = '‹9G› va alla riga 9, ‹f1› salta sul 10, ‹ci(› cambia gli argomenti di sum.',
      pos = { 0, 0 }, obiettivo = SUM57, par = 12, soluzione = '9Gf1ci(5, 7<Esc>', mostra = { '9G', 'f1', 'ci(', '5, 7', 'Esc' } },
  },
  rompi = {
    titolo = 'Modifica 2/2',
    consegna = 'Rompilo come fa antirez: due %d e un solo numero. ‹f\\› salta sul \\n della riga 9, ‹i› e scrivi uno spazio e %d, poi ‹Esc› e ‹:w›.',
    rotto = function(righe)
      for _, l in ipairs(righe) do if l:find('%d %d', 1, true) then return true end end
      return false
    end,
    esempio = function(righe) righe[9] = righe[9]:gsub('%%d\\n', '%%d %%d\\n') return righe end,
    attesa = 'warning',
    dopo = 'gcc compila ma ti avvisa: c\'è un %d senza numero, e printf stampa quello che trova in memoria. ‹u› annulla, poi ‹:w›.',
    ripara = SUM57,
    atteso = 'Hello World 12\n',
  },
  spiegazione = {
    note = {
      [3] = { 'Tipo di ritorno, nome, parametri tipizzati.', 'Niente inferenza: il tipo lo scrivi tu.' },
      [4] = { 'c è locale: vive solo durante la chiamata.' },
      [5] = { 'return consegna il valore a chi ha chiamato.' },
      [9] = { 'printf è variadica: %d legge il prossimo argomento.', 'Se manca, legge spazzatura (lo hai visto).' },
      [10] = { 'Il valore di main va alla shell: echo $?', 'Con ./sum && ls, ls parte solo se main ritorna 0.' },
    },
    momenti = {
      { '01:01', 'int main(void): tipo di ritorno e nessun argomento' },
      { '02:05', 'warning ed errori: cosa cambia con -Wall' },
      { '03:09', 'scrive int sum(int a, int b)' },
      { '05:20', 'printf è variadica e usa %d' },
      { '17:06', 'il valore di ritorno di main, $? e lo short circuit con &&' },
    },
    trappola = 'due %d e un solo argomento: compila, ma l\'output è indefinito.',
    prova = 'cambia return 0 in return 1, poi ./sum; echo $?',
  },
  prossima = 3,
}
