# Audio (SCC della Yamanooto)

- Chip: SCC (Konami5/SCC). Con `0x3F` nel registro banco `9000h` i registri compaiono a `9800h`
  (onde 9800-987F, frequenze 9880.., volumi 988A.., abilitazione 988F). Il banco `9000h` e' lo stesso della
  finestra flash: dopo aver scritto la bozza il codice riporta il banco ai suoi segmenti.
- Canali: 1 melodia (onda quadra), 2 basso (triangolo), 3 arpeggio pizzicato (impulso 25%), 4 effetti.
- Brano (`tools/gen_music.py`): re minore, 8 battute x 8 crome, 112 bpm circa, in loop. Dati nel segmento 4 (offset 2048).
- Effetti: salto, moneta, schiacciato, blocco colpito, morte, jingle di vittoria (C6-E6-G6-C7), chiave/portone.
  Si lanciano con `ld a,SFX_xxx / call sfx_a`.
- `snd_tick` va chiamato una volta per frame (nel ciclo di prova, dopo il vblank).

## Verifica
`editor/tests/t_audio.tcl` registra l'uscita emulata (`record start -audioonly`). L'analisi spettrale ha confermato le
note del brano (basso D2 73 Hz, melodia A4 440 Hz ... A5 881 Hz) e il jingle di vittoria (1050, 1300, 1550, 2075 Hz).
Non e' stato ancora ascoltato su hardware reale.
