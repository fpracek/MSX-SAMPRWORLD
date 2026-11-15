; blocks.asm - blocchi interattivi della modalita' prova
;   Pietra fessurata (BREAK): si rompe colpendola da sotto.
;   Blocco runico (RUNE) e forziere (CHEST): colpiti da sotto diventano "usati" e fanno apparire una moneta / una gemma
;   sopra di loro (ora: il premio viene accreditato subito).
;   Blocco friabile (CRUMB): ~0,5 s dopo che l'eroe ci sta sopra sparisce.
;   Portone (DOORT+DOORB): si apre toccandolo con una chiave; la chiave si consuma.
;   Chiave: si raccoglie come le monete; gemma = 5 monete.
; Ogni modifica passa da settile (mappa + ridisegno su entrambe le pagine).
CRMB    equ 0xCA40              ; 4 voci friabili: colonna, riga, timer (0 = libera)
p_keys  equ V+0xF8

; HL = &MAP[bo_row][bo_col]
tile_ptr:
        ld a,(bo_row)
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
        ret

; scrive il tile A in (bo_col,bo_row) e lo ridisegna
settile:
        push af
        call tile_ptr
        pop af
        ld (hl),a
        jp cell_changed

; E = tile colpito da sotto (p_tcol/p_trow)
head_hit:
        ld a,(p_tcol)
        ld (bo_col),a
        ld a,(p_trow)
        ld (bo_row),a
        ld a,e
        cp T_BREAK
        jr nz,hh_1
        ld a,SFX_HIT
        call sfx_a
        xor a
        jp settile
hh_1:   cp T_RUNE
        ld c,T_COIN
        jr z,hh_it
        cp T_CHEST
        ld c,T_GEM
        ret nz
hh_it:  push bc
        ld a,SFX_HIT
        call sfx_a
        ld a,T_RUNEU
        call settile
        pop bc                  ; C = T_COIN / T_GEM: il premio va subito nel conteggio (non resta sul blocco,
        ld b,1                  ; dove spesso non si potrebbe raggiungere)
        ld a,c
        cp T_GEM
        jr nz,hh_a
        ld b,5
hh_a:   ld a,(p_coins)
        add a,b
        jr nc,hh_s
        ld a,255
hh_s:   ld (p_coins),a
        ld a,SFX_COIN
        call sfx_a
        jp play_status

; E = tile che blocca di lato. CF=1 se resta bloccato; con una chiave il portone si apre (CF=0)
try_door:
        ld a,e
        cp T_DOORT
        jr z,td_d
        cp T_DOORB
        jr z,td_d
        scf
        ret
td_d:   ld a,(p_keys)
        or a
        scf
        ret z
        dec a
        ld (p_keys),a
        ld a,SFX_KEY
        call sfx_a
        ld a,e
        ld (p_cnt),a
        ld a,(p_tcol)
        ld (bo_col),a
        ld a,(p_trow)
        ld (bo_row),a
        xor a
        call settile
        ld a,(p_cnt)
        cp T_DOORT
        ld a,(p_trow)
        jr nz,td_up
        inc a
        jr td_p
td_up:  dec a
td_p:   ld (bo_row),a
        xor a
        call settile
        call play_status
        or a
        ret

; a fine fisica: se l'eroe sta su un blocco friabile parte il timer
crumble_check:
        ld a,(p_ground)
        or a
        ret z
        ld bc,0x0810
        call probe
        ld a,e
        cp T_CRUMB
        ret nz
        ld a,(p_tcol)
        ld d,a
        ld a,(p_trow)
        ld e,a
        ld hl,CRMB
        ld b,4
cc_f:   ld a,(hl)
        cp d
        jr nz,cc_n
        inc hl
        ld a,(hl)
        dec hl
        cp e
        jr nz,cc_n
        inc hl
        inc hl
        ld a,(hl)
        dec hl
        dec hl
        or a
        ret nz                  ; gia' in corso
cc_n:   inc hl
        inc hl
        inc hl
        djnz cc_f
        ld hl,CRMB
        ld b,4
cc_s:   inc hl
        inc hl
        ld a,(hl)
        dec hl
        dec hl
        or a
        jr z,cc_set
        inc hl
        inc hl
        inc hl
        djnz cc_s
        ret
cc_set: ld (hl),d
        inc hl
        ld (hl),e
        inc hl
        ld (hl),30
        ret

crumble_update:
        ld hl,CRMB
        ld b,4
cu_l:   push hl
        push bc
        inc hl
        inc hl
        ld a,(hl)
        or a
        jr z,cu_n
        dec a
        ld (hl),a
        jr nz,cu_n
        dec hl
        ld a,(hl)
        ld (bo_row),a
        dec hl
        ld a,(hl)
        ld (bo_col),a
        xor a
        call settile
cu_n:   pop bc
        pop hl
        inc hl
        inc hl
        inc hl
        djnz cu_l
        ret
