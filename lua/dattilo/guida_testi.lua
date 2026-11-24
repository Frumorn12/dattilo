-- Tutte le frasi della guida di «Rifallo tu» (progetto, sezioni 3.3 e 3.4), in un posto solo.
-- Fra ‹ › ci vanno solo i tasti da premere; ogni fila di tasti è seguita da «:» e da cosa fa.
-- %d e %s sono i valori del momento.
local M = {}

M.titoli = {
  briefing = 'COMINCIA · %s',
  batti = 'SCRIVI · %s',
  finito = 'FINITO · %d righe scritte',
  ko = 'IL CONTROLLO NON PASSA',
  modifica = 'RIFAI LA MODIFICA DI CLAUDE',
  spiegazione = 'CAPISCI · %s',
  fatto = 'FATTO · %s',
  elenco = 'LE LEZIONI DI RIFALLO TU',
  attesa = 'ASPETTO CLAUDE',
}

-- «Adesso» in Batti
M.batti_vuoto = '‹i›: entri in scrittura. In basso a sinistra NORMAL diventa INSERT, e da lì ogni tasto che premi scrive sopra il grigio.'
M.batti_cambiato = 'Il testo è cambiato mentre eri in NORMAL, dove le lettere sono comandi. ‹u›: annulla l\'ultimo cambio; premilo più volte per tornare più indietro.'
-- Non è nella 3.3: dopo un u di troppo, un altro u toglierebbe altro testo buono (compito 3).
M.batti_annullato = 'Hai annullato del testo che avevi scritto (in NORMAL il tasto u annulla). ‹g› ‹+›: lo rimette; ripetilo finché questa frase non cambia.'
M.batti_finito_i = 'Hai scritto tutto. ‹Esc›: smetti di scrivere (in basso torna NORMAL). Poi ‹:w› ‹Invio›: salvi e node controlla il codice.'
M.batti_finito_n = '‹:w› ‹Invio›: salvi e node controlla il codice. I due punti si fanno con Maiusc e il tasto del punto; il comando compare in fondo allo schermo.'
M.batti_maiuscole = 'Il rosso è in MAIUSCOLO dove il grigio è minuscolo: forse è acceso il Bloc Maiusc. Spegnilo; poi ‹Backspace›: cancella le lettere rosse.'
M.batti_errore = 'Il rosso è un errore. ‹Backspace›: cancella l\'ultima lettera; premilo finché il rosso sparisce, poi riscrivi giusto.'
M.batti_spezzata = 'La riga %d è stata spezzata da un a capo arrivato troppo presto. ‹Backspace›: premilo %s e torni in fondo alla riga %d; poi continua a scrivere.'
-- Non è nella 3.3: un a capo a metà di quello che si era scritto; il resto è sceso nella riga dopo.
M.batti_spezzata_meta = 'La riga %d è stata spezzata in due da un a capo. ‹Backspace›: premilo %s e la riga %d torna intera, col cursore nel punto dove si era spezzata; poi ‹Fine›: vai in fondo alla riga e continua a scrivere.'
M.batti_indietro_i = 'La riga %d non è finita. ‹Esc›: smetti di scrivere; poi ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.'
-- Non sono nella 3.3: la riga da cui si continua è intera, è solo l'ultima scritta.
M.batti_continua_i = 'Fin qui è tutto giusto: si va avanti dalla fine della riga %d, l\'ultima che hai scritto. ‹Esc›: smetti di scrivere; poi ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.'
M.batti_continua_n = 'Fin qui è tutto giusto: si va avanti dalla fine della riga %d, l\'ultima che hai scritto. ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.'
M.batti_rosso_qui = 'C\'è del rosso in questa riga. ‹A›: scrivi in fondo alla riga; poi ‹Backspace›: cancella fino al rosso, e riscrivi giusto.'
M.batti_rosso_n = 'C\'è del rosso alla riga %d. ‹%d› ‹G›: vai alla riga %d; poi ‹A›: scrivi in fondo alla riga; poi ‹Backspace›: cancella fino al rosso, e riscrivi giusto.'
M.batti_indietro_n = 'La riga %d non è finita. ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.'
M.batti_riprendi = '‹A›: torni a scrivere in fondo a questa riga. (Non i: scriverebbe prima dell\'ultima lettera.)'
-- il terzo %s è '' oppure maiuscola/maiuscole, qui sotto
M.batti_carattere = 'Il prossimo carattere, %s, non è sulla tastiera. %s: lo scrive (tieni premuto Ctrl e premi la lettera, poi gli altri tasti%s).'
M.maiuscola = '; %s maiuscola'
M.maiuscole = '; %s e %s maiuscole'
-- le volte di ‹Backspace› in batti_spezzata
M.una_volta = 'una volta'
M.volte = '%d volte'
M.batti_cursore = 'Il cursore non è in fondo a quello che hai scritto. ‹Fine›: lo porta in fondo alla riga; poi continua.'
M.batti_riga_vuota = 'Riga finita. ‹Invio› ‹Invio›: vai a capo due volte, perché nel grigio la riga dopo è vuota.'
M.batti_fine_riga = 'Riga finita. ‹Invio›: vai a capo; gli spazi all\'inizio della riga dopo li mette dattilo.'
M.batti_scrivi = 'Scrivi il testo grigio, uguale, lettera per lettera. ‹Backspace›: cancella l\'ultima lettera.'

