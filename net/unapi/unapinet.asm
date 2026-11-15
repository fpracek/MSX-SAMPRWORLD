; unapinet.asm - driver ROM 16K: implementazione MSX-UNAPI "TCP/IP" sopra al bridge
; openMSX UnapiNet (porte 28h/29h). Funzioni 0-5 (info, capab, ipinfo, netstate, echo).
; Un client NON parla mai alle porte: usa solo UNAPI (EXTBIO + CALSLT), quindi lo
; stesso client funziona con qualunque altra implementazione ROM TCP/IP UNAPI.
        output "unapinet.rom"
IO_CMD   equ 0x28
IO_DATA  equ 0x29
CMD_DNS_QUERY equ 0x01
CMD_DNS_STATUS equ 0x02
CMD_UDP_OPEN equ 0x09
CMD_UDP_CLOSE equ 0x0A
CMD_UDP_STATE equ 0x0B
CMD_UDP_SEND equ 0x0C
CMD_UDP_RECV equ 0x0F
CMD_LOCALIP equ 0x0D
CMD_NETSTATE equ 0x0E
CMD_ICMP_SEND equ 0x11
CMD_ICMP_RECV equ 0x12
CHPUT    equ 0x00A2
EXTBIO   equ 0xFFCA
HOKVLD   equ 0xFB20
ARG      equ 0xF847
SLTWRK   equ 0xFD09
EXPTBL   equ 0xFCC1
SLTTBL   equ 0xFCC5
NFUNC    equ 30

        org 0x4000
        db "AB"
        dw init,0,0,0,0,0,0

init:   di
        ld a,(HOKVLD)
        bit 0,a
        jr nz,.hv
        or 1
        ld (HOKVLD),a
        ld hl,EXTBIO
        ld b,5
.fill:  ld (hl),0xC9
        inc hl
        djnz .fill
.hv:    call getwrk             ; HL = area di lavoro (8 byte) di questo slot
        ex de,hl
        ld hl,EXTBIO
        ld bc,5
        ldir                    ; salva il vecchio hook
        call getslt             ; A = slot id
        ld hl,EXTBIO
        ld (hl),0xF7            ; RST 30h = CALLF
        inc hl
        ld (hl),a
        inc hl
        ld (hl),do_extbio & 0xFF
        inc hl
        ld (hl),do_extbio >> 8
        inc hl
        ld (hl),0xC9
        ei
        ld hl,banner
.pb:    ld a,(hl)
        inc hl
        or a
        ret z
        call CHPUT
        jr .pb

; ---- gestore EXTBIO (chiamato con RST 30h, il nostro slot in pagina 1) ----
do_extbio:
        push af
        ld a,d
        cp 0x22
        jr nz,.pass1
        ld a,e
        cp 0x22
        jr nz,.pass1
        pop af
        cp 0xFF
        jr z,pass_old
        push af
        push hl
        push de
        ld hl,ARG
        ld de,id_str
.cmp:   ld a,(hl)
        call toupper
        ex de,hl
        cp (hl)
        ex de,hl
        jr nz,.nomatch
        or a
        jr z,.match
        inc hl
        inc de
        jr .cmp
.nomatch:
        pop de
        pop hl
        pop af
        jr pass_old
.match: pop de
        pop hl
        pop af
        or a
        jr z,.count
        cp 1
        jr z,.info
        dec a
        jr pass_old
.count: inc b
        jr pass_old
.info:  push de
        call getslt
        pop de
        ld b,0xFF               ; segmento fittizio = ROM
        ld hl,unapi_entry
        ret
.pass1: pop af
pass_old:                       ; catena al vecchio hook, registri intatti
        push de
        push hl
        push af
        call getwrk
        ex de,hl                ; DE = area di lavoro (vecchio hook)
        pop af
        pop hl
        ex de,hl                ; HL = hook, DE = HL originale
        ex (sp),hl              ; HL = DE originale, in cima allo stack = hook
        ex de,hl                ; HL e DE originali
        ret                     ; salta al vecchio hook

toupper: cp 'a'
        ret c
        cp 'z'+1
        ret nc
        sub 32
        ret

; A = slot id (formato CALSLT) della pagina 1; usa DE, HL
getslt: in a,(0xA8)
        rrca
        rrca
        and 3
        ld e,a
        ld d,0
        ld hl,EXPTBL
        add hl,de
        ld a,(hl)
        and 0x80
        jr z,.r
        ld hl,SLTTBL
        add hl,de
        ld a,(hl)
        and 0x0C
        or 0x80
        or e
        ret
.r:     ld a,e
        ret

; HL = area di lavoro di 8 byte (SLTWRK + p*32 + s*8); usa A, DE; BC intatto
getwrk: in a,(0xA8)
        rrca
        rrca
        and 3
        ld e,a                  ; E = slot primario
        ld d,0
        ld hl,EXPTBL
        add hl,de
        ld a,(hl)
        and 0x80
        ld a,0
        jr z,.ns
        ld hl,SLTTBL
        add hl,de
        ld a,(hl)
        rrca
        rrca
        and 3
