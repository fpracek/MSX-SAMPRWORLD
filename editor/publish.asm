; publish.asm - lettura impostazioni dalla flash e tasto U (pubblica) - incluso da editor.asm
; Settore impostazioni = 8 segmenti da 8K (SETSEG..). Record da 128 B (vedi docs/FLASH.md), l'ultimo valido vince.

; copia l'ultimo record impostazioni valido in SETREC. CF=1 se non ce n'e'
load_settings:
        xor a
        ld (v_sfound),a
        ld b,0                  ; segmento
ls_seg: ld a,b
        add a,SETSEG
        ld (BANKW),a
        ld ix,0x8000
        ld c,64                 ; record per segmento
ls_rec: ld a,(ix+0)
        cp 0xFF
        jr z,ls_end             ; fine del log
        cp 'N'
        jr nz,ls_next
        ld a,(ix+1)
        cp 'S'
        jr nz,ls_next
        push bc
        push ix
        pop hl
        ld b,128
        xor a
ls_sum: add a,(hl)
        inc hl
        djnz ls_sum
        pop bc
        or a
        jr nz,ls_next
        push bc
        push ix
        pop hl
        ld de,SETREC
        ld bc,128
        ldir
        pop bc
        ld a,1
        ld (v_sfound),a
ls_next:
        ld de,128
        add ix,de
        dec c
        jr nz,ls_rec
        inc b
        ld a,b
        cp 8
        jr c,ls_seg
ls_end: ld a,(v_sfound)
        or a
        scf
        ret z
        or a                    ; CF=0
        ret

; tasto U: pubblica la bozza corrente
do_publish:
        ld a,(v_valid)
        or a
        ld hl,m_notval
        jr z,dpm                ; un livello si pubblica solo dopo che il creatore lo ha superato
        call load_settings
        ld hl,m_nosett
        jr c,dpm
        call build_record       ; REC <- mappa corrente (CRC16 compreso)
        ld hl,m_pubing
        ld (v_msg),hl
        call draw_status        ; mostra subito "Pubblico..."
        call NETRT              ; A = esito
        or a
        jr z,dp_ok
        ld hl,m_nounapi
        cp 1
        jr z,dpm
        ld hl,m_dns
        cp 2
        jr z,dpm
        ld hl,m_noopen
        cp 3
        jr z,dpm
        ld hl,m_notmo
        cp 4
        jr z,dpm
        ld hl,m_auth
        cp 5
        jr z,dpm
        ld a,(n_status)         ; altro rifiuto: mostra lo stato
        ld l,a
        ld h,0
        ld (v_msgnum),hl
        ld a,1
        ld (v_msgnf),a
        ld hl,m_refused
        jr dpm
dp_ok:  ld hl,(n_newid)
        ld (v_msgnum),hl
        ld a,1
        ld (v_msgnf),a
        call erase_draft        ; pubblicato: la bozza si cancella
        push af
        xor a
        ld (v_valid),a          ; niente doppia pubblicazione dello stesso livello
        pop af
        ld hl,m_pubok
        jr nc,dpm
        ld hl,m_err
dpm:    ld (v_msg),hl
        ld a,1
        ld (v_dirty),a
        ret

; stampa HL in decimale senza zeri iniziali
printdec16:
        ld b,0
        ld de,10000
        call pd16
        ld de,1000
        call pd16
        ld de,100
        call pd16
        ld de,10
        call pd16
        ld a,l
        add a,'0'
        jp print_char
pd16:   ld c,'0'-1
pd16s:  inc c
        or a
        sbc hl,de
        jr nc,pd16s
        add hl,de
        ld a,c
        cp '0'
        jr nz,pd16p
        ld a,b
        or a
        ret z
        ld a,'0'
pd16p:  ld b,1
        jp print_char

m_nosett: db "  No settings",0
m_notval: db "  Clear it first",0
m_pubing: db "  Publishing...",0
m_nounapi: db "  No UNAPI card",0
m_dns:    db "  DNS failed",0
m_noopen: db "  UDP open failed",0
m_notmo:  db "  Server not answering",0
m_auth:   db "  Wrong credentials",0
m_refused: db "  Refused, status ",0
m_pubok:  db "  Published id ",0