-- «Adesso» nelle altre schermate
M.briefing = '‹Invio›: apri il codice da riscrivere. Prima, se vuoi, leggi qui sotto cosa ha fatto Claude: non c\'è fretta.'
M.cmd_w = '‹Invio›: esegui :w, cioè salvi e node controlla il codice.'
-- ‹:salta› arriva col compito 8: fino ad allora l'uscita è ‹:q›, che c'è (il compito 8 rimette ‹:salta›).
M.controllo_ko = 'Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l\'errore non è tuo. ‹:q› ‹Invio›: lasci la lezione e torni all\'elenco, dove scegli un\'altra.'
-- Non sono nella 3.3: lo stesso controllo che non passa, in INSERT; e il passo esegui (tempo B),
-- dove il testo non è più quello di Batti: l'errore sta in «Controllo».
M.controllo_ko_i = 'Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l\'errore non è tuo. ‹Esc›: smetti di scrivere; poi ‹:q› ‹Invio›: lasci la lezione e torni all\'elenco, dove scegli un\'altra.'
M.esegui_ko = 'Il codice è quello della modifica di Claude, quindi l\'errore non è tuo. ‹:q› ‹Invio›: lasci la lezione e torni all\'elenco, dove scegli un\'altra.'
M.esegui_cambiato = 'Il codice non è più quello della modifica di Claude. ‹:e!› ‹Invio›: lo rimetti com\'era; poi ‹:w› ‹Invio›: lo ricontrolli.'
M.spiegazione = 'Leggi le note accanto alle righe. ‹Invio›: vai al riepilogo. ‹j›: scendi e ‹k›: sali, se il codice non sta tutto nello schermo.'
M.fatto_coda = '‹Invio›: apri la prossima lezione, “%s”%s.'
M.fatto_vuota = '‹Invio›: aspetti la prossima modifica di Claude; la lezione si apre da sola.'
M.elenco = '‹j›: scendi di una lezione; ‹k›: sali (vanno anche le frecce). ‹Invio›: apri la lezione col ▸.'
M.attesa = 'Niente da premere: appena Claude cambia una funzione JavaScript, la lezione si apre da sola.'
-- ‹:elenco› arriva col compito 8 (il compito 8 lo rimette: «‹:elenco› ‹Invio›: vedi quelle che ci sono»).
M.attesa_finita = 'La sessione di Claude è finita: non arrivano altre lezioni. ‹:q› ‹Invio›: chiudi dattilo.'

-- «Controllo»
M.controllo_ok = 'Node ha controllato il codice: sta in piedi.'
M.controllo_mancano = 'Salvato, ma il testo non è ancora uguale al grigio: mancano %d caratteri. Il controllo parte quando è uguale.'
M.controllo_rosso = 'Salvato, ma c\'è del rosso: il controllo parte quando il testo è uguale al grigio.'
-- Non sono nella 3.3: l'errore di node fuori da Batti, e il motivo quando node non dice niente.
M.controllo_errore = 'Node non accetta il codice: %s.'
M.controllo_muto = 'il controllo non è riuscito'
M.ripreso = 'Ripreso: qui c\'è il testo che avevi scritto l\'altra volta.'
M.non_si_apre = 'Questa lezione non si apre: %s.'
-- (il testo non è «salvato»: la bozza arriva col compito 9; qui si dice solo che non è stato toccato)
M.errore_dattilo = 'Errore di dattilo: %s. Il tuo testo non è cambiato.'
M.ctrl_z = 'Ctrl-z in Neovim mette in pausa il programma, e il pannello resterebbe fermo: qui è spento. Continua da dove eri.'

