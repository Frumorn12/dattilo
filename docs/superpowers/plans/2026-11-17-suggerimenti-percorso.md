# Suggerimenti a tre livelli e percorso: piano

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Suggerimenti di riga, blocco e «fin qui»; il percorso JS → Three.js → ATON → SmartExploration con le lezioni in fila; pacchetti 0.3.0 più grandi.

**Architecture:** Il formato Markdown riceve `### Blocchi` e `motivo:`. Il riquadro del suggerimento diventa a sezioni con altezza fissa per tutta la lezione. Il percorso si deduce da `richiede`; gli sblocchi stanno in `progressi.json`. I contenuti li scrivono subagent (Opus) a partire da una lezione pilota.

**Tech Stack:** Lua in Neovim 0.12 (`nvim --clean`), node per le lezioni JS, bwrap.

**Spec:** `docs/superpowers/specs/2026-11-17-suggerimenti-percorso-design.md`

## Global Constraints

- I pacchetti restano solo dati: nessun campo nuovo esegue codice.
- Errori di formato (sempre): un suggerimento fuori dal codice o su una riga vuota; un blocco non valido, fuori dal codice, sovrapposto o fuori ordine.
- `controlla` in più: ogni riga non vuota di Batti ha un suggerimento ed è dentro un blocco.
- Il riquadro ha 8 righe interne in lezione (6 se `lines < 34`) e 3 fuori.
- Lo sblocco si controlla solo nelle schermate, mai in `lezione.apri`.
- Pacchetti alla versione 0.3.0. Il codice di SmartExploration non va mai in repo pubblici.

## Review Focus

- Lezione senza `### Blocchi` (pacchetto di un collega): il riquadro mostra Riga e «riga N di M», niente errori → test in Task 3.
- Cursore su una riga vuota tra due blocchi: vale il blocco dopo; dopo l'ultimo blocco vale l'ultimo → test in Task 3.
- Testo troppo lungo per il riquadro: niente sforamenti, la sezione accorciata finisce con «…» → test in Task 2.
- Pacchetto richiesto ma non installato: il capitolo risulta mancante e le lezioni dopo restano bloccate → test in Task 4.
- Lezione aggiunta prima di una già sbloccata: la vecchia resta aperta grazie a `sbloccate` → test in Task 4.

---

### Task 1: Formato: blocchi, motivo e controlli

**Files:** `lua/dattilo/formato.lua`, `lua/dattilo/controlla.lua`, `lua/dattilo/cli.lua`, `tests/test_formato.lua`, `tests/fixture/lezione-completa.md`

**Produces:**
- `L.batti.blocchi = { { da = int, a = int, titolo = str, cosa = str, quadro = str|nil }, … }`, in ordine
- `m.motivo` (string|nil)
- `controla.pacchetto(dir, solo)`, dove `solo` è un id di lezione o nil
- CLI `controlla <dir> [lezione]` e `controlla --tip <dir> <lezione>`

- [ ] Test: una fixture con `### Blocchi` → `blocchi[1] == {da=1,a=3,titolo=…,cosa=…,quadro=…}`; con un blocco `5-3`, uno sovrapposto, uno oltre la fine o un suggerimento su una riga vuota → `formato.lezione` restituisce nil con il messaggio.
- [ ] Test: `controlla` su un pacchetto con una riga non vuota senza suggerimento → errore «riga N senza suggerimento»; senza blocco → «riga N fuori dai blocchi».
- [ ] Implementazione, poi `nvim --clean --headless -l tests/run.lua`: deve dare OK. Commit.

### Task 2: Riquadro a sezioni

**Files:** `lua/dattilo/ui.lua`, `tests/test_ui.lua`

**Produces:**
- `ui.riquadro(titolo, contenuto, larghezza, righe_interne, tipo)`, dove `contenuto` è una stringa (come prima) oppure una lista `{ {etichetta=str|nil, testo=str, hl=str|nil, priorita=int}, … }`
- `ui.tip(titolo, contenuto, tipo)` e `ui.altezza_tip(n|nil)`: nil vuol dire 3, l'altezza fuori lezione

- [ ] Test: con le sezioni, ogni riga ha la larghezza piena, l'etichetta ha la sua colonna (9 caratteri) e il testo va a capo sotto di sé. Con troppo testo: esattamente n righe interne, la sezione con priorità più bassa accorciata con «…». Con `altezza_tip(8)` la finestra ha 10 righe; con `altezza_tip(nil)` torna a 5.
- [ ] Implementazione, test, commit.

### Task 3: Suggerimenti nella lezione

