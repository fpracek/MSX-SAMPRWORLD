# Arte de "Il Maniero" (Nicola Brogelli)

`src/castle-tileset.png`, `src/sprite.png`, `src/MANIERO.png` provengono da https://github.com/nicolabrogelli/MSXIlManiero
(`datasrc/img/`), usati in SamPr World con il permesso dell'autore. `tools/gen_maniero.py` li converte nel formato
SCREEN 5 (palette MSX2 da 16 colori, blocchi 16x16 unici, frame degli sprite): vedi `docs/MANIERO.md`.

- `castle-tileset.png`: tavola di blocchi 16x16 (oggetti di scena e muri)
- `sprite.png`: sprite 16x16 (protagonista, nemici, monete, esplosioni)
- `MANIERO.png`: tavola 8x8 impacchettata usata dai livelli originali (id = riga*32 + colonna)
