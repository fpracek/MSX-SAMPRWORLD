; client3.asm - client livelli via UDP (protocollo in server\levelserver.py), solo UNAPI.
; Ciclo: DNS server -> UDP open -> LIST -> GET (CRC) -> PUT autenticato -> LIST -> GET (CRC+dati)
        output "client3.rom"
CHPUT    equ 0x00A2
INITXT   equ 0x006C
LINL40   equ 0xF3AE
EXTBIO   equ 0xFFCA
ARG      equ 0xF847
V        equ 0xDE00
LEVEL    equ 0xCC00          ; buffer livello (3K)
LEVMAX   equ 0x0C00
TXBUF    equ 0xD800
RXBUF    equ 0xD900
; V+0 fine, +0x10 totale1, +0x11 get1, +0x12 begin, +0x13 end, +0x14/15 newid, +0x16 totale2,
; +0x17 get2, +0x18 pattern, +0x19 chunk inviati

        org 0x4000
        db "AB"
        dw start,0,0,0,0,0,0
start:  ld hl,payload
        ld de,0xC000
        ld bc,cl_end-0xC000
        ldir
        jp 0xC000
payload:
        disp 0xC000
main:   di
        ld sp,0xF380
        ld a,40
        ld (LINL40),a
        call INITXT
        ei
        xor a
        ld (V),a
        ld hl,msg_title
        call prints

        ; --- scoperta UNAPI ---
        call setarg
        xor a
        ld b,a
        ld de,0x2222
        call EXTBIO
        ld a,b
        or a
        jr nz,.have
        ld hl,msg_nounapi
        call prints
        jp fin
.have:  call setarg
        ld a,1
        ld de,0x2222
        call EXTBIO
        ld (u_slotb),a
        ld (u_entry),hl

        ; --- DNS del server ---
        ld hl,msg_srv
        call prints
        ld hl,srv_name
        call prints
        ld hl,srv_name
        ld b,0
        ld a,6
        call ucall
        or a
        jr nz,.dnsfail
        call dnswait
        or a
        jr z,.dnsok
.dnsfail:
        ld hl,msg_dnsfb
        call prints
.dnsok: ld hl,msg_arrow
        call prints
        ld hl,blk
        call printip
        call crlf

        ; --- UDP open (porta casuale) ---
        ld hl,0xFFFF
        ld b,0
        ld a,8
        call ucall
        or a
        jr z,.opened
        ld hl,msg_noopen
        call prints
        jp fin
.opened: ld a,b
        ld (conn),a

        ; --- 1) LIST ---
        ld hl,msg_list
        call prints
        xor a
        call do_list
        jp nz,fail
        ld hl,(RXBUF+3)
        ld a,l
        ld (V+0x10),a
        ld hl,(RXBUF+7)         ; id del primo livello
        ld (first_id),hl

        ; --- 2) GET del primo livello ---
        ld hl,msg_get
        call prints
        ld hl,(first_id)
        call printdec16
        ld hl,msg_colon
        call prints
        ld hl,(first_id)
        call do_get
        jp nz,fail
        call verify
        ld a,0
        jr z,.g1
        ld a,1
.g1:    ld (V+0x11),a
        call print_okko

        ; --- 3) PUT ---
        call do_put
        jp nz,fail

        ; --- 4) LIST di nuovo ---
        ld hl,msg_list
        call prints
        xor a
        call do_list
        jp nz,fail
        ld hl,(RXBUF+3)
        ld a,l
        ld (V+0x16),a

        ; --- 5) GET del livello appena caricato ---
        ld hl,msg_get
        call prints
        ld hl,(V+0x14)
        call printdec16
        ld hl,msg_colon
        call prints
        ld hl,(V+0x14)
        call do_get
        jp nz,fail
        call verify
        ld a,0
        jr z,.g2
        ld a,1
.g2:    ld (V+0x17),a
        push af
        call print_okko
        pop af
        ld hl,msg_pat
        call prints
        call check_pattern
        ld a,0
        jr z,.pt
        ld a,1
.pt:    ld (V+0x18),a
        call print_okko
        jr fin
fail:   ld hl,msg_fail
        call prints
fin:    ld a,0x55
        ld (V),a
        ld hl,msg_end
        call prints
.h:     halt
        jr .h

print_okko:                      ; A = 0 -> OK
        or a
        ld hl,msg_ok
        jr z,.p
        ld hl,msg_ko
