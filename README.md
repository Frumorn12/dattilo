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

## Requisiti

- Neovim 0.12 o più recente
- un compilatore C come `cc` (GCC 14 o più recente per il passo "rompi" della lezione 1)
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
| Home e menu | `j` `k` per muoverti, `Invio` per aprire, `c` corso, `d` Dojo, `q` esci |
| Batti | `i` per scrivere, `Esc` per uscire, `:w` salva e compila |
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
