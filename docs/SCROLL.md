# Scorrimento orizzontale: cosa permette il VDP

Misure in openMSX 22 (`spikes/hmmm/bench.asm`, `bench2.tcl`): copia HMMM a schermo intero (256x192, 24 KB)

| Condizione | Tempo per copia |
|---|---|
| display acceso | ~115 ms |
| sprite hardware disattivati (R#8 SPD) | ~82 ms |

(il contatore JIFFY da' valori falsi con gli interrupt disabilitati: misurato con `after time` sul tempo emulato.)

Conseguenza: sul **V9938 (MSX2 puro) non esiste scorrimento fluido a pixel a 50/60 Hz**. Il registro R#18 sposta
solo l'immagine nel bordo e non e' uno scroll; R#26/R#27 (scroll orizzontale vero) esistono solo sul V9958 (MSX2+/turbo R).

## Soluzione attuale (MSX2 puro): scorrimento a pagine
- Doppio buffer: pagine 0/1 mostrano la mappa, la pagina 2 contiene il tileset (y = 512..).
- Quando l'eroe supera x=176 (o scende sotto 48) sullo schermo, la nuova vista (128 px piu' avanti o indietro) si
  disegna nella pagina nascosta **una colonna per frame** (16 frame circa) mentre fisica e sprite continuano a 60 Hz;
  poi, al vblank, si scambia la pagina (R#2) e si aggiorna lo sprite nello stesso vblank. Nessuna pausa.
- Le celle raccolte (monete) si aggiornano su entrambe le pagine; la barra di stato si copia sulla pagina 1.

## Possibile evoluzione
Rilevare il V9958 (ID nel registro di stato S#1) e usare lo scroll fluido a pixel con R#26/R#27 come nel motore
di Black Tiger (`blacktiger-scroll-engine`), lasciando lo scorrimento a pagine come ripiego sul V9938.