**Files:** `lua/dattilo/lezione.lua`, `lua/dattilo/esercizio.lua`, `tests/test_lezioni.lua`, `tests/test_revisione.lua`

**Consumes:** Task 1 e Task 2.

**Produces:** `lezione.tip_batti(s, modo) -> titolo, sezioni, tipo`; `lezione.blocco_di(L, riga) -> indice|nil`; `esercizio.testo_tip(e) -> titolo, sezioni`.

- [ ] Test:
  - Con il cursore sulla riga 2 della fixture: titolo `RIGA 2 · blocco 1 di 2: …`, sezioni Riga, Blocco e Fin qui (catena con ▸ sul primo blocco).
  - In NORMAL: c'è anche una sezione avviso in cima.
  - Lezione senza blocchi: nessuna sezione Blocco e Fin qui «riga 2 di N».
  - Riga vuota tra due blocchi: vale il blocco dopo.
  - Modifica con `motivo`: compare la sezione Perché.
- [ ] Altezza del riquadro: 8 in lezione (6 sotto 34 righe); `lezione.chiudi` la rimette a nil. Test, commit.

### Task 4: Percorsi e sblocchi

**Files:** `lua/dattilo/pacchetti.lua`, `lua/dattilo/progressi.lua`, `lua/dattilo/formato.lua` (campo `percorso` del manifesto), `tests/test_percorso.lua`

**Produces:**
- `pacchetti.percorsi() -> { {titolo=str, capitoli={ {id=str, P=pacchetto|nil}, … }, lezioni={ {pacchetto=id, n=int, L=lezione}, … }}, … }`
- `pacchetti.percorso_di(id) -> percorso|nil, indice_capitolo`
- `progressi.aperta(percorso, i, dati) -> bool`
- `progressi.sblocca(chiave)`; `progressi.registra` sblocca la lezione successiva del percorso

- [ ] Test con pacchetti finti in `XDG_DATA_HOME` (a ← b ← c):
  - l'ordine è a, b, c;
  - un capitolo che manca blocca quello che viene dopo;
  - la prima lezione è aperta, la seconda si apre dopo aver completato la prima;
  - una lezione in `sbloccate` resta aperta anche se ne viene inserita una prima;
  - `percorso` del manifesto dà il titolo.
- [ ] Implementazione, test, commit.

### Task 5: Schermate

**Files:** `lua/dattilo/home.lua`, `lua/dattilo/lezione.lua` (fine), `tests/test_percorso.lua`, `tests/e2e.sh`

- [ ] `home.percorso(indice, capitolo)`:
  - mostra le intestazioni dei capitoli e le lezioni con ✓, ▸ o 🔒;
  - ‹j› e ‹k› saltano le intestazioni;
  - ‹Invio› su una lezione bloccata dice «Prima finisci <lezione>»;
  - ‹q› torna alla home.
- [ ] Home: una voce per ogni percorso (scorciatoia ‹r› per il primo) e la «Prossima del percorso». Pacchetti ordinati come dice il progetto; ‹Invio› su un pacchetto del percorso apre il percorso su quel capitolo.
- [ ] Riepilogo: a fine capitolo, «Prossima» è la prima lezione del capitolo dopo; senza prossima si torna al percorso.
- [ ] Test (percorso aperto, ‹Invio› su una lezione bloccata che non apre niente, prossima a fine capitolo); poi `bash tests/e2e.sh`. Commit.

### Task 6: Lezione pilota e corso C

- [ ] Riscrivere `javascript/lezioni/01-let-const-tipi.md` con il formato completo: suggerimenti su ogni riga, blocchi con quadro, motivo, 5 modifiche e 25 note. Poi `dattilo controlla --tip` e una prova a mano in tmux.
- [ ] Corso C 01 e 02: suggerimenti, blocchi e motivo. Commit nei due repo.

### Task 7: Contenuti (subagent Opus, 2 per pacchetto)

- [ ] Rinumerare i file con l'elenco nuovo delle lezioni (deciso prima di lanciare i subagent).
- [ ] Per ogni pacchetto, un agente aggiorna le lezioni esistenti e uno scrive quelle nuove. Il riferimento è il pilota. Ognuno lancia `dattilo controlla <pkg> <lezione>` finché non è tutto pulito.
- [ ] Revisione mia di un campione: allineamento dei suggerimenti e qualità.

### Task 8: Chiusura

- [ ] Versione 0.3.0, `"percorso"` nel manifesto di smartexploration, `./esporta.sh`, `dattilo importa … --si` per ognuno. Poi `dattilo pacchetti` per vedere ordine e versioni.
- [ ] Aggiornare README e SCRIVERE.md, tutti i test, push dei due repo, nota in memoria.
