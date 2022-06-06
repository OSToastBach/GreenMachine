
;pmodeia - 32x16 - 512 bytes - $400-$600
;pmode1 - 128x96 - 3072 bytes - $400-$1000
;colour order: green, yellow, blue, red

screenbase      equ     $400

        ;setdp $100

        org 20

vsync_count     rmb 2
vsync_count2    rmb 1
vsync_count3    rmb 1
screenflag      rmb 1
letteraddr      rmb 2
letterendaddr   rmb 2
fieldfxlogoaddr rmb 2
fieldfxlogoend  rmb 2
stringindex     rmb 2
addtostring     rmb 2
stringaddamount rmb 1
ylettercnt      rmb 1

        org $1000

start

        lds #$3E00      ;set up stacks
        ldu #$3D00

        ;disable interrupts
        orcc #$50

        lda $ff23       ;set cassette output
        ora #%00001000
        sta $ff23

	lda #%00111110	;Bit 3=0 Bit0=Hsync
	sta $ff01		;Bit 3	CA2: Select Device (Multiplexor LSB)
	lda #%00110111	;Bit 3=0 Bit0=Vsync
	sta $FF03		;Bit 3	CB2: Select Device (Multiplexor MSB)

        ;MX-H   MX-L
        ;0      0       DAC
        ;0      1       Cassette
        ;1      0       Cartridge
        ;0      0       Unused

        ;new irq vector
        lda #$7e        ;hijack with jmp
        sta $010c
        ldx #irq_start  ;point to our irq routine
        stx $010d

        andcc #$ef      ;reenable interrupts

        jsr pmode1
        jsr copylogo
        
        lda #00
        sta screenflag

        ldd #letters
        addd #$258
        std letterendaddr       ;calc end addr

        ldd #letters            ;clear the first char
        addd #620
        std letteraddr

        ldd #fieldfxchars
        std fieldfxlogoaddr

        ldd #fieldfxcharsend
        std fieldfxlogoend

        ldd #$0000
        std stringindex

        ;do nothing until vsync
main
        jmp main

        ;main interrupt routine - triggered on vsync
irq_start
        lda $ff02               ;acknowledge interrupt

        inc vsync_count

        lda screenflag          ;check screen state
        bne skiptoscroller

        lda vsync_count
        cmpa #250
        bne skipsync            ;wait for 250 vsyncs - roughly 5 seconds

        jsr pmodeia
        jsr clearscreentx

        ldx #$400
        lda #00

        lda #01
        sta screenflag          ;switch screens

skiptoscroller
        inc vsync_count2
        lda vsync_count2
        cmpa #4
        bne skipcharreset

        ldy stringindex

        ldd #$0000
        std addtostring

        jsr stringcalc          ;calculate string byte offsets and things

skipcharreset
        jsr loadletter
        jsr copyletter
        inc vsync_count3
        lda vsync_count3
        cmpa #2
        bne skipsync
        jsr loadlogostrip
        jsr patchline
        jsr copytextlogo
        lda #0
        sta vsync_count3

skipsync

irq_end
        rti

stringcalc
        lda string,y            ;load string add amount
        cmpa #32
        bne skiploop            ;restart loop
        ldy #$0000
        sty stringindex
        lda string,y
skiploop
        sta stringaddamount

        bne addstring
        ldd #$0000
        std addtostring
        jmp stringadd
addstring
        ldd addtostring
        addd #20                ;add 20 for each letter iteration
        std addtostring
        dec stringaddamount
        lda stringaddamount
        bne addstring

stringadd
        ldd #letters
        addd addtostring
        std letteraddr

        leay 1,y
        sty stringindex

        lda #00
        sta vsync_count2
        rts

loadlogostrip
        ldx #$4FF
loadlogoloop
        lda [fieldfxlogoaddr]           ;same method as loading scroller
        sta ,x
        ldd fieldfxlogoaddr
        cmpd fieldfxlogoend
        bne skiplogoreset
        ldd #fieldfxchars
skiplogoreset
        addd #1
        std fieldfxlogoaddr
        leax 32,x
        cmpx #$5FF
        bne loadlogoloop

        lda $4FF                        ;pretty colours owo
        ;adda #32                        ;blue
        sta $4FF
        lda $51F
        ;adda #32                        ;blue
        sta $51F
        lda $53F
        adda #80                        ;pink
        sta $53F
        lda $55F
        adda #64                        ;white
        sta $55F
        lda $57F
        adda #64                        ;white
        sta $57F
        lda $59F
        adda #80                        ;pink
        sta $59F
        lda $5BF
        ;adda #32                        ;blue
        sta $5BF
        lda $5DF
        ;adda #32                        ;blue
        sta $5DF

        rts

