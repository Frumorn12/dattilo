---
titolo: "La somma"
breve: "somma"
etichetta: "Rifallo tu"
file: "somma.js"
fonte: "src/conti.js, righe 3-6"
tempo: "circa 1 minuto"
---

## Batti
```js
function somma(a, b) {
    if (typeof a !== "number") return 0;
    return a + b;
}
```

### Blocchi
1-4: La funzione | Prende due numeri e li somma. | La riga 2 è quella nuova di Claude.

### Suggerimenti
2: Riga cambiata da Claude: se a non è un numero, restituisce 0.

## Spiegazione
2: Il controllo nuovo. | typeof dice il tipo di un valore.
