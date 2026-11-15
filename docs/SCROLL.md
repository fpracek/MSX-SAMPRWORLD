# Scorrimento orizzontale: cosa permette il VDP

Misure in openMSX 22 (`spikes/hmmm/bench.asm`, `bench2.tcl`): copia HMMM a schermo intero (256x192, 24 KB)

| Condizione | Tempo per copia |
|---|---|
| display acceso | ~115 ms |
| sprite hardware disattivati (R#8 SPD) | ~82 ms |

(il contatore JIFFY da' valori falsi con gli interrupt disabilitati: misurato con `after time` sul tempo emulato.)

Conseguenza: sul **V9938 (MSX2 puro) non esiste scorrimento fluido a pixel a 50/60 Hz**. Il registro R#18 sposta
solo l'immagine nel bordo e non e' uno scroll; R#26/R#27 (scroll orizzontale vero) esistono solo sul V9958 (MSX2+/turbo R).

## Soluzione attuale (MSX2 puro): passi da 8 px (16 px per recuperare)
- Doppio buffer: pagine 0/1 mostrano la mappa, la pagina 2 contiene il tileset (y = 512..).
- Camera: l'eroe resta libero nella fascia x 80..127 dello schermo. Oltre 128 parte un passo da **8 px**; oltre 176 (a destra) o
  sotto 48 (a sinistra) il passo diventa da **16 px** per recuperare.
- Passo = HMMM **asincrona** dell'area di gioco dalla pagina visibile a quella nascosta, spostata di |d| px; poi si disegnano
  le colonne scoperte e al vblank si scambia la pagina (R#2) aggiornando lo sprite nello stesso vblank.
  Fisica, nemici e sprite restano a 60 Hz.
- Misure (openMSX, bot sul livello 1): un passo dura 10 frame (copia ~7 frame + strisce + scambio), quindi 8 px = 0,8 px/frame
  e 16 px = 1,6 px/frame; l'eroe corre a 1,5 px/frame. Con passi da 8 la camera non sta dietro a una corsa continua: l'eroe
  scivola verso destra fino a x=176 e da li' i passi diventano da 16 (misurato: eroe tra x=64 e x=196).
- Cronologia: 128 px a scatti (scartato: disorienta) -> 16 px (a scatti) -> 8/16 px adattivo.
- Limite fisico: la copia a schermo intero costa ~100 ms sul V9938; passi da 8 px a 90 px/s richiederebbero ~88 ms per passo.
- Le celle raccolte (monete) si aggiornano su entrambe le pagine; la barra di stato si copia sulla pagina 1.

## Possibile evoluzione
Rilevare il V9958 (ID nel registro di stato S#1) e usare lo scroll fluido a pixel con R#26/R#27 come nel motore
di Black Tiger (`blacktiger-scroll-engine`), lasciando lo scorrimento a pagine come ripiego sul V9938.
