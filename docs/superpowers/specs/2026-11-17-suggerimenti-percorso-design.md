# dattilo: suggerimenti a tre livelli, percorso con blocchi, lezioni più grandi

Progetto del 17/11/2026. Le tre scelte di fondo le ha fatte Andrea nella stessa
giornata (riquadro unico, ogni lezione in fila, più lezioni e più ricche).

## Perché

Andrea usa dattilo per imparare il codice di SmartExploration partendo da
JavaScript. Oggi mentre scrive vede pochi suggerimenti (6-10 per lezione, su righe
sparse) e non capisce sempre cosa sta costruendo. I quattro pacchetti del percorso
compaiono in ordine alfabetico (ATON, JavaScript, SmartExploration, Three.js),
invece che nell'ordine in cui si studiano, e niente impedisce di saltare avanti. Le
lezioni gli sembrano piccole.

## Obiettivi

1. **Suggerimenti su tre livelli** mentre si batte il codice:
   - **Riga**: cosa fa la riga su cui si trova il cursore. Ogni riga non vuota ne ha uno.
   - **Blocco**: il gruppo di righe di cui fa parte (una funzione, un gruppo di
     variabili) e a cosa serve.
   - **Fin qui**: la catena dei blocchi (fatti, quello in corso, quelli che mancano)
     e una frase sul quadro generale in quel punto.
   Gli avvisi su Vim (errore, sei in NORMAL, riga non finita, frecce) prendono una
   riga in cima e non cancellano più gli altri livelli.
2. **Le modifiche spiegano il perché**: chiave facoltativa `motivo:`, mostrata nel
   riquadro della modifica.
3. **Percorso**: JavaScript → Three.js → ATON → SmartExploration diventa una sola
   voce della home. I quattro pacchetti sono capitoli in ordine e **ogni lezione si
   apre solo dopo la precedente**, anche passando da un capitolo all'altro. Una
   lezione sbloccata resta sbloccata.
4. **Più lezioni e più ricche**: nuovi argomenti in ogni pacchetto, da 37 a circa
   55-60 lezioni, e quelle esistenti con più modifiche e più note. Versione 0.3.0.
5. Anche le 2 lezioni del corso C ricevono i suggerimenti a tre livelli.

## Non obiettivi

- Nuove lezioni del corso C prese dai video: non sono state chieste.
- Un pannello laterale con il «fin qui» riga per riga: Andrea ha scelto il riquadro
  unico.

## Anti-obiettivi

- Il codice che salta mentre si scrive: il riquadro ha la stessa altezza per tutta
  la lezione.
- Suggerimenti sfasati di una riga rispetto al codice: il verificatore li controlla
  e `dattilo controlla --tip` li stampa accanto al codice.
- Perdere progressi o sblocchi quando si aggiungono lezioni.
- Codice di SmartExploration in repo pubblici (vale come prima).

## Approcci

| Approccio | Esito |
|---|---|
| **Riquadro unico più alto, avvisi su una riga in cima** | **Scelto da Andrea**: sempre visibile, funziona anche su terminali stretti |
| Riquadro con riga e blocco, più un pannello a destra con il fin qui | Scartato: serve un terminale di almeno 120 colonne e un secondo posto da guardare |

| Percorso | Esito |
|---|---|
| **Dedotto da `richiede`**: la catena c'è già nei manifesti; il titolo viene dal campo facoltativo `percorso` del pacchetto finale | **Scelto (Claude)**: nessun file nuovo da scambiare, i pacchetti restano esportabili uno per uno |
| Un pacchetto unico con tutte le lezioni | Scartato: JavaScript non si potrebbe più dare da solo a un collega |
| Un file `percorso.json` a parte | Scartato: non viaggia con i `.dattilo` |

| Blocchi | Esito |
|---|---|
| **Ogni lezione in fila** | **Scelto da Andrea** |
| Solo tra capitoli | Scartato |

## Come funziona

### Formato della lezione

Dentro `## Batti`, accanto a `### Suggerimenti`:

```markdown
### Blocchi
1-9: Dati della sala | Sei const per i dati fissi e tre let per quelli che cambieranno. | Parti dai dati: tutto il resto li userà.
11-16: Calcoli | Aggiorni i contatori e ricavi posti liberi e percentuale. | Hai la scheda della sala; ora la fai lavorare.

### Suggerimenti
1: …
2: …
```

- `A-B: Titolo | cosa fa il blocco | quadro`. Il quadro è facoltativo: è la frase
  del «fin qui» mentre si scrive quel blocco.
- I blocchi vanno in ordine e non si sovrappongono. Le righe vuote tra un blocco e
  l'altro possono restare fuori.
- Nelle modifiche: `motivo: Perché questa modifica serve, in una frase.`

