#!/usr/bin/env bash
# Collaudo di «Rifallo tu» (dattilo vivo) in un terminale vero, con tmux: quello che il Neovim figlio
# delle prove non sa fare (il ridisegno del riquadro nella riga dei comandi e con un operatore in
# attesa, Ctrl-z, il pannello chiuso di colpo). Sullo stampo di tests/e2e.sh.
#
# Esce con 0 e stampa «COLLAUDO OK», oppure con 1 e stampa lo schermo dove si è fermato.
# Fanno eccezione le cose che non si sanno provare: la riga dei comandi e l'operatore in attesa se il
# riquadro non si ridisegna (punti 2 e 3), e Ctrl-z se nemmeno senza la guida Neovim si ferma (è
# l'ambiente, non dattilo). Non fanno fallire: escono con 0, ma al posto di «COLLAUDO OK» lo script
# stampa le righe «NON VERIFICATO: <cosa> (<perché>)» e «COLLAUDO INCOMPLETO».
#
# Sicurezza (lo schermo e i dati di chi lo lancia):
#   - tmux gira su un socket suo, in una cartella temporanea (tmux -S), e senza ~/.tmux.conf: il
#     server predefinito non si tocca mai, e le sessioni di chi lo lancia nemmeno;
#   - casa finta: HOME e gli XDG_* (dati, config, stato, cache, runtime) stanno nella stessa cartella temporanea;
#   - nessun processo si ferma per nome: si cercano i PID dal pannello (list-panes e ps --ppid);
#   - alla fine (anche con un errore) tmux del socket si chiude e la cartella si cancella.
#
# Cosa NON si prova qui, perché serve Herdr: il segnale con cui Herdr chiude il pannello (qui è SIGHUP
# di tmux), Ctrl-z dentro un pannello di Herdr, il clic del mouse dentro il pannello, l'incolla di
# Herdr (il testo incollato arriva da Herdr, non da tmux).
#
# Richiede: bash, tmux (con -e, 3.2 o più nuovo), nvim, node, ps di procps (--ppid).
set -u
RADICE="$(cd "$(dirname "$0")/.." && pwd)"
unset TMUX TMUX_PANE

B="$(mktemp -d -p "${TMPDIR:-/tmp}" dattilo-collaudo.XXXXXX)" || { echo 'COLLAUDO FALLITO: niente cartella temporanea'; exit 1; }
SOCK="$B/tmux.sock"
CASA="$B/casa"
C="$B/cartella"   # la cartella di «Rifallo tu» del collaudo principale
C2="$B/cartella2" # quella della prova di Ctrl-z
mkdir -p "$CASA/dati" "$CASA/config" "$CASA/stato" "$CASA/cache" "$C" "$C2" || exit 1
mkdir -m 700 "$CASA/run" || exit 1 # i socket che Neovim lascia se lo si uccide restano qui, non in /run/user
cp -r "$RADICE/tests/fixture/rifallo/." "$C/" && cp -r "$RADICE/tests/fixture/rifallo/." "$C2/" || exit 1
# la casa finta passa a ogni sessione di tmux
AMB=(-e "HOME=$CASA" -e "XDG_DATA_HOME=$CASA/dati" -e "XDG_CONFIG_HOME=$CASA/config" -e "XDG_STATE_HOME=$CASA/stato" -e "XDG_CACHE_HOME=$CASA/cache" -e "XDG_RUNTIME_DIR=$CASA/run")

# L'unico modo di chiamare tmux: sul socket nostro, senza la configurazione di chi lo lancia.
tm() { tmux -f /dev/null -S "$SOCK" "$@"; }

# I discendenti di un PID (lui compreso), per aspettare che finiscano o per fermarli.
discendenti() { local p; for p in "$@"; do echo "$p"; discendenti $(ps -o pid= --ppid "$p"); done; }
pannelli_pid() { local p; for p in $(tm list-panes -a -F '#{pane_pid}' 2>/dev/null); do discendenti "$p"; done; }

