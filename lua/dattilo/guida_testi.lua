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
M.batti_finito_i = 'Hai scritto tutto. ‹Esc›: smetti di scrivere (in basso torna NORMAL). Poi ‹:w› ‹Invio›: salvi e node controlla il codice.'
M.batti_finito_n = '‹:w› ‹Invio›: salvi e node controlla il codice. I due punti si fanno con Maiusc e il tasto del punto; il comando compare in fondo allo schermo.'
M.batti_maiuscole = 'Il rosso è in MAIUSCOLO dove il grigio è minuscolo: forse è acceso il Bloc Maiusc. Spegnilo; poi ‹Backspace›: cancella le lettere rosse.'
M.batti_errore = 'Il rosso è un errore. ‹Backspace›: cancella l\'ultima lettera; premilo finché il rosso sparisce, poi riscrivi giusto.'
M.batti_spezzata = 'La riga %d è stata spezzata da un a capo arrivato troppo presto. ‹Backspace›: premilo %s e torni in fondo alla riga %d; poi continua a scrivere.'
M.batti_indietro_i = 'La riga %d non è finita. ‹Esc›: smetti di scrivere; poi ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.'
M.batti_rosso_qui = 'C\'è del rosso in questa riga. ‹A›: scrivi in fondo alla riga; poi ‹Backspace›: cancella fino al rosso, e riscrivi giusto.'
M.batti_rosso_n = 'C\'è del rosso alla riga %d. ‹%d› ‹G›: vai alla riga %d; poi ‹A›: scrivi in fondo alla riga; poi ‹Backspace›: cancella fino al rosso, e riscrivi giusto.'
M.batti_indietro_n = 'La riga %d non è finita. ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.'
M.batti_riprendi = '‹A›: torni a scrivere in fondo a questa riga. (Non i: scriverebbe prima dell\'ultima lettera.)'
M.batti_carattere = 'Il prossimo carattere, %s, non è sulla tastiera. %s: lo scrive (tieni premuto Ctrl e premi la lettera, poi gli altri tasti).'
M.batti_cursore = 'Il cursore non è in fondo a quello che hai scritto. ‹Fine›: lo porta in fondo alla riga; poi continua.'
M.batti_riga_vuota = 'Riga finita. ‹Invio› ‹Invio›: vai a capo due volte, perché nel grigio la riga dopo è vuota.'
M.batti_fine_riga = 'Riga finita. ‹Invio›: vai a capo; gli spazi all\'inizio della riga dopo li mette dattilo.'
M.batti_scrivi = 'Scrivi il testo grigio, uguale, lettera per lettera. ‹Backspace›: cancella l\'ultima lettera.'

-- «Adesso» nelle altre schermate
M.briefing = '‹Invio›: apri il codice da riscrivere. Prima, se vuoi, leggi qui sotto cosa ha fatto Claude: non c\'è fretta.'
M.cmd_w = '‹Invio›: esegui :w, cioè salvi e node controlla il codice.'
M.controllo_ko = 'Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l\'errore non è tuo. ‹:salta› ‹Invio›: passi alla prossima lezione.'
M.spiegazione = 'Leggi le note accanto alle righe. ‹Invio›: vai al riepilogo. ‹j›: scendi e ‹k›: sali, se il codice non sta tutto nello schermo.'
M.fatto_coda = '‹Invio›: apri la prossima lezione, “%s”%s.'
M.fatto_vuota = '‹Invio›: aspetti la prossima modifica di Claude; la lezione si apre da sola.'
M.elenco = '‹j›: scendi di una lezione; ‹k›: sali (vanno anche le frecce). ‹Invio›: apri la lezione col ▸.'
M.attesa = 'Niente da premere: appena Claude cambia una funzione JavaScript, la lezione si apre da sola.'
M.attesa_finita = 'La sessione di Claude è finita: non arrivano altre lezioni. ‹:elenco› ‹Invio›: vedi quelle che ci sono.'

-- «Controllo»
M.controllo_ok = 'Node ha controllato il codice: sta in piedi.'
M.controllo_mancano = 'Salvato, ma il testo non è ancora uguale al grigio: mancano %d caratteri. Il controllo parte quando è uguale.'
M.controllo_rosso = 'Salvato, ma c\'è del rosso: il controllo parte quando il testo è uguale al grigio.'
M.ripreso = 'Ripreso: qui c\'è il testo che avevi scritto l\'altra volta.'
M.non_si_apre = 'Questa lezione non si apre: %s.'
M.errore_dattilo = 'Errore di dattilo: %s. Il tuo testo è salvato.'
M.ctrl_z = 'Ctrl-z in Neovim mette in pausa il programma, e il pannello resterebbe fermo: qui è spento. Continua da dove eri.'