Errori che il formato segnala sempre, anche all'import: un suggerimento fuori dal
codice o su una riga vuota, un blocco con intervallo non valido, fuori dal codice,
sovrapposto o fuori ordine.

Controlli in più di `dattilo controlla` (lo strumento degli autori, usato da
`esporta.sh`): ogni riga non vuota di Batti ha un suggerimento ed è dentro un
blocco. I pacchetti ricevuti da altri senza blocchi si importano comunque.

`dattilo controlla <cartella> [lezione]` controlla una sola lezione (nome del file,
con o senza `.md`). `dattilo controlla --tip <cartella> <lezione>` stampa ogni riga
di Batti con il suo blocco e il suo suggerimento.

### Il riquadro

- Durante la lezione (batti, modifica, rompi, esegui) il riquadro ha **8 righe
  interne** se il terminale ha almeno 34 righe, altrimenti 6. Fuori dalle lezioni
  resta di 3 (Dojo).
- Il contenuto è a sezioni con un'etichetta a sinistra (`Riga`, `Blocco`,
  `Fin qui`, `Consegna`, `Aiuto`, `Perché`, `Tasti`) e il testo che va a capo sotto
  di sé.
- Se il testo non ci sta, le sezioni meno importanti si accorciano per prime. Prima
  si accorcia il quadro, poi il blocco; l'avviso e la riga restano interi.
- Titolo del riquadro in Batti: `RIGA 12 · blocco 2 di 5: Calcoli`, oppure il nome
  dell'avviso (`ERRORE`, `NORMAL`…).
- Il blocco corrente è quello che contiene il cursore. Su una riga vuota tra due
  blocchi vale il blocco successivo. Un blocco è «fatto» quando tutte le sue righe
  coincidono con il bersaglio.
- Una lezione senza blocchi mostra Riga e un Fin qui con «riga N di M».

### Percorso

- `pacchetti.percorsi()`: tra i pacchetti installati, quelli che nessun altro
  richiede e che hanno un `richiede` non vuoto sono la fine di un percorso. Il
  percorso è l'ordine topologico della loro chiusura (prima le dipendenze, nell'ordine
  in cui sono scritte). Un pacchetto richiesto ma non installato è un capitolo
  «mancante», e le lezioni dopo restano bloccate.
- Titolo: il campo facoltativo `percorso` del manifesto finale
  (`"percorso": "Percorso SmartExploration"`). Senza il campo, il titolo è
  «Percorso » seguito dal titolo del pacchetto.
- Sblocco. La lezione *i* della lista piatta è aperta se:
  - è la prima;
  - oppure è completata;
  - oppure la lezione prima è completata;
  - oppure è in `progressi.sbloccate`.

  Quando si finisce una lezione, la successiva entra in `sbloccate`: così resta
  aperta anche se più avanti si aggiungono lezioni prima di lei.
- Il blocco vale solo nelle schermate (home, percorso, pacchetti): `lezione.apri`
  non lo controlla, così test e `controlla` funzionano come prima.
- Home: una voce per percorso (scorciatoia `‹r›` per il primo) e la «prossima
  lezione del percorso».
- Pacchetti: ordine corso C, poi i pacchetti del percorso nel loro ordine, poi gli
  altri in ordine alfabetico. `Invio` su un pacchetto del percorso apre il percorso
  su quel capitolo.
- Riepilogo di fine lezione: dopo l'ultima lezione di un capitolo, «Prossima» è la
  prima del capitolo dopo. `Invio` dall'elenco riporta al percorso.

### Contenuti (pacchetti 0.3.0)

| Pacchetto | Oggi | Lezioni nuove (indicative) |
|---|---|---|
| javascript | 10 | destructuring e spread; Map e Set; closure e scope; getter, setter e static; array tipati; eventi (EventTarget) |
| threejs | 8 | BufferGeometry; materiali e texture; Matrix4 e matrici del mondo; Box3 e Sphere; Clock e animazioni; traverse e ricerca nel grafo |
| aton | 9 | altri moduli di `~/aton/public/src` non ancora coperti (es. SceneHub, Utils, MatHub, MediaFlow, AudioHub) |
| smartexploration | 10 | altri file di `~/aton/wapps/smartexploration-at` non ancora coperti |

In ogni lezione:
- un suggerimento per ogni riga non vuota;
- blocchi con quadro;
- `motivo` in ogni modifica;
- 4-6 modifiche;
- 20-30 note di spiegazione;
- Batti di 50-100 righe.

Le lezioni esistenti si allungano senza cambiare tema. I file si rinumerano
liberamente: oggi l'unico progresso salvato è `corso-c-antirez/01-hello`.

## Lasciato a chi costruisce

- I testi esatti dei suggerimenti e quali argomenti nuovi scegliere, purché stiano
  nell'ordine del percorso.
- Come si spezza il quadro su due righe.
