; SamPr World - editor di livelli (v0): scelta e posizionamento dei blocchi
; MSX2, SCREEN 5. ROM 32K (pagina 1), codice eseguito in ROM, mappa in RAM.
;
; Tasti:  frecce = muovi    SPAZIO = piazza    X o DEL = cancella    , e . = tile prec/succ
;         P = prendi il tile sotto il cursore    TAB = elenco blocchi    INVIO = scegli    ESC = chiudi
;
; Schermo: mappa 16x12 tile (256x192) + barra di stato (20 righe). Il tileset sta in pagina 1 di VRAM
; (y=256..), la mappa si ridisegna con HMMM pagina1->pagina0.
        output "editor.rom"

CHGMOD  equ 0x005F
GRPPRT  equ 0x008D
FORCLR  equ 0xF3E9
GRPACX  equ 0xFCB7
GRPACY  equ 0xFCB9
RG1SAV  equ 0xF3E0
BAKCLR  equ 0xF3EA

MAPW    equ 128
MAPH    equ 12
MAP     equ 0xC000              ; MAPW*MAPH = 1536 byte
V       equ 0xC800
P       equ 0xC840              ; tabella parametri VDP (15 byte)
v_curx  equ V+0
v_cury  equ V+1
v_scrx  equ V+2
v_tile  equ V+3
v_pick  equ V+4
v_pcur  equ V+5
v_rep   equ V+6
v_held  equ V+7
v_prev2 equ V+8
v_prev4 equ V+9
v_prev7 equ V+10
v_prev8 equ V+11
v_k8    equ V+12
v_k5    equ V+13
v_e2    equ V+14
v_e4    equ V+15
v_e7    equ V+16
v_e8    equ V+17
v_frame equ V+18
v_bcol  equ V+19
v_redr  equ V+20
v_dirty equ V+21
v_nosp  equ V+22

        org 0x4000
        db "AB"
        dw start,0,0,0,0,0,0

start:  di
        ld sp,0xF380
        ld a,5
        call CHGMOD
        di
        ld a,0x80               ; 212 righe
        ld e,9
        call wrreg
        ld a,0x28               ; TP=1: il colore 0 e' un colore vero (non trasparente)
        ld e,8
        call wrreg
        ld a,(RG1SAV)
        or 2                    ; sprite 16x16
        ld e,1
        call wrreg
        ld a,0xEC               ; tabella attributi sprite = 0x7600
        ld e,5
        call wrreg
        ld a,0x0F               ; generatore sprite = 0x7800
        ld e,6
        call wrreg
        xor a
        ld e,11
        call wrreg
        ; palette
        xor a
        ld e,16
        call wrreg
        ld hl,palette
        ld bc,0x209A
        otir
        ; schermo nero
        ld hl,p_clear
        call vdp_cmd
        call upload_tiles
        call init_sprite
        ; mappa: vuota con una riga di terra erbosa in fondo
        ld hl,MAP
        ld de,MAP+1
        ld bc,MAPW*MAPH-1
        ld (hl),0
        ldir
        ld hl,MAP+(MAPH-1)*MAPW
        ld b,MAPW
        ld a,T_GRASS
mapfl:  ld (hl),a
        inc hl
        djnz mapfl
        ; variabili
        ld hl,V
        ld de,V+1
        ld bc,31
        ld (hl),0
        ldir
        ld a,T_GRASS
        ld (v_tile),a
        ld a,15
        ld (v_bcol),a
        ld a,10
        ld (v_cury),a
        call redraw_map
        call sprite_update
        call draw_status

; ------------------------------------------------------------------------- ciclo principale
main:   call vwait
        ld hl,v_frame
        inc (hl)
        ld a,(hl)
        and 0x0F
        call z,blink
        ld a,8
        call readrow
        cpl
        ld (v_k8),a
        ld a,5
        call readrow
        cpl
        ld (v_k5),a
        ld a,2
        ld hl,v_prev2
        call edge
        ld (v_e2),a
        ld a,4
        ld hl,v_prev4
        call edge
        ld (v_e4),a
        ld a,7
        ld hl,v_prev7
        call edge
        ld (v_e7),a
        ld a,8
        ld hl,v_prev8
        call edge
        ld (v_e8),a
        ; TAB apre/chiude l'elenco, ESC lo chiude
        ld a,(v_e7)
        bit 3,a
        jp nz,toggle_picker
        bit 2,a
        jr z,nopk
        ld a,(v_pick)
        or a
        jp nz,toggle_picker