-- «Comandi». Solo comandi che esistono adesso: ‹:salta›, ‹:ultima› ed ‹:elenco› arrivano col
-- compito 8, e «resta salvata» (la bozza) col compito 9, che li rimettono nei testi approvati.
M.comandi_batti = '‹:w› ‹Invio›: salvi e node controlla · ‹:q› ‹Invio›: lasci la lezione e torni all\'elenco; quello che hai scritto qui non si conserva'
M.comandi_testo = '‹q›: vai all\'elenco delle lezioni'
M.comandi_modifica = '‹:e!› ‹Invio›: ricominci la modifica da capo · ‹:q› ‹Invio›: lasci la lezione e torni all\'elenco'
M.comandi_fatto = '‹r›: rifai questa lezione · ‹q›: vai all\'elenco delle lezioni'
M.comandi_elenco = '‹:q› ‹Invio›: chiudi dattilo'
M.comandi_attesa = '‹:q› ‹Invio›: chiudi dattilo'
-- Non sono nella 3.3: «Comandi» quando il cursore è in un altro buffer (il %d è il numero del codice)
M.comandi_altro = '‹:b%d› ‹Invio›: torni al codice della lezione, com\'era'

-- Modifica (tempo B)
M.mod_parole = 'Sei in NORMAL: qui i tasti spostano il cursore e cambiano il testo. A parole: %s Se ti blocchi, fra 15 secondi senza tasti qui compaiono i tasti esatti, uno alla volta.'
M.mod_tasto = '%s: %s.'
M.mod_lista = '✓ ‹2G›: va alla riga 2 · ▸ ‹$›: va in fondo alla riga · ‹i›: entra in scrittura…'
M.mod_altri = 'Hai premuto tasti diversi da quelli suggeriti: va bene, se il testo arriva all\'obiettivo. ‹:e!› ‹Invio›: ricominci la modifica da capo, se vuoi ripartire dai tasti suggeriti.'
M.mod_uguale = 'Il testo è uguale all\'obiettivo. ‹Esc›: smetti di scrivere, e la modifica è fatta.'
M.mod_fatta = 'Fatto: è uguale alla modifica di Claude. Tasti premuti: %d; la soluzione suggerita ne usa %d. È un conto, non un voto.'

