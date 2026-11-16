; hud.asm - HUD "da sala giochi" dei livelli alti (segmento 3, finestra A000; ingressi in pagina 1 in swspr.asm).
;
; Lo schermo e' di 192 righe: 8 righe di HUD in alto, 176 righe di gioco (11 righe di tile) e 8 righe di HUD in basso, come in
; Il Maniero (fuori dall'area di gioco):  1UP 000000 HI 000500 2UP 000000  /  LIFE ♥♥♥ AMMO □□□□□ KEY ⚷00.
; Le due fasce (256x8) si disegnano con il font ridefinito (hudfont.inc) nel master, pagina 3 righe 176-191 (libere perche'
; in questa modalita' il master ha solo 11 righe di tile) e a ogni fotogramma si copiano (HMMM) nella vista D ruotate della
; camera, cosi' lo scorrimento orizzontale hardware dell'anello le lascia ferme sullo schermo.
; Il gioco sta nelle righe 8-183 di ogni vista: p_voff = 8, p_vh = 176 (vedi view_geo_i).
; Punteggi: moneta 10, gemma 50, chiave 100, nemico 50, livello 1000 (BCD a 3 byte). Vite: 3 per livello; il cuore ne da' una.
LIFEMAX equ 5

; ------------------------------------------------------------------------- geometria delle viste
view_geo_i:
        ld a,(p_tall)
        or a
        jr nz,vg_t
        xor a
        ld (p_voff),a
        ld a,192
        ld (p_vh),a
        ld a,177
        ld (p_vmax),a
        ld a,MAPH-1
        ld (p_vr1),a
        ret
vg_t:   ld a,8
        ld (p_voff),a
        ld a,176
        ld (p_vh),a
        ld a,161
        ld (p_vmax),a
        ld a,10
        ld (p_vr1),a
        ld a,(h_init)
        cp 0xA5
        jr z,vg_i
        ld a,0xA5
        ld (h_init),a
        xor a
        ld (h_sc1),a
        ld (h_sc1+1),a
        ld (h_sc1+2),a
        ld (h_sc2),a
        ld (h_sc2+1),a
        ld (h_sc2+2),a
        ld (h_hi),a
        ld (h_hi+2),a
        ld a,5
        ld (h_hi+1),a           ; HI iniziale 000500
vg_i:   ld a,3
        ld (h_life),a
        ld a,3
        ld (h_dirty),a
        ret

; ------------------------------------------------------------------------- eventi di gioco (A = tile / niente)
hud_item_i:
        ld b,a
        ld a,(p_tall)
        or a
        ret z
        ld a,b
        cp T_KEY
        ld de,0x0100
        jr z,hud_add
        cp T_GEM
        ld de,0x0050
        jr z,hud_add
        cp T_POTION
        jr nz,hit_c
        ld a,(h_life)           ; il cuore da' una vita
        cp LIFEMAX
        ret nc
        inc a
        ld (h_life),a
        jr hd_b
hit_c:   ld de,0x0010
hud_add:
        ld hl,h_sc1
        ld a,(p_two)
        or a
        jr z,ha_p
        ld a,(p_cur)
        or a
        jr z,ha_p
        ld hl,h_sc2
ha_p:   push hl
        ld a,(hl)
        add a,e
        daa
        ld (hl),a
        inc hl
        ld a,(hl)
        adc a,d
        daa
        ld (hl),a
        inc hl
        ld a,(hl)
        adc a,0
        daa
        ld (hl),a
        pop hl
        ld de,h_hi              ; record: se punteggio > HI, HI = punteggio
        ld a,(de)
        sub (hl)
        inc de
        inc hl
        ld a,(de)
        sbc a,(hl)
        inc de
        inc hl
        ld a,(de)
        sbc a,(hl)
        jr nc,ha_d
        ld a,(hl)
        ld (h_hi+2),a
        dec hl
        ld a,(hl)
        ld (h_hi+1),a
        dec hl
        ld a,(hl)
        ld (h_hi),a
ha_d:   ld a,(h_dirty)
        or 1
        ld (h_dirty),a
        ret
hd_b:   ld a,(h_dirty)
        or 2
        ld (h_dirty),a
        ret

hud_kill_i:
        ld a,(p_tall)
        or a
        ret z
        ld de,0x0050
        jr hud_add

hud_win_i:
        ld a,(p_tall)
        or a
        ret z
        ld a,(p_win)            ; una sola volta (il portale puo' toccarsi con due tile)
        or a
        ret nz
        ld de,0x1000
        jr hud_add

hud_die_i:
        ld a,(p_tall)
        or a
        ret z
        ld a,(h_life)
        or a
        jr z,hdi_o
        dec a
        ld (h_life),a
        call hd_b
        ld a,(h_life)
        or a
        ret nz
hdi_o:  ld a,1                  ; game over: si torna al menu e i punteggi ripartono da zero
        ld (p_exit),a
        xor a
        ld (h_sc1),a
        ld (h_sc1+1),a
        ld (h_sc1+2),a
        ld (h_sc2),a
        ld (h_sc2+1),a
        ld (h_sc2+2),a
        ret

; ------------------------------------------------------------------------- disegno delle fasce nel master (pagina 3, righe 176-191)
; BCD a 3 byte (HL, LSB per primo) -> 6 cifre ASCII + 0 in DE
hud_num:
        inc hl
        inc hl
        ld b,3
hn_l:   ld a,(hl)
        dec hl
        push af
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,'0'
        ld (de),a
        inc de
        pop af
        and 15
        add a,'0'
        ld (de),a
        inc de
        djnz hn_l
        xor a
        ld (de),a
        ret

; riempie con il colore C (due pixel uguali) h_nrow righe del master a partire dalla riga A (pagina 3), tutta la larghezza (HMMV)
hud_fill:
        ld (h_tmp),a
        ld hl,P
        ld b,15
        xor a
hf_z:   ld (hl),a
        inc hl
        djnz hf_z
        ld a,(h_tmp)
        ld (P+6),a              ; DY = 768 + riga
        ld a,3
        ld (P+7),a
        ld a,1
        ld (P+9),a              ; NX = 256
        ld a,(h_nrow)
        ld (P+10),a
        ld a,c
        ld (P+12),a
        ld a,0xC0
        ld (P+14),a
        ld hl,P
        jp vdp_cmd

hud_draw_i:
        ld a,0xFF               ; le fasce cambiano: tutte le viste da ricopiare
        ld (h_lr),a
        ld (h_lr+1),a
        ld (h_lr+2),a
        ld a,16                 ; sfondo nero: 16 righe (le due fasce)
        ld (h_nrow),a
        ld c,0x11
        ld a,176
        call hud_fill
        call vdp_wait
        ld a,7                  ; R#14 = 7: pagina 3, riga >= 128
        di
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        call vei
        ; ---- fascia alta: 1UP 000000 HI 000500 2UP 000000
        ld hl,s_1up
        ld bc,0x0100
        ld d,1
        call hud_str
        ld hl,h_sc1
        ld de,h_buf
        push de
        call hud_num
        pop hl
        ld bc,0x0500
        ld d,0
        call hud_str
        ld hl,s_hi
        ld bc,0x0C00
        ld d,2
        call hud_str
        ld hl,h_hi
        ld de,h_buf
        push de
        call hud_num
        pop hl
        ld bc,0x0F00
        ld d,0
        call hud_str
        ld hl,s_2up
        ld bc,0x1600
        ld d,3
        call hud_str
        ld hl,h_sc2
        ld de,h_buf
        push de
        call hud_num
        pop hl
        ld bc,0x1A00
        ld d,0
        call hud_str
        ; ---- fascia bassa: LIFE cuori AMMO caselle KEY chiave nn
        ld hl,s_life
        ld bc,0x0101
        ld d,1
        call hud_str
        ld a,(h_life)
        ld b,a
        ld hl,h_buf
        or a
        jr z,hl_z
hl_h:   ld (hl),'`'
        inc hl
        djnz hl_h
hl_z:   ld (hl),0
        ld hl,h_buf
        ld bc,0x0601
        ld d,0
        call hud_str
        ld hl,s_ammo
        ld bc,0x0C01
        ld d,1
        call hud_str
        ld hl,s_box
        ld bc,0x1101
        ld d,0
        call hud_str
        ld hl,s_key
        ld bc,0x1701
        ld d,1
        call hud_str
        ld hl,s_keyi
        ld bc,0x1B01
        ld d,0
        call hud_str
        ld a,(p_keys)           ; due cifre decimali
        ld b,0
hk_t:   cp 10
        jr c,hk_u
        sub 10
        inc b
        jr hk_t
hk_u:   ld c,a
        ld a,b
        add a,'0'
        ld (h_buf),a
        ld a,c
        add a,'0'
        ld (h_buf+1),a
        xor a
        ld (h_buf+2),a
        ld hl,h_buf
        ld bc,0x1D01
        ld d,0
        call hud_str
        ; ---- filetti blu fra le fasce e il gioco (riga 7 della fascia alta, riga 0 della bassa)
        call vdp_wait
        ld a,1
        ld (h_nrow),a
        ld a,176+7
        ld c,0xEE
        ld b,0
        call hud_fill
        ld a,176+8
        ld c,0xEE
        ld b,0
        call hud_fill
        xor a
        ld (h_dirty),a
        ret

; HL = stringa, B = colonna (glifi 0-31), C = fascia (0 alta, 1 bassa), D = schema (0 bianco, 1 etichetta, 2 HI, 3 2UP)
hud_str:
        ld a,d
        add a,a
        ld e,a
        ld d,0
        push hl
        ld hl,hs_sch
        add hl,de
        ld a,(hl)
        ld (h_f1),a
        inc hl
        ld a,(hl)
        ld (h_f2),a
        pop hl
        ld a,c
        ld (h_line),a
        ld a,b
        ld (h_col),a
hs_l:   ld a,(hl)
        or a
        ret z
        inc hl
        push hl
        call hud_glyph
        ld hl,h_col
        inc (hl)
        pop hl
        jr hs_l

; schemi: riempimento righe 0-3, riempimento righe 4-7
hs_sch: db 15,15,  11,7,  9,12,  14,13

; A = codice ASCII -> glifo 8x8 alla colonna h_col della fascia h_line
hud_glyph:
        sub 32
        ld e,a
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; * 32
        ld bc,hudfont
        add hl,bc
        ld a,e
        cp 64
        ld a,0
        jr nc,hg_n
        inc a                   ; lettere: si ricolora l'indice 15
hg_n:   ld (h_rm),a
        ld a,(h_col)            ; indirizzo di riga: 0x1800 + fascia*0x400 + colonna*4
        add a,a
        add a,a
        ld e,a
        ld a,(h_line)
        or a
        ld a,0x18
        jr z,hg_a
        ld a,0x1C
hg_a:   ld d,a
        ld (h_ad),de
        ld a,8
        ld (h_rows),a
hg_r:   ld a,(h_rows)
        cp 5
        ld a,(h_f1)
        jr nc,hg_f
        ld a,(h_f2)
hg_f:   ld (h_fill),a
        ld de,(h_ad)
        ld a,e
        di
        out (0x99),a
        ld a,d
        or 0x40
        out (0x99),a
        call vei
        ld b,4
hg_b:   ld a,(hl)
        inc hl
        ld c,a
        ld a,(h_rm)
        or a
        jr z,hg_o
        ld a,c
        rrca
        rrca
        rrca
        rrca
        and 15
        cp 15
        jr nz,hg_hi
        ld a,(h_fill)
hg_hi:  add a,a
        add a,a
        add a,a
        add a,a
        ld d,a
        ld a,c
        and 15
        cp 15
        jr nz,hg_lo
        ld a,(h_fill)
hg_lo:  or d
        ld c,a
hg_o:   ld a,c
        out (0x98),a
        djnz hg_b
        ld de,(h_ad)
        ld a,e
        add a,128
        ld e,a
        jr nc,hg_nc
        inc d
hg_nc:  ld (h_ad),de
        push hl
        ld hl,h_rows
        dec (hl)
        pop hl
        jp nz,hg_r
        ret

s_1up:  db "1UP",0
s_2up:  db "2UP",0
s_hi:   db "HI",0
s_life: db "LIFE",0
s_ammo: db "AMMO",0
s_key:  db "KEY",0
s_box:  db "bbbbb",0
s_keyi: db "a",0

        include "hudfont.inc"

; ------------------------------------------------------------------------- copia delle fasce nelle viste (ruotate della camera)
; A = pagina di destinazione (0..2)
hud_blit_i:
        ld (h_pg),a
        ld a,(p_cam)            ; rotazione = camera mod 256 (pari)
        and 0xFE
        ld hl,irq_on
        bit 0,(hl)
        jr z,hb_nz
        xor a                   ; con l'interruzione di linea l'HUD sta fermo: nessuna rotazione
hb_nz:  ld (h_rot),a
        ld a,(h_pg)             ; stessa rotazione e fascia invariata: la vista e' gia' a posto (risparmia 2-4 copie VDP)
        ld e,a
        ld d,0
        ld hl,h_lr
        add hl,de
        ld a,(h_rot)
        cp (hl)
        ret z
        ld (hl),a
        ld a,176
        ld (h_sy),a
        xor a
        ld (h_dy),a
        call hb_strip
        ld a,184
        ld (h_sy),a
        ld (h_dy),a
hb_strip:
        ld a,(h_rot)
        or a
        jr nz,hb_rot
        xor a                   ; senza rotazione: una copia da 256
        ld (h_sx),a
        ld (h_dx),a
        ld (h_nx),a
        ld a,1
        ld (h_nh),a
        jr hb_go
hb_rot: ld b,a                  ; pezzo 1: x 0.. -> ring x = rot, larghezza 256 - rot
        xor a
        ld (h_sx),a
        ld a,b
        ld (h_dx),a
        xor a
        sub b
        ld (h_nx),a
        xor a
        ld (h_nh),a
        call hb_go
        ld a,(h_rot)            ; pezzo 2: x = 256 - rot -> ring x = 0, larghezza rot
        ld b,a
        xor a
        sub b
        ld (h_sx),a
        xor a
        ld (h_dx),a
        ld a,b
        ld (h_nx),a
        xor a
        ld (h_nh),a
hb_go:  ld hl,P
        ld a,(h_sx)
        ld (hl),a
        inc hl
        ld (hl),0
        inc hl
        ld a,(h_sy)
        ld (hl),a
        inc hl
        ld (hl),3
        inc hl
        ld a,(h_dx)
        ld (hl),a
        inc hl
        ld (hl),0
        inc hl
        ld a,(h_dy)
        ld (hl),a
        inc hl
        ld a,(h_pg)
        ld (hl),a
        inc hl
        ld a,(h_nx)
        ld (hl),a
        inc hl
        ld a,(h_nh)
        ld (hl),a
        inc hl
        ld (hl),8
        inc hl
        ld (hl),0
        inc hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),0xD0
        ld hl,P
        jp vdp_cmd

; ogni fotogramma (da sw_update_i): ridisegna se serve e copia nella vista D
hud_frame_i:
        ld a,(p_tall)
        or a
        ret z
        ld a,(h_dirty)
        or a
        call nz,hud_draw_i
        ld a,(sw_D)
        jp hud_blit_i

; da sw_fill_i: le tre viste
hud_fill_all_i:
        ld a,(p_tall)
        or a
        ret z
        call hud_draw_i
        xor a
hfa_l:  push af
        call hud_blit_i
        pop af
        inc a
        cp 3
        jr c,hfa_l
        ret