# vero se almeno uno dei PID dati è ancora vivo
qualcuno_vivo() { local p; for p in "$@"; do kill -0 "$p" 2>/dev/null && return 0; done; return 1; }
pulisci() {
  local pids p n
  pids=$(pannelli_pid | sort -u)
  tm kill-server 2>/dev/null
  # un Neovim che si chiude scrive ancora qualcosa: si aspetta, poi si ferma per PID quello che resta
  for n in $(seq 1 30); do qualcuno_vivo $pids || break; sleep 0.1; done
  for p in $pids; do kill -0 "$p" 2>/dev/null && kill -KILL "$p" 2>/dev/null; done
  rm -rf -- "$B"
}
trap pulisci EXIT
trap 'exit 130' INT TERM HUP

S=principale # la sessione di cui si leggono gli schermi
cap() { tm capture-pane -t "$S" -p 2>/dev/null; }
# lo schermo su una riga sola, senza i bordi del riquadro: le frasi del riquadro vanno a capo
piatto() { cap | sed -e 's/│//g' -e 's/─//g' -e 's/╭//g' -e 's/╮//g' -e 's/╰//g' -e 's/╯//g' | tr '\n' ' ' | tr -s ' '; }
fallisci() {
  echo "COLLAUDO FALLITO: $1"
  tm has-session -t "$S" 2>/dev/null || echo "(la sessione tmux $S non c'è più: dattilo è uscito?)"
  echo "----- schermo ($S) -----"; cap; exit 1
}
ok() { echo "  ok: $1"; }
NONVER=()
non_verificato() { NONVER+=("NON VERIFICATO: $1 ($2)"); echo "  non verificato: $1"; }

# G5: «Premi INVIO» (o «Press ENTER») blocca lo schermo dove la guida non può parlare
senza_invio() { cap | grep -q 'INVIO\|ENTER' && fallisci "compare «Premi INVIO» $1"; return 0; }
# vero se lo schermo (riga per riga) o la frase (su una riga sola) compare entro `$2` decimi di secondo
vedo() { local n; for n in $(seq 1 "${2:-100}"); do cap | grep -q -- "$1" && return 0; sleep 0.1; done; return 1; }
vedo_frase() { local n; for n in $(seq 1 "${2:-100}"); do piatto | grep -qF -- "$1" && return 0; sleep 0.1; done; return 1; }
aspetta() { vedo "$1" || fallisci "non vedo: $1"; senza_invio "dopo «$1»"; }
aspetta_frase() { vedo_frase "$1" || fallisci "non vedo la frase: $1"; senza_invio "dopo «$1»"; }
sparita() { local n m="${2:-}"; [ -n "$m" ] || m="c'è ancora: $1"
  for n in $(seq 1 50); do piatto | grep -qF -- "$1" || return 0; sleep 0.1; done; fallisci "$m"; }
