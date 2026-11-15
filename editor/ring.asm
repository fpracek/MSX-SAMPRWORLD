; ring.asm - scorrimento orizzontale HARDWARE sul V9958 (MSX2+): registri R#26 (blocchi da 8 px) e R#27 (0-7 px).
; La pagina 0 e' un anello di 256 px: la colonna del mondo w sta alla x = w mod 256; a ogni frame si disegnano solo le colonne
; che entrano (qualche pixel) e si aggiornano i registri di scroll nel vblank: scorrimento fluido a 60 Hz, nessuna copia
; a schermo intero. R#25 MSK nasconde gli 8 px a sinistra (dove il fine-scroll mostra la colonna di ritorno dell'anello e dove
; avvengono le sostituzioni durante lo scorrimento verso destra). La barra di stato non puo' stare sullo schermo (scorrerebbe
; con la mappa): in questa modalita' lo schermo e' di 192 righe e il punteggio e' fatto di sprite (HUD).
; Sul V9938 (MSX2) si usa scroll.asm (passi con copia HMMM).
p_ring  equ FBUF+0xC4           ; 1 = V9958 rilevato
r_lo    equ FBUF+0xC5           ; 2 byte: x del mondo della prima colonna valida dell'anello
r_nlo   equ FBUF+0xC7           ; 2 byte
r_a     equ FBUF+0xC9           ; 2 byte: segmento da disegnare [a, e)
r_e     equ FBUF+0xCB           ; 2 byte
r_c     equ FBUF+0xCD           ; colonna di tile corrente
r_r0    equ FBUF+0xCE           ; righe da disegnare r0..r1
r_r1    equ FBUF+0xCF
hudbuf  equ FBUF+0xE0           ; 32 byte: pattern di due cifre
H_ICON  equ 180                 ; numeri di pattern degli sprite HUD: icone 180,184,188; cifre 192,196,200
H_DIG   equ 192

; ID del VDP dal registro di stato S#1 (bit 5-1): 0 = V9938, 2 = V9958
detect_vdp:
        ld a,1
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        in a,(0x99)
        push af
        xor a
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        pop af
        rrca
        and 0x1F
        cp 2
        ld a,0
        jr nz,dv_s
        inc a
dv_s:   ld (p_ring),a
        ret

ring_on:                        ; inizio prova: 192 righe, MSK, scroll a zero
        xor a
        ld e,9
        call wrreg
        ld a,0x02
        ld e,25
        call wrreg
        xor a
        ld e,26
        call wrreg
        xor a
        ld e,27
        jp wrreg

ring_off:                       ; fine prova: tutto come nell'editor
        ld a,0x80
        ld e,9
        call wrreg
        xor a
        ld e,25
        call wrreg
        xor a
        ld e,26
        call wrreg
        xor a
        ld e,27
        jp wrreg

; HL = camera (px) -> R#27 = (8 - cam%8) % 8, R#26 = ((cam%256) + 7) / 8
ring_setregs:
        ld a,l
        and 7
        ld b,a
        ld a,8
        sub b
        and 7
        ld e,27
        call wrreg
        ld h,0                  ; HL = cam & 255
        ld de,7
        add hl,de
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        ld a,l
        ld e,26
        jp wrreg

; riempie l'anello per la camera HL
ring_fill:
        ld (p_cam),hl
        push hl
        inc hl
        res 0,l
        ld (r_lo),hl
        ld de,256
        ld b,h
        ld c,l
        add hl,de
        ld d,b
        ld e,c                  ; DE = lo, HL = lo+256
        xor a
        ld (r_r0),a
        ld a,MAPH-1
        ld (r_r1),a
        call ring_strip
        pop hl
        jp ring_setregs

