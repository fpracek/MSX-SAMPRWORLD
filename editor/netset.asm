; netset.asm - tasto N: impostazioni di rete (server, porta, utente, chiave, DHCP/IP statico) salvate nel settore SET
; della flash come nuovo record da 128 byte (docs/FLASH.md). Tastiera letta direttamente dalla matrice (niente BIOS).
; Tasti: SU/GIU o TAB cambiano campo, si scrive, BS cancella, SPAZIO alterna DHCP/STATICO, INVIO salva, ESC annulla.
FBUF    equ 0xCC00
f_host  equ FBUF                ; 29
f_port  equ FBUF+0x1D           ; 6
f_user  equ FBUF+0x23           ; 13
f_key   equ FBUF+0x30           ; 17
f_mode  equ FBUF+0x41           ; 8
f_ip    equ FBUF+0x49           ; 4 x 16: locale, maschera, gateway, DNS
ns_i    equ FBUF+0x90
ns_prev equ FBUF+0x92           ; 6 righe della matrice (0..5)
ns_ch   equ FBUF+0x99
ns_lz   equ FBUF+0x9A
ns_nf   equ 9                   ; numero di campi
ns_ipbuf equ FBUF+0xA0          ; (in RAM: la ROM non e' scrivibile)

do_netset:
        call hide_cursor
        call ns_load
        xor a
        ld (ns_i),a
        ld hl,ns_prev
        ld de,ns_prev+1
        ld bc,5
        ld (hl),0xFF            ; i tasti gia' premuti all'ingresso non contano
        ldir
        call ns_draw_all
ns_loop:
        call vwait
        ld a,8
        ld hl,v_prev8
        call edge
        ld (v_e8),a
        ld a,7
        ld hl,v_prev7
        call edge
        ld (v_e7),a
        bit 2,a                 ; ESC: annulla
        jp nz,ns_exit
        bit 7,a                 ; INVIO: salva
        jp nz,ns_save
        bit 3,a                 ; TAB: campo successivo
        jp nz,ns_down
        bit 5,a                 ; BS
        jp nz,ns_bs
        ld a,(v_e8)
        bit 5,a                 ; SU
        jp nz,ns_up
        bit 6,a                 ; GIU
        jp nz,ns_down
        bit 0,a                 ; SPAZIO: alterna DHCP/STATICO sul campo Rete
        jr z,ns_keys
        ld a,(ns_i)
        cp 4
        jr nz,ns_keys
        ld hl,f_mode
        ld a,(hl)
        cp 'D'
        ld de,s_static
        jr z,ns_tg
        ld de,s_dhcp
ns_tg:  ex de,hl
        ld de,f_mode
        ld bc,8
        ldir
        ld a,4
        call ns_draw_field
        jr ns_loop
ns_keys:
        call ns_scan            ; A = carattere appena premuto (0 = nessuno)
        or a
        jr z,ns_loop
        call ns_type
        jr ns_loop
ns_exit:
        ld a,1
        ld (v_redr),a
        ld (v_dirty),a
        ret
ns_up:  ld a,(ns_i)
        or a
        jr z,ns_loop
        push af
        call ns_mark_off
        pop af
        dec a
        jr ns_mv
ns_down:
        ld a,(ns_i)
        cp ns_nf-1
        jp nc,ns_loop
        push af
        call ns_mark_off
        pop af
        inc a
ns_mv:  ld (ns_i),a
        ld a,(ns_i)
        call ns_draw_field
        jp ns_loop
ns_mark_off:                    ; ridisegna il campo corrente senza marcatore (il nuovo indice non e' ancora impostato)
        ld a,(ns_i)
        ld b,a
        ld a,0xFF
        ld (ns_i),a
        ld a,b
        push bc
        call ns_draw_field
        pop bc
        ld a,b
        ld (ns_i),a
        ret

; legge la matrice (righe 0..5) e restituisce il primo carattere nuovo
ns_scan:
        ld a,6
        call readrow
        cpl
        and 1
        ld e,a                  ; E = shift
        ld c,0                  ; riga
nss_r:  ld a,c
        call readrow
        cpl
        ld b,a
        ld hl,ns_prev
        ld d,0
        push bc
        ld a,c
        ld c,a
        ld b,0
        add hl,bc
        pop bc
        ld a,(hl)
        cpl
        and b
        ld d,a                  ; bit appena premuti
        ld (hl),b
        or a
        jr z,nss_n
        ld a,c                  ; riga * 8 + bit piu' basso
        add a,a
        add a,a
        add a,a
        ld b,a
        ld a,d
nss_b:  rrca
        jr c,nss_f
        inc b
        jr nss_b
nss_f:  ld hl,key_un
        ld a,e
        or a
        jr z,nss_t
        ld hl,key_sh
nss_t:  ld d,0
        ld e,b
        add hl,de
        ld a,(hl)
        or a
        ret nz
nss_n:  inc c
        ld a,c
        cp 6
        jr nz,nss_r
        xor a
        ret

; A = carattere: accoda al campo corrente se ammesso
ns_type:
        ld b,a
        ld a,(ns_i)
        call ns_desc            ; HL = descrittore
        ld a,(hl)               ; tipo
        cp 3
        ret z                   ; la modalita' si cambia con SPAZIO
        ld c,a
        push hl
        inc hl
        ld d,(hl)               ; lunghezza massima
        inc hl
        ld e,(hl)
        inc hl
        ld h,(hl)
        ld l,e                  ; HL = buffer
        push hl
        call strlen             ; A = lunghezza
        pop hl
        cp d
        jr nc,nst_no
        ld e,a
        ld a,c                  ; filtri per tipo
        cp 1
        jr nz,nst_t2
        ld a,b
        cp '0'
        jr c,nst_no
        cp '9'+1
        jr nc,nst_no
        jr nst_ok
nst_t2: cp 2
        jr nz,nst_t0
        ld a,b
        cp '.'
        jr z,nst_ok
        cp '0'
        jr c,nst_no
        cp '9'+1
        jr nc,nst_no
        jr nst_ok
nst_t0: ld a,b
        cp 33
        jr c,nst_no
        cp 127
        jr nc,nst_no
nst_ok: ld d,0
        add hl,de
        ld (hl),b
        inc hl
        ld (hl),0
        ld hl,88                ; stampa il carattere alla colonna 88 + lunghezza*8
        ld d,0
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        ld (GRPACX),hl
        pop hl
        inc hl
        inc hl
        inc hl
        inc hl
        inc hl
        inc hl
        ld a,(hl)               ; y
        ld l,a
        ld h,0
        ld (GRPACY),hl
        ld a,b
        jp print_char
nst_no: pop hl
        ret

ns_bs:  ld a,(ns_i)
        call ns_desc
        ld a,(hl)
        cp 3
        jp z,ns_loop
        push hl
        inc hl
        inc hl
        ld e,(hl)
        inc hl
        ld h,(hl)
        ld l,e
        push hl
        call strlen
        pop hl
        or a
        jr z,nbs_no
        dec a
        ld e,a
        ld d,0
        add hl,de
        ld (hl),0
        ld hl,88
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        ld (GRPACX),hl
        pop hl
        ld de,6
        add hl,de
        ld a,(hl)
        ld l,a
        ld h,0
        ld (GRPACY),hl
        ld a,' '
        call print_char
        jp ns_loop
nbs_no: pop hl
        jp ns_loop

strlen: push bc                 ; HL = stringa -> A = lunghezza (conserva HL e BC)
        push hl
        ld b,0
sl_l:   ld a,(hl)
        or a
        jr z,sl_e
        inc hl
        inc b
        jr sl_l
sl_e:   ld a,b
        pop hl
        pop bc
        ret

; A = indice campo -> HL = descrittore (8 byte)
ns_desc:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,fld_tab
        add hl,de
        ret

; disegna tutta la schermata
ns_draw_all:
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
        ld hl,s_nstitle
        call print_str
        ld hl,8
        ld (GRPACX),hl
        ld hl,172
        ld (GRPACY),hl
        ld hl,s_nsh1
        call print_str
        ld hl,8
        ld (GRPACX),hl
        ld hl,186
        ld (GRPACY),hl
        ld hl,s_nsh2
        call print_str
        ld b,0
nda_l:  push bc
        ld a,b
        call ns_draw_field
        pop bc
        inc b
        ld a,b
        cp ns_nf
        jr nz,nda_l
        ret

; A = indice: riga completa (marcatore, etichetta, valore)
ns_draw_field:
        ld b,a
        call ns_desc
        push hl
        ld de,6
        add hl,de
        ld a,(hl)               ; y
        ld c,a
        ld a,0
        ld (P+0),a
        ld (P+1),a
        ld (P+2),a
        ld (P+3),a
        ld (P+4),a
        ld (P+5),a
        ld (P+7),a
        ld (P+9+0),a
        ld a,c
        ld (P+6),a
        ld a,1
        ld (P+9),a
        xor a
        ld (P+8),a
        ld a,11
        ld (P+10),a
        xor a
        ld (P+11),a
        ld (P+13),a
        ld a,0x11
        ld (P+12),a
        ld a,0xC0
        ld (P+14),a
        push bc
        ld hl,P
        call vdp_cmd
        pop bc
        pop hl                  ; descrittore
        push hl
        ld l,c
        ld h,0
        ld (GRPACY),hl
        ld hl,0
        ld (GRPACX),hl
        ld a,(ns_i)
        cp b
        ld a,' '
        jr nz,ndf_m
        ld a,'>'
ndf_m:  call print_char
        pop hl
        push hl
        ld de,4
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        ld de,12
        ld (GRPACX),de
        call print_str          ; etichetta
        ld de,88
        ld (GRPACX),de
        pop hl
        inc hl
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        jp print_str            ; valore

; ---- caricamento e conversioni ----
ns_load:
        ld hl,FBUF
        ld de,FBUF+1
        ld bc,0x8F
        ld (hl),0
        ldir
        ld hl,s_dhcp
        ld de,f_mode
        ld bc,5
        ldir
        ld hl,9100
        ld de,f_port
        call u16str
        call load_settings
        ret c                   ; nessun record: valori predefiniti
        ld hl,SETREC+0x1A
        ld de,f_host
        ld bc,28
        ldir
        ld hl,(SETREC+0x18)
        ld de,f_port
        call u16str
        ld hl,SETREC+0x36
        ld de,f_user
        ld bc,12
        ldir
        ld hl,SETREC+0x42
        ld de,f_key
        ld bc,16
        ldir
        ld a,(SETREC+3)
        and 1
        jr z,nl_ips
        ld hl,s_static
        ld de,f_mode
        ld bc,8
        ldir
nl_ips: ld hl,SETREC+4
        ld de,f_ip
        call ip2str
        ld hl,SETREC+8
        ld de,f_ip+16
        call ip2str
        ld hl,SETREC+0x0C
        ld de,f_ip+32
        call ip2str
        ld hl,SETREC+0x10
        ld de,f_ip+48
        jp ip2str

; HL = 4 byte -> DE = "a.b.c.d" (azzerato)
ip2str: push hl               ; 0.0.0.0 = campo vuoto
        ld a,(hl)
        inc hl
        or (hl)
        inc hl
        or (hl)
        inc hl
        or (hl)
        pop hl
        jr nz,i2s_go
        xor a
        ld (de),a
        ret
i2s_go: ld b,4
i2s_l:  push bc
        ld c,(hl)
        inc hl
        push hl
        ld l,c
        ld h,0
        call u16str
        pop hl
        pop bc
        dec b
        jr z,i2s_e
        ld a,'.'
        ld (de),a
        inc de
        jr i2s_l
i2s_e:  xor a
        ld (de),a
        ret

; HL = valore -> DE = cifre decimali senza zeri iniziali, zero finale; DE avanza sul terminatore
u16str: xor a
        ld (ns_lz),a
        ld bc,10000
        call u16d
        ld bc,1000
        call u16d
        ld bc,100
        call u16d
        ld bc,10
        call u16d
        ld a,l
        add a,'0'
        ld (de),a
        inc de
        xor a
        ld (de),a
        ret
u16d:   ld a,'0'-1
u16s:   inc a
        or a
        sbc hl,bc
        jr nc,u16s
        add hl,bc
        cp '0'
        jr nz,u16w
        push af
        ld a,(ns_lz)
        or a
        jr z,u16x
        pop af
        jr u16o
u16x:   pop af
        ret
u16w:   push af
        ld a,1
        ld (ns_lz),a
        pop af
u16o:   ld (de),a
        inc de
        ret

; stringa decimale (HL) -> numero a 16 bit in HL
str2u16:
        ld de,0
s2u_l:  ld a,(hl)
        sub '0'
        jr c,s2u_e
        cp 10
        jr nc,s2u_e
        inc hl
        push hl
        ld h,d
        ld l,e
        add hl,hl
        add hl,hl
        add hl,de
        add hl,hl               ; *10
        ld e,a
        ld d,0
        add hl,de
        ex de,hl
        pop hl
        jr s2u_l
s2u_e:  ex de,hl
        ret

; ---- salvataggio ----
ns_save:
        ld hl,SETREC            ; record da zero
        ld de,SETREC+1
        ld bc,127
        ld (hl),0
        ldir
        ld a,(cp_done)          ; il salvataggio delle impostazioni conserva i progressi
        ld (SETREC+0x52),a
        ld a,(cp_done+1)
        ld (SETREC+0x53),a
        ld a,'N'
        ld (SETREC),a
        ld a,'S'
        ld (SETREC+1),a
        ld a,(f_mode)
        cp 'S'
        ld a,0
        jr nz,nsv_m
        inc a
nsv_m:  ld (SETREC+3),a
        ld hl,f_ip
        call ns_ipp             ; IP locale
        ld de,SETREC+4
        call ns_ipc
        ld hl,f_ip+16
        call ns_ipp
        ld de,SETREC+8
        call ns_ipc
        ld hl,f_ip+32
        call ns_ipp
        ld de,SETREC+0x0C
        call ns_ipc
        ld hl,f_ip+48
        call ns_ipp
        ld de,SETREC+0x10
        call ns_ipc
        ld hl,f_port
        call str2u16
        ld (SETREC+0x18),hl
        ld hl,f_host
        ld de,SETREC+0x1A
        ld bc,28
        ldir
        ld hl,f_user
        ld de,SETREC+0x36
        ld bc,12
        ldir
        ld hl,f_key
        ld de,SETREC+0x42
        ld bc,16
        ldir
        call ns_append
        ld hl,m_nsok
        jr nc,nsv_e
        ld hl,m_err
nsv_e:  ld (v_msg),hl
        jp ns_exit

; HL = testo "a.b.c.d" -> 4 byte in ns_ipbuf
ns_ipp: ld de,ns_ipbuf
        ld b,4
nip_l:  push bc
        push de
        call str2u16_p          ; HL avanza oltre il numero e il punto
        pop de
        ld a,c
        ld (de),a
        inc de
        pop bc
        djnz nip_l
        ret
ns_ipc: ld hl,ns_ipbuf
        ld bc,4
        ldir
        ret

; come str2u16 ma conserva il puntatore: HL -> dopo la cifra e l'eventuale '.', valore (8 bit) in C
str2u16_p:
        ld c,0
sp_l:   ld a,(hl)
        sub '0'
        jr c,sp_e
        cp 10
        jr nc,sp_e
        inc hl
        ld d,a
        ld a,c                  ; c = c*10 + d (saturato a 255)
        add a,a
        jr c,sp_sat
        ld e,a
        add a,a
        jr c,sp_sat
        add a,a
        jr c,sp_sat
        add a,e
        jr c,sp_sat
        add a,d
        jr c,sp_sat
        ld c,a
        jr sp_l
sp_sat: ld c,255
        jr sp_l
sp_e:   ld a,(hl)
        cp '.'
        ret nz
        inc hl
        ret

; aggiunge SETREC come nuovo record (seq+1, somma di controllo) nel settore SET. CF=1 se errore
ns_append:
        ld a,(v_flash)
        or a
        jr nz,nap_ok
        scf
        ret
nap_ok: call set_scan           ; v_fs/v_fr = prossimo slot, v_sseq = ultimo numero
        ld a,(v_sseq)
        inc a
        ld (SETREC+2),a
        ld hl,SETREC
        ld b,127
        xor a
nap_s:  add a,(hl)
        inc hl
        djnz nap_s
        neg
        ld (hl),a
        ld a,(v_sfound2)
        or a
        jr nz,nap_w
        ld a,SETSEG             ; settore pieno: si cancella e si riparte
        ld (BANKW),a
        call ram_erase
        ret c
        xor a
        ld (v_fs),a
        ld (v_fr),a
nap_w:  ld a,(v_fs)
        add a,SETSEG
        ld (BANKW),a
        ld a,(v_fr)             ; lo slot deve essere vuoto (FF), altrimenti si cancella il settore
        ld h,a
        ld l,0
        srl h
        rr l
        ld a,h
        or 0x80
        ld h,a
        ld b,128
nap_c:  ld a,(hl)
        inc a
        jr nz,nap_d
        inc hl
        djnz nap_c
        jr nap_e
nap_d:  ld a,SETSEG
        ld (BANKW),a
        call ram_erase
        ret c
        xor a
        ld (v_fs),a
        ld (v_fr),a
        ld a,SETSEG
        ld (BANKW),a
nap_e:  ld a,(v_fs)
        add a,SETSEG
        ld (BANKW),a
        ld a,(v_fr)
        ld h,a
        ld l,0
        srl h
        rr l
        ld a,h
        or 0x80
        ld h,a                  ; HL = 8000 + slot*128
        push hl
        ld de,SETREC
        ld b,128
nap_l:  ld a,(de)
        cp 0xFF
        jr z,nap_k
        ld c,a
        call FLRT
        jr c,nap_x
nap_k:  inc hl
        inc de
        djnz nap_l
        pop hl                  ; verifica
        ld de,SETREC
        ld b,128
nap_v:  ld a,(de)
        cp (hl)
        scf
        ret nz
        inc hl
        inc de
        djnz nap_v
        or a
        ret
nap_x:  pop hl
        scf
        ret

; cerca il primo slot libero e il numero dell'ultimo record valido
v_fs     equ FBUF+0x9B
v_fr     equ FBUF+0x9C
v_sseq   equ FBUF+0x9D
v_sfound2 equ FBUF+0x9E
set_scan:
        xor a
        ld (v_sseq),a
        ld (v_sfound2),a
        ld b,0                  ; segmento
ss_seg: ld a,b
        add a,SETSEG
        ld (BANKW),a
        ld ix,0x8000
        ld c,0                  ; slot
ss_rec: ld a,(ix+0)
        cp 0xFF
        jr nz,ss_used
        ld a,b                  ; primo slot libero
        ld (v_fs),a
        ld a,c
        ld (v_fr),a
        ld a,1
        ld (v_sfound2),a
        ret
ss_used:
        cp 'N'
        jr nz,ss_next
        ld a,(ix+1)
        cp 'S'
        jr nz,ss_next
        ld a,(ix+2)
        ld (v_sseq),a
ss_next:
        ld de,128
        add ix,de
        inc c
        ld a,c
        cp 64
        jr nz,ss_rec
        inc b
        ld a,b
        cp 8
        jr c,ss_seg
        ret

; ---- dati ----
fld_tab:                        ; tipo, max, buffer, etichetta, y, -
        db 0,28
        dw f_host,l_srv
        db 24,0
        db 1,5
        dw f_port,l_port
        db 40,0
        db 0,12
        dw f_user,l_user
        db 56,0
        db 0,16
        dw f_key,l_key
        db 72,0
        db 3,7
        dw f_mode,l_net
        db 88,0
        db 2,15
        dw f_ip,l_ip
        db 104,0
        db 2,15
        dw f_ip+16,l_mask
        db 120,0
        db 2,15
        dw f_ip+32,l_gw
        db 136,0
        db 2,15
        dw f_ip+48,l_dns
        db 152,0
l_srv:  db "Server",0
l_port: db "Port",0
l_user: db "User",0
l_key:  db "Key",0
l_net:  db "Network",0
l_ip:   db "IP",0
l_mask: db "Netmask",0
l_gw:   db "Gateway",0
l_dns:  db "DNS",0
s_dhcp: db "DHCP",0,0,0,0
s_static: db "STATIC",0
s_nstitle: db "NETWORK SETTINGS",0
s_nsh1: db "UP/DOWN field  SPACE DHCP/IP",0
s_nsh2: db "ENTER save  ESC cancel",0
m_nsok: db "  Settings saved",0
; matrice -> ASCII, righe 0..5 (8 colonne ciascuna); 0 = nessun carattere
key_un: db "01234567"
        db "89-=",0x5C,"[];"
        db 0x27,"`,./",0,"ab"
        db "cdefghij"
        db "klmnopqr"
        db "stuvwxyz"
key_sh: db ")!@#$%^&"
        db "*(_+|{}:"
        db 0x22,"~<>?",0,"AB"
        db "CDEFGHIJ"
        db "KLMNOPQR"
        db "STUVWXYZ"
