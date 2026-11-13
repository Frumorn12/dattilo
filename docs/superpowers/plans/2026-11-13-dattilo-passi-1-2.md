# dattilo, passi 1 e 2: piano di implementazione

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** il comando `dattilo` apre Neovim pulito con home, lezioni 1 e 2 del corso di antirez nei sei passi (briefing, batti, modifica, rompi/compila, spiegazione, riepilogo) e il Dojo Vim con 7 esercizi.

**Architecture:** app in Lua caricata da `nvim --clean -u init.lua`. Logica pura (confronto testo/bersaglio, metriche, impaginazione del riquadro, schermate come segmenti colorati) separata dal cablaggio con Neovim (extmark, autocmd, finestre). Le lezioni sono tabelle Lua.

**Tech Stack:** Neovim 0.12 (Lua, extmark, treesitter C incluso), `cc` di sistema (GCC 16), tmux per le prove end-to-end.

**Spec:** `docs/superpowers/specs/2026-11-13-dattilo-design.md`

## Global Constraints

- Avvio: `nvim --clean -u <repo>/init.lua`; nessun plugin dell'utente, tokyonight solo se esiste `~/.local/share/nvim/lazy/tokyonight.nvim`.
- Dati in `${XDG_DATA_HOME:-~/.local/share}/dattilo` (`progressi.json`, `lavoro/<id lezione>/`).
- Compilazione: `cc -Wall -Wextra -O2 -fdiagnostics-color=never -o <nome> <file.c>`, timeout 10 s; esecuzione con timeout 5 s.
- Buffer di battitura: `expandtab`, `tabstop=4`, `shiftwidth=4`, `softtabstop=4`, `noautoindent`, `nosmartindent`, `nocindent`, `indentexpr=`, `formatoptions=`, `textwidth=0`.
- Stelle: tre se tasti ≤ par, due se ≤ ceil(1,5 × par), una altrimenti; soluzione mostrata dopo 2 × par tasti.
- Testi dell'interfaccia in italiano, brevi, tasti scritti come `‹k›` e resi evidenziati.
- Licenza MIT, autore "Andrea Brescia".
- Test unitari: `nvim --clean --headless -l tests/run.lua` stampa `OK n test` ed esce 0.

## Review Focus

- Terminale più stretto di 84 colonne o ridimensionato: il riquadro del suggerimento va a capo sulla larghezza reale e si ridisegna su `VimResized` (test in Task 3).
- Testo oltre il bersaglio (righe in più, righe cancellate in normale, caratteri dopo la fine): niente errori Lua, errori evidenziati, fantasma coerente (test in Task 1 e 4).
- `:q`, `:wq`, `:x` dentro una lezione o il Dojo tornano alla home; dalla home chiudono l'app senza chiedere di salvare (test in Task 7).
- Programma che non termina o `cc` assente: messaggio chiaro entro i timeout, nessun blocco (test in Task 5).
- `<Tab>` e spazi a inizio riga: il rientro del bersaglio arriva da `<CR>`, un `<Tab>` battuto mette 4 spazi e se sono di troppo diventano errore (test in Task 4).

---

### Task 1: Scheletro, test runner, confronto

**Files:**
- Create: `bin/dattilo`, `init.lua`, `lua/dattilo/init.lua`, `lua/dattilo/confronto.lua`, `tests/run.lua`, `tests/test_confronto.lua`, `LICENSE`, `.gitignore`

