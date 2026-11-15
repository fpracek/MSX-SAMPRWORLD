; draft.asm - bozza del livello in flash Yamanooto (incluso da editor.asm)
; Settore bozza = 8 segmenti da 8K (64K allineati). Log di record: 'D','R',seq,len2,blob,somma.
; Un record non attraversa mai il confine tra segmenti. Il settore si cancella solo quando e'
; pieno o a livello pubblicato/nuovo. Le routine che toccano la flash stanno in RAM (flashrt).

init_map:
        xor a
        ld (ept_n),a            ; nessuna proprieta' dei nemici
        ld hl,MAP
        ld de,MAP+1
        ld bc,MAPW*MAPH-1
        ld (hl),0
        ldir
        ld hl,MAP+(MAPH-1)*MAPW
        ld b,MAPW
        ld a,T_GRASS
mapfl:  ld (hl),a
        inc hl
        djnz mapfl
        ret

getslot:
        in a,(0xA8)
        rrca
        rrca
        and 3
        ld e,a
        ld d,0
        ld hl,EXPTBL
        add hl,de
        ld a,(hl)
        and 0x80
        jr z,gsr
        ld hl,SLTTBL
        add hl,de
        ld a,(hl)
        and 0x0C
        or 0x80
        or e
        ret
gsr:    ld a,e
        ret

set_dseg:                       ; A = segmento 0-7 del settore bozza -> finestra 8000
        add a,DRAFTSEG
        ld (BANKW),a
        ret

; CRC16-CCITT-FALSE di BC byte da (HL) -> DE
crc16:  ld de,0xFFFF
c16b:   ld a,(hl)
        inc hl
        xor d
        ld d,a
        push bc
        ld b,8
c16t:   sla e
        rl d
        jr nc,c16n
        ld a,d
        xor 0x10
        ld d,a
        ld a,e
        xor 0x21
        ld e,a
c16n:   djnz c16t
        pop bc
        dec bc
        ld a,b
        or c
        jr nz,c16b
        ret

; scorre il settore: v_lvalid/v_lseg/v_lpos = ultimo record valido, v_fseg/v_fpos = primo spazio libero
scan_draft:
        xor a
        ld (v_lvalid),a
        ld (v_fseg),a
        ld (v_segi),a
        ld hl,0x8000
        ld (v_fpos),hl
        inc a
        ld (v_seq),a
        xor a
        call set_dseg
        ld ix,0x8000
sd_rec: push ix
        pop hl
        ld de,0x9FFA
        or a
        sbc hl,de
        jp nc,sd_full
        ld a,(ix+0)
        cp 0xFF
        jr z,sd_end
        cp 'D'
        jr nz,sd_full
        ld a,(ix+1)
        cp 'R'
        jr nz,sd_full
        ld e,(ix+3)
        ld d,(ix+4)
        push ix
        pop hl
        add hl,de
        ld de,7
        add hl,de               ; HL = fine del record
        push hl
        ld de,0xA001
        or a
        sbc hl,de
        pop hl
        jr nc,sd_full
        push hl
        push ix
        pop de
        or a
        sbc hl,de               ; HL = lunghezza record
        ld b,h
        ld c,l
        push ix
        pop hl
        ld d,0
sd_sum: ld a,d
        add a,(hl)
        ld d,a
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,sd_sum
        pop hl                  ; fine record
        ld a,d
        or a
        jr nz,sd_next           ; somma errata: record incompleto, lo salto
        ld a,(v_segi)
        ld (v_lseg),a
        push ix
        pop de
        ld (v_lpos),de
        ld a,1
        ld (v_lvalid),a
        ld a,(ix+2)
        inc a
        ld (v_seq),a
sd_next:
        ld de,15
        add hl,de
        ld a,l
        and 0xF0
        ld l,a
        push hl
        pop ix
        jr sd_rec
sd_end: push ix
        pop hl
        ld de,0x8000
        or a
        sbc hl,de
        jr z,sd_nseg            ; segmento vuoto
        ld a,(v_segi)
        ld (v_fseg),a
        push ix
        pop hl
        ld (v_fpos),hl
        jr sd_nseg
sd_full:
        ld a,(v_segi)
        ld (v_fseg),a
        ld hl,0xA000
        ld (v_fpos),hl