-- I posti sbagliati (3.4): { titolo, testo }
M.posti = {
  visuale = { titolo = 'SEI IN VISUAL: SELEZIONE', testo = 'Hai selezionato del testo (con il tasto v o col mouse). ‹Esc›: togli la selezione e torni in NORMAL.' },
  cmd_vuota = { titolo = 'RIGA DEI COMANDI', testo = '‹Esc›: annulli e torni dov\'eri. Se volevi salvare: ‹w› ‹Invio›: salvi e node controlla.' },
  -- Non è nella 3.4: la riga dei comandi vuota dove :w non salva niente (le schermate di testo, l'elenco).
  cmd_vuota_testo = { titolo = 'RIGA DEI COMANDI', testo = '‹Esc›: annulli e torni dov\'eri. I comandi che valgono qui sono in «Comandi», qui sotto.' },
  -- Cambiato costruendo: in fondo, come uscirne se il comando era scritto per sbaglio.
  cmd_noto = { titolo = 'RIGA DEI COMANDI', testo = '‹Invio›: esegui :%s, cioè %s. ‹Esc›: annulli e torni dov\'eri.' },
  -- Non è nella 3.4: a metà di un comando che vale qui (il secondo %s sono uno o più cmd_finisci).
  cmd_parziale = { titolo = 'RIGA DEI COMANDI', testo = 'Stai scrivendo il comando :%s. %s ‹Esc›: annulli e torni dov\'eri.' },
  cmd_ignoto = { titolo = 'RIGA DEI COMANDI', testo = 'In fondo c\'è il comando «:%s», che qui non serve. ‹Esc›: lo cancelli e torni dov\'eri.' },
  ricerca = { titolo = 'RICERCA', testo = 'Stai scrivendo una ricerca (la apre il tasto /). ‹Esc›: la cancelli e torni dov\'eri.' },
  cmdwin = { titolo = 'FINESTRA DEI COMANDI', testo = 'Si è aperta la finestra dei comandi già scritti (la apre q seguito dai due punti). ‹Ctrl-c›: la chiude e torni alla riga dei comandi; poi ‹Esc›: torni dov\'eri.' },
  registra_n = { titolo = 'STAI REGISTRANDO (@%s)', testo = 'Stai registrando i tasti in una macro (l\'ha aperta q seguito da %s). ‹q›: ferma la registrazione; il testo non cambia.' },
  registra_i = { titolo = 'STAI REGISTRANDO (@%s)', testo = 'Stai registrando i tasti in una macro. ‹Esc›: smetti di scrivere; poi ‹q›: ferma la registrazione.' },
  replace = { titolo = 'SEI IN REPLACE', testo = 'Ogni tasto scrive sopra la lettera che c\'è (l\'ha aperto R o il tasto Ins). ‹Ins›: torni a scrivere normale, in INSERT.' },
  operatore = { titolo = 'NEOVIM ASPETTA', testo = 'Hai premuto %s: Neovim aspetta di sapere su che pezzo di testo agire. ‹Esc›: annulli, e il testo non cambia.' },
  ctrl_o = { titolo = 'UN COMANDO SOLO', testo = 'Hai premuto Ctrl-o: Neovim aspetta un solo comando e poi torna a scrivere. ‹Esc›: torni subito a scrivere.' },
  -- Cambiati costruendo: ‹Ctrl-w› ‹c› chiude solo questa finestra. :q (DattiloEsci) oggi lascia la
  -- lezione: chiude solo la finestra in più dal compito 6.
  aiuto = { titolo = 'FINESTRA IN PIÙ', testo = 'Si è aperto l\'aiuto di Neovim, in inglese (l\'apre il tasto F1). ‹Ctrl-w› ‹c›: lo chiudi e torni al codice.' },
  divisa = { titolo = 'FINESTRA IN PIÙ', testo = 'Lo schermo si è diviso in due (l\'ha fatto Ctrl-w o un comando come :split). ‹Ctrl-w› ‹c›: chiudi questa finestra e torni al codice.' },
  -- Non è nella 3.4: si scrive in una finestra in più. In INSERT ‹Ctrl-w› cancella una parola: prima ‹Esc›.
  divisa_i = { titolo = 'FINESTRA IN PIÙ', testo = 'Stai scrivendo in un\'altra finestra, non nel codice della lezione. ‹Esc›: smetti di scrivere; poi ‹Ctrl-w› ‹c›: chiudi questa finestra e torni al codice.' },
  divisa_principale = { titolo = 'FINESTRA IN PIÙ', testo = 'Lo schermo si è diviso in due. ‹Ctrl-w› ‹o›: resta solo la finestra del codice; il riquadro torna da solo.' },
  frecce = { titolo = 'LE FRECCE SONO SPENTE', testo = 'Le frecce qui sono spente apposta: dattilo insegna i tasti di Vim. ‹Esc›: smetti di scrivere; poi ‹h›: sinistra, ‹j›: giù, ‹k›: su, ‹l›: destra; poi ‹A›: torni a scrivere in fondo alla riga.' },
  -- in NORMAL ‹Esc› non fa niente: si comincia da ‹A›
  frecce_n = { titolo = 'LE FRECCE SONO SPENTE', testo = 'Le frecce qui sono spente apposta: dattilo insegna i tasti di Vim. ‹A›: torni a scrivere in fondo alla riga. Per spostarti, in NORMAL: ‹h›: sinistra, ‹j›: giù, ‹k›: su, ‹l›: destra.' },
  -- Cambiato costruendo: le lettere di visual sono tasti da premere, il primo è ‹v› e non ‹Invio›.
  ex = { titolo = 'MODALITÀ EX', testo = 'Sei nella modalità Ex (l\'apre g seguito da Q). ‹v› ‹i› ‹s› ‹u› ‹a› ‹l› ‹Invio›: torni allo schermo normale (scrivi visual, poi Invio).' },
  -- Non è nella 3.4: un terminale in NORMAL (riga 16, dopo ‹Ctrl-\› ‹Ctrl-n›). Il ritorno è :b e il
  -- numero del buffer del codice: ‹Ctrl-^› con due terminali rimbalza fra i due.
  terminale = { titolo = 'UN TERMINALE', testo = 'Sei in un terminale dentro Neovim (l\'apre il comando :terminal). ‹:b%d› ‹Invio›: torni al codice della lezione, com\'era.' },
  -- Non sono nella 3.4: nella finestra della lezione c'è un altro buffer (‹Ctrl-^›, :e, :bn, ‹Ctrl-o›).
  -- Il ritorno è :b e il numero del buffer del codice: ‹Ctrl-^› rimbalzerebbe fra due buffer qualunque.
  altro_buffer = { titolo = 'UN ALTRO FILE', testo = 'Qui non c\'è il codice della lezione, ma un altro file (ci si arriva con un comando come :e o :bn, o col tasto Ctrl-^). ‹:b%d› ‹Invio›: torni al codice della lezione, com\'era.' },
  altro_buffer_i = { titolo = 'UN ALTRO FILE', testo = 'Stai scrivendo in un altro file, non nel codice della lezione. ‹Esc›: smetti di scrivere; poi ‹:b%d› ‹Invio›: torni al codice della lezione, com\'era.' },
  -- Cambiato costruendo: ‹Ctrl-\› ‹Ctrl-n› porta in NORMAL da ogni modalità, anche da un terminale,
  -- dove ‹Esc› va al programma e non a Neovim.
  sconosciuto = { titolo = 'POSTO SCONOSCIUTO', testo = 'Sei in una modalità di Neovim che la guida non conosce (in basso: %s). ‹Ctrl-\\› ‹Ctrl-n›: torni in NORMAL, da qualunque modalità (anche da un terminale, dove Esc non basta).' },
}

-- Un pezzo di cmd_parziale: i tasti che mancano, il comando intero e cosa fa.
M.cmd_finisci = '%s: finisci di scrivere :%s; poi ‹Invio›: %s.'

-- «Adesso» quando una freccia è appena stata premuta: è la riga 13 dei posti (in INSERT e in NORMAL)
M.frecce = M.posti.frecce.testo
M.frecce_n = M.posti.frecce_n.testo

-- Le spiegazioni dei comandi noti (3.4, riga 3)
M.spiega_comando = {
  w = 'salvi e node controlla il codice',
  -- la bozza (che fa restare il testo) arriva col compito 9
  q = 'lasci la lezione e torni all\'elenco',
  q_scritto = 'lasci la lezione e torni all\'elenco; quello che hai scritto qui non si conserva',
  q_finestra = 'chiudi questa finestra e torni al codice',
  q_esci = 'chiudi dattilo',
  b = 'torni al codice della lezione, com\'era',
  salta = 'passi alla prossima lezione',
  ultima = 'vai all\'ultima modifica di Claude',
  elenco = 'vedi le lezioni di Rifallo tu',
  ['e!'] = 'ricominci da capo',
}

local function cerca(nome)
  local v = M
  for pezzo in tostring(nome):gmatch('[^.]+') do
    if type(v) ~= 'table' then return nil end
    v = v[pezzo]
  end
  return type(v) == 'string' and v or nil
end

-- string.format sulla frase `nome` (anche 'titoli.briefing'); nil se il nome non c'è.
function M.f(nome, ...)
  local s = cerca(nome)
  if not s then return nil end
  return string.format(s, ...)
end

-- La riga M.posti[nome], con titolo e testo formattati con gli stessi valori.
function M.posto(nome, ...)
  local p = M.posti[nome]
  if not p then return nil end
  return string.format(p.titolo, ...), string.format(p.testo, ...)
end

local NOMI_TASTI = {
  Invio = '<CR>', Esc = '<Esc>', Backspace = '<BS>', Fine = '<End>', Home = '<Home>', Ins = '<Insert>',
  Tab = '<Tab>', Spazio = '<Space>', ['<'] = '<lt>', ['\\'] = '<Bslash>', ['|'] = '<Bar>',
}

-- Traduce un tasto della guida nella notazione di Neovim: Invio → <CR>, Ctrl-k → <C-k>.
function M.neovim(tasto)
  if NOMI_TASTI[tasto] then return NOMI_TASTI[tasto] end
  local c = tasto:match('^Ctrl%-(.+)$')
  if c then return '<C-' .. c .. '>' end
  return tasto
end

return M
