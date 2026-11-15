# Flash Yamanooto - mappa d'uso (decisione di Fausto, 15/11/2026)

La flash e' poca e serve soprattutto alle **impostazioni di rete**: la bozza in lavorazione ne occupa
una parte minima e **viene cancellata appena il livello e' pubblicato**. I livelli scaricati stanno solo in RAM.

Due settori da 64 KB riservati in fondo all'immagine ROM (allineati a 64 KB), cancellabili
indipendentemente (l'erase e' per settore):

| Settore | Contenuto | Scrittura | Cancellazione |
|---|---|---|---|
| SET (64K) | impostazioni di rete e credenziali | append di record da 128 B | solo quando e' pieno (512 versioni) |
| DRAFT (64K) | bozza del livello in creazione, **anche per giorni**, finche' non e' superata e pubblicata | append di record (blob RLE) | **dopo la pubblicazione**, con SELECT confermato, o quando e' pieno |

## Record impostazioni (128 byte, l'ultimo valido vince)
```
00 'N','S'        magic
02 seq            numero progressivo (1 byte, confronto circolare)
03 flags          bit0 = IP statico (0 = DHCP)
04 ip_local[4]    solo se statico
08 netmask[4]
0C gateway[4]
10 dns[4]
14 server_ip[4]   usato se server_host e' vuoto
18 server_port[2] (LE)
1A server_host[28] nome DNS, zero-terminato (vuoto = usa server_ip)
36 user[12]
42 key[16]
52 progressi campagna[2] (maschera di bit dei livelli superati; ogni vittoria aggiunge un record)
54 (riservato)
7F checksum       somma di tutti i 128 byte = 0
```
## Record bozza
```
00 'D','R'
02 seq
03 len[2]         lunghezza del blob livello (LE)
05 blob[len]      livello formato v1 (vedi docs/LEVEL.md), con il suo CRC16
.. val[1]         1 = il creatore ha superato il livello (docs/VALIDATION.md); non viene inviato al server
.. checksum[1]    somma dei byte del record = 0
```
Il record successivo parte all'indirizzo allineato a 16 byte. Si legge l'ultimo valido; dopo la pubblicazione
si cancella il settore DRAFT.

## Rischi noti
- Un reflash della cartuccia cancella tutto: la bozza va pubblicata prima, le impostazioni si reinseriscono.
- Credenziali in chiaro nella flash (la cartuccia e' dell'utente; da valutare un offuscamento).
- Se manca la corrente durante l'erase+riscrittura (settore pieno) la bozza puo' andare persa.
- Tempi reali di erase e allineamento a 64 KB nel menu Yamanooto: da verificare sul ferro.

## Impostazioni di rete (stato)
La schermata N (editor/netset.asm) scrive un nuovo record da 128 byte in coda al settore SET (il record di sviluppo
della ROM, `assets/settings_dev.bin`, e' solo il punto di partenza). Con IP statico (bit0 di flags) il modulo di rete chiama
TCPIP_CONFIG_AUTOIP (25, B=1 C=0) e TCPIP_CONFIG_IP (26) per IP locale, maschera, gateway e DNS primario; gli errori
(ERR_NOT_IMP) si ignorano. Il campo Server accetta un nome DNS o un IP in forma decimale.
