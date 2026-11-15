set R E:/TEMP/Claude/SAMPRWORLD/repo/editor
proc rd {a} { return [debug read memory $a] }
set log [open "$R/result.txt" w]
proc st {l} { global log; puts $log "$l: curx=[rd 0xC800] cury=[rd 0xC801] scrx=[rd 0xC802] tile=[rd 0xC803] pick=[rd 0xC804] pcur=[rd 0xC805] row10=[rd 0xC500] [rd 0xC501] [rd 0xC502] [rd 0xC503]"; flush $log }
# elenco azioni: {tempo azione}
set t 6.0
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
set acts {
  {right 8 0x80} {space 8 0x01} {dot 2 0x08} {dot 2 0x08} {right 8 0x80} {space 8 0x01}
  {left 8 0x10} {comma 2 0x04} {up 8 0x20} {space 8 0x01} {del 8 0x08}
  {P 4 0x20}
}
foreach a $acts {
    lassign $a name row mask
    after time $t [list tap $row $mask]
    after time [expr {$t+0.5}] [list st $name]
    set t [expr {$t+0.8}]
}
# scorrimento: 20 passi a destra
after time $t { keymatrixdown 8 0x80 }
after time [expr {$t+9}] { keymatrixup 8 0x80; st scroll; screenshot "E:/TEMP/Claude/SAMPRWORLD/repo/editor/shot_scroll.png" }
after time [expr {$t+10}] { close $log; exit }
