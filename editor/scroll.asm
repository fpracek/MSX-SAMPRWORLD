; scroll.asm - scorrimento a pagine per MSX2 puro (V9938: niente R#26/R#27): doppio buffer su pagine 0/1.
; Il tileset sta nelle righe 192.. della pagina 3 (y=960..). Ogni passo di camera (2 o 4 px, sempre pari: HMMM lavora a byte):
;   1) HMMM asincrona dell'intera area di gioco (256x192) dalla pagina visibile a quella nascosta, spostata di d px
;   2) le colonne scoperte (striscia a destra o a sinistra) si disegnano dalla cache tile, cella per cella
;   3) al vblank successivo si scambia la pagina (R#2).
; La copia a schermo intero costa ~28 ms in emulazione (misurato, spikes/hmmm): si lavora a ~30 passi/s mentre
; fisica e sprite hardware girano a ogni frame. Gli sprite sono hardware: nessun ripristino dello sfondo.
; Barra di stato (righe 192..211) copiata su entrambe le pagine a ogni aggiornamento.

p_cam   equ V+0xC0              ; 2 byte: camera (px) della pagina visibile
p_camh  equ V+0xC2              ; 2 byte: camera della pagina nascosta (in preparazione)
p_page  equ V+0xC4              ; pagina visibile (0/1)
p_job   equ V+0xC5              ; 0 = libero, 1 = copia in corso, 2 = pronto per lo scambio
p_nd    equ V+0xC6              ; celle da riapplicare alla pagina nascosta
p_dirty equ V+0xC7              ; 4 coppie (colonna,riga)
p_d     equ V+0xCF              ; 2 byte: passo di camera (con segno)
bc_x    equ V+0xD1              ; 2 byte: x cella + 16
bc_w0   equ V+0xD3              ; 2 byte: finestra + 16
bc_w1   equ V+0xD5
bc_v0   equ V+0xD7
bc_v1   equ V+0xD9
bc_t    equ V+0xDB
bc_r    equ V+0xDC
bc_pg   equ V+0xDD
bs_c    equ V+0xDE              ; colonna corrente
bs_c1   equ V+0xDF
bs_r    equ V+0xE0
bs_cam  equ V+0xE1              ; 2 byte
bo_col  equ V+0xE3
bo_row  equ V+0xE4

; VDP occupato? NZ se un comando e' in corso
vdp_busy:
        ld a,2
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        in a,(0x99)
        and 1
        push af
        xor a
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        pop af
        ret

; ---- una cella: tile A in riga bc_r, x biased bc_x, pagina bc_pg, finestra bc_w0..bc_w1 (biased +16) ----
blit_cell:
        ld (bc_t),a
        ld hl,(bc_x)            ; vis0 = max(x, w0)
        ld de,(bc_w0)
        or a
        sbc hl,de
        ld hl,(bc_x)
        jr nc,bcv0
        ld hl,(bc_w0)
bcv0:   ld (bc_v0),hl
        ld hl,(bc_x)            ; vis1 = min(x+16, w1)
        ld de,16
        add hl,de
        ld de,(bc_w1)
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,bcv1
        ex de,hl
bcv1:   ld (bc_v1),hl
        ld de,(bc_v0)
        or a
        sbc hl,de
        ret z
        ret c
        ld a,l
        ld (P+8),a              ; NX
        xor a
        ld (P+9),a
        ld hl,(bc_v0)
        ld de,16
        or a
        sbc hl,de
        ld a,l
        ld (P+4),a              ; DX = vis0 - 16
        ld a,h
        ld (P+5),a
        ld hl,(bc_v0)
        ld de,(bc_x)
        or a
        sbc hl,de
        ld c,l                  ; scarto dentro la cella
        ld a,(bc_t)
        and 15
        add a,a
        add a,a
        add a,a
        add a,a
        add a,c
        ld (P+0),a              ; SX
        xor a
        ld (P+1),a
        ld a,(bc_t)
        call tile_sy            ; SY dalla tabella delle righe del tileset (editor.asm)
        ld a,l
        ld (P+2),a
        ld a,h
        ld (P+3),a
        ld a,(bc_r)
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+6),a              ; DY = riga*16 + pagina*256
        ld a,(bc_pg)
        ld (P+7),a
        ld a,16
        ld (P+10),a
        xor a
        ld (P+11),a
        ld (P+12),a
        ld (P+13),a
        ld a,0xD0
        ld (P+14),a
        ld hl,P
        jp vdp_cmd

