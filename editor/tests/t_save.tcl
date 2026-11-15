carta E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor
proc rd {a} { return [debug read memory $a] }
set log [open "$R/result.txt" w]
proc st {l} { global log; puts $log "$l: curx=[rd 0xC800] tile=[rd 0xC803] map=[rd 0xC500] [rd 0xC501] [rd 0xC502] [rd 0xC503] lvalid=[rd 0xC840] seq=[rd 0xC849] fseg=[rd 0xC844] fpos=[format %02X [rd 0xC846]][format %02X [rd 0xC845]] perr=[rd 0xC84A] rlen=[expr {[rd 0xC847]+256*[rd 0xC848]}] msg=[format %02X [rd 0xC81A]][format %02X [rd 0xC819]]"; flush $log }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
set t 14.0
after time $t { st boot; screenshot "$R/s_boot.png" }
set t [expr {$t+1}]
foreach a {{right 8 0x80} {space 8 0x01} {dot 2 0x08} {right 8 0x80} {space 8 0x01} {dot 2 0x08} {right 8 0x80} {space 8 0x01}} {
    lassign $a name row mask
    after time $t [list tap $row $mask]
    set t [expr {$t+0.6}]
}
after time $t { st edited }
set t [expr {$t+0.5}]
after time $t [list tap 5 0x01]   ;# S
set t [expr {$t+2}]
after time $t { st saved; screenshot "$R/s_saved.png" }
set t [expr {$t+1}]
after time $t { close $log; exit }
