; generato da tools/gen_tiles.py - non modificare a mano
T_EMPTY   equ 0
T_GRASS   equ 1
T_DIRT    equ 2
T_STONE   equ 3
T_BRICK   equ 4
T_MOSSY   equ 5
T_CRATE   equ 6
T_CRYST   equ 7
T_GOLDB   equ 8
T_CWALL   equ 9
T_WOODP   equ 10
T_BRIDGE  equ 11
T_LEDGE   equ 12
T_RUNE    equ 13
T_RUNEU   equ 14
T_BREAK   equ 15
T_CRUMB   equ 16
T_SPRING  equ 17
T_SPIKES  equ 18
T_LAVAT   equ 19
T_LAVA    equ 20
T_WATERT  equ 21
T_WATER   equ 22
T_LADDER  equ 23
T_VINE    equ 24
T_DOORT   equ 25
T_DOORB   equ 26
T_COIN    equ 27
T_GEM     equ 28
T_KEY     equ 29
T_POTION  equ 30
T_CHEST   equ 31
T_CHKPT   equ 32
T_PORTT   equ 33
T_PORTB   equ 34
T_START   equ 35
T_TORCH   equ 36
T_TRUNK   equ 37
T_LEAVES  equ 38
T_BUSH    equ 39
T_FENCE   equ 40
T_FLOWER  equ 41
T_BONES   equ 42
T_BANNER  equ 43
T_WINDOW  equ 44
T_CRYDEC  equ 45
T_SHROOM  equ 46
T_SIGN    equ 47
T_CLOUD   equ 48
T_PILLAR  equ 49
T_DRAGON  equ 50
T_COUNT   equ 51

C_VUOTO    equ 0
C_SOLIDO   equ 1
C_PIATTAFORMA equ 2
C_PERICOLO equ 3
C_LIQUIDO  equ 4
C_SCALABILE equ 5
C_COLPIBILE equ 6
C_OGGETTO  equ 7
C_MARCATORE equ 8
C_DECORAZIONE equ 9

; classe di collisione di ogni tile (1 byte per tile)
tile_class:
        db 0,1,1,1,1,1,1,1,1,9,2,2,2,6,1,6
        db 6,8,3,3,3,4,4,5,5,8,8,7,7,7,7,6
        db 8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9
        db 9,9,9
