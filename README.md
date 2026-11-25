# dattilo

Scrivi C alla velocità delle mani.

dattilo è un'app da terminale per allenarsi a scrivere codice veloce con i tasti di
Neovim, imparando il C dal corso
[Impariamo il C](https://www.youtube.com/playlist?list=PLrEMgOSrS_3cFJpM2gdw8EGFyRBZOyAKY)
di Salvatore Sanfilippo (antirez).

Ogni lezione segue sei passi:

1. **Briefing**: due righe su cosa farai e le mosse nuove.
2. **Batti**: il codice della lezione è in grigio e lo copri scrivendo. Gli errori
   diventano rossi; parole al minuto e precisione sono nella barra in basso. Il riquadro
   in alto spiega su tre livelli quello che stai scrivendo: **Riga** (cosa fa la riga del
   cursore), **Blocco** (il pezzo di programma di cui fa parte) e **Fin qui** (i blocchi
   già scritti, quello in corso e il quadro generale). Gli avvisi su Vim (errore, sei in
   NORMAL, riga lasciata a metà) compaiono in cima senza coprire il resto.
3. **Modifica**: cambi il codice con le mosse di Vim, con i tasti contati contro un par;
   il riquadro dice anche perché la modifica ha senso.
4. **Rompi**: lo rompi apposta e leggi l'errore o il warning vero di `gcc`, poi `u` e `:w`.
5. **Cosa hai scritto**: la spiegazione riga per riga, con i minuti del video.
6. **Riepilogo**: tempi, stelle e prossima lezione.

C'è anche il **Dojo Vim**: esercizi brevi di trasformazione con il par.

Sotto c'è Neovim vero (`nvim --clean`), quindi ogni tasto fa esattamente quello che
fa nel tuo editor.

## Pacchetti

Le lezioni arrivano a **pacchetti**: una cartella con `pacchetto.json` e una lezione per
file Markdown in `lezioni/`. Il corso C è il primo pacchetto, incluso in dattilo. I
pacchetti contengono solo dati (JSON e Markdown), mai codice: importarne uno ricevuto da
altri non può eseguire niente.

Si scambiano come **un solo file `.dattilo`**, di testo:

```sh
dattilo esporta javascript            # scrive javascript-0.1.0.dattilo
dattilo importa javascript-0.1.0.dattilo
dattilo pacchetti                     # elenco degli installati
dattilo nuovo mio-pacchetto           # scheletro da cui partire
dattilo controlla mio-pacchetto       # il codice gira? le soluzioni stanno nel par?
```

Nell'app: home → **Pacchetti** (`p`), poi `i` importa ed `e` esporta.

### Percorsi

I pacchetti che si richiedono a catena (`"richiede"` nel manifesto) diventano un
**percorso**: una voce sola nella home (`r` per il primo), con i pacchetti come capitoli
nell'ordine giusto. Oggi c'è il **Percorso SmartExploration**: JavaScript → Three.js →
ATON → SmartExploration. Le lezioni del percorso si aprono **in fila**: ognuna dopo aver
finito la precedente, anche da un capitolo all'altro. Una lezione sbloccata resta aperta
anche se più avanti vengono aggiunte lezioni prima di lei. Il titolo del percorso viene
dal campo `"percorso"` del pacchetto finale.

### Scrivere lezioni

```sh
dattilo riempi mio-pacchetto/lezioni/01-x.md     # scrive blocchi obiettivo, par ed esempio di Rompi dalle soluzioni
dattilo controlla mio-pacchetto 01-x             # controlla una lezione sola
dattilo controlla --tip mio-pacchetto 01-x       # ogni riga con il suo blocco e il suo suggerimento
```

La guida per autori è `SCRIVERE.md` nel repo dei pacchetti; il progetto dei suggerimenti
e dei percorsi è in `docs/superpowers/specs/2026-11-17-suggerimenti-percorso-design.md`.

Il formato completo di una lezione è descritto in
`docs/superpowers/specs/2026-11-13-pacchetti-design.md`. Ogni pacchetto dice come si
esegue il suo codice: `compila` (es. `cc`), `comando` (es. `node main.js`) o
`controllo` (solo la sintassi, es. `node --check`).

### Sicurezza dei pacchetti ricevuti

- **Importare non esegue niente**: il file viene letto, controllato tutto (manifesto, lezioni,
  percorsi) e solo dopo scritto in `~/.local/share/dattilo/pacchetti/<id>/`. Percorsi con `..`,
  percorsi assoluti, estensioni diverse da `.json .md .html .js .css .txt .c` e file oltre 5 MB
  vengono rifiutati senza scrivere nulla.
- **Comandi chiusi**: un pacchetto può chiedere solo `cc`/`gcc`/`clang` con opzioni innocue,
  `./programma` per eseguire il risultato, e `node` (anche con `--check`). Niente shell,
  niente `node -e`, niente plugin del compilatore.
- **Nomi semplici**: il file di una lezione è un nome come `main.js` o `hello.c`, mai un percorso.
- **Soluzioni**: dei comandi `:` sono ammessi solo `:s`, `:sort`, `:noh` e i numeri di riga.
- **Verificatore**: `dattilo controlla` esegue codice e soluzioni del pacchetto, quindi gira
  anche lui dentro la sandbox.
- **Sandbox**: il codice delle lezioni, quando fai `:w`, gira con `bwrap` (se c'è): senza rete,
  con il sistema in sola lettura e la home nascosta; scrive solo nella sua cartella di lavoro.
  Senza `bwrap` gira normalmente: in quel caso importa pacchetti solo da persone di cui ti fidi.

## Rifallo tu (`dattilo vivo`)

**Cos'è.** Mentre Claude Code lavora in Herdr, la mod «Dal vivo» prepara una lezione da ogni
funzione JavaScript che Claude cambia, e dattilo la apre in un pannello accanto al suo terminale:
la riscrivi a mano mentre lui va avanti. Le lezioni nuove vanno in coda («2 nuove») e quella che
stai scrivendo non cambia mai sotto le dita. È il dattilo di sempre, con Neovim vero, ma pensato
per chi non conosce Vim.

```sh
dattilo vivo <cartella>    # apre le lezioni di quella cartella, senza home né menu
dattilo vivo --dove        # una riga JSON con la versione e la cartella di dattilo: la mod la usa per sapere se c'è
```

La cartella esiste già: la crea la mod, che ci scrive anche le lezioni. dattilo la guarda ogni
mezzo secondo, quindi una lezione nuova entra in coda entro un secondo da quando è scritta; se
non ce ne sono, aspetta e apre da sola la prima che arriva. Gli argomenti dopo la cartella vanno a Neovim.
I progressi e i file di lavoro stanno dentro la cartella, in `dati/`, non in `~/.local/share/dattilo`.

**La guida è sempre accesa.** Il riquadro in alto dice, in ogni schermata e in ogni momento, che
tasto premere adesso e cosa fa, come se fosse sempre la prima volta: non serve sapere niente di
Vim. In **Adesso** c'è il prossimo tasto (per esempio «‹i›: entri in scrittura»), in **Comandi**
quelli che valgono lì, in **Controllo** l'esito di `:w` e gli avvisi di dattilo, mai nella riga dei
messaggi. Se finisci in un posto di Vim che non conosci (una selezione, la riga dei comandi, una
finestra in più), il riquadro diventa rosso e dice dov'è e come tornare.

**Comandi.** Si scrivono in minuscolo, come `:q`, e valgono solo con `dattilo vivo`:

| Comando | Cosa fa |
|---|---|
| `:salta` | lascia la lezione, la segna come saltata se non è fatta e apre la prossima da fare; se non ce n'è, aspetta |
| `:ultima` | apre l'ultima lezione non fatta, cioè quella della funzione cambiata per ultima; se non c'è, o è già questa, lo dice nel riquadro |
| `:elenco` | apre l'elenco delle lezioni (✓ fatta, ▸ da fare, «nuova», «saltata»); `j` `k` per scegliere, `Invio` per aprire |

`:q` in una lezione torna all'elenco, e dall'elenco chiude dattilo.

**La bozza.** Il testo che scrivi in Batti si salva da solo in `bozze/<id>.json`: al massimo ogni
2 secondi mentre scrivi, quando esci dalla scrittura, quando cambi lezione e quando il pannello si
chiude, anche di colpo. Riaprendo la lezione si torna dritti a Batti con il testo di prima e la
guida dice «Ripreso». La bozza sparisce quando la lezione è fatta.

**Dove stanno i file**, tutti dentro `<cartella>`:

```
<cartella>/
  indice.json               la mod; dattilo non lo legge
  vuoi.json                 la mod chiede a dattilo di aprire una lezione
  stato.json                dattilo dice alla mod dov'è la persona
  bozze/<id>.json           il testo di Batti salvato
  dati/                     XDG_DATA_HOME di dattilo
    dattilo/pacchetti/rifallo/pacchetto.json
    dattilo/pacchetti/rifallo/lezioni/<id>.md     una lezione per file, nel formato dei pacchetti
    dattilo/lavoro/rifallo/<id>/<file>            il file controllato con node --check
    dattilo/progressi.json                        chiave "rifallo/<id>"
```

Il formato dei file e le regole sono nel progetto, `docs/superpowers/specs/2026-11-23-rifallo-tu-design.md`.

## Requisiti

- Neovim 0.12 o più recente
- un compilatore C come `cc` (GCC 14 o più recente per il passo "rompi" della lezione 1)
- `node` per i pacchetti JavaScript
- consigliato: `bwrap` (bubblewrap) per la sandbox
- facoltativo: tokyonight installato da lazy.nvim, per gli stessi colori di LazyVim

## Installazione

```sh
git clone https://github.com/Frumorn12/dattilo ~/code/dattilo
ln -s ~/code/dattilo/bin/dattilo ~/.local/bin/dattilo
dattilo
```

## Tasti utili

| Dove | Tasti |
|---|---|
| Home e menu | `j` `k` per muoverti, `Invio` per aprire, `c` corso C, `r` percorso, `p` pacchetti, `d` Dojo, `q` esci |
| Batti | `i` per scrivere; per spostarti `Esc`, poi `h` `j` `k` `l`, poi `i` di nuovo; `:w` salva e compila |
| Ovunque | `:q` torna alla home (dalla home chiude l'app), `:e!` ricomincia l'esercizio |

I progressi stanno in `~/.local/share/dattilo/progressi.json`, i file delle lezioni in
`~/.local/share/dattilo/lavoro/`.

## Stato

| Passo | Contenuto | Stato |
|---|---|---|
| 1 | Batti con Neovim vero, lezioni 1 e 2 | fatto |
| 2 | Modifica, compila, rompi, spiegazione, Dojo | fatto |
| 3 | Lezioni 1–8 di antirez (fino al Game of Life) | da fare |
| 4 | Endless e statistiche | da fare |
| 5 | Resto del corso, fantasma che sbiadisce, ripasso | da fare |

Progetto e piano: `docs/superpowers/specs/` e `docs/superpowers/plans/`.

## Prove

```sh
nvim --clean --headless -l tests/run.lua   # test unitari
bash tests/e2e.sh                          # partita vera in tmux
bash tests/rete/prova-rete.sh              # scambio tra due container su una rete finta + attacchi
bash tests/vivo_collaudo.sh                # Rifallo tu (dattilo vivo) in tmux, con i tasti veri
```

## Licenza

MIT. Il corso e i video sono di Salvatore Sanfilippo: qui ci sono solo riassunti nostri,
il codice riscritto e i link ai minuti dei video.