-- «Comandi»
M.comandi_batti = '‹:w› ‹Invio›: salvi e node controlla · ‹:q› ‹Invio›: lasci la lezione, resta salvata · ‹:salta› ‹Invio›: passi alla prossima · ‹:ultima› ‹Invio›: vai all\'ultima modifica di Claude'
M.comandi_testo = '‹q›: vai all\'elenco delle lezioni · ‹:salta› ‹Invio›: passi alla prossima · ‹:ultima› ‹Invio›: vai all\'ultima modifica di Claude'
M.comandi_modifica = '‹:e!› ‹Invio›: ricominci la modifica da capo · ‹:q› ‹Invio›: lasci la lezione · ‹:salta› ‹Invio›: passi alla prossima'
M.comandi_fatto = '‹r›: rifai questa lezione · ‹q›: vai all\'elenco delle lezioni · ‹:ultima› ‹Invio›: vai all\'ultima modifica di Claude'
M.comandi_elenco = '‹:ultima› ‹Invio›: apri l\'ultima modifica di Claude · ‹:q› ‹Invio›: chiudi dattilo (quello che hai scritto resta, e «Rifallo tu» lo riapre)'
M.comandi_attesa = '‹:elenco› ‹Invio›: vedi le lezioni già arrivate · ‹:q› ‹Invio›: chiudi dattilo'

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
  cmd_noto = { titolo = 'RIGA DEI COMANDI', testo = '‹Invio›: esegui :%s, cioè %s.' },
  cmd_ignoto = { titolo = 'RIGA DEI COMANDI', testo = 'In fondo c\'è il comando «:%s», che qui non serve. ‹Esc›: lo cancelli e torni dov\'eri.' },
  ricerca = { titolo = 'RICERCA', testo = 'Stai scrivendo una ricerca (la apre il tasto /). ‹Esc›: la cancelli e torni dov\'eri.' },
  cmdwin = { titolo = 'FINESTRA DEI COMANDI', testo = 'Si è aperta la finestra dei comandi già scritti (la apre q seguito dai due punti). ‹Ctrl-c›: la chiude e torni alla riga dei comandi; poi ‹Esc›: torni dov\'eri.' },
  registra_n = { titolo = 'STAI REGISTRANDO (@%s)', testo = 'Stai registrando i tasti in una macro (l\'ha aperta q seguito da %s). ‹q›: ferma la registrazione; il testo non cambia.' },
  registra_i = { titolo = 'STAI REGISTRANDO (@%s)', testo = 'Stai registrando i tasti in una macro. ‹Esc›: smetti di scrivere; poi ‹q›: ferma la registrazione.' },
  replace = { titolo = 'SEI IN REPLACE', testo = 'Ogni tasto scrive sopra la lettera che c\'è (l\'ha aperto R o il tasto Ins). ‹Ins›: torni a scrivere normale, in INSERT.' },
  operatore = { titolo = 'NEOVIM ASPETTA', testo = 'Hai premuto %s: Neovim aspetta di sapere su che pezzo di testo agire. ‹Esc›: annulli, e il testo non cambia.' },
  ctrl_o = { titolo = 'UN COMANDO SOLO', testo = 'Hai premuto Ctrl-o: Neovim aspetta un solo comando e poi torna a scrivere. ‹Esc›: torni subito a scrivere.' },
  aiuto = { titolo = 'FINESTRA IN PIÙ', testo = 'Si è aperto l\'aiuto di Neovim, in inglese (l\'apre il tasto F1). ‹:q› ‹Invio›: lo chiudi e torni al codice.' },
  divisa = { titolo = 'FINESTRA IN PIÙ', testo = 'Lo schermo si è diviso in due (l\'ha fatto Ctrl-w o un comando come :split). ‹:q› ‹Invio›: chiudi questa finestra e torni al codice.' },
  divisa_principale = { titolo = 'FINESTRA IN PIÙ', testo = 'Lo schermo si è diviso in due. ‹Ctrl-w› ‹o›: resta solo la finestra del codice; il riquadro torna da solo.' },
  frecce = { titolo = 'LE FRECCE SONO SPENTE', testo = 'Le frecce qui sono spente apposta: dattilo insegna i tasti di Vim. ‹Esc›: smetti di scrivere; poi ‹h›: sinistra, ‹j›: giù, ‹k›: su, ‹l›: destra; poi ‹A›: torni a scrivere in fondo alla riga.' },
  ex = { titolo = 'MODALITÀ EX', testo = 'Sei nella modalità Ex (l\'apre g seguito da Q). Scrivi visual, poi ‹Invio›: torni allo schermo normale.' },
  sconosciuto = { titolo = 'POSTO SCONOSCIUTO', testo = 'Sei in una modalità di Neovim che la guida non conosce (in basso: %s). ‹Esc›: di solito riporta in NORMAL; se non basta, ‹:q› ‹Invio›: lasci la lezione, che resta salvata.' },
}

-- «Adesso» quando una freccia è appena stata premuta: è la riga 13 dei posti
M.frecce = M.posti.frecce.testo

-- Le spiegazioni dei comandi noti (3.4, riga 3)
M.spiega_comando = {
  w = 'salvi e node controlla il codice',
  q = 'lasci la lezione, che resta salvata',
  q_finestra = 'chiudi questa finestra e torni al codice',
  q_esci = 'chiudi dattilo; quello che hai scritto resta',
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
