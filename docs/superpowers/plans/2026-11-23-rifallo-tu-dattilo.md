# «Rifallo tu» dentro dattilo: piano di costruzione

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `dattilo vivo <cartella>` apre le lezioni di «Rifallo tu» come lezioni normali di dattilo, con Vim vero e una guida sempre accesa che dice a chi non sa Vim che tasto premere e cosa fa. Le lezioni arrivano da una cartella guardata ogni 500 ms.

**Architecture:**
- Tre moduli nuovi:
  - `guida.lua`: il riquadro sempre acceso, «Adesso», i posti sbagliati;
  - `guida_testi.lua`: tutte le frasi;
  - `vivo.lua`: cartella, coda, `vuoi.json` e `stato.json`, bozze, riepilogo, elenco, attesa.
- La guida è un livello che si accende con `guida.accendi(fornitore)`, e oggi la accende solo `vivo`.
- I moduli di oggi cambiano in punti nominati, ognuno dietro `if M.guida` o `vivo.attivo()`.
- Tempo A: Batti, spiegazione e riepilogo. Tempo B, dopo la prova a mano: la Modifica coi tasti verificati.

**Tech Stack:** Lua in Neovim 0.12.6 (`nvim --clean`), `node --check` (Node 26.13.1) come giudice, un Neovim figlio `--embed` pilotato via RPC per le prove con le modalità, tmux per il collaudo.

**Spec:** `docs/superpowers/specs/2026-11-23-rifallo-tu-design.md`. Servono le sezioni 2 e 3 (tutta), 4-B, 5.2, 5.5, 5.7 e 5.9, la 7.2 e l'appendice. Le frasi esatte stanno nella 3.3 e nella 3.4.

## Global Constraints

- Si lavora solo in `/home/frumorn/code/dattilo-wt/rifallo`, ramo `rifallo`. Niente push.
- Non si toccano il dattilo installato né i dati veri: `~/.local/share/dattilo`, `~/.config`, `/home/frumorn/code/dattilo`. Ogni prova e ogni prova a mano usa `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_STATE_HOME` e `XDG_CACHE_HOME` in una cartella temporanea sotto `/tmp/claude-1000/`.
- **Il comando delle prove** (sotto lo si chiama così), con un filtro facoltativo:
  ```bash
  P=$(mktemp -d /tmp/claude-1000/dattilo-prove.XXXXXX); XDG_DATA_HOME=$P/d XDG_CONFIG_HOME=$P/c XDG_STATE_HOME=$P/s XDG_CACHE_HOME=$P/k nvim --clean --headless -l tests/run.lua [filtro]
  ```
  **Il cancello**, dopo ogni compito e senza filtro: nessuna riga `FALLITO` né `ERRORE caricando`, e l'ultima riga è `OK <n> test`, con `n` uguale a 166 più le prove aggiunte fino lì.
- Il dattilo di oggi, senza «Rifallo tu», non cambia. Le prove di oggi (`tests/test_*.lua`, «OK 166 test» prima del compito 1) non si modificano: le prove nuove stanno in file nuovi.
- Codice nuovo in moduli suoi: `guida.lua`, `guida_testi.lua`, `vivo.lua`. I moduli di oggi si toccano solo nei punti nominati nei compiti, e ogni aggancio sta dietro `if M.guida`, `guida.attiva()` o `vivo.attivo()`.
- Niente rete. Nessun comando di shell nuovo lanciato da dattilo: si lanciano solo `node` e `bwrap`, come oggi. I comandi `:` ammessi nelle soluzioni di `formato.lua` restano `:s`, `:sort`, `:noh` e i numeri di riga. La lista dei tasti rifiutati invece è stata **allargata** il 24/11 (compito 14, giro di correzione 1), dopo aver controllato che nessuna lezione esistente venga rifiutata (71 file, 422 righe di soluzione, 0 rifiutate): ora ferma anche la finestra dei comandi (`q:`, `q/` e `q?` fuori da una macro, `<C-f>`), il modo Ex (`gQ`), i registri d'espressione (`<C-r>=`, `"=`, `@=`, `<C-\>e`), `:@` e `:=`, e dentro un comando `:` ogni tasto speciale.
- Le cartelle del canale si creano a 0700 e i file a 0600. dattilo non segue link fuori dalla cartella data (vedi il contratto).
- I testi a schermo sono in italiano, esatti come nella 3.3 e nella 3.4 del progetto, e stanno tutti in `guida_testi.lua`.
- Codice, commenti e commit in italiano.
- Commit di una riga `feat:`, `fix:` o `docs:`, e in fondo, dopo una riga vuota:
  ```
  Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01CCSPYrsdC5Cmw7E9ysfsgp
  ```
  Nei compiti c'è solo la prima riga: le due in fondo vanno sempre.
- Quello che si vede solo in un terminale vero va nel compito di collaudo in tmux. Se non si riesce, si scrive «non verificato» col motivo.

## Il contratto con la mod

Questa sezione è il contratto fra dattilo e la mod di Herdr. Il piano del lato mod si appoggia qui. Le parti segnate **(tempo B)** arrivano coi compiti 13-16.

### La riga di comando

