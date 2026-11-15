; audio.asm - musica e effetti sull'SCC della Yamanooto (Konami5/SCC: banco 9000h = 3Fh mostra i registri a 9800h).
; Dati nel segmento 4 (finestra A000), generati da tools/gen_music.py. Chiamare snd_tick una volta per frame.
; Canali: 1 = melodia, 2 = basso, 3 = arpeggio, 4 = effetti. Il brano e' a righe (tempo = frame per riga).
; Gli effetti si lanciano con "ld a,SFX_xxx / call sfx_a" (conserva tutti i registri).
SCCW    equ 0x9800              ; forme d'onda: 4 x 32 byte
SCCF    equ 0x9880              ; frequenze: 2 byte per canale (basso, alto 4 bit)
SCCV    equ 0x988A              ; volumi
SCCE    equ 0x988F              ; abilitazione canali
SCCMAP  equ 0x3F                ; valore del registro banco che mappa l'SCC
AUD     equ 0xA000+2048
A_TEMPO equ AUD+2
A_WAVES equ AUD+4
A_NOTES equ AUD+132
A_SFX   equ AUD+324
A_SONG  equ AUD+420

SFX_JUMP  equ 0
SFX_COIN  equ 1
SFX_STOMP equ 3
SFX_HIT   equ 4
SFX_DIE   equ 5
SFX_WIN   equ 6
SFX_KEY   equ 10

s_on    equ 0xCA60
s_row   equ 0xCA61              ; 2 byte
s_ft    equ 0xCA63
s_cb    equ 0xCA64              ; 3 byte: volume di base dei canali musicali
s_age   equ 0xCA67              ; 3 byte: eta' della nota
x_on    equ 0xCA6A
x_per   equ 0xCA6B              ; 2 byte
x_del   equ 0xCA6D              ; 2 byte
x_vol   equ 0xCA6F
x_dec   equ 0xCA70
x_fr    equ 0xCA71
x_next  equ 0xCA72

snd_init:
        ld a,SCCMAP
        ld (BANKW),a
        xor a
        ld (SCCE),a             ; canali spenti mentre si caricano le onde
        ld hl,A_WAVES
        ld de,SCCW
        ld bc,128
        ldir
        ld hl,SCCV
        ld b,5
si_v:   ld (hl),0
        inc hl
        djnz si_v
        ld a,0x1F
        ld (SCCE),a
        ld hl,0
        ld (s_row),hl
        ld a,(A_TEMPO)
        dec a
        ld (s_ft),a             ; la prima riga parte subito
        ld a,1
        ld (s_on),a
        xor a
        ld (x_on),a
        ld (s_cb),a
        ld (s_cb+1),a
        ld (s_cb+2),a
        ret

snd_off:
        ld a,SCCMAP
        ld (BANKW),a
        xor a
        ld (s_on),a
        ld (x_on),a
        ld (SCCE),a
        ret

snd_music_off:                  ; ferma la musica, lascia finire l'effetto in corso
        xor a
        ld (s_on),a
        ld (SCCV),a
        ld (SCCV+1),a
        ld (SCCV+2),a
        ret

snd_tick:
        ld a,SCCMAP
        ld (BANKW),a
        ld a,(s_on)
        or a
        jr z,st_sfx
        ld a,(s_ft)
        inc a
        ld hl,A_TEMPO
        cp (hl)
        jr c,st_nr
        xor a
        ld (s_ft),a
        call snd_row
        jr st_env
st_nr:  ld (s_ft),a
st_env: call snd_env
st_sfx: jp snd_sfx

; una riga del brano: 3 note
snd_row:
        ld hl,(s_row)
        ld d,h
        ld e,l
        add hl,hl
        add hl,de               ; riga * 3
        ld de,A_SONG
        add hl,de
        push hl
        pop ix
        ld c,0                  ; canale
