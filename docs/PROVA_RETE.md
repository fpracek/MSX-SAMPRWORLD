# Prova della rete: pubblicare e richiamare i livelli

Il "servizio" e' un piccolo server **UDP** (porta 9100) scritto in Python (solo libreria standard): `net/server/levelserver.py`
(copia pronta in `dist/`). Non e' HTTP: il gioco parla UDP tramite la scheda di rete UNAPI.

## 1. Avviare il server
```
python levelserver.py                 # solo questo computer (127.0.0.1)
python levelserver.py 0.0.0.0         # raggiungibile dalla rete locale / da internet (aprire UDP 9100)
python adduser.py maria SEGRETA-1     # nuovo utente: nome max 11 caratteri, chiave max 15
```
Alla prima partenza crea la cartella `store/` con 3 livelli di esempio e l'utente `testuser` / `TESTKEY-0123456`
(sono i valori gia' presenti nelle impostazioni del gioco).

## 2. Configurare openMSX
- **Extensions**: aggiungere *openMSXnet UnapiNet* (il ponte di rete).
- **Cartridge Slot A**: `unapinet.rom` (il driver UNAPI per il ponte; mapper "auto detect"). **Deve stare nello slot A**:
  il BIOS inizializza le cartucce in ordine e il gioco, una volta partito, non restituisce il controllo, quindi il driver
  deve essere inizializzato prima (altrimenti il gioco dice "No UNAPI card").
- **Cartridge Slot B**: `editor.rom` con mapper-type **Yamanooto**.
- Reset della macchina.

## 3. Impostazioni di rete nel gioco
Menu -> NETWORK SETTINGS (o tasto **N** nell'editor): Server `127.0.0.1` (o l'indirizzo/nome del server), Port `9100`,
User e Key. INVIO salva (in flash).

## 4. Pubblicare un livello
1. CREATE LEVELS: disegna il livello (serve almeno la partenza e il portale), **S** per salvare.
2. **T**: prova il livello e arriva al portale ("Cleared! Validated"): senza questo non si puo' pubblicare.
3. **U**: pubblica. In basso appare "Published id N" e la bozza in flash viene cancellata.

## 5. Richiamare i livelli pubblicati
Menu -> SERVER LEVELS (o tasto **D**): elenco a pagine di 6 livelli; SU/GIU scelgono, SX/DX cambiano pagina,
INVIO scarica e gioca. Il tuo lavoro nell'editor non viene toccato.

## Note
- La chiave viaggia **in chiaro** su UDP: usarla solo per prove o reti fidate (vedi `docs/VALIDATION.md` per i limiti).
- Per un server su internet serve un computer sempre acceso con la porta UDP 9100 aperta; nel gioco si inserisce il suo indirizzo.
- Il server non fa moderazione e limita i livelli a 4096 byte e 50 per utente.