| Comando | Cosa fa | Uscita |
|---|---|---|
| `dattilo vivo --dove` | stampa una riga `{"vivo":1,"radice":"<cartella del repo dattilo>"}`. Nel tempo B `"vivo":2`; fino al compito 15 (la Modifica guidata) dattilo dice `"vivo":1` anche se `--prova` c'è già (25/11) | 0 |
| `dattilo vivo <cartella> [opzioni di nvim]` | `XDG_DATA_HOME=<cartella>/dati`, `DATTILO_VIVO=<cartella>`, `LANGUAGE=it`, poi `exec nvim --clean -u <radice>/init.lua <opzioni>` | quella di nvim: 0 quando si chiude con `:q` dall'elenco |
| `dattilo vivo` senza cartella, o con un percorso che non è una cartella | scrive `uso: dattilo vivo <cartella> [opzioni di nvim]` su stderr | 1 |
| `dattilo vivo --prova <lezione.md>` **(tempo B)** | Controlla il formato. Rifà i tasti di ogni Modifica in un Neovim senza interfaccia, **solo dentro `bwrap`**: i tasti di una lezione non si eseguono mai fuori dalla sandbox, e senza sandbox (`bwrap` manca o non funziona, o c'è `DATTILO_SANDBOX=0`) il comando esce subito con 2 senza provare niente, prima di leggere il formato. Il Neovim figlio vede la cartella della lezione in sola lettura e scrive solo in una sua cartella temporanea; il verdetto lo decide il processo di fuori, che confronta il testo lasciato dal figlio con l'obiettivo. Se tutto va, riscrive le righe `par:` col numero dei tasti, in modo atomico. Tetto di 9 s. Stampa una riga JSON. | 0: `{"ok":true,"modifiche":[{"tasti":41}]}` · 1: `{"ok":false,"motivo":"…"}` (lezione rifiutata: formato, tasti non ammessi, tasti che non arrivano all'obiettivo, tempo scaduto) · 2: `{"ok":false,"motivo":"…"}` (lezione non giudicata: uso sbagliato, file illeggibile o link, con `uso: dattilo vivo --prova <lezione.md>`; `senza sandbox i tasti di una lezione non si provano`; `la sandbox non è partita: …`; `non riesco a riscrivere il par: …`; `non riesco a creare la cartella temporanea della prova: …`) |
| dattilo vecchio, senza `vivo` | `nvim` riceve `vivo --dove` e rifiuta con «Unknown option argument» | 1 |

Come la mod distingue i casi:
- `exec` rifiutato vuol dire che dattilo manca;
- uscita 0 con `vivo ≥ 1` vuol dire che c'è; con `vivo ≥ 2` sa anche fare `--prova`;
- ogni altra cosa vuol dire un dattilo vecchio.

`--prova` riceve un file temporaneo che non finisce in `.md`, per esempio `lezioni/003-x.md.4242`. Il nome non conta per la prova. Se l'uscita è 0, la mod gli dà il nome finale; se è 1, riscrive la lezione senza `## Modifica`; se è 2 con «senza sandbox i tasti di una lezione non si provano», la lezione non è né approvata né rifiutata ma la Modifica non si offre, e la mod scrive la lezione senza `## Modifica`: resta il Batti. Negli altri casi dell'uscita 2 (bwrap che non parte, par che non si riscrive, uso sbagliato) la lezione non è stata giudicata: una Modifica non provata non si offre mai. Tempo massimo consigliato: 10 s; dattilo ferma la prova a 9 s.

### L'albero

```
<cartella>/                 0700, la crea la mod
  indice.json               mod/aiutante; dattilo non lo legge
  vuoi.json                 mod → dattilo
  stato.json                dattilo → mod (0600)
  bozze/                    dattilo (0700)
    <id>.json               dattilo (0600)
  dati/                     XDG_DATA_HOME di dattilo
    dattilo/pacchetti/rifallo/pacchetto.json          mod, una volta
    dattilo/pacchetti/rifallo/lezioni/<id>.md         mod/aiutante
    dattilo/lavoro/rifallo/<id>/<file>                dattilo: il file controllato con node --check
    dattilo/progressi.json                            dattilo: chiave "rifallo/<id>"
```

### I file, campo per campo

- **`pacchetto.json`** (mod): `{"id":"rifallo","titolo":"Rifallo tu · <progetto>","versione":"0.1.0","linguaggio":"javascript","richiede":[],"esecuzione":{"tipo":"controllo","comando":["node","--check","{file}"]}}`.
- **`lezioni/<id>.md`** (mod/aiutante): il formato normale di dattilo, con le regole della 5.5 del progetto.
  - L'id è il nome senza `.md`, e deve rispettare `^%d%d%d%-[a-z0-9%-]+$`.
  - dattilo apre sempre **per id**, mai per numero.
  - Niente `## Rompi` né `## Uscita`; dattilo li ignorerebbe, ma la mod non li scrive.
  - **(tempo B)** Al massimo una `## Modifica`, col blocco ```` ```js partenza ````, il blocco obiettivo e `### Tasti`, passata da `--prova`.
  - Il file temporaneo non finisce in `.md`.
- **`vuoi.json`** (mod, scritto in modo atomico): `{"v":1,"t":1795443912000,"azione":"apri","lezione":"003-codicepulito","dalvivo":"acceso"}`.

  | Campo | Tipo | Significato |
  |---|---|---|
  | `v` | 1 | versione; un altro valore → file ignorato |
  | `t` | intero, ms dal 1970 | quando è stato chiesto; dattilo esegue l'azione solo se `t` è più grande dell'ultimo eseguito |
  | `azione` | `"apri"` \| `"ultima"` | apri `lezione`, oppure l'ultima della coda |
  | `lezione` | id, solo con `"apri"` | un id fuori dal modello → azione ignorata |
  | `dalvivo` | `"acceso"` \| `"spento"` \| `"finita"` | dattilo lo legge a ogni giro, anche senza azione nuova |

  All'avvio vale lo stesso: se c'è una richiesta con un `t` più nuovo di quello in `stato.json`, la si esegue.
- **`stato.json`** (dattilo). Si scrive in `stato.json.<pid>` a 0600 e poi si rinomina. Si riscrive solo quando cambia qualcosa oltre a `t`.
  ```json
  {"v":1,"t":1795443913000,"lezione":"003-codicepulito","schermo":"batti","nuove":2,"prossima":"004-nomefile","ultima":"005-azioni","aperte":["001-somma","003-codicepulito"],"fatte":["001-somma"],"saltate":[],"eseguita":1795443912000}
  ```
  | Campo | Tipo | Significato |
  |---|---|---|
  | `lezione` | id \| `null` | la lezione aperta; `null` in elenco e attesa |
  | `schermo` | `"briefing"` \| `"batti"` \| `"modifica"` \| `"spiegazione"` \| `"fatto"` \| `"elenco"` \| `"attesa"` | dove è la persona |
  | `nuove` | intero | lezioni lette senza errori, dopo quella in corso, non fatte e non saltate; senza lezione in corso, tutte quelle non fatte e non saltate |
  | `prossima` | id \| `null` | la prima di quelle nuove |
  | `ultima` | id \| `null` | la più recente non fatta, quella di `:ultima` |
  | `aperte` | lista di id | aperte almeno una volta, in ordine di prima apertura. Sopravvive alla chiusura, perché si rilegge all'avvio |
  | `fatte` | lista di id | quelle con `rifallo/<id>` in `progressi.json` |
  | `saltate` | lista di id | lasciate con `:salta` e non fatte dopo. Si rilegge all'avvio |
  | `eseguita` | intero | il `t` dell'ultima richiesta di `vuoi.json` eseguita |
- **`bozze/<id>.json`** (solo dattilo; la mod non lo legge, e lo cancella con la cartella): `{"v":1,"passo":"batti","righe":["function somma(a, b) {","    if (ty"]}`. `passo` è `"batti"` oppure, nel tempo B, `"modifica"`.

### Come dattilo si accorge delle novità

- Un timer ogni **500 ms** chiama `vivo.controlla()`. Fa `fs_lstat` di `vuoi.json` (data di modifica e dimensione), `fs_stat` della cartella `lezioni/` e di ogni `lezioni/*.md` (data e dimensione). Se la «firma» cambia, rilegge.
- Una lezione nuova è letta entro 1 s dalla scrittura.
- La mod non aspetta mai dattilo: se dattilo è occupato, legge al giro dopo.

### File a metà, rotti o spariti

- **`vuoi.json` a metà o rotto** (non è JSON, `v ≠ 1`, campi del tipo sbagliato): si ignora in quel giro e si rilegge al giro dopo, anche se la firma non è cambiata. Non compare nessun errore a schermo.
- **Lezione rotta:** resta negli errori del pacchetto (pacchetti.lua:44-54), non entra in coda e non conta fra le nuove. Non sposta gli id delle altre. Chiesta per id, dà `non_si_apre` («Questa lezione non si apre: <errore>.») nel riquadro e l'elenco.
- **Spariti:**
  - `vuoi.json` mancante vuol dire nessuna richiesta;
  - `lezioni/` o `pacchetto.json` mancanti vogliono dire coda vuota;
  - la lezione in corso resta in memoria anche se il suo file sparisce.
- **Cartella vuota all'avvio** (le prime lezioni non sono pronte): «Attesa», e la prima lezione che arriva si apre da sola.

### Id e link

- Id ammessi: `^%d%d%d%-[a-z0-9%-]+$`. Un id diverso, in `vuoi.json` o come nome di file, si scarta. Così nessun percorso esce dalla cartella.
- dattilo usa `fs_lstat` e rifiuta:
  - `vuoi.json` se non è un file normale (un link, una cartella);
  - `bozze/` se non è una cartella normale: in quel caso non salva bozze;
  - un file di bozza che è un link.
- `fs_realpath(<cartella>/dati)` deve cominciare con `fs_realpath(<cartella>) .. '/'`. Altrimenti dattilo mostra «Attesa» con `non_si_apre` («la cartella dei dati non è dentro quella di Rifallo tu») e non apre lezioni.
- `stato.json` e le bozze si scrivono con un file nuovo e un `fs_rename`. Se al loro posto c'era un link, il rename sostituisce il link e non lo segue.

## Come si provano le modalità (verificato il 23/11 sera)

Le prove di oggi girano con `nvim -l`. Lì `startinsert` non ha effetto: l'ho provato, e dopo `startinsert` il modo resta `n`. Le prove che dipendono dalla modalità girano quindi in un **Neovim figlio**.

**Cosa ho provato** (script in `/tmp/claude-1000/rifallo-verifica/embed/`, con `XDG_*` lì dentro). Un padre `nvim --clean --headless -l padre.lua` lancia `vim.fn.jobstart({ 'nvim', '--clean', '--embed', '--headless', '-n', '-i', 'NONE' }, { rpc = true })`.
- **Funziona:**
  - `nvim_input('i')` porta `nvim_get_mode().mode` a `i`, e ‹Esc› la riporta a `n`;
  - `startinsert` eseguito nel figlio porta a `i`;
  - ‹v›, ‹:›, ‹R›, ‹d›, ‹i›‹Ctrl-o› danno `v`, `c`, `R`, `no`, `niI`;
  - `ModeChanged`, `RecordingEnter` e `RecordingLeave` scattano;
  - ‹q›‹:› apre la finestra dei comandi; ‹Ctrl-c› poi ‹Esc› la chiude;
  - ‹F1› apre una finestra con `buftype=help`;
  - `nvim_paste` passa da `vim.paste`;
  - `nvim_input_mouse` sulla riga di stato chiama la zona cliccabile;
  - con `env = { LANGUAGE = 'it' }` gli errori di Neovim sono in italiano;
  - 200 giri `nvim_input` + `nvim_get_mode` in 18 ms;
  - `nvim_command('qa!')` → `jobwait` 0; `jobstop` → `jobwait` −3 e `VimLeavePre` scatta; con SIGHUP `VimLeavePre` scatta. Il padre esce con 0, e niente resta appeso;
  - **col dattilo vero** (`-u init.lua`, il pacchetto `js-prova` in un `XDG_DATA_HOME` finto): briefing → ‹Invio› → Batti → ‹i› e il codice → ‹Esc›`:w`‹Invio› → passo `modifica`, col `:messages` pieno dell'esito su più righe.
- **Non funziona, e va nel collaudo in tmux:**
  - `nvim_ui_attach` chiamato dal padre fallisce. Senza interfaccia «Premi INVIO» non compare mai (`blocking` resta `false`). G5 si prova quindi due volte: nel figlio controllando `:messages`, e in tmux cercando «INVIO» sullo schermo;
  - Ctrl-z con `--embed` non sospende;
  - il ridisegno del riquadro mentre Neovim è nella riga dei comandi o aspetta un operatore.
- **Da sapere:** `vim.on_key` che restituisce `""` su `x`, battendo `a x b` con `nvim_input`, ha lasciato `a^Cb`. Nessun compito scarta tasti: l'unico `on_key` (compito 15) osserva e restituisce sempre `nil`.

L'aiutante delle prove (compito 1) è `tests/vivo_figlio.lua`. In tmux, come `tests/e2e.sh`, si prova quello che il figlio non sa fare (compito 11). In tmux ho già verificato che `VimLeavePre` scatta chiudendo la sessione (SIGHUP) e con SIGTERM.

## Review Focus

Le cinque cose che farebbero più male a chi non sa Vim, e che nessuna prova ovvia coprirebbe:

1. **‹i› dopo ‹Esc›.** ‹Esc› in fondo a una riga sposta il cursore indietro di una lettera. Se la guida dicesse ‹i›, la lettera dopo finirebbe prima dell'ultima e diventerebbe rossa, e la persona non capirebbe perché. La guida deve dire ‹A›. → compito 3, prova «Esc in fondo e poi la frase: si riprende senza rosso».
2. **«Premi INVIO» causato da dattilo.** Viene dagli esiti di ‹:w› su più righe (compila.lua:151-182) o da un errore Lua in una funzione della guida, e blocca lo schermo dove la guida non può parlare. → compito 4, prove «:w a metà…», «node che rifiuta…» e «un errore della guida va nel riquadro…».
3. **`:q` nell'aiuto.** `:q` nell'aiuto aperto per sbaglio con ‹F1› butta fuori dalla lezione, perché `:q` è `DattiloEsci` (init.lua:4-14). → compito 6, prova «F1 e poi :q: si torna in Batti col testo».
4. **La riga spezzata.** Dopo un ‹Invio› troppo presto, dattilo mette il rientro della riga dopo (batti.lua:103-108). ‹Backspace› va premuto più volte: prima toglie il rientro, 4 spazi alla volta, poi riunisce. Se la guida dicesse «una volta», la persona resterebbe lì. → compito 3, prova «Invio presto: i Backspace contati riuniscono la riga».
5. **Il pannello chiuso di colpo a metà riga.** Le prove ovvie escono con `:q`. → compito 9, prova «chiuso di colpo a metà: riaprendo il testo c'è».

---

### Task 1: Il banco delle prove: un Neovim figlio e la cartella finta

**Modello:** Sonnet. È codice di servizio con firma e prove già scritte qui, e la parte rischiosa (se il figlio regge) è già verificata.

**File:**
- Crea: `tests/vivo_figlio.lua`, `tests/test_vivo_banco.lua`
- Crea: `tests/fixture/rifallo/dati/dattilo/pacchetti/rifallo/pacchetto.json`, `.../lezioni/001-somma.md`, `.../lezioni/002-saluto.md`

**Interfacce:**
- Usa: `init.lua` di oggi.
- Dà (in `tests/vivo_figlio.lua`, caricato con `dofile(RADICE .. '/tests/vivo_figlio.lua')`):
  - `M.cartella(nome?: string) → string`: copia `tests/fixture/<nome or 'rifallo'>` in una cartella nuova (`vim.fn.tempname()`) a 0700 e la restituisce;
  - `M.avvia(o: { cartella?: string, vivo?: boolean, righe?: integer }) → F`;
  - `M.con(o, fn: fun(F))`: avvia il figlio, esegue `fn` dentro `xpcall`, **chiude sempre**, poi rilancia l'errore;
  - `F:input(tasti)`, `F:modo() → string`, `F:lua(codice, ...) → any`, `F:righe() → string[]` (la finestra corrente), `F:aspetta(cond: fun(F): boolean, ms = 3000) → boolean`, `F:messaggi() → string`, `F:chiudi()`;
  - i campi `F.canale`, `F.pid`, `F.cartella`.

- [ ] **Passo 1: le fixture.**
  - `pacchetto.json` è il manifesto del contratto, col titolo `"Rifallo tu · prove"`.
  - `001-somma.md` ha l'intestazione `titolo: "La somma"`, `breve: "somma"`, `etichetta: "Rifallo tu"`, `file: "somma.js"`, `fonte: "src/conti.js, righe 3-6"`, `tempo: "circa 1 minuto"`. Il Batti, a 4 spazi:
    ```js
    function somma(a, b) {
        if (typeof a !== "number") return 0;
        return a + b;
    }
    ```
    Poi `### Blocchi` con `1-4: La funzione | Prende due numeri e li somma. | La riga 2 è quella nuova di Claude.`, `### Suggerimenti` con `2: Riga cambiata da Claude: se a non è un numero, restituisce 0.`, e `## Spiegazione` con `2: Il controllo nuovo. | typeof dice il tipo di un valore.`
  - `002-saluto.md`: `breve: "saluta"`, `file: "saluto.js"`, e il Batti:
    ```js
    function saluta(nome) {
        return "«" + nome + "»";
    }
    ```
- [ ] **Passo 2: la prova che fallisce**, `tests/test_vivo_banco.lua`:
  - `'banco: la cartella finta è a 0700 e ha due lezioni lette senza errori'`:
    - `vim.uv.fs_stat(c).mode % 512 == 448`;
    - `pacchetti.carica_cartella(c .. '/dati/dattilo/pacchetti/rifallo')` ha `#lezioni == 2` e `#errori == 0`.
  - `'banco: il figlio entra in INSERT e ne esce'`, con `M.con({ cartella = c })`, senza `vivo`:
    - `F:lua('require("dattilo.lezione").apri("rifallo", 1)')`, poi ‹CR›: `F:lua('return require("dattilo.lezione").s.passo') == 'batti'`;
    - `F:input('i')` → `F:modo() == 'i'`;
    - `F:input('function')` → `F:righe()[1] == 'function'`;
    - `F:input('<Esc>')` → `'n'`.
  - `'banco: gli XDG del figlio stanno nella cartella temporanea'`: `XDG_DATA_HOME == c .. '/dati'`, `LANGUAGE == 'it'`, e `XDG_CONFIG_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME` cominciano con `/tmp/`.
  - `'banco: il figlio si chiude anche se la prova fallisce'`: `pcall(M.con, {}, function(F) canale = F.canale error('apposta') end)` → `false`, e `vim.fn.jobwait({ canale }, 0)[1] ~= -1`.
- [ ] **Passo 3: lancia** il comando delle prove con filtro `test_vivo_banco`. Deve dire `ERRORE caricando test_vivo_banco.lua` (manca `vivo_figlio.lua`).
- [ ] **Passo 4: scrivi `tests/vivo_figlio.lua`.**
  - Il figlio: `{ 'nvim', '--clean', '--embed', '--headless', '-n', '-i', 'NONE', '-u', RADICE .. '/init.lua' }` con `rpc = true`.
  - `env`: `XDG_DATA_HOME = (o.cartella or tmp) .. '/dati'`; gli altri tre `XDG_*` sotto un `tempname()`; `LANGUAGE = 'it'`; `DATTILO_VIVO = o.cartella` solo se `o.vivo`.
  - Se c'è `o.righe`, subito `vim.o.lines = o.righe`.
  - `F:input` fa `nvim_input` e poi un `nvim_get_mode`, così il figlio ha digerito i tasti.
  - `F:aspetta` usa `vim.wait(ms, …, 20)`.
  - `F:chiudi` fa `jobstop` e `jobwait({canale}, 3000)`.
- [ ] **Passo 5:** il comando delle prove con filtro `test_vivo_banco` → `OK 4 test`. Poi il cancello.
- [ ] **Passo 6: commit** `feat: banco delle prove di Rifallo tu, un Neovim figlio pilotato via RPC e la cartella finta`.

### Task 2: `dattilo vivo` apre la cartella sulla prima lezione, con la guida accesa

**Modello:** Sonnet. Firme, agganci e testi sono tutti fissati qui e nel progetto (5.9, 3.3). È il primo pezzo che si prova a mano.

**File:**
- Modifica:
  - `bin/dattilo:19-23`: il caso `vivo`, prima di `*)`, col blocco della 5.9 senza la riga `--prova`;
  - `lua/dattilo/cli.lua:176-186`: `vivo-dove`;
  - `lua/dattilo/init.lua:56`;
  - `lua/dattilo/home.lua:117`;
  - `lua/dattilo/lezione.lua`: riga 12 (`M.guida = nil`), 22 (`eco`), 105 (fine di `briefing`), 194-197 (`tip`), 316 (fine di `batti`);
  - `tests/vivo_figlio.lua`: aggiungi `F:riquadro()`.
- Crea: `lua/dattilo/guida.lua`, `lua/dattilo/guida_testi.lua`, `lua/dattilo/vivo.lua`, `tests/test_vivo_avvio.lua`.

**Interfacce:**
- Usa: `lezione.apri(pacchetto, n)`, `lezione.tip_batti(s, modo) → titolo, sezioni, tipo` (lezione.lua:156), `ui.tip(titolo, sezioni, tipo)`, `ui.altezza_tip(n)`, `pacchetti.dimentica()`, `pacchetti.carica('rifallo')`.
- Dà:
  - `guida.accendi(fornitore)`, `guida.spegni()`, `guida.attiva() → boolean`, `guida.tip(s)`, `guida.schermata(s)`, `guida.mostra(titolo: string, adesso: string, comandi: string, altre?: table)`, `guida.eco(chunks)`, `guida.ultimo() → { titolo: string, sezioni: { {etichetta: string, testo: string} }, tipo: string|nil }`;
  - `fornitore = { comandi = fun(schermata: 'batti'|'testo'|'modifica'|'fatto'|'elenco'|'attesa'): string, fine = fun(s): boolean, su_schermata = fun(s), destra = fun(): string }`;
  - `T = require('dattilo.guida_testi')`: ogni frase della 3.3 col suo nome (`T.batti_vuoto`, `T.comandi_batti`, …); `T.titoli.<briefing|batti|finito|ko|modifica|spiegazione|fatto|elenco|attesa>`; `T.posti.<visuale|cmd_vuota|cmd_noto|cmd_ignoto|ricerca|cmdwin|registra_n|registra_i|replace|operatore|ctrl_o|aiuto|divisa|divisa_principale|frecce|ex|sconosciuto> = { titolo, testo }` (le righe della 3.4); `T.spiega_comando = { w = 'salvi e node controlla il codice', q = 'lasci la lezione, che resta salvata', q_finestra = 'chiudi questa finestra e torni al codice', q_esci = 'chiudi dattilo; quello che hai scritto resta', salta = 'passi alla prossima lezione', ultima = "vai all'ultima modifica di Claude", elenco = 'vedi le lezioni di Rifallo tu', ['e!'] = 'ricominci da capo' }` (le spiegazioni della 3.4, riga 3); `T.f(nome, ...) → string`, cioè `string.format` sulla frase, dove `nome` è il nome di una frase o `titoli.<x>`; `T.posto(nome, ...) → titolo, testo`, cioè la riga `T.posti[nome]` con titolo e testo formattati con gli stessi valori; `T.neovim(tasto: string) → string`;
  - `vivo.attivo() → boolean`, `vivo.avvia(cartella)`, `vivo.ferma()` (per le prove: spegne timer, guida e comandi), `vivo.apri(id)`, `vivo.elenco()` (per ora l'elenco nudo: una riga per lezione, ‹Invio› apre);
  - `F:riquadro() → { titolo, sezioni = { [etichetta] = testo }, tipo }`.

- [ ] **Passo 1: la prova che fallisce**, `tests/test_vivo_avvio.lua`:
  - `'vivo --dove stampa vivo 1 e la radice'`: `vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--dove' }, { env = XDG finti }):wait()` → `code == 0`, e il JSON è `{ vivo = 1, radice = RADICE }`.
  - `'vivo senza cartella esce con 1 e dice come si usa'`: `code == 1`, e `stderr` contiene `uso: dattilo vivo <cartella> [opzioni di nvim]`.
  - `'senza vivo la guida resta spenta'` (con `nvim -l`): avvia l'app, `lezione.apri('corso-c-antirez', 1)` → `lezione.guida == nil`, `#vim.api.nvim_tabpage_list_wins(0) == 1`, `vim.fn.exists(':DattiloSalta') == 0`.
  - `'con vivo si parte dal briefing della prima lezione, col riquadro'`: `M.con({ cartella = c, vivo = true })` → `F:riquadro()` ha:
    - titolo `T.f('titoli.briefing', 'somma')`, cioè `COMINCIA · somma`;
    - `sezioni.Adesso == T.briefing`;
    - `sezioni.Comandi == T.comandi_testo`.
  - `'Invio porta a Batti con la guida'`: il titolo comincia con `SCRIVI · `, `Adesso == T.batti_vuoto`, `Comandi == T.comandi_batti`.
  - `'guida_testi: ogni fila di tasti è seguita dai due punti'` (G3, prova a): in ogni stringa di `T`, comprese le `testo` di `T.posti`, ogni sequenza `‹…›` (con spazi e altri `‹…›` dopo) è seguita da `:`.
- [ ] **Passo 2: lancia** con filtro `test_vivo_avvio` → `ERRORE caricando` (manca `dattilo.guida_testi`).
- [ ] **Passo 3: scrivi.**
  - `guida_testi.lua`: tutte le frasi della 3.3 e della 3.4 del progetto, copiate parola per parola.
  - Gli agganci di `lezione.lua` come nella tabella della 5.9.
  - `guida.tip`:
    - titolo: `'SCRIVI · ' ..` quello di `tip_batti`;
    - sezioni: «Adesso» (priorità 9; per ora `T.batti_vuoto` se il buffer è vuoto, altrimenti `T.batti_scrivi`: il compito 3 la sostituisce), quelle di `tip_batti` senza `avviso` e senza l'etichetta `Vim`, e «Comandi» (7) da `fornitore.comandi('batti')`;
    - `ui.altezza_tip(math.min(10, math.max(base, righe di Adesso + righe di Comandi + altre sezioni)))`, con `base` = 8 se `vim.o.lines >= 34`, altrimenti 6.
  - `guida.schermata(s)` per il briefing: `ui.tip(titolo, { Adesso = T.briefing, Comandi = comandi('testo') })`.
  - `guida.eco` per ora mette il testo dei chunks in «Controllo».
  - `vivo.avvia`:
    - `guida.accendi` con un fornitore le cui `comandi` danno `T.comandi_<schermata>`;
    - poi `vivo.apri` della prima lezione di `P.lezioni`; senza lezioni, `vivo.elenco()`.
  - `vivo.apri(id)`: `pacchetti.dimentica()`, cerca l'indice `n` con `L.id == id`, poi `lezione.apri('rifallo', n)`.
  - In `init.lua` e in `home.lua` le righe della 5.9.
- [ ] **Passo 4:** il comando delle prove con filtro `test_vivo_avvio` → `OK 6 test`. Poi il cancello.
- [ ] **Passo 5: prova a mano.**
  ```bash
  cp -r tests/fixture/rifallo /tmp/claude-1000/rifallo-mano && chmod 700 /tmp/claude-1000/rifallo-mano
  T=/tmp/claude-1000/rifallo-mano-xdg; XDG_CONFIG_HOME=$T/c XDG_STATE_HOME=$T/s XDG_CACHE_HOME=$T/k bin/dattilo vivo /tmp/claude-1000/rifallo-mano
  ```
  Lancialo in un terminale, o in `tmux new-session -d -x 100 -y 40` guardando con `capture-pane`. Si deve vedere il briefing col riquadro «COMINCIA · somma». Poi ‹Invio› → «SCRIVI»; ‹i› e qualche lettera; ‹Esc›, `:q` ‹Invio› → l'elenco nudo; `:q` ‹Invio› → esce. Scrivi nel resoconto del compito cosa si è visto.
- [ ] **Passo 6: commit** `feat: dattilo vivo apre una cartella sulla prima lezione con la guida accesa nel briefing e in Batti`.

### Task 3: La guida in Batti: «Adesso» punto per punto

**Modello:** Opus. I casi limite (‹A› dopo ‹Esc›, la riga spezzata col rientro di dattilo, il rosso, i digrammi) chiedono giudizio sul punto esatto in cui è la persona, e «il primo tasto è sempre quello giusto» va tenuto in tutti.

**File:**
- Modifica: `lua/dattilo/guida.lua`
- Crea: `tests/test_guida_batti.lua` (pura), `tests/test_guida_batti_figlio.lua`

**Interfacce:**
- Usa: `confronto.confronta(righe, bersaglio) → { errori = { {riga, da, a} }, finito }` (confronto.lua:5), `lezione.tip_batti`, `vim.fn.digraph_getlist(true)`.
- Dà:
  - `guida.adesso_batti(x: { codice: string[], righe: string[], r: integer, c: integer, modo: string, frecce?: boolean, cambiato?: boolean }) → string`. `c` è la colonna in byte, da 0, come `nvim_win_get_cursor`;
  - `guida.carattere(ch: string) → string|nil`;
  - `guida.cambio_voluto(buf: integer)`: salva le righe di adesso come quelle «giuste», dopo un cambio fatto da dattilo.

- [ ] **Passo 1: la prova pura che fallisce**, `tests/test_guida_batti.lua`.
  - Con `C` = il Batti di `001-somma.md`, ogni prova è `uguale(guida.adesso_batti(x), atteso)`:

    | # | righe | r, c, modo | atteso |
    |---|---|---|---|
    | 1 | `{''}` | 1, 0, `n` | `T.batti_vuoto` |
    | 2 | `{'func'}` | 1, 4, `i` | `T.batti_scrivi` |
    | 3 | `{'func'}` | 1, 3, `n` | `T.batti_riprendi` |
    | 4 | `{C[1]}` | 1, #C[1], `i` | `T.batti_fine_riga` |
    | 5 | `{'funx'}` | 1, 4, `i` | `T.batti_errore` |
    | 6 | `{'FUNC'}` | 1, 4, `i` | `T.batti_maiuscole` |
    | 7 | `{C[1], '    if (t', '    '}` | 3, 4, `i` | `T.f('batti_spezzata', 2, '2 volte', 2)` |
    | 8 | `{C[1], '    if (t', '    return a + b;'}` | 3, 17, `i` | `T.f('batti_indietro_i', 2, 2, 2)` |
    | 9 | come 8 | 3, 16, `n` | `T.f('batti_indietro_n', 2, 2, 2)` |
    | 10 | `C` | 4, 1, `i` / `n` | `T.batti_finito_i` / `T.batti_finito_n` |
    | 11 | `{C[1], '    if (typeof a !== "numbex'}` | 1, 0, `n` | `T.f('batti_rosso_n', 2, 2, 2)` |
    | 11b | come 11 | 2, 27, `n` | `T.batti_rosso_qui` |
    | 12 | `{'fun'}`, `cambiato = true` | 1, 2, `n` | `T.batti_cambiato` |
    | 13 | `{'fun'}`, `frecce = true` | 1, 3, `i` | `T.posti.frecce.testo` |
    | 14 | `{'functi'}` | 1, 2, `i` | `T.batti_cursore` |

  - Con `{'const a = 1;', '', 'const b = 2;'}` e righe `{'const a = 1;'}` in 1, 12, `i` → `T.batti_riga_vuota`.
  - Con `{'const s = "«ciao»";'}` e righe `{'const s = "'}` in 1, 11, `i` → `T.f('batti_carattere', '«', '‹Ctrl-k› ‹<› ‹<›')`.
  - `guida.carattere`:
    - `'«'` → `'‹Ctrl-k› ‹<› ‹<›'`, `'…'` → `'‹Ctrl-k› ‹,› ‹.›'`, `'→'` → `'‹Ctrl-k› ‹-› ‹>›'`, `'★'` → `'‹Ctrl-k› ‹*› ‹2›'`;
    - `'à'` → `nil`, `'a'` → `nil`;
    - `'🙂'` → `'‹Ctrl-v› ‹U› ‹0› ‹0› ‹0› ‹1› ‹F› ‹6› ‹4› ‹2›'`.
- [ ] **Passo 2: la prova nel figlio che fallisce**, `tests/test_guida_batti_figlio.lua`, con la cartella `rifallo` e `vivo = true`:
  - `'Esc in fondo e poi la frase: si riprende senza rosso'` (Review Focus 1): ‹CR› ‹i› `func` ‹Esc› → `Adesso == T.batti_riprendi`; poi `F:input(T.neovim('A'))` e `t` → `F:righe()[1] == 'funct'` e `batti.stato(buf).errori == 0`.
  - `'Invio presto: i Backspace contati riuniscono la riga'` (Review Focus 4): ‹CR› ‹i›, la riga 1, ‹CR›, `if (t`, ‹CR› → `Adesso == T.f('batti_spezzata', 2, '2 volte', 2)`; poi `<BS><BS>` → `#F:righe() == 2` e `F:righe()[2] == '    if (t'`; si finisce la riga → nessun rosso.
  - `'in NORMAL un movimento cambia Adesso'`: nello stato del caso 9 → `T.f('batti_indietro_n', 2, 2, 2)`; `F:input('2G')` → `Adesso == T.batti_riprendi`.
  - `'Esc dopo aver scritto non è un testo cambiato'`: `func` e ‹Esc› → «Adesso» non è `T.batti_cambiato`; `x` → lo è; `u` → torna `T.batti_riprendi`.
  - `'il digramma scrive il carattere'`: nella lezione 2 si batte fino a `return "`. «Adesso» contiene `‹Ctrl-k› ‹<› ‹<›`; `F:input('<C-k><lt><lt>')` → la riga 2 finisce con `"«` e non c'è rosso.
  - `'a 80×24 Adesso e Comandi stanno interi'` (G1), con `righe = 24` e poi `righe = 40`: in Batti, nessuna delle due sezioni finisce con `…`. Il testo si legge dalle righe del buffer del riquadro.
  - `'la decima lezione dice le stesse cose della prima'` (G3, prova b): `progressi.json` con 10 chiavi `rifallo/…` scritto prima dell'avvio → all'inizio di Batti `Adesso == T.batti_vuoto`.
- [ ] **Passo 3: lancia** con filtro `test_guida_batti`. Le prove della tabella falliscono, perché «Adesso» è ancora quella provvisoria del compito 2.
- [ ] **Passo 4: scrivi `guida.adesso_batti`.** I casi sono quelli della tabella della 3.3, in quell'ordine, e vale il primo che si applica.
  - `k` è la prima riga del buffer diversa dal grigio. Se le righe del buffer sono tutte uguali al grigio (ma meno), `k` è l'ultima riga del buffer: lì si continua.
  - «Rosso» vuol dire un errore di `confronta` sulla riga.
  - «Maiuscole» vuol dire che il primo carattere rosso è `upper` di quello grigio, ed è diverso da lui.
  - Le volte di `batti_spezzata` sono `math.ceil(#rientro / 4) + 1`, con `rientro = righe[r]`, che sono solo spazi, scritte `'una volta'` o `'<N> volte'`.
  - `guida.carattere`:
    - restituisce `nil` per ASCII e per `àèéìòùç°£§€`;
    - altrimenti cerca in `digraph_getlist(true)` la prima coppia di caratteri ASCII stampabili che dà `ch`;
    - senza una coppia: `‹Ctrl-v› ‹u›` e 4 cifre esadecimali maiuscole, oppure `‹Ctrl-v› ‹U›` e 8 sopra U+FFFF, un tasto per cifra.
  - In `guida.tip`, «Adesso» passa a `adesso_batti`:
    - `modo` è la prima lettera di `nvim_get_mode().mode`;
    - `frecce` viene da `s.frecce`;
    - `cambiato` è vero quando il modo è `n` e le righe del buffer sono diverse da quelle salvate all'ultimo `InsertLeave` o all'ultima `guida.cambio_voluto(buf)`. Non si contano gli eventi: dopo un `nvim_buf_set_lines` `TextChanged` scatta anche se il cambio è di dattilo (verificato).
    - Un autocomando `CursorMoved` sul buffer della lezione ridisegna il riquadro. lezione.lua:302-306 non lo ascolta, e dopo ‹4› ‹G› «Adesso» resterebbe vecchia.
  - Il titolo diventa `T.f('titoli.finito', #codice)` quando il testo è uguale al grigio.
- [ ] **Passo 5:** il comando delle prove con filtro `test_guida_batti` → tutte OK. Poi il cancello.
- [ ] **Passo 6: commit** `feat: la guida in Batti dice il prossimo tasto giusto in ogni punto, con la riga spezzata, il rosso e i digrammi`.

### Task 4: La guida nelle altre schermate della lezione, e l'esito di :w nel riquadro

**Modello:** Sonnet. Frasi e agganci sono già scritti nella 3.3 e nella 5.9.

**File:**
- Modifica: `lua/dattilo/lezione.lua:260-265` (`dopo_modifica`), `:363` (fine di `esegui`), `:454` (fine di `spiegazione`); `lua/dattilo/guida.lua` (`eco`, `schermata` per spiegazione ed esegui, `pcall`).
- Crea: `tests/test_guida_schermate.lua`, e la fixture `tests/fixture/rifallo-rotta/dati/dattilo/pacchetti/rifallo/` col manifesto e `lezioni/001-rotta.md`, il cui Batti è `function rotta( {` / `}`.

**Interfacce:**
- Usa: quello del compito 2, e `confronto.confronta`.
- Dà: `guida.eco(chunks)` nella forma definitiva. Non mostra i chunks: guarda lo stato e sceglie la frase.
  - Passo batti, testo non uguale e senza rosso: `controllo_mancano`, con `#table.concat(codice, '\n') - #table.concat(righe, '\n')`.
  - Con rosso: `controllo_rosso`.
  - Testo uguale ed esito con `Sintassi corretta.`: `controllo_ok`.
  - Altrimenti `controllo_ko` in «Adesso», con la prima riga che contiene `SyntaxError`, oppure `Error`, oppure la prima non vuota dopo `$ …`; titolo `T.titoli.ko` e bordo rosso.

- [ ] **Passo 1: la prova che fallisce**, `tests/test_guida_schermate.lua`, nel figlio con `vivo = true`:
  - `':w a metà: Controllo dice quanti caratteri mancano, e niente nei messaggi'` (Review Focus 2): ‹CR› ‹i› `func` ‹Esc› `:w<CR>` →
    - `sezioni.Controllo == T.f('controllo_mancano', N)`, con `N` calcolato come sopra;
    - `F:messaggi()` non contiene `Mancano`, `$ node` né `salvato`.
  - `':w col testo uguale: si va alla spiegazione senza il passo esegui'`: si batte tutto il codice, ‹Esc› `:w<CR>` →
    - `F:aspetta(passo == 'spiegazione')`;
    - una funzione appesa a `lezione.esegui` dalla prova non è mai chiamata;
    - il riquadro ha `T.f('titoli.spiegazione', 'somma')`, `Adesso == T.spiegazione`, `Controllo == T.controllo_ok`, `Comandi == T.comandi_testo`;
    - `F:messaggi()` non contiene `$ node`.
  - `':w con node che rifiuta: il riquadro dice che l errore non è tuo'` (cartella `rifallo-rotta`): si batte tutto, `:w` →
    - titolo `T.titoli.ko`, `tipo == 'rosso'`;
    - «Adesso» comincia con `Node non accetta il codice: ` e contiene `SyntaxError` e `‹:salta› ‹Invio›`;
    - `F:messaggi()` non contiene `$ node`.
  - `'un errore della guida va nel riquadro, non nei messaggi'`:
    - `F:lua` sostituisce `fornitore.comandi` con una funzione che fa `error('apposta')`, poi `F:input('i')`;
    - «Controllo» comincia con `Errore di dattilo:`;
    - `F:messaggi()` non contiene `apposta`.
- [ ] **Passo 2: lancia** con filtro `test_guida_schermate` → le quattro prove falliscono: oggi si passa da `esegui`, e gli esiti vanno nei messaggi.
- [ ] **Passo 3: scrivi.**
  - In `dopo_modifica`: `if M.guida and i == #L.modifiche and not L.rompi and vim.deep_equal(finale(L), L.batti.codice) then return M.spiegazione(s) end`, prima del ramo `esegui`.
  - `guida.schermata` per spiegazione ed esegui, con le frasi della 3.3.
  - Ogni funzione della guida chiamata da agganci e autocomandi gira in `pcall`. Un errore va in «Controllo» come `T.f('errore_dattilo', msg)`.
- [ ] **Passo 4:** il comando delle prove con filtro `test_guida_schermate` → OK. Poi il cancello: le prove di oggi su `esegui` (test_lezioni.lua:193-214) devono passare, perché lì la guida è spenta.
- [ ] **Passo 5: commit** `feat: con la guida gli esiti di :w vanno nel riquadro, la spiegazione arriva senza il secondo :w e ogni schermata ha Adesso e Comandi`.

### Task 5: I posti sbagliati

**Modello:** Opus. Per ognuno bisogna scegliere l'evento giusto, l'ordine dei controlli, il ritorno allo stato di prima e il ridisegno in modi dove Neovim aspetta un tasto. Le frasi sono nella 3.4.

**File:**
- Modifica: `lua/dattilo/guida.lua`: `posto()`; in `accendi`, gli autocomandi, `more = false` e la mappa ‹Ctrl-z›.
- Crea: `tests/test_guida_posti.lua`

**Interfacce:**
- Usa: `nvim_get_mode()`, `getcmdtype()`, `getcmdline()`, `getcmdwintype()`, `reg_recording()`, `v:operator`.
- Dà: `guida.posto(modo?: string) → nil | { titolo: string, testo: string }`. Il `modo` facoltativo serve alle prove della riga 16.

- [ ] **Passo 1: la prova che fallisce.** Nel figlio con `vivo = true`, da Batti con `func` già scritto e il modo indicato, una prova per riga della tabella:

  | Nome della prova | Si entra con | Titolo e frase (`T.posto`) | Si esce con | Dopo |
  |---|---|---|---|---|
  | `visuale` | `<Esc>v` | `visuale` | `<Esc>` | `n` |
  | `riga dei comandi vuota` | `<Esc>:` | `cmd_vuota` | `<Esc>` | `n` |
  | `riga dei comandi con w` | `<Esc>:w` | titolo di `cmd_vuota`, frase `T.cmd_w` | `<CR>` | `n`, Controllo `controllo_mancano` |
  | `comando noto` | `<Esc>:q` | `cmd_noto`, con `'q', T.spiega_comando.q` | `<Esc>` | `n` |
  | `comando ignoto` | `<Esc>:ls` | `cmd_ignoto`, con `'ls'` | `<Esc>` | `n` |
  | `ricerca` | `<Esc>/` | `ricerca` | `<Esc>` | `n` |
  | `finestra dei comandi` | `<Esc>q:` | `cmdwin` | `<C-c>` poi `<Esc>` | `n`, una finestra di codice |
  | `registrazione` | `<Esc>qa` | `registra_n`, con `'a'` | `q` | `reg_recording() == ''` |
  | `registrazione scrivendo` | `<Esc>qai` | `registra_i`, con `'a'` | `<Esc>` poi `q` | `reg_recording() == ''` |
  | `replace` | `<Esc>R` | `replace` | `<Insert>` | `i` |
  | `Ins scrivendo` | `<Insert>` | `replace` | `<Insert>` | `i` |
  | `operatore` | `<Esc>d` | `operatore`, con `'d'` | `<Esc>` | `n` |
  | `Ctrl-o` | `<C-o>` | `ctrl_o` | `<Esc>` | `i` |
  | `frecce` | `<Up>` | `frecce` | `<Esc>k` | `n`, cursore alla riga 1 |
  | `Ex` | `<Esc>gQ` | `ex` | `visual<CR>` | `n` |
  | `Ctrl-z` | `<C-z>` | Controllo `T.ctrl_z`, il titolo non cambia | — | il figlio risponde, modo `i` |
  | `testo cambiato in NORMAL` | `<Esc>x` | Adesso `T.batti_cambiato` | `u` | righe come prima |

  - Per ogni riga: il titolo e la frase («Adesso») sono quelli attesi, e `tipo == 'rosso'`. Fanno eccezione Ctrl-z e il testo cambiato, che non cambiano il bordo.
  - Dopo i tasti d'uscita: il modo è quello atteso, `F:righe()` è uguale a prima, e `tipo ~= 'rosso'`.
  - In più, `guida.posto('t')` dà `T.posto('sconosciuto', 't')`.
- [ ] **Passo 2: lancia** con filtro `test_guida_posti` → tutte FALLITO.
- [ ] **Passo 3: scrivi.**
  - L'ordine dei controlli in `posto()`: finestra dei comandi, riga dei comandi (per `getcmdtype`), Ex, registrazione, `lezione.s.frecce` (riga 13), poi il modo. I modi: `v V ^V s S ^S`, `R…`, `no…`, `niI niR`; ogni altro modo che non sia `n`, `i` o `c` dà `sconosciuto`. Le finestre in più arrivano nel compito 6.
  - In `cmd_noto` la spiegazione di `q` dipende da dove si è: `q_finestra` in una finestra in più (compito 6), `q_esci` nell'elenco e nell'attesa, `q` nella lezione.
  - Gli autocomandi, in un gruppo `dattilo_guida`: `ModeChanged`, `RecordingEnter`, `RecordingLeave` (`reg_recording()` vale ancora la lettera durante `RecordingLeave`: si usa `vim.schedule`), `CmdlineEnter`, `CmdlineChanged`, `CmdlineLeave`, `CmdwinEnter`, `CmdwinLeave`, `TextChanged`.
  - Ognuno ricalcola con `vim.schedule` e poi `vim.cmd.redraw()`.
  - ‹Ctrl-z› si mappa in `n`, `i` e `v` con `vim.keymap.set`, verso una funzione che mette `T.ctrl_z` in «Controllo». Dentro `M.spegni` la mappa si toglie.
- [ ] **Passo 4:** il comando delle prove con filtro `test_guida_posti` → OK. Poi il cancello.
- [ ] **Passo 5: commit** `feat: la guida riconosce i posti sbagliati di Vim e dice la frase che riporta indietro`.

### Task 6: `:q` e le finestre in più

**Modello:** Opus. Tocca la logica delle finestre di dattilo (schermo.lua, ui.lua:228-236) e il significato di `:q` in tre posti diversi.

**File:**
- Modifica:
  - `lua/dattilo/init.lua:12-14` (`DattiloEsci`), in testa: `local g = package.loaded['dattilo.guida'] if g and g.attiva() and g.esci_da_finestra_in_piu() then return end`;
  - `lua/dattilo/schermo.lua:15-31`, prima di `require('dattilo.home').apri()`: `local g = package.loaded['dattilo.guida'] if g and g.attiva() and g.riprendi(cur, a.buf) then vim.o.cmdheight = 1 return end`;
  - `lua/dattilo/guida.lua`.
- Crea: `tests/test_guida_finestre.lua`

**Interfacce:**
- Usa: `schermo.principale`, `schermo.mostra(buf, tipo)`, `ui.dimentica_tip(win)`, `ui.finestra_tip()`.
- Dà:
  - `guida.riprendi(win: integer, buf: integer) → boolean`: vero se c'è una lezione aperta. In quel caso rimette `buf` in `win` con `schermo.mostra` (`'editor'` in batti, modifica ed esegui, `'testo'` altrimenti), ridisegna il riquadro e, se c'è `lezione.s.e`, riapre l'OBIETTIVO (compito 15);
  - `guida.esci_da_finestra_in_piu() → boolean`: vero se la finestra corrente non è la principale, il riquadro né l'OBIETTIVO. In quel caso la chiude;
  - le righe 12 e 12b in `posto()`.

- [ ] **Passo 1: la prova che fallisce**, nel figlio con `vivo = true`, in Batti con `func` scritto:
  - `'F1 e poi :q: si torna in Batti col testo'` (Review Focus 3):
    - `<Esc><F1>` → `T.posti.aiuto`;
    - `:q<CR>` → `lezione.s.passo == 'batti'`, `F:righe()[1] == 'func'`, e ci sono 2 finestre (codice e riquadro).
  - `':q scritto nell aiuto dice che chiude la finestra'`: `<Esc><F1>:q` → `T.posto('cmd_noto', 'q', T.spiega_comando.q_finestra)`; nell'elenco, `:q` → `T.spiega_comando.q_esci`.
  - `'Ctrl-w s: la frase della finestra in più, e :q la chiude'`: `<Esc><C-w>s` → `T.posti.divisa`; `:q<CR>` → 2 finestre, Batti, testo intatto.
  - `'dalla finestra della lezione: Ctrl-w o'`: `<Esc><C-w>s<C-w>p` → `T.posti.divisa_principale`; `<C-w>o` → `F:aspetta` 2 finestre (il riquadro torna) e Batti.
  - `'Ctrl-w c sulla lezione con una divisione aperta: la lezione resta'`: `<Esc><C-w>s<C-w>p<C-w>c` → Batti, testo intatto, `schermo.principale` valida.
  - `':q nella lezione va all elenco; :q nell elenco esce'`:
    - `<Esc>:q<CR>` → `lezione.s == nil` e `stato.schermo == 'home'`;
    - `:q<CR>` → `vim.fn.jobwait({ F.canale }, 3000)[1] == 0`.
  - La prova di oggi «chiudere la finestra principale riporta alla home…» (test_lezioni.lua:63-74) resta verde: lì la guida è spenta.
- [ ] **Passo 2: lancia** con filtro `test_guida_finestre` → FALLITO: oggi `:q` dall'aiuto esce dalla lezione.
- [ ] **Passo 3: scrivi.**
  - La finestra «in più» è ogni finestra non galleggiante che non è `schermo.principale`, il riquadro (`ui.finestra_tip()`) né `lezione.s.e.fin`.
  - Si ricalcola su `WinNew`, `WinEnter` e `WinClosed`, con `vim.schedule`.
- [ ] **Passo 4:** il comando delle prove con filtro `test_guida_finestre` → OK. Poi il cancello.
- [ ] **Passo 5: commit** `feat: con la guida :q chiude la finestra in più e una lezione rimasta senza finestra si rimette nella finestra che resta`.

### Task 7: Il canale: `vuoi.json`, `stato.json` e la coda ogni 500 ms

**Modello:** Sonnet. Il contratto è scritto per intero sopra, coi casi; qui si traduce in codice e prove.

**File:**
- Modifica: `lua/dattilo/vivo.lua`
- Crea: `tests/test_vivo_canale.lua`. Gira con `nvim -l`, tranne l'ultima prova, che usa il figlio. Ogni prova finisce con `vivo.ferma()`.

**Interfacce:**
- Usa: `pacchetti.carica_cartella(dir)`, `progressi.carica()`, `vim.uv.fs_lstat`, `fs_realpath`, `fs_open(…, 'w', 384)`, `fs_rename`.
- Dà: `vivo.controlla()`, `vivo.coda(P, corrente: string|nil, fatte: table<string,true>, saltate: table<string,true>) → { nuove: integer, prossima: string|nil, ultima: string|nil }`, `vivo.scrivi_stato()`, `vivo.destra() → string`.

- [ ] **Passo 1: la prova che fallisce**, `tests/test_vivo_canale.lua`:
  - `'coda: nuove dopo la corrente, senza fatte e saltate'`:
    - lezioni `001`…`005`, corrente `003`, fatte `{001}`, saltate `{004}` → `{ nuove = 1, prossima = '005-…', ultima = '005-…' }`;
    - senza corrente → `{ nuove = 3, prossima = '002-…', ultima = '005-…' }`.
  - `'vuoi apri: si esegue una volta sola'`:
    - con `t = 100`, `apri 002-saluto` → `lezione.s.L.id == '002-saluto'`;
    - lo stesso file, `controlla()` → non si riapre (si conta con una spia su `lezione.apri`);
    - `t = 50` → niente.
  - `'vuoi a metà, poi intero'`:
    - `{"v":1,"t":` → niente e nessun errore;
    - un altro `controlla()` senza toccare il file lo rilegge (una spia sulla lettura conta 2 letture);
    - poi il file intero → al giro dopo si esegue.
  - `'id fuori modello e link: si ignorano'`:
    - `lezione: '../x'` → niente;
    - `vuoi.json` link a un file valido → niente;
    - `bozze` link → `bozza_salva` non scrive.
  - `'lezione nuova durante Batti: nuove sale, la corrente non si tocca'`: in Batti si scrive `func`, si copia `003-x.md`, `controlla()` → `stato.json` ha `nuove == 2`, `lezione == '001-somma'`, e il buffer ha ancora `func`.
  - `'lezione rotta in mezzo: non conta e non sposta gli id'`: `002-rotta.md` senza Batti, e `vuoi apri 003-x` → si apre `003-x`; `nuove` non la conta.
  - `'stato.json: 0600, atomico, riscritto solo se cambia'`:
    - modo `% 512 == 384`;
    - due `controlla()` senza novità → la data di modifica non cambia;
    - nella cartella non resta nessun `stato.json.*`.
  - `'dati fuori dalla cartella: attesa con l avviso'`: `dati` link a un'altra cartella → nessuna lezione aperta, e «Controllo» contiene `la cartella dei dati non è dentro quella di Rifallo tu`.
  - `'dalvivo finita: la barra lo dice'`: `stato.destra` finisce con `sessione finita: niente lezioni nuove`.
  - `'aperte e saltate sopravvivono alla chiusura'`: `ferma()`, poi `avvia()` → `stato.json` ha le stesse liste.
  - `'il timer vede una lezione nuova entro un secondo'` (figlio): si scrive `003-x.md` nella cartella; entro 1500 ms `stato.json` dice `nuove == 2`.
- [ ] **Passo 2: lancia** con filtro `test_vivo_canale` → FALLITO (le funzioni non ci sono).
- [ ] **Passo 3: scrivi**, seguendo «Come dattilo si accorge delle novità», «File a metà, rotti o spariti» e «Id e link» del contratto.
  - Il timer: `vim.uv.new_timer()`, `start(500, 500, vim.schedule_wrap(controlla))`.
  - `stato.destra` = la base di `lezione.barre` più `vivo.destra()`, ridisegnata con `redrawtabline`.
- [ ] **Passo 4:** il comando delle prove con filtro `test_vivo_canale` → OK. Poi il cancello.
- [ ] **Passo 5: commit** `feat: il canale di Rifallo tu, con vuoi.json e stato.json, la coda e il controllo della cartella ogni 500 ms`.

### Task 8: Le schermate di «Rifallo tu»: riepilogo, elenco, attesa e i comandi

**Modello:** Sonnet. Schermate e testi sono fissati nella 3.3 e nella 5.11, i comandi in G6.

**File:**
- Modifica: `lua/dattilo/lezione.lua:458` (in testa a `M.fine`: `if M.guida and M.guida.fine(s) then return end`), `lua/dattilo/guida.lua` (`fine`), `lua/dattilo/vivo.lua`
- Crea: `tests/test_vivo_schermate.lua` (figlio)

**Interfacce:**
- Usa: `progressi.registra(id, r)` (progressi.lua:46), `schermo.buffer`, `schermo.scrivi`, `schermo.mostra`, `guida.mostra`.
- Dà:
  - `vivo.fatto(s) → true`, `vivo.prossima()`, `vivo.salta()`, `vivo.ultima()`, `vivo.rifai()`, `vivo.elenco()` nella forma definitiva, `vivo.attesa()`;
  - `guida.fine(s) → boolean`;
  - i comandi `:DattiloSalta`, `:DattiloUltima` e `:DattiloElenco`, con le abbreviazioni `salta`, `ultima` ed `elenco` fatte come init.lua:4-9.

- [ ] **Passo 1: la prova che fallisce:**
  - `'riepilogo con la coda'`, alla fine della lezione 1 con la 2 in coda:
    - titolo `FATTO · somma`;
    - `Adesso == T.f('fatto_coda', 'Il saluto', ' (1 nuova)')`, `Comandi == T.comandi_fatto`;
    - `progressi.json` ha `rifallo/001-somma`;
    - il testo non contiene `Ripasso`.
  - `'Invio nel riepilogo apre la prossima'` → il briefing di `002-saluto`.
  - `'riepilogo senza coda e attesa'`:
    - finite le due lezioni, `Adesso == T.fatto_vuota`;
    - ‹CR› → titolo `ASPETTO CLAUDE`, `Adesso == T.attesa`, `Comandi == T.comandi_attesa`;
    - si scrive `003-x.md` → entro 1500 ms si apre il suo briefing da solo.
  - `':salta e :ultima'`:
    - in Batti della 1, `:salta<CR>` → `stato.json.saltate == {'001-somma'}` e si apre la 2;
    - `:ultima<CR>` apre la più recente non fatta.
  - `'elenco: segni e comandi'`:
    - `:elenco<CR>` → le righe hanno `✓` per le fatte, `▸` per le altre, e `saltata` o `nuova` a destra;
    - `Adesso == T.elenco`, `Comandi == T.comandi_elenco`;
    - `j` e `<CR>` aprono la seconda.
  - `'ogni comando scritto fa quello che dice'` (G6): per ogni schermata si esegue ogni voce del suo `comandi_*`, e si controlla lo schermo o la lezione d'arrivo.
  - `'senza vivo i comandi non ci sono'` (`nvim -l`): `vim.fn.exists(':DattiloSalta') == 0`.
- [ ] **Passo 2: lancia** con filtro `test_vivo_schermate` → FALLITO.
- [ ] **Passo 3: scrivi.**
  - `vivo.fatto`:
    - registra `rifallo/<id>` con `{ wpm, precisione, tempo_ms }` di `s.risultato`;
    - toglie la bozza;
    - disegna le righe della 5.11 nel buffer `schermo.buffer('rifallo-fatto')`;
    - mappa `<CR>`/`l` → `prossima`, `r` → `rifai`, `q` → `elenco`;
    - mostra il riquadro.
  - `elenco` e `attesa` mettono `stato.schermo = 'home'`, così `:q` chiude come dalla home (init.lua:13).
  - Nell'elenco, `j`, `k`, `<Down>`, `<Up>` e `<CR>` sono mappati come in home.lua:136-138.
- [ ] **Passo 4:** il comando delle prove con filtro `test_vivo_schermate` → OK. Poi il cancello.
- [ ] **Passo 5: commit** `feat: riepilogo, elenco e attesa di Rifallo tu, con :salta, :ultima ed :elenco`.

### Task 9: La bozza: niente testo perso

**Modello:** Sonnet. La regola (G8) e il formato del file sono fissati; i segnali sono già verificati.

**File:**
- Modifica: `lua/dattilo/vivo.lua`: `bozza_*`, `su_schermata`, autocomandi `InsertLeave` e `VimLeavePre`, il salvataggio ogni 2 s dentro `controlla`.
- Crea: `tests/test_vivo_bozza.lua` (figlio)

**Interfacce:**
- Dà: `vivo.bozza_salva(id)`, `vivo.bozza_leggi(id) → { passo: string, righe: string[] } | nil`, `vivo.bozza_togli(id)`, `vivo.su_schermata(s)`.

- [ ] **Passo 1: la prova che fallisce:**
  - `'la bozza si scrive mentre si scrive'`: due righe battute; entro 2500 ms `bozze/001-somma.json` le contiene. Il file è a 0600 (`% 512 == 384`) e `bozze/` a 0700.
  - `'chiuso di colpo a metà: riaprendo il testo c è'` (Review Focus 5):
    - righe battute, poi `F:chiudi()` subito, che fa `jobstop` e quindi `VimLeavePre`;
    - un figlio nuovo sulla stessa cartella → passo `batti` subito, senza briefing;
    - le stesse righe, il cursore in fondo all'ultima riga scritta;
    - `Controllo == T.ripreso`, `Adesso == T.batti_riprendi`.
  - `':ultima e ritorno: il testo resta'`.
  - `'lezione fatta: la bozza sparisce'`.
  - `'bozza col file link: non si legge e non si scrive'`.
- [ ] **Passo 2: lancia** con filtro `test_vivo_bozza` → FALLITO.
- [ ] **Passo 3: scrivi.**
  - Una bozza si salva solo se le righe sono cambiate.
  - Il salvataggio è atomico come `stato.json`.
  - `vivo.apri(id)` con una bozza `batti` chiama `lezione.batti(lezione.s)` subito dopo `lezione.apri`. `su_schermata` rimette le righe solo se il buffer è vuoto, poi chiama `batti.aggiorna(buf)` e `guida.cambio_voluto(buf)`, così la guida non lo prende per un testo cambiato in NORMAL.
- [ ] **Passo 4:** il comando delle prove con filtro `test_vivo_bozza` → OK. Poi il cancello.
- [ ] **Passo 5: commit** `feat: la bozza di Rifallo tu salva il testo ogni 2 secondi e alla chiusura, e lo rimette alla riapertura`.

### Task 10: Il giro «da chi non sa niente»

**Modello:** Opus. È la prova che regge G2. Il robot deve fare gli errori di chi non sa, e la prova deve accorgersi dei giri a vuoto.

**File:**
- Crea: `tests/test_vivo_giro.lua` (figlio)

**Interfacce:**
- Usa: `F:riquadro()`, `T.neovim(tasto)`, `lezione.s.L.batti.codice` (con `F:lua`).
- Dà: niente di nuovo. È una prova su quello che c'è; per questo non parte da una prova che fallisce.

- [ ] **Passo 1: scrivi il robot e la prova.** Il robot fa al massimo 400 passi. A ogni passo:
  1. legge `F:riquadro()`. Se non c'è, o non ha «Adesso», la prova fallisce (G1);
  2. se «Adesso» comincia con `Scrivi il testo grigio`, batte la prossima lettera del grigio: quella dopo il testo della riga del cursore;
  3. altrimenti prende la **prima** fila di `‹…›` di «Adesso», la traduce con `T.neovim` e la preme. Se la frase dice `premilo N volte` la preme N volte, se dice `premilo una volta` una volta;
  4. si ferma quando il titolo è `FATTO · saluta`.

  Lungo la strada il robot fa gli errori di chi non sa. Ognuno al primo passo, da quello indicato in poi, in cui è in Batti, in INSERT e in nessun posto sbagliato:
  - `x` al posto della lettera giusta, dal passo 10;
  - `<CR>` a metà riga, dal 25;
  - `<Esc>`, dal 40;
  - `<Esc>v`, dal 55;
  - `<Esc>qa`, dal 70;
  - `<Esc><F1>`, dall'85;
  - `<Up>`, dal 100.
  - `'chi fa solo quello che dice la guida arriva in fondo a due lezioni'`:
    - si arriva a `FATTO · saluta` in meno di 400 passi;
    - mai più di 3 passi di fila con lo stesso riquadro e le stesse righe;
    - `progressi.json` ha le due lezioni;
    - `F:messaggi()` non ha righe di dattilo.
- [ ] **Passo 2: lancia** con filtro `test_vivo_giro`. Deve passare con il codice dei compiti 2-9. Se fallisce, il guasto sta in una frase o nella scelta di «Adesso»: si corregge lì, nel compito che possiede quel codice, e non nel robot.
- [ ] **Passo 3:** il cancello.
- [ ] **Passo 4: commit** `feat: prova del giro da chi non sa niente, che segue solo la guida e sbaglia apposta`.

### Task 11: Il collaudo in tmux

**Modello:** Opus. È il collaudo a vista: bisogna giudicare uno schermo vero e scrivere cosa non si è potuto verificare.

**File:**
- Crea: `tests/vivo_collaudo.sh`, sullo stampo di `tests/e2e.sh`. Usa una cartella copiata da `tests/fixture/rifallo` e `XDG_*` temporanei, e la sessione `tmux new-session -d -x 100 -y 40 "<radice>/bin/dattilo vivo $C"`.

**Interfacce:**
- Usa: `bin/dattilo vivo` (compito 2), le funzioni `cap`, `aspetta`, `tasto` e `scrivi` di `tests/e2e.sh:9-16`, copiate.
- Dà: `bash tests/vivo_collaudo.sh`, che esce con 0 e stampa `COLLAUDO OK`, oppure esce con 1 e stampa lo schermo.

- [ ] **Passo 1: scrivi lo script.** Ogni controllo è `aspetta '<testo>'` su `capture-pane`, come in `tests/e2e.sh`. Dopo ogni tasto c'è anche un controllo che lo schermo non contenga `INVIO` (G5). I controlli:
  1. `COMINCIA` → ‹Enter› → `SCRIVI` → `i`, la lezione 1 battuta con un ‹Enter› a metà riga e i ‹BSpace› contati → `FINITO` → ‹Escape› `:w` ‹Enter› → `CAPISCI`.
  2. Riga dei comandi: in Batti, ‹Escape› `:` → `RIGA DEI COMANDI` mentre il cursore è ancora sulla riga dei comandi. È il ridisegno che il figlio non sa provare.
  3. Operatore: `d` → `NEOVIM ASPETTA`.
  4. Ctrl-z: `tmux send-keys C-z`; poi `ps -o stat= -p <pid di nvim>` non comincia con `T`, e `Ctrl-z in Neovim mette in pausa` è sullo schermo.
  5. Il pannello chiuso di colpo: in Batti, a metà riga, `tmux kill-session`. Poi la bozza c'è, e una sessione nuova sulla stessa cartella mostra `Ripreso`.
  6. `:q` ‹Enter› due volte → la sessione tmux finisce.

  In fondo lo script stampa `COLLAUDO OK`, oppure le righe `NON VERIFICATO: <cosa> (<perché>)` che restano.
- [ ] **Passo 2: lancia** `bash tests/vivo_collaudo.sh`. Deve stampare `COLLAUDO OK`. Se il punto 2 o il 3 fallisce perché il riquadro non si ridisegna in quei modi:
  - lo si scrive come «non verificato» col motivo;
  - si aggiunge una riga al rischio 10 del progetto: la persona vede la riga di Neovim, in italiano.
- [ ] **Passo 3: scrivi nel resoconto** cosa resta non verificato senza Herdr:
  - il segnale con cui Herdr chiude il pannello;
  - Ctrl-z dentro Herdr;
  - il clic del mouse dentro il pannello;
  - l'incolla di Herdr.
- [ ] **Passo 4: commit** `feat: collaudo di Rifallo tu in tmux, con il ridisegno nei modi in attesa, Ctrl-z e la chiusura di colpo`.

### Task 12: README: la sezione «Rifallo tu»

**Modello:** Sonnet. È documentazione da una sezione del progetto.

**File:**
- Modifica: `README.md`. Una sezione nuova «Rifallo tu (`dattilo vivo`)» dopo «Pacchetti», e una riga in «Prove».

**Interfacce:**
- Usa: il contratto (albero e riga di comando) e la 3.1 del progetto.

- [ ] **Passo 1: scrivi la sezione**, in poche righe:
  - cos'è;
  - `dattilo vivo <cartella>` e `dattilo vivo --dove`;
  - la guida sempre accesa;
  - i comandi `:salta`, `:ultima` ed `:elenco`;
  - dove stanno i file (l'albero del contratto);
  - `bash tests/vivo_collaudo.sh` nella sezione «Prove».
- [ ] **Passo 2:** `grep -c 'dattilo vivo' README.md` dà almeno 3. Poi il cancello.
- [ ] **Passo 3: commit** `docs: README con Rifallo tu, dattilo vivo e il suo collaudo`.

---

## Tempo B

**Tempo B: si costruisce dopo che il tempo A è provato a mano.**

### Task 13: Formato: la Modifica che parte dal codice di prima, e i suoi tasti

**Modello:** Sonnet. Le regole sono nella 5.5 e nella 5.9 del progetto, gli errori sono già scritti, e le lezioni di oggi devono leggersi identiche.

**File:**
- Modifica: `lua/dattilo/formato.lua:291-312` (`## Modifica`) e `:344-353` (catena delle partenze)
- Crea: `tests/test_formato_partenza.lua`, e la fixture `tests/fixture/rifallo-b/dati/dattilo/pacchetti/rifallo/` col manifesto e `lezioni/001-sosia.md`, cioè l'esempio completo della 5.5 del progetto.

**Interfacce:**
- Dà: `m.partenza_propria: string[]|nil`, `m.partenza` (la propria se c'è), `m.tasti: { {tasti: string, cosa: string} }|nil`, `m.mostra` (con `### Tasti` sono i `tasti`).

- [ ] **Passo 1: la prova che fallisce:**
  - `'Modifica col blocco partenza e i Tasti'`: `formato.lezione` della fixture →
    - `m.partenza[2]` è la riga senza il secondo `.replace`;
    - `m.obiettivo[2]` è quella con;
    - `#m.tasti == 5` e `m.tasti[1] == { tasti = '2G', cosa = 'va alla riga 2' }`;
    - `m.mostra == { '2G', '$', 'i', '.replace(/[O0U]/g, (x) => SIMILI[x])', '<Esc>' }`.
  - Gli errori (`formato.lezione` restituisce `nil` col messaggio):
    - due blocchi `partenza` → `la Modifica ha due blocchi partenza`;
    - una riga `- 2G va alla riga 2`, senza ` | `, → `riga non valida nei Tasti: scrivi - tasti | cosa fanno`;
    - i Tasti che non fanno la soluzione → `i Tasti messi in fila non sono la soluzione`.
  - `'le lezioni di oggi si leggono come prima'`. Su ogni `.md` di `pacchetti/` e di `tests/fixture/`:
    - `m.partenza_propria == nil` e `m.tasti == nil`;
    - la partenza di ogni Modifica è l'obiettivo della precedente, o il Batti per la prima.
  - `'controlla e riempi funzionano con la partenza'`:
    - `controlla.pacchetto(fixture)` non ha righe `errore` di soluzione;
    - `controlla.riempi` riscrive l'obiettivo dalla partenza.
- [ ] **Passo 2: lancia** con filtro `test_formato_partenza` → FALLITO.
- [ ] **Passo 3: scrivi.**
  - Il blocco partenza è quello con `info` che corrisponde a `%f[%w]partenza$`; l'obiettivo è il primo blocco senza `partenza`.
  - `m.blocco`, che usa `riempi`, punta all'obiettivo.
  - Le righe `- <tasti> | <cosa>` si dividono al primo ` | `.
  - Nel ciclo di formato.lua:346-353: `m.partenza = m.partenza_propria or partenza`. Il controllo di `pos` alla riga 348 deve leggere `m.partenza`, non la `partenza` della catena, altrimenti controlla la posizione sul testo sbagliato.
- [ ] **Passo 4:** il comando delle prove con filtro `test_formato_partenza` → OK. Poi il cancello, con le prove di oggi su `formato`, `riempi` e `controlla` verdi senza ritocchi.
- [ ] **Passo 5: commit** `feat: una Modifica può partire da un codice suo e avere i Tasti spiegati uno per uno`.

### Task 14: `dattilo vivo --prova`: i tasti proposti arrivano all'obiettivo?

**Modello:** Sonnet. Si riusa la strada della sandbox di `controlla` (cli.lua:146-154), con le uscite fissate nel contratto.

**File:**
- Modifica:
  - `lua/dattilo/controlla.lua:27-40`: `prova_soluzione` diventa `M.prova_soluzione`, e le chiamate interne seguono;
  - `lua/dattilo/cli.lua`: `vivo-prova`; `vivo-dove` → `vivo = 2`; (25/11: resta `vivo = 1` finché non c'è il compito 15)
  - `bin/dattilo`: la riga `--prova` del blocco della 5.9.
- Crea: `tests/test_vivo_prova.lua`

**Interfacce:**
- Usa: `formato.lezione`, `esercizio.conta_tasti(seq)` (esercizio.lua:15), `compila.sandbox()`, `compila.argomenti_sandbox(rw, ro, eseguibili)`.
- Dà: `controlla.prova_soluzione(m) → string[]|nil, errore`; la riga di comando del contratto, con uscite 0, 1 e 2.

- [ ] **Passo 1: la prova che fallisce**, con `vim.system({ RADICE .. '/bin/dattilo', 'vivo', '--prova', f })` e gli `XDG_*` finti. `f` è una copia di `001-sosia.md` con `par: 0`:
  - `'tasti giusti: 0, il JSON e il par riscritto'`:
    - `code == 0`;
    - JSON `{ ok = true, modifiche = { { tasti = 41 } } }`;
    - nel file c'è `par: 41`;
    - il modo del file è quello di prima.
  - `'tasti sbagliati: 1 e il motivo'`: con `soluzione` e `### Tasti` cambiati in `3G…` →
    - `code == 1`;
    - `motivo` contiene `non arrivano all'obiettivo`;
    - il file è uguale a prima.
  - `'tasti non ammessi: 1'`: `soluzione: :!ls<CR>` → `code == 1`, e `motivo` contiene `!`.
  - `'formato rotto: 1'` e `'file che non c è o nessun argomento: 2'`.
  - `'senza bwrap va lo stesso'`: con `DATTILO_SANDBOX=0` → `code == 0`.
  - `'vivo --dove ora dice 2'`.
- [ ] **Passo 2: lancia** con filtro `test_vivo_prova` → FALLITO.
- [ ] **Passo 3: scrivi `vivo-prova`.**
  - Se `compila.sandbox()` è vero e non si è già dentro: si rilancia dentro `bwrap` con `argomenti_sandbox({ cartella del file }, { radice }, { 'nvim' })`, come cli.lua:146-154.
  - Dentro: per ogni Modifica, `prova_soluzione` e `vim.deep_equal(righe, m.obiettivo)`.
  - Il `motivo` è `modifica <i>: i tasti non arrivano all'obiettivo (riga <n> diversa)`.
  - Se tutto va: righe `par:` = `conta_tasti(m.soluzione)`, file temporaneo nella stessa cartella con il modo di prima, poi `fs_rename`.
  - Il JSON va su stdout, con `vim.json.encode`, su una riga.
- [ ] **Passo 4:** il comando delle prove con filtro `test_vivo_prova` → OK. Poi il cancello.
- [ ] **Passo 5: commit** `feat: dattilo vivo --prova controlla che i tasti di una Modifica arrivino all'obiettivo e ne scrive il par`.

### Task 15: La Modifica guidata

**Modello:** Opus. Servono giudizio sulle frasi, sul conto dei tasti senza voto, sul momento in cui mostrare i tasti e sull'avanzamento «uno alla volta» quando la persona devia.

**File:**
- Modifica:
  - `lua/dattilo/lezione.lua:337-338`: con la guida, `M.guida.modifica_fatta(s, tasti)` al posto dell'`eco`;
  - `lua/dattilo/lezione.lua:347`: `M.guida.schermata(s)`;
  - `lua/dattilo/esercizio.lua:126-136`: `M.finestra_obiettivo(e)`, solo codice spostato;
  - `lua/dattilo/guida.lua`: `tip` e `schermata` per il passo `modifica`; `riprendi` riapre l'OBIETTIVO;
  - `lua/dattilo/vivo.lua`: la bozza `passo = "modifica"`, e la riga `Modifica  T tasti` nel riepilogo.
- Crea: `tests/test_guida_modifica.lua` (figlio, cartella `rifallo-b`)

**Interfacce:**
- Usa: `m.tasti`, `m.aiuto`, `m.consegna`, `e.tasti` (esercizio.lua:124), `esercizio.conta_tasti`.
- Dà: `guida.modifica_fatta(s, tasti: integer)`; `guida.ora: fun(): integer`, che vale `vim.uv.now` e si cambia nelle prove; `esercizio.finestra_obiettivo(e) → integer`.

- [ ] **Passo 1: la prova che fallisce:**
  - `'si arriva alla Modifica e si vede a parole'`:
    - Batti fatto e `:w` → passo `modifica`;
    - titolo `T.titoli.modifica`;
    - `Consegna == m.consegna`;
    - `Adesso == T.f('mod_parole', m.aiuto)`;
    - `Comandi == T.comandi_modifica`.
  - `'dopo 15 secondi fermi, i tasti uno alla volta'`:
    - `guida.ora` avanti di 16000 → `Adesso == T.f('mod_tasto', '‹2G›', 'va alla riga 2')`;
    - `2G` → `Adesso == T.f('mod_tasto', '‹$›', 'va in fondo alla riga, sul punto e virgola')`, e «Tasti» comincia con `✓ ‹2G›`;
    - poi `$`, `i`, il testo, ‹Esc› → `Controllo == T.f('mod_fatta', 41, 41)` → spiegazione.
  - `'oltre il doppio dei tasti, i tasti compaiono anche senza aspettare'`: 83 tasti di movimento.
  - `'tasti diversi: la frase lo dice, e :e! riparte'` → `T.mod_altri`; `:e!<CR>` → partenza e primo tasto di nuovo.
  - `'niente par né stelle'`: in nessun riquadro, nella riga di stato (`stato.metriche()`) né nel riepilogo compaiono `par` o `★`. Il riepilogo ha `Modifica  41 tasti`.
  - `'Ctrl-w o nella Modifica: l OBIETTIVO torna'`.
  - `'chiuso di colpo nella Modifica: si riapre alla Modifica'`.
- [ ] **Passo 2: lancia** con filtro `test_guida_modifica` → FALLITO.
- [ ] **Passo 3: scrivi.**
  - I tasti premuti li osserva un `vim.on_key(fn, ns)` che **restituisce sempre `nil`**. Accumula `keytrans(battuto)` da quando la Modifica parte o da `:e!`.
  - Il prossimo pezzo è il primo `k` per cui la somma dei pezzi `1..k` non è un prefisso di quello che si è premuto. Se quello che si è premuto non è un prefisso della soluzione, la frase è `mod_altri`.
  - I tasti si mostrano quando `guida.ora() - ultimo_tasto >= 15000` oppure quando `e.tasti > 2 * par`.
  - In INSERT, col testo uguale all'obiettivo, la frase è `mod_uguale`.
- [ ] **Passo 4:** il comando delle prove con filtro `test_guida_modifica` → OK. Poi il cancello.
- [ ] **Passo 5: commit** `feat: la Modifica di Rifallo tu guidata, prima a parole e poi coi tasti uno alla volta, senza par`.

### Task 16: Collaudo del tempo B e README

**Modello:** Opus. È il collaudo a vista.

**File:**
- Modifica: `tests/vivo_collaudo.sh` (una parte B con la cartella `rifallo-b`), `README.md` (due righe nella sezione «Rifallo tu»).

**Interfacce:**
- Usa: `tests/vivo_collaudo.sh` (compito 11), `dattilo vivo --prova` (compito 14), la fixture `rifallo-b` (compito 13).

- [ ] **Passo 1: aggiungi la parte B allo script:**
  - Batti e `:w` → `RIFAI LA MODIFICA DI CLAUDE` con la finestra `OBIETTIVO`;
  - `sleep 16` → sullo schermo `‹2G›`, cioè ` 2G ` evidenziato;
  - i tasti come dice la guida → `CAPISCI`;
  - `par` non compare mai;
  - `bin/dattilo vivo --prova` sulla fixture esce con 0.
- [ ] **Passo 2:** `bash tests/vivo_collaudo.sh` → `COLLAUDO OK`, con la parte B.
- [ ] **Passo 3: README:** la Modifica nel tempo B e `dattilo vivo --prova`.
- [ ] **Passo 4: commit** `feat: collaudo del tempo B di Rifallo tu e README con la Modifica`.

---

## Copertura

| Regola o punto del progetto | Compito | Prova |
|---|---|---|
| G1 la guida c'è sempre | 2, 3, 4, 8, 10 | `con vivo si parte dal briefing…`, `a 80×24 Adesso e Comandi stanno interi`, `:w col testo uguale…`, `riepilogo con la coda`, il giro (riquadro a ogni passo) |
| G2 il tasto giusto | 3, 10 | la tabella di `test_guida_batti`, `chi fa solo quello che dice la guida arriva in fondo…` |
| G3 ogni tasto spiegato, ogni volta | 2, 3 | `guida_testi: ogni fila di tasti è seguita dai due punti`, `la decima lezione dice le stesse cose…` |
| G4 i posti sbagliati | 5, 6 | `test_guida_posti` (una prova per riga), `test_guida_finestre` |
| G5 niente «Premi INVIO» | 4, 10, 11 | `:w a metà…`, `node che rifiuta…`, `un errore della guida…`, il giro (`:messages`), il collaudo (`INVIO` mai sullo schermo) |
| G6 comandi veri, sempre scritti | 8 | `ogni comando scritto fa quello che dice`, `senza vivo i comandi non ci sono` |
| G7 `:q` chiude il posto dove sei | 6 | `F1 e poi :q…`, `Ctrl-w s…`, `Ctrl-w o`, `Ctrl-w c…`, `:q nella lezione…` |
| G8 niente testo perso | 9, 11 | `chiuso di colpo a metà…`, `:ultima e ritorno…`, il collaudo (punto 5) |
| G9 Ctrl-z | 5, 11 | riga `Ctrl-z` di `test_guida_posti`, il collaudo (punto 4) |
| G10 le frecce | 5 | riga `frecce` di `test_guida_posti` |
| G11 i caratteri | 3 | `guida.carattere`, `il digramma scrive il carattere` |
| G12 la Modifica senza fretta | 15 | `test_guida_modifica` |
| 3.2 n. 1 briefing | 2 | `con vivo si parte dal briefing…` |
| 3.2 n. 2 Batti prima di scrivere | 2, 3 | `Invio porta a Batti…`, caso 1 |
| 3.2 n. 3 frecce | 5 | riga `frecce` |
| 3.2 n. 4 riga non finita | 3 | casi 7, 8, 9; `Invio presto…` |
| 3.2 n. 5 NORMAL e ‹i› | 3 | caso 3; `Esc in fondo e poi la frase…` |
| 3.2 n. 6 finire | 3, 5 | caso 10; riga `riga dei comandi con w` |
| 3.2 n. 7 esito su più righe | 4 | `:w a metà…`, `node che rifiuta…` |
| 3.2 n. 8 secondo :w | 4 | `:w col testo uguale: … senza il passo esegui` |
| 3.2 n. 9 spiegazione e riepilogo | 4, 8 | `:w col testo uguale…`, `riepilogo con la coda` |
| 3.2 n. 10 uscita | 6, 8 | `:q nella lezione…`, `ogni comando scritto…` |
| 3.2 n. 11 elenco | 8 | `elenco: segni e comandi` |
| 3.2 n. 12 mouse | 5, 11 | riga `visuale` (stesso evento del trascinamento); il clic vero in Herdr resta non verificato |
| 3.2 n. 13 caratteri | 3 | caso del digramma, `guida.carattere` |
| 3.2 n. 14 Ctrl-C | 3, 10 | caso 3 (dopo l'uscita dalla scrittura), il giro (‹Esc› a metà) |
| Contratto: CLI | 2, 14 | `vivo --dove…`, `vivo senza cartella…`, `test_vivo_prova` |
| Contratto: file, novità, file rotti, id e link | 7, 9 | `test_vivo_canale`, `test_vivo_bozza` |

**Nomi e firme, controllati da un compito all'altro:**
- `guida.adesso_batti(x)` (3) è la stessa che usa `guida.tip` (2 → 3).
- `guida.posto(modo?)` (5) è estesa, non cambiata, nel 6.
- `guida.fine(s) → boolean` (8) è quella chiamata da `lezione.lua:458`.
- `guida.riprendi(win, buf)` (6) riapre l'OBIETTIVO con `esercizio.finestra_obiettivo(e)` (15).
- Il `fornitore` ha le stesse quattro chiavi nel 2 (definite), nell'8 (`fine`) e nel 9 (`su_schermata`).
- `vivo.ferma()` (2) chiude ogni prova del 7.
- I nomi di `T` (2) sono quelli usati nelle prove dei compiti 3-15, e coincidono con i nomi della 3.3 del progetto. Le righe della 3.4 sono in `T.posti`, coi nomi del compito 2.
- `F:riquadro()` nasce nel 2 ed è usato dal 3 in poi.
- `guida.cambio_voluto(buf)` nasce nel 3 ed è chiamata dalla bozza nel 9.
- `controlla.prova_soluzione(m)` (14) è la funzione che il 13 usa già per nome interno, dentro `controlla.lua`.
