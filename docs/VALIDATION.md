# Validazione dei livelli prima della pubblicazione

Regola (Fausto, 15/11/2026): un livello si pubblica solo dopo che **il suo creatore lo ha superato**.
Puo' servire anche piu' di un giorno, quindi la bozza resta in flash (docs/FLASH.md) fino alla pubblicazione.

## Stato attuale (editor)
- Il record bozza ha un byte `val`. Vale 1 solo se il livello e' stato superato **e non e' piu' stato modificato**:
  qualsiasi modifica della mappa lo azzera (si deve rigiocare).
- Il tasto U rifiuta con "Superalo prima" se `val` = 0. A pubblicazione riuscita la bozza viene cancellata e `val` azzerato
  (niente doppia pubblicazione).
- SELECT (nuovo livello) chiede conferma entro ~3 s, perche' cancella la bozza.
- Con `DEVBUILD equ 1` il tasto V segna il livello come superato senza giocare: **solo sviluppo**, da togliere quando
  esiste la modalita' prova.

## Cosa manca (onesta')
Il flag e' solo nel client: chi modifica la cartuccia o il client puo' aggirarlo. La difesa vera e' **lato server**:
- durante la prova il gioco registra gli input (replay, RLE) e li accoda al livello;
- il server rigioca il replay con lo stesso motore (deterministico) e pubblica solo se arriva al portale;
- per questo la fisica e la generazione dei nemici devono essere deterministiche (nessun rnd non seminato).
Finche' il replay non esiste il server accetta qualsiasi livello valido dal punto di vista del formato.
