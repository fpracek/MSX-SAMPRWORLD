# Due giocatori (co-op locale)

Implementato in `editor/coop.asm`. Si sceglie dal menu iniziale (`PLAYERS: 1/2`, ENTER alterna) e vale per la campagna,
i livelli del server e la prova nell'editor.

## Controlli
| | Giocatore 1 | Giocatore 2 |
|---|---|---|
| Movimento | frecce **oppure** joystick 1 | joystick 2 **oppure** `A` `D` (sinistra/destra), `W` `S` (scale) |
| Salto | SPAZIO / pulsante del joystick 1 | pulsante del joystick 2 / `Z` |

Il joystick e' letto dal PSG (R#15 bit 6 sceglie la porta, R#14 i contatti). Anche con un giocatore solo il joystick 1
affianca la tastiera.

## Regole
- Condivisi: monete, chiavi, nemici uccisi, checkpoint, portale (vale chi lo raggiunge), ESC.
- Separati: posizione, velocita', salto, vita. Gli eroi non collidono tra loro (si attraversano).
- Camera di gruppo: nessuno dei due eroi puo' uscire dallo schermo (muri invisibili a `cam` e a `cam+240`, a destra e a sinistra). Chi e' davanti puo' avanzare fino al bordo opposto della finestra e li' si ferma; la camera non scorre finche' l'altro non gli si avvicina: scorre solo nel margine che resta, cioe' sta sempre tra `max(x)-240` e `min(x)` (ancora = punto medio, limitata). Se un eroe e' morto la camera segue l'altro. Codice in `swcam.asm`.
- Morte: l'eroe rinasce dopo 40 fotogrammi accanto all'altro (se e' vivo); se sono morti entrambi, tutti e due ripartono
  dall'ultimo checkpoint (camera inclusa).

## Architettura
Lo stato di un eroe sta nel blocco "attivo" di `play.asm` (`p_x` ... `p_cavail`, indirizzi invariati). Con due giocatori
ogni eroe ha un blocco di salvataggio da 22 byte (`HS0`/`HS1`, RAM 0xC720/0xC738) e `play_2p` carica/esegue/risalva a
turno: fisica, collisioni coi tile e coi nemici non sono state toccate. Con un giocatore solo non cambia nulla
(i test a un giocatore danno risultati identici). Il byte di input di ogni giocatore ha il formato di `v_k8`
(b7 destra, b4 sinistra, b5 su, b6 giu', b0 salto): e' il punto d'innesto per un giocatore remoto.

## Sprite
Il VDP ha 16 tabelle colore indipendenti e al massimo 8 sprite per riga. L'eroe 1 resta a 4 layer (piani 0-3); l'eroe 2
e' a 2 layer (contorno + riempimento, tunica rossa, elmo verde) per restare nel limite insieme ai nemici: piani 14-15 su
V9958 (l'HUD perde il contatore dei nemici) o 10-11 su V9938. I pattern dell'eroe 2 sono nel segmento 4 a offset 3328
(`tools/gen_sprites.py`). Con due eroi e due nemici sulla stessa fascia di righe l'eroe 2 puo' sfarfallare.

## Spazio ROM
La pagina 1 era piena: i nomi dei tile sono stati spostati nel segmento 2 (finestra A000). Restano circa 700 byte liberi in
pagina 1; il livello di rete per il gioco remoto richiedera' un'ulteriore rilocazione.

## Test
`editor/tests/t_coop.tcl` (corsa, camera, riporto), `t_coop2.tcl` (rinascite, V9958 e V9938 con `TAG`/`-machine`),
`t_menu2p.tcl` (voce di menu). Il ROM di test accetta tasti forzati scrivendo in 0xC765 (P1) e 0xC764 (P2).

## Livelli alti (scorrimento verticale)
Nei livelli alti (docs/TALL.md) la finestra verticale scorre solo se entrambi gli eroi restano visibili: chi sale verso il bordo
alto mentre l'altro e' piu' in basso di ~7 righe resta bloccato al bordo finche' l'altro non si avvicina (stessa regola della
camera orizzontale).