tasto() { tm send-keys -t "$S" "$@"; sleep 0.05; senza_invio "dopo il tasto $*"; }
# dopo Esc Neovim aspetta un attimo (ttimeoutlen) per capire se è un tasto o l'inizio di Alt-qualcosa
esc() { tasto Escape; sleep 0.2; }
scrivi() { local s="$1" c k; for ((k = 0; k < ${#s}; k++)); do c="${s:$k:1}"
  if [ "$c" = ";" ]; then tm send-keys -t "$S" '\;'; else tm send-keys -t "$S" -l -- "$c"; fi
  sleep 0.02; senza_invio "dopo il carattere «$c»"; done; }
# la lezione parte dal COMINCIA
avvia_sessione() { # $1 nome, $2 cartella, $3 file dove scrivere l'uscita
  local cmd; cmd="$(printf '%q ' "$RADICE/bin/dattilo" vivo "$2"); echo \$? > $(printf '%q' "$3")"
  tm new-session -d -s "$1" -x 100 -y 40 -c "$CASA" "${AMB[@]}" bash -c "$cmd" || { echo 'COLLAUDO FALLITO: tmux non parte'; exit 1; }
}
sessione_finita() { local n; for n in $(seq 1 50); do tm has-session -t "$1" 2>/dev/null || return 0; sleep 0.1; done; return 1; }
# aspetta che i PID dati siano spariti (un Neovim chiuso da fuori scrive ancora la bozza)
spariti() { local n; for n in $(seq 1 60); do qualcuno_vivo "$@" || return 0; sleep 0.1; done; return 1; }
# il PID dell'unico figlio del PID dato (il processo del pannello cerca da sé il suo)
figlio() { local f; f=$(ps -o pid= --ppid "$1" | tr -d ' '); case "$f" in ''|*[!0-9]*) return 1;; esac; echo "$f"; }

#################################################################### 1. la lezione 1, battuta davvero
command -v tmux >/dev/null || { echo 'COLLAUDO FALLITO: manca tmux'; exit 1; }
avvia_sessione principale "$C" "$B/uscita1"
aspetta 'COMINCIA'
# il rilevatore di «Premi INVIO» deve vedere davvero il «Premi INVIO» (senza questa prova un rilevatore
# rotto direbbe sempre «nessun INVIO»)
scrivi ':echo "a\nb"'; tm send-keys -t "$S" Enter
vedo 'INVIO\|ENTER' 30 || fallisci 'il rilevatore non vede il «Premi INVIO» che Neovim mostra'
tm send-keys -t "$S" Enter # un tasto qualunque chiude la richiesta
aspetta 'COMINCIA'
ok 'il rilevatore di «Premi INVIO» vede quello vero'
tasto Enter; aspetta 'SCRIVI'
tasto i; aspetta_frase 'lettera per lettera'
scrivi 'function somma(a, b) {'; tasto Enter
scrivi 'if (typeof a'
# l'a capo arriva troppo presto: la guida dice quante volte premere Backspace, e si preme proprio quelle
tasto Enter
aspetta_frase 'a capo arrivato troppo presto'
frase=$(piatto | grep -o 'premilo \(una volta\|[0-9][0-9]* volte\)' | head -1)
case "$frase" in
  'premilo una volta') n=1 ;;
  premilo\ *\ volte) n="${frase#premilo }"; n="${n% volte}" ;;
  *) fallisci 'il riquadro non dice quante volte premere Backspace' ;;
esac
for ((k = 1; k < n; k++)); do
  tasto BSpace; sleep 0.3
  piatto | grep -qF 'a capo arrivato troppo presto' || fallisci "la riga era già riunita dopo $k Backspace, ma la guida ne chiedeva $n"
done
tasto BSpace
sparita 'a capo arrivato troppo presto' "dopo i $n Backspace che dice la guida la riga è ancora spezzata"
aspetta_frase 'lettera per lettera'
ok "la riga spezzata si riunisce con i Backspace che dice la guida ($n)"
scrivi ' !== "number") return 0;'; tasto Enter
scrivi 'return a + b;'; tasto Enter
scrivi '}'
aspetta 'FINITO'
esc
scrivi ':w'; tasto Enter
aspetta 'CAPISCI'
ok 'lezione 1: SCRIVI, FINITO, :w, CAPISCI'

# la lezione 2, per i punti che seguono: si arriva al suo Batti dal riepilogo
tasto Enter; aspetta 'FATTO'
tasto Enter; aspetta 'COMINCIA'
tasto Enter; aspetta 'SCRIVI'
tasto i; aspetta_frase 'lettera per lettera'
scrivi 'function saluta(nome) {'; tasto Enter
scrivi 'ret'
esc; aspetta 'SCRIVI'

#################################################################### 2. la riga dei comandi
# il riquadro si ridisegna mentre il cursore è nella riga dei comandi
altezza=$(tm display-message -p -t "$S" '#{pane_height}')
nella_riga_dei_comandi() { # $1 = colonna del cursore (0 = prima lettera)
  local y x; read -r y x < <(tm display-message -p -t "$S" '#{cursor_y} #{cursor_x}')
  [ "$y" = "$((altezza - 1))" ] && [ "$x" = "$1" ] && cap | tail -1 | grep -q '^:'
}
scrivi ':'
if vedo 'RIGA DEI COMANDI' 50 && sleep 0.3 && nella_riga_dei_comandi 1; then
  scrivi 'w'
  if vedo_frase 'esegui :w' 50 && sleep 0.3 && nella_riga_dei_comandi 2; then
    ok 'riga dei comandi: RIGA DEI COMANDI e poi la frase di :w, col cursore sulla riga dei comandi'
  else
    non_verificato 'il riquadro nella riga dei comandi dopo aver scritto :w' 'il riquadro non cambia mentre si scrive il comando, o il cursore lascia la riga dei comandi'
  fi
