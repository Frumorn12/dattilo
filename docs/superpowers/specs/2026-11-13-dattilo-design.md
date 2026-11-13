# dattilo: progetto

Approvato da Andrea il 13/11/2026 sulla proposta con demo
(artifact https://claude.ai/artifact/4KyKTcsBiuBcUu3gfCtEC3).

## Perché

Andrea vuole un'app da terminale che, in quest'ordine:

1. lo faccia scrivere codice più veloce;
2. gli insegni i tasti di Vim/Neovim;
3. gli insegni il C davvero.

Il materiale è il corso "Impariamo il C" di Salvatore Sanfilippo (antirez),
38 video su YouTube (playlist `PLrEMgOSrS_3cFJpM2gdw8EGFyRBZOyAKY`). Quando i
tre obiettivi vanno in conflitto vince la velocità: il codice si scrive subito,
la spiegazione arriva dopo ("prima scrivi, poi capisci").

## Obiettivi

- Un comando, `dattilo`, che apre l'app a tutto schermo nel terminale.
- Neovim vero come motore: ogni tasto si comporta come nell'editor di Andrea.
- Lezioni ricavate dal corso di antirez, ognuna in sei passi: briefing, batti,
  modifica, compila (con "rompilo"), spiegazione, ripasso.
- Modalità endless per la sola velocità.
- Dojo Vim con esercizi di trasformazione e tasti contati contro un par.
- Statistiche: parole al minuto, precisione, tasti lenti, efficienza delle mosse.

## Non obiettivi

- Riscrivere un emulatore di Vim (la demo nel browser lo fa solo per mostrare l'idea).
- Interfaccia grafica, versione web, supporto Windows.
- Mettere nel repo le trascrizioni complete dei video: solo riassunti nostri,
  codice riscritto e link ai minuti.

## Anti-obiettivi

- Tasti che si comportano diversamente da Neovim.
- Plugin che falsano la battitura (autochiusura delle parentesi, completamento,
  rientro automatico diverso dal bersaglio).
- Lezioni lunghe da leggere prima di poter scrivere.

## Vincoli

- Neovim 0.12 (quello di Omarchy), avviato con `nvim --clean -u <init di dattilo>`.
- `cc` del sistema (GCC 16): dal GCC 14 una funzione non dichiarata è un errore,
  e il passo "rompilo" della lezione 1 si basa su questo.
- Dati in `~/.local/share/dattilo` (progressi in JSON, file di lavoro delle lezioni).
- Licenza MIT. `toyforth.c` di antirez (MIT) si può includere citandolo.
- Il materiale di ricerca (trascrizioni, analisi per lezione) sta fuori dal repo
  in `~/code/corso-c-antirez/`.

## Approcci considerati

| Approccio | Pro | Contro | Esito |
|---|---|---|---|
| App in Lua dentro `nvim --clean` | Tasti identici; treesitter C già incluso; `vim.on_key` per misurare; poco codice | Menu e grafici vanno disegnati in buffer | **Scelto** (Andrea ha lasciato a Claude la scelta tecnica) |
| TUI Go/Rust con `nvim --embed` | Libertà grafica totale | Bisogna ridisegnare buffer, cursore, selezioni; il doppio del codice | Scartato |
| Vim emulato da noi | Nessuna dipendenza | Mai identico a Neovim | Scartato |

## Come funziona

### Avvio

`bin/dattilo` esegue `nvim --clean -u <repo>/init.lua`. `init.lua` aggiunge il
repo al `runtimepath`, aggiunge tokyonight se è installato da lazy.nvim
(`~/.local/share/nvim/lazy/tokyonight.nvim`), imposta le opzioni e apre la home.

### Schermo

- In alto la `tabline`: nome dell'app, schermata, avanzamento della lezione.
- Sotto, la finestra del suggerimento: uno split fisso alto 5 righe (3 di testo), con il
  riquadro disegnato in caratteri di box e i tasti evidenziati. Non riceve il fuoco.
- Al centro l'editor: numeri relativi, riga del cursore, colonna dei segni.
- In basso la statusline globale: modalità, file, parole al minuto, precisione,
  tempo, posizione.
- I messaggi lunghi (uscita del compilatore) usano il prompt nativo
  "Premi INVIO" di Neovim.

### Batti

- Il bersaglio è un array di righe. Ciò che manca della riga corrente è testo
  virtuale sovrapposto (extmark `overlay` a fine riga); le righe successive sono
  `virt_lines`.
- Ogni carattere diverso dal bersaglio è evidenziato come errore; i caratteri
  giusti tengono l'evidenziazione di treesitter.
- Rientro: buffer con `autoindent`, `smartindent`, `cindent` e `indentexpr` spenti;
  `<CR>` in insert è rimappato per mettere il rientro della riga bersaglio successiva.
- Metriche: tempo dal primo tasto in insert al completamento; caratteri giusti e
  sbagliati contati confrontando, a ogni modifica, i caratteri inseriti con il
  bersaglio; parole al minuto = caratteri giusti / 5 / minuti.
- Finito quando le righe del buffer coincidono con il bersaglio.

### Modifica (e Dojo)

- Testo di partenza e testo obiettivo. Lo split in basso mostra l'obiettivo con
  le differenze evidenziate; la colonna dei segni marca con `~` le righe ancora diverse.
- Si contano tutti i tasti premuti (`vim.on_key`, argomento `typed`) dall'inizio
  dell'esercizio. Riuscito quando il testo coincide e si è in modalità normale.
- Stelle: tre se tasti ≤ par, due se ≤ 1,5 × par, una altrimenti. Dopo 2 × par
  il suggerimento mostra la soluzione. `:e!` ricomincia.

### Compila e rompi

- Il file della lezione è un file vero in `~/.local/share/dattilo/lavoro/<lezione>/`.
  `:w` lo salva e, tramite `BufWritePost`, lancia `cc -Wall -Wextra -O2` e poi il
  programma (con timeout), mostrando uscita e diagnostica.
- Il passo "rompi" ha una condizione sul testo (es. manca `#include`) e un'uscita
  attesa del compilatore (errore o warning). Dopo averlo visto, `u` e `:w`.

### Spiegazione e fine

- Buffer in sola lettura con il codice evidenziato e le note come testo virtuale
  a destra; sotto, i momenti del video con il minuto. `v` apre il video al minuto
  giusto con `vim.ui.open`.
- Riepilogo: tempo, parole al minuto, precisione, tasti nella modifica contro il par,
  mosse e concetti nuovi, prossima lezione. I risultati vanno nei progressi.

### Formato di una lezione

Un file Lua in `lua/dattilo/lezioni/NN.lua` che ritorna una tabella con:
`id`, `numero`, `etichetta`, `titolo`, `video` (id, durata, minuto di partenza),
`briefing`, `passi` (cosa farai), `mosse`, `concetti`, `file`, `batti` (codice e
suggerimenti per riga), `modifiche` (consegna, aiuto, obiettivo, par, soluzione),
`rompi` (consegna, condizione, cosa aspettarsi, testo atteso dopo la riparazione),
`esegui` (uscita attesa), `spiegazione` (note per riga, momenti, trappola, prova),
`prossima`.

## A step

1. **Batti con Neovim vero**: comando, schermata Batti con fantasma, errori,
   metriche e suggerimento; lezioni 1 e 2.
2. **Modifica, compila, rompi**: Dojo con tasti contati, `:w` che compila,
   spiegazione e riepilogo. La lezione 1 completa come nella demo.
3. **Fondamenta del corso**: lezioni 1–8 di antirez.
4. **Endless e statistiche**: spezzoni da `toyforth.c` e dalle lezioni, tasti lenti,
   grafici, home con la serie di giorni.
5. **Resto del corso e ripasso**: fantasma che sbiadisce, ripasso distanziato.

## Lasciato a chi costruisce

- Nomi interni di moduli e funzioni.
- Colori quando tokyonight non c'è (schema predefinito di Neovim più gruppi propri).
- Testi esatti dei suggerimenti, purché brevi e con i tasti evidenziati.
