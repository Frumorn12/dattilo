---
titolo: Introduzione al C e primo Hello World
breve: Hello World
etichetta: L1
file: hello.c
video: HjXBXBgfKyk
durata: 22:00
video_da: 05:26
mosse: [i, Esc, ":w", 3j, "ci\"", gg, dd, u]
concetti: ["#include", main, printf, "\\n", "return 0", "cc -Wall"]
tempo: circa 4 minuti
---

## Briefing
Nel video antirez scrive Hello World, lo compila con cc, guarda l'assembly con -S e scopre che con -O2 il compilatore cambia printf in puts.

## Passi
- Batti il programma | il codice è in grigio, lo copri scrivendo
- Cambialo | Hello World diventa Ciao mondo
- Rompilo | togli l'#include e leggi l'errore di gcc
- Capisci | riga per riga, con i minuti del video

## Batti
```c
#include <stdio.h>

int main(void) {
    printf("Hello World\n");
    return 0;
}
```

### Blocchi
1-1: Le inclusioni | Prima di tutto si dice al compilatore quali librerie servono: qui stdio.h, quella dell'input e dell'output. | Un programma C inizia dalle dichiarazioni: senza, il compilatore non conosce printf.
3-6: La funzione main | Il corpo del programma: stampa una riga e restituisce 0 al sistema. | Hai incluso stdio.h; ora scrivi il codice che gira davvero.

### Suggerimenti
1: #include incolla qui il file stdio.h, dove è dichiarata printf. I < > vogliono dire «cercalo tra i file di sistema».
3: main è la funzione da cui parte ogni programma C: restituisce un int e, con void, non prende argomenti. La graffa apre il corpo.
4: printf stampa la stringa tra virgolette. \n va a capo: printf non lo aggiunge da sola. Dopo ‹Invio› il rientro lo mette dattilo.
5: return 0 chiude main e dice al sistema «tutto bene». Il ; chiude ogni istruzione.
6: La graffa chiude il corpo di main: il programma finisce qui.

## Uscita
```text
Hello World
```

## Modifica: Modifica 1/2
consegna: Fallo parlare italiano: Hello World diventa Ciao mondo.
aiuto: ‹3j› scende di tre righe, ‹ci"› cancella dentro le virgolette e ti mette in INSERT.
motivo: Il testo tra virgolette è un dato come un altro: cambi solo quello e il programma resta identico.
par: 18
soluzione: 3jci"Ciao mondo\n<Esc>
mostra: 3j · ci" · Ciao mondo\n · Esc
```c
#include <stdio.h>

int main(void) {
    printf("Ciao mondo\n");
    return 0;
}
```

## Rompi: Modifica 2/2
consegna: Ora rompilo apposta: ‹gg› va in cima, ‹dd› cancella la riga dell'#include. Poi ‹:w› e leggi cosa dice gcc.
attesa: errore
cerca: implicit declaration
dopo: Senza stdio.h il compilatore non sa chi è printf, e dal GCC 14 è un errore. ‹u› annulla la cancellazione, poi ‹:w›.
```c

int main(void) {
    printf("Ciao mondo\n");
    return 0;
}
```

## Spiegazione
1: Il preprocessore incolla qui le dichiarazioni | di stdio.h, tra cui quella di printf.
3: Il programma parte da main. | void: niente argomenti.
4: printf è della libreria standard, non del C. | \n va a capo: printf non lo aggiunge, puts sì.
5: Zero al sistema vuol dire tutto bene. | Provalo con: ./hello; echo $?

### Momenti
- 05:26 scrive il primo Hello World
- 08:34 cc -S hello.c mostra l'assembly: dentro c'è la chiamata a printf
- 10:40 con -O2 il compilatore sostituisce printf con puts e toglie il \n
- 11:43 man 3 printf, perché man printf apre il comando della shell

### Trappola
senza #include il compilatore rifiuta printf. L'hai appena visto.

### Prova
cc -O2 -S hello.c e cerca puts nel file hello.s