**Interfaces:**
- Produces: `confronto.confronta(righe: string[], bersaglio: string[]) -> { errori = { {riga=int0, da=int0, a=int0} }, finito = bool }` (colonne in byte, fine esclusa).
- Produces: `confronto.fantasma(righe, bersaglio) -> { coda = { {riga=int0, col=int0, testo=string} }, sotto = string[] }` (`coda`: parte mancante delle righe esistenti; `sotto`: righe del bersaglio oltre l'ultima del buffer).
- Produces: `confronto.diff_riga(a: string, b: string) -> p: int, sa: int, sb: int` (lunghezza del prefisso comune e fine esclusiva della parte diversa in a e in b, con suffisso comune).
- Produces: `confronto.inseriti(prima: string, dopo: string) -> da: int0|nil, testo: string|nil` (testo inserito in un punto solo, nil se non è un inserimento puro).
- Produces: test runner: ogni `tests/test_*.lua` ritorna una tabella `{ ["nome"] = function() ... end }`; helper globale `uguale(a, b, msg)` con confronto profondo.

- [ ] **Step 1: test runner e test del confronto**

`tests/test_confronto.lua`, casi con valori esatti:
  - `confronta({"int"}, {"int x;"})` → nessun errore, `finito=false`.
  - `confronta({"imt"}, {"int"})` → `errori = {{riga=0,da=1,a=2}}`.
  - `confronta({"int x;", "extra"}, {"int x;"})` → errore `{riga=1,da=0,a=5}`, `finito=false`.
  - `confronta({"int x;  "}, {"int x;"})` → errore `{riga=0,da=6,a=8}`.
  - `confronta(b, b)` con `b = {"#include <stdio.h>", "", "}"}` → `finito=true`.
  - `fantasma({"int m"}, {"int main", "}"})` → `coda={{riga=0,col=5,testo="ain"}}`, `sotto={"}"}`.
  - `fantasma({""}, {"a","b"})` → `coda={{riga=0,col=0,testo="a"}}`, `sotto={"b"}`.
  - `inseriti("prntf", "printf")` → `2, "i"`; `inseriti("ab", "a")` → `nil`.
  - `diff_riga("Hello World", "Ciao mondo")` → `0, 11, 10`.

- [ ] **Step 2:** `nvim --clean --headless -l tests/run.lua` → FAIL (modulo mancante).
- [ ] **Step 3:** implementa `confronto.lua`; `bin/dattilo` (bash: `DIR=$(dirname "$(readlink -f "$0")")/..; exec nvim --clean -u "$DIR/init.lua" "$@"`); `init.lua` aggiunge il repo a `runtimepath` e chiama `require('dattilo').avvia()`; `lua/dattilo/init.lua` con `avvia()` vuoto per ora.
- [ ] **Step 4:** test → `OK`.
- [ ] **Step 5:** commit `feat: scheletro, test runner e confronto con il bersaglio`.

### Task 2: Metriche di battitura

**Files:** Create `lua/dattilo/metriche.lua`, `tests/test_metriche.lua`

**Interfaces:**
- Produces: `metriche.nuova() -> m` con `m:inserito(testo: string, atteso: string, ora_ms: number)` (conta per carattere giusti/sbagliati, fa partire il tempo al primo), `m:a_capo(giusto: bool, ora_ms)`, `m:pausa(ora_ms)`, `m:riprendi(ora_ms)`, `m:fine(ora_ms)`, `m:wpm(ora_ms) -> int`, `m:precisione() -> number` (0–100, una cifra decimale), `m:tempo(ora_ms) -> ms`, campi `giusti`, `sbagliati`, `inizio`, `finito`.

- [ ] **Step 1: test**: dopo `inserito("int", "int", 0)` e `inserito("x", "y", 0)` → `giusti=3`, `sbagliati=1`, `precisione()=75`; con `inizio=0` e 60 000 ms trascorsi e 250 giusti → `wpm(60000)=50`; `wpm` è 0 sotto 1 s; pausa da 10 000 a 20 000 esclude 10 s dal tempo; dopo `fine(t)` il tempo non cresce.
- [ ] **Step 2:** test → FAIL. **Step 3:** implementa. **Step 4:** test → OK. **Step 5:** commit `feat: metriche di battitura`.

### Task 3: Interfaccia: colori, riquadro, barre

**Files:** Create `lua/dattilo/ui.lua`, `tests/test_ui.lua`

**Interfaces:**
- Produces: `ui.colori()` definisce i gruppi `DattiloGhost`, `DattiloErrore`, `DattiloGiusto`, `DattiloTasto`, `DattiloBordo`, `DattiloBordoRosso`, `DattiloBordoVerde`, `DattiloApp`, `DattiloModoNormal|Insert|Visual|Command`, `DattiloBarra`, `DattiloBarra2`, `DattiloMuto`, `DattiloAccento`, `DattiloObiettivo`, `DattiloAggiunto`, `DattiloStella` (colori tokyonight-night; `default=true` non serve).
- Produces: `ui.segmenti(testo: string, hl_base: string) -> { {testo, hl} }` (`‹k›` → `" k "` in `DattiloTasto`).
- Produces: `ui.a_capo(testo: string, larghezza: int) -> string[]` (parole intere, `‹…›` indivisibili, `\n` forza l'a capo).
- Produces: `ui.riquadro(titolo, testo, larghezza, righe_interne, tipo) -> righe: string[], segni: { {riga, da, a, hl} }` (bordo `╭─ TITOLO ─…╮`, `│ … │`, `╰─…╯`; `tipo` ∈ `nil|"rosso"|"verde"` sceglie il gruppo del bordo; colonne in byte).
- Produces: `ui.tabline()` e `ui.statusline()` (stringhe per `%!v:lua`), che leggono `require('dattilo.stato')` = tabella `{ titolo, destra, modo_file, metriche = fn()->string[] }`.
- Produces: `ui.finestra_tip()` crea/riusa lo split in alto alto 4 righe (`winfixheight`, niente numeri, non riceve il fuoco: `WinEnter` → `wincmd p`), `ui.tip(titolo, testo, tipo)` lo ridisegna; `VimResized` lo ridisegna con la nuova larghezza.
- Create anche `lua/dattilo/stato.lua` (tabella condivisa, nessuna logica).

- [ ] **Step 1: test**: `ui.a_capo("aa bb cc", 5)` → `{"aa bb", "cc"}`; `ui.a_capo("premi ‹:w› ora", 8)` non spezza `‹:w›`; `ui.riquadro("TIP", "ciao", 20, 2)` → 4 righe, la prima inizia con `╭─ TIP ` e tutte hanno 20 colonne di display (`vim.fn.strdisplaywidth`); `ui.segmenti("premi ‹i›", "X")` → `{{"premi ","X"},{" i ","DattiloTasto"}}`.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: interfaccia, riquadro dei suggerimenti e barre`.

### Task 4: Batti

**Files:** Create `lua/dattilo/batti.lua`, `tests/test_batti.lua`

**Interfaces:**
- Consumes: `confronto.*`, `metriche.nuova`.
- Produces: `batti.avvia(buf: int, bersaglio: string[], cb: { su_cambio = fn(stato), su_finito = fn(m) }) -> stato` dove `stato = { metriche = m, bersaglio, finito = bool }`; imposta le opzioni di buffer dei Global Constraints, mappa `<CR>` in insert (expr) per inserire `"\r" .. rientro della riga bersaglio successiva`, aggancia `TextChanged`/`TextChangedI`/`InsertLeave`/`InsertEnter` per `batti.aggiorna(buf)` e per le metriche (`confronto.inseriti` sulla riga del cursore rispetto alla copia precedente; testo inserito confrontato con il bersaglio alla stessa colonna; nuova riga = `a_capo`), pausa in normale e ripresa in insert.
- Produces: `batti.aggiorna(buf)` ridisegna extmark nel namespace `dattilo_batti`: `DattiloErrore` sugli errori, `virt_text` con `virt_text_pos="overlay"` per la coda, `virt_lines` per `sotto` agganciate all'ultima riga; segno `●` (`DattiloErrore`) nella colonna dei segni delle righe con errori.
- Produces: `batti.stacca(buf)`.

- [ ] **Step 1: test** (headless, buffer reale): `avvia` con bersaglio `{"int x;", "}"}`, `nvim_buf_set_lines` a `{"imt"}`, `aggiorna` → un extmark con `hl_group="DattiloErrore"` su `(0,1)-(0,2)` e virt_lines con `"}"`; buffer `{"int x;", "}", "z"}` → nessun errore Lua, errore sulla riga 2; buffer uguale al bersaglio → `cb.su_finito` chiamato una volta; `vim.bo[buf].expandtab == true` e `indentexpr == ""`; la mappa `<CR>` restituisce `"\r    "` quando la riga bersaglio successiva inizia con 4 spazi.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: schermata Batti con fantasma, errori e metriche`.

### Task 5: Compila ed esegui

**Files:** Create `lua/dattilo/compila.lua`, `tests/test_compila.lua`

**Interfaces:**
- Produces: `compila.esegui(dir: string, file: string) -> r` con `r = { ok = bool, compilato = bool, warning = bool, diagnostica = string, uscita = string, codice = int|nil, comando = string, scaduto = bool }`, flag dei Global Constraints, eseguibile = nome del file senza `.c`.
- Produces: `compila.messaggio(r) -> chunks` per `nvim_echo` (righe `$ comando`, diagnostica con `error` → `DattiloErrore`, `warning` → `DiagnosticWarn`, `note` → `DiagnosticInfo`, uscita, ultima riga verde "compilato senza warning" o gialla "compilato con warning").

- [ ] **Step 1: test** (cartella temporanea): Hello World → `ok`, `uscita == "Hello World\n"`, `warning=false`; senza `#include` → `compilato=false`, `diagnostica` contiene `implicit declaration of function 'printf'` (accetta apici tipografici); `printf("%d %d\n", 1)` → `compilato=true`, `warning=true`; `while(1);` in main → `scaduto=true` entro 6 s; con `PATH` senza `cc` (`vim.env.PATH = "/nonesiste"` nel test, ripristinato) → `ok=false` e diagnostica che nomina `cc`.
- [ ] **Step 2–4:** FAIL, implementa con `vim.system(...):wait()`, OK. **Step 5:** commit `feat: compilazione ed esecuzione con cc`.

### Task 6: Esercizi di modifica e Dojo

**Files:** Create `lua/dattilo/esercizio.lua`, `lua/dattilo/dojo.lua`, `tests/test_esercizi.lua`

**Interfaces:**
- Produces: `esercizio.avvia(o) -> e` con `o = { buf, partenza: string[], obiettivo: string[]|nil, cursore_obiettivo: {r0,c0}|nil, pos: {r0,c0}, par: int, soluzione: string (tasti in notazione Neovim, es. "3jci\"Ciao mondo\\n<Esc>"), consegna, aiuto, su_fatto = fn(tasti: int, stelle: int) }`; conta i tasti con `vim.on_key` (argomento `typed`, solo con il fuoco nel buffer `o.buf`); finestra obiettivo in basso (`botright split`, altezza `#obiettivo + 1`, `winbar` " OBIETTIVO ", differenze `DattiloAggiunto` con `confronto.diff_riga`); segno `~` sulle righe diverse; riuscito su `TextChanged`/`CursorMoved`/`ModeChanged` quando in normale; `:e!` ricomincia (abbreviazione `cnoreabbrev <expr>` → comando `DattiloRicomincia`).
- Produces: `esercizio.stelle(tasti, par) -> int`; `esercizio.chiudi(e)`.
- Produces: `dojo.ESERCIZI` (i 7 della demo, con `titolo`, `partenza`, `obiettivo` o `cursore_obiettivo`, `pos`, `par`, `soluzione`, `aiuto`) e `dojo.apri(i)`.

- [ ] **Step 1: test**: `stelle(18,18)=3`, `stelle(27,18)=2`, `stelle(28,18)=1`; per ogni esercizio del Dojo: buffer con `partenza`, cursore a `pos`, `nvim_feedkeys(nvim_replace_termcodes(soluzione), "xt", false)` → testo uguale a `obiettivo` (o cursore su `cursore_obiettivo`) e numero di tasti della soluzione (contati sui token `<...>` come uno) uguale a `par`; stesso controllo per le `modifiche` delle lezioni 1 e 2 (Task 7).
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: esercizi di modifica con tasti contati e Dojo Vim`.

### Task 7: Lezioni, schermate, home, progressi

**Files:** Create `lua/dattilo/schermo.lua`, `lua/dattilo/lezione.lua`, `lua/dattilo/home.lua`, `lua/dattilo/progressi.lua`, `lua/dattilo/lezioni/indice.lua`, `lua/dattilo/lezioni/01.lua`, `lua/dattilo/lezioni/02.lua`, `tests/test_lezioni.lua`

**Interfaces:**
- Consumes: tutto quanto sopra.
- Produces: `schermo.scrivi(buf, righe)` con `righe = { { {testo, hl}, ... } }` (imposta testo e extmark; buffer `nomodifiable`), `schermo.buffer(nome) -> buf` (scratch riusabile).
- Produces: formato lezione dello spec; `rompi = { consegna, rotto = fn(righe)->bool, attesa = "errore"|"warning", dopo, ripara = string[] }`; `esegui = { atteso = string }`.
- Produces: `lezione.apri(n: int)` con passi `briefing → batti → modifica (una o più) → rompi → spiegazione → fine`; `:w` in batti/rompi → `compila.esegui` e `nvim_echo(compila.messaggio(r), true, {})`; avanzamenti come nella demo; risultati in `progressi.registra(id, { wpm, precisione, tempo_ms, tasti_modifica })`.
- Produces: `home.apri()` (logo, menu Corso C / Dojo Vim / Endless "passo 4" / Statistiche "passo 4" / Esci, `j`/`k`/`<CR>` e scorciatoie `c d e s q`, elenco delle 38 lezioni con le prime 2 giocabili); `:q`, `:wq`, `:x` via `cnoreabbrev <expr>` → `DattiloEsci` (home se fuori dalla home, `qa!` dalla home).
- Produces: `progressi.carica() -> t`, `progressi.registra(id, r)`, file `progressi.json`.

- [ ] **Step 1: test**: per le lezioni 1 e 2 il codice di `batti` compila con `compila.esegui` e stampa `esegui.atteso` (prima della modifica: `Hello World\n` e `Hello World 30\n`); il testo di `rompi.ripara` compila senza warning; applicare a `ripara` la mossa di rottura descritta nella consegna (test: per la 1 togliere la riga 1, per la 2 aggiungere ` %d` prima di `\n`) rende `rotto(...) == true` e la compilazione dà rispettivamente errore e warning; `progressi.registra` + `carica` in una cartella temporanea (`vim.env.XDG_DATA_HOME`) conserva wpm e tempo; l'abbreviazione su `q` produce `DattiloEsci`.
- [ ] **Step 2–4:** FAIL, implementa, OK. **Step 5:** commit `feat: lezioni 1 e 2, home e progressi`.

### Task 8: Prova vera nel terminale, installazione, repo

**Files:** Create `tests/e2e.sh`, `README.md`

- [ ] **Step 1:** `tests/e2e.sh`: `tmux new-session -d -x 100 -y 32 bin/dattilo`, poi `send-keys` per: `c` (corso), `<CR>` (lezione 1), `<CR>` (via), `i` + codice riga per riga con `Enter`, `Escape`, `:w Enter`, `capture-pane -p` deve contenere `Hello World` e il prompt di Neovim (`Premi INVIO` o `Press ENTER`, secondo la lingua); poi `Enter`, `3jci"Ciao mondo\n Escape` → contiene `Par 18`; `ggdd :w` → contiene `implicit declaration`; `u :w` → contiene `Ciao mondo`; `Enter` → contiene `Cosa hai scritto`. Esce 0 se tutte le catture contengono il testo atteso, altrimenti stampa la schermata e esce 1. Usa `XDG_DATA_HOME` temporaneo.
- [ ] **Step 2:** `bash tests/e2e.sh` → PASS.
- [ ] **Step 3:** `ln -sf ~/code/dattilo/bin/dattilo ~/.local/bin/dattilo`; README con installazione, tasti e passi del progetto.
- [ ] **Step 4:** `gh repo create Frumorn12/dattilo --private --source . --push`.
- [ ] **Step 5:** commit `docs: README e prova end-to-end` e push.
