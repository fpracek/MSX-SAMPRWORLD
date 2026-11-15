# SamPr World

Platform game per **MSX2** (SCREEN 5) ispirato a Mario Maker: ambientazione fantasy, editor di livelli
integrato, livelli scaricabili/caricabili da un server via **UNAPI** (UDP). Cartuccia **Yamanooto**
(Konami5/SCC, salvataggio impostazioni in flash).

## Struttura
- `tools/gen_tiles.py` - genera il tileset fantasy (51 blocchi/oggetti 16x16) in `assets/`
- `assets/` - `tiles.png`, `tiles.bin` (SCREEN 5), `palette.bin`, `tileset.inc` (costanti asm + classi di collisione), `catalog.json`, anteprime
- `tools/gen_sprites.py` - sprite dell'eroe (4 frame x 2 direzioni, 4 sprite sovrapposti per frame) -> `assets/hero.bin`
- `net/` - spike di rete verificati su openMSX 22: driver UnapiNet, client UNAPI, server livelli UDP, test Yamanooto/flash

## Stato
Fase 0 (rete/banking/flash) verificata in emulazione. Ora: blocchi e oggetti per i livelli.
Ancora da fare: formato livello, motore (da soccerlg), editor, SCC, prove su hardware reale.

## Editor (v0) - `editor/editor.asm`
Assemblare con sjasmplus, provare con `openmsx -machine Panasonic_FS-A1ST -cart editor/editor.rom`.
Frecce = muovi, SPAZIO = piazza (tenuto premuto = pittura), X/DEL = cancella, `,` `.` = tile precedente/successivo,
P = prendi il tile sotto il cursore, TAB = elenco blocchi (INVIO/SPAZIO sceglie, ESC chiude).
Bozza in flash Yamanooto (ROM Konami5 da 256K: `-romtype Yamanooto`, vedi docs/FLASH.md):
S = salva la bozza, L = ricarica, SELECT = nuovo livello (cancella anche la bozza). All'avvio la bozza salvata viene ripristinata.
U = pubblica sul server (UNAPI/UDP; richiede il livello superato, vedi docs/VALIDATION.md; V = valida, solo build DEV).
T = prova il livello (modalita' gioco: frecce + SPAZIO salta, ESC esce). Arrivare al portale valida il livello e salva la bozza.
Nemici: tile "Goblin" (cammina, si gira ai bordi) e "Pipistrello" (vola ondeggiando) dalla lista blocchi; in prova si schiacciano dall'alto, altrimenti uccidono. Alla fine della prova la mappa viene ripristinata.
Blocchi interattivi (in prova): pietra fessurata si rompe da sotto; blocco runico/forziere colpiti da sotto fanno apparire moneta/gemma; blocco friabile crolla dopo ~0,5 s; chiave + portone (la chiave si consuma).
Audio SCC: musica in prova (re minore) ed effetti (salto, moneta, schiacciato, blocco, morte, vittoria); vedi docs/AUDIO.md.
D = livelli sul server (UNAPI/UDP): elenco a pagine, SU/GIU/SX/DX, INVIO scarica e gioca (il lavoro dell'editor e la sua validazione non cambiano), ESC esce. Solo livelli 128x12 con CRC valido.
Mappa 128x12 in RAM. Test automatici in `editor/tests/` (openMSX con tastiera vera; prima di ogni prova da zero
cancellare `Documents/openMSX/persistent/roms/editor.rom`).
