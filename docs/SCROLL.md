# Scorrimento: MSX2+ (V9958) hardware, MSX2 (V9938) a passi

**Bersaglio del gioco: MSX2+ (V9958).** Il VDP si riconosce all'avvio (registro di stato S#1, bit 5-1: 0 = V9938, 2 = V9958).

## MSX2+ (V9958): scroll hardware fluido (`editor/ring.asm`)
- R#27 (0-7 px) e R#26 (blocchi da 8 px) spostano la visuale: `R#27 = (8 - cam%8) % 8`, `R#26 = ((cam%256) + 7) / 8`.
- La pagina 0 e' un **anello di 256 px**: la colonna di mondo `w` sta alla x `w mod 256`. A ogni frame, subito dopo il vblank,
  si aggiornano i registri e si disegnano solo le colonne che entrano (fino a 6-7 px, tile per tile dalla cache in pagina 2).
  Nessuna copia a schermo intero, nessuna pagina da scambiare: scorrimento a pixel a 60 Hz.
- R#25 MSK nasconde gli 8 px a sinistra: li' il fine-scroll mostra la colonna di ritorno dell'anello e li' avvengono le
  sostituzioni quando si scorre verso destra (verso sinistra le colonne si sostituiscono a destra, davanti al raster).
- La barra di stato scorrerebbe con la mappa: in prova lo schermo e' di 192 righe e il punteggio e' fatto di **sprite**
  (icona + due cifre per monete, chiavi, nemici). Sprite: eroe piani 0-3, 3 slot nemici dinamici piani 4-9, HUD piani 10-15.
- **Trappola scoperta**: i bit 1-0 di R#5 devono valere 1 (BIOS: 0xEF). Con 0xEC le tabelle colore dei piani 8-31 coincidono
  con quelle dei piani 0-7 (verificato scrivendo i colori in VRAM).
- Camera: obiettivo x-112, zona morta +-12 px, passo 1-6 px/frame; l'eroe resta tra x=103 e x=143 dello schermo (bot).

## MSX2 (V9938): passi con copia (fallback, `editor/scroll.asm`)
Misure (openMSX): la copia HMMM a schermo intero (256x192) costa ~115 ms (82 ms con sprite spenti): lo scroll a pixel non e'
possibile. Il fallback usa passi da 8 px (16 px se l'eroe e' lontano dal centro) con HMMM asincrona e doppio buffer sulle pagine
0/1 (il tileset sta in pagina 2). Un passo dura ~10 frame: 8 px = 0,8 px/frame, 16 px = 1,6 px/frame (l'eroe corre a 1,5).
Cronologia: salti da 128 px (disorientanti) -> 16 px (a scatti) -> 8/16 px adattivo -> hardware V9958.