nopk:   ld a,(v_pick)
        or a
        jp nz,picker_logic

; ------------------------------------------------------------------------- modalita' modifica
        call get_move           ; B=dx C=dy
        ld a,b
        or c
        jr z,nomove
        ld a,(v_curx)
        add a,b
        cp MAPW
        jr nc,skx
        ld (v_curx),a
skx:    ld a,(v_cury)
        add a,c
        cp MAPH
        jr nc,sky
        ld (v_cury),a
sky:    ld a,(v_curx)           ; scorrimento orizzontale
        ld hl,v_scrx
        cp (hl)
        jr nc,chkr
        ld (hl),a
        jr dored
chkr:   sub 15
        jr c,nosc
        cp (hl)
        jr c,nosc
        jr z,nosc
        ld (hl),a
dored:  ld a,1
        ld (v_redr),a
nosc:   ld a,1
        ld (v_dirty),a
nomove: ld a,(v_k8)
        bit 0,a
        jr nz,spc
        xor a
        ld (v_nosp),a
        jr nospc
spc:    ld a,(v_nosp)
        or a
        jr nz,nospc
        ld a,(v_tile)
        call place
nospc:  ld a,(v_k8)
        bit 3,a                 ; DEL
        jr nz,erase
        ld a,(v_k5)
        bit 5,a                 ; X
        jr z,noerase
erase:  xor a
        call place
noerase:
        ld a,(v_e2)
        bit 2,a                 ; ,
        jr z,nprev
        ld a,(v_tile)
        or a
        jr nz,pv1
        ld a,T_COUNT
pv1:    dec a
        ld (v_tile),a
        ld a,1
        ld (v_dirty),a
nprev:  ld a,(v_e2)
        bit 3,a                 ; .
        jr z,nnext
        ld a,(v_tile)
        inc a
        cp T_COUNT
        jr c,nx1
        xor a
nx1:    ld (v_tile),a
        ld a,1
        ld (v_dirty),a
nnext:  ld a,(v_e4)
        bit 5,a                 ; P
        jr z,nopick
        call cur_addr
        ld a,(hl)
        ld (v_tile),a
        ld a,1
        ld (v_dirty),a
nopick: ld a,(v_redr)
        or a
        jr z,nor
        xor a
        ld (v_redr),a
        call redraw_map
nor:    call sprite_update
        ld a,(v_dirty)
        or a
        jp z,main
        xor a
        ld (v_dirty),a
        call draw_status
        jp main

; ------------------------------------------------------------------------- modalita' elenco blocchi
picker_logic:
        call get_move
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        add a,b
        ld d,a
        or a
        jr z,pnomv
        ld a,(v_pcur)
        add a,d
        cp T_COUNT
        jr nc,pnomv
        ld (v_pcur),a
        ld a,1
        ld (v_dirty),a
pnomv:  ld a,(v_e8)
        bit 0,a
        jr nz,pselect
        ld a,(v_e7)
        bit 7,a
        jr z,pdone
pselect:
        ld a,(v_pcur)
        ld (v_tile),a
        ld a,1
        ld (v_nosp),a
        jp toggle_picker
pdone:  call sprite_update
        ld a,(v_dirty)
        or a
        jp z,main
        xor a
        ld (v_dirty),a
        call draw_status
        jp main

toggle_picker:
        ld a,(v_pick)
        xor 1
        ld (v_pick),a
        jr z,tpclose
        ld a,(v_tile)
        ld (v_pcur),a
        call draw_picker
        jr tpend
tpclose:
        call redraw_map
tpend:  call sprite_update
        call draw_status
        xor a
        ld (v_dirty),a
        jp main

draw_picker:
        ld hl,p_pick
        call vdp_cmd
        ld d,0
dpl:    ld a,d
        and 15
        ld b,a
        ld a,d
        rrca
        rrca
        rrca
        rrca
        and 15
        ld c,a
        ld a,d
        push de
        call draw_tile
        pop de
        inc d
        ld a,d
        cp T_COUNT
        jr nz,dpl
        ret

; ------------------------------------------------------------------------- mappa
; indirizzo in RAM della cella sotto il cursore -> HL
cur_addr:
        ld a,(v_cury)
        ld h,a
        ld l,0
        srl h
        rr l
        ld de,MAP
        add hl,de
        ld a,(v_curx)
        ld e,a
        ld d,0
        add hl,de
        ret

