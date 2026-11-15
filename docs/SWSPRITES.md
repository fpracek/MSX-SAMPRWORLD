# Sprite software (V9958) - triplo buffer

Gli sprite hardware dell'MSX2 hanno 8 sprite per riga e un colore per riga per sprite: gli sprite del Maniero (fino a 5
colori per riga) non ci stanno. Su V9958 (MSX2+, turboR) eroe, secondo giocatore e nemici sono quindi **codice Z80
compilato** che scrive in VRAM solo i pixel opachi, come in soccerwl. Sul V9938 restano gli sprite hardware (con
l'arte vecchia): senza scroll orizzontale hardware (`R#26`/`R#27`) il triplo buffer costerebbe 3 copie a schermo intero a ogni passo.
L'HUD resta fatto di sprite hardware (piani 10-15).

## Pagine di VRAM
| pagina | contenuto |
|---|---|
| 0, 1, 2 | tre viste: anello da 256 px scorrevole (righe 0-191); righe libere 192-255 ospitano parte del tileset |
| 3 | master dello sfondo (righe 0-191) + tileset (righe 192-255) |
| 2, riga 192 | copia della mappa durante la prova (0x16000); area di lavoro degli sprite (0x17000) |

## Pipeline (ogni fotogramma f, `swengine.asm`)
1. Si MOSTRA la vista S (R#2 e registri di scroll della sua camera).
2. Le colonne di mondo che entrano si disegnano nel master (tile) e si copiano nella vista D=(S+1)%3 (HMMM).
3. Per ogni oggetto (0-7 nemici, 8 giocatore 2, 9 giocatore 1): si cancella il suo vecchio rettangolo nella vista E=(S+2)%3
   copiandolo dal master, poi lo si disegna nella vista D eseguendo il frame compilato.
4. Ogni vista ricorda camera e posizioni; al fotogramma successivo D viene mostrata.
Gli sprite stanno su x pari (2 px per byte). Uno sprite a cavallo della cucitura dell'anello (x>240) o del confine di 16 KB
della VRAM (riga 128 di una pagina) si disegna nell'area di lavoro e si copia con LMMM trasparente. Gli oggetti non
interamente dentro lo schermo non si disegnano.

## Dati
`tools/gen_swsprites.py` legge `assets/maniero/src/sprite.png` (palette `assets/maniero/palette.json`) e genera 40 frame
(eroe a destra/sinistra x4 stati, giocatore 2 con abiti rossi, goblin = soldato, pipistrello = medico, 6+6 frame ciascuno) in
`editor/swfr10..12.inc` (segmenti ROM 10-12, finestra 8000) e la tabella `editor/swtab.inc`. Il motore sta nel segmento 3
(finestra A000, con trampolini in `swspr.asm`); durante il disegno la finestra 8000 mappa il frame e poi torna all'SCC.

## Costi misurati (openMSX, V9958)
Eroe fermo ~2,5 ms di `sw_update`; ogni oggetto in piu' ~0,8 ms; ciclo totale ~9 ms con l'eroe, ~12 ms con 4 nemici su 16,7.
Con 8 nemici in vista si arriva vicino al limite: ottimizzare la cancellazione (un rettangolo unico) se serve.
