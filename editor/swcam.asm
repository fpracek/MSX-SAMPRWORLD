; swcam.asm - camera di gruppo per due giocatori (segmento 3, finestra A000; ingressi in coop.asm)
; ------------------------------------------------------------------------- camera di gruppo
; Gli eroi vivi non escono dalla finestra della camera [cam, cam+240] (muri invisibili ai bordi): chi e' davanti si ferma
; al bordo e la camera non scorre finche' l'altro non gli si avvicina. L'ancora della camera e' il punto medio del
; gruppo, limitato in modo che nessuno esca dallo schermo: la camera sta sempre in [maxX-240, minX]. Vale a destra e a sinistra.
pa_mn   equ PXV+0x41            ; 2 byte
pa_mx   equ PXV+0x43
pa_a    equ PXV+0x45
pa_lo   equ PXV+0x47
pa_hi   equ PXV+0x49

p2_clamp_i:
        ld iy,HS0
        call pc_one
        ld iy,HS1
pc_one: ld a,(iy+HO_DEAD)
        or a
        ret nz
        ld l,(iy+HO_X)
        ld h,(iy+HO_X+1)
        ld de,(p_cam)
        or a
        sbc hl,de               ; x - cam
        bit 7,h
        jr nz,pc_lo
        ld a,h
        or a
        jr nz,pc_hi
        ld a,l
        cp 241
        ret c                   ; dentro
pc_hi:  ld hl,(p_cam)           ; oltre il bordo destro: si ferma a cam+240
        ld de,240
        add hl,de
        jr pc_set
pc_lo:  ld hl,(p_cam)           ; oltre il bordo sinistro: si ferma a cam
pc_set: ld (iy+HO_X),l
        ld (iy+HO_X+1),h
        xor a
        ld (iy+2),a             ; frazione di x
        ld (iy+HO_VX),a         ; e velocita' orizzontale azzerata
        ld (iy+HO_VX+1),a
        ret

; (blocco attivo = eroe caricato) con due eroi vivi sostituisce p_x con l'ancora della camera
p2_anchor_i:
        ld a,(HS0+HO_DEAD)
        ld hl,HS1+HO_DEAD
        or (hl)
        ret nz                  ; uno e' morto: la camera segue l'eroe vivo (gia' caricato)
        ld hl,(HS0+HO_X)
        ld de,(HS1+HO_X)
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,pa_s               ; x0 < x1: HL = minimo
        ex de,hl
pa_s:   ld (pa_mn),hl
        ld (pa_mx),de
        add hl,de
        srl h
        rr l
        ld (pa_a),hl            ; punto medio
        ld hl,(pa_mx)           ; limite basso: max - 128 (l'ultimo eroe resta a cam+240 al massimo)
        ld de,128
        or a
        sbc hl,de
        jr nc,pa_l1
        ld hl,0
pa_l1:  ld (pa_lo),hl
        ld hl,(pa_mn)           ; limite alto: min + 112 (il primo eroe resta a cam almeno)
        ld de,112
        add hl,de
        ld (pa_hi),hl
        ld de,(pa_lo)
        or a
        sbc hl,de
        jr nc,pa_ok
        ld hl,(p_cam)           ; i due sono piu' lontani di uno schermo: la camera sta ferma
        ld de,112
        add hl,de
        jr pa_set
pa_ok:  ld hl,(pa_a)
        ld de,(pa_lo)
        push hl
        or a
        sbc hl,de
        pop hl
        jr nc,pa_c2
        ld hl,(pa_lo)
pa_c2:  ld de,(pa_hi)
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,pa_set
        ld hl,(pa_hi)
pa_set: ld (p_x),hl
        ret