copytextlogo              ;cheap method - needs fixing before release
        ldx #$4df
copytextlogoloop
        leax 2,x
        lda ,x
        leax -1,x
        sta ,x
        cmpx #$600
        bne copytextlogoloop
        rts

patchline               ;not ideal but works - needs fixing before release
        ldx #$500
        lda #128
patchloop
        sta ,x
        leax 32,x
        cmpx #$600
        bne patchloop
        rts

copylogo
        ldy #$00
        ldx #$400
copyloop
        ldd slipstreamlogo,y
        leay 2,y
        std ,x++
        cmpx #$1000
        bne copyloop
        rts

clearscreenbm
        ldd #00
        ldx #$400
clearloopbm                     ;clear screen
        std ,x++
        cmpx #$1000             ;end of screen
        bne clearloopbm
        rts

clearscreentx
        ldd #$8080
        ldx #$400
clearlooptx                     ;clear screen
        std ,x++
        cmpx #$800              ;end of screen
        bne clearlooptx
        rts

pmodereset                      ;pmode routines from chibiakumas
        lda #0
        sta $FFC6
        sta $FFC8
        sta $FFCA
        sta $FFCC
        sta $FFCE
        sta $FFD0
        sta $FFD2

        sta $FFC8+1             ;set screenbase $400
        sta $FFC0
        sta $FFC2
        sta $FFC4
        rts

pmode1  ;128x96
        jsr pmodereset
        ;     AGGGC---	C=Color (0=Green 1=Orange)
        lda #%11000000
        sta $FF22
        sta $FFC4+1 ;SAM V2=1
        rts

pmodeia
	jsr pmodereset
		; AGGGC---	C=Color (0=Green 1=Orange)
	lda #%00000000
	sta $FF22
	rts

palswap
        lda $FF22
        eora #%00001000	;Switch CSS color palette
        sta $FF22
        rts

copyletter              ;cheap method - needs fixing before release
        ldx #$3FF
copyletterloop
        leax 2,x
        lda ,x
        leax -1,x
        sta ,x
        cmpx #$4A0
        bne copyletterloop
        rts

loadletter
        ldx #$0420                      ;dank
        lda #00
        sta ylettercnt
letterloop1
        lda [letteraddr]                ;load char from current address
        sta ,x                          ;store current char
        leax 32,x                       ;inc screen memory y+1
        ldd letteraddr
        addd #1                         ;increment
        std letteraddr
        inc ylettercnt
        lda ylettercnt
        cmpa #5
        bne letterloop1

        lda $420                        ;pretty colours owo
        adda #48                        ;red
        sta $420
        lda $440
        adda #112                       ;orange
        sta $440
        lda $460
        adda #16                        ;yellow
        sta $460
        lda $480
        adda #112                       ;orange
        sta $480
        lda $4A0
        adda #48                        ;red
        sta $4A0

skipreset
        rts

        ;+16 for each colour semigraphics
        ;+0:    light green
        ;+16:   yellow
        ;+32:   blue
        ;+48:   red
        ;+64:   white
        ;+80:   dark green
        ;+96:   pink
        ;+112:  orange

letters
        ;each letter 4x5, 4th column blank, arranged in columns top to bottom
        ;5 bytes/column, 20 bytes/character, 31 chars, 31x20=620 bytes total
letter_a
        fcb 129,138,142,138,138,140,128,140,128,128,130,133,141,133,133,128,128,128,128,128
letter_b
        fcb 142,138,142,138,139,140,128,140,128,131,137,133,137,133,134,128,128,128,128,128
letter_c
        fcb 134,138,138,138,137,140,128,128,128,131,140,128,128,128,131,128,128,128,128,128
letter_d
        fcb 142,138,138,138,139,140,128,128,128,131,130,133,133,133,136,128,128,128,128,128
letter_e
        fcb 142,138,142,138,139,140,128,140,128,131,140,128,128,128,131,128,128,128,128,128
letter_f
        fcb 142,138,142,138,138,140,128,140,128,128,140,128,128,128,128,128,128,128,128,128
letter_g
        fcb 129,138,138,138,132,140,128,129,128,131,130,133,131,133,141,128,128,128,128,128
