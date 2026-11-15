# Scorrimento orizzontale: cosa permette il VDP

Misure in openMSX 22 (`spikes/hmmm/bench.asm`, `bench2.tcl`): copia HMMM a schermo intero (256x192, 24 KB)

| Condizione | Tempo per copia |
|---|---|
| display acceso | ~115 ms |
| sprite hardware disattivati (R#8 SPD) | ~82 ms |

(il contatore JIFFY da' valori falsi con gli interrupt disabilitati: misurato con `after time` sul tempo emulato.)

Conseguenza: sul **V9938 (MSX2 puro) non esiste scorrimento fluido a pixel a 50/60 Hz**. Il registro R#18 sposta
solo l'immagine nel bordo e non e' uno scroll; R#26/R#27 (scroll orizzontale vero) esistono solo sul V9958 (MSX2+/turbo R).

## Soluzione attuale (MSX2 puro): passi da 16 px (1 tile)
- Doppio buffer: pagine 0/1 mostrano la mappa, la pagina 2 contiene il tileset (y = 512..).
- Quando l'eroe esce dalla fascia centrale dello schermo (x < 96 o x >= 144), parte un passo: HMMM **asincrona** dell'area
  di gioco dalla pagina visibile a quella nascosta, spostata di 16 px; poi si disegna la colonna di tile scoperta e, al vblank,
  si scambia la pagina (R#2) aggiornando lo sprite nello stesso vblank. Fisica, nemici e sprite continuano a 60 Hz.
- Ritmo: la copia costa ~100 ms, quindi lo sfondo avanza di 16 px circa 7-8 volte al secondo (>= velocita' dell'eroe, 90 px/s):
  l'eroe resta tra x=79 e x=158 sullo schermo (misurato con il bot sul livello 1).
- Prima (versione scartata): salti di 128 px preparati una colonna per frame. Funzionava ma il cambio improvviso di mezzo
  schermo disorientava (feedback di Fausto): i passi piccoli e frequenti fanno comparire il terreno nuovo un tile alla volta.
- Le celle raccolte (monete) si aggiornano su entrambe le pagine; la barra di stato si copia sulla pagina 1.

## Possibile evoluzione
Rilevare il V9958 (ID nel registro di stato S#1) e usare lo scroll fluido a pixel con R#26/R#27 come nel motore
di Black Tiger (`blacktiger-scroll-engine`), lasciando lo scorrimento a pagine come ripiego sul V9938.