else
  non_verificato 'il riquadro nella riga dei comandi' 'RIGA DEI COMANDI non compare, o il cursore lascia la riga dei comandi'
fi
senza_invio 'nella riga dei comandi'
esc; aspetta 'SCRIVI'

#################################################################### 3. l'operatore in attesa
scrivi 'd'
if vedo 'NEOVIM ASPETTA' 50; then ok 'operatore in attesa: NEOVIM ASPETTA'
else non_verificato 'il riquadro con un operatore in attesa' 'NEOVIM ASPETTA non compare dopo d'; fi
esc; aspetta 'SCRIVI'

# (non è nel compito: è il terzo posto del rischio 10) la modalità Ex, che si apre con g e Q
scrivi 'gQ'
vedo 'MODALITÀ EX' 50 || fallisci 'il riquadro non dice MODALITÀ EX dopo gQ'
scrivi 'visual'; tm send-keys -t "$S" Enter
vedo 'SCRIVI' 50 || fallisci 'dopo visual il riquadro non torna a SCRIVI'
senza_invio 'dopo la modalità Ex'
ok 'modalità Ex: MODALITÀ EX, e con visual si torna'

#################################################################### 4. Ctrl-z
# Neovim lanciato direttamente da tmux è il capo del suo gruppo di processi, e il kernel ignora lì
# la pausa (SIGTSTP): il controllo sarebbe vuoto. Serve una shell con il controllo dei lavori, come
# in un terminale vero: dattilo parte dalla shell. Prima il controllo contrario: senza la guida
# Ctrl-z mette davvero in pausa Neovim (stato T), altrimenti il resto non prova niente.
stato() { ps -o stat= -p "$1" | tr -d ' '; }
S=controllo
tm new-session -d -s "$S" -x 100 -y 40 -c "$CASA" "${AMB[@]}" bash --norc --noprofile -i || { echo 'COLLAUDO FALLITO: tmux non parte'; exit 1; }
sleep 0.5
tm send-keys -t "$S" -l -- 'nvim --clean -u NONE -n'; tasto Enter
pannello=$(tm list-panes -t "$S" -F '#{pane_pid}')
for n in $(seq 1 50); do tui=$(figlio "$pannello") && break; sleep 0.1; done
[ -n "${tui:-}" ] || fallisci 'il controllo di Ctrl-z: Neovim non è partito'
sleep 0.7
tasto C-z
fermo=no
for n in $(seq 1 30); do case "$(stato "$tui")" in T*) fermo=si; break;; esac; sleep 0.1; done
kill -KILL "$tui" $(ps -o pid= --ppid "$tui") 2>/dev/null
tm kill-session -t "$S"
S=principale
tui=''
if [ "$fermo" = si ]; then
  ok 'controllo contrario: senza la guida Ctrl-z ferma Neovim'
  S=ctrlz
  tm new-session -d -s "$S" -x 100 -y 40 -c "$CASA" "${AMB[@]}" bash --norc --noprofile -i || { echo 'COLLAUDO FALLITO: tmux non parte'; exit 1; }
  sleep 0.5
  tm send-keys -t "$S" -l -- "$(printf '%q ' "$RADICE/bin/dattilo" vivo "$C2")"; tasto Enter
  aspetta 'COMINCIA'
  pannello=$(tm list-panes -t "$S" -F '#{pane_pid}')
  tui=$(figlio "$pannello") || fallisci 'Ctrl-z: non trovo il Neovim della sessione'
  non_fermo() { local p; for p in "$tui" $(ps -o pid= --ppid "$tui"); do
    case "$(stato "$p")" in T*|t*) fallisci "Ctrl-z ha fermato Neovim (PID $p, stato $(stato "$p")) $1";; esac; done; }
  tasto Enter; aspetta 'SCRIVI'
  tasto i; aspetta_frase 'lettera per lettera'
  scrivi 'fun'
  # in INSERT Neovim non si ferma (scrive ^Z): la guida deve dire la sua frase e non scrivere ^Z nel testo
  tasto C-z
  aspetta_frase 'Ctrl-z in Neovim mette in pausa'
  sleep 0.3; non_fermo 'mentre si scrive (INSERT)'
  cap | grep -q '\^Z' && fallisci 'Ctrl-z ha scritto ^Z nel testo'
  cap | grep -q 'Stopped' && fallisci 'Ctrl-z: la shell dice che Neovim è fermo'
  ok 'Ctrl-z in INSERT: la guida lo dice, e non scrive ^Z'
  # in NORMAL e con un operatore in attesa Neovim si ferma davvero, se Ctrl-z non è spento: qui conta lo stato (T)
  scrivi 'c'; sparita 'Ctrl-z in Neovim mette in pausa' 'la frase di Ctrl-z non sparisce quando il testo cambia'
  esc; tasto C-z
  aspetta_frase 'Ctrl-z in Neovim mette in pausa'
  sleep 0.3; non_fermo 'in NORMAL'
  cap | grep -q 'Stopped' && fallisci 'Ctrl-z: la shell dice che Neovim è fermo'
  ok 'Ctrl-z in NORMAL: Neovim non si ferma, e la guida lo dice'
  scrivi 'd'; aspetta 'NEOVIM ASPETTA'
  tasto C-z
  sparita 'NEOVIM ASPETTA'
  sleep 0.3; non_fermo 'con un operatore in attesa'
  cap | grep -q 'Stopped' && fallisci 'Ctrl-z: la shell dice che Neovim è fermo'
  ok "Ctrl-z con un operatore in attesa: Neovim non si ferma, e l'operatore è annullato"
  pids=$(discendenti "$pannello" | sort -u)
  tm kill-session -t "$S"
  spariti $pids || fallisci 'dopo la chiusura Neovim è ancora vivo'
  S=principale
