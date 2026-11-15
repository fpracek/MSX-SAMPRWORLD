; reach.asm - ingressi in pagina 1 dell'avviso "monete irraggiungibili" (il codice sta nel segmento 3: swreach.asm) e i suoi messaggi
; (i messaggi restano qui: vengono mostrati dopo il ritorno, con il segmento 3 gia' smappato)
rc_run:  ld bc,rc_run_i
         jr seg3_tr
do_check: ld bc,do_check_i
seg3_tr: ld e,a                 ; A viene passato alla routine
         ld a,3
         ld (0xB000),a
         ld a,e
         call sw_jbc
         ld a,HEROSEG
         ld (0xB000),a
         ret
m_rcn:    db "  Unreachable coins: ",0
m_rcexit: db "  Exit unreachable!",0
m_rcok:   db "  All items reachable",0
