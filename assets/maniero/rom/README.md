# Livelli dalla ROM di Il Maniero con scrolling verticale

La ROM `ilmaniero.rom` (1 MB, ASCII16 + V9990) fornita da Fausto contiene livelli **64x64 tile da 8 px (512x512 px)**, cioe' con
scrolling verticale, a differenza del repository pubblico (64x25). Mappe u16 little-endian (id = riga*32+colonna in MANIERO.png),
0 = vuoto, in pagine da 8 KB agli offset 0x50000, 0x5C000, 0x60000 (0x70000 e' un duplicato del primo). Monete, chiavi, scale ecc.
sono tile della mappa. Le tabelle dei nemici trovate a 0x2D90-0x2F20 (record da 17 byte) sono quelle vecchie: i nemici dei
livelli alti vanno ancora estratti (RAM durante il gioco).