; un passo di camera (nuova camera in HL, differenza <= 7 px)
ring_move:
        ld (p_cam),hl
        push hl
        call ring_setregs
        pop hl
        inc hl
        res 0,l
        ld (r_nlo),hl
        ld de,(r_lo)
        or a
        sbc hl,de
        jr z,rm_end
        xor a
        ld (r_r0),a
        ld a,MAPH-1
        ld (r_r1),a
        bit 7,h
        jr nz,rm_left
        ld hl,(r_lo)            ; verso destra: [lo+256, lo'+256)
        ld de,256
        add hl,de
        ex de,hl
        ld hl,(r_nlo)
        ld bc,256
        add hl,bc
        call ring_strip
        jr rm_end
rm_left:
        ld de,(r_nlo)           ; verso sinistra: [lo', lo)
        ld hl,(r_lo)
        call ring_strip
rm_end: ld hl,(r_nlo)
        ld (r_lo),hl
        ret

; segue l'eroe: obiettivo = x - 112, entro il livello; passo 1..6 px
ring_frame:
        ld hl,(p_x)
        ld de,112
        or a
        sbc hl,de
        bit 7,h
        jr z,rf_p
        ld hl,0
rf_p:   push hl
        ld de,MAPW*16-256
        or a
        sbc hl,de
        pop hl
        jr c,rf_c
        ld hl,MAPW*16-256
rf_c:   ld de,(p_cam)
        or a
        sbc hl,de               ; differenza obiettivo - camera
        bit 7,h
        jr nz,rf_neg
        ld a,h
        or a
        ld b,6
        jr nz,rf_up
        ld a,l
        cp 13
        ret c                   ; entro la zona morta: la camera sta ferma
        sub 12
        srl a
        srl a
        inc a
        cp 7
        jr c,rf_s
        ld a,6
rf_s:   ld b,a
rf_up:  ld hl,(p_cam)
        ld e,b
        ld d,0
        add hl,de
        jp ring_move
rf_neg: call neg_hl
        ld a,h
        or a
        ld b,6
        jr nz,rf_dn
        ld a,l
        cp 13
        ret c
        sub 12
        srl a
        srl a
        inc a
        cp 7
        jr c,rf_s2
        ld a,6
rf_s2:  ld b,a
rf_dn:  ld hl,(p_cam)
        ld e,b
        ld d,0
        or a
        sbc hl,de
        jp ring_move

; riposizionamento (riavvio/checkpoint): camera sull'eroe, anello riempito da zero
ring_respawn_cam:
        ld hl,(p_x)
        ld de,112
        or a
        sbc hl,de
        bit 7,h
        jr z,rr_p
        ld hl,0
rr_p:   push hl
        ld de,MAPW*16-256
        or a
        sbc hl,de
        pop hl
        jr c,rr_c
        ld hl,MAPW*16-256
rr_c:   call ring_fill
        xor a
        ld (p_page),a
        ld (p_job),a
        ld (p_nd),a
        ret

; ---- disegno di una striscia di mondo [DE, HL) per le righe r0..r1 ----
ring_strip:
        ld (r_a),de
        ld (r_e),hl
rs_l:   ld hl,(r_a)
        ld de,(r_e)
        or a
        sbc hl,de
        ret nc                  ; a >= e: finito
        ld hl,(r_a)
        ld l,255
        inc hl                  ; prossimo confine dell'anello
        ld de,(r_e)
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,rs_s
        ex de,hl                ; il confine e' oltre e: si usa e
rs_s:   push hl
        call ring_seg           ; segmento [a, hl) senza attraversare il confine dell'anello
        pop hl
        ld (r_a),hl
        jr rs_l

; segmento [r_a, segend) con segend in HL (sullo stesso giro dell'anello)
ring_seg:
        ld (r_e),hl
        ld a,(r_a)
        ld l,a
        ld h,0
        ld de,16
        add hl,de
        ld (bc_w0),hl           ; finestra (bias +16) = x dell'anello + 16
        ld hl,(r_e)
        ld de,(r_a)
        or a
        sbc hl,de
        ld de,(bc_w0)
        add hl,de
        ld (bc_w1),hl
        xor a
        ld (bc_pg),a
        ld hl,(r_a)
        call div16
        ld (r_c),a              ; prima colonna di tile
        ld hl,(r_e)
        dec hl
        call div16
        ld (bs_c1),a            ; ultima
rsg_c:  ld a,(r_c)
        and 15
        add a,a
        add a,a
        add a,a
        add a,a
        ld l,a
        ld h,0
        ld de,16
        add hl,de
        ld (bc_x),hl            ; origine della cella nell'anello (bias +16)
        ld a,(r_r0)
        ld (bs_r),a
rsg_r:  ld a,(bs_r)
        ld (bc_r),a
        ld h,a
        ld l,0
        srl h
        rr l
        ld de,MAP
        add hl,de
        ld a,(r_c)
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        call blit_cell
        ld a,(r_r1)
        ld hl,bs_r
        cp (hl)
        jr z,rsg_n
        inc (hl)
        jr rsg_r
rsg_n:  ld a,(r_c)
        ld hl,bs_c1
        cp (hl)
        ret z
        inc a
        ld (r_c),a
        jr rsg_c

; una cella (bo_col, bo_row) e' cambiata: la si ridisegna nell'anello se e' visibile
ring_cell:
        ld a,(bo_col)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; x0 = col*16
        ld de,(r_lo)
        push hl
        or a
        sbc hl,de
        pop hl
        jr nc,rc_a
        ex de,hl                ; a = max(x0, lo)
rc_a:   push hl                 ; a
        ld a,(bo_col)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,16
        add hl,de               ; x0+16
        ld de,(r_lo)
        push hl
        ld hl,256
        add hl,de
        ex de,hl                ; DE = lo+256
        pop hl
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,rc_b
        ex de,hl                ; b = min(x0+16, lo+256)
rc_b:   pop de                  ; DE = a, HL = b
        push hl
        or a
        sbc hl,de
        pop hl
        ret z
        ret c                   ; vuota
        ld a,(bo_row)
        ld (r_r0),a
        ld (r_r1),a
        jp ring_strip

; ---- HUD a sprite ----
hud_init:
        ld hl,0x7800+H_ICON*8   ; icone (3 pattern da 32 byte) dal segmento sprite
        call vram_w
        ld hl,0xA000+3072+80
        ld bc,0x6098
        otir
        ld hl,0x7400+10*16      ; colori dei piani 10-15: oro, ciano, bianco; cifre bianche
        call vram_w
        ld hl,hud_cols
        ld b,6
hi_l:   push bc
        ld a,(hl)
        inc hl
        ld b,16
hi_c:   out (0x98),a
        djnz hi_c
        pop bc
        djnz hi_l
        jp hud_update

hud_cols: db 11,15,11,15,15,15

hud_update:
        ld a,(p_coins)
        ld hl,0x7800+H_DIG*8
        call hud_pair
        ld a,(p_keys)
        ld hl,0x7800+(H_DIG+4)*8
        call hud_pair
        ld a,(p_kills)
        ld hl,0x7800+(H_DIG+8)*8
        jp hud_pair

; A = valore (0-99 mostrati), HL = indirizzo VRAM del pattern (due cifre affiancate)
h_t     equ FBUF+0xDE
h_u     equ FBUF+0xDF
hud_pair:
        push hl
        ld b,0
hp_c:   cp 100
        jr c,hp_t
        sub 100
        jr hp_c
hp_t:   cp 10
        jr c,hp_u
        sub 10
        inc b
        jr hp_t
hp_u:   ld (h_u),a
        ld a,b
        ld (h_t),a
        ld hl,hudbuf
        ld de,hudbuf+1
        ld bc,31
        ld (hl),0
        ldir
        ld a,(h_t)
        call hp_glyph
        ld de,hudbuf
        ld bc,8
        ldir
        ld a,(h_u)
        call hp_glyph
        ld de,hudbuf+16
        ld bc,8
        ldir
        pop hl
        call vram_w
        ld hl,hudbuf
        ld bc,0x2098
        otir
        ret
hp_glyph:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,0xA000+3072
        add hl,de
        ret

; attributi dei 6 sprite HUD (piani 10-15) e terminatore
hud_attr:
        ld hl,hud_tab
        ld bc,0x1898
        otir
        ld a,216
        out (0x98),a
        ret
hud_tab: db 3,14,H_ICON,0,  7,32,H_DIG,0
         db 21,14,H_ICON+4,0, 25,32,H_DIG+4,0
         db 39,14,H_ICON+8,0, 43,32,H_DIG+8,0

ring_start:
        call ring_on
        jp hud_init
