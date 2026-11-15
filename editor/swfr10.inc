; generato da tools/gen_swsprites.py - NON modificare a mano (segmento ROM 10, finestra 8000)
        disp 0x8000
h1r_idle:
        ld hl,h1r_idle_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ret
h1r_idle_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,29,234,255,174,175,161,30,239,241,254,241,241,29,239,241,254,241,241,30,234,255,174,175,161,29,238,238,238,238,209,17,29,221,221,209,17,23,247,125,221,215,113,23,119,113,23,119,113,17,17,17,17,17,17
h1r_runa:
        ld hl,h1r_runa_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h1r_runa_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,29,234,255,174,175,161,30,239,241,254,241,241,29,239,241,254,241,241,30,234,255,174,175,161,29,238,238,238,238,209,17,29,221,221,215,17,23,127,125,221,215,17,23,119,113,17,17,17,17,17
h1r_runb:
        ld hl,h1r_runb_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,130 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h1r_runb_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,29,234,255,174,175,161,30,239,241,254,241,241,29,239,241,254,241,241,30,234,255,174,175,161,29,238,238,238,238,209,17,125,221,221,209,17,17,125,221,221,215,113,17,17,23,119,113,17,17,17
h1r_jump:
        ld hl,h1r_jump_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
h1r_jump_d:   db 17,17,17,17,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,29,234,255,174,175,161,30,239,241,254,241,241,29,239,241,254,241,241,30,234,255,174,175,161,29,238,238,238,238,209,17,29,215,247,209,17,29,119,119,209,17,119,113,17,17,17
h1l_idle:
        ld hl,h1l_idle_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h1l_idle_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,234,255,174,209,31,31,239,31,254,225,31,31,239,31,254,209,26,250,234,255,174,225,29,238,238,238,238,209,17,29,221,221,209,17,29,215,247,113,17,23,119,113,17,17,17
h1l_runa:
        ld hl,h1l_runa_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
h1l_runa_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,234,255,174,209,31,31,239,31,254,225,31,31,239,31,254,209,26,250,234,255,174,225,29,238,238,238,238,209,17,29,221,127,119,17,17,125,221,119,119,17,17,119,119,17,17,17,17
h1l_runb:
        ld hl,h1l_runb_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h1l_runb_d:   db 17,17,17,17,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,234,255,174,209,31,31,239,31,254,225,31,31,239,31,254,209,26,250,234,255,174,225,29,238,238,238,238,209,17,127,125,221,221,209,17,17,119,119,221,221,215,113,23,119,17,23,119,113,17,17,17,17,17
h1l_jump:
        ld hl,h1l_jump_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
h1l_jump_d:   db 17,17,17,17,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,234,255,174,209,17,31,239,17,254,225,17,31,239,17,254,209,26,250,234,255,174,225,29,238,238,238,238,209,17,119,125,221,221,215,247,17,17,119,125,221,221,119,119,17,23,119,17,17,119,113,17,17,17,17
h2r_idle:
        ld hl,h2r_idle_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ret
h2r_idle_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,21,202,255,172,175,161,28,207,241,252,241,241,21,207,241,252,241,241,28,202,255,172,175,161,21,204,204,204,204,81,17,21,85,85,81,17,23,247,117,85,87,113,23,119,113,23,119,113,17,17,17,17,17,17
h2r_runa:
        ld hl,h2r_runa_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h2r_runa_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,21,202,255,172,175,161,28,207,241,252,241,241,21,207,241,252,241,241,28,202,255,172,175,161,21,204,204,204,204,81,17,21,85,85,87,17,23,127,117,85,87,17,23,119,113,17,17,17,17,17
h2r_runb:
        ld hl,h2r_runb_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,130 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h2r_runb_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,21,202,255,172,175,161,28,207,241,252,241,241,21,207,241,252,241,241,28,202,255,172,175,161,21,204,204,204,204,81,17,117,85,85,81,17,17,117,85,85,87,113,17,17,23,119,113,17,17,17
h2r_jump:
        ld hl,h2r_jump_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
h2r_jump_d:   db 17,17,17,17,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,21,202,255,172,175,161,28,207,241,252,241,241,21,207,241,252,241,241,28,202,255,172,175,161,21,204,204,204,204,81,17,21,87,247,81,17,21,119,119,81,17,119,113,17,17,17
h2l_idle:
        ld hl,h2l_idle_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h2l_idle_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,202,255,172,81,31,31,207,31,252,193,31,31,207,31,252,81,26,250,202,255,172,193,21,204,204,204,204,81,17,21,85,85,81,17,21,87,247,113,17,23,119,113,17,17,17
h2l_runa:
        ld hl,h2l_runa_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
h2l_runa_d:   db 17,17,17,17,22,70,70,65,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,202,255,172,81,31,31,207,31,252,193,31,31,207,31,252,81,26,250,202,255,172,193,21,204,204,204,204,81,17,21,85,127,119,17,17,117,85,119,119,17,17,119,119,17,17,17,17
h2l_runb:
        ld hl,h2l_runb_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,3 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi
        ret
h2l_runb_d:   db 17,17,17,17,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,202,255,172,81,31,31,207,31,252,193,31,31,207,31,252,81,26,250,202,255,172,193,21,204,204,204,204,81,17,127,117,85,85,81,17,17,119,119,85,85,87,113,23,119,17,23,119,113,17,17,17,17,17
h2l_jump:
        ld hl,h2l_jump_d
        ld a,e : add a,2 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,126 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ld a,e : add a,4 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi
        ret
h2l_jump_d:   db 17,17,17,17,21,100,100,97,18,51,51,49,17,17,34,35,51,34,17,17,21,101,101,100,100,100,100,97,17,17,22,102,102,97,17,17,26,250,202,255,172,81,17,31,207,17,252,193,17,31,207,17,252,81,26,250,202,255,172,193,21,204,204,204,204,81,17,119,117,85,85,87,247,17,17,119,117,85,85,119,119,17,23,119,17,17,119,113,17,17,17,17
gob_r0:
        ld hl,gob_r0_d
        ld a,e : add a,131 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,127 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi : outi
        ld a,e : add a,129 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ld a,e : add a,128 : ld e,a : out (0x99),a : ld a,d : adc a,0 : ld d,a : out (0x99),a
        outi : outi : outi : outi : outi : outi
        ret
gob_r0_d:   db 17,17,17,17,17,102,102,102,81,17,86,102,102,102,97,21,86,102,31,22,97,17,85,85,102,207,198,97,17,21,85,85,85,85,81,21,106,255,166,175,161,22,111,241,246,241,241,21,111,241,246,241,241,22,106,255,166,175,161,21,102,102,102,102,81,17,21,85,85,81,17,26,250,165,85,83,161,26,170,161,19,51,49,17,17,17,17,17,17
swfr10_end:
        ent
