# «Rifallo tu»: progetto (Dal vivo, parte 2, 23/11/2026)

> **Cambiato la sera del 23/11.** Andrea ha corretto la regola sui tasti: «no, vim ci deve stare, è che andava costruito per qualcuno che non lo sapeva fare». La versione di prima l'aveva letta come «togli Vim» (modalità «solo battitura», filtro dei tasti, tasti F), e tutto questo è tolto.
> Ora una lezione di «Rifallo tu» è una lezione normale di dattilo, con Vim vero e una guida sempre accesa. La guida dice in italiano, in ogni momento, che tasto premere e cosa fa, e come si esce da ogni posto sbagliato (sezione 3).
> Andrea ha scelto anche il passo Modifica («sì la modifica di Claude va inserita»). Si costruisce nel tempo B, dopo che il tempo A è provato a mano.

Questo documento è il progetto di «Rifallo tu», non il piano di costruzione. Chi lo legge deve poterne ricavare il piano senza tornare a chiedere. Dove una cosa è verificata cito il file e la riga, o la prova fatta. Dove è una mia ipotesi lo scrivo. Il piano del lato dattilo è `docs/superpowers/plans/2026-11-23-rifallo-tu-dattilo.md`.

**In breve.**
- Dal fumetto di «Dal vivo» un tasto «Rifallo tu» apre dattilo in un pannello accanto al terminale di Claude.
- La persona riscrive a mano la funzione che Claude ha appena cambiato.
- A ogni modifica nuova di Claude si prepara una lezione nuova, che va in coda («2 nuove»). Quella che la persona sta scrivendo non si tocca.
- La lezione la prepara l'aiutante che già chiama Haiku per «Dal vivo», con la stessa chiamata.
- La lezione passa a dattilo attraverso dei file. dattilo guarda la sua cartella da solo, e nessuno dei due aspetta l'altro.
- dattilo, aperto così, è il dattilo di sempre, con Vim vero: si entra in scrittura con ‹i›, si esce con ‹Esc›, si salva con ‹:w›. La differenza è la guida. In ogni schermata dice che tasto premere adesso e cosa fa, come se fosse la prima volta. Se la persona finisce in un posto sbagliato, lo dice e dice come uscirne.
- Due tempi:
  - **A:** Batti con la guida, spiegazione e riepilogo;
  - **B:** in più Modifica. Si parte dal codice di prima e si rifà la modifica di Claude con le mosse di Vim, coi tasti suggeriti.

---

## 1. Cosa si vuole

### Le parole di Andrea (scelte sue, non si riaprono)

- «Rifallo tu» si apre dal fumetto di «Dal vivo». È la scelta «rifallo» della tavola: artifact `MNwVwedVNWguq1NghQTdfQ`, documento `scelte/tavola`, campo `dattilo: ["rifallo"]`. L'ho riletto oggi.
- In tempo reale: «in realtime riscrivi quello che ha fatto», «ogni volta si riaggiorna sarebbe l'obiettivo». La nota della tavola dice: «"Rifallo tu" in tempo reale, che si riaggiorna a ogni modifica di Claude».
- La spiegazione la scrive Haiku, lo stesso modello che già spiega i passi.
- **«Per chi usa Rifallo tu devi dare per scontato che uno non sa mai niente di nvim, nessun keybinding, ogni volta».** Corretta da lui la sera stessa: **«no, vim ci deve stare, è che andava costruito per qualcuno che non lo sapeva fare».** La lettura confermata, che da ora è la regola:
  - Vim vero: modalità e tasti veri, niente filtro, niente modalità finta, niente tasti inventati al posto di quelli di Vim;
  - fatto per chi non lo sa usare: in ogni schermata e in ogni momento c'è scritto, in italiano, che tasto premere adesso e cosa fa, come se fosse sempre la prima volta;
  - nel posto sbagliato la guida lo dice e dice come uscirne.

  Questa regola ha una sezione tutta sua, la 3, e vale più di ogni altra scelta di questo documento.
- **«sì la modifica di Claude va inserita»**: il passo Modifica (tempo B).
- Le altre risposte di Andrea alle domande della prima versione:
  - per ora solo JavaScript (`.js`, `.mjs`, `.cjs`);
  - le lezioni si preparano dal suo primo clic su «Rifallo tu» in poi;
  - i commenti non si battono;
  - su Windows il tasto non c'è.

La tavola descriveva così l'opzione scelta: «Un clic prepara la lezione da quella modifica e apre dattilo nel riquadro accanto». Il pannello accanto viene da lì.

### Obiettivi

1. La persona impara il codice del proprio progetto riscrivendo a mano quello che Claude ha appena fatto: la funzione intera, non due righe sparse.
2. Tutto va al passo con Claude:
   - ogni modifica nuova dà una lezione nuova, pronta in pochi secondi;
   - la lezione in corso non viene mai cancellata né cambiata sotto le dita;
   - si passa alla prossima quando lo decide la persona.
3. Funziona per chi non ha mai visto Vim, ogni volta. Vim c'è tutto, ma ogni tasto che serve è scritto a schermo, con cosa fa, nel momento in cui serve.
4. La persona impara Vim mentre rifà: i tasti sono quelli veri e valgono in qualunque Neovim.
5. Niente di quello che c'è oggi in «Dal vivo» peggiora:
   - il fumetto arriva con gli stessi tempi;
   - l'hook non rallenta Claude;
   - su Windows la mod resta uguale.
6. Il dattilo di oggi, aperto senza «Rifallo tu», non cambia.

### Non-obiettivi (per questa parte)

- «Rompi» e il Dojo: in «Rifallo tu» non compaiono. «Modifica» c'è, nel tempo B.
- Il C, TypeScript e gli altri linguaggi: per ora solo JavaScript (`.js`, `.mjs`, `.cjs`). Il perché è nella sezione 5.4.
- Windows: dattilo lì non c'è, e il tasto non compare.
- La coop (parte 3) e la gara.
- Tenere le lezioni dopo la fine: era l'opzione «Il pacchetto del progetto», che Andrea non ha scelto.
- Statistiche e ripasso di dattilo.
- Accendere la guida per le lezioni normali di dattilo. Il disegno lo permette (5.9), ma oggi non lo fa niente.

### Anti-obiettivi: è un fallimento anche se «funziona» quando…

- la persona deve premere un tasto che in quel momento non è scritto a schermo, con cosa fa;
- la persona si trova in un posto di Vim che non conosce, e lo schermo non le dice dov'è e che tasto la riporta indietro;
- la guida dà per scontato qualcosa perché «l'ha già visto»: alla decima lezione deve dire le stesse cose della prima;
- dattilo stesso fa comparire «Premi INVIO», che blocca lo schermo e lì nessuna guida può parlare;
- il codice da battere cambia mentre la persona lo sta scrivendo, o una lezione nuova la strappa dall'esercizio senza che l'abbia chiesto;
- la persona passa più tempo su rientri, commenti in prosa, caratteri che non trova sulla tastiera o righe rosse misteriose che sul codice;
- la lezione non si può finire, perché il codice da battere non passa il controllo di `node --check`;
- il fumetto di «Dal vivo» arriva più tardi o sparisce, perché la chiamata a Haiku è diventata troppo grossa;
- il codice di lavoro della persona resta in giro sul disco, in cartelle leggibili da altri o per sempre;
- chiudere il pannello a metà fa perdere il testo scritto.

---

## 2. Come si usa, passo per passo

Situazione di partenza: Andrea ha acceso «Dal vivo» sulla sua sessione di Claude (tasto destro → «Dal vivo»). La finestrella sta sopra il terminale. Claude cambia `server/src/logica/regole.js` e tocca la funzione `codicePulito`.

I tasti si scrivono fra ‹ ›, come li scrive dattilo (ui.lua:47-57): ‹i› è il tasto i, e ‹:w› ‹Invio› vuol dire scrivere `:w` e premere Invio. In ogni punto qui sotto la guida (il riquadro in alto, sezione 3) dice il tasto e cosa fa. Le frasi esatte sono nella 3.3 e nella 3.4.

1. **Il fumetto.** Il passo compare come oggi: viola «sta scrivendo», poi verde «spiega». A destra del fumetto c'è il tasto **«Rifallo tu»**.
   - Nella finestrella il fumetto è una riga sola, e il tasto sta in fondo a quella riga.
   - Nella scheda intera il tasto sta accanto a «Di più».
   - Mentre la lezione si prepara, il tasto mostra «Rifallo tu ···» e non si può premere. Dura al massimo 40 secondi.
2. **Il clic.** In circa un secondo:
   - a destra del terminale di Claude si apre un pannello con dattilo, e la tastiera va lì;
   - dattilo è già sulla lezione, al **briefing**: niente home e niente menu.
3. **Il briefing.**
   - Al centro ci sono il titolo («La tabella dei sosia»), il file, due frasi di Haiku su cosa ha fatto Claude e i passi della lezione: «Batti il codice» e «Capisci», più «Rifai la modifica» nel tempo B.
   - In alto, il riquadro della guida dice: «‹Invio›: apri il codice da riscrivere.»
   - La persona preme ‹Invio›.
4. **Batti, prima di scrivere.**
   - La funzione è in grigio, col cursore sulla prima riga. In basso a sinistra c'è scritto NORMAL.
   - La guida dice: «‹i›: entri in scrittura. In basso a sinistra NORMAL diventa INSERT, e da lì ogni tasto che premi scrive sopra il grigio.»
   - La persona preme ‹i›, e in basso compare INSERT.
5. **Batti, mentre scrive.**
   - Scrive sopra il grigio. Un errore diventa rosso, e la guida dice «‹Backspace›: cancella l'ultima lettera…».
   - ‹Invio› a fine riga va a capo e mette da solo gli spazi del rientro (batti.lua:103-108).
   - Sotto «Adesso» il riquadro mostra «Riga», «Blocco» e «Fin qui» coi testi di Haiku, come oggi (lezione.lua:154-192).
   - Se il prossimo carattere non è sulla tastiera (« … →), la guida dice il digramma di Vim: «‹Ctrl-k› ‹<› ‹<›: lo scrive…».
   - Nel riquadro c'è sempre la sezione «Comandi»: ‹:w›, ‹:q›, ‹:salta› e ‹:ultima›, ognuno con cosa fa.
   - Se la persona esce dalla scrittura (‹Esc›, ‹Ctrl-c›, un clic), la guida dice come rientrare nel punto giusto. Di solito è ‹A›, «scrivi in fondo alla riga», e non ‹i›: ‹Esc› sposta il cursore indietro di una lettera, e ‹i› scriverebbe prima dell'ultima.
   - Se finisce in un posto di Vim che non conosce (selezione, riga dei comandi, registrazione, finestra divisa…), il riquadro diventa rosso. Dice dov'è e qual è la frase per tornare (3.4).
6. **Testo finito.**
   - Appena il testo è uguale al grigio, la guida dice: «Hai scritto tutto. ‹Esc›: smetti di scrivere (in basso torna NORMAL). Poi ‹:w› ‹Invio›: salvi e node controlla il codice.»
   - La persona preme ‹Esc›, poi ‹:›, ‹w› e ‹Invio›.
7. **Il controllo.**
   - dattilo salva e lancia `node --check` (compila.lua:89-128).
   - L'esito va nel riquadro, mai nella riga dei messaggi (G5).
   - Se passa, si va subito alla spiegazione: il secondo ‹:w› del passo «esegui» di oggi non c'è (3.2, punto 8).
8. **(Tempo B) Rifai la modifica.**
   - Si apre il codice com'era *prima* di Claude, con sotto la finestra OBIETTIVO: il codice di adesso, con le differenze evidenziate (esercizio.lua:123-160).
   - La guida dice a parole cosa cambiare.
   - Se la persona resta ferma 15 secondi, compaiono i tasti esatti, uno alla volta, ognuno con cosa fa.
   - Il conto dei tasti c'è, il par e le stelle no.
   - Quando il testo è uguale all'obiettivo e la persona preme ‹Esc›, la modifica è fatta.
9. **La spiegazione.** Il codice con le note di Haiku accanto alle righe (lezione.lua:390-414). La guida: «‹Invio›: vai al riepilogo.»
10. **Il riepilogo.**
    - Mostra righe, tempo, parole al minuto e precisione. Nel tempo B anche i tasti della modifica, senza voto.
    - La guida: «‹Invio›: apri la prossima lezione, “Il nome” (2 nuove).» Senza coda: «‹Invio›: aspetti la prossima modifica di Claude…»
11. **L'attesa.** Senza coda, dattilo dice «Aspetto la prossima modifica di Claude a un file JavaScript…». Appena arriva una lezione si apre da sola: la persona ha già detto che vuole continuare.
12. **Claude modifica ancora mentre la persona scrive.**
    - Nella finestrella di «Dal vivo» compare il passo nuovo, con il suo tasto «Rifallo tu».
    - In dattilo, nella barra in alto a destra, compare «1 nuova». Nella testata di «Dal vivo» compare il tasto «1 nuova».
    - L'esercizio in corso non cambia.
    - Se Claude ha cambiato proprio la funzione che la persona sta scrivendo, la versione nuova va in coda come lezione a parte. Il testo in grigio resta quello di prima.
13. **Saltare, andare all'ultima, l'elenco.** Si fa con comandi veri di Neovim, sempre scritti nella sezione «Comandi»:
    - ‹:salta› ‹Invio› lascia la lezione, che resta segnata come saltata, e apre la prossima in coda;
    - ‹:ultima› ‹Invio› apre l'ultima modifica di Claude. La lezione lasciata resta da finire, col testo già scritto;
    - ‹:elenco› ‹Invio›, oppure ‹:q› ‹Invio› da una lezione, apre l'elenco delle lezioni di «Rifallo tu» (✓ fatta, ▸ da fare, «nuova», «saltata»).

    Col mouse, in «Dal vivo»:
    - un clic su «Rifallo tu» di un altro passo porta a quella lezione;
    - un clic su «N nuove» nella testata fa come ‹:ultima›.
14. **Uscire.**
    - ‹:q› ‹Invio› da una lezione porta all'elenco. ‹:q› ‹Invio› dall'elenco o dall'attesa chiude dattilo, e con lui il pannello.
    - Anche chiudere il pannello dalla sua × di Herdr va bene.
    - In tutti i casi non si perde niente. Il testo scritto è in una bozza (G8), e la coda resta. Un altro clic su «Rifallo tu» riapre dattilo sulla lezione lasciata, col testo di prima.
    - Mentre dattilo è chiuso non si preparano lezioni nuove.

**I casi a parte.**
- **Il file non è JavaScript** (per esempio `.ts`, `.py`, `.lua`, `.c`).
  - Nella finestrella il tasto non c'è.
  - Nella scheda intera, al suo posto, una riga grigia: «Rifallo tu: dattilo controlla solo JavaScript (.js, .mjs, .cjs); questo file è .ts.»
  - Non si prepara nessuna lezione.
- **La funzione non si può rifare**, perché è troppo lunga o il pezzo non sta in piedi da solo. Come sopra, con il motivo in chiaro. Per esempio: «Rifallo tu: questa funzione è troppo lunga (84 righe) e non si taglia in un pezzo che stia in piedi da solo.»
- **(Tempo B) La modifica non si può rifare coi tasti**: Haiku non ha dato tasti validi, oppure i tasti non portano all'obiettivo. La lezione esce senza Modifica, come nel tempo A, e la persona non vede nessun errore.
- **La sessione di Claude finisce, oppure «Dal vivo» si spegne.**
  - «Dal vivo» si spegne come nella parte 1. dattilo resta aperto, e la persona finisce quello che sta facendo.
  - In alto a destra, in dattilo, compare «sessione finita: niente lezioni nuove» (oppure «Dal vivo spento: niente lezioni nuove»).
  - Quando poi la persona chiude dattilo, la cartella delle lezioni si cancella.
- **dattilo non è installato** (Linux o macOS).
  - Il tasto «Rifallo tu» c'è.
  - Il clic mostra un avviso di Herdr: titolo «Serve dattilo», testo «"Rifallo tu" usa dattilo, che su questo computer non c'è. Installalo (github.com/Frumorn12/dattilo, serve Neovim 0.12) e riprova.»
  - Con un dattilo vecchio, che non conosce `vivo`, l'avviso è un altro: «Il tuo dattilo non sa ancora fare "Rifallo tu": aggiornalo (git pull nella sua cartella) e riprova.»
- **Windows.** Il tasto non c'è mai. Niente viene preparato, e il resto di «Dal vivo» è identico.
- **Haiku spento** con l'interruttore di «Dal vivo». Le lezioni si fanno lo stesso, ma senza le frasi di Haiku e senza Modifica. Restano:
  - il titolo, che è il nome della funzione;
  - le parole di Claude;
  - blocchi semplici: «Prima», «La modifica di Claude», «Dopo».

---

## 3. Per chi non sa Vim

La regola di Andrea, come l'ha corretta lui: Vim c'è tutto, ma è costruito per chi non lo sa usare, e lo dà per non saputo ogni volta. In questa sezione:
- le regole, ognuna con la sua prova (3.1);
- i punti dove dattilo oggi dà Vim per scontato (3.2);
- le frasi della guida, schermata per schermata (3.3);
- i posti sbagliati e la frase che riporta indietro (3.4).

**La guida, in breve.** È il riquadro che dattilo ha già in alto (ui.lua:136-226), acceso in ogni schermata della lezione e non solo in Batti. Contiene sempre:
- un titolo che dice dove sei («SCRIVI · riga 3 di 5», «SEI IN VISUAL»), con il bordo rosso nei posti sbagliati;
- la sezione **«Adesso»**: il prossimo tasto e cosa fa;
- la sezione **«Comandi»**: i comandi che valgono in quella schermata, ognuno con cosa fa.

Dove serve contiene anche:
- **«Controllo»**: l'esito di ‹:w› e gli avvisi di dattilo;
- in Batti, **«Riga»**, **«Blocco»** e **«Fin qui»**, come oggi (lezione.lua:154-192);
- nella Modifica, **«Consegna»** e **«Tasti»**.

**L'ordine quando lo spazio non basta.** ui.lua:97-133 accorcia per prime le sezioni meno importanti. L'ordine è Adesso 9, Controllo 8, Comandi 7, Consegna 6, Tasti 5, Riga 4, Fin qui 3, Blocco 2. Prima di accorciare «Adesso» o «Comandi», la guida alza il riquadro, fino a 10 righe interne.

### 3.1 Le regole

- **G1. La guida c'è sempre.**
  - In ogni schermata il riquadro è aperto in alto, con «Adesso» e «Comandi». Vale per le schermate della lezione guidata (briefing, Batti, Modifica, spiegazione, riepilogo) e per quelle di «Rifallo tu» (elenco, attesa).
  - «Adesso» e «Comandi» si leggono interi.
  - *Prova:* nel Neovim figlio (7.2), per ogni schermata del giro, il titolo e le sezioni del riquadro sono quelli della 3.3, e «Adesso» e «Comandi» non finiscono con «…». Si fa a 80×24 e a 80×40.
- **G2. Il tasto giusto per il punto dove sei.**
  - «Adesso» dipende da schermata, modo di Neovim, testo e cursore (tabella della 3.3).
  - Il **primo** tasto scritto in «Adesso» è sempre la cosa giusta da fare adesso. Gli altri vengono dopo, nell'ordine.
  - Dopo ‹Esc› in fondo a una riga, la guida dice ‹A›, non ‹i›. ‹Esc› porta il cursore indietro di una lettera, e ‹i› scriverebbe prima dell'ultima.
  - *Prova:* `guida.adesso_batti` sui casi della 3.3, senza figlio. Poi, nel figlio, il giro «da chi non sa niente»: un robot che preme solo il primo tasto di «Adesso» arriva in fondo alla lezione (7.2).
