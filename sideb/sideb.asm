        org 20

vsync_count     rmb 2
imageflag       rmb 1

        org $1000

start

        lds #$3E00      ;set up stacks
        ldu #$3D00

        orcc #$50       ;disable interrupts

        lda $ff23
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

        lda #$7e                ;hijack with jmp
        sta $010c
        ldx #irq_start          ;point to our irq routine
        stx $010d

        andcc #$ef              ;reenable interrupts

        jsr pmode1
        jsr clearscreen
        ldx #startlogo
        jsr copyimage

        clr imageflag

        clr vsync_count

main
        jmp main

irq_start
        lda $ff02               ;acknowledge interrupt
        inc vsync_count

        lda vsync_count
        cmpa #180
        bne skipinc
        inc imageflag
        ldd #$0000
        std vsync_count
skipinc
        lda imageflag
        cmpa #1
        bne skip1
        ldx #handslap
        jsr copyimage
skip1
        lda imageflag
        cmpa #2
        bne skip2
        ldx #dealwithit
        jsr copyimage
skip2
        lda imageflag
        cmpa #3
        bne skip3
        ldx #dragon
        jsr copyimage
skip3
        lda imageflag
        cmpa #4
        bne skip4
        ldx #palmtree
        jsr copyimage
skip4
        lda imageflag
        cmpa #5
        bne skip5
        ldx #saul
        jsr copyimage
skip5
        lda imageflag
        cmpa #6
        bne skip6
        ldx #slipstreamlogo
        jsr copyimage
skip6
        lda imageflag
        cmpa #7
        bne skip7
        ldx #ymo
        jsr copyimage
skip7
        lda imageflag
        cmpa #8
        bne irq_end
        lda #1
        sta imageflag

irq_end
        rti


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

clearscreen
        ldx #$400
        ldd #0
clearloop
        std ,x++
        cmpx #$1000
        bne clearloop
        rts

copyimage
        ldy #$400
copyloop
        lda ,x+
        sta ,y+
        cmpy #$1000
        bne copyloop
        rts

startlogo
        includebin "start.bin"
handslap
        includebin "32handslap.bin"
dealwithit
        includebin "dealwithit.bin"
dragon
        includebin "dragon.bin"
palmtree
        includebin "palmtree.bin"
saul
        includebin "saul.bin"
slipstreamlogo
        includebin "slipstreamlogo.bin"
ymo
        includebin "ymo.bin"

        end start