.ns:    ld d,a                  ; D = sottoslot
        ld a,e
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a                 ; p*32
        ld e,a
        ld a,d
        add a,a
        add a,a
        add a,a                 ; s*8
        add a,e
        ld e,a
        ld d,0
        ld hl,SLTWRK
        add hl,de
        ret

; ---- punto d'ingresso UNAPI: A = numero funzione ----
unapi_entry:
        bit 7,a
        ret nz
        cp NFUNC
        ret nc
        push de
        push hl
        ld e,a
        ld d,0
        ld hl,fntab
        add hl,de
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)               ; DE = gestore
        pop hl                  ; HL originale
        ex de,hl
        ex (sp),hl              ; HL = DE originale, cima stack = gestore
        ex de,hl                ; HL e DE originali
        ret                     ; salta al gestore

fntab:  dw f_info,f_capab,f_ipinfo,f_netstate,f_sendecho,f_rcvecho
        dw f_dnsq,f_dnss,f_udpopen,f_udpclose,f_udpstate,f_udpsend,f_udprcv
        dup NFUNC-13
        dw f_notimp
        edup

f_notimp:
        ld a,1                  ; ERR_NOT_IMP
        ret

f_info: ld hl,info_str
        ld de,0x0101            ; API 1.1
        ld bc,0x0100            ; implementazione 1.0
        xor a
        ret

f_capab:
        ld a,b
        cp 1
        jr z,.b1
        cp 2
        jr z,.b2
        cp 3
        jr z,.b3
        cp 4
        jr z,.b4
        ld a,4                  ; ERR_INV_PARAM
        ret
.b1:    ld hl,0x0405            ; echo (bit0), DNS (bit2), UDP (bit10)
        ld de,0
        ld b,3                  ; Ethernet
        xor a
        ret
.b2:    ld bc,0x0004            ; max TCP 0, max UDP 4
        ld de,0x0004            ; liberi TCP 0, UDP 4
        ld hl,0
        xor a
        ret
.b3:    ld hl,1024
        ld de,1024
        xor a
        ret
.b4:    ld hl,0
        ld de,0
        xor a
        ret

f_ipinfo:
        ld a,b
        or a
        jr z,.bad
        cp 7
        jr nc,.bad
        cp 1
        jr z,.local
        ld hl,0                 ; indirizzi non noti al bridge: 0.0.0.0
        ld de,0
        xor a
        ret
.local: ld a,CMD_LOCALIP
        out (IO_CMD),a
        in a,(IO_DATA)          ; stato
        in a,(IO_DATA)
        ld l,a
        in a,(IO_DATA)
        ld h,a
        in a,(IO_DATA)
        ld e,a
        in a,(IO_DATA)
        ld d,a
        xor a
        ret
.bad:   ld a,4
        ret

f_netstate:
        ld a,CMD_NETSTATE
        out (IO_CMD),a
        in a,(IO_DATA)          ; stato
        in a,(IO_DATA)
        ld b,a
        xor a
        ret

f_sendecho:                     ; HL = blocco parametri (in pagina 3)
        ld b,11
.w:     ld a,(hl)
        out (IO_DATA),a
        inc hl
        djnz .w
        ld a,CMD_ICMP_SEND
        out (IO_CMD),a
        in a,(IO_DATA)
        or a
        ret z
        ld a,2                  ; ERR_NO_NETWORK
        ret

f_rcvecho:
        ld a,CMD_ICMP_RECV
        out (IO_CMD),a
        in a,(IO_DATA)
        or a
        jr nz,.nd
        ld b,11
.r:     in a,(IO_DATA)
        ld (hl),a
        inc hl
        djnz .r
        xor a
        ret
.nd:    ld a,3                  ; ERR_NO_DATA
        ret

; ---- DNS: il bridge vuole il nome SENZA terminatore NUL (verificato con sonda) ----
f_dnsq:                         ; HL = nome (ASCIIZ), B = flag
        bit 0,b
        jr z,.q
        xor a                   ; abort: nulla da fare
        ret
.q:     ld a,(hl)
        or a
        jr z,.go
        out (IO_DATA),a
        inc hl
        jr .q
.go:    ld a,CMD_DNS_QUERY
        out (IO_CMD),a
        in a,(IO_DATA)          ; 0 = avviata, 4 = nome non valido (codici = UNAPI)
        ld b,0                  ; stato: query in corso
        ret

f_dnss: ld a,CMD_DNS_STATUS
        out (IO_CMD),a
        in a,(IO_DATA)
        or a
        ret nz
        in a,(IO_DATA)          ; 0 nessuna, 1 in corso, 2 finita, FFh errore
        cp 2
        jr z,.done
        cp 0xFF
        jr z,.err
        ld b,a
        ld c,0
        xor a
        ret