letter_h
        fcb 138,138,142,138,138,128,128,140,128,128,133,133,141,133,133,128,128,128,128,128
letter_i
        fcb 140,128,128,128,131,143,143,143,143,143,140,128,128,128,131,128,128,128,128,128
letter_j
        fcb 140,128,128,128,131,141,133,133,133,134,140,128,128,128,128,128,128,128,128,128
letter_k
        fcb 138,138,142,138,138,128,129,137,128,128,133,136,128,137,133,128,128,128,128,128
letter_l
        fcb 138,138,138,138,139,128,128,128,128,131,128,128,128,128,131,128,128,128,128,128
letter_m
        fcb 139,138,138,138,138,128,143,140,128,128,135,133,133,133,133,128,128,128,128,128
letter_n
        fcb 139,142,138,138,138,128,130,137,132,128,133,133,133,135,141,128,128,128,128,128
letter_o
        fcb 134,138,138,138,137,140,128,128,128,131,137,133,133,133,134,128,128,128,128,128
letter_p
        fcb 142,138,142,138,138,140,128,140,128,128,137,133,136,128,128,128,128,128,128,128
letter_q
        fcb 134,138,138,138,137,140,128,128,129,131,137,133,133,133,137,128,128,128,128,128
letter_r
        fcb 142,138,143,138,138,140,128,140,137,128,137,133,136,128,137,128,128,128,128,128
letter_s
        fcb 134,138,132,128,131,140,128,140,128,131,140,128,137,133,134,128,128,128,128,128
letter_t
        fcb 140,128,128,128,128,143,143,143,143,143,140,128,128,128,128,128,128,128,128,128
letter_u
        fcb 138,138,138,138,137,128,128,128,128,131,133,133,133,133,134,128,128,128,128,128
letter_v
        fcb 138,138,138,137,132,128,128,128,128,131,133,133,133,134,136,128,128,128,128,128
letter_w
        fcb 138,138,138,138,137,128,128,128,143,143,133,133,133,133,134,128,128,128,128,128
letter_x
        fcb 138,137,129,134,138,128,128,140,128,128,133,134,130,137,133,128,128,128,128,128
letter_y
        fcb 138,138,132,128,128,128,128,131,143,143,133,133,136,128,128,128,128,128,128,128
letter_z
        fcb 140,128,128,133,139,140,128,134,128,131,141,138,128,128,131,128,128,128,128,128
letter_dash
        fcb 128,128,140,128,128,128,128,140,128,128,128,128,140,128,128,128,128,128,128,128
letter_exclamation
        fcb 128,128,128,128,128,143,143,143,140,131,128,128,128,128,128,128,128,128,128,128
letter_question
        fcb 134,128,128,128,128,140,128,129,136,138,137,134,136,128,128,128,128,128,128,128
letter_fullstop
        fcb 128,128,128,128,128,128,128,128,128,143,128,128,128,128,128,128,128,128,128,128
letter_circumflex
        fcb 128,132,134,138,137,131,128,140,128,131,128,136,137,133,134,128,128,128,128,128
letter_space
        fcb 128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128
letter_scrollloop ;left in bc of additional characters
        fcb 128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128
letter_apostrophe
        fcb 128,128,128,128,128,143,128,128,128,128,128,128,128,128,128,128,128,128,128,128
letter_comma
        fcb 128,128,128,129,135,128,128,128,130,136,128,128,128,128,128,128,128,128,128,128
letter_zero
        fcb 134,138,138,139,141,140,129,134,136,131,139,141,133,133,134,128,128,128,128,128
letter_one
        fcb 128,140,128,128,131,143,143,143,143,143,128,128,128,128,131,128,128,128,128,128
letter_two
        fcb 134,128,128,134,139,140,128,134,128,131,137,134,128,128,131,128,128,128,128,128
letter_three
        fcb 134,128,128,128,137,140,128,140,128,131,137,133,138,133,134,128,128,128,128,128
letter_four
        fcb 128,134,140,128,128,134,128,140,128,128,138,138,142,138,138,128,128,128,128,128
letter_five
        fcb 142,138,140,128,137,140,128,140,128,131,140,128,137,133,134,128,128,128,128,128
letter_six
        fcb 134,138,142,138,137,140,128,140,128,131,140,128,137,133,134,128,128,128,128,128
letter_seven
        fcb 140,128,128,128,128,140,128,133,138,138,141,138,128,128,128,128,128,128,128,128
