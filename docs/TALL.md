# Livelli alti (scorrimento verticale) e HUD

Nella ROM di Il Maniero a cui giocano Fausto e Nicola (`ilmaniero.rom`, V9990) i livelli sono **64x64 tile da 8 px = 512x512 px**
con scorrimento verticale; il repository pubblicato e' una versione piu' vecchia (64x25). I livelli della campagna di SamPr World
sono quelli della ROM: `assets/maniero/rom/` (mappe estratte), `tools/import_rom_levels.py` (griglia 32x32 di celle 16x16),
`tools/make_tall.py` (blob + anteprime), campagna di 4 livelli (stage 1-4 della ROM; il 2 usa la mappa del 1 con altri nemici).

## Finestra verticale (`editor/tall.asm`, segmento 3)
- Il livello intero sta in RAM (`BIG`, 0xD800: 32 righe x 64 colonne); il motore lavora su `MAP`, una **finestra di 12 righe**
  (11 visibili) copiata da BIG a partire dalla riga `p_cr`. Fisica, collisioni, nemici, camera orizzontale non cambiano.
- Quando un eroe sale sopra y=80 (o scende oltre 144) la finestra scorre di 4 righe (`WSTEP`, `WUP` in tall.asm: l'eroe resta nella meta' bassa dello schermo): `win_save` (MAP -> BIG: le monete
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
- Le fasce (256x8) si disegnano con il font ridefinito (`tools/gen_hudfont.py`) nel master (pagina 3 righe 176-191) e si copiano
  UNA VOLTA nelle tre viste (righe 0-7 e 184-191; gioco nelle righe 8-183: `p_voff`, `p_vh`, `p_vmax`, `p_vr1`, `view_geo_i`).
- **HUD fermo con l'interruzione di linea** (`editor/irq.asm`): lo scorrimento hardware R#26/R#27 vale per tutto lo schermo; la
  ISR (IM 2, vettori a 0xEC00, gestore a 0xEDED, solo IRQ di linea, IE0 spento: il vblank resta a polling) porta lo scroll a 0
  alla riga 8 -> camera, alla riga 184 -> 0 (R#19 = 6 / 183: la ISR parte sul filetto blu, dove lo scroll cambia senza che si veda). Prima le fasce si ricopiavano ruotate della camera a ogni fotogramma
  (2 KB di HMMM, ~20% del tempo durante lo scorrimento). Misura (`t_frames.tcl`, 8 s di corsa): 307 -> 371 fotogrammi.
  Atomicita' sulla porta 0x99: ogni coppia di byte del codice normale sta fra `di` e `call vei` (`vei` riabilita le IRQ solo se
  `irq_on`); `vdp_wait` imposta R#15=2 una volta sola e tiene le IRQ attive durante l'attesa: la ISR (che legge S#1) ripristina R#15 da `vdp_r15`. I frame compilati degli sprite hanno centinaia di coppie non protette:
  la ISR guarda il PC interrotto (`sw_inframe`, opcode ld a,d / adc a,0 / ld d,a / out dopo ld d,a), se e' fra i due out legge S#0
  per azzerare il latch (ricorda il flag di vblank in `isr_vb`, che `sw_vwait` considera visto) e alla fine rimanda E.
  Attiva solo nei livelli alti (`irq_start` in `play_init`, `irq_stop` in `play_end`). Su hardware vero serve il vettore IM 2
  letto dal bus (0xFF o qualunque valore: la tabella di 257 byte e' tutta 0xED).
- Punteggi (BCD): moneta 10, gemma 50, chiave 100, nemico schiacciato 50, livello 1000; il cuore da' una vita (max 5). Tre vite
  per livello; a zero vite game over (menu, punteggi azzerati). HI resta per tutta la sessione.
- Munizioni: caselle vuote (le armi non sono ancora implementate).

## Memoria
La pagina 1 della ROM era piena: il modulo di rete (888 byte, `netpub.asm`) e' ora nel segmento 9 e si copia in RAM all'avvio;
tutto il codice nuovo sta nel segmento 3 con ingressi in `swspr.asm`.