.p:     jp prints

; ======================= protocollo ============================
hdr:    ld (TXBUF),a            ; A = codice operazione; assegna un nuovo rid
        ld a,(rid)
        inc a
        ld (rid),a
        ld (TXBUF+1),a
        ret

; invia TXBUF (BC byte) e attende la risposta con lo stesso rid; 3 tentativi da ~1 s
; uscita: A=0 ok (risposta in RXBUF), altrimenti 0xFF
txn:    ld (tx_len),bc
        ld a,3
        ld (retries),a
.try:   ld hl,TXBUF
        ld bc,(tx_len)
        call net_send
        xor a
        ld (fcnt),a
.wait:  call net_poll
        jr z,.nodata
        ld a,(RXBUF+1)          ; rid uguale?
        ld hl,TXBUF+1
        cp (hl)
        jr nz,.wait
        ld a,(TXBUF)
        or 0x80
        ld hl,RXBUF
        cp (hl)
        jr nz,.wait
        xor a
        ret
.nodata: halt
        ld a,(fcnt)
        inc a
        ld (fcnt),a
        cp 60
        jr c,.wait
        ld a,(retries)
        dec a
        ld (retries),a
        jr nz,.try
        ld a,0xFF
        ret

net_send:                       ; HL = dati, BC = lunghezza
        ld (blk_len),bc
        ld a,(conn)
        ld b,a
        ld de,blk
        ld a,11
        jp ucall

net_poll:                       ; NZ = datagramma ricevuto in RXBUF (rx_len)
        ld a,(conn)
        ld b,a
        ld a,10
        call ucall
        ld a,b
        or a
        ret z
        ld a,(conn)
        ld b,a
        ld hl,RXBUF
        ld de,0x00FF
        ld a,12
        call ucall
        or a
        jr nz,.none
        ld (rx_len),bc
        ld a,1
        or a
        ret
.none:  xor a
        ret

do_list:                        ; A = pagina; stampa i record; NZ = errore
        ld (pg),a
        ld a,1
        call hdr
        ld a,(pg)
        ld (TXBUF+2),a
        ld bc,3
        call txn
        or a
        jr nz,.err
        ld a,(RXBUF+2)
        or a
        jr nz,.err
        ld hl,(RXBUF+3)
        call printdec16
        ld hl,msg_levels
        call prints
        ld a,(RXBUF+6)
        ld b,a
        ld hl,RXBUF+7
.rec:   ld a,b
        or a
        jr z,.done
        push bc
        push hl
        ld a,' '
        call CHPUT
        ld a,' '
        call CHPUT
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        call printdec16         ; id
        ld a,' '
        call CHPUT
        pop hl
        push hl
        ld de,4
        add hl,de
        ld b,16
.t:     ld a,(hl)
        or a
        jr z,.te
        call CHPUT
        inc hl
        djnz .t
.te:    ld a,' '
        call CHPUT
        ld a,'('
        call CHPUT
        pop hl
        push hl
        inc hl
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        call printdec16         ; dimensione
        ld a,')'
        call CHPUT
        call crlf
        pop hl
        ld de,22
        add hl,de
        pop bc
        dec b
        jr .rec
.done:  xor a
        ret
.err:   ld a,1
        or a
        ret

do_get:                         ; HL = id; scarica a pezzi in LEVEL; NZ = errore
        ld (gid),hl
        ld hl,0
        ld (goff),hl
.loop:  ld a,2
        call hdr
        ld hl,(gid)
        ld (TXBUF+2),hl
        ld hl,(goff)
        ld (TXBUF+4),hl
        ld a,128
        ld (TXBUF+6),a
        ld bc,7
        call txn
        or a
        jr nz,.err
        ld a,(RXBUF+2)
        or a
        jr nz,.err
        ld hl,(RXBUF+7)
        ld (gtot),hl
        ld de,LEVMAX+1
        or a
        sbc hl,de
        jr nc,.err              ; troppo grande per il buffer
        ld a,(RXBUF+9)
        ld c,a
        ld b,0
        ld a,b
        or c
        jr z,.err
        ld hl,(goff)
        ld de,LEVEL
        add hl,de
        ex de,hl
        ld hl,RXBUF+10
        ldir
        ld a,(RXBUF+9)
        ld c,a
        ld b,0
        ld hl,(goff)
        add hl,bc
        ld (goff),hl
        ld de,(gtot)
        or a
        sbc hl,de
        jr c,.loop
        ld hl,(gtot)
        call printdec16
        ld hl,msg_bytes
        call prints
        xor a
        ret
