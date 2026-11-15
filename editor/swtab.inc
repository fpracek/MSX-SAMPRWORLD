; generato da tools/gen_swsprites.py - NON modificare a mano: id di frame -> segmento e indirizzo (finestra 8000)
SWF_COUNT equ 56
SWF_HERO1 equ 0
SWF_HERO2 equ 8
SWF_GOB equ 16
SWF_BAT equ 28
SWF_POL equ 40
SWF_CLIMB1 equ 52
SWF_CLIMB2 equ 54
swf_kb: db SWF_GOB,SWF_BAT,SWF_POL          ; primo frame di ogni sprite nemico (soldato, medico, poliziotto)
swf_adr: dw h1r_idle,h1r_runa,h1r_runb,h1r_jump,h1l_idle,h1l_runa,h1l_runb,h1l_jump,h2r_idle,h2r_runa,h2r_runb,h2r_jump,h2l_idle,h2l_runa,h2l_runb,h2l_jump,gob_r0,gob_r1,gob_r2,gob_r3,gob_r4,gob_r5,gob_l0,gob_l1,gob_l2,gob_l3,gob_l4,gob_l5,bat_r0,bat_r1,bat_r2,bat_r3,bat_r4,bat_r5,bat_l0,bat_l1,bat_l2,bat_l3,bat_l4,bat_l5,pol_r0,pol_r1,pol_r2,pol_r3,pol_r4,pol_r5,pol_l0,pol_l1,pol_l2,pol_l3,pol_l4,pol_l5,h1_climb_a,h1_climb_b,h2_climb_a,h2_climb_b
swf_seg: db 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13