sr_l:   ld a,(ix+0)
        inc ix
        cp 0xFE
        jr z,sr_n               ; continua la nota precedente
        ld e,c
        ld d,0
        or a
        jr nz,sr_note
        ld hl,s_cb              ; silenzio
        add hl,de
        ld (hl),0
        jr sr_n
sr_note:
        add a,a                 ; periodo dalla tabella (2 byte per nota)
        ld l,a
        ld h,0
        push de
        ld de,A_NOTES
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)               ; DE = periodo
        ld a,c
        add a,a
        ld l,a
        ld h,0
        push bc
        ld bc,SCCF
        add hl,bc
        pop bc
        ld (hl),e
        inc hl
        ld a,d
        and 15
        ld (hl),a
        pop de                  ; DE = indice del canale
        ld hl,vol_tab           ; volume di base: melodia 11, basso 12, arpeggio 8
        add hl,de
        ld a,(hl)
        ld hl,s_cb
        add hl,de
        ld (hl),a
        ld hl,s_age
        add hl,de
        ld (hl),0
sr_n:   inc c
        ld a,c
        cp 3
        jr nz,sr_l
        ld hl,(s_row)           ; riga successiva, in loop
        inc hl
        ld a,(AUD)
        ld e,a
        ld a,(AUD+1)
        ld d,a
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,sr_ok
        ld hl,0
sr_ok:  ld (s_row),hl
        ret

vol_tab: db 11,12,8

; inviluppo e volumi dei 3 canali
snd_env:
        ld c,0
se_l:   ld e,c
        ld d,0
        ld hl,s_cb
        add hl,de
        ld a,(hl)
        or a
        jr z,se_w
        ld b,a                  ; base
        ld hl,s_age
        add hl,de
        ld a,(hl)
        cp 255
        jr z,se_a
        inc (hl)
se_a:   ld d,a                  ; eta'
        ld a,c
        cp 2
        jr nz,se_nl
        ld a,d                  ; arpeggio: pizzicato, cala di 1 ogni 2 frame fino a 2
        srl a
        ld d,a
        ld a,b
        sub d
        jr c,se_min
        cp 2
        jr nc,se_w
se_min: ld a,2
        jr se_w
se_nl:  ld a,b
se_w:   ld hl,SCCV
        ld e,c
        ld d,0
        add hl,de
        ld (hl),a
        inc c
        ld a,c
        cp 3
        jr nz,se_l
        ret

; effetto in corso sul canale 4
snd_sfx:
        ld a,(x_on)
        or a
        ret z
        ld hl,(x_per)
        ld a,l
        ld (SCCF+6),a
        ld a,h
        and 15
        ld (SCCF+7),a
        ld a,(x_vol)
        ld (SCCV+3),a
        ld de,(x_del)           ; periodo += delta, limitato a 1..4095
        add hl,de
        bit 7,h
        jr z,sx_p
        ld hl,1
sx_p:   ld a,h
        cp 16
        jr c,sx_s
        ld hl,0x0FFF
sx_s:   ld (x_per),hl
        ld a,(x_dec)
        or a
        jr z,sx_f
        ld b,a
        ld a,(x_vol)
        sub b
        jr nc,sx_v
        xor a
sx_v:   ld (x_vol),a
sx_f:   ld a,(x_fr)
        dec a
        ld (x_fr),a
        ret nz
        ld a,(x_next)
        cp 0xFF
        jr nz,sfx_play
        xor a
        ld (SCCV+3),a
        ld (x_on),a
        ret

; A = numero dell'effetto: carica i parametri (la tabella e' nel segmento 4, finestra A000)
sfx_play:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,A_SFX
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (x_per),de
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (x_del),de
        ld a,(hl)
        inc hl
        ld (x_vol),a
        ld a,(hl)
        inc hl
        ld (x_dec),a
        ld a,(hl)
        inc hl
        ld (x_fr),a
        ld a,(hl)
        ld (x_next),a
        ld a,1
        ld (x_on),a
        ret

sfx_a:  push af
        push hl
        push de
        push bc
        call sfx_play
        pop bc
        pop de
        pop hl
        pop af
        ret
