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

.const	IRQ_ZP		= $02	// zajmuje 4
.const	PTR_ZP		= $06	// zajmuje 4
.const	SCRIPT_ZP		= $0A	// zajmuje 2

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
	lda #<DEMO_SCRIPT_ADDRESS
	sta SCRIPT_ZP
	lda #>DEMO_SCRIPT_ADDRESS
	sta SCRIPT_ZP+1

	// Czyścimy tylko raz na początku 6400-8000 dla sprajtów
	FillMem(0, FREEMEM_ADDRESS, FREEMEM_PAGES, PTR_ZP)

	ldx #$3e
	lda #$ff
!:	sta FREEMEM_ADDRESS,x
	dex
	bpl !-

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
	sta ptr1+1
	inc ptr1:script_tab,x
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
	sta ptr2+1
	dec ptr2:script_tab,x
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
// ===================================================================

	* = DEMO_SCRIPT_ADDRESS "Demo script"
script_tab:
	.fill $200,$ff
	// #import "inc\script.asm"
		
// ===================================================================
// Art Studio BMP
// ===================================================================

	* = CHARSET_ADDRESS "Art studio gfx (bmp)"
	.import binary "data\gfx-hires.art",2,$2000
	* = SCREEN_ADDRESS "Art studio gfx (col)"
	.import binary "data\gfx-hires.art",2+$1f40,$3e8

