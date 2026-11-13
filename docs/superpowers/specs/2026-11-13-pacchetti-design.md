# dattilo: pacchetti di lezioni

Progetto del 13/11/2026, da approvare.

## Perché

Andrea vuole che le lezioni di dattilo non siano solo quelle del corso C, ma
**pacchetti** che chiunque può scrivere, esportare in un file e importare.
Il primo uso è una guida al codice di **SmartExploration**, l'app web che
Andrea sviluppa in 3D Research sopra ATON e Three.js. Il percorso è
JavaScript → Three.js → ATON → SmartExploration. L'obiettivo resta quello di
dattilo: scrivere il codice veloce con i tasti di Neovim e capirlo davvero.

## Obiettivi

- Un formato di pacchetto semplice da scrivere a mano: cartella con un
  manifesto e una lezione per file Markdown.
- Esportare un pacchetto in **un solo file** `.dattilo` e importarlo da file,
  sia da riga di comando sia dall'app.
- Ogni pacchetto dichiara come si esegue il suo codice (C con `cc`, JS con
  `node`, solo controllo della sintassi, anteprima nel browser).
- Il corso C attuale diventa il primo pacchetto, `corso-c-antirez`, nello
  stesso formato (le lezioni 1 e 2 vengono convertite).
- Quattro pacchetti nuovi, nell'ordine: `javascript`, `threejs`, `aton`,
  `smartexploration`.

## Non obiettivi

- Un registro pubblico o un negozio di pacchetti: i pacchetti sono privati e
  si scambiano come file.
- Firma o cifratura dei file `.dattilo`.
- Eseguire SmartExploration o ATON per intero dentro dattilo.

## Anti-obiettivi

- Un pacchetto importato che esegue codice dentro Neovim: i pacchetti sono
  **solo dati** (JSON e Markdown), mai Lua. Importare un file ricevuto da
  altri non deve poter fare nulla oltre a mostrare lezioni.
- Percorsi nel file `.dattilo` che scrivono fuori dalla cartella del pacchetto.
- Mettere in un repo pubblico il codice di SmartExploration.

## Vincoli

- Neovim 0.12, `nvim --clean`; nessun plugin esterno.
- Andrea è l'autore di SmartExploration e può usarne il codice per la guida.
  Il codice di SmartExploration lo legge solo Claude, mai DeepSeek.
- I sorgenti dei pacchetti stanno in un repo **privato**
  (`Frumorn12/dattilo-pacchetti`); si condividono con il file `.dattilo`.
- Parser treesitter: C è incluso in Neovim; per JavaScript dattilo usa quello
  già installato da LazyVim in `~/.local/share/nvim/site/parser` se c'è,
  altrimenti l'evidenziazione classica di Vim.

## Approcci considerati

