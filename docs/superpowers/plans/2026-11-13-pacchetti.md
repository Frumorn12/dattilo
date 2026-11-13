# Pacchetti di lezioni: piano di implementazione

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** dattilo carica pacchetti di lezioni in Markdown, li esporta e importa come file `.dattilo`, e arriva con quattro pacchetti nuovi (javascript, threejs, aton, smartexploration) oltre al corso C convertito.

**Architecture:** un parser trasforma `pacchetto.json` e le lezioni `.md` nella stessa tabella lezione che `lezione.lua` usa oggi; l'esecuzione diventa generica (`compila` / `comando` / `controllo`); un verificatore (`controlla`) prova ogni pacchetto come fanno oggi i test del corso C. Lo scambio è un formato di testo con validazione prima di scrivere.

**Tech Stack:** Neovim 0.12 Lua, `vim.json`, `vim.system`, `cc`, `node` 26, tmux per l'e2e.

**Spec:** `docs/superpowers/specs/2026-11-13-pacchetti-design.md`

## Global Constraints

- I pacchetti sono solo dati: nessun file Lua viene letto da un pacchetto.
- Pacchetti installati in `${XDG_DATA_HOME:-~/.local/share}/dattilo/pacchetti/<id>/`; il corso C sta in `<repo>/pacchetti/corso-c-antirez/`.
- `.dattilo`: prima riga `dattilo-pacchetto 1`; file introdotti da `--- file: <percorso>`; estensioni ammesse `.json .md .html .js .css .txt .c`; massimo 5 MB; niente `..` né `/` iniziale; escape `^\\*--- file:` con un `\` in più.
- Cartella di lavoro: `${XDG_DATA_HOME}/dattilo/lavoro/<pacchetto>/<lezione>/`; `file/` del pacchetto copiata lì prima di eseguire.
- Progressi: chiave `<pacchetto>/<lezione>`; migrazione una tantum di `01-hello`, `02-sum`.
- Tetti di esecuzione invariati: 10 s compilazione/controllo, 5 s esecuzione, 64 KB di uscita.
- Testi in italiano, tasti come `‹k›`.
- Il codice di SmartExploration lo legge solo Claude; il repo dei pacchetti `Frumorn12/dattilo-pacchetti` è privato.

## Review Focus

- Lezione malformata in un pacchetto installato: l'app non va in errore, il pacchetto mostra il problema (file e riga) e le altre lezioni restano usabili (test in Task 3).
- `.dattilo` con percorso `../`, estensione vietata o oltre 5 MB: rifiutato, niente scritto su disco (test in Task 5).
- Import di un pacchetto già installato rifiutato alla conferma: il vecchio resta intatto (test in Task 5).
- Lezione senza `Rompi`, senza video o senza `Uscita`: briefing, passi e spiegazione si disegnano senza righe vuote o errori (test in Task 4).
- `node` assente: messaggio chiaro come per `cc` (test in Task 2).

---

### Task 1: Formato delle lezioni e del manifesto

**Files:** Create `lua/dattilo/formato.lua`, `tests/test_formato.lua`

**Interfaces:**
- Produces: `formato.manifesto(testo: string, nome: string) -> m|nil, errori` con `m = { id, titolo, versione, autore, descrizione, linguaggio, richiede = {}, esecuzione = {tipo, compila?, esegui?, comando?}, in_arrivo = {} }`; obbligatori `id` (solo `[a-z0-9-]`), `titolo`, `versione`, `esecuzione.tipo` ∈ `compila|comando|controllo`.
- Produces: `formato.lezione(testo: string, nome_file: string, indice: int) -> L|nil, errori` dove `errori = { {file, riga, msg} }` e `L` ha i campi di oggi: `id` (nome file senza `.md`), `numero`, `etichetta` (default `string.format('%02d', indice)`), `titolo`, `breve` (default titolo), `video` (`{id, durata, da}` o nil), `fonte`, `briefing`, `passi` (default generati: Batti, una voce per Modifica, Rompi se c'è, Capisci), `mosse`, `concetti`, `tempo`, `file`, `batti = {codice, suggerimenti}`, `esegui = {atteso}` (contenuto di `Uscita` + `\n`, o nil), `modifiche = { {titolo, consegna, aiuto, pos = {r0,c0}, partenza, obiettivo, par, soluzione, mostra} }`, `rompi = {titolo, consegna, attesa, cerca, dopo, ripara, esempio}` o nil, `spiegazione = {note, momenti, trappola, prova}`, `esecuzione` (override o nil).
- Produces: `formato.front_matter(testo) -> tabella, corpo, riga_inizio_corpo` (sottoinsieme YAML: `chiave: valore`, liste `[a, "b c"]`).

- [ ] **Step 1: test** con una lezione d'esempio completa in stringa (front matter con lista e stringa quotata; `## Briefing`; `## Batti` con blocco e `### Suggerimenti` `4: testo`; `## Uscita`; due `## Modifica: …` con `aiuto`, `par`, `soluzione`, `mostra: a · b`, `pos: 3:5`; `## Rompi` con `consegna`, `attesa`, `cerca`, `dopo` e blocco esempio; `## Spiegazione` con `1: a | b`, `### Momenti` `- 05:26 testo`, `### Trappola`, `### Prova`). Asserzioni: `L.batti.codice` righe esatte; `L.esegui.atteso == 'Hello World\n'`; seconda modifica `partenza` = obiettivo della prima; `pos == {2,4}`; `mostra == {'a','b'}`; `rompi.ripara` = obiettivo dell'ultima modifica; `spiegazione.note[1] == {'a','b'}`; `momenti[1] == {'05:26','testo'}`.
  Altri casi: lezione senza `Batti` → `nil` ed errore con `riga`; `par: dieci` → errore con riga; blocco ``` dentro un blocco ```` resta testo; manifesto senza `id` → errore; `id` con maiuscole → errore; lezione senza Rompi né video → `rompi == nil`, `video == nil`, `passi` default senza voce Rompi.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: formato Markdown delle lezioni e manifesto dei pacchetti`.

