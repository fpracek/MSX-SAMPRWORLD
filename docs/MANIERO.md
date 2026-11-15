# Arte de "Il Maniero" in SamPr World

Sorgente: https://github.com/nicolabrogelli/MSXIlManiero (V9990, MSXgl). Qui si usa solo la grafica, convertita per
SCREEN 5 dal programma `tools/gen_maniero.py` (ingressi in `assets/maniero/src/`, uscite in `assets/maniero/`).

## Come si usa
```
python tools/gen_maniero.py                          # palette automatica
python tools/gen_maniero.py --palette assets/maniero/palette.json   # palette corretta a mano
```
`palette.json` contiene i 16 colori (r,g,b da 0 a 7); l'indice 0 e' il cielo (trasparente), l'indice 1 il contorno.
`tiles.json` si compila a mano con `name` e `class` di ogni tile (guardare `tiles_labeled.png`); le modifiche
sopravvivono a una nuova esecuzione. `preview.png` confronta originale e convertito.

## Risultati
- **Palette:** i 50 colori originali (41 a 9 bit) diventano 16: cielo, contorno e 14 scelti con k-means pesato.
  Il risultato e' fedele (vedi `preview.png`); il muro scuro vira leggermente al blu: ritoccabile con `--palette`.
- **Tile:** 82 blocchi 16x16 unici (6 righe da 16) dalla tavola `castle-tileset.png`. Gli oggetti piu' grandi (porte,
  stendardi, tavoli) sono gia' divisi in blocchi 16x16 e si compongono come PORTT/PORTB.
- **Sprite:** 84 frame 16x16. In 71 frame ci sono 5 colori in una riga, quindi la scomposizione a 4 layer degli sprite
  hardware non basta: servono gli sprite software (`docs/SWSPRITES.md`, V9958). Su V9938 resterebbero silhouette semplici.

## Integrazione nel gioco (stato)
- `tools/gen_tiles.py` aggiunge i tile del Maniero ai 53 legacy (119 in tutto): quelli con `replaces` in `tiles.json`
  prendono il posto del tile legacy omonimo (stessi id, il codice non cambia: mattoni, pietra, terra, cassa, moneta,
  chiave, portone, portale, scala, arazzo, parete), gli altri si accodano come `T_Mnn` con nome e classe.
- La palette del gioco e' quella del Maniero, con gli slot assegnati in modo da restare vicini ai vecchi ruoli (15 = bianco,
  12 = rosso, 11 = oro...): testo, HUD e sprite hardware dell'eroe restano leggibili. I tile legacy non sostituiti
  (spuntoni, lava, acqua, molla...) hanno i colori riadattati e vanno ridisegnati.
- Il motore regge fino a 144 tile (`trow_tab` in `editor.asm`, dati in 3 segmenti ROM).
- Livelli: gli id dei tile arrivano a 127 (RLE a 7 bit, `docs/LEVEL.md`); le proprieta' dei nemici viaggiano nel blob.

## Cosa manca
1. Eroe e nemici del Maniero come sprite software (`tools/gen_swsprites.py` accetta oggi solo i frame di `gen_sprites.py`).
2. Ridisegnare con la nuova palette i tile funzionali che l'arte non ha (molla, spuntoni, acqua, lava, checkpoint, blocchi).
3. Ricostruire i 10 livelli della campagna con i nuovi blocchi (`tools/make_levels.py` usa ancora i tile legacy).
4. Le 8 IA complete: oggi pattuglia, dormiglione, inseguitore e pauroso (goblin); il pipistrello usa raggio e vita.
