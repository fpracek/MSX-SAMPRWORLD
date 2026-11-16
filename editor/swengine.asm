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
        ld a,(p_vr1)
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
        ld a,(p_voff)
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
        ld a,(p_vh)
        ld (hl),a
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
        call hud_fill_all_i     ; HUD dei livelli alti nelle tre viste
        ld hl,(p_cam)
        ld (sw_cam),hl
        ld (sw_cam+2),hl
        ld (sw_cam+4),hl
        ld hl,SWOK
        ld de,SWOK+1
        ld bc,SWN*3-1
        ld (hl),0
        ldir
        xor a
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
        call hud_frame_i        ; HUD dei livelli alti (hud.asm)
        call vdp_wait           ; (le strisce di D devono essere finite prima di disegnarci)
        call sw_objs            ; lista degli oggetti: nemici, eroe
        xor a
        ld (sw_j),a
suo_l:  call sw_erase           ; vista E: via lo sprite vecchio (il VDP lavora mentre la CPU disegna in D)
        call sw_draw
        ld a,(sw_j)
        inc a
        ld (sw_j),a
        cp SWN
        jr nz,suo_l
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
        ret

; lista oggetti SWO (SWN x 4 byte: frame, x (2), y; frame 0xFF = assente): 0-7 nemici, 8 giocatore 2, 9 giocatore 1.
; Si disegnano nell'ordine: gli ultimi stanno sopra.
sw_objs:
        ld ix,ENT
        ld hl,SWO
        ld b,E_MAX
so_e:   ld a,(ix+0)
        or a
        jr z,so_off
        ld a,(ix+5)             ; sprite scelto nelle proprieta' (0 = quello del tipo)
        or a
        jr nz,so_k
        ld a,(ix+0)
so_k:   dec a                   ; 0 soldato, 1 medico, 2 poliziotto
        ld e,a
        ld d,3                  ; un frame di animazione ogni 8 fotogrammi (medico: ogni 4)
        cp 1
        jr nz,so_s
        ld d,2
so_s:   ld a,d
        ld (sw_t),a
        ld d,0
        push hl
        ld hl,swf_kb
        add hl,de
        ld c,(hl)
        pop hl
        ld a,(sw_t)
        ld e,a
        ld a,(p_tick)
so_sh:  srl a
        dec e
        jr nz,so_sh
        and 7
        cp 6
        jr c,so_a
        sub 6
so_a:   add a,c
        bit 0,(ix+4)
        jr z,so_r
        add a,6                 ; verso sinistra
so_r:   ld (hl),a
        inc hl
        ld a,(ix+1)
        ld (hl),a
        inc hl
        ld a,(ix+2)
        ld (hl),a
        inc hl
        ld a,(ix+3)
        ld (hl),a
        inc hl
        jr so_n
so_off: ld (hl),0xFF
        inc hl
        inc hl
        inc hl
        inc hl
so_n:   ld de,8
        add ix,de
        djnz so_e
        ld a,(p_two)
        or a
        jr nz,so_2p
        ld (hl),0xFF            ; 8: giocatore 2 assente
        inc hl
        inc hl
        inc hl
        inc hl
        ld a,(p_dead)           ; 9: giocatore 1 (blocco attivo)
        or a
        jr nz,so_h1
        ld a,(p_climb)
        or a
        jr z,so_n1
        ld a,(p_y)              ; sulla scala: di schiena, il frame cambia ogni 4 px
        rrca
        rrca
        and 1
        add a,SWF_CLIMB1
        jr so_f1
so_n1:  ld a,(p_frame)
        add a,SWF_HERO1
so_f1:  ld (hl),a
        inc hl
        ld a,(p_x)
        ld (hl),a
        inc hl
        ld a,(p_x+1)
        ld (hl),a
        inc hl
        ld a,(p_y)
        ld (hl),a
        ret
so_h1:  ld (hl),0xFF
        ret
so_2p:  ld iy,HS1               ; 8: giocatore 2
        ld c,SWF_HERO2
        ld b,SWF_CLIMB2
        call so_hero
        ld iy,HS0               ; 9: giocatore 1
        ld c,SWF_HERO1
        ld b,SWF_CLIMB1
