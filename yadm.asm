// ====================================================================================================================
// YetAnotherDemoMaker
// Code by DKT/Samar
// ====================================================================================================================

#import "inc/makra.asm"

// ===================================================================
// Stałe
// ===================================================================

.const IRQ0_LINE		= $ff

.const CODE_START_ADDRESS	= $0810
.const DEMO_SCRIPT_ADDRESS	= $8000

.const CHARSET_ADDRESS	= $4000
.const SCREEN_ADDRESS	= $6000
.const FREEMEM_ADDRESS	= $6400
.const FREEMEM_PAGES	= $1c

// ===================================================================
// Rozkazy skryptu
// ===================================================================

.const SCRIPT_PTR		= $80

.const SCRIPT_CMD_D012	= $90
.const SCRIPT_CMD_SYNC	= $91
.const SCRIPT_CMD_NEWLINE	= $92
.const SCRIPT_CMD_IRQ	= $93

.const SCRIPT_CMD_INC	= $A0
.const SCRIPT_CMD_DEC	= $A1

.const SCRIPT_CMD_NOP	= $FD
.const SCRIPT_CMD_JMP	= $FE
.const SCRIPT_CMD_END	= $FF

// POMOCNE STAŁE

.const SCRIPT_CMD_PTR_END	= $88

// ===================================================================
// Zeropage
// ===================================================================

.const IRQ_ZP		= $02	// zajmuje 4
.const PTR_ZP		= $06	// zajmuje 4
.const SCRIPT_ZP		= $0A	// zajmuje 2

.const ptr1		= $10
.const ptr1l		= ptr1
.const ptr1h		= ptr1+1
.const ptr2		= $12
.const ptr2l		= ptr2
.const ptr2h		= ptr2+1

// ====================================================================================================================
// Basic i start programu
// ====================================================================================================================

	BasicUpstart2(start)

	* = CODE_START_ADDRESS "Code start"
start:	
	sei
	lda #$35
	sta $01

	Sync()

	lda #0
	sta $d011
	sta $d020
	sta $d021
	sta SCRIPT_PTR
	lda #<DEMO_SCRIPT_ADDRESS
	sta SCRIPT_ZP
	lda #>DEMO_SCRIPT_ADDRESS
	sta SCRIPT_ZP+1

	// Czyścimy tylko raz na początku 6400-8000 dla sprajtów
	// FillMem(0, FREEMEM_ADDRESS, FREEMEM_PAGES, PTR_ZP)

	jsr get_colors

	Sync()

	lda $dc0d
	lda $dd0d
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda #$01
	sta $d01a
	lsr $d019

	lda #$3b
	sta $d011
	lda #2
	sta $dd00
	SetD018(CHARSET_ADDRESS, SCREEN_ADDRESS)

	IrqSetup(IRQ0_LINE, irq0)
	cli
	jmp *

// ===================================================================
// get_colors
// ===================================================================

get_colors:

	lda #<SCREEN_ADDRESS
	sta ptr1l
	lda #>SCREEN_ADDRESS
	sta ptr1h
	lda #<CHARSET_ADDRESS
	sta ptr2l
	lda #>CHARSET_ADDRESS
	sta ptr2h
	ldx #0
	ldy #[dst_col-src_col]
	jsr bmp_neg

	rts

// ===================================================================
// Zmiana kolorów bitmapy i negacja
// ===================================================================

bmp_neg:
	stx neg_st+1
	sty neg_en+1
	
	lda ptr1h
	clc
	adc #4
	sta fin+1
	
dekod:	ldy #$00
neg_st:	ldx #0
!:	lda (ptr1),y
	cmp src_col,x
	beq !+
	inx
neg_en:	cpx #2
	bne !-
	beq cont
!:	lda dst_col,x
	sta (ptr1),y
	lda col_neg,x
	bne neg

cont:
	inc ptr1l
	bne !+
	inc ptr1h
!:	lda ptr2l
	clc
	adc #8
	sta ptr2l
	lda ptr2h
	adc #0
	sta ptr2h
	
	lda ptr1h
fin:	cmp #>(SCREEN_ADDRESS+$400)
	beq !+
	jmp dekod
!:
	rts

neg:
	ldy #$07
!:	lda (ptr2),y
	eor #$ff
	sta (ptr2),y
	dey
	bpl !-
	jmp cont
	
src_col:
	.byte $e3,$e0,$90,$ed,$3d,$29,$20,$cd,$c0,$28,$c1,$81,$08,$01
dst_col:
	.byte $3e,$0e,$09,$de,$d3,$92,$02,$dc,$0c,$82,$1c,$18,$80,$10
col_neg:
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	
// ===================================================================
// irq
// ===================================================================

irq0:
	IrqEntry2(IRQ_ZP)

	ldy SCRIPT_PTR
script_loop:
	lda (SCRIPT_ZP),y
	bmi rozkaz
	tax
	iny
	lda (SCRIPT_ZP),y
	sta $d000,x
	iny
	bne script_loop
	inc SCRIPT_ZP+1
	bne script_loop

rozkaz:
	//
	// zmiana ptr sprajta
	//
	cmp #SCRIPT_CMD_PTR_END
	bcs !+
	and #$07
	tax
	iny
	lda (SCRIPT_ZP),y
	sta SCREEN_ADDRESS+$3f8,x
	iny
	bne script_loop
	inc SCRIPT_ZP+1
	bne script_loop

