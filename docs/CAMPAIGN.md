# La campagna (4 livelli alti, dalla ROM di Il Maniero)

I livelli fissi stanno nel segmento 6 della ROM (`assets/campaign.bin`) e si generano con `python tools/make_levels.py`, che usa
`tools/make_tall.py` su `tools/levels_rom.json`. Quel file viene da `python tools/import_rom_levels.py`: legge le mappe estratte
dalla ROM (`assets/maniero/rom/rom_levelN.bin`), le ridisegna con `MANIERO.png` e riconosce i tile 16x16 per confronto con il
tileset ridisegnato (`assets/maniero/tiles.png`); monete, chiave, cuore, scale, forzieri, botti e porte si cercano per confronto
di modello. (I vecchi livelli 64x25 del repository pubblico restano in `tools/import_maniero_levels.py`, `OLDLEVELS=1`.)

## Fedelta' all'originale
- **Dalla ROM giocabile di Fausto e Nicola** (`ilmaniero.rom`), non dal repository pubblicato (piu' vecchio, livelli alti una sola
  schermata e senza scorrimento verticale). I livelli sono 64x64 tile da 8 px (512x512 px): qui 32x32 celle da 16 px con
  **scorrimento verticale a finestra** e HUD in alto/in basso (docs/TALL.md). La ROM contiene 3 mappe distinte (0x50000,
  0x5C000, 0x60000; 0x70000 e' una copia della prima): sono i 4 stage della campagna (lo stage 2 ha la mappa del 1).
- I nemici si leggono dalla tabella RAM della ROM (posizione, sprite, IA); le monete, la chiave, le scale sono tile della mappa.
  L'ingresso e' in basso a sinistra, l'uscita e' la porta in alto.
- Le celle da 16 px approssimano la griglia da 8 px dell'originale; dove un elemento cade a mezza cella si sceglie la cella piu'
  vicina (`tools/make_tall.py`, `PATCHES` per i ritocchi a mano).

| # | Livello |
|---|---|
| 1 | tre piani, scale a sinistra e al centro, chiave nella camera a destra |
| 2 | stessa mappa, altri nemici |
| 3 | grande sala a 5 piani con scale ai lati |
| 4 | torre con ripiani |

## Verifiche automatiche (`make_levels.py`)
1. Modello dell'editor (`swreach.asm`): ogni moneta/gemma/chiave e l'uscita sono raggiungibili.
2. Pianificatore (camminata, caduta, salti di buche e gradini, salti con rialzo, scale): esiste un percorso partenza -> chiave
   -> uscita (per i livelli alti: 32 righe).
3. `editor/tests/t_campbot.tcl` (`TALL=1 LEVEL=N`): un bot segue il percorso nella campagna vera (menu) con salti automatici.
   **Stato**: il livello 4 si completa; i livelli 1-3 non sono ancora completati dal bot (si incastra in punti stretti), il
   pianificatore li dichiara raggiungibili.
4. `t_tall.tcl`, `t_tall2.tcl` (due giocatori), `t_tall3.tcl` (vite, game over): scorrimento verticale, HUD, punteggi.