### Task 2: Esecuzione generica

**Files:** Modify `lua/dattilo/compila.lua`, `tests/test_compila.lua`

**Interfaces:**
- Produces: `compila.lancia(dir, file, esecuzione, o?) -> r` con i campi di oggi più `tipo`; `{file}` e `{nome}` sostituiti negli array. Semantica: `compila` → come oggi; `comando` → un solo comando, `compilato=true`, `ok = codice==0 and not scaduto and not troncato`, `diagnostica` = stderr; `controllo` → `compilato = ok = codice==0`, `uscita=''`, `diagnostica` = stderr..stdout. Eseguibile mancante (primo elemento) → `ok=false`, `diagnostica` che lo nomina.
- Produces: `compila.esegui(dir, file, o?)` resta = `lancia` con l'esecuzione C (`cc -Wall -Wextra -O2 -fdiagnostics-color=never -o {nome} {file}` poi `./{nome}`).
- Produces: `compila.messaggio(r)`: per `comando` e `controllo` la prima riga è `$ <comando>`; esiti: `controllo` ok → "Sintassi corretta."; errore → "Errore: leggi qui sopra."; il resto come oggi.
- Produces: `compila.fallito(r, attesa, cerca) -> bool` (regola 1 dello spec).

- [ ] **Step 1: test**: `lancia` con `{tipo='comando', comando={'node','{file}'}}` su `console.log("ciao")` → `ok`, `uscita=='ciao\n'`; `throw new Error("x")` → `ok=false`, `diagnostica` contiene `Error: x`; `{tipo='controllo', comando={'node','--check','{file}'}}` su `class A {` → `ok=false`, diagnostica contiene `SyntaxError`; su codice valido → `ok`, messaggio contiene "Sintassi corretta."; `PATH` senza node → `ok=false` e diagnostica nomina `node`; `fallito(r,'errore','SyntaxError')` vero sul caso rotto e falso con `cerca='ReferenceError'`; `fallito` con `attesa='warning'` su C con due `%d` vero. I test esistenti di `esegui` restano verdi.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: esecuzione generica (compila, comando, controllo)`.

### Task 3: Pacchetti, verificatore e corso C convertito

**Files:** Create `lua/dattilo/pacchetti.lua`, `lua/dattilo/controlla.lua`, `pacchetti/corso-c-antirez/pacchetto.json`, `pacchetti/corso-c-antirez/lezioni/01-hello.md`, `pacchetti/corso-c-antirez/lezioni/02-sum.md`, `tests/test_pacchetti.lua`. Delete `lua/dattilo/lezioni/01.lua`, `02.lua`, `indice.lua` (il contenuto passa nel pacchetto, l'elenco delle 38 in `in_arrivo`). Modify `lua/dattilo/progressi.lua`, `tests/test_lezioni.lua`.

**Interfaces:**
- Produces: `pacchetti.cartella_utente() -> string`; `pacchetti.elenco() -> { {id, titolo, versione, autore, descrizione, cartella, lezioni=int, errori={...}} }` (corso C prima, poi gli altri per titolo); `pacchetti.carica(id) -> P|nil, err` con `P = { m = manifesto, cartella, lezioni = {L...}, in_arrivo, errori }` (lezioni malformate saltate e messe in `errori`); `pacchetti.lezione(id, n) -> L`; `pacchetti.dimentica()` svuota la cache.
- Produces: `controlla.pacchetto(cartella) -> { ok = bool, righe = { {stato='ok'|'errore', testo} } }`: valida manifesto e lezioni; per ogni lezione: codice di Batti eseguito con l'esecuzione del pacchetto (uscita uguale ad `Uscita` se c'è); ogni modifica raggiunta con `soluzione` in un buffer (feedkeys) e `conta_tasti(soluzione) == par`; `ripara` eseguito pulito; `esempio` di Rompi (se c'è) `fallito(...)` vero. Esegue nella cartella temporanea con `file/` copiata.
- Produces: `progressi.carica()` migra `01-hello`→`corso-c-antirez/01-hello` e `02-sum`→`corso-c-antirez/02-sum`.

- [ ] **Step 1: test**: `controlla.pacchetto(RADICE..'/pacchetti/corso-c-antirez').ok == true` (sostituisce i test per-lezione di `test_lezioni.lua`, che vengono tolti); `pacchetti.carica('corso-c-antirez')` ha 2 lezioni, 36 `in_arrivo`, `lezioni[1].video.id == 'HjXBXBgfKyk'`, `lezioni[1].batti.suggerimenti[4]` presente; pacchetto utente in `XDG_DATA_HOME` temporaneo con una lezione buona e una senza Batti → `carica` ha 1 lezione e 1 errore con file e riga, `elenco()` lo mostra; migrazione: `progressi.json` con chiave `01-hello` → dopo `carica()` c'è `corso-c-antirez/01-hello` e il file è riscritto.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: pacchetti, verificatore e corso C in Markdown`.

