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
19 ent[n_ent] * 8 byte: proprieta' di un nemico (n_ent <= 16), vedi sotto
.. mappa RLE di w*h tile, per righe dall'alto
-2 crc16     CRC16-CCITT-FALSE (init FFFF, poly 1021) dei byte precedenti, little-endian
```
RLE: un byte < 0x80 e' un tile singolo (id 0-127); `0x80|tile` seguito da `n` (2-255) e' una ripetizione di `n` tile.
Caso peggiore (nessuna ripetizione): w*h byte, per 128x12 = 1536 < MAX_SIZE del server (4096).

## Proprieta' dei nemici (record da 8 byte)
Ogni record e' agganciato a un nemico (goblin/pipistrello) del livello dalla sua posizione. Un nemico senza record usa i
valori predefiniti. Nell'editor si modificano con INVIO sul nemico (`editor/props.asm`, `swprops.asm`).

| byte | campo | valori |
|---|---|---|
| 0 | colonna | 0-127 |
| 1 | riga | 0-11 |
| 2 | comportamento | 0 pattuglia, 1 dormiglione (si muove solo se l'eroe e' vicino), 2 inseguitore, 3 pauroso (fugge) |
| 3 | velocita' | 1 = un passo ogni 2 fotogrammi, 2 = un passo, 3 = due passi |
| 4 | raggio di pattuglia in tile | 0 = illimitato; dopo il raggio dalla posizione di partenza torna indietro (pipistrelli: durata dell'andata) |
| 5 | vita | 1-3 balzi sulla testa per ucciderlo |
| 6 | rilevamento in tile | 1-15: distanza a cui l'eroe "sveglia"/attira/spaventa il nemico |
| 7 | riservato | 0 |

Il formato e' retrocompatibile con i livelli esistenti (n_ent = 0). Tile id fino a 127 (RLE a 7 bit).