.err:   ld a,1
        or a
        ret

verify:                         ; Z = magic "LV" e CRC16 corretti
        ld a,(LEVEL)
        cp 'L'
        jr nz,.bad
        ld a,(LEVEL+1)
        cp 'V'
        jr nz,.bad
        ld bc,(gtot)
        dec bc
        dec bc
        ld hl,LEVEL
        call crc16              ; DE
        ld hl,(gtot)
        ld bc,LEVEL-2
        add hl,bc
        ld c,(hl)
        inc hl
        ld b,(hl)
        ex de,hl
        or a
        sbc hl,bc
        ret                     ; Z se uguali
.bad:   ld a,1
        or a
        ret

check_pattern:                  ; i byte 2..297 del livello caricato valgono 0,1,2,...
        ld hl,LEVEL+2
        ld de,296
        ld c,0
.p:     ld a,(hl)
        cp c
        jr nz,.bad
        inc hl
        inc c
        dec de
        ld a,d
        or e
        jr nz,.p
        xor a
        ret
.bad:   ld a,1
        or a
        ret

do_put:                         ; costruisce un livello di prova (300 byte) e lo carica
        ld hl,msg_put
        call prints
        ld hl,LEVEL
        ld (hl),'L'
        inc hl
        ld (hl),'V'
        inc hl
        ld de,296
        ld c,0
.f:     ld (hl),c
        inc hl
        inc c
        dec de
        ld a,d
        or e
        jr nz,.f
        ld hl,LEVEL
        ld bc,298
        call crc16
        ld hl,LEVEL+298
        ld (hl),e
        inc hl
        ld (hl),d
        ; --- begin ---
        ld a,3
        call hdr
        ld hl,put_hdr
        ld de,TXBUF+2
        ld bc,44
        ldir
        ld hl,300
        ld (TXBUF+46),hl
        ld bc,48
        call txn
        or a
        jp nz,.err
        ld a,(RXBUF+2)
        ld (V+0x12),a
        or a
        jp nz,.err
        ld a,(RXBUF+3)
        ld (upid),a
        ; --- chunk da 128 ---
        ld hl,0
        ld (poff),hl
.ch:    ld hl,300
        ld de,(poff)
        or a
        sbc hl,de               ; restanti
        jr z,.end
        ld a,h
        or a
        jr nz,.big
        ld a,l
        cp 128
        jr c,.n
.big:   ld a,128
.n:     ld (pn),a
        ld a,4
        call hdr
        ld a,(upid)
        ld (TXBUF+2),a
        ld hl,(poff)
        ld (TXBUF+3),hl
        ld a,(pn)
        ld (TXBUF+5),a
        ld c,a
        ld b,0
        ld hl,(poff)
        ld de,LEVEL
        add hl,de
        ld de,TXBUF+6
        ldir
        ld a,(pn)
        ld c,a
        ld b,0
        ld hl,6
        add hl,bc
        ld b,h
        ld c,l
        call txn
        or a
        jr nz,.err
        ld a,(RXBUF+2)
        or a
        jr nz,.err
        ld a,(V+0x19)
        inc a
        ld (V+0x19),a
        ld a,(pn)
        ld c,a
        ld b,0
        ld hl,(poff)
        add hl,bc
        ld (poff),hl
        jr .ch
.end:   ld a,5
        call hdr
        ld a,(upid)
        ld (TXBUF+2),a
        ld bc,3
        call txn
        or a
        jr nz,.err
        ld a,(RXBUF+2)
        ld (V+0x13),a
        or a
        jr nz,.err
        ld hl,(RXBUF+3)
        ld (V+0x14),hl
        ld hl,(RXBUF+3)
        call printdec16
        ld hl,msg_newid
        call prints
        xor a
        ret
.err:   ld hl,msg_puterr
        call prints
        ld a,(RXBUF+2)
        ld l,a
        ld h,0
        call printdec16
        call crlf
        ld a,1
        or a
        ret

; CRC16-CCITT (init FFFF, poly 1021): HL = dati, BC = lunghezza -> DE
crc16:  ld de,0xFFFF
.b:     ld a,b
        or c
        ret z
        ld a,(hl)
        inc hl
        dec bc
        xor d
        ld d,a
        push bc
        ld b,8
