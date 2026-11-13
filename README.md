# dattilo

Scrivi C alla velocità delle mani.

dattilo è un'app da terminale per allenarsi a scrivere codice veloce con i tasti di
Neovim, imparando il C dal corso
[Impariamo il C](https://www.youtube.com/playlist?list=PLrEMgOSrS_3cFJpM2gdw8EGFyRBZOyAKY)
di Salvatore Sanfilippo (antirez).

Ogni lezione segue sei passi:

1. **Briefing**: due righe su cosa farai e le mosse nuove.
2. **Batti**: il codice della lezione è in grigio e lo copri scrivendo. Gli errori
   diventano rossi; parole al minuto e precisione sono nella barra in basso.
3. **Modifica**: cambi il codice con le mosse di Vim, con i tasti contati contro un par.
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
- **Sandbox**: il codice delle lezioni, quando fai `:w`, gira con `bwrap` (se c'è): senza rete,
  con il sistema in sola lettura e la home nascosta; scrive solo nella sua cartella di lavoro.
  Senza `bwrap` gira normalmente: in quel caso importa pacchetti solo da persone di cui ti fidi.

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
| Home e menu | `j` `k` per muoverti, `Invio` per aprire, `c` corso C, `p` pacchetti, `d` Dojo, `q` esci |
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
```

## Licenza

MIT. Il corso e i video sono di Salvatore Sanfilippo: qui ci sono solo riassunti nostri,
il codice riscritto e i link ai minuti dei video.