### Task 4: Lezioni dai pacchetti nell'app

**Files:** Modify `lua/dattilo/lezione.lua`, `lua/dattilo/home.lua`, `lua/dattilo/init.lua`, `tests/test_lezioni.lua`, `tests/e2e.sh`

**Interfaces:**
- Consumes: `pacchetti.*`, `compila.lancia/fallito`, `formato` L.
- Produces: `lezione.apri(pacchetto_id: string, n: int)`; Rompi dichiarativo (regola 1); passo Rompi assente → passo "esegui" (`‹:w›` esegue, pulito → spiegazione); evidenziazione con `vim.treesitter.start(buf, linguaggio)` dove `linguaggio` = `c` o `javascript` (parser JS da `~/.local/share/nvim/site` se esiste, aggiunto al `runtimepath` in `avvia`); copia di `file/` nella cartella di lavoro; briefing e spiegazione senza righe del video quando `video == nil` (mostrano `fonte` se c'è); `Rompi` del riepilogo dice "un errore vero di gcc|node".
- Produces: `home.pacchetti()` (elenco con titolo, versione, numero di lezioni, avviso dipendenze mancanti; `Invio` apre `home.lezioni(id)`), `home.lezioni(id)` (elenco delle lezioni del pacchetto + `in_arrivo` in grigio, come l'elenco del corso di oggi); voce home "Corso C" = `home.lezioni('corso-c-antirez')`, nuova voce "Pacchetti" (`p`).
- Produces: comando `:Lezione <pacchetto> <n>`.

- [ ] **Step 1: test**: aprire `corso-c-antirez` 1 e passare a Batti come oggi; pacchetto di prova JS (fixture in `tests/fixture/js-prova/` con una lezione senza Rompi, senza video, con `Uscita`) → `lezione.apri('js-prova', 1)` disegna il briefing senza la riga del video; Batti apre `main.js` con `filetype=javascript`; dopo aver scritto il codice e `:w` (con `vim.cmd('write')`) si passa a Modifica; dopo la modifica si arriva al passo esegui; `:w` → Spiegazione. `home.lezioni('corso-c-antirez')` elenca 38 righe. `tests/e2e.sh` resta verde (con "Corso C" che apre il pacchetto) e aggiunge la lezione JS di prova.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: lezioni dai pacchetti, schermata Pacchetti`.

### Task 5: Scambio: esporta, importa, riga di comando

**Files:** Create `lua/dattilo/scambio.lua`, `lua/dattilo/cli.lua`, `tests/test_scambio.lua`; Modify `bin/dattilo`, `lua/dattilo/home.lua`, `README.md`

**Interfaces:**
- Produces: `scambio.esporta(cartella) -> testo, nome_file` (`<id>-<versione>.dattilo`, file in ordine alfabetico, solo estensioni ammesse); `scambio.leggi(testo) -> { manifesto, file = { [percorso] = contenuto } } | nil, errori`; `scambio.anteprima(dati) -> righe di riepilogo` (titolo, versione, autore, lezioni, dipendenze mancanti); `scambio.installa(dati, { sostituisci = bool }) -> ok, msg` (valida tutte le lezioni con `formato` prima di scrivere; scrive in una cartella temporanea e la rinomina).
- Produces: `cli.main(args)` per `importa <file> [--si]`, `esporta <id> [file]`, `pacchetti`, `nuovo <id>`, `controlla <cartella>`; codice d'uscita 0/1. `bin/dattilo <sottocomando>` esegue `nvim --clean --headless -l lua/dattilo/cli.lua …`; per `importa` senza `--si` mostra l'anteprima e chiede `[s/N]` in bash.
- Produces: nella schermata Pacchetti `i` (chiede il percorso con `vim.ui.input`, anteprima, `vim.fn.confirm`) ed `e` (esporta in `~/<id>-<versione>.dattilo`).

- [ ] **Step 1: test**: andata e ritorno: `leggi(esporta(corso C))` ricostruisce gli stessi file; una riga di contenuto `--- file: x` e una `\--- file: y` tornano identiche; rifiutati con errore e senza scrivere: percorso `../x.md`, `/etc/x.md`, estensione `.lua`, testo oltre 5 MB, prima riga diversa, lezione malformata; `installa` su id esistente senza `sostituisci` → `ok=false`, cartella vecchia intatta; con `sostituisci` → nuova versione; `cli.main({'nuovo','prova'})` in una cartella temporanea crea uno scheletro che `controlla` passa.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: esporta e importa pacchetti come file .dattilo`.

### Task 6: Pacchetto `javascript`

**Files:** Create in `~/code/dattilo-pacchetti/javascript/` (`pacchetto.json`, `lezioni/01…10.md`); repo `~/code/dattilo-pacchetti` con `README.md` e `esporta.sh` (esporta ogni pacchetto in `dist/`).

- Esecuzione `comando` `node {file}`, file `main.js`. Dieci lezioni come da spec, ognuna con Uscita, 1–2 Modifica (mosse Vim che crescono), Rompi con `cerca` (`SyntaxError`, `ReferenceError`, `TypeError`), Spiegazione.
- [ ] **Step 1:** `dattilo controlla ~/code/dattilo-pacchetti/javascript` → tutte le righe `ok`.
- [ ] **Step 2:** repo privato `Frumorn12/dattilo-pacchetti`, commit `feat: pacchetto javascript`.

### Task 7: Pacchetto `threejs`

- Esecuzione `comando` `node {file}` per le lezioni di matematica e grafo della scena; `controllo` (override per lezione) per quelle grafiche. `file/three.module.js` e `file/three.core.js` dalla build MIT già presente in `~/aton/wapps/smartexploration-at/src/vendor/three/` con la licenza in `file/LICENSE-three.txt`. Otto lezioni come da spec.
- [ ] **Step 1:** `dattilo controlla …/threejs` tutto `ok`. **Step 2:** commit.

### Task 8: Pacchetto `aton`

- Esecuzione `controllo`. Nove lezioni come da spec, brani da `~/aton/public/src` e `~/aton/wapps/app_template`, `fonte` sempre indicata.
- [ ] **Step 1:** `dattilo controlla …/aton` tutto `ok`. **Step 2:** commit.

### Task 9: Pacchetto `smartexploration`

- Esecuzione `controllo`, `richiede: ["aton"]`. Dieci lezioni come da spec, brani da `~/aton/wapps/smartexploration-at` letti solo da Claude, `fonte` sempre indicata.
- [ ] **Step 1:** `dattilo controlla …/smartexploration` tutto `ok`. **Step 2:** commit.

### Task 10: Installazione e consegna

- [ ] **Step 1:** `esporta.sh` produce i quattro `.dattilo` in `dist/`; `dattilo importa dist/<x>.dattilo --si` per ciascuno; `dattilo pacchetti` li elenca con il numero di lezioni.
- [ ] **Step 2:** tmux: dalla home `p`, apri `smartexploration`, prima lezione fino a Batti; cattura schermo senza errori.
- [ ] **Step 3:** suite completa ed e2e verdi; push di entrambi i repo.
