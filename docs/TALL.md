# Livelli alti (scorrimento verticale) e HUD

Nella ROM di Il Maniero a cui giocano Fausto e Nicola (`ilmaniero.rom`, V9990) i livelli sono **64x64 tile da 8 px = 512x512 px**
con scorrimento verticale; il repository pubblicato e' una versione piu' vecchia (64x25). I livelli della campagna di SamPr World
sono quelli della ROM: `assets/maniero/rom/` (mappe estratte), `tools/import_rom_levels.py` (griglia 32x32 di celle 16x16),
`tools/make_tall.py` (blob + anteprime), campagna di 4 livelli (stage 1-4 della ROM; il 2 usa la mappa del 1 con altri nemici).

## Finestra verticale (`editor/tall.asm`, segmento 3)
- Il livello intero sta in RAM (`BIG`, 0xD800: 32 righe x 64 colonne); il motore lavora su `MAP`, una **finestra di 12 righe**
  (11 visibili) copiata da BIG a partire dalla riga `p_cr`. Fisica, collisioni, nemici, camera orizzontale non cambiano.
- Quando un eroe supera 32 px dal bordo alto (o 144 dal basso) la finestra scorre di 6 righe: `win_save` (MAP -> BIG: le monete
  prese restano prese; i marcatori dei nemici restano in BIG), `win_load`, ribasamento delle y (eroi, checkpoint, nemici nelle
  righe in comune), nemici delle righe nuove creati da BIG, ridisegno completo (`sw_fill`). Lo scorrimento e' "a scatti"
  (non fluido come nel V9990): costo di qualche fotogramma.
- **Due giocatori**: la finestra scorre solo se entrambi restano visibili; se uno sta salendo e l'altro e' troppo lontano, il
  primo e' bloccato al bordo alto (stessa regola della camera orizzontale). Chi cade oltre il bordo basso muore come al solito.
- Il blob del livello ha `h = 32` (intestazione) e la mappa RLE di 64x32 tile; `blob_decode` lo manda in BIG (`p_tall = 1`).
  Se il livello contiene una chiave l'uscita funziona solo a chiave raccolta (`p_needk`).
- Solo V9958 (sprite software). Sul V9938 il menu campagna avvisa che serve un MSX2+.

## HUD "da sala giochi" (`editor/hud.asm`, segmento 3)
- Schermo da 192 righe: **8 righe di HUD in alto**, 176 di gioco (11 righe di tile) e 8 di HUD in basso (come Il Maniero, fuori
  dall'area di gioco): `1UP 000000 HI 000500 2UP 000000` / `LIFE ♥♥♥ AMMO □□□□□ KEY ⚷00`.
- Le fasce (256x8) si disegnano con il font ridefinito (`tools/gen_hudfont.py`, schemi di colore: etichette arancio/giallo, HI
  rosso, 2UP azzurro, cifre bianche) nel master (pagina 3 righe 176-191) e a ogni fotogramma si copiano (HMMM) nella vista D
  **ruotate della camera**, cosi' lo scorrimento orizzontale hardware le lascia ferme. Gioco nelle righe 8-183 di ogni vista
  (`p_voff`, `p_vh`, `p_vmax`, `p_vr1` impostati da `view_geo_i`).
- Punteggi (BCD): moneta 10, gemma 50, chiave 100, nemico schiacciato 50, livello 1000; il cuore da' una vita (max 5). Tre vite
  per livello; a zero vite game over (menu, punteggi azzerati). HI resta per tutta la sessione.
- Munizioni: caselle vuote (le armi non sono ancora implementate).

## Memoria
La pagina 1 della ROM era piena: il modulo di rete (888 byte, `netpub.asm`) e' ora nel segmento 9 e si copia in RAM all'avvio;
tutto il codice nuovo sta nel segmento 3 con ingressi in `swspr.asm`.
