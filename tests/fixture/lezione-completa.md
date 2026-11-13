---
titolo: Introduzione al C e primo Hello World
breve: Hello World
file: hello.c
mosse: [i, Esc, ":w", "ci\"", gg]
concetti: [main, printf, "return 0"]
tempo: circa 4 minuti
etichetta: L1
video: HjXBXBgfKyk
durata: 22:00
video_da: 05:26
fonte: hello.c
---

## Briefing
antirez scrive Hello World
e lo compila con cc.

## Passi
- Batti il programma | il codice è in grigio
- Cambialo | Hello World diventa Ciao mondo

## Batti
```c
#include <stdio.h>

int main(void) {
    printf("Hello World\n");
    return 0;
}
```

### Suggerimenti
4: printf stampa.
5: return 0 vuol dire tutto bene.

## Uscita
```text
Hello World
```

## Modifica: Modifica 1/2
consegna: Fallo parlare italiano.
aiuto: ‹3j› scende di tre righe.
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

## Modifica
consegna: Ritorna uno.
aiuto: ‹r1›.
pos: 5:12
par: 2
soluzione: r1
mostra: r1
```c
#include <stdio.h>

int main(void) {
    printf("Ciao mondo\n");
    return 1;
}
```

## Rompi
consegna: Togli la riga dell'#include e salva con ‹:w›.
attesa: errore
cerca: implicit declaration
dopo: ‹u› e ‹:w›.
```c

int main(void) {
    printf("Ciao mondo\n");
    return 1;
}
```

## Spiegazione
1: Il preprocessore | incolla stdio.h
3: Il programma parte da main.

### Momenti
- 05:26 scrive il primo Hello World
- 10:40 con -O2 printf diventa puts

### Trappola
Senza include niente printf.

### Prova
cc -O2 -S hello.c