.done:  in a,(IO_DATA)
        ld l,a
        in a,(IO_DATA)
        ld h,a
        in a,(IO_DATA)
        ld e,a
        in a,(IO_DATA)
        ld d,a
        ld b,2
        ld c,0
        xor a
        ret
.err:   in a,(IO_DATA)          ; codice errore DNS
        ld b,a
        ld a,8                  ; ERR_DNS
        ret

; ---- UDP (i codici d'errore del bridge coincidono con quelli UNAPI) ----
f_udpopen:                      ; HL = porta locale, B = durata
        ld a,b
        cp 2
        jr nc,.bad
        ld a,h
        or l
        jr z,.bad               ; porta 0
        ld a,h
        cp 0xFF
        jr nz,.ok
        ld a,l
        cp 0xF0
        jr c,.ok                ; FFF0..FFFE non valide, FFFF = casuale
        cp 0xFF
        jr nz,.bad
.ok:    ld a,l
        out (IO_DATA),a
        ld a,h
        out (IO_DATA),a
        ld a,CMD_UDP_OPEN
        out (IO_CMD),a
        in a,(IO_DATA)
        or a
        ret nz
        in a,(IO_DATA)
        ld b,a                  ; numero di connessione
        xor a
        ret
.bad:   ld a,4
        ret

f_udpclose:                     ; B = connessione (0 = tutte le transitorie: no-op)
        ld a,b
        or a
        ret z
        out (IO_DATA),a
        ld a,CMD_UDP_CLOSE
        out (IO_CMD),a
        in a,(IO_DATA)
        ret

f_udpstate:                     ; B = connessione -> B = in attesa, DE = dimensione
        ld a,b
        out (IO_DATA),a
        ld a,CMD_UDP_STATE
        out (IO_CMD),a
        in a,(IO_DATA)
        or a
        ret nz
        in a,(IO_DATA)
        ld e,a
        in a,(IO_DATA)
        ld d,a
        ld b,0
        ld a,d
        or e
        jr z,.n
        ld b,1                  ; (un datagramma vuoto e' indistinguibile da "nessuno")
.n:     ld hl,0                 ; porta locale non nota al bridge
        xor a
        ret

f_udpsend:                      ; B = conn, HL = dati, DE = blocco (IP4, porta2, len2)
        ld a,b
        out (IO_DATA),a
        ex de,hl                ; HL = blocco, DE = dati
        push hl
        ld bc,6
        add hl,bc
        ld c,(hl)
        inc hl
        ld b,(hl)               ; BC = lunghezza
        pop hl
        dup 8
        ld a,(hl)
        out (IO_DATA),a
        inc hl
        edup
        ex de,hl                ; HL = dati
.d:     ld a,b
        or c
        jr z,.go
        ld a,(hl)
        out (IO_DATA),a
        inc hl
        dec bc
        jr .d
.go:    ld a,CMD_UDP_SEND
        out (IO_CMD),a
        in a,(IO_DATA)
        ret

f_udprcv:                       ; B = conn, HL = destinazione, DE = max byte
        push hl                 ; destinazione
        ld a,b
        out (IO_DATA),a
        ld a,d
        and e
        cp 0xFF                 ; FFFFh = intero datagramma
        jr nz,.m
        ld de,1024
.m:     ld a,e
        out (IO_DATA),a
        ld a,d
        out (IO_DATA),a
        ld a,CMD_UDP_RECV
        out (IO_CMD),a
        in a,(IO_DATA)
        or a
        jr z,.ok
        pop hl
        ret                     ; errore (3 = nessun dato)
.ok:    in a,(IO_DATA)
        ld c,a
        in a,(IO_DATA)
        ld b,a
        push bc                 ; IP1 IP2
        in a,(IO_DATA)
        ld c,a
        in a,(IO_DATA)
        ld b,a
        push bc                 ; IP3 IP4
        in a,(IO_DATA)
        ld e,a
        in a,(IO_DATA)
        ld d,a
        push de                 ; porta
        in a,(IO_DATA)
        ld c,a
        in a,(IO_DATA)
        ld b,a                  ; BC = lunghezza
        push bc
        ld hl,8
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl                ; HL = destinazione
.c:     ld a,b
        or c
        jr z,.e
        in a,(IO_DATA)
        ld (hl),a
        inc hl
        dec bc
        jr .c
.e:     pop bc                  ; lunghezza
        pop ix                  ; porta
        pop de                  ; E=ip3 D=ip4
        pop hl                  ; L=ip1 H=ip2
        inc sp
        inc sp                  ; scarta la destinazione
        xor a
        ret

id_str:   db "TCP/IP",0
info_str: db "UnapiNet bridge (MSXMAKER)",0
banner:   db "UNAPI TCP/IP: UnapiNet bridge",13,10,0
        ds 0xC000-$,0xFF