; piazza il tile A nella cella del cursore
place:  ld c,a
        call cur_addr
        ld a,(hl)
        cp c
        ret z
        ld (hl),c
        ld a,(v_curx)
        ld hl,v_scrx
        sub (hl)
        ld b,a
        ld e,c
        ld a,(v_cury)
        ld c,a
        ld a,e
        jp draw_tile

; tile della mappa in colonna schermo B, riga C -> A
get_tile:
        ld h,c
        ld l,0
        srl h
        rr l
        ld de,MAP
        add hl,de
        ld a,(v_scrx)
        add a,b
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        ret

redraw_map:
        ld c,0
rmr:    ld b,0
rmc:    push bc
        call get_tile
        call draw_tile
        pop bc
        inc b
        ld a,b
        cp 16
        jr nz,rmc
        inc c
        ld a,c
        cp MAPH
        jr nz,rmr
        ret

; disegna il tile A in colonna B, riga C (celle da 16x16 su pagina 0)
draw_tile:
        ld e,a
        and 15
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+0),a              ; SX
        xor a
        ld (P+1),a
        ld a,e
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+2),a              ; SY (pagina 1: +256)
        ld a,1
        ld (P+3),a
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+4),a              ; DX
        xor a
        ld (P+5),a
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+6),a              ; DY
        xor a
        ld (P+7),a
        ld a,16
        ld (P+8),a              ; NX
        xor a
        ld (P+9),a
        ld a,16
        ld (P+10),a             ; NY
        xor a
        ld (P+11),a
        ld (P+12),a
        ld (P+13),a
        ld a,0xD0               ; HMMM
        ld (P+14),a
        ld hl,P
        jp vdp_cmd

; ------------------------------------------------------------------------- input
; riga della matrice tastiera A -> A (0 = tasto premuto)
readrow:
        ld b,a
        in a,(0xAA)
        and 0xF0
        or b
        out (0xAA),a
        in a,(0xA9)
        ret

; fronti di salita: A = riga, HL = indirizzo del valore precedente -> A = tasti appena premuti
edge:   push hl
        call readrow
        pop hl
        cpl
        ld b,a
        ld a,(hl)
        cpl
        and b
        ld c,a
        ld (hl),b
        ld a,c
        ret

; movimento con ripetizione: B = dx, C = dy (0, 1, 255)
get_move:
        ld a,(v_k8)
        and 0xF0
        jr nz,gmh
        xor a
        ld (v_rep),a
        ld (v_held),a
        ld b,a
        ld c,a
        ret
gmh:    ld a,(v_rep)
        or a
        jr z,gmgo
        dec a
        ld (v_rep),a
        ld bc,0
        ret
gmgo:   ld a,(v_held)
        or a
        ld a,10
        jr z,gms
        ld a,3
gms:    ld (v_rep),a
        ld a,1
        ld (v_held),a
        ld a,(v_k8)
        ld b,0
        ld c,0
        bit 4,a
        jr z,gm1
        ld b,0xFF
gm1:    bit 7,a
        jr z,gm2
        ld b,1
gm2:    bit 5,a
        jr z,gm3
        ld c,0xFF
gm3:    bit 6,a
        ret z
        ld c,1
        ret

; ------------------------------------------------------------------------- sprite cursore
init_sprite:
        ld hl,0x7800
        call vram_w
        ld hl,spat
        ld bc,0x2098
        otir
        ld hl,0x7400
        call vram_w
        ld a,15
        ld b,16
isc:    out (0x98),a
        djnz isc
        ret

blink:  ld a,(v_bcol)
        xor 15^12
        ld (v_bcol),a
        ld hl,0x7400
        call vram_w
        ld a,(v_bcol)
        ld b,16
bl1:    out (0x98),a
        djnz bl1
        ret

sprite_update:
        ld a,(v_pick)
        or a
        jr nz,supk
        ld a,(v_curx)
        ld hl,v_scrx
        sub (hl)
        ld b,a
        ld a,(v_cury)
        ld c,a
        jr suw
supk:   ld a,(v_pcur)
        and 15
        ld b,a
        ld a,(v_pcur)
        rrca
        rrca
        rrca
        rrca
        and 15
        ld c,a
suw:    ld hl,0x7600
        call vram_w
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        dec a
        out (0x98),a            ; Y
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,a
        out (0x98),a            ; X
        xor a
        out (0x98),a            ; pattern 0
        out (0x98),a
        ld a,216                ; fine lista sprite
        out (0x98),a
        ret