else
  non_verificato 'Ctrl-z con la guida: Neovim non si ferma' 'senza la guida Ctrl-z non ferma nemmeno un Neovim qualunque in questo tmux, e il controllo non proverebbe niente'
fi

#################################################################### 5. il pannello chiuso di colpo
# si riprende a scrivere a metà riga, si aspetta più di 2 s (la bozza si salva ogni 2 s) e si chiude la
# sessione: Neovim riceve SIGHUP, come quando Herdr chiude il pannello
tasto A
scrivi 'urn'
sleep 2.5
pids=$(pannelli_pid | sort -u)
tm kill-session -t "$S"
spariti $pids || fallisci 'dopo la chiusura Neovim è ancora vivo'
S=principale
bozza="$C/bozze/002-saluto.json"
[ -f "$bozza" ] || { echo "COLLAUDO FALLITO: dopo la chiusura di colpo la bozza non c'è"; ls -la "$C" "$C/bozze" 2>&1; exit 1; }
grep -qF '"righe":["function saluta(nome) {","    return"]' "$bozza" || { echo "COLLAUDO FALLITO: la bozza non ha il testo battuto:"; cat "$bozza"; exit 1; }
ok "chiuso di colpo a metà riga: la bozza c'è, col testo battuto"
avvia_sessione principale "$C" "$B/uscita2"
aspetta 'Ripreso'
aspetta_frase 'SCRIVI · RIGA 2' # il cursore è in fondo al testo ripreso, alla riga 2
ok 'una sessione nuova sulla stessa cartella mostra Ripreso, col testo alla riga 2'

#################################################################### 6. :q due volte
scrivi ':q'; tasto Enter
aspetta 'LE LEZIONI DI RIFALLO TU'
scrivi ':q'; tasto Enter
sessione_finita "$S" || fallisci ":q dall'elenco non chiude dattilo"
[ -f "$B/uscita2" ] && [ "$(cat "$B/uscita2")" = 0 ] || { echo "COLLAUDO FALLITO: dattilo è uscito con $(cat "$B/uscita2" 2>/dev/null || echo '?'), non con 0"; exit 1; }
ok ":q dalla lezione e poi dall'elenco: la sessione finisce, uscita 0"

if [ "${#NONVER[@]}" -gt 0 ]; then
  printf '%s\n' "${NONVER[@]}"
  echo "COLLAUDO INCOMPLETO: il resto è a posto; controlli non fatti: ${#NONVER[@]} (sopra)"
else
  echo 'COLLAUDO OK'
fi