sd_nseg:
        ld a,(v_segi)
        inc a
        ld (v_segi),a
        cp 8
        ret nc
        call set_dseg
        ld ix,0x8000
        jp sd_rec

; compone il record in REC (mappa -> RLE -> CRC16 -> somma); v_rlen = lunghezza
build_record:
        call ept_prune
        ld hl,lvhdr
        ld de,REC+5
        ld bc,25
        ldir
        ld a,(ept_n)
        ld (REC+5+24),a         ; n_ent
        or a
        jr z,br_ne
        add a,a
        add a,a
        add a,a
        ld c,a
        ld b,0
        ld hl,EPT
        ldir                    ; record dei nemici (8 byte ciascuno)
br_ne:  ld hl,MAP
        ld bc,MAPW*MAPH
rl_next:
        ld a,b
        or c
        jr z,rl_done
        ld a,(hl)
        ld (v_rt),a
        xor a
        ld (v_rn),a
rl_run: ld a,(v_rn)
        inc a
        ld (v_rn),a
        inc hl
        dec bc
        ld a,b
        or c
        jr z,rl_emit
        ld a,(v_rn)
        cp 255
        jr z,rl_emit
        ld a,(v_rt)
        cp (hl)
        jr z,rl_run
rl_emit:
        ld a,(v_rn)
        cp 3
        jr nc,rl_rep
rl_lit: ld a,(v_rt)
        ld (de),a
        inc de
        ld a,(v_rn)
        dec a
        ld (v_rn),a
        jr nz,rl_lit
        jr rl_next
rl_rep: ld a,(v_rt)
        or 0x80
        ld (de),a
        inc de
        ld a,(v_rn)
        ld (de),a
        inc de
        jr rl_next
rl_done:
        push de                 ; fine dati
        ex de,hl
        ld de,REC+5
        or a
        sbc hl,de
        ld b,h
        ld c,l
        ld hl,REC+5
        call crc16              ; DE = CRC16 del blob
        pop hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        push hl                 ; posizione della somma di controllo
        ld de,REC+5
        or a
        sbc hl,de               ; HL = lunghezza del blob
        ld a,'D'
        ld (REC),a
        ld a,'R'
        ld (REC+1),a
        ld a,(v_seq)
        ld (REC+2),a
        ld a,l
        ld (REC+3),a
        ld a,h
        ld (REC+4),a
        pop hl
        ld a,(v_valid)
        ld (hl),a               ; byte 'superato' dopo il blob
        inc hl
        push hl
        ld de,REC
        or a
        sbc hl,de
        ld b,h
        ld c,l
        ld hl,REC
        ld d,0
cs_lp:  ld a,d
        add a,(hl)
        ld d,a
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,cs_lp
        ld a,d
        neg
        pop hl
        ld (hl),a
        inc hl
        ld de,REC
        or a
        sbc hl,de
        ld (v_rlen),hl
        ret

; scrive REC nel settore bozza (erase se pieno) e verifica. CF=1 se errore
write_record:
        xor a
        ld (v_perr),a
        ld hl,(v_fpos)
        ld de,(v_rlen)
        add hl,de
        ld de,0xA001
        or a
        sbc hl,de
        jr c,wr_fits            ; sta nel segmento corrente
        ld a,(v_fseg)
        inc a
        ld (v_fseg),a
        ld hl,0x8000
        ld (v_fpos),hl
        cp 8
        jr c,wr_fits
        call erase_draft        ; settore pieno: si ricomincia da capo
        jr c,wr_err
        xor a
        ld (v_fseg),a
wr_fits:
        ld a,(v_fseg)
        call set_dseg
        ld hl,(v_fpos)          ; la zona di destinazione deve essere vuota (FF): altrimenti la flash non puo' programmarla
        ld bc,(v_rlen)
wr_bl:  ld a,(hl)
        inc a
        jr nz,wr_dirty
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,wr_bl
        jr wr_go
wr_dirty:
        call erase_draft        ; residui nel settore: si cancella e si riparte da capo
        jr c,wr_err
        xor a
        ld (v_fseg),a
        ld hl,0x8000
        ld (v_fpos),hl
wr_go:
        ld hl,(v_fpos)
        ld de,REC
        ld iy,(v_rlen)
wr_lp:  ld a,(de)
        cp 0xFF
        jr z,wr_sk
        ld c,a
        call FLRT               ; ram_prog: HL = destinazione, C = dato
        jr c,wr_err             ; nessuna risposta dalla flash: ci si ferma subito