- **G3. Ogni tasto spiegato, ogni volta.**
  - Fra ‹ › ci vanno solo i tasti da premere. Ogni tasto fra ‹ ›, o fila di tasti, è seguito da «:» e da cosa fa, nella stessa frase. Esempio: «‹Ctrl-k› ‹<› ‹<›: lo scrive».
  - I tasti che dicono come ci si è arrivati («l'ha aperta q seguito da a») si scrivono senza ‹ ›, così non si confondono con quelli da premere.
  - La guida non ricorda niente della persona. Nessuna frase cambia perché la persona ha già fatto lezioni o ha già visto quella frase. Alla decima lezione la guida è uguale alla prima.
  - *Prova:*
    - su tutti i testi di `guida_testi.lua`, ogni fila di ‹…› è seguita da «:»;
    - nel figlio, «Adesso» all'inizio di Batti è identica con `progressi.json` vuoto e con 10 lezioni fatte.
- **G4. I posti sbagliati.**
  - Per ogni riga della 3.4, dattilo se ne accorge con l'evento scritto lì. Il riquadro diventa rosso col titolo del posto, e «Adesso» dice la frase per tornare.
  - Quando si torna, il riquadro torna com'era.
  - Ogni modo che la tabella non conosce ha la frase di riserva (3.4, riga 16).
  - *Prova:* nel figlio, per ogni riga della tabella:
    - ci si entra con i tasti veri;
    - titolo e frase sono quelli della 3.4;
    - si premono i tasti della frase e si è di nuovo dove si era, col testo della lezione uguale a prima.
- **G5. Niente «Premi INVIO» per colpa di dattilo.**
  - In una lezione guidata, ogni esito, avviso o errore di dattilo va nel riquadro (sezione «Controllo»), mai nella riga dei messaggi. Oggi `eco` di lezione.lua:22 scrive su più righe ogni esito di ‹:w› (compila.lua:151-182), e da lì viene «Premi INVIO». Con la guida passa dalla guida.
  - Le funzioni della guida girano protette (`pcall`). Un errore di dattilo va nel riquadro («Errore di dattilo: …»), non nella riga dei messaggi.
  - L'opzione `more` è spenta, così «-- Ancora --» non compare.
  - Le frasi di Neovim sono in italiano, perché `bin/dattilo vivo` mette `LANGUAGE=it` (provato: «E492: Non è un comando dell'editor»). Anche «Premi INVIO o un comando per proseguire» è in italiano. Compare solo dopo un comando lungo della persona, e dice da sola cosa premere.
  - *Prova:*
    - nel figlio, dopo ‹:w› con testo a metà, con testo finito e con node che rifiuta: `:messages` non ha righe che vengono da dattilo, cioè altro dal messaggio di Neovim sul file scritto;
    - in tmux, «INVIO» non compare mai sullo schermo nel giro completo.
- **G6. Comandi veri, sempre scritti.**
  - Le azioni sono comandi di Neovim: `:w` salva, `:q` lascia, `:e!` ricomincia (quelli di oggi, init.lua:4-9). In più ci sono `:salta`, `:ultima` ed `:elenco`, che esistono solo in «Rifallo tu».
  - Si scrivono in minuscolo, come `:q`: sono abbreviazioni come quelle di oggi.
  - Nelle schermate di testo valgono i tasti di dattilo di sempre: ‹Invio›, ‹q›, ‹r›, ‹j›, ‹k›.
  - Niente tasti funzione, niente tasti inventati.
  - La sezione «Comandi» di ogni schermata elenca tutto quello che fa qualcosa lì, e solo quello.
  - *Prova:*
    - per ogni schermata, nel figlio, ogni comando di «Comandi» porta dove dice;
    - senza `vivo`, `:DattiloSalta`, `:DattiloUltima` e `:DattiloElenco` non esistono.
- **G7. `:q` chiude il posto dove sei.**
  - In una finestra in più (l'aiuto di ‹F1›, una divisione) `:q` chiude solo quella finestra.
  - Nella finestra della lezione `:q` lascia la lezione, che resta salvata, e va all'elenco. Dall'elenco e dall'attesa chiude dattilo. (Cambiato costruendo: «resta salvata» arriva col compito 9, la bozza; fino ad allora `:q` perde il testo scritto e la guida lo dice prima dell'Invio. In più `:qa` chiude dattilo del tutto, da qualunque posto: vedi «Compito 6» in fondo.)
  - La finestra della lezione si può chiudere anche in un altro modo (‹Ctrl-w› ‹c›, oppure ‹Ctrl-w› ‹o› da una finestra in più). In quel caso dattilo rimette la lezione nella finestra che resta, invece di tornare alla home come oggi (schermo.lua:15-31).
  - *Prova:* nel figlio:
    - ‹F1›, poi `:q` ‹Invio› → di nuovo in Batti, col testo intatto;
    - ‹Ctrl-w› ‹s›, poi ‹Ctrl-w› ‹o› → in Batti, con una finestra di codice più il riquadro;
    - `:q` in Batti → elenco;
    - `:q` nell'elenco → Neovim esce.
- **G8. Niente testo perso.**
  - Il testo di Batti si salva in `bozze/<id>.json`:
    - al massimo ogni 2 s mentre si scrive;
    - quando si esce dalla scrittura;
    - quando si cambia lezione;
    - alla chiusura di Neovim (`VimLeavePre`).
  - `VimLeavePre` scatta anche quando il pannello si chiude da fuori. L'ho provato in tmux chiudendo la sessione (SIGHUP) e con SIGTERM, e nel figlio con `jobstop`. Con un'uccisione secca (SIGKILL) si perdono al massimo gli ultimi 2 s.
  - Quando si riapre la lezione (dall'elenco, da `vuoi.json` o riaprendo dattilo), si va dritti a Batti col testo di prima e il cursore in fondo. La guida dice «Ripreso: …» e ‹A›.
  - La bozza si cancella quando la lezione è fatta.
  - **Scelta mia.** La bozza è un file di `vivo`, e `lezione.batti` resta com'è. Oggi `lezione.batti` svuota il file di lavoro a ogni apertura (lezione.lua:277), e cambiarlo toccherebbe il dattilo di tutti.
  - *Prova:* nel figlio:
    - scrivere 2 righe, `jobstop`, riaprire un figlio sulla stessa cartella → Batti con le 2 righe;
    - `:ultima` e ritorno → righe intatte.
- **G9. Ctrl-z non ferma il pannello.**
  - In Neovim Ctrl-z sospende il programma e ridà il terminale alla shell. Nel pannello di «Rifallo tu» la shell non c'è, perché dattilo parte da `pane.split` con `argv`. Il pannello resterebbe fermo, e lì nessuna guida può parlare.
  - Nelle lezioni guidate ‹Ctrl-z› ha una mappa (in NORMAL, INSERT e VISUAL, e, cambiato costruendo, con un operatore in attesa, dove prima annulla l'operatore) che non sospende e scrive in «Controllo» la frase della 3.4.
  - Visto in tmux (24/11): da una shell, ‹d› e poi ‹Ctrl-z› fermava dattilo anche con la mappa in NORMAL, perché con un operatore in attesa valgono le mappe di quel modo; ora non più. Nella riga dei comandi ‹Ctrl-z› fa il completamento, e non ferma niente. Quando Neovim è il comando stesso del pannello, senza una shell davanti, ‹Ctrl-z› non lo ferma nemmeno senza mappa (il sistema scarta il segnale): il rischio vero è dattilo lanciato da una shell.
  - Non è un filtro. È una mappa, come quella delle frecce di oggi (lezione.lua:309-311), ed è l'unico tasto di Vim che cambia.
  - *Prova:*
    - nel figlio, la mappa c'è e scrive la frase;
    - in tmux il processo non resta fermo (stato `T`);
    - in Herdr: non verificato.
- **G10. Le frecce.**
  - In Batti restano spente come oggi (lezione.lua:309-311), perché dattilo insegna ‹h› ‹j› ‹k› ‹l›.
  - La guida dice la frase intera (3.4, riga 13) ogni volta che una freccia viene premuta.
  - **Scelta mia.** È il modo in cui dattilo insegna i movimenti, e Andrea vuole Vim vero. Se preferisce le frecce accese, basta togliere quella mappa solo con la guida accesa.
  - *Prova:* nel figlio, ‹Up› in Batti dà la frase; poi ‹Esc› e ‹k› fanno salire il cursore.
- **G11. I caratteri che non sono sulla tastiera.**
  - Il prossimo carattere da battere può non essere ASCII e non essere fra quelli della tastiera italiana (àèéìòùç°£§€). In quel caso «Adesso» dice come si scrive in Vim:
    - il digramma, se Neovim ne ha uno (`digraph_getlist(true)`): ‹Ctrl-k› e due tasti;
    - altrimenti ‹Ctrl-v› ‹u› e il codice, oppure ‹Ctrl-v› ‹U› e otto cifre sopra U+FFFF.
  - *Prova:* `guida.carattere('«')` dà ‹Ctrl-k› ‹<› ‹<›. Così anche `'…'` (‹,› ‹.›), `'→'` (‹-› ‹>›) e `'★'` (‹*› ‹2›), tutti verificati in Neovim 0.12.6. `'🙂'` non ha digramma, e dà ‹Ctrl-v› ‹U› ‹0› ‹0› ‹0› ‹1› ‹F› ‹6› ‹4› ‹2›. Nel figlio, premere quei tasti scrive il carattere senza rosso.
- **G12. La Modifica senza fretta (tempo B).**
  - Niente par né stelle. La guida mostra quanti tasti sono stati premuti e quanti ne usa la soluzione suggerita, con «è un conto, non un voto».
  - Prima vengono la consegna e il suggerimento a parole.
  - I tasti esatti, uno alla volta e con cosa fanno, compaiono in due casi: dopo 15 s senza tasti, oppure quando i tasti premuti superano il doppio di quelli della soluzione (la regola di oggi, esercizio.lua:45).
  - *Prova:* nel figlio, su una Modifica:
    - subito si vede «A parole»;
    - dopo 15 s fermi (con un orologio finto) si vedono i tasti;
    - seguendoli uno per uno, la modifica è fatta;
    - nessun testo contiene «par» né ★.

### 3.2 Dove dattilo oggi dà Vim per scontato

Ho riletto tutto il percorso di una lezione: briefing, batti, salvataggio, esegui, spiegazione, riepilogo, elenco. Per ogni punto la tabella dice cosa dice oggi la guida lì, cosa manca perché basti a chi non sa niente, e la frase della guida in «Rifallo tu». Le frasi lunghe sono nella 3.3 col loro nome.

| # | Dove | Cosa dice oggi | Cosa manca | In «Rifallo tu» |
|---|---|---|---|---|
| 1 | Briefing, lezione.lua:97-104 | In fondo al testo: «‹Invio› inizia ‹v› apre il video… ‹q› torna alla home» | È una riga muta in fondo alla pagina. Non dice cosa succede dopo ‹Invio›. ‹q› porta alla home, che in «Rifallo tu» non c'è. | Riquadro con `briefing`: «‹Invio›: apri il codice da riscrivere…» più i `comandi_testo`. ‹q› porta all'elenco (home.lua:117 rimanda lì). |
| 2 | Batti prima di scrivere, lezione.lua:145-146 | Avviso «NORMAL»: «Sei in NORMAL: qui i tasti sono comandi, non lettere. Premi ‹i› per entrare in INSERT…» | Usa NORMAL e INSERT senza dire dove si vedono. Non dice cosa succede dopo. | `batti_vuoto`: «‹i›: entri in scrittura. In basso a sinistra NORMAL diventa INSERT…» |
| 3 | Frecce, lezione.lua:118-123 e 309-311 | «Le frecce qui non valgono: ti muovi con ‹h› ‹j› ‹k› ‹l›…» | Non dice quale lettera va dove. L'avviso sparisce al primo movimento (lezione.lua:302-303). | `frecce` (3.4, riga 13): ogni lettera con la sua direzione e ‹A› per tornare a scrivere. In INSERT comincia da ‹Esc›; in NORMAL, dove ‹Esc› non fa niente, comincia da ‹A› (`frecce_n`), e fatta la mossa la frase se ne va. |
| 4 | Riga non finita, lezione.lua:136-144 | «La riga 4 non è finita. ‹Backspace› a inizio riga la riunisce a quella sopra; oppure ‹Esc›, sali con ‹k›, poi ‹A›…» | Dà due strade senza dire quale vale. Non dice che, dopo l'‹Invio› di dattilo, ‹Backspace› va premuto più volte: prima toglie il rientro, poi riunisce. «Sali con ‹k›» da lontano vuol dire molte ‹k›. | Quattro casi: `batti_spezzata` (‹Backspace› premuto N volte, contate); `batti_spezzata_meta`, quando l'a capo è arrivato a metà di quello che si era scritto e la coda è scesa nella riga dopo (le stesse ‹Backspace› contate riuniscono la riga, e la frase dice che il cursore torna nel punto della spaccatura); `batti_indietro` (‹4› ‹G› poi ‹A›), o `batti_continua` quando quella riga è intera ed è solo l'ultima scritta; il rosso con `batti_errore`. |
| 5 | Avvisi NORMAL e sezione «Vim», lezione.lua:145-148 e 188-190 | «‹h› ‹j› ‹k› ‹l› ti spostano, ‹i› torna a scrivere, ‹x› cancella…»; «Per spostarti: ‹Esc›, poi ‹h› ‹j› ‹k› ‹l›, poi ‹i›» | ‹i› dopo ‹Esc› scrive prima dell'ultima lettera, e il carattere dopo diventa rosso. La sezione «Vim» ha priorità 0, quindi è la prima a sparire. | `batti_riprendi`: «‹A›: torni a scrivere in fondo a questa riga…». Se il testo è cambiato in NORMAL, `batti_cambiato` con ‹u›; se un ‹u› di troppo ha annullato del testo scritto, `batti_annullato` con ‹g› ‹+›, che lo rimette (un altro ‹u› ne toglierebbe ancora). |
| 6 | Finire, lezione.lua:125-131 | «Ora ‹Esc› per tornare in NORMAL», poi «Salva ed esegui: scrivi ‹:w› e premi ‹Invio›. dattilo lancia node.» | Non dice come si fa ‹:›. Dice «esegui» mentre node controlla e basta. Non dice cosa viene dopo. | `batti_finito_i` e `batti_finito_n`; nella riga dei comandi, `cmd_w`. |
| 7 | Salvataggio, lezione.lua:217-229 e compila.lua:151-182 | Esito su più righe nella riga dei messaggi | È su più righe, quindi Neovim chiede «Press ENTER» (in inglese, con `LANG=en_US`), e lo schermo si blocca. | Tutto in «Controllo»: `controllo_ok`, `controllo_mancano`, `controllo_rosso`, `controllo_ko` (G5). |
| 8 | Batti senza Modifica, lezione.lua:259-265 e 207-208 | Dopo Batti c'è il passo «esegui»: «Ora ‹:w›: dattilo salva ed esegue il codice.» | Chiede un secondo ‹:w› senza motivo: il codice è già stato controllato. | Con la guida, se il testo finale è uguale al codice di Batti, il passo «esegui» si salta e si va alla spiegazione. Vale anche nel tempo B, dove l'obiettivo è il codice di Batti. |
| 9 | Spiegazione e riepilogo, lezione.lua:446-454 e 502-511 | «‹Invio› continua ‹q› torna alla home» come testo virtuale dopo l'ultima riga del codice | Con 30 righe di codice in un pannello mezzo schermo, la riga è fuori dalla vista. Gli altri tasti fanno cose di Vim (‹v› seleziona, ‹:› comandi) senza che niente lo dica. | Riquadro con `spiegazione` e, nel riepilogo di `vivo`, `fatto_coda` o `fatto_vuota`. I posti sbagliati sono coperti dalla 3.4. |
| 10 | Uscita, init.lua:4-14 e lezione.lua:307-308 | Niente a schermo. `:q`, `:wq`, `:x`, `ZZ` e `ZQ` portano alla home, e dalla home `:q` chiude. | I comandi non sono mai scritti. `:q` nella finestra dell'aiuto butta fuori dalla lezione. | «Comandi» in ogni schermata (G6). `:q` chiude il posto dove sei (G7). |
| 11 | Elenco, home.lua:180 e 192-201 | «‹j› ‹k› muovi ‹Invio› apri ‹q› indietro». ‹G› e ‹gg› ci sono ma non sono scritti. | Non dice quale lettera va su e quale giù. | L'elenco di `vivo` con `elenco`: «‹j›: scendi di una lezione; ‹k›: sali…» |
| 12 | Mouse, init.lua:37 (`mouse = 'a'`) | Niente | Trascinare o fare doppio clic apre VISUAL senza che niente lo dica. Il tasto centrale incolla. | Trascinare apre VISUAL, e la guida lo dice (3.4, riga 1). Il clic che sposta il cursore è come le frecce di Vim: la guida ricalcola «Adesso». Un clic a metà di quello che si è scritto dà ‹Fine›; un clic a metà di una riga intera, con un'altra da finire, porta subito a quella. |
| 13 | Caratteri speciali | Niente | I digrammi di Vim ci sono (verificati: « » … — – ’ “ ” × → ★), ma nessuno li dice. | `batti_carattere` (G11), che dice anche le lettere maiuscole fra i tasti («E maiuscola», come per la G). |
| 14 | Ctrl-C | Niente. In INSERT esce dalla scrittura (provato: `ModeChanged i:n`). | Niente dice che si è usciti. | «Adesso» torna a dire come rientrare: `batti_riprendi` o `batti_indietro`. |

**Cosa c'è già e si riusa.**
- Il «motore» della battitura (batti.lua): grigio, rosso, metriche e Invio col rientro.
- Il riquadro a sezioni con priorità (ui.lua:97-226).
- Le sezioni «Riga», «Blocco» e «Fin qui» di `lezione.tip_batti` (lezione.lua:156-192). La guida le prende da lì e toglie l'avviso su Vim e la sezione «Vim», che sostituisce con «Adesso».
- Le note della spiegazione (`lezione.note_spiegazione`, lezione.lua:390).
- Il controllo (compila.lua, `M.lancia`).
- La Modifica con la finestra OBIETTIVO e il conto dei tasti (esercizio.lua), nel tempo B.

### 3.3 Le frasi della guida, schermata per schermata

Tutte le frasi stanno in un modulo solo, `lua/dattilo/guida_testi.lua`, col nome scritto qui fra parentesi: le prove le confrontano da lì. `%d` e `%s` sono i valori del momento.

**Titoli del riquadro.**

| Schermata | Titolo |
|---|---|
| Briefing | `COMINCIA · <breve>` |
| Batti | quello di oggi (`RIGA 3 · blocco 1 di 2: Pulizia`), con davanti `SCRIVI · ` |
| Batti finito | `FINITO · <N> righe scritte` |
| Controllo che non passa | `IL CONTROLLO NON PASSA`, bordo rosso |
| Modifica (tempo B) | `RIFAI LA MODIFICA DI CLAUDE` |
| Spiegazione | `CAPISCI · <breve>` |
| Riepilogo | `FATTO · <breve>` |
| Elenco | `LE LEZIONI DI RIFALLO TU` |
| Attesa | `ASPETTO CLAUDE` |
| Posti sbagliati | quelli della 3.4, bordo rosso |

**«Adesso» in Batti** (`guida.adesso_batti`). `r` è la riga del cursore, `c` la sua colonna. `k` è la prima riga del buffer diversa dal grigio; se le righe del buffer sono tutte uguali al grigio ma sono meno, `k` è l'ultima, perché lì si continua. Vale il primo caso che si applica, dall'alto. Prima di tutti vengono i posti sbagliati della 3.4. L'ordine e alcune frasi sono cambiati costruendo, per non far perdere testo buono e non lasciare ferma la persona: l'elenco è in fondo, in «Cambiato costruendo (24/11)».

*In INSERT:*

| Caso | Nome | Frase |
|---|---|---|
| Una freccia appena premuta | `frecce` | 3.4, riga 13 |
| Tutto uguale al grigio | `batti_finito_i` | Hai scritto tutto. ‹Esc›: smetti di scrivere (in basso torna NORMAL). Poi ‹:w› ‹Invio›: salvi e node controlla il codice. |
| `k = r-1`, il cursore è nel rientro della riga `r` e quello che ha a destra, messo in fondo alla riga `k`, è ancora l'inizio giusto del grigio (un a capo a metà di quello che si era scritto) | `batti_spezzata_meta` | La riga %d è stata spezzata in due da un a capo. ‹Backspace›: premilo %s e la riga %d torna intera, col cursore nel punto dove si era spezzata; poi ‹Fine›: vai in fondo alla riga e continua a scrivere. |
| Cursore non in fondo alla riga `r`, la riga `r` è uguale al grigio e `k ≠ r` | `batti_indietro_i` o `batti_continua_i` | come nelle righe `k ≠ r` qui sotto: si va subito alla riga da finire |
| Cursore non in fondo a quello che si è scritto | `batti_cursore` | Il cursore non è in fondo a quello che hai scritto. ‹Fine›: lo porta in fondo alla riga; poi continua. |
| Rosso sulla riga `r` e la lettera rossa è la maiuscola di quella grigia | `batti_maiuscole` | Il rosso è in MAIUSCOLO dove il grigio è minuscolo: forse è acceso il Bloc Maiusc. Spegnilo; poi ‹Backspace›: cancella le lettere rosse. |
| Rosso sulla riga `r` | `batti_errore` | Il rosso è un errore. ‹Backspace›: cancella l'ultima lettera; premilo finché il rosso sparisce, poi riscrivi giusto. |
| `k = r-1` e la riga `r` ha solo il rientro | `batti_spezzata` | La riga %d è stata spezzata da un a capo arrivato troppo presto. ‹Backspace›: premilo %s e torni in fondo alla riga %d; poi continua a scrivere. |
| `k ≠ r` (sopra o sotto) e la riga `k` non è finita | `batti_indietro_i` | La riga %d non è finita. ‹Esc›: smetti di scrivere; poi ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga. |
| `k ≠ r` e la riga `k` è intera (è l'ultima scritta) | `batti_continua_i` | Fin qui è tutto giusto: si va avanti dalla fine della riga %d, l'ultima che hai scritto. ‹Esc›: smetti di scrivere; poi ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga. |
| Il prossimo carattere non è sulla tastiera | `batti_carattere` | Il prossimo carattere, %s, non è sulla tastiera. %s: lo scrive (tieni premuto Ctrl e premi la lettera, poi gli altri tasti%s). |
| Riga `r` uguale al grigio e quella dopo vuota | `batti_riga_vuota` | Riga finita. ‹Invio› ‹Invio›: vai a capo due volte, perché nel grigio la riga dopo è vuota. |
| Riga `r` uguale al grigio | `batti_fine_riga` | Riga finita. ‹Invio›: vai a capo; gli spazi all'inizio della riga dopo li mette dattilo. |
| Altrimenti | `batti_scrivi` | Scrivi il testo grigio, uguale, lettera per lettera. ‹Backspace›: cancella l'ultima lettera. |

*In NORMAL:*

| Caso | Nome | Frase |
|---|---|---|
| Le righe sono diverse da quelle dell'ultima uscita dalla scrittura (o dell'ultimo cambio fatto da dattilo, come la bozza rimessa), e la storia degli annullamenti è più indietro di allora (un ‹u› di troppo) | `batti_annullato` | Hai annullato del testo che avevi scritto (in NORMAL il tasto u annulla). ‹g› ‹+›: lo rimette; ripetilo finché questa frase non cambia. |
| Le righe sono diverse da quelle dell'ultima uscita dalla scrittura | `batti_cambiato` | Il testo è cambiato mentre eri in NORMAL, dove le lettere sono comandi. ‹u›: annulla l'ultimo cambio; premilo più volte per tornare più indietro. |
| Niente scritto | `batti_vuoto` | ‹i›: entri in scrittura. In basso a sinistra NORMAL diventa INSERT, e da lì ogni tasto che premi scrive sopra il grigio. |
| Una freccia appena premuta | `frecce_n` | 3.4, riga 13, la frase di NORMAL |
| Tutto uguale al grigio | `batti_finito_n` | ‹:w› ‹Invio›: salvi e node controlla il codice. I due punti si fanno con Maiusc e il tasto del punto; il comando compare in fondo allo schermo. |
| Rosso sulla riga del cursore | `batti_rosso_qui` | C'è del rosso in questa riga. ‹A›: scrivi in fondo alla riga; poi ‹Backspace›: cancella fino al rosso, e riscrivi giusto. |
| Rosso alla riga `e`, un'altra | `batti_rosso_n` | C'è del rosso alla riga %d. ‹%d› ‹G›: vai alla riga %d; poi ‹A›: scrivi in fondo alla riga; poi ‹Backspace›: cancella fino al rosso, e riscrivi giusto. |
| `k ≠ r` e la riga `k` non è finita | `batti_indietro_n` | La riga %d non è finita. ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga. |
| `k ≠ r` e la riga `k` è intera | `batti_continua_n` | Fin qui è tutto giusto: si va avanti dalla fine della riga %d, l'ultima che hai scritto. ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga. |
| `k = r` | `batti_riprendi` | ‹A›: torni a scrivere in fondo a questa riga. (Non i: scriverebbe prima dell'ultima lettera.) |

In `batti_spezzata` le volte sono `ceil(rientro / 4) + 1`; in `batti_spezzata_meta` sono `ceil(c / 4) + 1`, contate dalla colonna del cursore. Si scrivono «una volta» o «N volte» (`una_volta`, `volte`). Il buffer ha `softtabstop=4` (batti.lua:12), quindi ogni ‹Backspace› toglie fino a 4 spazi del rientro, e l'ultimo riunisce le righe.

In `batti_carattere` il terzo `%s` dice le lettere maiuscole fra i tasti, come la G di ‹%d› ‹G›: «; E maiuscola» (`maiuscola`) o «; O e K maiuscole» (`maiuscole`), oppure niente. Le cifre dopo ‹Ctrl-v› ‹u› valgono anche minuscole, e non si dicono.

Con la guida la nota «Riga vuota: … ‹Invio› e vai avanti.» di `lezione.tip_batti` non si mostra: dice ‹Invio› senza dire cosa fa (G3), e sulla riga vuota «Adesso» dice già cosa premere.

**«Adesso» nelle altre schermate.**

| Schermata | Nome | Frase |
|---|---|---|
| Briefing | `briefing` | ‹Invio›: apri il codice da riscrivere. Prima, se vuoi, leggi qui sotto cosa ha fatto Claude: non c'è fretta. |
| Riga dei comandi con `w` | `cmd_w` | ‹Invio›: esegui :w, cioè salvi e node controlla il codice. |
| Controllo che non passa, in Batti | `controllo_ko` | Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l'errore non è tuo. ‹:salta› ‹Invio›: passi alla prossima lezione. |
| Lo stesso, in INSERT | `controllo_ko_i` | Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l'errore non è tuo. ‹Esc›: smetti di scrivere; poi ‹:salta› ‹Invio›: passi alla prossima lezione. |
| Passo esegui (tempo B), in INSERT | `batti_finito_i` | come in Batti |
| Passo esegui, in NORMAL | `batti_finito_n` | come in Batti |
| Passo esegui, node rifiuta il codice della modifica | `esegui_ko` | Il codice è quello della modifica di Claude, quindi l'errore non è tuo. ‹:salta› ‹Invio›: passi alla prossima lezione. |
| Passo esegui, node rifiuta un codice cambiato dopo la modifica | `esegui_cambiato` | Il codice non è più quello della modifica di Claude. ‹:e!› ‹Invio›: lo rimetti com'era; poi ‹:w› ‹Invio›: lo ricontrolli. |
| Spiegazione | `spiegazione` | Leggi le note accanto alle righe. ‹Invio›: vai al riepilogo. ‹j›: scendi e ‹k›: sali, se il codice non sta tutto nello schermo. |
| Riepilogo, con coda | `fatto_coda` | ‹Invio›: apri la prossima lezione, “%s”%s. |
| Riepilogo, senza coda | `fatto_vuota` | ‹Invio›: aspetti la prossima modifica di Claude; la lezione si apre da sola. |
| Elenco | `elenco` | ‹j›: scendi di una lezione; ‹k›: sali (vanno anche le frecce). ‹Invio›: apri la lezione col ▸. |
| Attesa | `attesa` | Niente da premere: appena Claude cambia una funzione JavaScript, la lezione si apre da sola. |
| Attesa, sessione finita | `attesa_finita` | La sessione di Claude è finita: non arrivano altre lezioni. ‹:elenco› ‹Invio›: vedi quelle che ci sono. |

In `fatto_coda` il secondo `%s` è « (2 nuove)» quando ce ne sono, altrimenti niente.

**«Controllo».**

| Nome | Frase |
|---|---|
| `controllo_ok` | Node ha controllato il codice: sta in piedi. |
| `controllo_mancano` | Salvato, ma il testo non è ancora uguale al grigio: mancano %d caratteri. Il controllo parte quando è uguale. |
| `controllo_rosso` | Salvato, ma c'è del rosso: il controllo parte quando il testo è uguale al grigio. |
| `controllo_errore` | Node non accetta il codice: %s. (fuori da Batti; in Batti il titolo è IL CONTROLLO NON PASSA e la frase sta in «Adesso») |
| `controllo_muto` | il controllo non è riuscito (il `%s` delle frasi qui sopra, quando node non dice niente) |
| `ripreso` | Ripreso: qui c'è il testo che avevi scritto l'altra volta. |
| `non_si_apre` | Questa lezione non si apre: %s. |
| `errore_dattilo` | Errore di dattilo: %s. Il tuo testo è salvato. |
| `ctrl_z` | Ctrl-z in Neovim mette in pausa il programma, e il pannello resterebbe fermo: qui è spento. Continua da dove eri. |

**«Comandi».**

| Dove | Nome | Testo |
|---|---|---|
| Batti | `comandi_batti` | ‹:w› ‹Invio›: salvi e node controlla · ‹:q› ‹Invio›: lasci la lezione, resta salvata · ‹:salta› ‹Invio›: passi alla prossima · ‹:ultima› ‹Invio›: vai all'ultima modifica di Claude |
| Briefing, spiegazione | `comandi_testo` | ‹q›: vai all'elenco delle lezioni · ‹:salta› ‹Invio›: passi alla prossima · ‹:ultima› ‹Invio›: vai all'ultima modifica di Claude |
| Modifica | `comandi_modifica` | ‹:e!› ‹Invio›: ricominci la modifica da capo · ‹:q› ‹Invio›: lasci la lezione · ‹:salta› ‹Invio›: passi alla prossima |
| Riepilogo | `comandi_fatto` | ‹r›: rifai questa lezione · ‹q›: vai all'elenco delle lezioni · ‹:ultima› ‹Invio›: vai all'ultima modifica di Claude |
| Elenco | `comandi_elenco` | ‹:ultima› ‹Invio›: apri l'ultima modifica di Claude · ‹:q› ‹Invio›: chiudi dattilo (quello che hai scritto resta, e «Rifallo tu» lo riapre) |
| Attesa | `comandi_attesa` | ‹:elenco› ‹Invio›: vedi le lezioni già arrivate · ‹:q› ‹Invio›: chiudi dattilo |

**Modifica (tempo B).**

| Caso | Nome | Frase |
|---|---|---|
| Sezione «Consegna» | — | la `consegna` della lezione |
| NORMAL, prima dei tasti | `mod_parole` | Sei in NORMAL: qui i tasti spostano il cursore e cambiano il testo. A parole: %s Se ti blocchi, fra 15 secondi senza tasti qui compaiono i tasti esatti, uno alla volta. |
| Tasti mostrati, il prossimo | `mod_tasto` | %s: %s. |
| Sezione «Tasti», mentre si va | `mod_lista` | ✓ ‹2G›: va alla riga 2 · ▸ ‹$›: va in fondo alla riga · ‹i›: entra in scrittura… (uno per pezzo, ✓ i fatti, ▸ il prossimo) |
| Tasti diversi da quelli suggeriti | `mod_altri` | Hai premuto tasti diversi da quelli suggeriti: va bene, se il testo arriva all'obiettivo. ‹:e!› ‹Invio›: ricominci la modifica da capo, se vuoi ripartire dai tasti suggeriti. |
| INSERT, testo uguale all'obiettivo | `mod_uguale` | Il testo è uguale all'obiettivo. ‹Esc›: smetti di scrivere, e la modifica è fatta. |
| Fatta («Controllo») | `mod_fatta` | Fatto: è uguale alla modifica di Claude. Tasti premuti: %d; la soluzione suggerita ne usa %d. È un conto, non un voto. |

### 3.4 I posti sbagliati

Per ogni posto ci sono: come ci si arriva, come se ne accorge dattilo, il titolo del riquadro e la frase di «Adesso». Gli eventi della colonna «Come se ne accorge» li ho provati tutti nel Neovim figlio (appendice).

| # | Posto | Come ci si arriva | Come se ne accorge | Titolo | Frase |
|---|---|---|---|---|---|
| 1 | VISUAL | ‹v›, ‹V›, ‹Ctrl-v›, trascinare o doppio clic col mouse, ‹g› ‹h› | `ModeChanged` verso `v`, `V`, `^V`, `s`, `S`, `^S` | SEI IN VISUAL: SELEZIONE | Hai selezionato del testo (con il tasto v o col mouse). ‹Esc›: togli la selezione e torni in NORMAL. |
| 2 | Riga dei comandi, vuota | ‹:› | `ModeChanged` verso `c`, `getcmdtype() == ':'`, `CmdlineChanged` | RIGA DEI COMANDI | ‹Esc›: annulli e torni dov'eri. Se volevi salvare: ‹w› ‹Invio›: salvi e node controlla. Dove `:w` non salva niente (le schermate di testo, l'elenco, l'attesa: «Comandi» non lo elenca), `cmd_vuota_testo`: ‹Esc›: annulli e torni dov'eri. I comandi che valgono qui sono in «Comandi», qui sotto. |
| 3 | Riga dei comandi, un comando noto | `:w`, `:q`, `:salta`, `:ultima`, `:elenco`, `:e!`, quando «Comandi» li elenca ed esistono già (`:salta`, `:ultima` ed `:elenco` arrivano col compito 8); `:q`, `:q!`, `:wq` e `:x` (tutti `DattiloEsci`) valgono sempre | come sopra, `getcmdline()` | RIGA DEI COMANDI | ‹Invio›: esegui :%s, cioè %s. ‹Esc›: annulli e torni dov'eri. (per `w` è `cmd_w`) |
| 3b | Riga dei comandi, a metà di un comando noto | `:sa` di `:salta` | come sopra | RIGA DEI COMANDI | `cmd_parziale`: Stai scrivendo il comando :%s. %s ‹Esc›: annulli e torni dov'eri. Il secondo `%s` è un `cmd_finisci` per ogni comando che comincia così: %s: finisci di scrivere :%s; poi ‹Invio›: %s. (per esempio «‹l› ‹t› ‹a›: finisci di scrivere :salta; poi ‹Invio›: passi alla prossima lezione.») |
| 4 | Riga dei comandi, un comando che dattilo non conosce | ‹:› e altro | come sopra | RIGA DEI COMANDI | In fondo c'è il comando «:%s», che qui non serve. ‹Esc›: lo cancelli e torni dov'eri. |
| 5 | Ricerca | ‹/›, ‹?› | `getcmdtype()` è `/` o `?` | RICERCA | Stai scrivendo una ricerca (la apre il tasto /). ‹Esc›: la cancelli e torni dov'eri. |
| 6 | Finestra dei comandi già scritti | ‹q› ‹:›, ‹q› ‹/› | `CmdwinEnter` | FINESTRA DEI COMANDI | Si è aperta la finestra dei comandi già scritti (la apre q seguito dai due punti). ‹Ctrl-c›: la chiude e torni alla riga dei comandi; poi ‹Esc›: torni dov'eri. |
| 7 | Registrazione di una macro, in NORMAL | ‹q› e una lettera | `RecordingEnter`, `reg_recording()` | STAI REGISTRANDO (@%s) | Stai registrando i tasti in una macro (l'ha aperta q seguito da %s). ‹q›: ferma la registrazione; il testo non cambia. |
| 8 | Registrazione, mentre si scrive | come sopra, poi ‹i› | come sopra, con modo `i` | STAI REGISTRANDO (@%s) | Stai registrando i tasti in una macro. ‹Esc›: smetti di scrivere; poi ‹q›: ferma la registrazione. (anche in REPLACE; negli altri modi, come VISUAL, prima viene la frase del modo, e uscito da quello la registrazione) |
| 9 | REPLACE | ‹R›, il tasto ‹Ins› mentre si scrive | `ModeChanged` verso `R`, `Rv`, `Rx`, `Rc` | SEI IN REPLACE | Ogni tasto scrive sopra la lettera che c'è (l'ha aperto R o il tasto Ins). ‹Ins›: torni a scrivere normale, in INSERT. |
| 10 | Operatore in attesa | ‹d›, ‹c›, ‹y›, ‹>›… | `ModeChanged` verso `no…`, `v:operator` | NEOVIM ASPETTA | Hai premuto %s: Neovim aspetta di sapere su che pezzo di testo agire. ‹Esc›: annulli, e il testo non cambia. |
| 11 | Un comando solo da INSERT | ‹Ctrl-o› | `ModeChanged` verso `niI`, `niR` | UN COMANDO SOLO | Hai premuto Ctrl-o: Neovim aspetta un solo comando e poi torna a scrivere. ‹Esc›: torni subito a scrivere. |
| 12 | Finestra in più, col cursore dentro | ‹Ctrl-w› ‹s›/‹v›/‹n›, `:split`, ‹F1›, `:help`, ‹K› | `WinNew`, `WinEnter`: la finestra non è la principale, il riquadro, l'OBIETTIVO o una galleggiante | FINESTRA IN PIÙ | Aiuto (`buftype=help`): Si è aperto l'aiuto di Neovim, in inglese (l'apre il tasto F1). ‹:q› ‹Invio›: lo chiudi e torni al codice. Altrimenti: Lo schermo si è diviso in due (l'ha fatto Ctrl-w o un comando come :split). ‹:q› ‹Invio›: chiudi questa finestra e torni al codice. (Cambiato costruendo: in INSERT ‹:› è una lettera, e la frase è `divisa_i`, che comincia da ‹Esc›. In una finestra in più «Comandi» è solo `comandi_finestra`: ‹:q› ‹Invio›: chiudi questa finestra e torni al codice; ‹:w› nell'aiuto darebbe un errore e ‹q› registrerebbe una macro. Nel compito 5, prima che `:q` chiudesse solo la finestra, la frase era ‹Ctrl-w› ‹c›.) |
| 12b | Finestra in più, col cursore nella finestra della lezione | come sopra, poi un clic | come sopra | FINESTRA IN PIÙ | Lo schermo si è diviso in due. ‹Ctrl-w› ‹o›: resta solo la finestra del codice; il riquadro torna da solo. |
| 13 | Freccia in Batti | ‹↑› ‹↓› ‹←› ‹→› | la mappa di oggi (lezione.lua:309-311) mette `s.frecce`; un movimento o un cambio di modo lo toglie | LE FRECCE SONO SPENTE | In INSERT (`frecce`): Le frecce qui sono spente apposta: dattilo insegna i tasti di Vim. ‹Esc›: smetti di scrivere; poi ‹h›: sinistra, ‹j›: giù, ‹k›: su, ‹l›: destra; poi ‹A›: torni a scrivere in fondo alla riga. In NORMAL (`frecce_n`), dove ‹Esc› non fa niente: Le frecce qui sono spente apposta: dattilo insegna i tasti di Vim. ‹A›: torni a scrivere in fondo alla riga. Per spostarti, in NORMAL: ‹h›: sinistra, ‹j›: giù, ‹k›: su, ‹l›: destra. |
| 14 | Ctrl-z | ‹Ctrl-z› | la mappa di G9 | (resta quello della schermata) | `ctrl_z`, in «Controllo» |
| 15 | Modalità Ex | ‹g› ‹Q› | `ModeChanged` verso `cv`, `ce` | MODALITÀ EX | Sei nella modalità Ex (l'apre g seguito da Q). ‹v› ‹i› ‹s› ‹u› ‹a› ‹l› ‹Invio›: torni allo schermo normale (scrivi visual, poi Invio). In Ex anche `getcmdtype()` dà `:`: il controllo di Ex viene prima di quello della riga dei comandi. |
| 16 | Ogni altro modo | per esempio `:terminal` | `ModeChanged` verso un modo che non è qui sopra | POSTO SCONOSCIUTO (in un terminale in NORMAL, `nt`: UN TERMINALE, `terminale`: Sei in un terminale dentro Neovim (l'apre il comando :terminal). ‹:b%d› ‹Invio›: torni al codice della lezione, com'era.) | Sei in una modalità di Neovim che la guida non conosce (in basso: %s). ‹Ctrl-\› ‹Ctrl-n›: torni in NORMAL, da qualunque modalità (anche da un terminale, dove Esc non basta). (Cambiato costruendo: tolta la frase «Se il codice non si vede più, ‹:q› ‹Invio›: lasci la lezione, che resta salvata», falsa fino al compito 9. Un altro buffer nella finestra della lezione ha la riga 18.) |
| 17 | «Premi INVIO», «-- Ancora --» | un comando della persona con un'uscita lunga (`:ls`, `:reg`) | non si vede: Neovim non ridisegna niente finché la persona non preme un tasto | — | La riga di Neovim stessa, in italiano: «Premi INVIO o un comando per proseguire». `more` è spento, quindi «-- Ancora --» non compare. Dopo ‹Invio› la guida è di nuovo lì. dattilo non lo fa mai comparire da sé (G5). |
| 18 | Un altro buffer nella finestra della lezione | ‹Ctrl-^›, `:e`, `:bn`, `:enew`, ‹Esc› ‹Ctrl-o› (il salto riporta al briefing), un terminale | `BufEnter`, `BufWinEnter`: nella finestra principale c'è un buffer diverso dall'ultimo messo da `schermo.mostra` (il codice in Batti, il testo della schermata altrove) | UN ALTRO FILE (un terminale in NORMAL: UN TERMINALE, riga 16) | In NORMAL (`altro_buffer`): Qui non c'è il codice della lezione, ma un altro file (ci si arriva con un comando come :e o :bn, o col tasto Ctrl-^). ‹:b%d› ‹Invio›: torni al codice della lezione, com'era. In INSERT (`altro_buffer_i`): Stai scrivendo in un altro file, non nel codice della lezione. ‹Esc›: smetti di scrivere; poi ‹:b%d› ‹Invio›: torni al codice della lezione, com'era. Il `%d` è il numero del buffer del codice. Non è ‹Ctrl-^›, che con due buffer qualunque rimbalza. «Comandi» è solo `comandi_altro`: «‹:b%d› ‹Invio›: torni al codice della lezione, com'era». |

**Le spiegazioni dei comandi noti** (riga 3): `w` «salvi e node controlla il codice»; `q` «lasci la lezione, che resta salvata», ma «chiudi questa finestra e torni al codice» in una finestra in più e «chiudi dattilo; quello che hai scritto resta» nell'elenco e nell'attesa (G7; cambiato costruendo, fino al compito 9: «lasci la lezione e torni all'elenco», con del testo scritto «…; quello che hai scritto qui non si conserva», e «chiudi dattilo» nell'elenco); `qa` (cambiato costruendo) «chiudi dattilo del tutto (qa vuol dire «esci da tutto»)», con del testo scritto «…; quello che hai scritto qui non si conserva»; `salta` «passi alla prossima lezione»; `ultima` «vai all'ultima modifica di Claude»; `elenco` «vedi le lezioni di Rifallo tu»; `e!` «ricominci da capo».

**Perché la riga 12b non dice `:q`.** Nella finestra della lezione `:q` lascia la lezione (G7). ‹Ctrl-w› ‹o› invece chiude tutte le altre finestre. Il riquadro lo riapre la guida, e nel tempo B anche l'OBIETTIVO (5.9).

**Il ridisegno, visto in tmux (24/11).** Senza un `redraw` esplicito, nella riga dei comandi (righe 2-5) e in modalità Ex (riga 15) il riquadro resta quello di prima; con un operatore in attesa (riga 10) Neovim lo ridisegna da solo. Per questo ogni evento della guida ricalcola il riquadro con `vim.schedule` e poi chiama `redraw`: così il riquadro cambia a ogni tasto battuto nella riga dei comandi, e il cursore resta in fondo alla riga dei comandi. Davanti a «Premi INVIO» (modo `r…`, riga 17) il riquadro si aggiorna ma lo schermo non si ridisegna, perché cancellerebbe quello che Neovim sta mostrando: dopo il tasto lo ridisegna Neovim. In modalità Ex il `redraw` toglie dallo schermo la frase di Neovim («Entro modalità Ex. Batti "visual"…»), che il riquadro dice comunque.

---

## 4. Le vie per far arrivare una lezione nuova a un dattilo già aperto

Il punto difficile è questo: dattilo è aperto e la persona sta scrivendo. Arriva una lezione nuova. dattilo deve saperlo («1 nuova»), non deve perdere l'esercizio in corso, e deve aprirla quando la persona lo chiede, anche se la richiesta parte dal mouse in «Dal vivo».

### Via A: pacchetto rigenerato su disco + comando a dattilo con `nvim --remote-expr`

- **Come.** dattilo parte con `--listen <socket>`. La mod, dopo ogni lezione nuova, lancia `nvim --server <socket> --remote-expr "luaeval(...)"`. Il comando svuota la cache dei pacchetti (`pacchetti.dimentica()`, pacchetti.lua:11) e aggiorna il conteggio. Un altro comando apre una lezione.
- **Cosa costa.**
  - Un socket per terminale, con la sua pulizia. Il percorso di un socket Unix ha un tetto di circa 108 byte.
  - Un processo `nvim` per ogni messaggio.
  - In dattilo servono lo stesso: aprire per id, contare le nuove, mostrarle.
- **Cosa rompe.**
  - `--remote-expr` resta appeso finché Neovim mostra «Press ENTER»: lo dice note.md, dove il monitor della gara ha dovuto mettere un tempo massimo di 1,5 s.
  - Oggi dattilo mostra messaggi su più righe proprio a ogni `:w` (compila.lua:152-182). Il blocco cadrebbe proprio quando la persona finisce e arriva la lezione nuova.
  - Il mio tentativo in Neovim senza interfaccia non mostra il «Press ENTER», quindi non prova niente né in un senso né nell'altro.
  - Lo stato starebbe in due posti, mod e dattilo, da tenere allineati con dei messaggi.
- **Cosa chiede a dattilo.** Le funzioni da chiamare da fuori, più la gestione della coda.

### Via B: la cartella è il canale, e dattilo la guarda da solo (scelta)

- **Come.** Tutto passa da file, nella cartella privata del terminale:
  - le lezioni le scrive l'aiutante;
  - `vuoi.json` lo scrive la mod: «apri questa lezione», «vai all'ultima», «Dal vivo è spento»;
  - `stato.json` lo scrive dattilo: quale lezione è aperta, quante nuove, quale viene dopo.

  dattilo controlla ogni 500 ms se `vuoi.json` o la cartella delle lezioni sono cambiati: è un `fs_stat` su due percorsi. La mod rilegge `stato.json` col timer che «Dal vivo» ha già (dalvivo.js:61).
- **Cosa costa.**
  - In dattilo, un modulo nuovo che guarda la cartella e gestisce la coda: lo stesso lavoro della via A, senza la parte remota.
  - Fino a mezzo secondo di ritardo.
- **Cosa rompe.** Niente di quello che c'è. Nessuno aspetta l'altro:
  - se dattilo mostra un messaggio o è occupato, legge i file al giro dopo;
  - se la mod è chiusa, dattilo va avanti con le lezioni che ci sono.
- **Cosa chiede a dattilo.** Il modulo `vivo` della sezione 5.9.
- **Perché è il canale giusto.** È lo stesso schema che «Dal vivo» usa già: hook → file → mod. Si prova senza Herdr: si scrivono file in una cartella e si guarda dattilo. Il socket non serve, e `--listen` resta libero per le statistiche lette da fuori, come nella gara.

### Via C: chiudere e riaprire dattilo a ogni passaggio

- **Come.** Per passare a un'altra lezione la mod uccide il terminale di dattilo e ne apre un altro con `-c 'Lezione rifallo N'`. Il comando `:Lezione` c'è già, ma accetta solo un numero (dattilo/init.lua:24-27).
- **Cosa costa.** Quasi niente in dattilo.
- **Cosa rompe.**
  - Il pannello sparisce e ricompare, e il fuoco salta.
  - «N nuove» si può mostrare solo in Herdr, mentre gli occhi della persona sono su dattilo.
  - A fine lezione la «prossima» di dattilo usa il pacchetto in cache e `L.prossima`, calcolati all'apertura (pacchetti.lua:56, lezione.lua:467): non vede le lezioni arrivate dopo. L'ho provato oggi: dopo aver aggiunto `002-doppio.md`, `pacchetti.lezione("rifallo-t3", 2)` resta `nil` finché non si chiama `dimentica()`.
  - Decidere «la prossima» dalla tastiera, in dattilo, non si potrebbe.

**Scelta: via B.** Il motivo che decide non è il costo, simile per A e B. È il blocco di `--remote-expr` sul «Press ENTER» nel momento peggiore. In B nessuno aspetta l'altro. In più la decisione «passo alla prossima» deve stare nella tastiera della persona, in dattilo, e questo esclude C.

---

## 5. Il disegno, pezzo per pezzo

### 5.1 I pezzi

| Dove | File | Cosa fa |
|---|---|---|
| mod (logica pura) | `rifallo-logica.js` (nuovo) | Estrazione del codice da battere (e, nel tempo B, di quello di prima), testo della lezione, lettura dei campi di Haiku, stato del tasto, testi. Non importa niente: lo caricano mod, aiutante e prove, come `dalvivo-logica.js`. |
| mod (logica pura) | `dalvivo-logica.js` | `leggiPassi` legge le righe nuove `lezione`. `promptHaiku` e `leggiRispostaHaiku` imparano i campi della lezione. `testoAcceso` impara `rifallo`. |
| aiutante | `strumenti/dalvivo-spiega.mjs` | Dopo la risposta di Haiku scrive anche le lezioni, se «Rifallo tu» è acceso. Nel tempo B le passa prima da `dattilo vivo --prova`. |
| strumento | `strumenti/rifallo.mjs` (nuovo) | Le funzioni Node che scrivono le lezioni (le usa l'aiutante), e il comando `node rifallo.mjs apri\|pulisci` per la mod. |
| mod | `rifallo.js` (nuovo) | Rileva dattilo, gestisce il clic su «Rifallo tu», apre il pannello, legge `stato.json`, scrive `vuoi.json`, e c'è la parte di «Rifallo tu» del giro della barra. |
| mod | `dalvivo.js`, `dalvivo-vista.js` | Il tasto nel fumetto, il tasto «N nuove» nella testata, i comandi nuovi in `su`. |
| hook | `installa/hooks/dalvivo.mjs` | **Non cambia.** |
| dattilo | `lua/dattilo/guida.lua`, `lua/dattilo/guida_testi.lua`, `lua/dattilo/vivo.lua` (nuovi), più ritocchi in punti nominati | La guida sempre accesa (guida), le sue frasi (guida_testi), il canale a cartelle, la coda e le schermate di «Rifallo tu» (vivo). Sezione 5.9. |

### 5.2 Le cartelle e i file su disco

Una cartella per terminale seguito: `~/.cache/herdr-pixel/rifallo/<nome>/`. `<nome>` è lo stesso di «Dal vivo», cioè `nomeFile(sessione)` (dalvivo-logica.js:14-19), per esempio `t3`.

```
~/.cache/herdr-pixel/rifallo/            0700
  t3/                                    0700
    indice.json        aiutante/strumento: lezioni, chiavi, passi (sotto lucchetto)
    vuoi.json          mod → dattilo
    stato.json         dattilo → mod
    bozze/<id>.json    dattilo: il testo battuto (0700, file 0600)
    dati/              XDG_DATA_HOME di dattilo per questo terminale
      dattilo/pacchetti/rifallo/pacchetto.json
      dattilo/pacchetti/rifallo/lezioni/001-codicepulito.md …
      dattilo/lavoro/rifallo/<id>/regole.js   (lo scrive dattilo: il file controllato con node --check)
      dattilo/progressi.json                  (lo scrive dattilo)
```

**Perché `XDG_DATA_HOME`.** dattilo prende la cartella dei pacchetti, del lavoro e dei progressi da `progressi.cartella()`, che legge `XDG_DATA_HOME` (progressi.lua:4-5; pacchetti.lua:10). L'ho provato oggi: con `XDG_DATA_HOME=<cartella>/dati`, dattilo vede solo il suo corso C e il pacchetto della cartella, e scrive il lavoro lì dentro. Con questo:
- il codice della persona non finisce in `~/.local/share/dattilo` (cartelle a 755, per sempre);
- i progressi veri di Andrea non si sporcano;
- il pacchetto ha un id fisso, `rifallo`;
- la pulizia è cancellare una cartella.

Il tema e il parser di JavaScript restano, perché dattilo li cerca con `~` e non con XDG (dattilo/init.lua:42-49). La sandbox `bwrap` monta la cartella di lavoro anche se sta nella home (compila.lua:44-45).

**I permessi.** `rifallo.mjs` crea `rifallo/` e `rifallo/<nome>/` con `mkdirSync(…, { recursive: true, mode: 0o700 })` e poi `chmodSync(…, 0o700)` fuori da Windows, come l'hook (dalvivo.mjs:140-142). dattilo crea `bozze/` a 0700, e scrive `stato.json` e le bozze a 0600. Le cartelle che dattilo crea in `dati/` sono a 755, ma stanno dentro una cartella a 700.

**I tre file di scambio** (sempre `v: 1`, sempre scritti in modo atomico: un file temporaneo e poi un cambio di nome).

```json
// indice.json (aiutante e strumento, sotto il lucchetto prendiChiave("<cartella>/indice.json", { attesa: 2000, vecchia: 10000 }))
{"v":1,"seq":4,"lezioni":[{"id":"003-codicepulito","chiave":"server/src/logica/regole.js#codicePulito","file":"/home/a/p/server/src/logica/regole.js","passi":["toolu_01A…","toolu_01C…"],"t":1795443900000}]}

// vuoi.json (mod). `t` = quando è stato chiesto; dattilo esegue una richiesta solo se `t` è più nuovo dell'ultima eseguita.
{"v":1,"t":1795443912000,"azione":"apri","lezione":"003-codicepulito","dalvivo":"acceso"}
//   azione: "apri" (lezione: id) | "ultima"; dalvivo: "acceso" | "spento" | "finita"

// stato.json (dattilo)
{"v":1,"t":1795443913000,"lezione":"003-codicepulito","schermo":"batti","nuove":2,"prossima":"004-nomefile","ultima":"005-azioni","aperte":["001-somma","003-codicepulito"],"fatte":["001-somma"],"saltate":[]}
//   schermo: "briefing" | "batti" | "modifica" | "spiegazione" | "fatto" | "elenco" | "attesa"
```

Quando la mod cambia solo `dalvivo`, riscrive `vuoi.json` tenendo `t`, `azione` e `lezione` dell'ultima richiesta. Così una richiesta non si perde se dattilo non ha ancora fatto il suo giro.

Il file temporaneo delle lezioni non deve finire in `.md`, perché dattilo legge `lezioni/*.md` (pacchetti.lua:40). `scriviAtomico` di comune.mjs usa già `<file>.<pid>`, e va bene.

Il contratto completo, campo per campo, con i casi dei file a metà, rotti o spariti, è nel piano del lato dattilo, sezione «Il contratto con la mod».

**La pulizia.**
- Chiudere dattilo **non** cancella niente. Restano la coda e le bozze, per riprendere.
- La barra lancia `node strumenti/rifallo.mjs pulisci --tranne <nomi>`.
  - `--tranne` elenca le cartelle con un dattilo vivo (un terminale vivo che ha quella cartella nel suo argv), più quella della sessione che «Dal vivo» segue adesso.
  - Lo strumento cancella tutte le altre cartelle sotto `rifallo/`. Non serve aspettare: la sola cartella che può essere appena nata è quella della sessione seguita, ed è sempre in `--tranne`.
- **Quando parte**, cioè mai a ogni giro (`controllaDalVivo` gira ogni 500 ms):
  - una volta sola, quando l'insieme dei «da tenere» perde qualcuno. Per esempio quando «Dal vivo» smette di seguire un terminale che non ha dattilo aperto, o quando si chiude il dattilo di un terminale che «Dal vivo» non segue più. La barra tiene l'insieme del giro prima e lo confronta;
  - una volta all'avvio della barra, ma solo dopo che `terminals()` non è vuoto. Una lista vuota vuol dire «non si sa», come in `sessioneViva` (dalvivo-logica.js:385).
- Una rete di sicurezza: `rifallo.mjs apri` cancella le cartelle di altri terminali ferme da più di 24 ore.

### 5.3 Chi prepara la lezione, e quando

- **L'aiutante** (`strumenti/dalvivo-spiega.mjs`), quando «Rifallo tu» è acceso per quel terminale (`acceso.json` con `rifallo: true`, sezione 5.10). Il giro di `lavora` (dalvivo-spiega.mjs:130-157) diventa:
  1. cerca le parole di Claude, come oggi;
  2. aspetta `PAUSA`, come oggi;
  3. **nuovo:** per i passi recenti senza riga `lezione`, estrae il codice da battere dal file com'è adesso sul disco, e lo controlla con `node --check` (5.4). Nel tempo B estrae anche il codice di prima;
  4. chiama Haiku **una volta**. Per le modifiche con codice da battere, il prompt contiene quel codice e chiede anche i campi della lezione (5.6);
  5. scrive le righe `spiega` come oggi, e **subito dopo** le lezioni e le righe `lezione`. Nel tempo B, prima di dare il nome finale a una lezione con Modifica, lancia `dattilo vivo --prova` sul file temporaneo. Se esce con 1, riscrive la lezione senza Modifica.

  `daFare(passi, adesso, haiku)` (dalvivo-spiega.mjs:78-84) diventa `daFare(passi, adesso, haiku, rifallo)`, e restituisce anche `lezione`: i passi recenti senza riga `lezione` e con un'estensione JavaScript. Il ciclo continua finché c'è qualcosa in una delle tre liste.

  Ogni passo riceve sempre la sua riga `lezione`, pronta oppure «no». Per questo il ciclo finisce.

  Con Haiku spento, o se il passo ha già la sua `spiega` di prima, la lezione si scrive coi testi di base (5.5), senza Modifica.
- **La mod, solo al clic**, per un passo che non ha ancora la lezione. Succede col primo clic, quando «Rifallo tu» era spento e l'aiutante non l'ha preparata, o per un passo vecchio. La mod lancia `node strumenti/rifallo.mjs apri <nome> <id del passo>`, che:
  - prepara la cartella;
  - costruisce la lezione dal disco, coi testi di base e senza Modifica, senza chiamare Haiku;
  - scrive la riga `lezione`;
  - stampa `{"ok":true,"lezione":"003-codicepulito"}` oppure `{"ok":false,"motivo":"…"}`.

  Questa è l'unica lezione fatta senza Haiku quando Haiku è acceso. Rispetta la scelta «nessuna seconda chiamata».
- **L'hook non cambia.** Ci avevo pensato: fargli salvare una copia del file subito dopo la modifica. Però a ogni modifica scriverebbe file in più, e l'hook ha già il vincolo dei 150 ms. La 5.4 spiega come si fa a meno della copia.

### 5.4 Il codice da battere: la regola

**Solo JavaScript, per ora** (scelta confermata da Andrea). Il controllo che fa avanzare una lezione dipende dal linguaggio:
- `controllo` ammette solo `node` (formato.lua:29-38 e 41-51);
- `compila` deve compilare, linkare ed eseguire `./{nome}` (formato.lua:46), e le opzioni del compilatore sono una lista chiusa, senza `-c` né `-fsyntax-only` (formato.lua:8-9).

Una funzione C presa da sola non ha `main`, e spesso usa tipi e macro dichiarati altrove: non linka, e quindi la lezione non finirebbe mai. Per il C bisognerebbe allargare la lista di sicurezza di dattilo con un `controllo` fatto con `cc -fsyntax-only`, e anche così molte funzioni non passerebbero senza i loro header.

**Dove sta la modifica adesso, cioè «l'àncora».** L'aiutante legge il file qualche secondo dopo la modifica. Intanto Claude può averlo cambiato di nuovo, e i numeri di riga di `structuredPatch` possono non valere più. Si cerca quindi il testo, non il numero.
- Si prendono le righe «+» del primo pezzo (tolto il `+`) e si cercano, consecutive, nel file di adesso.
  - Trovate una volta sola: quella è l'àncora.
  - Trovate più volte: si sceglie quella più vicina a `newStart` più le righe di contesto iniziali (`rigaDi`, dalvivo-logica.js:72-78).
- Se il pezzo ha solo righe «-» (Claude ha tolto e basta), si cercano consecutive le righe di contesto subito prima e subito dopo il taglio, e l'àncora è il punto fra le due.
- Se non si trova niente, la lezione per quel passo è «superata»: riga `lezione` con `stato: "no"` e motivo «Claude ha cambiato di nuovo questo punto: rifai il passo dopo».
- Per un file nuovo (`Write` con `oldStart: 0`) l'àncora è tutto il file.
- Con più pezzi (`MultiEdit`, `replace_all`) conta il primo pezzo.

Così la lezione è sempre il codice com'è *adesso*, comprese eventuali modifiche successive alla stessa funzione. Per chi vuole imparare il proprio progetto è il codice giusto.

**L'unità che contiene la modifica.** Un piccolo lettore di JavaScript (`scandisci`) passa il file una volta e, per ogni riga, segna la profondità delle parentesi `( [ {` all'inizio e alla fine. Salta:
- le stringhe `'…'` e `"…"`;
- i template `` `…${…}…` ``, anche annidati;
- i commenti `//` e `/* */`;
- le espressioni regolari.

Una `/` apre un'espressione regolare se il pezzo prima è vuoto, un segno fra `( , = : [ ! & | ? { } ; + - * % < > ~ ^`, oppure una delle parole `return typeof instanceof in of new delete void throw case do else yield await`. Negli altri casi è una divisione. È l'euristica solita: se sbaglia, il controllo finale lo scopre.

- **Unità di primo livello:** comincia su una riga a profondità 0 che non è vuota né solo commento. Finisce alla prima riga che torna a profondità 0 e il cui ultimo carattere di codice non chiede seguito (`= + - * / % & | ^ ! ? : . , ( [ {`), purché la riga dopo non cominci con `. ? : ) ] } + - * / , && ||`.
- **Si prende:** tutte le unità di primo livello toccate dall'àncora, con le righe vuote fra loro. Di solito è una funzione sola, ma può essere anche `const SIMILI = {…}` più la funzione che la usa, come nel caso dei sosia.

**La pulizia del testo** (per non far battere ciò che non è codice):
- si tolgono tutti i commenti (scelta confermata da Andrea). Un commento in mezzo a una riga lascia uno spazio. Le righe che restano vuote spariscono, più righe vuote di fila diventano una, e non ci sono righe vuote in cima o in fondo;
- ogni tab diventa spazi fino al prossimo multiplo di 4. Il buffer di dattilo ha `expandtab` (batti.lua:12): un tab del file non si potrebbe battere;
- si tolgono gli spazi in fondo alle righe e i `\r`.

**Il tetto.**
- Al massimo **30 righe** di codice da battere e **1800 caratteri**. A circa 40 parole al minuto sono 4-5 minuti: abbastanza per stare dietro a Claude.
- Se l'unità supera il tetto si taglia, tenendo sempre pezzi interi:
  1. si tengono la riga che apre l'unità (fino al primo `{` del corpo) e quella che la chiude;
  2. dentro il corpo si trovano i pezzi del livello sotto: istruzioni di una funzione, metodi di una classe, voci di un oggetto. Si riconoscono con la stessa regola, alla profondità del corpo, dove anche `,` e `;` chiudono un pezzo;
  3. si tengono i pezzi toccati dall'àncora, poi quelli vicini, uno prima e uno dopo a turno, finché si sta nel tetto;
  4. ogni serie di pezzi tolti diventa una riga sola, col rientro del primo pezzo tolto: `// ... (12 righe)`. È l'unico commento che resta, in ASCII, così si batte senza fatica;
  5. se il pezzo toccato è da solo più lungo del tetto, si scende di un livello dentro di lui, fino a 3 livelli.
- Se non basta, niente lezione: «questa funzione è troppo lunga (N righe) e non si taglia in un pezzo che stia in piedi da solo».
- Una riga più lunga di **160 caratteri**: niente lezione («righe troppo lunghe da battere»).
- Meno di **2 righe** da battere: niente lezione («modifica troppo piccola»).
- File più grande di **512 KB**: niente lezione.

**Il giudice: `node --check`.**
- Il pezzo finale si scrive in una cartella temporanea nuova, a 0700, sotto `os.tmpdir()`, senza `package.json` intorno, **con lo stesso nome di file che userà dattilo**. Si lancia `node --check <file>` e la cartella si cancella subito dopo.
- Se non passa, niente lezione: «questo pezzo di codice non sta in piedi da solo».
- Prove fatte oggi con Node 26.13.1, in una cartella senza `package.json`, circa 20 ms a controllo:
  - `export function` in un `.js` passa (Node riconosce da solo i moduli);
  - un metodo preso da solo fuori dalla sua classe non passa;
  - `await` al primo livello in un `.js` passa;
  - `import.meta` passa;
  - `require` ed `export` insieme passano;
  - un `export` in un `.cjs` non passa.

  Per questo l'estensione si tiene uguale a quella del file vero.
- Il JSX e le annotazioni di tipo non passano, e quei file restano senza lezione.

**Il nome del file nella lezione.** Il campo `file:` deve essere un nome semplice: `^[%w][%w_%-]*%.(%w+)$`, con estensione `c`, `js`, `mjs` o `cjs` (formato.lua:54 e 219-220).
- Si usa il nome vero se va bene (`regole.js`).
- Altrimenti `codice.<estensione>`: per esempio per `regole.test.mjs` o `[id].js`.
- Il percorso vero va in `fonte`.

**Le righe cambiate.** Durante l'estrazione si tiene una mappa riga della lezione → riga del file. Le righe «cambiate» sono quelle della lezione che corrispondono alle righe «+» trovate con l'àncora. Servono ai blocchi, ai suggerimenti e alle note.

**Il codice di prima (tempo B).** Serve come punto di partenza della Modifica.
- Si prende il codice da battere già estratto, tagliato e pulito, e al posto delle sue righe «cambiate» si rimettono le righe «-» del primo pezzo, pulite allo stesso modo.
- Se dopo la pulizia il codice di prima è uguale a quello di adesso (Claude ha cambiato solo commenti), niente Modifica.
- Un file nuovo non ha un codice di prima: niente Modifica.
- Con più pezzi conta il primo, come per l'àncora: la Modifica rifà il primo pezzo, e l'obiettivo è comunque il codice di adesso.
- **Il tetto della Modifica:** al massimo **8 righe** fra «+» e «-» nel pezzo, altrimenti niente Modifica («la modifica è troppo grande per rifarla coi tasti»). La lezione resta, con Batti e spiegazione.

### 5.5 La lezione su disco

Ogni lezione è un file Markdown nel formato normale di dattilo (formato.lua:201-364). Si può aprire con un dattilo qualunque.

**Come si controlla il formato.** `dattilo controlla` non va bene: chiede un suggerimento su ogni riga non vuota e ogni riga dentro un blocco (`completezza`, controlla.lua:43-64), mentre Haiku ne dà al massimo 12 e i testi di base uno solo. Per controllare il formato si usa `dattilo controlla --tip <cartella>/dati/dattilo/pacchetti/rifallo <id>`, che stampa una riga «✗ …» per ogni errore di formato (cli.lua:133-143). Nel tempo B si usa `dattilo vivo --prova`, che controlla anche i tasti della Modifica (5.9).

**Il nome:** `<NNN>-<nome>.md`.
- `NNN` è `seq` di `indice.json` su tre cifre.
- `<nome>` è il nome della funzione in minuscolo con `[a-z0-9-]`, al massimo 30 caratteri. Se non c'è un nome, `codice`.
- dattilo ordina i file per nome (pacchetti.lua:40-41), quindi l'ordine è quello di arrivo.
- Si apre sempre **per id**, non per numero. L'ho provato oggi: una lezione rotta non entra in `P.lezioni` (pacchetti.lua:44-51), e tutti i numeri dopo di lei scorrono.

Il manifesto, scritto una volta da `rifallo.mjs apri`:

```json
{ "id": "rifallo", "titolo": "Rifallo tu · herdr-pixel", "versione": "0.1.0", "linguaggio": "javascript", "richiede": [],
  "esecuzione": { "tipo": "controllo", "comando": ["node", "--check", "{file}"] } }
```

Un esempio completo, con i testi di Haiku. La parte da `## Modifica` in giù c'è solo nel tempo B.

````markdown
---
titolo: "La tabella dei sosia"
breve: "codicePulito"
etichetta: "Rifallo tu"
file: "regole.js"
fonte: "server/src/logica/regole.js, righe 84-88"
tempo: "circa 1 minuto"
---

## Briefing
codicePulito prende il codice amico scritto dalla persona e lo riduce alla forma che si salva. Claude ci ha aggiunto la correzione dei sosia: O, 0 e U diventano C e V prima del controllo.

## Batti
```js
export function codicePulito(t) {
  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/[O0U]/g, (x) => SIMILI[x]);
  if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
  return `${c.slice(0, 4)}-${c.slice(4)}`;
}
```

### Blocchi
1-2: Pulizia | Mette tutto maiuscolo, toglie quello che non è lettera o cifra e corregge i sosia. | È qui la riga nuova di Claude.
3-5: Controllo e forma | Rifiuta i codici sbagliati e mette il trattino in mezzo. | Quello che c'era già.

### Suggerimenti
2: Riga cambiata da Claude. L'ultimo .replace cambia ogni O, 0 e U con il suo sosia, preso dalla tabella SIMILI.
3: Un codice vero ha 8 simboli dell'alfabeto: se no, null.

## Modifica: Rifai la modifica di Claude
consegna: Alla riga 2, dopo il primo .replace, aggiungi il .replace che corregge i sosia.
aiuto: Vai alla riga 2, mettiti sul punto e virgola finale, entra in scrittura subito prima e scrivi il pezzo nuovo; poi esci dalla scrittura.
motivo: Nel carattere a pixel la C sembra una O: il secondo .replace corregge i sosia prima del controllo.
pos: 1:1
par: 41
soluzione: 2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>
```js partenza
export function codicePulito(t) {
  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");
  if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
  return `${c.slice(0, 4)}-${c.slice(4)}`;
}
```
```js
export function codicePulito(t) {
  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/[O0U]/g, (x) => SIMILI[x]);
  if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
  return `${c.slice(0, 4)}-${c.slice(4)}`;
}
```

### Tasti
- 2G | va alla riga 2
- $ | va in fondo alla riga, sul punto e virgola
- i | entra in scrittura subito prima del punto e virgola
- .replace(/[O0U]/g, (x) => SIMILI[x]) | scrive il pezzo nuovo
- <Esc> | esce dalla scrittura

## Spiegazione
2: Il .replace nuovo usa la tabella dei sosia. | (x) => SIMILI[x] è una funzione freccia.
````

La soluzione dell'esempio l'ho provata oggi nel dattilo di questo ramo, con la stessa chiamata di `controlla` (controlla.lua:27-40). Dal codice di partenza arriva all'obiettivo, e `conta_tasti` dà 41.

**Regole di scrittura** (sono le trappole del formato che ho trovato leggendolo):
- **Intestazione.**
  - Ogni valore va tra virgolette doppie, con `\"` e `\\` (formato.lua:101-108). Un valore che comincia con `[` verrebbe letto come lista (formato.lua:110-113): `fonte: [id]/page.js` darebbe errore.
  - `etichetta` è sempre `"Rifallo tu"`: va nella barra in alto come `Rifallo tu · <breve>` (lezione.lua:24-29).
  - Niente `mosse` né `concetti`.
- **Briefing, suggerimenti, blocchi e note.**
  - Ognuno su una riga sola: gli a capo diventano spazi.
  - Nei blocchi e nelle note ` | ` è il separatore (formato.lua:275 e 330), quindi il ` | ` dei testi diventa ` / `.
  - Una riga di testo che comincia con `parola:` verrebbe presa come campo se la parola è `titolo`, `consegna`, `aiuto`, `par`, `soluzione`, `mostra`, `pos`, `attesa`, `cerca`, `dopo` o `motivo` (formato.lua:149-150 e 179-181). In quel caso i due punti diventano « —».
  - Una riga che comincia con `#` o con un accento grave prende davanti uno spazio.
- **Il recinto del codice** ha un accento grave in più della riga di soli accenti gravi più lunga del codice, e almeno tre. Il codice non può chiuderlo per sbaglio (formato.lua:159-166).
- **Validità.** Una riga dei Blocchi che non si legge fa cadere tutta la lezione (formato.lua:285 e 362), e così un suggerimento su una riga vuota (formato.lua:258). Il generatore scrive solo blocchi e suggerimenti già controllati (5.6).
- **Niente `## Rompi` né `## Uscita`.** `## Modifica` c'è solo nel tempo B, una sola, e solo se `dattilo vivo --prova` l'ha passata.
- **La Modifica (tempo B).**
  - `consegna`, `aiuto` e `motivo` stanno su una riga; i valori di sezione non hanno virgolette (formato.lua:179-182).
  - `pos: 1:1`: i tasti partono dalla riga 1, colonna 1.
  - Il `par` lo scrive `dattilo vivo --prova`. Il generatore mette `par: 0`, e la prova lo riscrive col numero contato da `conta_tasti`. Il formato lo vuole (formato.lua:295-297), la guida non lo mostra (G12).
  - Il blocco del codice di partenza ha `partenza` dopo il linguaggio (```` ```js partenza ````). Viene prima del blocco obiettivo, e tutti e due vengono prima di `### Tasti`: le righe dopo `### Tasti` appartengono a quella sottosezione (formato.lua:175-177).
  - In `### Tasti` c'è un pezzo per riga, `- <tasti> | <cosa fanno>`, nella notazione di Vim: `<Esc>`, `<CR>`, `<BS>`, `<lt>` per un `<` vero e `<Bar>` per un `|` vero. Messi in fila, i pezzi devono essere uguali a `soluzione`.
- **`tempo`:** caratteri del codice / 175, arrotondato in su, «circa N minuti» (175 = 35 parole al minuto per 5 caratteri). Con 1, «circa 1 minuto». Nel tempo B, con la Modifica, un minuto in più.
- **I testi di base**, quando Haiku manca:
  - titolo = nome della funzione;
  - briefing = «Claude ha cambiato `<nome>` in `<file corto>`.», più le sue parole se ci sono;
  - blocchi = «Prima» (righe prima della prima cambiata), «La modifica di Claude» (dalla prima all'ultima riga cambiata), «Dopo» (il resto). I blocchi vuoti si saltano. Come «cosa» e «quadro» si usano `spiega` e `dipiu` del passo se ci sono, altrimenti «Righe che c'erano già.» e «Righe che Claude ha cambiato.»;
  - suggerimento sulla prima riga cambiata: «Riga cambiata da Claude.» più la `spiega` del passo;
  - nota della spiegazione sulla prima riga cambiata: la `spiega`, oppure «Qui Claude ha cambiato il codice.»;
  - niente Modifica: i tasti li dà solo Haiku.
- **Caratteri speciali.** La lezione non deve dire niente. Come scriverli lo calcola la guida al momento, dal digramma di Neovim (G11).

### 5.6 Haiku: cosa cambia nel prompt e nella risposta

Si cambia la stessa chiamata di oggi: `promptHaiku` e `leggiRispostaHaiku` (dalvivo-logica.js:88-117 e 138-154). Nessuna seconda chiamata.

**Quando.** I campi della lezione si chiedono solo se:
- «Rifallo tu» è acceso per quel terminale;
- la modifica ha un codice da battere valido (5.4);
- è fra le ultime **3** funzioni diverse del gruppo. Due modifiche alla stessa funzione contano una volta sola, e i testi vanno all'ultima.

Nel tempo B, i campi della Modifica si chiedono solo per le modifiche che hanno anche un codice di prima valido (5.4). Le altre lezioni del gruppo prendono i testi di base. Tutto il resto del prompt è com'è oggi.

**Nel prompt**, sotto le righe ± della modifica, c'è un blocco nuovo:

```
Codice da battere per la modifica 2 (funzione codicePulito; le righe con * sono cambiate):
 1  export function codicePulito(t) {
 2* const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/[O0U]/g, (x) => SIMILI[x]);
 3    if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
 4    return `${c.slice(0, 4)}-${c.slice(4)}`;
 5  }
```

Nel tempo B, sotto, c'è anche:

```
Codice di prima per la modifica 2 (com'era prima della modifica; il cursore parte dalla riga 1, colonna 1):
 1  export function codicePulito(t) {
 2    const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");
 3    if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
 4    return `${c.slice(0, 4)}-${c.slice(4)}`;
 5  }
```

E, in fondo, prima della riga «Rispondi solo con un oggetto JSON…»:

```
Per le modifiche che hanno un «Codice da battere» aggiungi anche "lezione", un oggetto con:
- "briefing": due frasi, in italiano semplice: cosa fa questo codice e cosa ci ha cambiato la modifica;
- "blocchi": da 1 a 4 pezzi del codice, in ordine e senza sovrapporsi, ognuno {"da": prima riga, "a": ultima riga, "titolo": al massimo 30 caratteri, "cosa": una frase su cosa fa, "quadro": una frase su come si lega al resto};
- "righe": un oggetto {"numero di riga": una frase su cosa fa quella riga}, solo per le righe cambiate (con *) e per quelle difficili, al massimo 12, al massimo 140 caratteri l'una.
I numeri di riga sono quelli scritti a sinistra del «Codice da battere». Non parlare di tasti né di Vim.
```

Nel tempo B si aggiunge:

```
Per le modifiche che hanno anche un «Codice di prima», dentro "lezione" aggiungi "modifica", un oggetto con:
- "consegna": una frase: cosa ha cambiato la modifica, detto a parole, senza nomi di tasti;
- "parole": una o due frasi: come rifarla con Vim, a parole (dove andare, cosa togliere, cosa scrivere), senza nomi di tasti;
- "tasti": la lista dei tasti di Vim che, partendo dalla modalità normale col cursore alla riga 1 colonna 1 del «Codice di prima», lo fanno diventare uguale al «Codice da battere». In pezzi, in ordine: ogni pezzo {"tasti": i tasti nella notazione di Vim (<Esc>, <CR>, <BS>, <lt> per un < vero, <Bar> per un | vero), "cosa": cosa fa quel pezzo, al massimo 80 caratteri}. Il testo da scrivere è un pezzo a sé. Niente comandi con i due punti, tranne :s. Niente mouse e niente frecce. Al massimo 20 pezzi.
```

**La risposta attesa** (chiave «2» dell'esempio):

```json
{"2": {"titolo": "La tabella dei sosia", "spiega": "Aggiungo la correzione dei sosia prima del controllo.", "dipiu": "Nel carattere a pixel la C sembra una O…",
       "lezione": {"briefing": "codicePulito riduce il codice scritto dalla persona alla forma che si salva. Ora corregge O, 0 e U prima del controllo.",
                   "blocchi": [{"da": 1, "a": 2, "titolo": "Pulizia", "cosa": "Mette tutto maiuscolo e corregge i sosia.", "quadro": "È qui la riga nuova."},
                               {"da": 3, "a": 5, "titolo": "Controllo e forma", "cosa": "Rifiuta i codici sbagliati.", "quadro": "C'era già."}],
                   "righe": {"2": "L'ultimo .replace cambia ogni O, 0 e U con il suo sosia."},
                   "modifica": {"consegna": "Alla riga 2, dopo il primo .replace, aggiungi il .replace che corregge i sosia.",
                                "parole": "Vai alla riga 2, mettiti sul punto e virgola finale, entra in scrittura subito prima e scrivi il pezzo nuovo; poi esci dalla scrittura.",
                                "tasti": [{"tasti": "2G", "cosa": "va alla riga 2"},
                                          {"tasti": "$", "cosa": "va in fondo alla riga, sul punto e virgola"},
                                          {"tasti": "i", "cosa": "entra in scrittura subito prima del punto e virgola"},
                                          {"tasti": ".replace(/[O0U]/g, (x) => SIMILI[x])", "cosa": "scrive il pezzo nuovo"},
                                          {"tasti": "<Esc>", "cosa": "esce dalla scrittura"}]}}}}
```

**La lettura.**
- La firma diventa `leggiRispostaHaiku(testo, chiavi, codici = {})`, con `codici["2"] = { righe: 5, vuote: [], prima: true }`.
- Restituisce `{ [id]: { titolo, spiega, dipiu, lezione? } }`.
- I campi della lezione si controllano **uno per uno**, con `leggiLezioneHaiku(o, nRighe, vuote)` di `rifallo-logica.js`:
  - `briefing`: testo su una riga, al massimo 300 caratteri, altrimenti `""`;
  - `blocchi`: si tengono solo quelli con `da` e `a` interi e `1 ≤ da ≤ a ≤ nRighe`, con `da` maggiore dell'`a` del blocco prima e un titolo non vuoto. Il titolo si taglia a 30 caratteri, `cosa` e `quadro` a 160. Al massimo 4. Se non ne resta nessuno, i blocchi di base;
  - `righe`: chiavi intere fra 1 e `nRighe`, non su righe vuote; testo su una riga, al massimo 140 caratteri; al massimo 12.
- **Tempo B:** `modifica` si controlla con `leggiModificaHaiku(o)`:
  - `consegna`, al massimo 200 caratteri, e `parole`, al massimo 300, devono essere testi su una riga, non vuoti;
  - `tasti` è una lista da 1 a 20 pezzi, ognuno con `tasti` (testo non vuoto, senza a capo, al massimo 200 caratteri) e `cosa` (al massimo 80, una riga);
  - la soluzione, cioè i pezzi messi in fila, è al massimo 400 caratteri;
  - nei `tasti` un ` | ` diventa `<Bar>`, così la riga di `### Tasti` si legge;
  - se qualcosa non va, la `modifica` vale `null`, e la lezione esce senza Modifica.

  Se il controllo passa, la parola finale spetta a `dattilo vivo --prova`, che rifà i tasti in un Neovim senza interfaccia.
- Un campo della lezione rotto non tocca `titolo`/`spiega`/`dipiu`. Una `lezione` illeggibile vuol dire testi di base. **La spiegazione del fumetto non si perde mai per colpa della lezione.**
- Le prove di oggi (dalvivo-logica.test.mjs) restano valide: senza `codici` non c'è `lezione`.

**I tempi.**
- Se il prompt contiene almeno un codice da battere, il tempo massimo sale da 20 000 a **30 000 ms** (`TEMPO_HAIKU_LEZIONE`). Senza «Rifallo tu» resta 20 000, come vuole la parte 1.
- Il fumetto smette di mostrare i puntini a 20 s (dalvivo-logica.js:285). Una spiegazione che arriva a 25 s si vede comunque, appena arriva.
- Nel tempo B la risposta è più lunga, perché i tasti sono 5-20 pezzi a lezione. È un rischio da misurare (6.4).

### 5.7 La coda «N nuove»

- **Lezione in corso:** quella aperta in dattilo (`stato.json`, `lezione`).
- **Nuove:** le lezioni dopo quella in corso, nell'ordine dei file, non fatte e non saltate. Si contano fra quelle che dattilo **ha letto senza errori**, non fra i file scritti. Senza lezione in corso, tutte quelle non fatte e non saltate. Le conta dattilo e le scrive in `stato.json`. La mod le mostra e basta.
- **Quando arriva una modifica a una funzione che ha già una lezione** (stessa `chiave` = file corto + nome della funzione, in `indice.json`):
  - se quella lezione non è mai stata aperta (non è in `aperte`) e non è fatta, la si **riscrive al suo posto**: stesso id, stesso posto in coda, contenuto nuovo. Il conteggio non cambia, e la riga `lezione` del passo nuovo punta a lei;
  - se è quella in corso, o è già stata aperta, o è fatta: **lezione nuova** in fondo alla coda. Quella in corso non si tocca mai.
  - L'aiutante legge `stato.json` e `dati/dattilo/progressi.json` per decidere, sotto il lucchetto di `indice.json`. Se dattilo apre la lezione proprio mentre la si riscrive, non è un danno: dattilo ha già in memoria il testo che ha letto, e la scrittura atomica gli evita di leggerne uno a metà.
- **Il tetto:** al massimo **30 lezioni** in cartella. Oltre, si cancella la più vecchia: prima fra le fatte o saltate, poi fra le altre, mai quella in corso. Per i suoi passi si aggiunge una riga `lezione` con `stato: "no"` e motivo «lezione tolta: ce n'erano più di 30».
- **Passare alla prossima lo decide la persona:**
  - ‹Invio› nel riepilogo (la prima nuova in ordine);
  - `:salta`;
  - `:ultima` (la più recente);
  - un clic su «Rifallo tu» di un passo;
  - un clic su «N nuove» nella testata, che fa come `:ultima`.

  Una lezione nuova non apre niente da sola, tranne che dalla schermata «Attesa».

### 5.8 Come la mod apre dattilo

**Si accorge che dattilo c'è.** Una volta per vista, al primo clic, la mod lancia `exec("dattilo", ["vivo", "--dove"], { timeout: 10000 })`:
- se `exec` rifiuta, dattilo non è nel `PATH`: «manca»;
- se esce con 0 e stampa `{"vivo":1,"radice":"/home/…/dattilo"}`: c'è, e si tiene `radice`. Con `"vivo":2` sa anche fare `--prova`, cioè il tempo B. Con `"vivo":1` l'aiutante non scrive Modifiche;
- altrimenti è un dattilo vecchio. Oggi `bin/dattilo` manderebbe `vivo --dove` a `exec nvim` (bin/dattilo:22), e Neovim esce subito con 1 per l'opzione sconosciuta: l'ho provato oggi con `nvim --clean -u NONE vivo --dove`, che esce con 1 e scrive «Unknown option argument».

Durante `checking()` non si lancia niente. Su Windows il tasto non esiste, e quindi neanche il controllo.

**Il clic su «Rifallo tu»**, in `rifallo.js`:
1. Se dattilo manca o è vecchio: l'avviso della sezione 2, e basta.
2. `exec("node", [`${appHome()}/mods/pixel/strumenti/rifallo.mjs`, "apri", nome, passo.id], { timeout: 15000 })`. Lo stesso modo di lanciare uno strumento c'è già in chat-canali.js:151. Se risponde `ok: false`, un avviso col `motivo`.
3. `setShared(CHIAVE, accendiRifallo(stato, adesso))`, cioè `rifallo: true` nello stato di «Dal vivo».
4. Scrive `vuoi.json` con `{ azione: "apri", lezione, t: adesso, dalvivo: "acceso" }` (`readTextFile` e poi `writeTextFile` con il testo letto come atteso, herdr.d.ts:27-32).
5. Cerca un dattilo già aperto: `terminals().find((t) => (t.argv ?? []).includes(cartella) && (!t.state || t.state === "live"))`. È lo stesso modo di riconoscere un terminale dal suo argv di coop.js:731.
   - Se c'è: `run("pane.focus", { terminal: t.address })`, e basta.
6. Se non c'è, apre il pannello a destra del terminale di Claude:
   ```js
   const a = agents().find((x) => x.address === stato.sessione);
   run("pane.split", { direction: "right", pane: a.pane, argv: [`${radice}/bin/dattilo`, "vivo", cartella] });
   ```
   `pane.split` con `argv` è in AGENTS.md:604 e herdr.d.ts:64. Il pannello si sceglie così perché la tavola diceva «apre dattilo nel riquadro accanto».

   **bash.** `bin/dattilo` è uno script bash. Il vincolo della mod, «niente bash né Python mentre gira», vale per quello che deve andare uguale su Linux e Windows. «Rifallo tu» su Windows è spento per scelta, e dattilo esiste solo dove c'è bash. Il resto della mod (aiutante, strumento, vista) resta in Node e in JavaScript della mod.
7. Aspetta il terminale nuovo, come `nuovaScheda` di coop-sessioni.js:160-173: fino a 20 giri di `await cx.sleep(250)`, cercando l'argv con `cartella`. Poi `run("pane.focus", { terminal })`.

**Lo stato.**
- In `shared("pixel.dalvivo")` si aggiunge `rifallo: boolean`. `accendi`, `spegni` e il cambio di sessione lo mettono a `false` (dalvivo-logica.js:364-367).
- La barra mette `rifallo: false` quando non c'è più un dattilo vivo per quella cartella da almeno 5 s dopo l'ultimo cambio (`dal`). Così, mentre dattilo è chiuso, non si preparano lezioni.

### 5.9 Cosa cambia in dattilo

Tutto il nuovo si accende solo con `dattilo vivo <cartella>`. Senza, dattilo fa esattamente quello che fa oggi: le prove che ci sono (`nvim --clean --headless -l tests/run.lua`, oggi «OK 166 test») devono restare tutte verdi senza ritocchi.

**Niente modalità «solo battitura» e niente filtro.** «Rifallo tu» usa il percorso normale di una lezione (`lezione.apri` → briefing → batti → spiegazione), con la guida accesa. Il codice nuovo sta in tre moduli suoi. I moduli di oggi cambiano in punti nominati, con una riga o poche ciascuno.

**Scelta: un livello di guida, non un'opzione di «Rifallo tu».** La guida sta in `guida.lua`, e si accende con `guida.accendi(fornitore)`. `vivo.lua` la accende per le sue lezioni, e le passa un «fornitore»: le poche parti che sono solo di «Rifallo tu» (i comandi della coda, il riepilogo con la prossima in coda, il ripristino della bozza, la scritta «2 nuove»). Perché così:
- quasi tutte le frasi parlano di Vim dentro una lezione di dattilo, non di «Rifallo tu», e varrebbero identiche per una lezione del corso C;
- costa uguale;
- domani una riga, per esempio un'opzione di `:Lezione` o una voce della home, la accende anche per le lezioni normali, senza toccare la guida.

Oggi niente la accende fuori da `vivo`: il dattilo di oggi non cambia.

**`bin/dattilo`** (righe 19-23): un caso nuovo nel `case`, prima del `*)` finale.

```bash
  vivo)
    case "${2:-}" in
      --dove) cli vivo-dove; exit $? ;;
      --prova) shift 2; cli vivo-prova "$@"; exit $? ;;   # tempo B
    esac
    [ -d "${2:-}" ] || { echo "uso: dattilo vivo <cartella> [opzioni di nvim]" >&2; exit 1; }
    export XDG_DATA_HOME="$2/dati" DATTILO_VIVO="$2" LANGUAGE=it
    shift 2
    exec nvim --clean -u "$DIR/init.lua" "$@" ;;
```

- La cartella passa per una variabile d'ambiente, non per `-c`, così un percorso con spazi non dà problemi.
- Gli argomenti dopo la cartella vanno a Neovim: `dattilo vivo <cartella> --listen <socket>` lascia leggere le statistiche da fuori, come nella gara di note.md.
- `LANGUAGE=it` mette in italiano le frasi di Neovim. Funziona anche senza la locale `it_IT` installata: l'ho provato su questa macchina, dove c'è solo `en_US`. Vale solo per `vivo`.

**`lua/dattilo/cli.lua`** (righe 176-186):
- `vivo-dove` stampa `vim.json.encode({ vivo = 1, radice = radice })` ed esce con 0. Nel tempo B `vivo` diventa 2.
- `vivo-prova` arriva nel tempo B, più sotto.

**`lua/dattilo/init.lua`.**
- In `M.avvia` (riga 56), al posto di `require('dattilo.home').apri()`:
  ```lua
  if vim.env.DATTILO_VIVO and vim.env.DATTILO_VIVO ~= '' then require('dattilo.vivo').avvia(vim.env.DATTILO_VIVO)
  else require('dattilo.home').apri() end
  ```
- In `DattiloEsci` (righe 12-14), in testa: se la guida è accesa e `guida.esci_da_finestra_in_piu()` dà vero, si esce lì (G7).

**`lua/dattilo/home.lua`**: in cima a `M.apri()` (riga 117), `if require('dattilo.vivo').attivo() then return require('dattilo.vivo').elenco() end`. È una rete: `schermo.lua:15-31` torna alla home se la finestra principale si chiude, e `DattiloEsci` porta alla home da ogni lezione. L'elenco mette `stato.schermo = 'home'`, così `:q` dall'elenco chiude dattilo come oggi dalla home (init.lua:13), senza toccare `DattiloEsci`.

**`lua/dattilo/schermo.lua`** (righe 15-31): nella funzione di `WinClosed`, prima di `require('dattilo.home').apri()`, se la guida è accesa e `guida.riprendi(cur, a.buf)` dà vero, ci si ferma lì (G7).

**`lua/dattilo/lezione.lua`**: un campo e alcune righe di aggancio, tutte con `if M.guida then … end`. Con `M.guida == nil` il comportamento è quello di oggi.

| Riga di oggi | Aggancio |
|---|---|
| 12 | `M.guida = nil`: la guida accesa (guida.lua) o nil, cioè il dattilo di sempre |
| 22 (`eco`) | con la guida, `return M.guida.eco(chunks)`: gli esiti vanno in «Controllo» (G5) |
| 310 (`BufWritePost`) | con la guida, `M.guida.protetta(salvato, s)`: un errore nel salvataggio va nel riquadro, non in un «Error executing autocommand» su più righe (G5) |
| 101 e 456 (le righe mute «‹q› torna alla home» di briefing e spiegazione) | con la guida non si scrivono: le istruzioni sono nel riquadro, e la home lì non c'è |
| 105 (fine di `briefing`) | `M.guida.schermata(s)` |
| 194-197 (`tip`) | con la guida, `return M.guida.tip(s)` |
| 260-265 (`dopo_modifica`) | con la guida, se il testo finale è uguale al codice di Batti, `M.spiegazione(s)` al posto di `M.esegui(s)` (3.2, punto 8) |
| 316 (fine di `batti`) | `M.guida.schermata(s)` |
| 337-338 (`su_fatto`, tempo B) | con la guida, `M.guida.modifica_fatta(s, tasti)` al posto dell'`eco` col par e le stelle |
| 347 (fine di `modifica`, tempo B) | `M.guida.schermata(s)` |
| 363 (fine di `esegui`) | `M.guida.schermata(s)` |
| 454 (fine di `spiegazione`) | `M.guida.schermata(s)` |
| 458 (`fine`) | con la guida, `if M.guida.fine(s) then return end`: il riepilogo lo fa il fornitore (`vivo.fatto`) |

**`lua/dattilo/guida.lua`** (nuovo): la guida sempre accesa.

| Funzione | Cosa fa |
|---|---|
| `M.accendi(fornitore)` | Mette `lezione.guida = M`. Opzioni: `more = false`. Mappa ‹Ctrl-z› (G9). Crea il gruppo di autocomandi dei posti sbagliati (3.4), `dattilo_guida`: `ModeChanged`, `RecordingEnter`/`RecordingLeave` (durante `RecordingLeave` `reg_recording()` ha ancora la lettera: per questo si aspetta), `CmdlineEnter`/`CmdlineChanged`/`CmdlineLeave`, `CmdwinEnter`/`CmdwinLeave`, `TextChanged`, `WinNew`, `WinEnter`, `WinClosed` (aprire l'aiuto o dividere lo schermo non cambia il modo). Ognuno ricalcola il riquadro con `vim.schedule` (gli eventi che arrivano insieme fanno un giro solo), sotto `pcall`, e poi chiama `redraw` (vedi la 3.4, «Il ridisegno»). La mappa di ‹Ctrl-z› è in NORMAL, INSERT e VISUAL, e con un operatore in attesa (lì è un `<Esc>` che annulla l'operatore, poi la frase); `M.spegni` la toglie, col gruppo. Nello stesso gruppo, costruendo, sono arrivati anche `VimResized` (il riquadro si rimisura), `ModeChanged` in uscita dalla scrittura (`cambio_voluto`) e `CursorMoved` (in NORMAL un movimento cambia «Adesso» e toglie la frase delle frecce). `fornitore = { comandi = fun(schermata): string, fine = fun(s): boolean, su_schermata = fun(s), destra = fun(): string }` |
| `M.spegni()`, `M.attiva() → boolean` | |
| `M.tip(s)` | Il riquadro per i passi batti, modifica ed esegui: titolo, «Adesso», «Controllo», le sezioni di `lezione.tip_batti` senza l'avviso e senza «Vim», «Comandi». Alza il riquadro (`ui.altezza_tip`) fino a 10 righe interne, perché «Adesso» e «Comandi» stiano interi. |
| `M.schermata(s)` | Chiamata in fondo a ogni schermata della lezione. Riapre il riquadro (briefing e spiegazione lo chiudono, lezione.lua:70 e 421). Aggiunge a `stato.destra` quello del fornitore. Chiama `fornitore.su_schermata(s)`. |
| `M.mostra(titolo, adesso, comandi, altre)` | Il riquadro delle schermate di `vivo` (riepilogo, elenco, attesa). Una schermata nuova parte senza l'esito di prima; un avviso per questa schermata (Ctrl-z, `non_si_apre`) si passa a `eco` dopo, e va in «Controllo». |
| `M.eco(chunks)` | Mette l'ultimo esito in «Controllo», che resta fino al prossimo cambio del testo. In Batti, col testo uguale e node che rifiuta, il titolo è IL CONTROLLO NON PASSA e la frase va in «Adesso» (`controllo_ko`, `controllo_ko_i`); negli altri passi l'errore va in «Controllo» (`controllo_errore`). Nei passi che la guida non disegna ancora (modifica e rompi, tempo B) l'esito va nel riquadro di prima: non sparisce mai. |
| `M.protetta(fn, …)` | Esegue `fn` protetta, come le funzioni della guida: un errore va nel riquadro. La usa `lezione.lua` per il salvataggio (`BufWritePost`) quando la guida è accesa. |
| `M.errore_disegno()` | L'ultimo errore della guida che non si è potuto nemmeno disegnare nel riquadro, per le prove. |
| `M.adesso_batti(x) → string` | Pura. `x = { codice, righe, r, c, modo, frecce, cambiato, annullato }`: `annullato` vuol dire che la storia degli annullamenti (`undotree().seq_cur`) è più indietro di quella dell'ultima uscita dalla scrittura. Dà la frase della tabella della 3.3. |
| `M.cambio_voluto(buf)` | Il testo di adesso è quello «giusto»: lo chiamano l'uscita dalla scrittura (`ModeChanged`, perché con ‹Ctrl-c› `InsertLeave` non scatta), l'apertura di Batti e la bozza rimessa. In NORMAL un testo diverso da questo è un testo cambiato. |
| `M.carattere(ch) → string\|nil, string` | Pura: G11. Il secondo valore è la nota sulle lettere maiuscole fra i tasti (`maiuscola`, `maiuscole`), o `''`. |
| `M.posto(modo?) → nil \| { titolo, testo }` | Il posto sbagliato in cui si è adesso (3.4). `modo` (facoltativo, per le prove) prende il posto di `nvim_get_mode()`. L'ordine: la finestra dei comandi, Ex, la riga dei comandi (`getcmdtype()`), la registrazione (in NORMAL, INSERT e REPLACE), le frecce, il terminale in NORMAL, la finestra in più col cursore dentro (riga 12, in NORMAL; la 12b arriva col compito 6), poi il modo. NORMAL e INSERT (anche `ic` e `ix`) non sono posti sbagliati; «Premi INVIO» (`r…`) e un comando esterno (`!`) nemmeno, perché lì non si ridisegna. In un posto sbagliato il riquadro della schermata tiene le sue sezioni, ma titolo e «Adesso» sono quelli del posto e il bordo è rosso. |
| `M.riprendi(win, buf) → boolean` | Da schermo.lua. Se c'è una lezione aperta, rimette `buf` in `win`, ne fa la finestra principale e ridisegna il riquadro (e, nel tempo B, l'OBIETTIVO). |
| `M.esci_da_finestra_in_piu() → boolean` | Da `DattiloEsci`. Se il cursore è in una finestra in più, la chiude e dà vero. |
| `M.fine(s) → boolean` | Passa al fornitore. |
| `M.modifica_fatta(s, tasti)` (tempo B) | `mod_fatta` in «Controllo». |
| `M.ultimo() → { titolo, sezioni, tipo }` | L'ultimo riquadro disegnato, per le prove. |
| `M.fornitore()` | Il fornitore acceso, per le prove. |
| `M.ETICHETTA` | La larghezza della colonna delle etichette del riquadro della guida: 11, perché «Controllo» più due spazi non sta nei 9 di oggi. |

**`lua/dattilo/guida_testi.lua`** (nuovo): tutte le frasi della 3.3 e della 3.4, coi nomi scritti lì. Ha anche `M.neovim(tasto) → string`, che traduce un tasto della guida nella notazione di Neovim: ‹Invio› → `<CR>`, ‹Ctrl-k› → `<C-k>`, ‹<› → `<lt>`, ‹Fine› → `<End>`. Lo usa il robot delle prove (7.2).

**`lua/dattilo/vivo.lua`** (nuovo): la cartella, la coda e le schermate di «Rifallo tu».

| Funzione | Cosa fa |
|---|---|
| `M.attivo() → boolean` | Vero dopo `avvia`. |
| `M.avvia(cartella)` | Controlla la cartella (link, 5.2). Accende la guida col suo fornitore. Crea `:DattiloSalta`, `:DattiloUltima` e `:DattiloElenco`, con le abbreviazioni `salta`, `ultima` ed `elenco`, come quelle di init.lua:4-9. Rilegge `aperte` e `saltate` da `stato.json`. Poi esegue `vuoi.json` se c'è una richiesta; altrimenti apre la prima lezione non fatta e non saltata; altrimenti «Attesa». Fa partire il timer di 500 ms e l'autocomando `VimLeavePre` della bozza. |
| `M.controlla()` | Un giro del timer. Se `vuoi.json` ha un `t` nuovo, esegue la richiesta. Se cambia la cartella delle lezioni (data di modifica della cartella o di un file), chiama `pacchetti.dimentica()`, ricalcola la coda e aggiorna la barra; in «Attesa», apre la prima nuova. Se cambia `dalvivo`, aggiorna la barra. Salva la bozza se sono passati 2 s dall'ultima. Poi `scrivi_stato()`. Si chiama anche dalle prove. |
| `M.coda(P, corrente, fatte, saltate) → { nuove, prossima, ultima }` | Pura, sulle lezioni lette senza errori. |
| `M.apri(id)` | Salva la bozza di quella aperta. `pacchetti.dimentica()`. Cerca la lezione per **id**, e `lezione.apri('rifallo', n)`. Con una bozza di Batti va dritto a `lezione.batti`. Se l'id non c'è o la lezione ha errori, `non_si_apre` e l'elenco. |
| `M.fatto(s) → true` | Il riepilogo (fornitore `fine`). Registra `rifallo/<id>` in `progressi.json` (progressi.lua:46), toglie la bozza, disegna i numeri e mappa ‹Invio›, ‹r› e ‹q›. |
| `M.prossima()`, `M.salta()`, `M.ultima()`, `M.rifai()` | ‹Invio› nel riepilogo, `:salta`, `:ultima`, ‹r›. |
| `M.elenco()`, `M.attesa()` | Le schermate «Elenco» (✓ fatta, ▸ da fare, «nuova», «saltata») e «Attesa». Mettono `stato.schermo = 'home'`. |
| `M.bozza_salva(id)`, `M.bozza_leggi(id) → { passo, righe } \| nil`, `M.bozza_togli(id)` | `bozze/<id>.json`, file 0600 in una cartella 0700. Si salva come dice G8. |
| `M.su_schermata(s)` | Fornitore. In Batti, se il buffer è vuoto e c'è una bozza, la rimette, porta il cursore in fondo e mostra `ripreso`. |
| `M.destra() → string` | Fornitore: « · 2 nuove», « · sessione finita: niente lezioni nuove» o « · Dal vivo spento: niente lezioni nuove». |
| `M.scrivi_stato()` | Riscrive `stato.json` in modo atomico, solo se è cambiato. |

**`lua/dattilo/ui.lua`**: due aggiunte, senza effetto sul dattilo di oggi (cambiato costruendo: prima qui c'era «nessun cambio»). `ui.sezioni`, `ui.riquadro` e `ui.tip` hanno un parametro in più, facoltativo, per la larghezza della colonna delle etichette (senza, vale 9 come oggi); e c'è `ui.tip_aperto()`, che dice se il riquadro è aperto, per ridisegnarlo quando la finestra cambia misura. Per il resto la guida usa `ui.tip`, `ui.altezza_tip` e `ui.chiudi_tip` così come sono.

**Tempo B, in più.**
- **`lua/dattilo/formato.lua`** (righe 291-312 e 344-353): la Modifica può avere il blocco ```` ```js partenza ````, che diventa `m.partenza` invece dell'obiettivo di prima. Può avere anche `### Tasti`, che dà `m.tasti = { { tasti, cosa } }`. Con `### Tasti`, `mostra` sono i pezzi, e i pezzi messi in fila devono essere uguali a `soluzione`. Gli errori nuovi:
  - «la Modifica ha due blocchi partenza»;
  - «riga non valida nei Tasti: scrivi - tasti | cosa fanno»;
  - «i Tasti messi in fila non sono la soluzione».

  Una lezione senza queste due cose si legge esattamente come oggi.
- **`lua/dattilo/controlla.lua`** (righe 27-40): `prova_soluzione` diventa `M.prova_soluzione(m) → righe|nil, errore`. Cambia solo il nome.
- **`lua/dattilo/cli.lua`**: `vivo-prova <lezione.md>`. Gira nella sandbox quando c'è, come `controlla` (cli.lua:146-154), con la cartella del file in scrittura. Per ogni Modifica rifà i tasti con `prova_soluzione` e confronta il risultato con l'obiettivo. Se tutto va, riscrive le righe `par:` col numero di `conta_tasti`, in modo atomico. Le uscite:
  - **0**, con `{"ok":true,"modifiche":[{"tasti":41}]}`;
  - **1**, lezione rifiutata, con `{"ok":false,"motivo":"…"}`;
  - **2**, uso sbagliato o file illeggibile, con `{"ok":false,"motivo":"uso: dattilo vivo --prova <lezione.md>"}`.
- **`lua/dattilo/esercizio.lua`** (righe 126-136): l'apertura della finestra OBIETTIVO diventa `M.finestra_obiettivo(e)`, così la guida la può riaprire dopo ‹Ctrl-w› ‹o›. È solo codice spostato.
- **`guida.lua`**: la Modifica guidata (G12, frasi della 3.3). I tasti premuti li conta un osservatore `vim.on_key` che restituisce sempre `nil`: guarda e non scarta mai niente. I tasti si mostrano dopo 15 s fermi, con `vim.uv.now()`, o oltre il doppio della soluzione.
- **`vivo.lua`**: una bozza con `passo: "modifica"` riapre la lezione direttamente alla Modifica, ripartendo dal codice di partenza. È breve, e il testo di Batti è già fatto.

**Compatibilità.** Una persona che usa dattilo da solo vede tutto uguale:
- `bin/dattilo` senza `vivo`, `init.lua` senza `DATTILO_VIVO`, `home.apri` senza `vivo.attivo()`, `schermo` e `DattiloEsci` senza la guida accesa;
- in `lezione.lua` ogni aggancio è dentro `if M.guida`;
- nel tempo B le lezioni di oggi si leggono uguali: senza blocco `partenza` e senza `### Tasti` non cambia niente.

**Quanto è grosso.** È una stima. `guida.lua` circa 350 righe, `guida_testi.lua` circa 120, `vivo.lua` circa 300, più circa 40 righe di agganci. Il tempo B aggiunge circa 150 righe fra formato, cli e guida.

### 5.10 Cosa cambia nella mod

**`acceso.json`.** Diventa `{"acceso":…,"haiku":…,"terminale":…,"rifallo":…}`, con le chiavi sempre in quest'ordine. `testoAcceso` (dalvivo-logica.js:379-382) lo scrive.
- Le uguaglianze esatte in prove/dalvivo-logica.test.mjs:301-303 vanno aggiornate: è un cambio voluto.
- Aiutante e strumento leggono `rifallo === true && nomeFile(terminale) === nome`, come per `haiku` (dalvivo-spiega.mjs:104-107).
- Su Windows la barra scrive sempre `rifallo: false`.

**Le righe nuove nel `.jsonl` di «Dal vivo».** Le scrive l'aiutante o lo strumento, sotto il lucchetto del file con `attesa: 2000`, come le altre (dalvivo-spiega.mjs:108-111):

```json
{"v":1,"tipo":"lezione","id":"toolu_…","stato":"pronta","lezione":"003-codicepulito"}
{"v":1,"tipo":"lezione","id":"toolu_…","stato":"no","motivo":"dattilo controlla solo JavaScript (.js, .mjs, .cjs); questo file è .ts."}
```

- `leggiPassi` (dalvivo-logica.js:27-58) aggiunge a ogni `Passo` il campo `lezione: { stato, id, motivo } | null`. Vale l'ultima riga.
- `accorcia` dell'hook tiene già le righe per id, di qualunque tipo (dalvivo.mjs:97-108), e quindi non cambia.

**`rifallo-logica.js`.** Per la mod servono queste funzioni pure:
- `bottoneRifallo(passo, { piattaforma, rifallo, adesso, corrente }) → { testo, attivo, attesa, suggerimento } | null`:
  - `null` su Windows, per un file non JavaScript, e con `lezione.stato === "no"`;
  - «Rifallo tu ···» non premibile se `rifallo` è vero, non c'è ancora la riga e il passo ha meno di 40 s;
  - «La stai rifacendo» se `lezione.id === corrente` (il clic porta il fuoco a dattilo);
  - altrimenti «Rifallo tu».
- `motivoRifallo(passo) → string | null`: la riga grigia per la scheda.
- `chipRifallo(statoDattilo) → string | null`: «1 nuova», «2 nuove», oppure `null`.
- `accendiRifallo(stato, adesso)` e `rifalloDaSpegnere({ stato, dattiloVivo, adesso }) → boolean`.
- Tempo B: `codiceDiPrima(...)` (5.4) e `leggiModificaHaiku(o)` (5.6).

**La vista** (`dalvivo-vista.js`).
- **Nella finestrella** il fumetto è una riga sola, oggi senza tasti (righe 116-129). Il tasto si aggiunge in fondo a quella riga, con `tasto()` (righe 34-43) in piccolo (`alto: 22`, `misura: 11`). Il testo del fumetto si accorcia di conseguenza.
- **Nella scheda** (righe 132-148) la riga di «Di più» diventa: `Di più · Rifallo tu`. Senza tasto ci va la riga grigia di `motivoRifallo`. `altezzaFumetto` (righe 151-158) conta 20 px in più.
- **Nella testata** (righe 51-60), prima di ⤢, quando c'è: un tasto acceso `2 nuove`, col suggerimento «2 lezioni nuove in dattilo: un clic porta all'ultima». Nella scheda intera dice `dattilo · 2 nuove`.
- Come tutti i comandi, i tasti fermano la pressione con `cx.stop_propagation()`, così non trascinano la finestrella.

**`dalvivo.js`.**
- `this.su` (righe 42-51) prende `rifallo: (cx) => apriRifallo(cx, passo)` e `ultima: (cx) => chiediUltima(cx)`. `chiediUltima` scrive `vuoi.json` con `azione: "ultima"` e porta il fuoco a dattilo.
- Il timer di 1000 ms (riga 61) rilegge `stato.json` quando `rifallo` è vero.
- `controllaDalVivo` (righe 300-317) chiama anche `controllaRifallo(cx, d)`, che:
  - applica `rifalloDaSpegnere`;
  - riscrive `vuoi.json` quando `dalvivo` cambia (acceso → spento o «finita»);
  - lancia `rifallo.mjs pulisci` come in 5.2.

**Niente di tutto questo su Windows.** `bottoneRifallo` dà `null` e `controllaRifallo` esce subito.

### 5.11 I testi, tutti insieme

| Dove | Testo |
|---|---|
| Tasto nel fumetto | «Rifallo tu» · «Rifallo tu ···» (suggerimento: «Preparo la lezione: aspetto la spiegazione di Haiku») · «La stai rifacendo» |
| Suggerimento del tasto | «Riscrivi tu questa funzione in dattilo» |
| Riga grigia nella scheda | «Rifallo tu: » + motivo |
| Motivi | «dattilo controlla solo JavaScript (.js, .mjs, .cjs); questo file è .X.» · «questa funzione è troppo lunga (N righe) e non si taglia in un pezzo che stia in piedi da solo.» · «questo pezzo di codice non sta in piedi da solo.» · «righe troppo lunghe da battere.» · «modifica troppo piccola.» · «Claude ha cambiato di nuovo questo punto: rifai il passo dopo.» · «lezione tolta: ce n'erano più di 30.» · «file troppo grande.» |
| Testata | «1 nuova» / «N nuove» (finestrella), «dattilo · N nuove» (scheda) |
| Avvisi di Herdr | «Serve dattilo» / «"Rifallo tu" usa dattilo, che su questo computer non c'è. Installalo (github.com/Frumorn12/dattilo, serve Neovim 0.12) e riprova.» · «dattilo da aggiornare» / «Il tuo dattilo non sa ancora fare "Rifallo tu": aggiornalo (git pull nella sua cartella) e riprova.» · «Rifallo tu non parte» / motivo |
| dattilo, barra in alto | a sinistra `dattilo  Rifallo tu · <breve>`; a destra i pallini dei passi, poi « · 2 nuove», « · sessione finita: niente lezioni nuove» o « · Dal vivo spento: niente lezioni nuove» |
| dattilo, riquadro della guida | sezioni 3.3 e 3.4 (`guida_testi.lua`) |
| dattilo, riepilogo | `Batti  N righe in M:SS   P parole al minuto · Q% di precisione`; nel tempo B `Modifica  T tasti` (senza par né stelle); `Prossima  “<titolo>”` o `Prossima  arriva con la prossima modifica di Claude` |
| dattilo, attesa | «Aspetto la prossima modifica di Claude a un file JavaScript…» |
| dattilo, elenco | una riga per lezione: segno (✓ fatta, ▸ da fare), titolo, «nuova» o «saltata» a destra |

---

## 6. Rischi e cose non verificate

1. **`node --check` su un pezzo di codice.**
   - Verificato con Node 26: un metodo da solo non passa, un `export` in `.cjs` non passa, `.js` con `export` passa grazie al riconoscimento automatico dei moduli.
   - Non verificato: un Node vecchio, senza quel riconoscimento, rifiuterebbe ogni `.js` con `export`. Il generatore se ne accorge, perché usa lo stesso controllo, e semplicemente non fa lezioni.
   - Non verificato nemmeno che il `node` dell'aiutante (`process.execPath` o `PATH` dell'hook) sia lo stesso del terminale di dattilo. Con `mise` o `nvm` potrebbero differire.
   - Se differiscono, una lezione può passare il controllo del generatore e non quello di dattilo. Per questo c'è `controllo_ko`, che dice «l'errore non è tuo» e porta a `:salta`.
2. **Il lettore di JavaScript è un'euristica.** Su `/` dopo `)`, per esempio `if (x) /re/.test(y)`, sbaglia. Le conseguenze:
   - un'unità sbagliata, che il controllo di solito scarta: lezione mancante, mai una lezione rotta;
   - oppure un'unità valida ma diversa da quella voluta, che passa il controllo e va in coda: è il caso peggiore.

   Va provato su file veri del progetto (7.1).
3. **Funzioni lunghissime.** Il taglio tiene la firma, i pezzi vicini alla modifica e i segni `// ... (N righe)`. Non verificato su classi enormi, come `coop.js` con le sue 80 KB. Lì è probabile «troppo lunga».
4. **Una chiamata a Haiku più grossa.** La «stessa chiamata» regge in teoria: al massimo 3 lezioni, 12 righe di spiegazione l'una, campi controllati uno per uno, e un tempo massimo che sale a 30 s solo con «Rifallo tu» acceso. Nel tempo B la risposta cresce ancora, con fino a 20 pezzi di tasti per lezione. **Non misurato.** Se nel banco le spiegazioni del fumetto arrivano dopo i 20 s, ci sono due strade:
   - ridurre a 1 lezione per chiamata, o chiedere la Modifica per una lezione sola;
   - accettare una seconda chiamata solo per la lezione. Questo va contro la scelta già presa, e va detto ad Andrea.
5. **I tasti di Haiku (tempo B).** Haiku sbaglierà spesso i tasti di Vim, soprattutto i conti di riga e colonna. `dattilo vivo --prova` scarta quelli sbagliati, e la lezione esce senza Modifica. Il rischio è che succeda quasi sempre. Si misura nel banco: su 10 modifiche, quante Modifiche passano la prova.
6. **Il file modificato due volte prima che la persona finisca.** È gestito: àncora sul testo, lezione «superata», sostituzione della lezione in coda non aperta, lezione in corso intoccabile. Non verificato in una raffica vera di Claude, cioè 5-10 modifiche in 20 s alla stessa funzione.
7. **Codice riservato su disco e in rete.**
   - Il codice della funzione finisce in `~/.cache/herdr-pixel/rifallo/<nome>/`, a 0700, e si cancella quando «Dal vivo» smette di seguire quel terminale e dattilo è chiuso. C'è anche la rete delle 24 ore.
   - Per un attimo sta anche in una cartella a 0700 sotto `/tmp`, durante il controllo.
   - Le bozze contengono quello che la persona ha battuto.
   - Haiku riceve più codice di oggi: la funzione intera invece delle sole righe ±, e nel tempo B anche il codice di prima. Va allo stesso fornitore che ha già visto il file con Claude Code, ma è comunque più codice che esce.
   - Se Herdr non gira per giorni, la pulizia aspetta.
8. **`pane.split` con `argv`.** Non verificati:
   - se il programma parte con il `PATH` della persona, perché `bin/dattilo` cerca `nvim` e dattilo cerca `node`;
   - se il pannello si chiude da solo quando dattilo esce. Per `tab.new` AGENTS.md dice che la shell resta aperta; la nota di Andrea del 16/11 dice che `pane.split` con `argv` si chiude da solo;
   - cosa succede se la sessione seguita è in una scheda che non si vede;
   - che segnale manda Herdr a dattilo quando si chiude il pannello. In tmux `VimLeavePre` scatta con SIGHUP e SIGTERM, ma con SIGKILL no: lì si perdono al massimo 2 s di bozza.

   Si guarda nel banco.
9. **La finestrella di «Dal vivo» copre l'angolo in alto a destra del pannello di dattilo,** dove c'è il riquadro. La persona la può spostare. Non so se `openOverlay` con la stessa `key` e un `at` nuovo la sposti: è il «guasto D» del compito 11 della parte 1.
10. **La guida dove Neovim non ridisegna.** Nella riga dei comandi, con un operatore in attesa e in modalità Ex, non so se il riquadro si aggiorna (3.4, ultimo paragrafo). Durante «Premi INVIO» di sicuro no: lì parla solo Neovim, in italiano. Si guarda nel collaudo in tmux. Se il riquadro non si ridisegna, in quei posti la persona vede la frase di Neovim e, appena torna, quella della guida.
11. **ui2.** Neovim 0.12 ha un'interfaccia nuova dei messaggi che toglie «Premi INVIO» del tutto (`require('vim._core.ui2').enable()`, news.txt di 0.12). È sperimentale, e apre finestre sue (riga dei comandi, messaggi, pager) che si scontrano con la logica delle finestre di dattilo (schermo.lua, ui.lua:228-236). Non la uso. Se diventa stabile, è il modo per chiudere il rischio 10.
12. **La tastiera.** La guida dà per scontata la tastiera italiana: dice che ‹:› si fa con Maiusc e il tasto del punto, e non spiega àèéìòù. Con un'altra tastiera queste due cose sono sbagliate (domanda 1).
13. **La guida è lunga.** Il riquadro arriva a 10 righe interne più il bordo. In un pannello basso (meno di 24 righe) copre metà del codice. Le sezioni della lezione («Riga», «Blocco») si accorciano per prime, ma «Adesso» e «Comandi» no.
14. **`LANGUAGE=it`.** Cambia anche la lingua dei messaggi dei programmi che dattilo lancia e che usano gettext. Oggi lancia solo `node`, che gettext non lo usa, e `bwrap`, che non scrive niente quando funziona.
15. **Righe lunghe.** dattilo non manda a capo (schermo.lua:74). In un pannello largo metà schermo una riga di 140 caratteri scorre di lato mentre si scrive. Si può guardare nel banco.
16. **macOS.** Dovrebbe andare: `bash`, `nvim`, `node`, niente `bwrap`. Non provato.

---

## 7. Come si prova

### 7.1 Prove automatiche nella mod (`node --test prove/`)

- **`prove/rifallo-logica.test.mjs`** (nuovo):
  - **`scandisci` e le unità** su file costruiti apposta: funzione, classe, oggetto, `export const` con freccia; parentesi dentro stringhe, template con `${}` annidati, commenti e espressioni regolari (`/[{}]/`); divisione `a / b / c`. Più una cartella di file veri copiati dal progetto (`dalvivo-logica.js`, `regole.js`), con le unità attese scritte a mano.
  - **L'àncora:** trovata una volta; trovata due volte (vince la più vicina); non trovata («superata»); solo righe tolte; file nuovo.
  - **Il taglio:** una funzione di 80 righe con la modifica alla riga 40 dà al massimo 30 righe, coi segni `// ... (N righe)`, e passa `node --check`. Una funzione di 200 righe senza punti di taglio dà «troppo lunga».
  - **La pulizia:** commenti tolti, tab diventati spazi, spazi in fondo tolti; nome del file (`regole.test.mjs` → `codice.mjs`).
  - **`lezioneMd`:** intestazione tra virgolette (anche con `[id]/page.js` in `fonte`), ` | ` cambiato, «titolo:» in testa al briefing cambiato in «titolo —», recinto più lungo se il codice contiene tre accenti gravi, nessun `## Rompi`, e `## Modifica` solo con una `modifica` valida.
  - **`leggiLezioneHaiku`:** blocchi fuori misura, sovrapposti, senza titolo; righe su righe vuote o fuori misura; testi con a capo; più di 12 righe; lezione illeggibile → `null`.
  - **Tempo B:**
    - `codiceDiPrima`: riga cambiata, riga aggiunta, riga tolta, cambio solo nei commenti (niente Modifica), file nuovo (niente Modifica);
    - `leggiModificaHaiku`: pezzi vuoti, più di 20, `cosa` troppo lunga, ` | ` nei tasti diventa `<Bar>`.
  - **`bottoneRifallo`, `motivoRifallo`, `chipRifallo`:** tutti gli stati della 5.10, Windows compreso.
- **`prove/dalvivo-logica.test.mjs`:**
  - `leggiPassi` con righe `lezione` (l'ultima vince);
  - `promptHaiku` con `codice` (blocco numerato, asterischi, regole nuove) e senza (identico a oggi);
  - `leggiRispostaHaiku` con `codici` (una `lezione` rotta non toglie la `spiega`);
  - `testoAcceso` con `rifallo`.
- **`prove/rifallo.test.mjs`** (nuovo, con una casa finta sotto `/tmp`, come prove/hook-notizie.test.mjs:40-49):
  - `apri` crea le cartelle a 0700, con la prova saltata su win32;
  - scrive il manifesto, la lezione, la riga `lezione` e `indice.json`;
  - `pulisci` cancella tutto tranne le cartelle in `--tranne`;
  - la sostituzione in coda: non aperta → stesso id; in corso → id nuovo; fatta → id nuovo;
  - il tetto di 30;
  - il lucchetto occupato.
  - Se `dattilo` c'è nel `PATH` (altrimenti la prova è saltata):
    - `dattilo controlla --tip <pacchetto> <id>` non stampa nessuna riga «✗» sulle lezioni scritte;
    - nel tempo B, `dattilo vivo --prova` esce con 0 sulla lezione dell'esempio della 5.5 e con 1 se un pezzo di tasti è sbagliato.
- **`prove/dalvivo-spiega.test.mjs`:**
  - con `rifallo: true` e un `claude` finto (come prove/hook-cronista.test.mjs:421-444) che risponde coi campi `lezione`, si ottengono la riga `spiega`, la lezione col testo di Haiku e la riga `lezione`, e **una** chiamata sola;
  - con Haiku spento, lezione coi testi di base e nessuna chiamata;
  - con `rifallo: false`, nessuna lezione;
  - con un file `.ts`, riga `lezione` con `stato: "no"`;
  - nel tempo B, con un `dattilo` finto che esce con 1 a `--prova`, la lezione esce senza `## Modifica`.
- **Il controllo della mod** (`node prove/controlla-dalvivo.mjs`): `prove/controlla-dalvivo-main.js` disegna in più:
  - la finestrella con «Rifallo tu», «Rifallo tu ···» e «2 nuove» in testata;
  - la scheda con «Di più · Rifallo tu» e con la riga grigia di un `.ts`;
  - la finestrella con `platform: "windows"` finto, senza tasto.

### 7.2 Prove automatiche in dattilo (`nvim --clean --headless -l tests/run.lua`)

**Come si provano le modalità.** Con `nvim -l`, il modo in cui girano le prove di oggi, `startinsert` non ha effetto (l'ho provato stasera: dopo `startinsert` il modo resta `n`). Le prove che dipendono dalla modalità girano in un **Neovim figlio** `nvim --clean --embed --headless -u init.lua`, pilotato dalla prova con `vim.fn.jobstart(…, { rpc = true })`, `nvim_input` e `nvim_get_mode`. L'ho verificato (appendice): `i` porta in `i`, ‹Esc› riporta in `n`, il figlio si chiude con `jobwait` 0 e niente resta appeso. Funziona anche col dattilo vero (`:w` lancia node e la lezione avanza). Il piano scrive l'aiutante delle prove come primo compito.

Le prove:
- **Pure, senza figlio** (`test_guida_batti.lua`, `test_vivo_canale.lua`):
  - `guida.adesso_batti` su ogni caso della 3.3;
  - `guida.carattere`;
  - G3 su tutti i testi;
  - `vivo.coda`;
  - `vuoi.json` e `stato.json`, permessi, link, file a metà, rotti e spariti.
- **Nel figlio:**
  - **Ogni schermata del giro** ha il riquadro della 3.3 (G1);
  - **Ogni posto sbagliato** della 3.4: ci si entra coi tasti veri, la frase è quella, i suoi tasti riportano indietro col testo intatto (G4);
  - **I messaggi:** dopo ogni ‹:w› `:messages` non ha righe di dattilo (G5);
  - **`:q` e le finestre** (G7);
  - **La bozza:** `jobstop` a metà, poi riapertura (G8);
  - **La coda:** una lezione nuova scritta mentre si scrive → «1 nuova» entro 1,5 s, col testo intatto; una lezione rotta in mezzo non sposta gli id.
- **Il giro «da chi non sa niente»** (G2). Un robot legge «Adesso» e preme solo il primo tasto scritto lì, oppure, se la frase dice «Scrivi il testo grigio», la prossima lettera del grigio. Lungo la strada fa apposta gli errori di chi non sa: una lettera sbagliata, un ‹Invio› a metà riga, ‹Esc› a metà, ‹v›, ‹q› ‹a›, ‹F1›, una freccia. Deve:
  - arrivare al riepilogo della prima lezione e poi aprire la seconda, in meno di 400 passi;
  - trovare a ogni passo il riquadro con «Adesso»;
  - non restare mai più di 3 passi sullo stesso riquadro senza che cambi niente.
- **Le prove di oggi** passano tutte senza ritocchi. Questo prova la compatibilità.

Quello che il figlio non sa fare va nel collaudo in tmux (`tests/vivo_collaudo.sh`):
- «Premi INVIO»: senza interfaccia attaccata non compare mai. Ho provato ad attaccarne una da un padre `nvim -l` (`nvim_ui_attach`), e la chiamata fallisce;
- il ridisegno del riquadro nella riga dei comandi;
- Ctrl-z: nel figlio `--embed` non sospende;
- la chiusura del pannello con SIGHUP.

### 7.3 Lo scenario a clic nel banco nascosto (scenario 13, «Rifallo tu»)

Nel banco della parte 1 (`prove/collaudo/`, `COLLAUDO_BASE=/tmp/claude-1000/collaudo-rifallo`), con:
- dattilo installato nella casa, come in note.md (`<casa>/bin/dattilo` → `~/code/dattilo/bin/dattilo`, il link a `~/.local/share/nvim` per il tema);
- `dalvivo-passo.mjs` col `claude` finto di `--haiku-finto`, esteso perché risponda coi campi `lezione` quando il prompt contiene «Codice da battere» (nel tempo B anche `modifica`, quando c'è «Codice di prima»).

Per ogni passo: cosa si deve vedere, e una foto `rifallo-<n>`.

1. **Il tasto.**
   - Si accende «Dal vivo».
   - Fixture JavaScript con `--haiku-finto`.
   - Nella finestrella il fumetto verde ha «Rifallo tu» in fondo. Nella scheda: «Di più · Rifallo tu».
2. **Il clic.**
   - Entro 2 s, il pannello a destra del terminale di Claude con dattilo, sul briefing.
   - Il riquadro della guida col titolo «COMINCIA · …» e «‹Invio›: apri il codice da riscrivere».
3. **Il giro «da chi non sa niente».** Con `tipo.py` (XTest) si preme **solo** quello che la guida scrive in «Adesso», più le lettere del grigio:
   - ‹Invio›, ‹i›, il codice, con due errori corretti con ‹Backspace›;
   - un ‹Invio› premuto a metà riga, e poi i ‹Backspace› che la guida conta;
   - ‹Esc› a metà, poi ‹A› come dice la guida;
   - un carattere «difficile» col digramma, se il codice ne ha uno;
   - alla fine ‹Esc›, ‹:w› e ‹Invio›.

   Deve comparire la spiegazione, poi il riepilogo. «Premi INVIO» non deve comparire mai.
4. **Una modifica nuova mentre si scrive.**
   - Si comincia una lezione e si lancia `dalvivo-passo.mjs` su un'altra funzione.
   - In dattilo compare «1 nuova» in alto a destra, e nella testata di «Dal vivo» il tasto «1 nuova».
   - Il testo già battuto è intatto.
   - Poi una modifica alla **stessa** funzione che si sta scrivendo: la lezione in corso non cambia, e in coda ce n'è una in più.
5. **Avanti.**
   - ‹Invio› nel riepilogo apre la prossima.
   - `:ultima` porta all'ultima.
   - Un clic su «Rifallo tu» di un passo vecchio porta a quella lezione.
   - Un clic su «2 nuove» porta all'ultima.
6. **I posti sbagliati.**
   - Si premono, con XTest: ‹v›, ‹q› ‹a›, ‹:› e una parola, ‹Ctrl-w› ‹s›, ‹F1›, ‹R›, ‹Ctrl-z›.
   - Dopo ognuno, la foto mostra il riquadro rosso con la frase della 3.4. Premendo i suoi tasti si torna dove si era.
   - Foto `rifallo-6-posti`.
7. **Uscire senza perdere niente.**
   - A metà di un esercizio si chiude il pannello con la × di Herdr.
   - Un clic su «Rifallo tu» riapre dattilo sulla stessa lezione, col testo battuto meno al massimo 2 s, e la guida dice «Ripreso».
   - `:q` ‹Invio› porta all'elenco; ancora `:q` ‹Invio› chiude dattilo e il pannello.
8. **Non JavaScript.** Una fixture `.ts`: nella finestrella nessun tasto; nella scheda la riga grigia.
9. **La sessione finisce.**
   - Si chiude il terminale di Claude: «Dal vivo» si spegne, dattilo resta, in alto a destra «sessione finita: niente lezioni nuove».
   - Chiuso dattilo, entro 10 s la cartella `rifallo/<nome>` non c'è più.
10. **dattilo non c'è.** Una casa senza dattilo nel `PATH`: il clic dà l'avviso «Serve dattilo». Il resto di «Dal vivo» va.
11. **I tempi.**
    - 10 modifiche con «Rifallo tu» acceso: si annota quanto ci mette la riga `spiega` (deve restare sotto i 20 s nella maggior parte dei casi) e quanto la riga `lezione`.
    - Nel tempo B, anche quante delle 10 hanno la Modifica (rischio 5).
    - L'hook resta sotto 150 ms. Non cambia, ma si rimisura.
12. **(Tempo B) La Modifica.** Dopo Batti si apre il codice di prima con l'OBIETTIVO sotto. Si aspettano 15 s: compaiono i tasti. Li si preme uno per uno come dice la guida, poi ‹Esc›: la modifica è fatta, senza par né stelle.

**Quello che il banco non sa fare:** il clic dentro il terminale di dattilo, se `occhi.mjs` non sa cliccare dentro un terminale, e Windows. Si scrivono in `GUASTI.md`. Per Windows basta il controllo della mod con la piattaforma finta (7.1).

---

## 8. Cosa resta a chi costruisce

- I nomi delle funzioni interne, dove non li ho dati io.
- Come dividere `rifallo.js` se cresce.
- Le misure fini dei tasti nella finestrella.
- L'implementazione del lettore di JavaScript: la regola è in 5.4, il codice no.
- L'ordine dei compiti. Il mio consiglio:
  1. `rifallo-logica.js` con le sue prove;
  2. dattilo, tempo A (il piano `docs/superpowers/plans/2026-11-23-rifallo-tu-dattilo.md`);
  3. `rifallo.mjs` e l'aiutante;
  4. la mod;
  5. il banco, e la prova a mano di Andrea;
  6. il tempo B: dattilo (stesso piano, compiti del tempo B), poi la mod (`codiceDiPrima`, `leggiModificaHaiku`, `--prova` nell'aiutante), poi il passo 12 del banco.

  I punti 1 e 2 si possono fare in parallelo: si toccano solo nel formato della lezione e nei tre file di scambio, che sono descritti qui e nel contratto del piano.
- Le note per chi viene dopo: la sezione «Rifallo tu: come si usa» in LEGGIMI.md, una riga in «Cosa non fa ancora», HANDOFF.md, e il README di dattilo per `dattilo vivo`.

---

## 9. Domande per Andrea (cambiano cosa si costruisce)

1. **La tastiera.** La guida dà per scontata quella italiana. Dice che ‹:› si fa con Maiusc e il tasto del punto, e non spiega come si scrivono àèéìòù. Per il collega con un'altra tastiera servirebbe una scelta della tastiera al primo avvio, con frasi diverse per quelle due cose. La facciamo, o per ora va bene la sola tastiera italiana?

Le domande della prima versione hanno avuto risposta da Andrea (sezione 1). Le scelte che ho preso io e che si cambiano in una riga, se Andrea preferisce, sono queste:
- le frecce spente in Batti (G10);
- Ctrl-z spento nelle lezioni guidate (G9);
- `LANGUAGE=it` (5.9);
- riaprire dritti in Batti quando c'è una bozza (G8);
- 15 s prima dei tasti esatti nella Modifica (G12).

---

## Appendice: cosa ho verificato, e come

Tutto in cartelle mie sotto `/tmp/claude-1000/rifallo-prove/` (prima versione) e `/tmp/claude-1000/rifallo-verifica/` (stasera), con `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_STATE_HOME` e `XDG_CACHE_HOME` lì dentro. Non ho toccato `~/.local/share/dattilo`, Herdr, il banco né i repo.

**Prima versione (23/11, giorno).**
- **dattilo con `XDG_DATA_HOME` spostato**, in Neovim 0.12.6 senza interfaccia con `--listen`:
  - `progressi.cartella()` punta alla cartella nuova;
  - `pacchetti.elenco()` vede `corso-c-antirez` e il pacchetto di prova;
  - aprire la lezione, completarla e salvare porta al passo `esegui` (il secondo `:w`);
  - il lavoro finisce sotto `dati/dattilo/lavoro/`.
- **Cache dei pacchetti.** Una lezione aggiunta dopo l'apertura non si vede finché non si chiama `dimentica()`, e `L.prossima` resta `nil`. Una lezione rotta finisce negli errori e non entra fra le lezioni.
- **`node --check`** (Node 26.13.1) sui sette casi della 5.4, circa 20 ms l'uno.
- **`nvim … vivo --dove`** esce con 1 («Unknown option argument»).
- **Neovim 0.12.6:** i digrammi `<<` `>>` `,.` `-M` `-N` `'9` `"6` `"9` `*X` `->` danno « » … — – ’ “ ” × →. Ctrl-C fa `ModeChanged i:n`.
- **Le scelte di Andrea:** riletto il documento `scelte/tavola` dell'artifact `MNwVwedVNWguq1NghQTdfQ` (`dattilo: ["rifallo"]` e la nota sul tempo reale).
- **Senza interfaccia non si vede il «Press ENTER».** Il blocco di `--remote-expr` lo riporto da note.md, non l'ho rifatto.

**Stasera, dopo la correzione.**
- **Le prove di oggi:** `nvim --clean --headless -l tests/run.lua` → «OK 166 test».
- **Il Neovim figlio.** Ho lanciato `nvim --clean --embed --headless -n -i NONE` da un padre `nvim --clean --headless -l`, con `jobstart(…, { rpc = true })`:
  - `nvim_input('i')` → `nvim_get_mode().mode == 'i'`; dopo `ciao` il buffer ha `ciao`; ‹Esc› → `n`;
  - `startinsert` eseguito nel figlio → `i`. Nel padre `nvim -l`, invece, `startinsert` lascia `n`;
  - ‹v› → `v`, ‹:› → `c`, ‹R› → `R`, ‹d› → `no`, ‹i›‹Ctrl-o› → `niI`, ‹q›‹a› → `reg_recording() == 'a'`, ‹Ctrl-w›‹v› → 2 finestre, ‹F1› → 2 finestre con `buftype=help`, ‹i›‹Ctrl-c› → `n`;
  - `ModeChanged` scatta per tutti questi cambi: `n>no`, `n>v`, `n>R`, `n>c`, `i>niI`. Scattano anche `RecordingEnter` e `RecordingLeave`;
  - ‹q›‹:› apre la finestra dei comandi (`getcmdwintype() == ':'`, 2 finestre). ‹Ctrl-c› riporta alla riga dei comandi (`c`, 1 finestra), ‹Esc› a `n`;
  - `nvim_paste` passa da `vim.paste` (sostituito, viene chiamato una volta);
  - `nvim_input_mouse` sulla riga di stato (`%1@v:lua.clic@ZONA%X`) chiama la funzione, anche senza interfaccia;
  - `feedkeys(…, 'xt')` nel figlio funziona;
  - 200 giri di `nvim_input` + `nvim_get_mode` in 18 ms;
  - `qa!` → `jobwait` 0, il padre esce con 0 e niente resta appeso;
  - **col dattilo vero** (`-u init.lua`, `XDG_*` finti, il pacchetto `js-prova`): `lezione.apri`, ‹Invio› → passo `batti`, ‹i› e il codice → modo `i` col testo giusto, ‹Esc›`:w`‹Invio› → passo `modifica`. `:messages` contiene l'esito su più righe (`$ node main.js`, `5`, `Eseguito senza errori.`): è quello che in un terminale vero fa comparire «Premi INVIO».
- **Cosa non funziona nel figlio:**
  - `nvim_ui_attach` chiamato dal padre `nvim -l` fallisce, e senza interfaccia «Premi INVIO» non compare mai (`blocking` resta `false` anche dopo un messaggio su tre righe);
  - Ctrl-z in `--embed` non sospende niente;
  - `vim.on_key` che restituisce `""` su `x`, battendo `a x b` con `nvim_input`, lascia `a^Cb`, non `ab`. La prima versione diceva il contrario. Il disegno nuovo non scarta nessun tasto, quindi non conta più, ma è un motivo in più per non usare un filtro.
- **`LANGUAGE=it`** (senza la locale `it_IT`, che qui non c'è): `:nonesiste` → «E492: Non è un comando dell'editor: nonesiste». `nvim.mo` contiene «Premi INVIO o un comando per proseguire».
- **`VimLeavePre`** scatta:
  - chiudendo la sessione tmux (SIGHUP dal terminale);
  - con SIGTERM;
  - nel figlio, con `jobstop` e con SIGHUP.
- **`TextChanged`:** dopo `iabc` e ‹Esc› non scatta (solo `TextChangedI`, `InsertLeave`, `CursorMoved`); dopo un `nvim_buf_set_lines` in NORMAL scatta. Per questo «testo cambiato in NORMAL» si decide confrontando le righe, non contando gli eventi. Muoversi in NORMAL dà solo `CursorMoved`, che `lezione.lua:302-306` non ascolta: la guida lo ascolta da sé.
- **I digrammi da Lua:** `digraph_get('<<') .. digraph_get(',.') .. digraph_get('->')` = «…→; `digraph_getlist(true)` ha 1366 voci; `★` ha `*2`; `🙂` non ne ha.
- **La soluzione dell'esempio della 5.5** (`2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>`): con la stessa chiamata di `controlla.lua:27-40`, dal codice di partenza arriva all'obiettivo; `conta_tasti` dà 41.
- **ui2** c'è in Neovim 0.12.6 (`vim._core.ui2`), segnato come sperimentale.

---

## Cambiato costruendo (24/11)

I testi della guida nuovi o cambiati rispetto a quelli approvati, uno per riga, col loro nome in `guida_testi.lua`. Le ragioni sono le stesse per tutti: senza, chi segue solo la guida perderebbe testo buono o resterebbe ferma. Se una frase non piace, si cambia lì e basta.

**Testi.**
- `batti_annullato` (nuovo): «Hai annullato del testo che avevi scritto (in NORMAL il tasto u annulla). ‹g› ‹+›: lo rimette; ripetilo finché questa frase non cambia.»
- `batti_spezzata_meta` (nuovo): «La riga %d è stata spezzata in due da un a capo. ‹Backspace›: premilo %s e la riga %d torna intera, col cursore nel punto dove si era spezzata; poi ‹Fine›: vai in fondo alla riga e continua a scrivere.»
- `batti_continua_i` (nuovo, al posto di `batti_indietro_i` quando la riga è intera): «Fin qui è tutto giusto: si va avanti dalla fine della riga %d, l'ultima che hai scritto. ‹Esc›: smetti di scrivere; poi ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.»
- `batti_continua_n` (nuovo, al posto di `batti_indietro_n` quando la riga è intera): «Fin qui è tutto giusto: si va avanti dalla fine della riga %d, l'ultima che hai scritto. ‹%d› ‹G›: vai alla riga %d (il numero, poi G maiuscola); poi ‹A›: scrivi in fondo a quella riga.»
- `frecce_n` (nuovo, la riga 13 della 3.4 in NORMAL): «Le frecce qui sono spente apposta: dattilo insegna i tasti di Vim. ‹A›: torni a scrivere in fondo alla riga. Per spostarti, in NORMAL: ‹h›: sinistra, ‹j›: giù, ‹k›: su, ‹l›: destra.»
- `batti_carattere` (cambiato: in fondo dice le maiuscole): «Il prossimo carattere, %s, non è sulla tastiera. %s: lo scrive (tieni premuto Ctrl e premi la lettera, poi gli altri tasti%s).»
- `maiuscola` e `maiuscole` (nuovi pezzi di `batti_carattere`): «; %s maiuscola», «; %s e %s maiuscole».
- `una_volta` e `volte` (pezzi di `batti_spezzata`, prima scritti nel codice): «una volta», «%d volte».
- `cmd_vuota_testo` (nuovo, la riga dei comandi vuota dove `:w` non salva niente): «‹Esc›: annulli e torni dov'eri. I comandi che valgono qui sono in «Comandi», qui sotto.»
- `cmd_noto` (cambiato: in fondo come uscirne, se il comando era scritto per sbaglio): «‹Invio›: esegui :%s, cioè %s. ‹Esc›: annulli e torni dov'eri.»
- `cmd_parziale` (nuovo, a metà di un comando che vale lì; senza, a ogni lettera di `:salta` la guida direbbe «che qui non serve. ‹Esc›»): «Stai scrivendo il comando :%s. %s ‹Esc›: annulli e torni dov'eri.»
- `cmd_finisci` (nuovo pezzo di `cmd_parziale`): «%s: finisci di scrivere :%s; poi ‹Invio›: %s.»
- `ex` (cambiato: le lettere di visual sono tasti, e il primo tasto è ‹v›, non ‹Invio›): «Sei nella modalità Ex (l'apre g seguito da Q). ‹v› ‹i› ‹s› ‹u› ‹a› ‹l› ‹Invio›: torni allo schermo normale (scrivi visual, poi Invio).»
- `sconosciuto` (cambiato: in un terminale ‹Esc› va al programma, e nemmeno ‹:q› arriva a Neovim; ‹Ctrl-\› ‹Ctrl-n› torna in NORMAL da ogni modalità. **Giro di correzione 1:** tolta l'ultima frase, «Se il codice non si vede più, ‹:q› ‹Invio›: lasci la lezione, che resta salvata», falsa fino al compito 9; dopo ‹Ctrl-\› ‹Ctrl-n› la guida dice da sola come tornare al codice): «Sei in una modalità di Neovim che la guida non conosce (in basso: %s). ‹Ctrl-\› ‹Ctrl-n›: torni in NORMAL, da qualunque modalità (anche da un terminale, dove Esc non basta).»
- `aiuto` e `divisa`: nel compito 5 erano con ‹Ctrl-w› ‹c› (`:q` lasciava la lezione). **Compito 6:** tornano come nel progetto, con ‹:q› ‹Invio›, perché ora `:q` chiude solo la finestra in più: «Si è aperto l'aiuto di Neovim, in inglese (l'apre il tasto F1). ‹:q› ‹Invio›: lo chiudi e torni al codice.» e «Lo schermo si è diviso in due (l'ha fatto Ctrl-w o un comando come :split). ‹:q› ‹Invio›: chiudi questa finestra e torni al codice.»
- `terminale` (nuovo, un terminale in NORMAL: lì ‹Ctrl-\› ‹Ctrl-n› non fa più niente. **Giro di correzione 1:** il ritorno non è più ‹Ctrl-^›, che con due terminali rimbalza fra i due, ma `:b` e il numero del codice; il `%d` è il numero del buffer del codice): «Sei in un terminale dentro Neovim (l'apre il comando :terminal). ‹:b%d› ‹Invio›: torni al codice della lezione, com'era.»
- `controllo_ko_i` (nuovo, il controllo che non passa in INSERT; provvisorio, vedi «Giro di correzione 1»): «Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l'errore non è tuo. ‹Esc›: smetti di scrivere; poi ‹:q› ‹Invio›: lasci la lezione e torni all'elenco, dove scegli un'altra.»
- `controllo_errore` (nuovo, l'errore di node fuori da Batti, in «Controllo»): «Node non accetta il codice: %s.»
- `controllo_muto` (nuovo pezzo, prima scritto nel codice): «il controllo non è riuscito».
- `esegui_ko` (nuovo, passo esegui del tempo B; provvisorio, vedi «Giro di correzione 1»): «Il codice è quello della modifica di Claude, quindi l'errore non è tuo. ‹:q› ‹Invio›: lasci la lezione e torni all'elenco, dove scegli un'altra.»
- `esegui_cambiato` (nuovo, passo esegui del tempo B): «Il codice non è più quello della modifica di Claude. ‹:e!› ‹Invio›: lo rimetti com'era; poi ‹:w› ‹Invio›: lo ricontrolli.»

**Ordine e regole di «Adesso» in Batti** (la tabella della 3.3 è già quella nuova).
- In INSERT la riga spezzata a metà del testo scritto viene prima di tutto: con ‹Fine› e poi ‹Backspace› la coda scesa giù si cancellerebbe.
- In INSERT ‹Fine› viene prima del rosso: col rosso a destra del cursore ‹Backspace› cancellerebbe le lettere giuste a sinistra.
- In INSERT vale `k ≠ r`, non solo `k < r`: con la riga da finire sotto il cursore, ‹Invio› aprirebbe una riga in più e tutto sotto diventerebbe rosso. A metà di una riga intera, con un'altra da finire, si va subito lì.
- In NORMAL `batti_annullato` e `batti_cambiato` vengono prima di «niente scritto»: dopo un `dd` o un ‹u› che svuotano il buffer, ‹i› farebbe riscrivere tutto.
- Con la guida la nota «Riga vuota: … ‹Invio› e vai avanti.» di Batti non si mostra (‹Invio› senza i due punti, G3).

**Il riquadro.**
- «Adesso» vale sempre per il modo in cui si è: il controllo che non passa ha la sua frase in INSERT, e il passo esegui la sua.
- Una parola più larga della riga del riquadro (un nome lunghissimo nell'errore di node, un percorso) si spezza in pezzi che ci stanno, invece di uscire dal bordo.

**I posti sbagliati.**
- Un comando è «noto» (riga 3) solo se «Comandi» lo elenca e se esiste già: `:w` nell'elenco o nella spiegazione non salva niente, `:e!` in Batti cancellerebbe tutto, e `:salta`, `:ultima` ed `:elenco` arrivano col compito 8. Prima di allora la guida li tratta come comandi che lì non servono, e non promette quello che non c'è. `:q` (con `:q!`, `:wq` e `:x`) vale sempre.
- La modalità Ex si controlla prima della riga dei comandi, perché anche lì `getcmdtype()` dà `:`.
- La registrazione ha la sua frase in NORMAL, in INSERT e in REPLACE; negli altri modi prima viene la frase del modo (per esempio ‹Esc› da VISUAL), e poi quella della registrazione.
- ‹Ctrl-z› ha la mappa anche con un operatore in attesa (G9).
- La finestra in più col cursore dentro (riga 12) era già nel compito 5, perché nell'aiuto la guida diceva ‹A›, che lì dà E21 e lascia nell'aiuto. La riga 12b e il nuovo `:q` sono del compito 6 (sezione sotto).


**Giro di correzione 1 (24/11, dopo la revisione del compito 5).**

*Un altro buffer nella finestra della lezione* (riga 18 della 3.4, testi nuovi):
- `altro_buffer` (NORMAL): «Qui non c'è il codice della lezione, ma un altro file (ci si arriva con un comando come :e o :bn, o col tasto Ctrl-^). ‹:b%d› ‹Invio›: torni al codice della lezione, com'era.» Titolo: UN ALTRO FILE.
- `altro_buffer_i` (INSERT, perché lì ‹:› è una lettera): «Stai scrivendo in un altro file, non nel codice della lezione. ‹Esc›: smetti di scrivere; poi ‹:b%d› ‹Invio›: torni al codice della lezione, com'era.»
- `comandi_altro` (la sezione «Comandi» in quel posto, al posto di quella della schermata, che offrirebbe ‹:w› sul file sbagliato): «‹:b%d› ‹Invio›: torni al codice della lezione, com'era»
- `spiega_comando.b` (nuovo, quello che dice la riga dei comandi scrivendo `:b4`: «‹Invio›: esegui :b4, cioè …»): «torni al codice della lezione, com'era»
- `divisa_i` (nuovo, si scrive in una finestra in più, per esempio dopo ‹Ctrl-w› ‹n› e ‹i›; titolo FINESTRA IN PIÙ. In questo giro diceva ‹Ctrl-w› ‹c›; dal compito 6 dice ‹:q› ‹Invio›, come qui): «Stai scrivendo in un'altra finestra, non nel codice della lezione. ‹Esc›: smetti di scrivere; poi ‹:q› ‹Invio›: chiudi questa finestra e torni al codice.»
- Il `%d` è il numero del buffer del codice. Il ritorno è `:b4` e non ‹Ctrl-^›, che porta al buffer alternato e con due buffer qualunque rimbalza fra i due. `:b4` scritto senza spazio vale; la riga dei comandi lo riconosce (e `:b` a metà, con ‹4› per finire) come un comando noto, perché la frase lo dice.
- Dove sta il buffer giusto: `schermo.mostra` ricorda l'ultimo buffer messo nella finestra principale (`schermo.mostrato`: il codice in Batti, il testo della schermata altrove). Se la finestra principale ne mostra un altro, la guida lo dice, in Batti come nel briefing o nell'elenco.
- Nuovi eventi che ricalcolano il riquadro: `BufEnter` e `BufWinEnter` (‹Ctrl-^›, `:e`, `:bn` e ‹Esc› ‹Ctrl-o› non cambiano né il modo né il cursore).
- Le frecce spente valgono solo nel buffer del codice.
- Il briefing e la spiegazione rimasti in giro (‹Esc› ‹Ctrl-o› ci riporta) non rifanno Batti con ‹Invio› o ‹l›, e l'elenco non apre una lezione mentre se ne scrive un'altra: con la guida accesa quei tasti valgono solo nella loro schermata. Prima, un ‹Invio› nel briefing rimasto indietro svuotava il testo di Batti.

*`:e!` nel passo esegui* (tempo B). `esegui_cambiato` dice ‹:e!› ‹Invio›, e la riga dei comandi diceva «che qui non serve». Ora un comando è noto se lo scrive «Comandi» **o «Adesso»** (e se esiste), quindi `:e`, a metà, dà `cmd_parziale` con ‹!›, e `:e!` dà `cmd_noto`. Nei posti dove `:w` o `:e!` scriverebbero o rifarebbero il buffer sbagliato (un altro buffer, una finestra in più) non valgono.

*Frasi che promettevano cose che non ci sono ancora* (testi provvisori, fino ai compiti 8 e 9; i testi approvati restano nelle tabelle della 3.3 e della 3.4, e i compiti 8 e 9 li rimettono):
- Niente ‹:salta›, ‹:ultima› ed ‹:elenco› nei testi: arrivano col compito 8. Dove la frase mandava a ‹:salta›, ora manda a ‹:q›, che c'è:
  - `controllo_ko`: «Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l'errore non è tuo. ‹:q› ‹Invio›: lasci la lezione e torni all'elenco, dove scegli un'altra.»
  - `controllo_ko_i`: lo stesso, con «‹Esc›: smetti di scrivere; poi ‹:q› ‹Invio›: …».
  - `esegui_ko`: «Il codice è quello della modifica di Claude, quindi l'errore non è tuo. ‹:q› ‹Invio›: lasci la lezione e torni all'elenco, dove scegli un'altra.»
  - `attesa_finita`: «La sessione di Claude è finita: non arrivano altre lezioni. ‹:q› ‹Invio›: chiudi dattilo.»
- «Resta salvata» arriva col compito 9 (la bozza). Oggi `:q` da Batti perde il testo: `lezione.batti` svuota il file a ogni apertura. I testi lo dicono prima dell'Invio:
  - `spiega_comando.q`: «lasci la lezione e torni all'elenco»; con del testo scritto (`q_scritto`): «lasci la lezione e torni all'elenco; quello che hai scritto qui non si conserva»;
  - `spiega_comando.q_esci`: «chiudi dattilo» (prima «chiudi dattilo; quello che hai scritto resta»);
  - `errore_dattilo`: «Errore di dattilo: %s. Il tuo testo non è cambiato.» (prima «…è salvato»).
- «Comandi», senza i comandi che non ci sono:
  - `comandi_batti`: «‹:w› ‹Invio›: salvi e node controlla · ‹:q› ‹Invio›: lasci la lezione e torni all'elenco; quello che hai scritto qui non si conserva»;
  - `comandi_testo`: «‹q›: vai all'elenco delle lezioni»;
  - `comandi_modifica`: «‹:e!› ‹Invio›: ricominci la modifica da capo · ‹:q› ‹Invio›: lasci la lezione e torni all'elenco»;
  - `comandi_fatto`: «‹r›: rifai questa lezione · ‹q›: vai all'elenco delle lezioni»;
  - `comandi_elenco` e `comandi_attesa`: «‹:q› ‹Invio›: chiudi dattilo».
- Una prova (`ogni comando scritto nei testi della guida esiste`) guarda ogni ‹:nome› di ogni testo e controlla che il comando esista nel Neovim figlio: quando il compito 8 crea `:DattiloSalta` e gli altri, i testi con ‹:salta› possono tornare, e la prova passa da sola.

**Compito 6 (24/11): `:q` e dintorni.**

*La decisione rimasta aperta, presa da chi coordina (24/11).* `:q` chiude la lezione e riporta all'elenco, come dice il piano. **`:qa` chiude dattilo del tutto**, perché in Vim vuol dire «esci da tutto», e a chi impara va insegnato il significato vero. In tutti e due i casi il lavoro non si perde senza avviso: la riga dei comandi, mentre si scrive `:q` o `:qa`, dice cosa succede al testo scritto (vedi sotto) e ‹Esc› per annullare, e la persona non vede mai un errore di Vim da decifrare. Per il resto si segue il piano.

*Com'è fatto.*
- ‹:q› in una finestra in più (l'aiuto di ‹F1›, una divisione, un terminale, anche con del testo non salvato dentro) chiude solo quella e riporta il cursore nella finestra della lezione. Nella finestra dei comandi (`q:`) fa quello che fa Vim e la chiude. `guida.esci_da_finestra_in_piu()`, chiamata in testa a `DattiloEsci` (init.lua) solo se la guida è accesa.
- `:q` nella finestra della lezione lascia la lezione e va all'elenco, `:q` nell'elenco chiude dattilo (come oggi).
- `:qa` e gli altri «esci da tutto» (`:qa!`, `:qall`, `:quitall`, `:wqa`, `:wqall`, `:xa`, `:xall`) sono abbreviazioni, come `q`, verso il comando `:DattiloEsciTutto`, che fa `qa!`. Esistono solo con la guida accesa (`accendi` li crea, `spegni` li toglie). Il motivo: con del testo non salvato `:qa` di Vim dà E37 ed E162 su due righe («Premi INVIO»), con un terminale acceso un altro errore, e con tutto salvato chiudeva dattilo mentre la guida diceva «che qui non serve». Un modo di scriverlo che non è fra questi (per esempio `:qal`) arriva a Vim com'è.
- La finestra della lezione chiusa in un altro modo (‹Ctrl-w› ‹c›, ‹Ctrl-w› ‹o› da una finestra in più, `:quit` per intero): con una lezione aperta la lezione si rimette nella finestra che resta, con lo stesso buffer di prima, e il riquadro si rifà (`guida.riprendi`, chiamata da schermo.lua prima di tornare alla home, solo con la guida accesa). Se la finestra che resta è il riquadro e ce n'è un'altra, la lezione va nell'altra. Nell'elenco o in attesa, senza lezione aperta, resta com'era: si rifà la schermata.
- Riga 12b della 3.4 (`divisa_principale`, in NORMAL, col cursore nella finestra della lezione e un'altra finestra aperta): «Lo schermo si è diviso in due. ‹Ctrl-w› ‹o›: resta solo la finestra del codice; il riquadro torna da solo.» «Comandi» resta quello della schermata.
- Una finestra in più cambia anche «Comandi» (nuovo `comandi_finestra`): «‹:q› ‹Invio›: chiudi questa finestra e torni al codice». Prima diceva ‹:q› «lasci la lezione», ‹:w› (che nell'aiuto dà E382) e, nel briefing, ‹q› (che lì registra una macro).
- In una finestra in più `:w` ed `:e!` non valgono come comandi noti.

*Testi nuovi del compito 6* (tutti in `guida_testi.lua`):
- `spiega_comando.qa`: «chiudi dattilo del tutto (qa vuol dire «esci da tutto»)»; con del testo scritto (`qa_scritto`): «chiudi dattilo del tutto (qa vuol dire «esci da tutto»); quello che hai scritto qui non si conserva». Così la riga dei comandi dice, scrivendo `:qa`: «‹Invio›: esegui :qa, cioè chiudi dattilo del tutto (qa vuol dire «esci da tutto»); quello che hai scritto qui non si conserva. ‹Esc›: annulli e torni dov'eri.»
- `spiega_comando.q` e `q_scritto`: già nel giro di correzione 1. In una finestra in più `q` è `q_finestra`: «chiudi questa finestra e torni al codice».
- `comandi_finestra`: «‹:q› ‹Invio›: chiudi questa finestra e torni al codice».
- `divisa_i` (cambiato): «Stai scrivendo in un'altra finestra, non nel codice della lezione. ‹Esc›: smetti di scrivere; poi ‹:q› ‹Invio›: chiudi questa finestra e torni al codice.»
- `aiuto`, `divisa`: tornano con ‹:q› ‹Invio› (vedi sopra).
- `divisa_principale`: quello della riga 12b, già nel progetto.
- «Testo scritto» vuol dire: una lezione aperta, nel passo di Batti, della Modifica o di esegui, con almeno una riga non vuota nel buffer del codice.

*Cosa resta ai compiti 8 e 9.* Il compito 8 crea `:salta`, `:ultima` ed `:elenco`, e rimette nei testi quelli del giro di correzione 1. Il compito 9 salva la bozza: allora `:q` e `:qa` non perdono più niente, e `spiega_comando.q`, `q_esci`, `qa` e i «Comandi» tornano a dire «resta salvata».

**Compito 8 (24/11): le schermate di Rifallo tu, `:salta`, `:ultima`, `:elenco`.**

*Testi che tornano come nel progetto* (erano provvisori, vedi «Frasi che promettevano cose che non ci sono ancora»):
- `controllo_ko`: «Node non accetta il codice: %s. Il testo è uguale al grigio, quindi l'errore non è tuo. ‹:salta› ‹Invio›: passi alla prossima lezione.»
- `controllo_ko_i`: lo stesso, con «‹Esc›: smetti di scrivere; poi ‹:salta› ‹Invio›: passi alla prossima lezione.»
- `esegui_ko`: «Il codice è quello della modifica di Claude, quindi l'errore non è tuo. ‹:salta› ‹Invio›: passi alla prossima lezione.»
- `attesa_finita`: «La sessione di Claude è finita: non arrivano altre lezioni. ‹:elenco› ‹Invio›: vedi quelle che ci sono.»
- «Comandi»: `comandi_batti` («‹:w› ‹Invio›: salvi e node controlla · ‹:q› ‹Invio›: lasci la lezione e torni all'elenco; quello che hai scritto qui non si conserva · ‹:salta› ‹Invio›: passi alla prossima · ‹:ultima› ‹Invio›: vai all'ultima modifica di Claude»), `comandi_testo` («‹q›: vai all'elenco delle lezioni · ‹:salta› ‹Invio›: passi alla prossima · ‹:ultima› ‹Invio›: vai all'ultima modifica di Claude»), `comandi_modifica` («‹:e!› ‹Invio›: ricominci la modifica da capo · ‹:q› ‹Invio›: lasci la lezione e torni all'elenco · ‹:salta› ‹Invio›: passi alla prossima»), `comandi_fatto` («‹r›: rifai questa lezione · ‹q›: vai all'elenco delle lezioni · ‹:ultima› ‹Invio›: vai all'ultima modifica di Claude»), `comandi_elenco` («‹:ultima› ‹Invio›: apri l'ultima modifica di Claude · ‹:q› ‹Invio›: chiudi dattilo») e `comandi_attesa` («‹:elenco› ‹Invio›: vedi le lezioni già arrivate · ‹:q› ‹Invio›: chiudi dattilo»). «Resta salvata» e «lo riapre» tornano col compito 9.

*Testi nuovi* (tutti in `guida_testi.lua`):
- `attesa_spento` (nuovo: con «Dal vivo» spento la frase di `attesa_finita` direbbe «la sessione è finita», che non è vero): «Dal vivo è spento: non arrivano altre lezioni. ‹:elenco› ‹Invio›: vedi quelle che ci sono.»
- `elenco_vuoto` («Adesso» dell'elenco quando non c'è nessuna lezione da aprire): «Non c'è nessuna lezione da aprire. ‹:elenco› ‹Invio›: rivedi l'elenco, quando Claude ne ha preparata una.»
- `ultima_gia` e `ultima_niente` («Controllo», quando `:ultima` non porta da nessuna parte): «Questa è già l'ultima modifica di Claude: non ce n'è una più recente da fare.» e «Non c'è nessuna lezione da fare.»
- Le righe del riepilogo (5.11): `riepilogo.etichetta_batti` «Batti», `etichetta_modifica` «Modifica», `etichetta_prossima` «Prossima», `batti` «%d righe in %s», `velocita` «%s parole al minuto · %s di precisione», `modifica` «%d tasti», `prossima` «“%s”», `prossima_vuota` «arriva con la prossima modifica di Claude».
- `fatto_nuova` « (1 nuova)» e `fatto_nuove` « (%d nuove)»: il secondo `%s` di `fatto_coda`.
- `elenco_nuova` «nuova» e `elenco_saltata` «saltata»: a destra di ogni lezione non fatta.
- Le frasi del canale, spostate da `vivo.lua` senza cambiarle, nella tabella `canale`: `nuova` « · 1 nuova», `nuove` « · %d nuove», `finita` « · sessione finita: niente lezioni nuove», `spenta` « · Dal vivo spento: niente lezioni nuove», `dati_fuori` «la cartella dei dati non è dentro quella di Rifallo tu», `assente` «la lezione non c'è» e `attesa` «Aspetto la prossima modifica di Claude a un file JavaScript…».

*Com'è fatto.*
- **Il riepilogo** (`vivo.fatto`) lo disegna `vivo` al posto di `lezione.fine`: l'aggancio sta in `lezione.fine` dopo le prime due righe (`s.passo = 'fine'` e la barra), non in cima, così il passo e la barra sono già quelli giusti. Registra `rifallo/<id>` in `progressi.json` con `wpm`, `precisione` e `tempo_ms`, e subito dopo rilegge i dati: «(1 nuova)» è già quello di adesso. ‹Invio› e ‹l› aprono la prossima, ‹r› la rifà, ‹q› va all'elenco; valgono solo nella loro schermata.
- **Una regola sola per «la prossima».** ‹Invio› nel riepilogo, `:salta` e l'attesa aprono la stessa lezione: la prima dopo la corrente, non fatta e non saltata; se dopo non c'è niente, la prima fra quelle lasciate a metà (né fatte né saltate), che l'attesa aprirebbe comunque. Così il riepilogo non dice «aspetti la prossima modifica» e poi riapre da sola una lezione lasciata. «Saltata» è l'unico modo di dire «non la voglio».
- **`:salta`** segna la lezione come saltata (se non è fatta) e apre la prossima; senza prossima va in attesa. **`:ultima`** apre la lezione non fatta più recente, e se è già quella aperta, o non ce ne sono, lo dice in «Controllo» (`guida.avviso`, che non passa da `eco`: in Batti `eco` sceglie la frase da solo). **`:elenco`** apre l'elenco. Fuori da una lezione `:salta` non fa niente. I tre comandi sono `:DattiloSalta`, `:DattiloUltima` e `:DattiloElenco` con le abbreviazioni in minuscolo, create da `vivo.avvia` e tolte da `vivo.ferma`; scritti con uno spazio dopo (`:salta `) la guida li riconosce lo stesso.
- **L'elenco**: una riga per lezione valida con ✓ (fatta), ▸ (da fare), il titolo e «nuova» o «saltata» a destra. «Nuova» è quella del contratto per chi non ha una lezione aperta: non fatta e non saltata (anche una lasciata a metà). La riga scelta ha lo sfondo, e non è segnata da ▸, che è delle lezioni da fare: ‹Invio› apre quella dove sta il cursore, anche dopo un clic. ‹j› ‹k› e le frecce si fermano alla prima e all'ultima riga, e valgono i numeri davanti.
- **L'attesa** (`vivo.attesa`) si rifà quando `dalvivo` cambia mentre si è lì: la frase è `attesa`, `attesa_finita` o `attesa_spento`.
- **Prove cambiate** (testi provvisori del compito 5 e 6 che il compito 8 toglie): in `test_guida_posti.lua` «il controllo che non passa: seguendo la guida si esce dalla lezione» cerca ‹:salta›, e «un comando che non c'è ancora non si promette» diventa «:salta è un comando noto dove «Comandi» lo scrive»; in `test_guida_schermate.lua` la frase del controllo cerca ‹:salta›; in `test_vivo_avvio.lua` «ridimensionando la finestra il riquadro si rimisura» controlla la larghezza delle righe e non più l'altezza, che con «Comandi» lungo come adesso è la stessa a 120×40 e a 80×24.

**Correzioni della revisione del compito 7 (24/11): il canale aspetta il momento giusto.**
- `canale.assente` (cambiato: parla del file, non della lezione): «il file non c'è più». Si legge in «Controllo» come «Questa lezione non si apre: il file non c'è più.»
- Una richiesta di `vuoi.json` (`apri` o `ultima`) non si esegue, e non si consuma, quando la persona ha qualcosa a metà: la riga dei comandi (anche con `:w` scritto), un operatore in attesa (`d`), la finestra dei comandi (`q:`), «Premi INVIO» o un comando esterno. Si riprova al giro dopo, senza dire niente: sono stati di pochi secondi. Lo stesso vale per la lezione che si apre da sola dall'attesa. `dalvivo` si applica sempre.
- Un `azione` che non sia `apri` o `ultima` scarta il file, come per i tipi sbagliati.
- La lezione aperta entra in `aperte` a ogni giro, anche se non l'ha aperta `vivo.apri`.
- `parti_canale` gira protetta come il timer: un errore all'avvio va nel riquadro, e il timer parte lo stesso.

**Compito 9 (24/11): la bozza, niente testo perso.**

*Testi che tornano a «resta salvata»* (erano provvisori fino alla bozza; i nomi sono gli stessi):
- `comandi_batti`: «‹:w› ‹Invio›: salvi e node controlla · ‹:q› ‹Invio›: lasci la lezione e torni all'elenco; resta salvata · ‹:salta› ‹Invio›: passi alla prossima · ‹:ultima› ‹Invio›: vai all'ultima modifica di Claude». Rispetto al progetto («lasci la lezione, resta salvata») dice anche dove si va, perché chi non sa Vim deve saperlo prima dell'Invio.
- `comandi_elenco`: «‹:ultima› ‹Invio›: apri l'ultima modifica di Claude · ‹:q› ‹Invio›: chiudi dattilo (quello che hai scritto resta, e «Rifallo tu» lo riapre)» (è la frase del progetto).
- `spiega_comando.q_scritto` (con del testo scritto, nella lezione): «lasci la lezione, che resta salvata, e torni all'elenco». `spiega_comando.q` (senza testo) resta «lasci la lezione e torni all'elenco».
- `spiega_comando.q_esci` (nell'elenco e nell'attesa): «chiudi dattilo; quello che hai scritto resta».
- `spiega_comando.qa_scritto`: «chiudi dattilo del tutto (qa vuol dire «esci da tutto»); quello che hai scritto resta salvato».
- `errore_dattilo`: «Errore di dattilo: %s. Il tuo testo è salvato.»

*Com'è fatto.*
- **Quando si salva** (`bozze/<id>.json`, solo nel passo di Batti, solo se le righe sono cambiate): uscendo dalla scrittura (`ModeChanged` in uscita da INSERT o REPLACE, perché con ‹Ctrl-c› `InsertLeave` non scatta), lasciando la lezione (un solo punto, `lascia`, in `vivo.apri`, nell'elenco e nell'attesa: ci passano ‹:q›, ‹:salta›, ‹:ultima›, le richieste della mod e ‹q›), alla chiusura di Neovim (`VimLeavePre`) e, mentre si scrive, al massimo ogni 2 secondi dentro `controlla`. Alla chiusura si riscrive anche `stato.json` (`aperte` deve sopravvivere).
- **Chiuso da fuori** (SIGTERM, SIGHUP: il pannello chiuso): Neovim scarica i buffer prima di `VimLeavePre`, e il buffer risponde senza righe. Il testo si prende allora da quello che `batti.lua` ha già visto (`st.prima`, aggiornato a ogni modifica). Visto nelle prove: senza questo ripiego la bozza si cancellava proprio in questo caso.
- **Riaprendo** (`vivo.apri`): con una bozza di Batti si va dritti a Batti, senza briefing, col testo di prima, il cursore in fondo all'ultima riga scritta, «Controllo» che dice `ripreso` (sparisce al primo tasto) e «Adesso» `batti_riprendi` (‹A›). Solo la riapertura rimette la bozza: un `:e!` ricomincia da capo.
- **La bozza si toglie** quando la lezione è fatta, e quando il buffer di Batti è tornato vuoto (una bozza vecchia riporterebbe testo che la persona ha cancellato). Una bozza che non è fatta bene (non è JSON, `v` diversa, righe che non sono stringhe o con un a capo, vuota, più di 262144 byte o 2000 righe, passo sconosciuto o `modifica`, che è del tempo B) non si legge: si parte dal briefing, senza errori.
- **Collegamenti**: `bozze/` che è un collegamento, o un file di bozza che è un collegamento, non si leggono; scrivendo, il collegamento è sostituito da un file vero e il bersaglio non cambia; `bozza_togli` toglie il collegamento e non il bersaglio. Leggere o togliere una bozza non crea `bozze/` (`dir_bozze(true)`).
- **La richiesta della mod che cambia lezione mentre si scrive** (il caso lasciato dal compito 7) non perde più il testo: la lezione si salva prima di chiudersi, e riaprendola il testo c'è.
- **Prove cambiate**: in `test_guida_posti.lua` la prova «nessun testo promette quello che il compito 9 non ha ancora fatto» è tolta (la bozza c'è); al suo posto `test_vivo_bozza.lua` prova che i testi di ‹:q› e ‹:qa› dicono la verità.

**Giro di correzione 2 (24/11, dopo la revisione dei compiti 5 e 6).**

*Testi nuovi* (`guida_testi.lua`):
- `posti.cmd_vuota_ritorno` (la riga dei comandi vuota in un altro file o in una finestra in più: «Adesso» continua la strada, non dice ‹Esc›; il `%s` è un `cmd_finisci` col comando di ritorno): «Stai scrivendo un comando. %s ‹Esc›: annulli e torni dov'eri.» Per esempio: «Stai scrivendo un comando. ‹b› ‹4›: finisci di scrivere :b4; poi ‹Invio›: torni al codice della lezione, com'era. ‹Esc›: annulli e torni dov'eri.»
- `posti.cmd_noto_spiegazione` (`:q`, `:qa` e sinonimi dalla spiegazione; la lezione si segna solo al riepilogo): «‹Invio›: esegui :%s, cioè %s. Ma la lezione non conta come fatta finché non arrivi al riepilogo. ‹Esc›: annulli e resti qui; poi ‹Invio›: vai al riepilogo e la finisci.» In una finestra in più `:q` chiude solo la finestra (nessuna frase); `:qa` ha la frase anche lì.
- `comandi_spiegazione` («Comandi» nella spiegazione, al posto di `comandi_testo`): «‹q›: vai all'elenco delle lezioni, ma la lezione non conta come fatta finché non arrivi al riepilogo · ‹Invio›: vai al riepilogo». Chi rimette ‹:salta›, ‹:elenco› ecc. in `comandi_testo` li metta anche qui.
- `posti.divisa_principale` (cambiato, B7: «la finestra del codice» non vale nell'elenco e nel briefing): «Lo schermo si è diviso in due. ‹Ctrl-w› ‹o›: resta solo questa finestra; il riquadro torna da solo.»

*Com'è fatto.*
- «Comandi» è quello del luogo (`comandi_luogo`, al posto di `COMANDI_POSTO`): in un altro buffer `comandi_altro`, in una finestra in più (anche la finestra dei comandi `q:`) `comandi_finestra`, in ogni posto sbagliato che ci si trovi, anche mentre si scrive un comando.
- `finisci()` (estratta dal ciclo di `cmd_parziale`) dà i tasti che mancano a un comando.
- `:b 4` (con lo spazio) vale come `:b4`.
- Con la guida le abbreviazioni (`q`, `q!`, `wq`, `x`, `e!`, e quelle di `:qa`) guardano la riga senza gli spazi davanti: `: qa` e `: q` fanno quello che la guida dice (`init.abbreviazioni(true)`, tolte da `spegni`).
- La prova «ogni comando scritto nei testi esiste» vede anche i comandi in chiaro (`:nome`) e accetta solo il nome intero, un comando di dattilo (`:salta` è `:DattiloSalta`) o una delle abbreviazioni scritte apposta (`w`, `q`, `e`, `b`, `bn`, `qa`): ‹:sal› non passa.

**Dopo l'unione dei rami (25/11): compiti 8 e 9 con le correzioni 5 e 6.**
- «Comandi» della spiegazione (`comandi_spiegazione`) scrive anche ‹:salta› e ‹:ultima›, come `comandi_testo` del briefing: la spiegazione legge `comandi_spiegazione`, e senza quelle due voci la guida diceva «qui non serve» a un comando che funziona. La prova «ogni comando scritto fa quello che dice» guarda ogni voce di quella riga.
- Le abbreviazioni di `:salta`, `:ultima` ed `:elenco` (`vivo.lua`, `crea_comandi`) guardano la riga senza gli spazi davanti, come quelle di `:q` (B3): la guida riconosce `: salta` e promette «‹Invio›: esegui :salta», e prima Vim rispondeva E492.
