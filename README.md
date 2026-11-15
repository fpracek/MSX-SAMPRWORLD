# SamPr World

A fantasy platformer for **MSX2** (SCREEN 5, pure V9938) with a built-in level editor, ten fixed campaign levels, and
level sharing over the network: levels made by other players are downloaded from a server through **UNAPI** (UDP).
Runs from a **Yamanooto** cartridge (Konami5/SCC mapper, flash for saving a draft and the network settings).

All on-screen text is in English.

## Build and run
`editor/build.sh` (needs [sjasmplus](https://github.com/z00m128/sjasmplus)) produces
- `editor/editor.rom` - the game (title menu on start-up),
- `editor/editor_test.rom` - the same without the menu, used by the automated tests in `editor/tests` (openMSX Tcl scripts).

Run in openMSX with the Yamanooto mapper: `openmsx -machine <MSX2 machine> -ext unapinet -carta net/unapi/unapinet.rom`
and load `editor.rom` in slot B as `-romtype Yamanooto` (the UNAPI bridge driver is only needed for the network features).

## What is in the game
- **Title menu**: Play the campaign - Create levels - Server levels - Network settings (F1 reopens it from the editor).
- **Campaign**: 10 fixed levels (meadows, caves, castle) always available in the ROM (`tools/make_levels.py`).
- **Editor** (arrows move, SPACE places, X/DEL erases, `,` `.` previous/next block, TAB block list, P pick, S save the
  draft to flash, L reload it, SELECT new level, T test-play, U publish, D server levels, N network settings).
- **Test-play**: physics, one-way platforms, ladders, water, springs, checkpoints, coins/gems/keys, crumbling blocks,
  breakable stone, rune blocks, gates, goblins and bats. A level must be cleared by its creator before it can be published
  (`docs/VALIDATION.md`).
- **Network**: publish the draft, browse the server list, download and play other players' levels
  (`net/server/levelserver.py` is a stdlib-only UDP server, `docs/` has the formats).
- **Audio**: music and effects on the SCC (`docs/AUDIO.md`).

## Repository layout
- `editor/` - Z80 source (sjasmplus), `tests/` - automated openMSX tests
- `tools/` - tile/sprite/music/level generators (Python + Pillow)
- `assets/` - generated tileset, sprites, audio, campaign levels
- `net/` - UNAPI bridge driver, test clients, level server, spikes
- `docs/` - flash layout, level format, validation, scrolling and audio notes (Italian)

## Status
Everything is verified in openMSX (including a scripted bot that clears all 10 campaign levels), but not yet on real
hardware: flash timing and 64 KB alignment on the Yamanooto, real UNAPI cards and the static-IP calls still need testing.
Scrolling is page-based because the V9938 cannot scroll smoothly at 50/60 Hz (`docs/SCROLL.md`).