letter_eight
        fcb 134,138,134,138,137,140,128,140,128,131,137,133,137,133,134,128,128,128,128,128
letter_nine
        fcb 134,138,132,128,129,140,128,140,128,134,137,133,141,138,128,128,128,128,128,128
letters_end

;letter table byte offsets
        ;a:0 b:20 c:40 d:60 e:80 f:100 g:120 h:140 i:160 j:180
        ;k:200 l:220 m:240 n:260 o:280 p:300 q:320 r:340 s:360
        ;t:380 u:400 v:420 w:440 x:460 y:480 z:500 -:520 !:540
        ;?:560 .:580 ô:600 space:620

;letter table values
        ;a:0 b:1 c:2 d:3 e:4 f:5 g:6 h:7 i:8 j:9 k:10 l:11 m:12 n:13 o:14 p:15
        ;q:16 r:17 s:18 t:19 u:20 v:21 w:22 x:23 y:24 z:25 -:26 !:27 ?:28 .:29 ô:30 space:31, scroll loop:32
        ;':33 ,:34 0:35 1:36 2:37 3:38 4:39 5:40 6:41 7:42 8:43 9:44

string
        ;in amounts of 20 bytes to add by, converted from text by scrolltextconv.py
        fcb 31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,24,14,31,22,0,18,18,20,15,31,13,4,17,3,18,28,27,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,18,11,8,15,18,19,17,4,0,12,31,7,4,17,4,31,15,17,4,18,4,13,19,8,13,6,31,0,31,11,8,19,19,11,4,31,18,2,17,14,11,11,4,17,31,8,13,19,17,14,31,14,13,31,19,7,4,31,3,17,0,6,14,13,31,38,37,31,0,19,31,5,8,4,11,3,26,5,23,27,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,19,7,8,18,31,8,18,31,18,8,3,4,31,0,31,14,5,31,19,7,4,31,6,17,4,4,13,31,12,0,2,7,8,13,4,31,19,0,15,4,31,3,20,14,34,31,22,8,19,7,31,0,31,11,8,12,8,19,4,3,31,17,20,13,31,14,5,31,43,31,19,0,15,4,18,27,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,2,7,4,2,10,31,14,20,19,31,19,7,8,18,31,2,7,20,13,10,24,31,18,2,17,14,11,11,4,17,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,22,8,19,7,31,19,7,4,18,4,31,2,14,11,14,20,17,18,34,31,14,7,31,12,24,27,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,0,11,11,31,1,4,8,13,6,31,17,4,13,3,4,17,4,3,31,22,8,19,7,31,18,4,12,8,6,17,0,15,7,8,2,18,31,2,7,0,17,0,2,19,4,17,18,31,8,13,31,19,7,4,31,3,4,5,0,20,11,19,31,19,4,23,19,31,12,14,3,4,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,11,14,21,4,11,24,31,0,8,13,33,19,31,8,19,28,31,31,31,31,31,31,31,31,31,31,31,31,31,31,19,7,0,19,31,11,14,6,14,31,0,19,31,19,7,4,31,18,19,0,17,19,31,19,14,14,28,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,0,12,0,25,8,13,6,31,8,5,31,8,31,3,14,31,18,0,24,31,18,14,31,12,24,18,4,11,5,27,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,18,20,15,4,17,1,11,24,31,15,8,23,4,11,11,4,3,31,1,24,31,0,13,3,14,31,31,31,31,31,31,31,31,31,31,31,31,31,31,19,7,4,18,4,31,17,0,3,31,2,7,14,14,13,18,31,19,14,14,34,31,18,19,17,4,0,12,4,3,31,5,17,14,12,31,2,0,18,18,4,19,19,4,31,19,0,15,4,31,9,20,18,19,31,0,5,19,4,17,31,19,7,4,31,3,4,12,14,31,3,0,19,0,27,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,7,14,22,31,2,14,14,11,31,8,18,31,19,7,0,19,28,27,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,2,14,3,4,34,31,12,20,18,8,2,31,0,13,3,31,2,7,0,17,0,2,19,4,17,31,6,17,0,15,7,8,2,18,31,26,31,19,30,1,0,2,7,31,31,31,31,31,31,31,31,31,31,31,31,1,8,19,12,0,15,31,6,17,0,15,7,8,2,18,31,26,31,0,13,3,14,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,6,17,4,4,19,8,13,6,18,31,5,11,24,31,14,20,19,31,19,14,29,29,29,29,31,31,31,31,31,31,31,19,20,7,1,31,31,31,31,31,31,31,31,17,8,5,19,31,31,31,31,31,31,31,7,14,14,24,26,15,17,14,6,17,0,12,31,31,31,31,31,31,31,31,31,1,8,19,18,7,8,5,19,4,17,18,31,31,31,31,31,31,31,31,31,6,4,13,4,18,8,18,31,15,17,14,9,4,2,19,31,31,31,31,31,31,31,31,31,31,31,31,14,13,18,11,0,20,6,7,19,31,31,31,31,31,31,31,31,31,31,31,31,17,0,18,19,4,17,19,0,8,11,31,31,31,31,31,31,31,31,31,31,15,4,6,12,14,3,4,31,31,31,31,31,31,31,31,31,31,31,19,4,5,31,31,31,31,31,31,31,31,31,31,31,19,0,17,6,25,31,31,31,31,31,31,31,31,31,31,31,31,0,13,3,31,0,11,11,31,19,7,4,31,18,11,8,15,18,19,17,4,0,12,31,2,17,4,22,29,29,29,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,4,13,9,14,24,31,4,12,5,31,2,0,12,15,31,37,35,37,37,27,32