wr_sk:  inc hl
        inc de
        dec iy
        ld a,iyh
        or iyl
        jr nz,wr_lp
        ld a,(v_perr)
        or a
        jr nz,wr_err
        ld hl,(v_fpos)          ; verifica
        ld de,REC
        ld iy,(v_rlen)
wr_vl:  ld a,(de)
        cp (hl)
        jr nz,wr_err
        inc hl
        inc de
        dec iy
        ld a,iyh
        or iyl
        jr nz,wr_vl
        or a
        ret
wr_err: scf
        ret

erase_draft:                    ; CF=1 se timeout
        xor a
        call set_dseg
        jp ram_erase

; ---- azioni dei tasti ----
do_save:
        ld a,(v_flash)
        or a
        jr z,dsv_e              ; senza flash non si tenta nemmeno la scrittura
        call scan_draft
        call build_record
        call write_record
        jr c,dsv_e
        xor a
        ld (v_unsaved),a        ; il disegno e' tutto in flash
        ld hl,m_saved
        jr dsv
dsv_e:  ld hl,m_err
dsv:    ld (v_msg),hl
        ld a,1
        ld (v_dirty),a
        ret

        IF DEVBUILD
do_devvalid:                    ; SOLO SVILUPPO: segna il livello come superato e lo salva
        ld a,1
        ld (v_valid),a
        call do_save
        ld hl,m_devval
        ld (v_msg),hl
        ret
        ENDIF

do_load:
        call load_draft
        xor a
        ld (v_unsaved),a
        ld a,1
        ld (v_redr),a
        ld (v_dirty),a
        ret

do_new:
        ld a,(v_conf)
        or a
        jr nz,dn_go
        ld a,180                ; ~3 s per confermare: la bozza puo' valere giorni di lavoro
        ld (v_conf),a
        ld hl,m_confirm
        ld (v_msg),hl
        ld a,1
        ld (v_dirty),a
        ret
dn_go:  xor a
        ld (v_conf),a
        ld (v_unsaved),a
        ld (v_valid),a
        call init_map
        call erase_draft
        ld hl,m_erased
        jr nc,dnw
        ld hl,m_err
dnw:    ld (v_msg),hl
        ld a,1
        ld (v_redr),a
        ld (v_dirty),a
        ret

; carica l'ultima bozza valida nella mappa; imposta v_msg
load_draft:
        xor a
        ld (v_valid),a
        call scan_draft
        ld hl,m_none
        ld (v_msg),hl
        ld a,(v_lvalid)
        or a
        ret z
        ld a,(v_lseg)
        call set_dseg
        ld ix,(v_lpos)
        ld a,(ix+5)
        cp 'L'
        jp nz,ld_bad
        ld a,(ix+6)
        cp 'V'
        jp nz,ld_bad
        ld a,(ix+8)
        cp MAPW
        jp nz,ld_inc
        ld a,(ix+9)
        cp MAPH
        jp nz,ld_inc
        ld e,(ix+3)
        ld d,(ix+4)             ; DE = lunghezza blob
        push ix
        pop hl
        ld bc,5
        add hl,bc               ; HL = inizio blob
        push hl
        push de
        dec de
        dec de
        ld b,d
        ld c,e
        call crc16              ; DE = CRC calcolato
        pop bc                  ; lunghezza blob
        pop hl
        add hl,bc
        dec hl
        dec hl                  ; HL -> CRC memorizzato
        ld a,(hl)
        cp e
        jr nz,ld_bad
        inc hl
        ld a,(hl)
        cp d
        jr nz,ld_bad
        inc hl
        ld a,(hl)               ; byte 'superato'
        and 1
        ld (v_valid),a
        ld a,(ix+5+24)          ; n_ent
        cp EP_MAX+1
        jp nc,ld_bad
        push ix                 ; decodifica RLE
        pop hl
        ld bc,5+25
        add hl,bc
        ld (ept_n),a
        or a
        jr z,ld_ne
        add a,a
        add a,a
        add a,a
        ld c,a
        ld b,0
        ld de,EPT
        ldir                    ; record dei nemici
ld_ne:  ld de,MAP
        ld bc,MAPW*MAPH
ld_lp:  ld a,(hl)
        inc hl
        bit 7,a
        jr nz,ld_run
        ld (de),a
        inc de
        dec bc
        ld a,b
        or c
        jr nz,ld_lp
        jr ld_ok
