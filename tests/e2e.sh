#!/usr/bin/env bash
# Prova vera nel terminale: avvia dattilo in tmux e gioca la lezione 1, la 2 e un esercizio del Dojo.
set -u
RADICE="$(cd "$(dirname "$0")/.." && pwd)"
S="dattilo-e2e-$$"
export XDG_DATA_HOME="$(mktemp -d)"
trap 'tmux kill-session -t "$S" 2>/dev/null; rm -rf "$XDG_DATA_HOME"' EXIT

cap() { tmux capture-pane -t "$S" -p; }
fallisci() { echo "E2E FALLITO: $1"; echo "----- schermo -----"; cap; exit 1; }
aspetta() { for _ in $(seq 1 80); do cap | grep -q -- "$1" && return 0; sleep 0.1; done; fallisci "non vedo: $1"; }
tasto() { tmux send-keys -t "$S" "$@"; sleep 0.05; }
scrivi() { local s="$1" c; for ((k = 0; k < ${#s}; k++)); do c="${s:$k:1}"
  if [ "$c" = ";" ]; then tmux send-keys -t "$S" '\;'; else tmux send-keys -t "$S" -l -- "$c"; fi; sleep 0.01; done; }
batti_codice() { tasto i; local n=$#; local i=0
  for l in "$@"; do i=$((i + 1)); [ -n "$l" ] && scrivi "$l"; [ "$i" -lt "$n" ] && tasto Enter; done
  tasto Escape; }
PROMPT='ENTER\|INVIO'

mkdir -p "$XDG_DATA_HOME/dattilo/pacchetti"
cp -r "$RADICE/tests/fixture/js-prova" "$XDG_DATA_HOME/dattilo/pacchetti/"
tmux new-session -d -s "$S" -x 110 -y 40 "$RADICE/bin/dattilo"
aspetta 'Prossima lezione'

# Lezione 1
tasto Enter; aspetta 'Impariamo il C'
tasto Enter; aspetta 'Tu adesso'
tasto Enter; aspetta 'Premi  i  per entrare'
batti_codice '#include <stdio.h>' '' 'int main(void) {' 'printf("Hello World\n");' 'return 0;' '}'
aspetta 'SALVA'
scrivi ':w'; tasto Enter; aspetta "$PROMPT"
cap | grep -q '^Hello World$' || fallisci 'manca la stampa di Hello World'
tasto Enter; aspetta 'MODIFICA 1/2'
scrivi '3jci"Ciao mondo\n'; tasto Escape; aspetta 'Par 18'
tasto Enter; aspetta 'MODIFICA 2/2'
scrivi 'ggdd:w'; tasto Enter; aspetta 'implicit declaration'
tasto Enter; aspetta 'CAPITO?'
scrivi 'u:w'; tasto Enter; aspetta "$PROMPT"
cap | grep -q '^Ciao mondo$' || fallisci 'manca la stampa di Ciao mondo'
tasto Enter; aspetta 'Cosa hai scritto'
tasto Enter; aspetta 'riepilogo'
cap | grep -q 'par 18 ★★★' || fallisci 'riepilogo senza par 18'

# Lezione 2 dal riepilogo
tasto Enter; aspetta 'Tu adesso'
tasto Enter; aspetta 'Premi  i  per entrare'
batti_codice '#include <stdio.h>' '' 'int sum(int a, int b) {' 'int c = a + b;' 'return c;' '}' '' 'int main(void) {' 'printf("Hello World %d\n", sum(10, 20));' 'return 0;' '}'
aspetta 'SALVA'
scrivi ':w'; tasto Enter; aspetta 'Hello World 30'
tasto Enter; aspetta 'MODIFICA 1/2'
scrivi '9Gf1ci(5, 7'; tasto Escape; aspetta 'Par 12'
tasto Enter; aspetta 'MODIFICA 2/2'
scrivi '9Gf\i %d'; tasto Escape; scrivi ':w'; tasto Enter; aspetta 'warning'
tasto Enter; scrivi 'u:w'; tasto Enter; aspetta 'Hello World 12'
tasto Enter; aspetta 'Cosa hai scritto'
tasto Enter; aspetta 'riepilogo'

# :q torna alla home, poi un pacchetto JavaScript
scrivi 'q'; aspetta '2 lezioni fatte'
scrivi 'p'; aspetta 'JS di prova'
scrivi 'j'; tasto Enter; aspetta 'Una somma in JavaScript'
tasto Enter; aspetta 'Tu adesso'
tasto Enter; aspetta 'Premi  i  per entrare'
batti_codice 'const somma = (a, b) => a + b;' 'console.log(somma(2, 3));'
aspetta 'SALVA'
scrivi ':w'; tasto Enter; aspetta 'Eseguito senza errori'
tasto Enter; aspetta 'MODIFICA 1/1'
scrivi 'jf2r4f3r5'; aspetta 'Par 9'
tasto Enter; aspetta 'ESEGUI'
scrivi ':w'; tasto Enter; aspetta "$PROMPT"
cap | grep -q '^9$' || fallisci 'manca la stampa di 9'
tasto Enter; aspetta 'Cosa hai scritto'
tasto Enter; aspetta 'riepilogo'
scrivi 'q'; aspetta '3 lezioni fatte'

# Dojo
scrivi 'd'; aspetta 'MUOVITI SENZA FRECCE'
scrivi 'jf+'; aspetta 'Par 3'
tasto Enter; aspetta 'CAMBIA UNA PAROLA'
scrivi ':q'; tasto Enter; aspetta 'Prossima lezione'
scrivi ':q'; tasto Enter
for _ in $(seq 1 30); do tmux has-session -t "$S" 2>/dev/null || break; sleep 0.1; done
tmux has-session -t "$S" 2>/dev/null && fallisci ':q dalla home non chiude dattilo'
echo 'E2E OK: lezione 1, lezione 2, pacchetto JS, Dojo, :q'
