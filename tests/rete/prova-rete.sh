#!/usr/bin/env bash
# Prova di scambio su una rete finta: "andrea" esporta e serve i pacchetti, "collega" li scarica e li importa.
# Poi un mittente ostile manda file .dattilo costruiti per fare danni. Nessun accesso a internet.
set -u
RADICE="$(cd "$(dirname "$0")/../.." && pwd)"
PACCHETTI="${PACCHETTI:-$HOME/code/dattilo-pacchetti}"
RETE=dattilo-rete-finta
SICUREZZA=(--security-opt seccomp=unconfined --security-opt apparmor=unconfined)
esito=0
ok() { echo "  ✓ $*"; }
ko() { echo "  ✗ $*"; esito=1; }
pulisci() { docker rm -f dattilo-andrea dattilo-collega >/dev/null 2>&1; docker network rm "$RETE" >/dev/null 2>&1; }
trap pulisci EXIT
pulisci
docker network create --internal "$RETE" >/dev/null
docker run -d --name dattilo-andrea --hostname andrea --network "$RETE" --network-alias andrea "${SICUREZZA[@]}" \
  -v "$RADICE":/opt/dattilo:ro -v "$PACCHETTI":/opt/pacchetti:ro dattilo-prova sleep infinity >/dev/null
docker run -d --name dattilo-collega --hostname collega --network "$RETE" "${SICUREZZA[@]}" \
  -v "$RADICE":/opt/dattilo:ro dattilo-prova sleep infinity >/dev/null
A() { docker exec dattilo-andrea bash -lc "$1"; }
C() { docker exec dattilo-collega bash -lc "$1"; }
D=/opt/dattilo/bin/dattilo

echo "1. Rete finta"
C "curl -s -m 4 -o /dev/null https://example.com" && ko "collega raggiunge internet" || ok "collega non raggiunge internet"
A "curl -s -m 4 -o /dev/null https://example.com" && ko "andrea raggiunge internet" || ok "andrea non raggiunge internet"
C "$D controlla /opt/dattilo/pacchetti/corso-c-antirez >/dev/null" && ok "dattilo gira nel collega" || ko "dattilo non gira nel collega"
C "nvim --clean --headless -l /dev/stdin <<< 'package.path=\"/opt/dattilo/lua/?.lua;\"..package.path; io.stdout:write(tostring(require(\"dattilo.compila\").sandbox()))'" | grep -q true && ok "sandbox bwrap attiva nel collega" || echo "  · sandbox bwrap non disponibile nel collega (si prova senza)"

echo "2. Andrea esporta e serve i pacchetti"
A "mkdir -p ~/dist && for p in javascript threejs aton smartexploration; do $D esporta /opt/pacchetti/\$p ~/dist >/dev/null; done; ls ~/dist | wc -l" | grep -q '^4$' && ok "4 file .dattilo esportati" || ko "esportazione"
docker exec -d dattilo-andrea bash -lc "cd ~/dist && python -m http.server 8000 >/dev/null 2>&1"
sleep 1.5

echo "3. Il collega scarica e importa"
for p in javascript threejs aton smartexploration; do
  C "cd ~ && curl -s -f -O http://andrea:8000/$p-0.1.0.dattilo && $D importa $p-0.1.0.dattilo --si >/dev/null" && ok "importato $p" || ko "importazione di $p"
done
C "$D pacchetti" | sed 's/^/    /'
n=$(C "$D pacchetti | grep -c 'lezioni'"); [ "$n" = 5 ] && ok "5 pacchetti installati" || ko "pacchetti installati: $n"
C "for p in javascript threejs aton smartexploration; do $D controlla ~/.local/share/dattilo/pacchetti/\$p | tail -1; done" | grep -c 'Tutto a posto' | grep -q '^4$' && ok "i pacchetti importati passano il verificatore" || ko "verificatore sui pacchetti importati"
C "nvim --clean --headless -l /opt/dattilo/tests/rete/fumo.lua" | sed 's/^/    /'
C "nvim --clean --headless -l /opt/dattilo/tests/rete/fumo.lua" | grep -q FERMO && ko "una lezione non parte" || ok "la prima lezione di ogni pacchetto parte e gira"

echo "4. Mittente ostile"
A "bash /opt/dattilo/tests/rete/attacchi.sh ~/dist/attacchi >/dev/null"
C "md5sum ~/.bashrc > ~/.bashrc.md5"
for f in $(A "ls ~/dist/attacchi"); do
  C "curl -s -f -o ~/$f http://andrea:8000/attacchi/$f"
  out=$(C "$D importa ~/$f --si 2>&1"); rc=$?
  case "$f" in
    15-*|16-*) [ $rc = 0 ] && ok "$f accettato (atteso)" || ko "$f rifiutato: $out" ;;
    *) [ $rc != 0 ] && ok "$f rifiutato: $(echo "$out" | tail -1 | sed 's/^ *//')" || ko "$f ACCETTATO" ;;
  esac
done
C "test ! -e /tmp/PWNED" && ok "nessun /tmp/PWNED" || ko "/tmp/PWNED esiste"
C "md5sum -c --quiet ~/.bashrc.md5" && ok "~/.bashrc intatto dopo gli import" || ko "~/.bashrc modificato"
C "ls ~/.local/share/dattilo/pacchetti" | tr '\n' ' ' | sed 's/^/    installati: /'; echo
C "test ! -e ~/.local/share/dattilo/pacchetti/corso-c-antirez && test ! -e ~/.local/share/evil" && ok "nessun pacchetto fuori posto" || ko "pacchetto fuori posto"

echo "5. Pacchetto valido ma ostile: il suo codice gira nella sandbox"
risultato=$(C "nvim --clean --headless -l /opt/dattilo/tests/rete/esegui-ostile.lua")
echo "$risultato" | sed 's/^/    /'
if C "nvim --clean --headless -l /dev/stdin <<< 'package.path=\"/opt/dattilo/lua/?.lua;\"..package.path; io.stdout:write(tostring(require(\"dattilo.compila\").sandbox()))'" | grep -q true; then
  echo "$risultato" | grep -q 'home: bloccata\|home: scritta' && C "md5sum -c --quiet ~/.bashrc.md5" && ok "la home vera resta intatta" || ko "il codice ha scritto nella home vera"
  echo "$risultato" | grep -q 'rete: chiusa' && ok "il codice non vede la rete" || ko "il codice vede la rete"
else
  echo "  · senza sandbox il codice ostile gira normalmente: è il caso descritto nel README"
fi
echo
[ $esito = 0 ] && echo "PROVA DI RETE OK" || echo "PROVA DI RETE: CI SONO PROBLEMI"
exit $esito
