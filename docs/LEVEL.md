# Formato livello v1 (blob scambiato col server)

```
00 'L','V'
02 ver = 1
03 w         colonne (1-255)
04 h         righe (1-16)
05 start_x   colonna di partenza
06 start_y   riga di partenza
07 theme     0 = prato, 1 = caverna, 2 = castello (sfondo/musica)
08 title[16] ASCII, riempito con 0
18 n_ent     numero di entita' (nemici, oggetti mobili)
19 ent[n_ent] * 3 byte: tipo, x, y
.. mappa RLE di w*h tile, per righe dall'alto
-2 crc16     CRC16-CCITT-FALSE (init FFFF, poly 1021) dei byte precedenti, little-endian
```
RLE: un byte < 0x40 e' un tile singolo; `0x80|tile` seguito da `n` (2-255) e' una ripetizione di `n` tile.
Caso peggiore (nessuna ripetizione): w*h byte, per 128x12 = 1536 < MAX_SIZE del server (4096).
