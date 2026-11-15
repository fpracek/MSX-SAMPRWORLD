# menu iniziale: voci, navigazione verso elenco server e impostazioni, ritorno e ingresso nell'editor (usa editor.rom, con menu)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/menu_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
after time 24 { screenshot "$R/m1_menu.png"; L "menu: voce=[rd 0xCCB0]" }
after time 24.5 { tap 8 0x40 }                  ;# GIU
after time 26 { L "dopo GIU: voce=[rd 0xCCB0]"; screenshot "$R/m2_down.png" }
after time 26.5 { tap 7 0x80 }                  ;# INVIO: livelli del server (nessun server attivo: errore di rete)
after time 45 { screenshot "$R/m3_browse.png" }
after time 45.5 { tap 7 0x04 }                  ;# ESC: torna al menu
after time 60 { screenshot "$R/m4_back.png"; L "ritorno dal server: voce=[rd 0xCCB0]" }
after time 60.5 { tap 8 0x40 }
after time 62 { tap 7 0x80 }                    ;# INVIO: impostazioni
after time 74 { screenshot "$R/m5_settings.png" }
after time 74.5 { tap 7 0x04 }                  ;# ESC
after time 90 { L "ritorno dalle impostazioni: voce=[rd 0xCCB0]" }
after time 90.5 { tap 8 0x20 }
after time 91.2 { tap 8 0x20 }                  ;# SU x2: CREA
after time 92 { tap 7 0x80 }                    ;# INVIO: editor
after time 100 { screenshot "$R/m6_editor.png"; L "editor: v_pick=[rd 0xC804] curx=[rd 0xC800] cury=[rd 0xC801]"; close $log; exit }