ld_run: and 0x7F
        ld (v_rt),a
        ld a,(hl)
        inc hl
        ld (v_rn),a
ld_r2:  ld a,(v_rt)
        ld (de),a
        inc de
        dec bc
        ld a,b
        or c
        jr z,ld_ok
        ld a,(v_rn)
        dec a
        ld (v_rn),a
        jr nz,ld_r2
        jr ld_lp
ld_ok:  ld hl,m_loaded
        ld (v_msg),hl
        ret
ld_bad: ld hl,m_bad
        ld (v_msg),hl
        ret
ld_inc: ld hl,m_incomp
        ld (v_msg),hl
        ret

m_saved:  db "  Draft saved",0
m_confirm: db "  SELECT = confirm",0
m_devval: db "  Validated (DEV)",0
m_loaded: db "  Draft loaded",0
m_none:   db "  No draft",0
m_erased: db "  Draft erased",0
m_err:    db "  No flash found",0
m_nofl2:  db "  NO FLASH: not saved",0
m_bad:    db "  Draft corrupt",0
m_incomp: db "  Draft incompatible",0
; intestazione livello v1 (25 byte): LV, ver, w, h, start x/y, tema, titolo[16], n_ent
lvhdr:  db "LV",1,MAPW,MAPH,1,10,0
        db "Draft",0,0,0,0,0,0,0,0,0,0,0
        db 0

; routine che toccano la flash: eseguite in RAM (la flash in programmazione non e' leggibile)
flashrt_rom:
        disp FLRT
ram_prog:                       ; HL = destinazione (finestra 8000), C = dato -> CF=1 se timeout
        push de
        di
        ld a,0x10
        ld (ENAR),a             ; WREN
        ld a,0xAA
        ld (0x8AAA),a
        ld a,0x55
        ld (0x8555),a
        ld a,0xA0
        ld (0x8AAA),a
        ld (hl),c
        ld de,0x2000            ; timeout ~50 ms per byte: senza flash l'errore arriva subito
rpw:    ld a,(hl)
        cp c
        jr z,rpok
        dec de
        ld a,d
        or e
        jr nz,rpw
        xor a
        ld (ENAR),a
        pop de
        scf
        ret
rpok:   xor a
        ld (ENAR),a
        pop de
        ret
; rileva la flash AMD/Spansion (comando autoselect, codice produttore 01h). Gira in RAM e, se il mapper non e'
; quello della Yamanooto, rimette i banchi 1 (Konami5: 7000h, Konami4: 6000h) per non perdere il codice in ROM.
; Uscita: CF=0 flash presente, CF=1 assente
ram_probe:
        di
        ld a,0x10
        ld (ENAR),a
        ld a,0xAA
        ld (0x8AAA),a
        ld a,0x55
        ld (0x8555),a
        ld a,0x90
        ld (0x8AAA),a
        ld a,(0x8000)
        ld b,a
        ld a,0xF0
        ld (0x8000),a           ; torna in lettura
        xor a
        ld (ENAR),a
        ld a,1
        ld (0x7000),a           ; ripristino dei banchi di codice (innocuo sulla Yamanooto)
        ld (0x6000),a
        ld a,b
        cp 0x01
        scf
        ret nz
        ccf
        ret
ram_erase:                      ; erase del settore mappato in finestra 8000 -> CF=1 se timeout
        di
        ld a,0x10
        ld (ENAR),a
        ld a,0xAA
        ld (0x8AAA),a
        ld a,0x55
        ld (0x8555),a
        ld a,0x80
        ld (0x8AAA),a
        ld a,0xAA
        ld (0x8AAA),a
        ld a,0x55
        ld (0x8555),a
        ld a,0x30
        ld (0x8000),a
        ld b,32
reo:    ld de,0
ree:    ld a,(0x8000)
        cp 0xFF
        jr z,redn
        dec de
        ld a,d
        or e
        jr nz,ree
        djnz reo
        xor a
        ld (ENAR),a
        scf
        ret
redn:   xor a
        ld (ENAR),a
        ret
        ent
flashrt_end:

; salva la bozza solo se ci sono modifiche non ancora salvate (prima del menu e della prova)
autosave:
        ld a,(v_unsaved)
        or a
        ret z
        jp do_save
