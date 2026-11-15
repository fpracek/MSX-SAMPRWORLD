# audio SCC: registra l'uscita sonora durante la prova e legge i registri (se esposti)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc cell {col row t} { debug write memory [expr {0xC000 + $row*128 + $col}] $t }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.2 [list keymatrixup $row $mask] }
after time 17 { cell 1 10 35; cell 24 9 33; cell 24 10 34; record start -audioonly "E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests/audio.wav" }
after time 18 { tap 5 0x02 }       ;# T: inizia la prova (musica)
after time 22 { tap 8 0x01 }       ;# salto (effetto)
after time 26 { keymatrixdown 8 0x80 }   ;# corre fino al portale (vittoria)
after time 38 { keymatrixup 8 0x80; record stop; exit }