| Approccio | Pro | Contro | Esito |
|---|---|---|---|
| **Cartella con `pacchetto.json` e lezioni in Markdown** | Si scrive a mano, si legge su GitHub, solo dati, il codice sta in blocchi ``` normali | Serve un piccolo parser Markdown in Lua | **Scelto** |
| Lezioni come tabelle Lua (formato attuale) | Già funziona | Importare un pacchetto = eseguire codice di altri; scomodo per chi non scrive Lua | Scartato per i pacchetti; il formato attuale viene convertito |
| Un unico JSON o YAML per pacchetto | Facile da leggere per una macchina | Il codice dentro stringhe JSON è illeggibile; YAML non ha parser in Neovim | Scartato |

Per il file da scambiare:

| Approccio | Esito |
|---|---|
| **File di testo `.dattilo`**: un'intestazione e i file del pacchetto uno dopo l'altro | **Scelto**: si apre e si controlla con qualsiasi editor prima di importarlo, non serve `tar`, va bene in chat e per mail |
| Archivio `.tar.gz` o `.zip` | Scartato: binario, non ispezionabile, serve un programma esterno |

Un pacchetto unico o quattro: **quattro**, con dipendenze. JS, Three.js e ATON
servono anche da soli (anche a un collega), SmartExploration li richiede.

## Come funziona

### Pacchetto su disco

```
smartexploration/
  pacchetto.json
  lezioni/
    01-architettura.md
    02-layer-e-poi.md
  file/              (facoltativo: pagine HTML per l'anteprima, file di partenza)
```

`pacchetto.json`:

```json
{
  "id": "smartexploration",
  "titolo": "SmartExploration, il codice",
  "versione": "0.1.0",
  "autore": "Andrea Brescia",
  "descrizione": "L'editor e il viewer di SmartExploration, file per file.",
  "linguaggio": "javascript",
  "richiede": ["aton"],
  "esecuzione": { "tipo": "controllo", "comando": ["node", "--check", "{file}"] }
}
```

`esecuzione.tipo`:

- `compila`: `compila` (comando) e poi `esegui` (comando); uscita confrontata
  con quella attesa. È il caso del C.
- `comando`: un solo comando che esegue il file (`node {file}`); uscita
  confrontata con quella attesa.
- `controllo`: solo controllo (`node --check {file}`); nessuna uscita attesa.
- `browser`: controllo della sintassi più anteprima nel browser con una
  pagina del pacchetto servita in locale (arriva dopo, vedi "A step").

Segnaposto nei comandi: `{file}` (es. `main.js`), `{nome}` (senza
estensione). I comandi girano nella cartella di lavoro della lezione, con gli
stessi tetti di oggi (10 s, 5 s, 64 KB di uscita). Una lezione può
sovrascrivere `esecuzione`.

### Lezione in Markdown

````markdown
---
titolo: Layer, POI e POV
breve: il modello dati
file: modello.js
mosse: [ciw, "ci{", yyp, "."]
concetti: [classi, export, getter]
tempo: circa 6 minuti
fonte: model/POI.js
---

## Briefing
Due o tre righe su cosa scriverai.

## Batti
```js
export class POI { … }
```

## Uscita
```text
quello che stampa, se l'esecuzione la prevede
```

## Modifica: Rinomina il campo
aiuto: ‹/titolo› lo trova, ‹ciw› lo cambia.
par: 9
soluzione: /titolo<CR>ciwnome<Esc>
mostra: /titolo · Invio · ciw · nome · Esc

```js
…testo obiettivo…
```

## Rompi
consegna: Togli la graffa di chiusura della classe e salva con ‹:w›.
attesa: errore
cerca: SyntaxError
dopo: node non sa dove finisce la classe. ‹u› e ‹:w›.

## Spiegazione
1: Prima riga della nota | seconda riga
4: Nota sulla riga 4

### Momenti
- 05:26 testo (solo se c'è un video)

### Trappola
Una frase.

### Prova
Una frase.
````

Regole:

- Le sezioni sono titoli `##`; `Modifica` può ripetersi. `Uscita`, `Modifica`,
  `Rompi`, `Momenti`, `Trappola`, `Prova` sono facoltative.
- Il primo blocco ``` di `Batti` è il codice da battere; il blocco di ogni
  `Modifica` è il testo obiettivo. La partenza di ogni modifica è l'obiettivo
  della precedente (la prima parte dal codice di Batti).
- `Rompi` è riuscito quando l'esecuzione fallisce (`attesa: errore`) o avvisa
  (`attesa: warning`) e la diagnostica contiene `cerca`. Si ripara tornando
  al testo dell'ultima modifica con l'esecuzione pulita. Senza `Rompi` la
  lezione passa da Modifica a Spiegazione con un'esecuzione normale.
- Il front matter è un sottoinsieme di YAML: `chiave: valore` e liste
  `[a, b]`. Niente altro.
- Errori del formato: l'import li elenca con file e riga e non installa.

### File `.dattilo`

Testo UTF-8:

```
dattilo-pacchetto 1
id: smartexploration
versione: 0.1.0
--- file: pacchetto.json
{ … }
--- file: lezioni/01-architettura.md
…
```

- Ogni file inizia con una riga `--- file: <percorso>`; il contenuto va fino
  alla prossima riga di quel tipo. Una riga del contenuto che inizia con
  `--- file:` viene scritta con un `\` davanti e ripulita all'import.
- All'import: percorsi relativi, senza `..` e senza `/` iniziale; solo file
  `.json`, `.md`, `.html`, `.js`, `.css`, `.txt`, `.c`; massimo 5 MB in tutto.
- Validazione completa (manifesto e tutte le lezioni) prima di scrivere su disco.

### Dove vanno

- Installati: `~/.local/share/dattilo/pacchetti/<id>/`.
- `corso-c-antirez` è incluso nel repo di dattilo e sempre presente.
- Progressi: chiave `<id pacchetto>/<id lezione>` in `progressi.json`; le chiavi
  vecchie del corso C (`01-hello`, `02-sum`) vengono migrate.

### Comandi

- `dattilo importa <file.dattilo>`: mostra titolo, versione, autore, numero di
  lezioni e dipendenze mancanti, chiede conferma, installa. Se c'è già: chiede
  se sostituire (dice le due versioni).
- `dattilo esporta <id> [file]`: scrive `<id>-<versione>.dattilo`.
- `dattilo pacchetti`: elenco degli installati.
- `dattilo nuovo <id>`: crea lo scheletro di un pacchetto in una cartella, per
  scriverne uno.
- `dattilo controlla <cartella>`: valida un pacchetto e prova le soluzioni
  delle modifiche e la compilazione, come fanno i test di oggi per il C.

Nell'app: la home ha la voce **Pacchetti** (elenco, `i` importa chiedendo il
percorso, `e` esporta, `Invio` apre l'elenco lezioni del pacchetto); la voce
**Corso C** diventa l'apertura del pacchetto `corso-c-antirez`.

### I quattro pacchetti

| Pacchetto | Esecuzione | Lezioni (prima versione) |
|---|---|---|
| `javascript` | `node {file}` | let/const e tipi; stringhe e template; funzioni e arrow; oggetti; array e map/filter/reduce; classi; moduli import/export; Promise e async/await; JSON; errori e try/catch |
| `threejs` | `node {file}` per matematica e grafo della scena (con `three` installato nella cartella di lavoro); controllo per quelle grafiche | Vector3 e matematica; Object3D e gerarchie; Mesh = geometria + materiale; camera, renderer e ciclo di animazione; luci; caricare un glTF; Raycaster; Quaternion e rotazioni |
| `aton` | `controllo` | struttura di una wapp (`app_template`); `ATON.FE` e avvio; nodi e scene; `ATON.Nav` e POV; eventi `ATON.on`; `ATON.SUI`; `ATON.SemFactory`; `ATON.XR`; `ATON.XPFNetwork` |
| `smartexploration` | `controllo` | architettura editor/viewer; Layer, POI, POV; salvataggio e serializzazione; pivot-wrapper e trasformazioni; maschere semantiche; misure; walk start e POV; popup e media; VR, input e controller; export standalone |

Il codice delle lezioni ATON e SmartExploration viene dai file veri
(`~/aton/public/src`, `~/aton/wapps/app_template`, `~/aton/wapps/smartexploration-at`),
ridotto a brani di 10–40 righe che stanno in piedi da soli e passano
`node --check`. Ogni lezione cita il file d'origine (`fonte`).

## A step

1. **Formato e motore**: parser Markdown, manifesto, esecuzioni `compila` /
   `comando` / `controllo`, conversione del corso C, schermata Pacchetti.
2. **Scambio**: `esporta`, `importa`, `pacchetti`, `nuovo`, `controlla`.
3. **Pacchetto `javascript`** (10 lezioni) e repo privato `dattilo-pacchetti`.
4. **Pacchetto `threejs`** (8 lezioni).
5. **Pacchetto `aton`** (9 lezioni).
6. **Pacchetto `smartexploration`** (10 lezioni).
7. Dopo: esecuzione `browser` con anteprima.

## Decisioni prese da Claude (dopo la lettura di un revisore)

Queste regole completano il formato e il motore; Andrea può correggerle.

1. **Rompi.** È riuscito quando l'esecuzione fallisce: compilazione o comando
   con codice d'uscita diverso da 0. Con `attesa: errore` basta questo; con
   `attesa: warning` la compilazione deve riuscire e avere warning, e vale
   solo per `compila`. Se c'è `cerca`, la diagnostica (stderr più stdout) deve
   anche contenerlo. Il testo del buffer non conta per dire "rotto".
   È riparato quando il testo coincide con l'obiettivo dell'ultima modifica
   (le righe vuote in fondo non contano) e l'esecuzione è pulita. `node --check`
   scrive il SyntaxError su stderr ed esce con 1: va bene così.
2. **Campi del corso C.** Il formato li prevede tutti, facoltativi: nel front
   matter `etichetta`, `video` (id YouTube), `durata`, `video_da` (minuto);
   la sezione `## Passi` con righe `- Titolo | descrizione`; dentro `## Batti`
   la sottosezione `### Suggerimenti` con righe `N: testo`. Il numero della
   lezione e la "prossima" vengono dall'ordine dei file. La conversione del
   corso C non perde niente.
3. **Uscita.** Confronto esatto come oggi: il contenuto del blocco `## Uscita`
   più un a capo finale deve essere uguale allo stdout. Vale per `compila` e
   `comando` solo se la sezione c'è; senza, basta un'esecuzione pulita.
4. **Ordine e puntate future.** Le lezioni si ordinano per nome di file
   (`01-…`, `02-…`). Il manifesto può avere `"in_arrivo": [{ "etichetta",
   "titolo", "durata", "video" }]` per le puntate non ancora scritte,
   mostrate in grigio dopo quelle vere: così il corso C tiene l'elenco delle 38.
5. **Progressi.** L'id della lezione è il nome del file senza `.md`; i file del
   corso C si chiamano `01-hello.md` e `02-sum.md`. Al caricamento, se ci sono
   chiavi vecchie (`01-hello`), vengono rinominate in `corso-c-antirez/01-hello`
   e il file viene salvato: succede una volta sola.
6. **Dipendenze.** `richiede` produce solo un avviso, all'import e nella
   schermata del pacchetto; non blocca e non controlla versioni.
7. **Evidenziazione JS.** Se esiste `~/.local/share/nvim/site/parser/javascript.so`,
   dattilo aggiunge `~/.local/share/nvim/site` al `runtimepath` e usa
   treesitter; altrimenti `filetype` e sintassi classica. Le lezioni girano
   uguale.
8. **Cartella `file/` e Three.js.** Prima di eseguire, dattilo copia `file/`
   del pacchetto nella cartella di lavoro della lezione
   (`~/.local/share/dattilo/lavoro/<pacchetto>/<lezione>/`), che resta tra una
   volta e l'altra. Il pacchetto `threejs` include in `file/` la build di
   Three.js (licenza MIT, citata nel pacchetto) e le lezioni la importano da
   `./three.module.js`: niente `npm`, funziona offline.
9. **Escape nel `.dattilo`.** All'export, ogni riga che corrisponde a
   `^\\*--- file:` riceve un `\` in più davanti; all'import se ne toglie uno.
   Così anche una riga che inizia già con `\--- file:` torna identica.

## Lasciato a chi costruisce

- Nomi interni dei moduli Lua.
- Testo esatto dei messaggi di errore dell'import, purché dicano file e riga.
- Quali brani esatti estrarre dai file di ATON e SmartExploration, purché
  coprano gli argomenti della tabella.
