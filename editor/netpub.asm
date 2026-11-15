; netpub.asm - pubblicazione della bozza sul server (UNAPI/UDP). Modulo eseguito in RAM (NETRT):
; il codice che chiama UNAPI deve stare in pagina 3, perche' la chiamata inter-slot commuta la pagina 1.
; Ingresso: NETRT (net_publish). Usa SETREC (impostazioni, 128 B) e REC (record bozza; blob a REC+5).
; Uscita: A = 0 ok (n_newid = id assegnato), 1 niente UNAPI, 2 DNS, 3 UDP non apre,
;         4 nessuna risposta, 5 credenziali rifiutate, 6 altro rifiuto (n_status).
; Protocollo: net/server/levelserver.py (PUTBEG/PUTCHK/PUTEND). Solo funzioni UNAPI standard.
        disp NETRT
        jp net_publish          ; tabella di ingresso: NETRT+0 pubblica, +3 elenco, +6 scarica
        jp net_list
        jp net_get

net_publish:
        ei
        call n_open
        or a
        jr nz,np_ret
        call n_put
        push af
        call n_close
        pop af
np_ret: di
        ret

; sessione: UNAPI + DNS + UDP aperto (A = 0 ok, altrimenti codice d'errore)
n_open: call n_discover
        or a
        ret nz
        call n_static
        call n_resolve
        or a
        ret nz
        ld hl,0xFFFF            ; UDP_OPEN, porta casuale
        ld b,0
        ld a,8
        call ucall
        or a
        ld a,3
        ret nz
        ld a,b
        ld (conn),a
        xor a
        ret

n_close:
        ld a,(conn)
        ld b,a
        ld a,9                  ; UDP_CLOSE
        jp ucall

; A = pagina -> RXBUF = risposta dell'elenco (6 livelli per pagina). Uscita: A = 0 ok
net_list:
        ld (nl_pg),a
        ei
        call n_open
        or a
        jr nz,nl_ret
        ld a,1                  ; LIST
        call hdr
        ld a,(nl_pg)
        ld (TXBUF+2),a
        ld bc,3
        call txn
        or a
        jr nz,nl_tmo
        ld a,(RXBUF+2)
        or a
        jr nz,nl_st
        call n_close
        xor a
        jr nl_ret
nl_tmo: call n_close
        ld a,4
        jr nl_ret
nl_st:  ld (n_status),a
        call n_close
        ld a,6
nl_ret: di
        ret

; HL = id -> il livello va in REC (n_glen = lunghezza). Uscita: A = 0 ok, 7 = troppo grande
net_get:
        ld (gid),hl
        ei
        call n_open
        or a
        jp nz,ng_ret
        ld hl,0
        ld (goff),hl
ng_l:   ld a,2                  ; GET
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
        jp nz,ng_tmo
        ld a,(RXBUF+2)
        or a
        jp nz,ng_st
        ld hl,(RXBUF+7)         ; lunghezza totale
        ld (n_glen),hl
        ld de,4097
        or a
        sbc hl,de
        jr nc,ng_big
        ld a,(RXBUF+9)
        or a
        jr z,ng_zero
        ld c,a
        ld b,0
        ld hl,(goff)
        ld de,REC
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
        ld de,(n_glen)
        or a
        sbc hl,de
        jr c,ng_l
        call n_close
        xor a
        jr ng_ret
ng_zero:
        ld a,6
        ld (n_status),a
        call n_close
        ld a,6
        jr ng_ret
ng_big: call n_close
        ld a,7
        jr ng_ret
ng_tmo: call n_close
        ld a,4
        jr ng_ret
ng_st:  ld (n_status),a
        call n_close
        ld a,6
ng_ret: di
        ret

; IP statico (impostazioni: bit0 di SETREC+3): CONFIG_AUTOIP (25) -> manuale, poi CONFIG_IP (26) per
; IP locale, maschera, gateway e DNS primario. Se la scheda non lo supporta gli errori si ignorano
; (resta la sua configurazione). Funzioni dalla specifica TCP/IP UNAPI 1.1; NON provate su schede reali.
n_static:
        ld a,(SETREC+3)
        and 1
        ret z
        ld a,25
        ld b,1
        ld c,0
        call ucall
        ld b,1
        ld hl,SETREC+4
        call n_setip
        ld b,3
        ld hl,SETREC+8
        call n_setip
        ld b,4
        ld hl,SETREC+0x0C
        call n_setip
        ld b,5
        ld hl,SETREC+0x10
n_setip:
        ld c,(hl)
        inc hl
        ld a,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld h,a
        ld l,c
        ld a,26
        jp ucall

n_discover:
        call setarg
        xor a
        ld b,a
        ld de,0x2222
        call EXTBIO
        ld a,b
        or a
        jr nz,nd_have
        ld a,1
        ret
nd_have:
        call setarg
        ld a,1
        ld de,0x2222
        call EXTBIO
        ld (u_slotb),a
        ld (u_entry),hl
        xor a
        ret

; IP e porta del server: DNS sul nome se presente, altrimenti l'IP delle impostazioni
n_resolve:
        ld a,(SETREC+0x1A)
        or a
        jr z,nr_ip
        ld hl,SETREC+0x1A
        ld b,0
        ld a,6                  ; DNS_Q
        call ucall
        or a
        jr nz,nr_ip
        call dnswait
        or a
        jr z,nr_port
nr_ip:  ld hl,SETREC+0x14
        ld a,(hl)
        or a
        ld a,2
        ret z                   ; ne' DNS ne' IP: errore
        ld de,blk
        ld bc,4
        ldir
nr_port:
        ld hl,(SETREC+0x18)
        ld (blk+4),hl
        xor a
        ret

n_put:  ld hl,(REC+3)
        ld (n_size),hl
        ld a,3                  ; PUTBEG
        call hdr
        ld hl,SETREC+0x36       ; utente
        ld de,TXBUF+2
        ld bc,12
        ldir
        ld hl,SETREC+0x42       ; chiave
        ld bc,16
        ldir
        ld hl,REC+5+8           ; titolo (dall'intestazione del livello)
        ld bc,16
        ldir
        ld hl,(n_size)
        ld (TXBUF+46),hl
        ld bc,48
        call txn
        or a
        jp nz,np_tmo
        ld a,(RXBUF+2)
        or a
        jp nz,np_st
        ld a,(RXBUF+3)
        ld (upid),a
        ld hl,0
        ld (poff),hl
np_ch:  ld hl,(n_size)
        ld de,(poff)
        or a
        sbc hl,de
        jr z,np_end
        ld a,h
        or a
        jr nz,np_big
        ld a,l
        cp 128
        jr c,np_n
np_big: ld a,128
np_n:   ld (pn),a
        ld a,4                  ; PUTCHK
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
        ld de,REC+5
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
        jr nz,np_tmo
        ld a,(RXBUF+2)
        or a
        jr nz,np_st
        ld a,(pn)
        ld c,a
        ld b,0
        ld hl,(poff)
        add hl,bc
        ld (poff),hl
        jr np_ch
np_end: ld a,5                  ; PUTEND
        call hdr
        ld a,(upid)
        ld (TXBUF+2),a
        ld bc,3
        call txn
        or a
        jr nz,np_tmo
        ld a,(RXBUF+2)
        or a
        jr nz,np_st
        ld hl,(RXBUF+3)
        ld (n_newid),hl
        xor a
        ret
np_tmo: ld a,4
        ret
np_st:  ld (n_status),a
        cp 1
        ld a,6
        ret nz
        ld a,5
        ret

; ---- trasporto: richiesta/risposta con rid, 3 tentativi da ~1 s ----
hdr:    ld (TXBUF),a
        ld a,(rid)
        inc a
        ld (rid),a
        ld (TXBUF+1),a
        ret

txn:    ld (tx_len),bc
        ld a,3
        ld (retries),a
tx_try: ld hl,TXBUF
        ld bc,(tx_len)
        call net_send
        xor a
        ld (fcnt),a
tx_wait:
        call net_poll
        jr z,tx_nodata
        ld a,(RXBUF+1)
        ld hl,TXBUF+1
        cp (hl)
        jr nz,tx_wait
        ld a,(TXBUF)
        or 0x80
        ld hl,RXBUF
        cp (hl)
        jr nz,tx_wait
        xor a
        ret
tx_nodata:
        halt
        ld a,(fcnt)
        inc a
        ld (fcnt),a
        cp 60
        jr c,tx_wait
        ld a,(retries)
        dec a
        ld (retries),a
        jr nz,tx_try
        ld a,0xFF
        ret

net_send:
        ld (blk_len),bc
        ld a,(conn)
        ld b,a
        ld de,blk
        ld a,11                 ; UDP_SEND
        jp ucall

net_poll:
        ld a,(conn)
        ld b,a
        ld a,10                 ; UDP_STATE
        call ucall
        ld a,b
        or a
        ret z
        ld a,(conn)
        ld b,a
        ld hl,RXBUF
        ld de,0x00FF
        ld a,12                 ; UDP_RCV
        call ucall
        or a
        jr nz,npl_none
        ld a,1
        or a
        ret
npl_none:
        xor a
        ret

dnswait:
        xor a
        ld (fcnt),a
dw_l:   ld b,0
        ld a,7                  ; DNS_S
        call ucall
        or a
        ret nz
        ld a,b
        cp 2
        jr z,dw_ok
        halt
        ld a,(fcnt)
        inc a
        ld (fcnt),a
        cp 200
        jr c,dw_l
        ld a,0xFE
        ret
dw_ok:  ld (blk),hl
        ld (blk+2),de
        xor a
        ret

setarg: ld hl,id_str
        ld de,ARG
        ld bc,7
        ldir
        ret
ucall:  rst 0x30                ; CALLF: chiamata inter-slot che conserva tutti i registri
u_slotb: db 0
u_entry: dw 0
        ei
        ret

id_str: db "TCP/IP",0
conn:   db 0
rid:    db 0
retries: db 0
fcnt:   db 0
upid:   db 0
pn:     db 0
tx_len: dw 0
poff:   dw 0
n_size: dw 0
n_newid: dw 0
n_status: db 0
nl_pg:  db 0
gid:    dw 0
goff:   dw 0
n_glen: dw 0
blk:    db 0,0,0,0
        dw 0                    ; porta
blk_len: dw 0
        ent
netrt_end:
