#!/usr/bin/env bash
# Prepara file .dattilo ostili in $1, come farebbe un mittente malintenzionato.
set -e
out="$1"; mkdir -p "$out"
J='{"id":"%s","titolo":"%s","versione":"1.0.0","linguaggio":"javascript","esecuzione":%s}'
NODE='{"tipo":"comando","comando":["node","{file}"]}'
LEZ='---
titolo: Lezione
file: %s
---

## Batti
```js
%s
```
'
pacchetto() { # file id esecuzione file_lezione codice [righe in più...]
  local f="$1" id="$2" es="$3" fl="$4" code="$5"; shift 5
  { echo 'dattilo-pacchetto 1'; echo "id: $id"; echo 'versione: 1.0.0'
    echo '--- file: pacchetto.json'; printf "$J\n" "$id" "$id" "$es"
    echo "--- file: lezioni/01-a.md"; printf -- "$LEZ" "$fl" "$code"
    for extra in "$@"; do printf '%s\n' "$extra"; done; } > "$out/$f"
}
pacchetto 01-percorso-indietro.dattilo prova1 "$NODE" main.js 'console.log(1)' '--- file: ../../.bashrc' 'echo PWNED > /tmp/PWNED'
pacchetto 02-percorso-assoluto.dattilo prova2 "$NODE" main.js 'console.log(1)' '--- file: /home/utente/.bashrc' 'echo PWNED'
pacchetto 03-estensione-sh.dattilo prova3 "$NODE" main.js 'console.log(1)' '--- file: file/attacco.sh' 'touch /tmp/PWNED'
pacchetto 04-file-lua.dattilo prova4 "$NODE" main.js 'console.log(1)' '--- file: lua/dattilo/init.lua' 'os.execute("touch /tmp/PWNED")'
pacchetto 05-comando-bash.dattilo prova5 '{"tipo":"comando","comando":["bash","-c","touch /tmp/PWNED"]}' main.js 'x'
pacchetto 06-node-e.dattilo prova6 '{"tipo":"comando","comando":["node","-e","require(\"fs\").writeFileSync(\"/tmp/PWNED\",\"x\")","{file}"]}' main.js 'x'
pacchetto 07-plugin-cc.dattilo prova7 '{"tipo":"compila","compila":["cc","-fplugin=/tmp/x.so","{file}"],"esegui":["./{nome}"]}' main.c 'int main(void){return 0;}'
pacchetto 08-nome-file-indietro.dattilo prova8 "$NODE" '../../.bashrc' 'console.log(1)'
pacchetto 09-id-indietro.dattilo '../evil' "$NODE" main.js 'console.log(1)'
pacchetto 10-sostituisce-corso-c.dattilo corso-c-antirez "$NODE" main.js 'console.log(1)'
pacchetto 11-soluzione-shell.dattilo prova11 "$NODE" main.js 'console.log(1)' '## Modifica' 'consegna: x' 'aiuto: x' 'par: 1' 'soluzione: :!touch /tmp/PWNED<CR>' '```js' 'console.log(2)' '```'
pacchetto 12-soluzione-g-call.dattilo prova12 "$NODE" main.js 'console.log(1)' '## Modifica' 'consegna: x' 'aiuto: x' 'par: 1' 'soluzione: :g/./call system("touch /tmp/PWNED")<CR>' '```js' 'console.log(2)' '```'
{ pacchetto 13-troppo-grande.dattilo prova13 "$NODE" main.js 'console.log(1)'; } && { echo '--- file: file/grande.txt'; head -c 6000000 /dev/zero | tr '\0' 'a'; echo; } >> "$out/13-troppo-grande.dattilo"
printf 'ciao, non sono un pacchetto\n' > "$out/14-non-dattilo.dattilo"
# Pacchetto valido ma ostile: il codice della lezione prova a scrivere nella home e a usare la rete.
pacchetto 15-valido-ma-ostile.dattilo ostile "$NODE" main.js "const fs = require('fs'); try { fs.appendFileSync(require('os').homedir() + '/.bashrc', 'PWNED'); console.log('home: scritta'); } catch (e) { console.log('home: bloccata'); } require('http').get('http://andrea:8000/', () => { console.log('rete: aperta'); process.exit(0); }).on('error', () => { console.log('rete: chiusa'); process.exit(0); });"
# Valido con fine riga Windows: deve entrare.
pacchetto 16-crlf-valido.dattilo crlf "$NODE" main.js 'console.log("crlf ok")'
sed -i 's/$/\r/' "$out/16-crlf-valido.dattilo"
ls "$out"
