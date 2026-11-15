; netui.asm - tasto D: elenco dei livelli sul server, download e prova del livello scaricato.
; Il livello scaricato si gioca senza toccare il lavoro dell'editor: la mappa dell'editor viene copiata in VRAM
; (0x19000) e ripristinata, la validazione e la bozza in flash non cambiano. Vale solo il formato 128x12 (docs/LEVEL.md).
p_foreign equ V+0xF9            ; 1 = livello scaricato (la vittoria non valida la bozza)
br_pg   equ V+0xFA
br_sel  equ V+0xFB
br_cnt  equ V+0xFC
br_msg  equ V+0xFD              ; 2 byte: messaggio in basso (0 = nessuno)
sv_curx equ V+0x98
sv_cury equ V+0x99
sv_scrx equ V+0x9A
sv_valid equ V+0x9B
BRBUF   equ 0xCB00              ; copia della risposta LIST (resta valida anche dopo un download)

do_browse:
        call hide_cursor
        xor a
        ld (br_pg),a
        ld (br_cnt),a
        ld (br_sel),a
        ld h,a
        ld l,a
        ld (br_msg),hl
        call br_fetch
br_show:
        call br_draw
br_loop:
        call vwait
        ld a,8
        ld hl,v_prev8
        call edge
        ld (v_e8),a
        ld a,7
        ld hl,v_prev7
        call edge
        ld (v_e7),a
        bit 2,a                 ; ESC
        jp nz,br_exit
        bit 7,a                 ; INVIO
        jp nz,br_go
        ld a,(v_e8)
        bit 5,a
        jr nz,br_up
        bit 6,a
        jr nz,br_dn
        bit 7,a
        jr nz,br_next
        bit 4,a
        jp nz,br_prev
        jr br_loop
br_exit:
        ld a,1
        ld (v_redr),a
        ld (v_dirty),a
        ret
br_up:  ld a,(br_sel)
        or a
        jp z,br_loop
        ld c,' '
        call br_mark
        ld a,(br_sel)
        dec a
        ld (br_sel),a
        ld c,'>'
        call br_mark
        jp br_loop
br_dn:  ld a,(br_sel)
        inc a
        ld hl,br_cnt
        cp (hl)
        jp nc,br_loop
        ld a,(br_sel)
        ld c,' '
        call br_mark
        ld a,(br_sel)
        inc a
        ld (br_sel),a
        ld c,'>'
        call br_mark
        jp br_loop

