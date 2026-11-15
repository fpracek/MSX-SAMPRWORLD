# menu iniziale: voci, navigazione verso elenco server e impostazioni, ritorno e ingresso nell'editor (usa editor.rom, con menu)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/menu_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
after time 24 { screenshot "$R/m1_menu.png"; L "menu: voce=[rd 0xCCB0]" }
after time 24.5 { tap 8 0x40 }                  ;# GIU: CREATE LEVELS
after time 25.3 { tap 8 0x40 }                  ;# GIU: SERVER LEVELS
after time 27 { L "dopo GIU x2: voce=[rd 0xCCB0] (atteso 2)"; screenshot "$R/m2_down.png" }
after time 27.5 { tap 7 0x80 }                  ;# INVIO: livelli del server (nessun server attivo: errore di rete)
after time 46 { screenshot "$R/m3_browse.png" }
after time 46.5 { tap 7 0x04 }                  ;# ESC: torna al menu
after time 62 { screenshot "$R/m4_back.png"; L "ritorno dal server: voce=[rd 0xCCB0] (atteso 2)" }
after time 62.5 { tap 8 0x40 }                  ;# GIU: NETWORK SETTINGS
after time 64 { tap 7 0x80 }                    ;# INVIO: impostazioni
after time 76 { screenshot "$R/m5_settings.png" }
after time 76.5 { tap 7 0x04 }                  ;# ESC
after time 92 { L "ritorno dalle impostazioni: voce=[rd 0xCCB0] (atteso 3)" }
after time 92.5 { tap 8 0x20 }
after time 93.2 { tap 8 0x20 }                  ;# SU x2: CREATE LEVELS
after time 94.5 { tap 7 0x80 }                  ;# INVIO: editor
after time 102 { screenshot "$R/m6_editor.png"; L "editor: v_pick=[rd 0xC804] curx=[rd 0xC800] cury=[rd 0xC801]"; close $log; exit }
