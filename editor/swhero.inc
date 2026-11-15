; generato da tools/gen_swsprites.py - NON modificare a mano
; sprite software compilati dell'eroe (8 frame: 4 a destra + 4 specchiati)
swh0:
        ld hl,swh0_d
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ret
swh0_d:   db 17,17,17,170,169,17,193,25,170,169,145,28,25,153,153,145,25,119,119,145,23,23,113,113,17,119,119,17,17,238,238,17,17,113,238,238,225,113,17,113,235,190,225,113,17,113,238,238,225,17,238,238,17,21,85,85,17,21,17,21,17,17,102,17,22,97,17,17,17,17,17
swh1:
        ld hl,swh1_d
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,125 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
swh1_d:   db 17,17,17,170,169,17,193,25,170,169,145,28,25,153,153,145,25,119,119,145,23,23,113,113,17,119,119,17,17,17,238,238,17,23,113,238,238,225,23,113,235,190,225,17,17,238,238,225,17,238,238,17,21,85,85,81,17,81,17,81,22,97,22,97,17,17,17,17
swh2:
        ld hl,swh2_d
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
swh2_d:   db 17,17,17,170,169,17,193,25,170,169,145,28,25,153,153,145,25,119,119,145,23,23,113,113,17,119,119,17,17,238,238,17,30,238,238,225,23,30,235,190,225,119,30,238,238,225,23,17,238,238,17,17,85,81,17,85,81,17,102,97,17,17,17
swh3:
        ld hl,swh3_d
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
swh3_d:   db 17,17,193,17,170,169,17,193,25,170,169,145,25,153,153,145,25,119,119,145,17,23,23,113,113,17,17,113,17,23,119,17,23,113,17,119,17,238,238,17,23,113,17,113,238,238,23,17,17,235,190,17,17,238,238,17,21,85,85,81,17,81,21,17,22,97,22,97,17,17,17,17
swh4:
        ld hl,swh4_d
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ret
swh4_d:   db 17,17,28,17,154,170,17,193,25,154,170,145,25,153,153,145,25,119,119,145,23,23,113,113,17,119,119,17,17,238,238,17,23,30,238,238,23,17,23,30,235,190,23,17,30,238,238,23,17,17,238,238,17,17,85,85,81,17,81,17,81,22,97,17,102,17,17,17,17,17,17
swh5:
        ld hl,swh5_d
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
swh5_d:   db 17,17,28,17,154,170,17,193,25,154,170,145,25,153,153,145,25,119,119,145,23,23,113,113,17,119,119,17,17,238,238,17,17,30,238,238,23,113,30,235,190,23,113,30,238,238,17,17,17,238,238,17,21,85,85,81,21,17,21,17,22,97,22,97,17,17,17,17
swh6:
        ld hl,swh6_d
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
swh6_d:   db 17,17,28,17,154,170,17,193,25,154,170,145,25,153,153,145,25,119,119,145,23,23,113,113,17,119,119,17,17,238,238,17,113,30,238,238,225,119,30,235,190,225,113,30,238,238,225,17,238,238,17,21,85,17,21,85,17,22,102,17,17,17,17
swh7:
        ld hl,swh7_d
        ld a,e : add a,1 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,124 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
swh7_d:   db 28,17,17,28,17,154,170,17,25,154,170,145,25,153,153,145,25,119,119,145,17,23,23,113,113,17,23,113,17,119,113,17,23,17,23,113,17,238,238,17,119,17,17,113,238,238,23,17,17,235,190,17,17,238,238,17,21,85,85,81,17,81,21,17,22,97,22,97,17,17,17,17
swh_tab: dw swh0,swh1,swh2,swh3,swh4,swh5,swh6,swh7
