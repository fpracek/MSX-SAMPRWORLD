; menu.asm - schermata iniziale (all'avvio e con F1): creare/continuare la bozza, livelli del server, impostazioni di rete.
mn_sel  equ FBUF+0xB0
mn_n    equ 5

do_menu:
        call hide_cursor
        xor a
        ld (mn_sel),a
        call mn_draw
mn_loop:
        call vwait
        ld a,8
        ld hl,v_prev8
        call edge
        ld (v_e8),a
        ld a,7
        ld hl,v_prev7
        call edge
        ld (v_e7),a
        bit 7,a                 ; INVIO
        jr nz,mn_go
        ld a,(v_e8)
        bit 0,a                 ; SPAZIO
        jr nz,mn_go
        bit 5,a
        jr nz,mn_up
        bit 6,a
        jr nz,mn_dn
        jr mn_loop
mn_up:  ld a,(mn_sel)
        or a
        jr z,mn_loop
        ld c,' '
        call mn_mark
        ld a,(mn_sel)
        dec a
        ld (mn_sel),a
        ld c,'>'
        call mn_mark
        jr mn_loop
mn_dn:  ld a,(mn_sel)
        cp mn_n-1
        jr nc,mn_loop
        ld c,' '
        call mn_mark
        ld a,(mn_sel)
        inc a
        ld (mn_sel),a
        ld c,'>'
        call mn_mark
        jr mn_loop
mn_go:  ld a,(mn_sel)
        or a
        jr nz,mg_1
        call do_campaign
        jr mn_back
mg_1:   cp 1
        jr z,mn_exit            ; CREATE LEVELS: si entra nell'editor
        cp 4
        jr nz,mg_2
        ld a,(p_two)            ; PLAYERS: 1 <-> 2
        xor 1
        ld (p_two),a
        jr mn_back
mg_2:   cp 2
        jr nz,mn_set
        call do_browse
        jr mn_back
mn_set: call do_netset
mn_back:
        call hide_cursor
        call mn_draw
        jp mn_loop
mn_exit:
        ld a,1
        ld (v_redr),a
        ld (v_dirty),a
        ret

; carattere C a sinistra della voce A
mn_mark:
        ld b,a
        ld a,142
        ld d,b
        inc d
mm_y:   dec d
        jr z,mm_d
        add a,12
        jr mm_y
mm_d:   ld l,a
        ld h,0
        ld (GRPACY),hl
        ld hl,40
        ld (GRPACX),hl
        ld a,c
        jp print_char

; scena fantasy (tile) + titolo + voci
mn_draw:
        ld hl,p_clear
        call vdp_cmd
        ld hl,p_sky             ; cielo: 5 righe di tile
        call vdp_cmd
        ld hl,mn_scene
mn_s:   ld a,(hl)
        cp 0xFF
        jr z,mn_t
        push hl
        ld b,(hl)               ; colonna
        inc hl
        ld c,(hl)               ; riga
        inc hl
        ld a,(hl)               ; tile
        call draw_tile
        pop hl
        inc hl
        inc hl
        inc hl
        jr mn_s
mn_t:   ld a,15
        ld (FORCLR),a
        ld a,1
        ld (BAKCLR),a
        ld hl,72
        ld (GRPACX),hl
        ld hl,116
        ld (GRPACY),hl
        ld hl,s_mtitle
        call print_str
        ld hl,20
        ld (GRPACX),hl
        ld hl,127
        ld (GRPACY),hl
        ld hl,s_msub
        call print_str
        ld hl,s_mi0
        ld b,0
mn_i:   push bc
        push hl
        ld a,142
        ld d,b
        inc d
mi_y:   dec d
        jr z,mi_d
        add a,12
        jr mi_y
mi_d:   ld l,a
        ld h,0
        ld (GRPACY),hl
        ld hl,40
        ld (GRPACX),hl
        ld a,(mn_sel)
        cp b
        ld a,' '
        jr nz,mi_m
        ld a,'>'
mi_m:   call print_char
        ld hl,56
        ld (GRPACX),hl
        pop hl
        call print_str
        inc hl                  ; oltre il terminatore
        pop bc
        inc b
        ld a,b
        cp mn_n-1
        jr nz,mn_i
        ld hl,40                ; ultima voce: PLAYERS: 1 / 2
        ld (GRPACX),hl
        ld hl,190
        ld (GRPACY),hl
        ld a,(mn_sel)
        cp mn_n-1
        ld a,' '
        jr nz,mp_m
        ld a,'>'
mp_m:   call print_char
        ld hl,56
        ld (GRPACX),hl
        ld hl,s_mpl
        call print_str
        ld a,(p_two)
        add a,'1'
        call print_char
        ld hl,16
        ld (GRPACX),hl
        ld hl,200
        ld (GRPACY),hl
        ld a,(v_flash)
        or a
        ld hl,s_mfoot
        jr nz,mf_p
        ld hl,s_mnoflash
mf_p:   jp print_str

p_sky:  db 0,0,0,0, 0,0,0,0, 0,1, 112,0, 0x00,0,0xC0      ; HMMV colore 0 sulle prime 112 righe

; colonna, riga, tile (terminato da 0xFF)
mn_scene:
        db 0,5,T_GRASS, 1,5,T_GRASS, 2,5,T_GRASS, 3,5,T_GRASS, 4,5,T_GRASS, 5,5,T_GRASS, 6,5,T_GRASS, 7,5,T_GRASS
        db 8,5,T_GRASS, 9,5,T_GRASS, 10,5,T_GRASS, 11,5,T_GRASS, 12,5,T_GRASS, 13,5,T_GRASS, 14,5,T_GRASS, 15,5,T_GRASS
        db 0,6,T_DIRT, 1,6,T_DIRT, 2,6,T_DIRT, 3,6,T_DIRT, 4,6,T_DIRT, 5,6,T_DIRT, 6,6,T_DIRT, 7,6,T_DIRT
        db 8,6,T_DIRT, 9,6,T_DIRT, 10,6,T_DIRT, 11,6,T_DIRT, 12,6,T_DIRT, 13,6,T_DIRT, 14,6,T_DIRT, 15,6,T_DIRT
        db 1,4,T_TRUNK, 1,3,T_LEAVES, 0,3,T_LEAVES, 2,3,T_LEAVES
        db 3,4,T_FLOWER, 4,4,T_BUSH, 6,4,T_SIGN, 8,4,T_DRAGON
        db 11,4,T_BRICK, 12,4,T_BRICK, 13,4,T_BRICK, 14,4,T_BRICK
        db 11,3,T_BRICK, 12,3,T_WINDOW, 13,3,T_BRICK, 14,3,T_BRICK
        db 11,2,T_BRICK, 12,2,T_BANNER, 13,2,T_BRICK, 14,2,T_BRICK
        db 11,1,T_BRICK, 12,1,T_BRICK, 13,1,T_BRICK, 14,1,T_BRICK
        db 10,4,T_TORCH, 15,4,T_TORCH, 12,0,T_PILLAR, 13,0,T_PILLAR
        db 4,1,T_CLOUD, 8,1,T_CLOUD, 15,0,T_CLOUD
        db 0xFF

s_mtitle: db "SAMPR WORLD  r8",0
s_msub:   db "Fantasy platformer for MSX2",0
s_mi0:    db "PLAY THE CAMPAIGN",0
s_mi1:    db "CREATE LEVELS",0
s_mi2:    db "SERVER LEVELS",0
s_mi3:    db "NETWORK SETTINGS",0
s_mpl:    db "PLAYERS: ",0
s_mfoot:  db "UP/DOWN select  ENTER confirm",0
s_mnoflash: db "NO FLASH - use Yamanooto ROM",0