; ------------------------------------------------------------------------- barra di stato
draw_status:
        ld hl,p_stat
        call vdp_cmd
        ld a,15
        ld (FORCLR),a
        ld a,1
        ld (BAKCLR),a
        ld hl,2
        ld (GRPACX),hl
        ld hl,194
        ld (GRPACY),hl
        ld a,(v_pick)
        or a
        ld a,(v_tile)
        jr z,dst1
        ld a,(v_pcur)
dst1:   ld e,a
        call print_num2
        ld a,' '
        call print_char
        ; nome
        ld l,e
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld d,h
        ld e,l
        add hl,hl
        add hl,de               ; *24
        ld de,tile_names
        add hl,de
        call print_str
        ld hl,2
        ld (GRPACX),hl
        ld hl,203
        ld (GRPACY),hl
        ld hl,s_x
        call print_str
        ld a,(v_curx)
        call print_num3
        ld hl,s_y
        call print_str
        ld a,(v_cury)
        call print_num2
        ld hl,s_help
        jp print_str

print_char:
        push bc
        push de
        push hl
        call GRPPRT
        di
        pop hl
        pop de
        pop bc
        ret

print_str:
        ld a,(hl)
        or a
        ret z
        inc hl
        push hl
        call print_char
        pop hl
        jr print_str

print_num3:
        ld b,100
        call pnd
print_num2x:
        ld b,10
        call pnd
        add a,'0'
        jp print_char
print_num2:
        ld b,10
        call pnd
        add a,'0'
        jp print_char
pnd:    ld c,'0'-1
pnl:    inc c
        sub b
        jr nc,pnl
        add a,b
        push af
        ld a,c
        call print_char
        pop af
        ret

; ------------------------------------------------------------------------- VDP
wrreg:  out (0x99),a
        ld a,e
        or 0x80
        out (0x99),a
        ret

vwait:  in a,(0x99)
vwl:    in a,(0x99)
        rlca
        jr nc,vwl
        ret

vdp_wait:
        ld a,2
        out (0x99),a
        ld a,0x8F
        out (0x99),a
vwc:    in a,(0x99)
        rrca
        jr c,vwc
        xor a
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        ret

; esegue il comando VDP descritto da 15 byte in (HL), a partire da R#32
vdp_cmd:
        call vdp_wait
        ld a,32
        out (0x99),a
        ld a,0x91
        out (0x99),a
        ld bc,0x0F9B
        otir
        ret

; imposta l'indirizzo VRAM di scrittura HL (bit 16 = 0)
vram_w: ld a,h
        rlca
        rlca
        and 3
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        ld a,l
        out (0x99),a
        ld a,h
        and 0x3F
        or 0x40
        out (0x99),a
        ret

; copia il tileset in pagina 1 di VRAM: tile t in (t%16*16, 256+t/16*16)
upload_tiles:
        ld hl,tiles
        xor a
        ld (V+0x30),a
utt:    ld a,(V+0x30)
        ld c,a
        and 15
        add a,a
        add a,a
        add a,a
        ld e,a
        ld a,c
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,a
        add a,a
        add a,a
        add a,0x80
        ld d,a
        ld b,16
utr:    push bc
        push de
        push hl
        ex de,hl
        call vram_w
        pop hl
        ld bc,0x0898
        otir
        pop de
        ld a,128
        add a,e
        ld e,a
        jr nc,utn
        inc d
utn:    pop bc
        djnz utr
        ld a,(V+0x30)
        inc a
        ld (V+0x30),a
        cp T_COUNT
        jr nz,utt
        ret

; ------------------------------------------------------------------------- dati
p_clear: db 0,0,0,0, 0,0,0,0, 0,1, 212,0, 0x11,0,0xC0
p_stat:  db 0,0,0,0, 0,0,192,0, 0,1, 20,0, 0x11,0,0xC0
p_pick:  db 0,0,0,0, 0,0,0,0, 0,1, 64,0, 0x11,0,0xC0
s_x:     db "X:",0
s_y:     db " Y:",0
s_help:  db "  ,.=tile TAB=elenco",0
; cursore 16x16: cornice spessa 2 pixel (UL, LL, UR, LR)
spat:    db 0xFF,0xFF,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0
         db 0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,0xFF,0xFF
         db 0xFF,0xFF,0x03,0x03,0x03,0x03,0x03,0x03
         db 0x03,0x03,0x03,0x03,0x03,0x03,0xFF,0xFF
palette: incbin "../assets/palette.bin"
tiles:   incbin "../assets/tiles.bin"
        include "../assets/tileset.inc"
        include "../assets/tilenames.inc"
        ds 0xC000-$,0xFF
