; swprops.asm - finestra delle proprieta' dei nemici (segmento 3, finestra A000; ingresso in props.asm)
; ------------------------------------------------------------------------- finestra delle proprieta'
do_eprops_i:
        ld a,(v_curx)
        ld b,a
        ld a,(v_cury)
        ld c,a
        call ept_get
        ret c                   ; troppi nemici con proprieta'
        ld (ep_rec),hl
        xor a
        ld (ep_sel),a
        call hide_cursor
        call ep_draw
epl:    call vwait
        ld a,8
        ld hl,v_prev8
        call edge
        ld (v_e8),a
        ld a,7
        ld hl,v_prev7
        call edge
        ld (v_e7),a
        bit 2,a                 ; ESC
        jr nz,ep_exit
        bit 7,a                 ; INVIO
        jr nz,ep_exit
        ld a,(v_e8)
        bit 5,a                 ; su
        jr nz,ep_up
        bit 6,a                 ; giu'
        jr nz,ep_dn
        bit 4,a                 ; sinistra
        jr nz,ep_lt
        bit 7,a                 ; destra
        jr nz,ep_rt
        jr epl
ep_up:  ld a,(ep_sel)
        or a
        jr z,epl
        dec a
        jr ep_s
ep_dn:  ld a,(ep_sel)
        cp 4
        jr nc,epl
        inc a
ep_s:   ld c,a
        ld a,(ep_sel)
        ld (ep_i),a
        ld a,c
        ld (ep_sel),a
        call ep_row             ; la riga lasciata (senza indicatore)
        ld a,(ep_sel)
        ld (ep_i),a
        call ep_row
        jr epl
ep_lt:  ld c,0xFF
        jr ep_ch
ep_rt:  ld c,1
ep_ch:  ld a,(ep_sel)
        ld e,a
        ld d,0
        ld hl,(ep_rec)
        add hl,de
        inc hl
        inc hl
        push hl
        ld hl,ep_min
        add hl,de
        ld b,(hl)
        ld hl,ep_max
        add hl,de
        ld e,(hl)
        pop hl
        ld a,(hl)
        bit 7,c
        jr z,epc_u
        cp b
        jp z,epl
        dec (hl)
        jr ep_v
epc_u:  cp e
        jp z,epl
        inc (hl)
ep_v:   ld a,(ep_sel)
        ld (ep_i),a
        call ep_row
        jp epl
ep_exit:
        xor a
        ld (v_valid),a          ; cambiare le regole di un nemico richiede di rigiocare il livello
        inc a
        ld (v_unsaved),a
        ld (v_redr),a
        ld (v_dirty),a
        ret

; ridisegno completo (apertura) e di una sola riga (cambi di valore/selezione: stampare e' lento)
ep_draw:
        ld hl,p_epbox
        call vdp_cmd
        ld a,15
        ld (FORCLR),a
        ld a,1
        ld (BAKCLR),a
        ld hl,40
        ld (GRPACX),hl
        ld hl,54
        ld (GRPACY),hl
        ld hl,s_ephead
        call print_str
        ld hl,40
        ld (GRPACX),hl
        ld hl,138
        ld (GRPACY),hl
        ld hl,s_epfoot
        call print_str
        xor a
epd_a:  ld (ep_i),a
        call ep_row
        ld a,(ep_i)
        inc a
        cp 5
        jr nz,epd_a
        ret

; riga (ep_i): indicatore, nome del campo e valore
ep_row: ld a,(ep_i)             ; y = 72 + i*12
        ld e,a
        add a,a
        add a,e
        add a,a
        add a,a
        add a,72
        ld l,a
        ld h,0
        ld (GRPACY),hl
        ld hl,36
        ld (GRPACX),hl
        ld a,(ep_sel)
        ld hl,ep_i
        cp (hl)
        ld a,' '
        jr nz,epd_m
        ld a,'>'
epd_m:  call print_char
        ld hl,50
        ld (GRPACX),hl
        ld a,(ep_i)
        add a,a
        ld e,a
        ld d,0
        ld hl,ep_lab
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        call print_str
        ld hl,140
        ld (GRPACX),hl
        ld a,(ep_i)
        ld e,a
        ld d,0
        ld hl,(ep_rec)
        add hl,de
        inc hl
        inc hl
        ld a,(hl)               ; valore del campo
        ld c,a
        ld a,(ep_i)
        or a
        jr nz,epd_n
        ld a,c                  ; IA: nome
        add a,a
        ld e,a
        ld d,0
        ld hl,ep_ai
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jp print_str
epd_n:  ld a,c
        jp print_num2

p_epbox: db 0,0,0,0, 24,0,50,0, 208,0,100,0, 0x11,0,0xC0
ep_min:  db 0,1,0,1,1
ep_max:  db 3,3,15,3,15
ep_lab:  dw s_eplai,s_eplsp,s_eplrg,s_eplhp,s_epldt
ep_ai:   dw s_ai0,s_ai1,s_ai2,s_ai3
s_ephead: db "ENEMY PROPERTIES",0
s_eplai:  db "BEHAVIOR",0
s_eplsp:  db "SPEED",0
s_eplrg:  db "RANGE",0
s_eplhp:  db "HEALTH",0
s_epldt:  db "DETECT",0
s_ai0:    db "PATROL ",0
s_ai1:    db "SLEEPER",0
s_ai2:    db "CHASER ",0
s_ai3:    db "COWARD ",0
s_epfoot: db "UP/DOWN LEFT/RIGHT  ESC",0