fieldfxchars
        ;field
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,133,143
        fcb 128,128,128,128,133,143,138,128
        fcb 128,128,133,143,138,128,128,128
        fcb 133,128,138,143,128,128,128,128
        fcb 143,128,128,143,128,128,128,128
        fcb 143,128,128,143,128,128,128,128
        fcb 143,128,128,136,128,128,128,128
        fcb 143,128,128,128,128,128,128,135
        fcb 142,128,128,128,128,128,128,143
        fcb 128,128,128,128,128,128,128,143
        fcb 129,128,128,128,128,133,143,143
        fcb 143,128,128,133,143,138,128,143
        fcb 143,133,143,138,128,128,128,142
        fcb 143,138,128,128,128,128,128,128
        fcb 143,128,128,128,128,128,128,128
        fcb 142,128,128,128,128,128,133,135
        fcb 128,128,128,128,133,143,138,143
        fcb 128,128,133,143,138,128,128,143
        fcb 133,128,138,143,128,128,128,143
        fcb 143,128,128,143,128,128,128,143
        fcb 143,128,128,143,128,128,128,142
        fcb 143,128,128,136,128,128,128,128
        fcb 143,128,128,128,128,128,128,129
        fcb 142,128,128,128,128,133,143,143
        fcb 128,128,128,133,143,138,128,143
        fcb 128,133,143,138,128,128,128,143
        fcb 143,138,128,128,128,128,128,143
        fcb 128,128,128,128,128,128,128,142
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,133,143
        fcb 128,128,128,128,133,143,143,143
        fcb 128,128,133,143,138,128,128,143
        fcb 133,128,138,128,128,128,128,143
        fcb 143,128,128,128,128,128,133,143
        fcb 143,128,128,128,133,143,138,128
        fcb 143,128,133,143,138,128,128,128
        fcb 138,143,138,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,129,128,128,128,128
        fcb 128,128,128,143,128,128,128,128
        fcb 128,128,128,143,128,128,128,128
        fcb 128,128,128,143,128,128,128,128
        fcb 128,128,128,143,128,128,128,128
        fcb 128,128,128,143,128,128,128,128
        fcb 128,128,128,142,128,128,128,128
        ;fx
        fcb 128,128,128,128,128,128,133,143
        fcb 128,128,128,128,133,143,138,128
        fcb 128,128,133,143,138,128,128,128
        fcb 133,128,138,143,128,128,128,128
        fcb 143,128,128,143,128,128,128,128
        fcb 143,128,128,143,128,128,128,128
        fcb 143,128,128,136,128,128,128,128
        fcb 143,128,128,128,128,128,128,128
        fcb 142,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,129
        fcb 128,128,128,128,128,128,129,142
        fcb 128,128,128,128,128,129,142,128
        fcb 143,133,128,128,129,142,128,128
        fcb 128,138,143,133,142,128,128,128
        fcb 128,128,129,143,141,132,128,128
        fcb 128,129,142,128,130,139,141,132
        fcb 129,142,128,128,128,128,130,139
        fcb 142,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,128
        fcb 128,128,128,128,128,128,128,128
fieldfxcharsend
        fcb 128

slipstreamlogo
        includebin "slipstreamlogo.bin"

        end start