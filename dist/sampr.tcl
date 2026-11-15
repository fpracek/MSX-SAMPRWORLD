# SamPr World launcher script for openMSX (loaded with -script).
# Slot A = UnapiNet driver, slot B = game (Yamanooto mapper: flash for draft/settings/progress).
set d [file dirname [file normalize [info script]]]
set rom $d/editor.rom

# openMSX keeps the Yamanooto flash image on disk (persistent/roms/<romname>/<romname>.SRAM) and it
# OVERRIDES the ROM file: after updating editor.rom the old game would keep starting.
# If the ROM is newer than the saved flash image, drop the image (this erases draft and progress).
if {[info exists ::env(OPENMSX_USER_DATA)]} { set ud $::env(OPENMSX_USER_DATA) } else { set ud [file join $::env(USERPROFILE) Documents openMSX] }
set sram [file join $ud persistent roms [file tail $rom] "[file tail $rom].SRAM"]
if {[file exists $sram] && [file mtime $rom] > [file mtime $sram]} {
    file delete -force [file dirname $sram]
    puts "editor.rom is newer than the saved flash: flash image reset (draft/progress cleared)"
}

carta $d/unapinet.rom
cartb $rom -romtype Yamanooto
reset
