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
.const DEMO_INIT_ADDRESS	= $8100

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
.const	script_ptr	= $0A

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
	sta script_ptr

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

	ldy script_ptr
script_loop:
	lda script_tab,y
	bmi rozkaz
	tax
	iny
	lda script_tab,y
	sta $d000,x
	iny
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
	lda script_tab,y
	sta SCREEN_ADDRESS+$3f8,x
	iny
	jmp script_loop

!:	iny

	//
	// czekamy na d012
	//
	cmp #SCRIPT_CMD_D012
	bne !+
	lda script_tab,y
	cmp $d012
	bne *-3
	iny
	jmp script_loop

	//
	// NOP
	//
!:	cmp #SCRIPT_CMD_NOP
	bne !+
	iny
	jmp script_loop

	//
	// zwiększenie zmiennej w skrypcie
	//
!:	cmp #SCRIPT_CMD_INC
	bne !+
	ldx script_tab,y
	inc script_tab,x
	iny
	jmp script_loop

	//
	// zmniejszenie zmiennej w skrypcie
	//
!:	cmp #SCRIPT_CMD_DEC
	bne !+
	ldx script_tab,y
	dec script_tab,x
	iny
	jmp script_loop

	//
	// skok
	//
!:	cmp #SCRIPT_CMD_JMP
	bne !+
	lda script_tab,y
	and #$fe
	tay
	jmp script_loop

	//
	// SYNC
	//
!:	cmp #SCRIPT_CMD_SYNC
	bne !+
	Sync()
	iny
	jmp script_loop

	//
	// New line
	//
!:	cmp #SCRIPT_CMD_NEWLINE
	bne !+
	lda $d012
	cmp $d012
	beq *-3
	ldx script_tab,y
	dex
	bpl *-1
	iny
	jmp script_loop

	//
	// nowe przerwanie
	//
!:	cmp #SCRIPT_CMD_IRQ
	bne !+
	lda script_tab,y
	sta $d012
	iny
	sty script_ptr
	jmp irq_finish

	//
	// koniec skryptu
	//
!:	cmp #SCRIPT_CMD_END
	bne irq_finish
	lda script_tab,y
	sta $d012
	lda #0
	sta script_ptr

irq_finish:
	IrqExit2(IRQ_ZP)

// ===================================================================
// "Skrypt"
// ===================================================================

	* = DEMO_SCRIPT_ADDRESS "Demo script"
script_tab:

	.byte $15 // SCRIPT_VIC               Włączenie sprajta nr 0
	.byte $01 // SCRIPT_DATA              $01

	.byte $80 // SCRIPT_PTR               Pointer sprajta nr 0
	.byte $90 // SCRIPT_DATA              $6400-$643E
	.byte $2e // SCRIPT_VIC               Kolor sprajta nr 0
	.byte $0f // SCRIPT_DATA              Jasny szary
var1:	.byte $00 // SCRIPT_VIC               Pozycja X LO sprajta nr 0
	.byte $00 // SCRIPT_DATA              $18
	.byte $10 // SCRIPT_VIC               Pozycja X HI sprajta nr 0
	.byte $00 // SCRIPT_DATA              $00
	.byte $01 // SCRIPT_VIC               Pozycja Y sprajta nr 0
	.byte $32 // SCRIPT_DATA              $32

	.byte $A0 // SCRIPT_CMD_INC           Zwiększenie pozycji X
	.byte [var1-script_tab+1] //          Indeks w tablicy skryptu
	.byte $A1 // SCRIPT_CMD_DEC           Zmniejszenie pozycji X
	.byte [var2-script_tab+1] //          Indeks w tablicy skryptu

	.byte $93 // SCRIPT_CMD_IRQ           Dodatkowe przerwanie
	.byte $2f // SCRIPT_DATA              Linia $2F
	.byte $92 // SCRIPT_CMD_NEWLINE       Czekaj na kolejną linię
	.byte $07 // SCRIPT_DATA              Opóźnienie w celu eliminacji glitch
	.byte $20 // SCRIPT_VIC               Rejestr $D020
	.byte $00 // SCRIPT_DATA              Kolor czarny

	.byte $90 // SCRIPT_CMD_D012          Czekaj na $D012
	.byte $50 // SCRIPT_DATA              Linia $50
var2:	.byte $00 // SCRIPT_VIC               Pozycja X LO sprajta nr 0
	.byte $00 // SCRIPT_DATA              $18
	.byte $01 // SCRIPT_VIC               Pozycja Y sprajta nr 0
	.byte $62 // SCRIPT_DATA              $62

	.byte $93 // SCRIPT_CMD_IRQ           Dodatkowe przerwanie
	.byte $f9 // SCRIPT_DATA              Linia $F9
	.byte $92 // SCRIPT_CMD_NEWLINE       Czekaj na kolejną linię
	.byte $07 // SCRIPT_DATA              Opóźnienie w celu eliminacji glitch
	.byte $20 // SCRIPT_VIC               Rejestr $D020
	.byte $06 // SCRIPT_DATA              Kolor czarny

	.byte $ff // SCRIPT_CMD_END           Koniec skryptu (zapętlenie)
	.byte IRQ0_LINE // SCRIPT_DATA        Linia rastra

// ===================================================================
// Art Studio BMP
// ===================================================================

	* = CHARSET_ADDRESS "Art studio gfx (bmp)"
	.import binary "data\gfx-hires.art",2,$2000
	* = SCREEN_ADDRESS "Art studio gfx (col)"
	.import binary "data\gfx-hires.art",2+$1f40,$3e8

