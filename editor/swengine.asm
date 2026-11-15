; swengine.asm - motore degli sprite software (vedi swspr.asm): vive nel segmento 3 (finestra A000)
; mostra la pagina sw_S con la sua camera
sw_show_i:
        ld a,(sw_S)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        or 0x1F
        ld e,2
        call wrreg
        ld a,(sw_S)
        add a,a
        ld e,a
        ld d,0
        ld hl,sw_cam
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jp ring_setregs

; ------------------------------------------------------------------------- riempimento (inizio prova, rinascita)
sw_fill_i:                        ; HL = camera
        ld (p_cam),hl
        inc hl
        res 0,l
        ld (sw_t),hl
        ld (sw_lo+6),hl         ; master
        ld (r_lo),hl
        ld a,3
        ld (bc_pg),a
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
        ld hl,(sw_t)
        ld (sw_lo),hl
        ld (sw_lo+2),hl
        ld (sw_lo+4),hl
        xor a
        ld (sx_pg),a
sf_cp:  ld hl,P                 ; HMMM master (0,768) -> pagina sx_pg, 256x192
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),3
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld a,(sx_pg)
        ld (hl),a
        inc hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),1
        inc hl
        ld (hl),192
        inc hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),0xD0
        ld hl,P
        call vdp_cmd
        ld a,(sx_pg)
        inc a
        ld (sx_pg),a
        cp 3
        jr nz,sf_cp
        ld hl,(p_cam)
        ld (sw_cam),hl
        ld (sw_cam+2),hl
        ld (sw_cam+4),hl
        xor a
        ld (sw_ok),a
        ld (sw_ok+1),a
        ld (sw_ok+2),a
        ld (sw_S),a
        call vdp_wait
        jp sw_show_i

; ------------------------------------------------------------------------- aggiornamento di un fotogramma
sw_update_i:
        ld a,(sw_S)
        inc a
        cp 3
        jr c,su1
        xor a
su1:    ld (sw_D),a
        inc a
        cp 3
        jr c,su2
        xor a
su2:    ld (sw_E),a
        ld hl,(sw_lo+6)         ; master: le strisce entrano come tile
        ld (r_lo),hl
        ld a,3
        ld (bc_pg),a
        ld hl,(p_cam)
        call ring_strips_to
        ld hl,(r_lo)
        ld (sw_lo+6),hl
        call sw_view_strip      ; vista D: le stesse colonne, copiate dal master
        call vdp_wait           ; (le strisce di D devono essere finite prima di disegnarci)
        call sw_erase           ; vista E: via lo sprite vecchio (il VDP lavora mentre la CPU disegna in D)
        ld a,(sw_D)
        add a,a
        ld e,a
        ld d,0
        ld hl,sw_cam
        add hl,de
        ld de,(p_cam)
        ld (hl),e
        inc hl
        ld (hl),d
        jp sw_drawhero

; vista D: copia la striscia [lo_D, nuovo lo) dal master
sw_view_strip:
        ld a,(sw_D)
        add a,a
        ld e,a
        ld d,0
        ld hl,sw_lo
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)               ; DE = lo della vista
        push hl
        ld hl,(sw_lo+6)
        or a
        sbc hl,de               ; nuovo - vecchio
        jr nz,svs_m
        pop hl
        ret
svs_m:  bit 7,h
        jr nz,svs_left
        ld a,l                  ; verso destra: colonne [lo+256, nlo+256): x = lo & 255
        ld (sx_n),a
        ld a,e
        ld (sx_x),a
        jr svs_do
svs_left:
        call neg_hl             ; verso sinistra: [nlo, lo): x = nlo & 255
        ld a,l
        ld (sx_n),a
        ld a,e
        sub l
        ld (sx_x),a
svs_do: xor a
        ld (sx_y),a
        ld a,192
        ld (sx_h),a
        ld a,(sw_D)
        ld (sx_pg),a
        call sw_cp
        pop hl
        ld de,(sw_lo+6)
        ld (hl),d
        dec hl
        ld (hl),e
        ret

; HMMM dal master: x = sx_x, larghezza sx_n (anche a cavallo della cucitura), riga sx_y, altezza sx_h, verso la pagina sx_pg
sw_cp:  ld a,(sx_n)
        or a
        ret z
        ld b,a
        ld a,(sx_x)
        add a,b
        jr nc,sx_one
        jr z,sx_one
        ld a,(sx_x)             ; a cavallo: prima parte [x, 256), seconda [0, n-(256-x))
        ld c,a
        xor a
        sub c
        ld (sx_t),a             ; n1 = 256 - x
        ld a,b
        ld hl,sx_t
        sub (hl)
        ld (sx_n2),a
        ld a,(sx_t)
        call sx_do
        xor a
        ld (sx_x),a
        ld a,(sx_n2)
        jr sx_do
sx_one: ld a,b
sx_do:  ld (sx_t),a
        ld hl,P
        ld a,(sx_x)
        ld (hl),a
        inc hl
        ld (hl),0
        inc hl
        ld a,(sx_y)
        ld (hl),a
        inc hl
        ld (hl),3               ; SY = 768 + y
        inc hl
        ld a,(sx_x)
        ld (hl),a
        inc hl
        ld (hl),0
        inc hl
        ld a,(sx_y)
        ld (hl),a
        inc hl
        ld a,(sx_pg)
        ld (hl),a
        inc hl
        ld a,(sx_t)
        ld (hl),a
        inc hl
        ld (hl),0
        inc hl
        ld a,(sx_h)
        ld (hl),a
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