so_hero:
        ld a,(iy+HO_DEAD)
        or a
        jr nz,so_hx
        ld a,(iy+20)            ; p_climb salvato
        or a
        ld a,(iy+15)            ; p_frame salvato
        jr z,so_nc
        ld a,(iy+HO_Y)
        rrca
        rrca
        and 1
        ld c,b
so_nc:  add a,c
        ld (hl),a
        inc hl
        ld a,(iy+HO_X)
        ld (hl),a
        inc hl
        ld a,(iy+HO_X+1)
        ld (hl),a
        inc hl
        ld a,(iy+HO_Y)
        ld (hl),a
        inc hl
        ret
so_hx:  ld (hl),0xFF
        inc hl
        inc hl
        inc hl
        inc hl
        ret

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
        ld a,(p_vh)
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
        ld c,a
        ld a,(p_voff)
        add a,c
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

; DE = pagina*SWN + oggetto corrente (A = pagina)
sw_idx: ld c,a
        add a,a
        add a,a
        add a,a
        add a,c
        add a,c
        ld c,a
        ld a,(sw_j)
        add a,c
        ld e,a
        ld d,0
        ret

; cancella lo sprite dell'oggetto sw_j nella vista E (se c'e')
sw_erase:
        ld a,(sw_E)
        call sw_idx
        ld hl,SWOK
        add hl,de
        ld a,(hl)
        or a
        ret z
        ld (hl),0
        ld hl,SWX
        add hl,de
        ld a,(hl)
        ld (sx_x),a
        ld hl,SWY
        add hl,de
        ld a,(hl)
        ld (sx_y),a
        ld a,16
        ld (sx_n),a
        ld (sx_h),a
        ld a,(sw_E)
        ld (sx_pg),a
        jp sw_cp

; ------------------------------------------------------------------------- disegno dell'oggetto sw_j nella vista D
sw_draw:
        ld a,(sw_j)
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,SWO
        add hl,de
        ld a,(hl)
        cp 0xFF
        ret z
        ld (sw_fr),a
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)               ; BC = x del mondo
        inc hl
        ld a,(hl)               ; y (nella finestra)
        ld hl,p_vmax
        cp (hl)
        ret nc                  ; fuori schermo (sopra/sotto)
        ld (sw_wy),a
        ld hl,p_voff
        add a,(hl)
        ld (sw_ry),a            ; y nella vista
        ld h,b
        ld l,c
        ld de,(p_cam)
        or a
        sbc hl,de               ; x sullo schermo: solo se interamente dentro [0, 240]
        ld a,h
        or a
        ret nz
        ld a,l
        cp 241
        ret nc
        ld a,c
        and 0xFE
        ld (sw_rx),a
        ld a,(sw_D)             ; memorizza posizione e validita' per la cancellazione
        call sw_idx
        ld hl,SWOK
        add hl,de
        ld (hl),1
        ld hl,SWX
        add hl,de
        ld a,(sw_rx)
        ld (hl),a
        ld hl,SWY
        add hl,de
        ld a,(sw_wy)
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

; DE = indirizzo VRAM (14 bit | 0x4000), R#14 gia' impostato: esegue il frame compilato sw_fr (segmento nella finestra 8000)
sw_callframe:
        ld a,(sw_fr)
        ld c,a
        ld b,0
        ld hl,swf_seg
        add hl,bc
        ld a,(hl)
        ld (BANKW),a
        ld hl,swf_adr
        add hl,bc
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld c,0x98
        call sw_jphl
        ld a,SCCMAP             ; la finestra 8000 serve all'SCC (audio ed effetti)
        ld (BANKW),a
        ret
sw_jphl:
        jp (hl)

; una cella della mappa e' cambiata: master e le tre viste
sw_cell_i:
        ld a,(p_vr1)            ; le righe sotto l'area di gioco (HUD) non si disegnano
        ld hl,bo_row
        cp (hl)
        ret c
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
