---
titolo: "La tabella dei sosia"
breve: "codicePulito"
etichetta: "Rifallo tu"
file: "regole.js"
fonte: "server/src/logica/regole.js, righe 84-88"
tempo: "circa 1 minuto"
---

## Briefing
codicePulito prende il codice amico scritto dalla persona e lo riduce alla forma che si salva. Claude ci ha aggiunto la correzione dei sosia: O, 0 e U diventano C e V prima del controllo.

## Batti
```js
export function codicePulito(t) {
  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/[O0U]/g, (x) => SIMILI[x]);
  if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
  return `${c.slice(0, 4)}-${c.slice(4)}`;
}
```

### Blocchi
1-2: Pulizia | Mette tutto maiuscolo, toglie quello che non è lettera o cifra e corregge i sosia. | È qui la riga nuova di Claude.
3-5: Controllo e forma | Rifiuta i codici sbagliati e mette il trattino in mezzo. | Quello che c'era già.

### Suggerimenti
2: Riga cambiata da Claude. L'ultimo .replace cambia ogni O, 0 e U con il suo sosia, preso dalla tabella SIMILI.
3: Un codice vero ha 8 simboli dell'alfabeto: se no, null.

## Modifica: Rifai la modifica di Claude
consegna: Alla riga 2, dopo il primo .replace, aggiungi il .replace che corregge i sosia.
aiuto: Vai alla riga 2, mettiti sul punto e virgola finale, entra in scrittura subito prima e scrivi il pezzo nuovo; poi esci dalla scrittura.
motivo: Nel carattere a pixel la C sembra una O: il secondo .replace corregge i sosia prima del controllo.
pos: 1:1
par: 41
soluzione: 2G$i.replace(/[O0U]/g, (x) => SIMILI[x])<Esc>
```js partenza
export function codicePulito(t) {
  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");
  if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
  return `${c.slice(0, 4)}-${c.slice(4)}`;
}
```
```js
export function codicePulito(t) {
  const c = String(t ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/[O0U]/g, (x) => SIMILI[x]);
  if (c.length !== 8 || [...c].some((x) => !ALFABETO.includes(x))) return null;
  return `${c.slice(0, 4)}-${c.slice(4)}`;
}
```

### Tasti
- 2G | va alla riga 2
- $ | va in fondo alla riga, sul punto e virgola
- i | entra in scrittura subito prima del punto e virgola
- .replace(/[O0U]/g, (x) => SIMILI[x]) | scrive il pezzo nuovo
- <Esc> | esce dalla scrittura

## Spiegazione
2: Il .replace nuovo usa la tabella dei sosia. | (x) => SIMILI[x] è una funzione freccia.
