# SamPr World

Platform game per **MSX2** (SCREEN 5) ispirato a Mario Maker: ambientazione fantasy, editor di livelli
integrato, livelli scaricabili/caricabili da un server via **UNAPI** (UDP). Cartuccia **Yamanooto**
(Konami5/SCC, salvataggio impostazioni in flash).

## Struttura
- `tools/gen_tiles.py` - genera il tileset fantasy (51 blocchi/oggetti 16x16) in `assets/`
- `assets/` - `tiles.png`, `tiles.bin` (SCREEN 5), `palette.bin`, `tileset.inc` (costanti asm + classi di collisione), `catalog.json`, anteprime
- `net/` - spike di rete verificati su openMSX 22: driver UnapiNet, client UNAPI, server livelli UDP, test Yamanooto/flash

## Stato
Fase 0 (rete/banking/flash) verificata in emulazione. Ora: blocchi e oggetti per i livelli.
Ancora da fare: formato livello, motore (da soccerlg), editor, SCC, prove su hardware reale.

## Editor (v0) - `editor/editor.asm`
Assemblare con sjasmplus, provare con `openmsx -machine Panasonic_FS-A1ST -cart editor/editor.rom`.
Frecce = muovi, SPAZIO = piazza (tenuto premuto = pittura), X/DEL = cancella, `,` `.` = tile precedente/successivo,
P = prendi il tile sotto il cursore, TAB = elenco blocchi (INVIO/SPAZIO sceglie, ESC chiude).
Mappa 128x12 in RAM; per ora non si salva. `editor/run2.tcl` e' il test automatico con tastiera vera.