; stampa il carattere C a sinistra della riga A (solo il marcatore: ridisegnare tutto e' lento)
br_mark:
        ld b,a
        ld a,28
        ld d,b
        inc d
bm_y:   dec d
        jr z,bm_d
        add a,14
        jr bm_y
bm_d:   ld l,a
        ld h,0
        ld (GRPACY),hl
        ld hl,8
        ld (GRPACX),hl
        ld a,c
        jp print_char
br_next:
        ld a,(br_pg)            ; c'e' una pagina successiva? (pagina+1)*6 < totale
        inc a
        ld b,a
        ld hl,0
        ld de,6
br_n6:  add hl,de
        djnz br_n6
        ld de,(BRBUF+3)
        or a
        sbc hl,de
        jp nc,br_loop
        ld a,(br_pg)
        inc a
        ld (br_pg),a
        call br_fetch
        jp br_show
br_prev:
        ld a,(br_pg)
        or a
        jp z,br_loop
        dec a
        ld (br_pg),a
        call br_fetch
        jp br_show

; scarica la pagina br_pg dell'elenco
br_fetch:
        ld hl,m_brload
        ld (br_msg),hl
        call br_draw
        ld a,(br_pg)
        call NETRT+3
        or a
        jr z,bf_ok
        call err_msg
        ld (br_msg),hl
        xor a
        ld (br_cnt),a
        ld (br_sel),a
        ret
bf_ok:  ld hl,RXBUF
        ld de,BRBUF
        ld bc,160
        ldir
        ld a,(BRBUF+6)
        ld (br_cnt),a
        xor a
        ld (br_sel),a
        ld hl,0
        ld (br_msg),hl
        ld a,(br_cnt)
        or a
        ret nz
        ld hl,m_nolev
        ld (br_msg),hl
        ret

; schermata testuale
br_draw:
        ld hl,p_clear
        call vdp_cmd
        ld a,15
        ld (FORCLR),a
        ld a,1
        ld (BAKCLR),a
        ld hl,8
        ld (GRPACX),hl
        ld hl,6
        ld (GRPACY),hl
        ld hl,s_brtitle
        call print_str
        ld a,(br_pg)
        inc a
        ld l,a
        ld h,0
        call printdec16
        ld a,(br_cnt)
        or a
        jr z,bd_msg
        ld b,0
bd_l:   push bc
        ld a,28                 ; y = 28 + indice*14
        ld c,b
        inc c
bd_y:   dec c
        jr z,bd_yd
        add a,14
        jr bd_y
bd_yd:  ld l,a
        ld h,0
        ld (GRPACY),hl
        ld hl,8
        ld (GRPACX),hl
        ld a,(br_sel)
        cp b
        ld a,' '
        jr nz,bd_m
        ld a,'>'
bd_m:   call print_char
        ld a,' '
        call print_char
        pop bc
        push bc
        ld hl,BRBUF+7           ; record = BRBUF+7 + indice*22
        ld de,22
        ld a,b
        or a
        jr z,bd_r
bd_p:   add hl,de
        dec a
        jr nz,bd_p
bd_r:   push hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        call printdec16         ; id
        ld a,' '
        call print_char
        pop hl
        ld de,4
        add hl,de
        ld b,16
bd_t:   ld a,(hl)
        or a
        jr z,bd_e
        push hl
        push bc
        call print_char
        pop bc
        pop hl
        inc hl
        djnz bd_t
bd_e:   pop bc
        inc b
        ld a,b
        ld hl,br_cnt
        cp (hl)
        jr nz,bd_l
bd_msg: ld hl,8
        ld (GRPACX),hl
        ld hl,150
        ld (GRPACY),hl
        ld hl,(br_msg)
        ld a,h
        or l
        jr z,bd_f
        call print_str
bd_f:   ld hl,8
        ld (GRPACX),hl
        ld hl,176
        ld (GRPACY),hl
        ld hl,s_brh1
        call print_str
        ld hl,8
        ld (GRPACX),hl
        ld hl,190
        ld (GRPACY),hl
        ld hl,s_brh2
        jp print_str

; INVIO: scarica il livello selezionato e lo gioca
br_go:  ld a,(br_cnt)
        or a
        jp z,br_loop
        ld hl,BRBUF+7
        ld de,22
        ld a,(br_sel)
        or a
        jr z,bg_p
bg_l:   add hl,de
        dec a
        jr nz,bg_l
bg_p:   ld e,(hl)
        inc hl
        ld d,(hl)
        push de
        ld hl,m_brget
        ld (br_msg),hl
        call br_draw
        pop hl
        call NETRT+6
        or a
        jr nz,bg_err
        call blob_check
        or a
        jr nz,bg_err
        jp play_foreign
bg_err: call err_msg
        ld (br_msg),hl
        call br_draw
        jp br_loop

; A = codice d'errore di rete -> HL = messaggio
err_msg:
        ld hl,m_nounapi
        cp 1
        ret z
        ld hl,m_dns
        cp 2
        ret z
        ld hl,m_noopen
        cp 3
        ret z
        ld hl,m_notmo
        cp 4
        ret z
        ld hl,m_toobig
        cp 7
        ret z
        ld hl,m_badfmt
        cp 8
        ret z
        ld hl,m_srverr
        ret

; il blob in REC (n_glen byte) e' un livello 128x12 valido? A = 0 si', 8 no
blob_check:
        ld hl,(n_glen)
        ld de,32
        or a
        sbc hl,de
        jr c,bk_bad
        ld a,(REC)
        cp 'L'
        jr nz,bk_bad
        ld a,(REC+1)
        cp 'V'
        jr nz,bk_bad
        ld a,(REC+2)
        cp 1
        jr nz,bk_bad
        ld a,(REC+3)
        cp MAPW
        jr nz,bk_bad
        ld a,(REC+4)
        cp MAPH
        jr nz,bk_bad
        ld a,(REC+24)
        cp EP_MAX+1
        jr nc,bk_bad
        ld bc,(n_glen)
        dec bc
        dec bc
        ld hl,REC
        call crc16
        ld hl,(n_glen)
        ld bc,REC-2
        add hl,bc
        ld a,(hl)
        cp e
        jr nz,bk_bad
        inc hl
        ld a,(hl)
        cp d
        jr nz,bk_bad
        xor a
        ret
bk_bad: ld a,8
        ret

; REC -> MAP (RLE); i tile fuori dal catalogo diventano vuoti
blob_decode:
        ld a,(REC+24)           ; n_ent (<= EP_MAX: lo garantisce blob_check)
        ld (ept_n),a
        add a,a
        add a,a
        add a,a
        ld c,a
        ld b,0
        ld hl,REC+25
        or a
        jr z,bd2_ne
        ld de,EPT
        push bc
        ldir                    ; record dei nemici
        pop bc
        jr bd2_go
bd2_ne: add hl,bc
bd2_go: ld de,MAP
        ld bc,MAPW*MAPH
bd2_lp: ld a,(hl)
        inc hl
        bit 7,a
        jr nz,bd2_run
        ld (de),a
        inc de
        dec bc
        ld a,b
        or c
        jr nz,bd2_lp
        jr bd2_san
bd2_run:
        and 0x7F
        ld (v_rt),a
        ld a,(hl)
        inc hl
        ld (v_rn),a
bd2_r2: ld a,(v_rt)
        ld (de),a
        inc de
        dec bc
        ld a,b
        or c
        jr z,bd2_san
        ld a,(v_rn)
        dec a
        ld (v_rn),a
        jr nz,bd2_r2
        jr bd2_lp
bd2_san:
        ld hl,MAP
        ld bc,MAPW*MAPH
bs_l:   ld a,(hl)
        cp T_COUNT
        jr c,bs_k
        ld (hl),0
bs_k:   inc hl
        dec bc
        ld a,b
        or c
        jr nz,bs_l
        ret

play_foreign:
        call emap_save
        ld a,(v_curx)
        ld (sv_curx),a
        ld a,(v_cury)
        ld (sv_cury),a
        ld a,(v_scrx)
        ld (sv_scrx),a
        ld a,(v_valid)
        ld (sv_valid),a
        call blob_decode
        ld a,1
        ld (p_foreign),a
        call do_play
        xor a
        ld (p_foreign),a
        call emap_load
        ld a,(sv_curx)
        ld (v_curx),a
        ld a,(sv_cury)
        ld (v_cury),a
        ld a,(sv_scrx)
        ld (v_scrx),a
        ld a,(sv_valid)
        ld (v_valid),a
        ld a,1
        ld (v_redr),a
        ld (v_dirty),a
        ret

; mappa dell'editor <-> VRAM 0x19000
; la mappa dell'editor + la tabella dei nemici (C000-C6FF) si salvano in VRAM durante la prova di un livello altrui:
; la mappa in pagina 1 righe 212..223 (0xEA00), la tabella in pagina 0 riga 228 (0x7200)
emap_save:
        ld a,3
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x6A
        out (0x99),a
        ld hl,MAP
        ld b,6
es2_l:  push bc
        ld bc,0x0098
        otir
        pop bc
        djnz es2_l
        ld a,1
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x72
        out (0x99),a
        ld bc,0x0098
        otir                    ; HL = EPT (subito dopo la mappa): 256 byte
        ret

emap_load:
        ld a,3
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x2A
        out (0x99),a
        ld hl,MAP
        ld b,6
el2_l:  push bc
        ld bc,0x0098
        inir
        pop bc
        djnz el2_l
        ld a,1
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x32
        out (0x99),a
        ld bc,0x0098
        inir
        ret

hide_cursor:
        ld hl,0x7600
        call vram_w
        ld a,216
        out (0x98),a
        ret

s_brtitle: db "SERVER LEVELS  page ",0
s_brh1:    db "UP/DOWN select  LEFT/RIGHT page",0
s_brh2:    db "ENTER download+play  ESC back",0
m_brload:  db "Loading list...",0
m_brget:   db "Downloading level...",0
m_nolev:   db "No levels",0
m_toobig:  db "Level too big",0
m_badfmt:  db "Unsupported format",0
m_srverr:  db "Server error",0
m_fwon:    db "  Level cleared!",0