!:	iny

	//
	// czekamy na d012
	//
	cmp #SCRIPT_CMD_D012
	bne !+
	lda (SCRIPT_ZP),y
	cmp $d012
	bne *-3
	iny
	bne script_loop
	inc SCRIPT_ZP+1
	bne script_loop

	//
	// NOP
	//
!:	cmp #SCRIPT_CMD_NOP
	bne !+
	iny
	bne script_loop
	inc SCRIPT_ZP+1
	bne script_loop

	//
	// New line
	//
!:	cmp #SCRIPT_CMD_NEWLINE
	bne !+
	lda $d012
	cmp $d012
	beq *-3
	lda (SCRIPT_ZP),y
	tax
	// ldx script_tab,y
	dex
	bpl *-1
	iny
	bne script_loop
	inc SCRIPT_ZP+1
	bne script_loop

	//
	// zwiększenie zmiennej w skrypcie
	//
!:	cmp #SCRIPT_CMD_INC
	bne !+
	lda (SCRIPT_ZP),y
	tax
	lda SCRIPT_ZP+1
	sta ptr1x+1
	inc ptr1x:script_tab,x
	iny
	bne script_loop1
	inc SCRIPT_ZP+1
	jmp script_loop

	//
	// zmniejszenie zmiennej w skrypcie
	//
!:	cmp #SCRIPT_CMD_DEC
	bne !+
	lda (SCRIPT_ZP),y
	tax
	lda SCRIPT_ZP+1
	sta ptr2x+1
	dec ptr2x:script_tab,x
	iny
	bne script_loop1
	inc SCRIPT_ZP+1
	jmp script_loop

	//
	// skok
	//
!:	cmp #SCRIPT_CMD_JMP
	bne !+
	lda (SCRIPT_ZP),y
	and #$fe
	tay
	bne script_loop1
	inc SCRIPT_ZP+1
	jmp script_loop

	//
	// SYNC
	//
!:	cmp #SCRIPT_CMD_SYNC
	bne !+
	Sync()
	iny
	bne script_loop1
	inc SCRIPT_ZP+1
	jmp script_loop

script_loop1:
	jmp script_loop

	//
	// nowe przerwanie
	//
!:	cmp #SCRIPT_CMD_IRQ
	bne !+
	lda (SCRIPT_ZP),y
	sta $d012
	iny
	sty SCRIPT_PTR
	bne irq_finish
	inc SCRIPT_ZP+1
	bne irq_finish

	//
	// koniec skryptu
	//
!:	cmp #SCRIPT_CMD_END
	bne irq_finish
	lda (SCRIPT_ZP),y
	sta $d012
	lda #0
	sta SCRIPT_PTR
	// lda #<DEMO_SCRIPT_ADDRESS
	// sta SCRIPT_ZP
	lda #>DEMO_SCRIPT_ADDRESS
	sta SCRIPT_ZP+1

irq_finish:
	IrqExit2(IRQ_ZP)

// ===================================================================
// "Skrypt"
/*
.const SCRIPT_PTR		= $80

.const SCRIPT_CMD_D012	= $90
.const SCRIPT_CMD_SYNC	= $91
.const SCRIPT_CMD_NEWLINE	= $92
.const SCRIPT_CMD_IRQ	= $93

.const SCRIPT_CMD_INC	= $A0
.const SCRIPT_CMD_DEC	= $A1

.const SCRIPT_CMD_NOP	= $FD
.const SCRIPT_CMD_JMP	= $FE
.const SCRIPT_CMD_END	= $FF
*/
// ===================================================================

	* = FREEMEM_ADDRESS
	.import binary "data\demo.prg",2

	* = DEMO_SCRIPT_ADDRESS "Demo script"
script_tab:
	// .byte SCRIPT_PTR+0,[(FREEMEM_ADDRESS & $3fff)/$40]+0
	// .byte SCRIPT_PTR+1,[(FREEMEM_ADDRESS & $3fff)/$40]+1
	// .byte SCRIPT_PTR+2,[(FREEMEM_ADDRESS & $3fff)/$40]+2
	// .byte SCRIPT_PTR+3,[(FREEMEM_ADDRESS & $3fff)/$40]+3
	// .byte SCRIPT_PTR+4,[(FREEMEM_ADDRESS & $3fff)/$40]+4
	// .byte SCRIPT_PTR+5,[(FREEMEM_ADDRESS & $3fff)/$40]+5
	// .byte SCRIPT_PTR+6,[(FREEMEM_ADDRESS & $3fff)/$40]+6
	// .byte SCRIPT_PTR+7,[(FREEMEM_ADDRESS & $3fff)/$40]+7
	// .byte $00,0
	// .byte $01,0
	// .byte $02,0
	// .byte $03,0
	// .byte $04,0
	// .byte $05,0
	// .byte $06,0
	// .byte $07,0
	// .byte $08,0
	// .byte $09,0
	// .byte $0a,0
	// .byte $0b,0
	// .byte $0c,0
	// .byte $0d,0
	// .byte $0e,0
	// .byte $0f,0
	// .byte $27,1
	// .byte $28,1
	// .byte $29,1
	// .byte $2a,1
	// .byte $2b,1
	// .byte $2c,1
	// .byte $2d,1
	// .byte $2e,1

	// .fill $200,$ff
	// // #import "inc\script.asm"
		
// ===================================================================
// Art Studio BMP
// ===================================================================

	* = CHARSET_ADDRESS "Art studio gfx (bmp)"
	.import binary "data\cx60cy70cz07_2.art",2,$2000
	* = SCREEN_ADDRESS "Art studio gfx (col)"
	.import binary "data\cx60cy70cz07_2.art",2+$1f40,$3e8