; colonne bs_c..bs_c1 (tutte le 12 righe) per camera bs_cam, pagina bc_pg, finestra bc_w0/w1
blit_cols:
bcl_c:  ld a,(bs_c)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,(bs_cam)
        or a
        sbc hl,de
        ld de,16
        add hl,de
        ld (bc_x),hl
        xor a
        ld (bs_r),a
bcl_r:  ld a,(bs_r)
        ld (bc_r),a
        ld h,a
        ld l,0
        srl h
        rr l
        ld de,MAP
        add hl,de
        ld a,(bs_c)
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        call blit_cell
        ld a,(bs_r)
        inc a
        ld (bs_r),a
        cp MAPH
        jr nz,bcl_r
        ld a,(bs_c)
        ld hl,bs_c1
        cp (hl)
        ret z
        inc a
        ld (bs_c),a
        jr bcl_c

; ridisegna tutta la vista: HL = camera, A = pagina
redraw_view:
        ld (bc_pg),a
        ld (bs_cam),hl
        ld de,16
        ld (bc_w0),de
        ld de,272
        ld (bc_w1),de
        call cam_cols_all
        jp blit_cols

cam_cols_all:                   ; bs_c = cam/16, bs_c1 = (cam+255)/16
        ld hl,(bs_cam)
        call div16
        ld (bs_c),a
        ld hl,(bs_cam)
        ld de,255
        add hl,de
        call div16
        ld (bs_c1),a
        ret
div16:  srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        ld a,l
        ret

; una cella (bo_col, bo_row) con camera HL su pagina A; se fuori vista non fa nulla
blit_one:
        ld (bc_pg),a
        ld a,(bo_col)
        ld e,a
        ld d,0
        push hl
        ex de,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; col*16
        pop de                  ; camera
        or a
        sbc hl,de
        ld de,16
        add hl,de               ; x + 16
        bit 7,h
        ret nz
        push hl
        ld de,272
        or a
        sbc hl,de
        pop hl
        ret nc
        ld (bc_x),hl
        ld de,16
        ld (bc_w0),de
        ld de,272
        ld (bc_w1),de
        ld a,(bo_row)
        ld (bc_r),a
        ld h,a
        ld l,0
        srl h
        rr l
        ld de,MAP
        add hl,de
        ld a,(bo_col)
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        jp blit_cell

; una cella e' cambiata (raccolta): aggiorna la pagina visibile e, se serve, quella nascosta
cell_changed:
        ld a,(p_ring)
        or a
        jp nz,ring_cell
        ld hl,(p_cam)
        ld a,(p_page)
        call blit_one
        ld a,(p_job)
        cp 1
        jr z,cc_push
        cp 2
        ret nz
        ld hl,(p_camh)          ; copia gia' pronta: aggiorna subito anche quella
        ld a,(p_page)
        xor 1
        jp blit_one
cc_push:
        ld a,(p_nd)
        cp 4
        ret nc
        add a,a
        ld e,a
        ld d,0
        ld hl,p_dirty
        add hl,de
        ld a,(bo_col)
        ld (hl),a
        inc hl
        ld a,(bo_row)
        ld (hl),a
        ld hl,p_nd
        inc (hl)
        ret

apply_dirty:
        ld a,(p_nd)
        or a
        ret z
        ld hl,p_dirty
ad_l:   push hl
        ld a,(hl)
        ld (bo_col),a
        inc hl
        ld a,(hl)
        ld (bo_row),a
        ld hl,(p_camh)
        ld a,(p_page)
        xor 1
        call blit_one
        pop hl
        inc hl
        inc hl
        ld a,(p_nd)
        dec a
        ld (p_nd),a
        jr nz,ad_l
        ret

; ---- scambio pagina (subito dopo il vblank) + sprite con la nuova camera ----
scroll_flip:
        ld a,(p_job)
        cp 2
        ret nz
        ld a,(p_page)
        xor 1
        ld (p_page),a
        ld e,2
        ld a,0x1F
        jr z,sf_w
        ld a,0x3F
sf_w:   call wrreg              ; R#2: pagina visibile
        ld hl,(p_camh)
        ld (p_cam),hl
        xor a
        ld (p_job),a
        jp play_sprite          ; l'eroe cambia posizione sullo schermo nello stesso vblank