.bit:   sla e
        rl d
        jr nc,.n
        ld a,d
        xor 0x10
        ld d,a
        ld a,e
        xor 0x21
        ld e,a
.n:     djnz .bit
        pop bc
        jr .b

dnswait:
        xor a
        ld (fcnt),a
.l:     ld b,0
        ld a,7
        call ucall
        or a
        ret nz
        ld a,b
        cp 2
        jr z,.ok
        halt
        ld a,(fcnt)
        inc a
        ld (fcnt),a
        cp 200
        jr c,.l
        ld a,0xFE
        ret
.ok:    ld (blk),hl
        ld (blk+2),de
        xor a
        ret

; ======================= utilita' ============================
setarg: ld hl,id_str
        ld de,ARG
        ld bc,7
        ldir
        ret
ucall:  rst 0x30                ; CALLF: conserva tutti i registri (IX incluso)
u_slotb: db 0
u_entry: dw 0
        ei                      ; CALLF lascia gli interrupt disabilitati
        ret
prints: ld a,(hl)
        inc hl
        or a
        ret z
        call CHPUT
        jr prints
crlf:   ld a,13
        call CHPUT
        ld a,10
        jp CHPUT
printdec:
        push bc
        ld c,0
        ld b,100
        call .d
        ld b,10
        call .d
        add a,'0'
        call CHPUT
        pop bc
        ret
.d:     ld e,'0'-1
.l:     inc e
        sub b
        jr nc,.l
        add a,b
        ld d,a
        ld a,e
        cp '0'
        jr nz,.pr
        bit 0,c
        jr z,.skip
.pr:    set 0,c
        call CHPUT
.skip:  ld a,d
        ret
printdec16:                     ; HL, senza zeri iniziali
        ld b,0
        ld de,10000
        call .d
        ld de,1000
        call .d
        ld de,100
        call .d
        ld de,10
        call .d
        ld a,l
        add a,'0'
        jp CHPUT
.d:     ld c,'0'-1
.s:     inc c
        or a
        sbc hl,de
        jr nc,.s
        add hl,de
        ld a,c
        cp '0'
        jr nz,.p
        ld a,b
        or a
        ret z
        ld a,'0'
.p:     ld b,1
        jp CHPUT
printip:
        ld b,4
.i:     ld a,(hl)
        inc hl
        push hl
        push bc
        call printdec
        pop bc
        pop hl
        dec b
        ret z
        push hl
        push bc
        ld a,'.'
        call CHPUT
        pop bc
        pop hl
        jr .i

; ---- variabili e dati ----
conn:    db 0
rid:     db 0
retries: db 0
fcnt:    db 0
pg:      db 0
upid:    db 0
pn:      db 0
tx_len:  dw 0
rx_len:  dw 0
gid:     dw 0
goff:    dw 0
gtot:    dw 0
poff:    dw 0
first_id: dw 0
blk:     db 127,0,0,1           ; IP del server (aggiornato dal DNS)
         dw 9100                ; porta
blk_len: dw 0
id_str:  db "TCP/IP",0
srv_name: db "localhost",0
put_hdr: db "testuser",0,0,0,0                  ; utente[12]
         db "TESTKEY-0123456",0                 ; chiave[16] (segnaposto)
         db "Livello prova",0,0,0               ; titolo[16]
msg_title: db "Client3: livelli via UDP",13,10,13,10,0
msg_nounapi: db "Nessuna impl. UNAPI",13,10,0
msg_srv:  db "Server ",0
msg_arrow: db " -> ",0
msg_dnsfb: db " (DNS fallito, uso default)",0
msg_noopen: db "UDP_OPEN fallita",13,10,0
msg_list: db "LIST: ",0
msg_levels: db " livelli",13,10,0
msg_get:  db "GET ",0
msg_colon: db ": ",0
msg_bytes: db " byte, CRC ",0
msg_ok:   db "OK",13,10,0
msg_ko:   db "ERRORE",13,10,0
msg_pat:  db "  dati identici: ",0
msg_put:  db "PUT livello prova... ",0
msg_newid: db " = nuovo id",13,10,0
msg_puterr: db "errore, stato ",0
msg_fail: db 13,10,"Errore di rete (timeout?)",13,10,0
msg_end:  db 13,10,"Fine.",0
cl_end:
        assert cl_end <= LEVEL
        ent
        ds 0xC000-$,0xFF