; cancella lo sprite della vista E (se c'e')
sw_erase:
        ld a,(sw_E)
        ld e,a
        ld d,0
        ld hl,sw_ok
        add hl,de
        ld a,(hl)
        or a
        ret z
        ld (hl),0
        ld hl,sw_x
        add hl,de
        ld a,(hl)
        ld (sx_x),a
        ld hl,sw_y
        add hl,de
        ld a,(hl)
        ld (sx_y),a
        ld a,16
        ld (sx_n),a
        ld (sx_h),a
        ld a,e
        ld (sx_pg),a
        jp sw_cp

; ------------------------------------------------------------------------- disegno dell'eroe nella vista D
sw_drawhero:
        ld a,(p_dead)
        or a
        ret nz
        ld hl,(p_y)
        ld a,h
        or a
        ret nz                  ; fuori schermo (sopra): non si disegna
        ld a,l
        cp 177
        ret nc
        ld (sw_ry),a
        ld a,(p_x)
        and 0xFE
        ld (sw_rx),a
        ld a,(sw_D)             ; memorizza posizione e validita' per la cancellazione
        ld e,a
        ld d,0
        ld hl,sw_ok
        add hl,de
        ld (hl),1
        ld hl,sw_x
        add hl,de
        ld a,(sw_rx)
        ld (hl),a
        ld hl,sw_y
        add hl,de
        ld a,(sw_ry)
        ld (hl),a
        ld a,(sw_rx)
        cp 241
        jr nc,sdh_slow          ; a cavallo della cucitura
        ld a,(sw_ry)
        and 127
        cp 113
        jr nc,sdh_slow          ; a cavallo del confine di 16 KB
        ; percorso veloce: indirizzo = D*0x8000 + y*128 + x/2
        ld a,(sw_ry)
        ld b,a
        srl a
        ld h,a
        ld a,b
        and 1
        rrca
        ld l,a
        ld a,(sw_rx)
        srl a
        add a,l
        ld l,a
        ld a,h
        rlca
        rlca
        and 3
        ld b,a
        ld a,(sw_D)
        add a,a
        add a,b
        out (0x99),a            ; R#14 = A16..A14
        ld a,0x8E
        out (0x99),a
        ld a,h
        and 0x3F
        or 0x40
        ld d,a
        ld e,l
        jp sw_callframe
sdh_slow:                       ; area di lavoro: azzera, disegna, copia con LMMM trasparente
        ld hl,P
        ld b,15
        xor a
sds_z:  ld (hl),a
        inc hl
        djnz sds_z
        ld hl,P+6               ; HMMV: DY = 736, 16x16, colore 0
        ld (hl),SWSCR_Y&255
        inc hl
        ld (hl),SWSCR_Y>>8
        inc hl
        ld (hl),16
        inc hl
        inc hl
        ld (hl),16
        ld a,0xC0
        ld (P+14),a
        ld hl,P
        call vdp_cmd
        call vdp_wait
        ld a,5                  ; 0x17000: R#14 = 5, indirizzo 14 bit = 0x3000
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        ld de,0x7000
        call sw_callframe
        ld a,(sw_rx)            ; prima parte: n1 = min(16, 256 - x)
        ld b,a
        xor a
        sub b
        jr z,sds_f              ; x = 0: nessuna cucitura
        cp 16
        jr c,sds_n
sds_f:  ld a,16
sds_n:  ld c,a
        push bc
        ld hl,P
        xor a
        ld (hl),a               ; SX = 0
        inc hl
        ld (hl),a
        inc hl
        ld (hl),SWSCR_Y&255
        inc hl
        ld (hl),SWSCR_Y>>8
        inc hl
        ld a,(sw_rx)
        ld (hl),a               ; DX
        inc hl
        ld (hl),0
        inc hl
        ld a,(sw_ry)
        ld (hl),a               ; DY = D*256 + y
        inc hl
        ld a,(sw_D)
        ld (hl),a
        inc hl
        ld (hl),c               ; NX
        inc hl
        ld (hl),0
        inc hl
        ld (hl),16
        inc hl
        ld (hl),0
        inc hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),0x98            ; LMMM + TIMP
        ld hl,P
        call vdp_cmd
        pop bc
        ld a,c
        cp 16
        ret z
        ld b,a                  ; seconda parte: [n1, 16) -> x = 0
        ld a,16
        sub b
        ld c,a
        ld hl,P
        ld (hl),b               ; SX = n1
        inc hl
        ld (hl),0
        inc hl
        ld (hl),SWSCR_Y&255
        inc hl
        ld (hl),SWSCR_Y>>8
        inc hl
        ld (hl),0               ; DX = 0
        inc hl
        ld (hl),0
        inc hl
        ld a,(sw_ry)
        ld (hl),a
        inc hl
        ld a,(sw_D)
        ld (hl),a
        inc hl
        ld (hl),c
        inc hl
        ld (hl),0
        inc hl
        ld (hl),16
        inc hl
        ld (hl),0
        inc hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),0x98
        ld hl,P
        jp vdp_cmd

; DE = indirizzo VRAM (14 bit | 0x4000), R#14 gia' impostato: esegue il frame compilato p_frame
sw_callframe:
        ld a,(p_frame)
        add a,a
        ld c,a
        ld b,0
        ld hl,swh_tab
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld c,0x98
        jp (hl)

; una cella della mappa e' cambiata: master e le tre viste
sw_cell_i:
        ld a,3
sc_l:   ld (sx_pg),a
        ld (bc_pg),a
        add a,a
        ld e,a
        ld d,0
        ld hl,sw_lo
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (r_lo),de
        call ring_cell_hw
        ld a,(sx_pg)
        or a
        ret z
        dec a
        jr sc_l