; ---- scorrimento a passi da 8 px (16 px se l'eroe e' lontano dal centro) ----
; Ogni passo: HMMM asincrona dell'area di gioco dalla pagina visibile a quella nascosta spostata di |d| px, poi si
; disegnano le colonne di tile scoperte e al vblank si scambia la pagina. La copia costa ~100 ms sul V9938 (docs/SCROLL.md):
; con passi da 8 px la camera arriva a ~0,75 px/frame, con passi da 16 px a ~1,45 px/frame (l'eroe corre a 1,5):
; quando l'eroe e' molto avanti rispetto al centro si passa ai passi grandi per recuperare. Eroe, nemici e fisica a 60 Hz.
scroll_update:
        ld a,(p_job)
        or a
        jp z,su_idle
        cp 1
        ret nz                  ; 2 = pronta, attende il vblank per lo scambio
        call vdp_busy
        ret nz                  ; copia ancora in corso
        ld a,(p_page)           ; colonne scoperte, sulla pagina nascosta
        xor 1
        ld (bc_pg),a
        ld hl,(p_camh)
        ld (bs_cam),hl
        ld hl,(p_d)
        bit 7,h
        jr nz,ss_l
        ld hl,272               ; passo a destra: finestra [256-d, 256) (bias +16)
        ld de,(p_d)
        or a
        sbc hl,de
        ld (bc_w0),hl
        ld hl,272
        ld (bc_w1),hl
        ld hl,(bs_cam)
        ld de,256
        add hl,de
        ld de,(p_d)
        or a
        sbc hl,de
        call div16
        ld (bs_c),a
        ld hl,(bs_cam)
        ld de,255
        add hl,de
        call div16
        ld (bs_c1),a
        jr ss_go
ss_l:   ld hl,(p_d)             ; passo a sinistra: finestra [0, |d|)
        call neg_hl
        push hl
        ld de,16
        add hl,de
        ld (bc_w1),hl
        ld hl,16
        ld (bc_w0),hl
        ld hl,(bs_cam)
        call div16
        ld (bs_c),a
        pop hl
        dec hl
        ld de,(bs_cam)
        add hl,de
        call div16
        ld (bs_c1),a
ss_go:  call blit_cols
        call apply_dirty
        ld a,2
        ld (p_job),a
        ret
su_idle:
        ld hl,(p_x)
        ld de,(p_cam)
        or a
        sbc hl,de               ; x dell'eroe sullo schermo
        bit 7,h
        jr nz,su_fl
        ld a,h
        or a
        jr nz,su_fr
        ld a,l
        cp 176
        jr nc,su_fr             ; molto avanti: passo grande
        cp 128
        jr nc,su_r8
        cp 80
        ret nc                  ; fascia centrale: la camera sta ferma
        cp 48
        jr c,su_fl
        ld hl,-8
        jr su_l
su_fl:  ld hl,-16
        jr su_l
su_fr:  ld hl,16
        jr su_r
su_r8:  ld hl,8
su_r:   ld (p_d),hl
        ld hl,(p_cam)
        ld de,MAPW*16-256
        or a
        sbc hl,de               ; camera - massimo (negativo se c'e' spazio)
        ret nc
        call neg_hl
        ex de,hl                ; DE = spazio rimasto
        ld hl,(p_d)
        or a
        sbc hl,de
        jr c,su_ok
        ld (p_d),de             ; passo piu' grande dello spazio: si riduce
        jr su_ok
su_l:   ld (p_d),hl
        ld hl,(p_cam)
        ld a,h
        or l
        ret z
        ld de,(p_d)
        add hl,de
        bit 7,h
        jr z,su_ok
        ld hl,(p_cam)           ; passo piu' grande dello spazio: si riduce
        call neg_hl
        ld (p_d),hl
su_ok:  ld hl,(p_d)
        ld de,(p_cam)
        add hl,de
        ld (p_camh),hl
        ld hl,(p_d)             ; parametri della copia: sorgente x = d (o 0), destinazione x = 0 (o |d|), larghezza 256-|d|
        ld a,l
        bit 7,h
        jr z,su_pos
        neg
        ld c,a
        xor a
        ld (P+0),a
        ld a,c
        ld (P+4),a
        jr su_nx
su_pos: ld c,a
        ld (P+0),a
        xor a
        ld (P+4),a
su_nx:  xor a
        ld (P+1),a
        ld (P+2),a
        ld (P+5),a
        ld (P+6),a
        ld (P+9),a
        ld a,c
        neg
        ld (P+8),a
        ld a,(p_page)
        ld (P+3),a
        xor 1
        ld (P+7),a
        ld a,192
        ld (P+10),a
        xor a
        ld (P+11),a
        ld (P+12),a
        ld (P+13),a
        ld a,0xD0
        ld (P+14),a
        ld hl,P
        call vdp_cmd            ; parte in background
        ld a,1
        ld (p_job),a
        ret

; barra di stato: la copia della pagina 0 sulla pagina 1 (righe 192..211)
status_copy:
        ld hl,p_scopy
        jp vdp_cmd
p_scopy: db 0,0, 192,0, 0,0, 0xC0,1, 0,1, 20,0, 0,0,0xD0
