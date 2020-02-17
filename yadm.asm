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

.const SCRIPT_PTR		= $0C

.const ptr1		= $10
.const ptr1l		= ptr1
.const ptr1h		= ptr1+1
.const ptr2		= $12
.const ptr2l		= ptr2
.const ptr2h		= ptr2+1

.const kolor00		= $80
.const kolor01		= kolor00+01
.const kolor02		= kolor00+02
.const kolor03		= kolor00+03
.const kolor04		= kolor00+04
.const kolor05		= kolor00+05
.const kolor06		= kolor00+06
.const kolor07		= kolor00+07
.const kolor08		= kolor00+08
.const kolor09		= kolor00+09
.const kolor10		= kolor00+10
.const kolor11		= kolor00+11
.const kolor12		= kolor00+12
.const kolor13		= kolor00+13
.const kolor14		= kolor00+14
.const kolor15		= kolor00+15

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

// ===================================================================

lp:
	lda #$e0
	cmp $d012
	bne *-3
	jsr fill_colors
	jmp lp

// ===================================================================
// fill_colors
// ===================================================================

color_tab:
	.byte $06,$0b,$04,$0c,$03,$0d,$01,$0d,$03,$0c,$04,$0b,$06
	.fill 20,0
color_tab_end:
	.byte 0

color_cycle:
	.byte 1

fill_colors:

	dec color_cycle
	lda color_cycle
	bne nope
	lda #2
	sta color_cycle

	ldx #0
	lda color_tab,x
	sta ctemp
!:	lda color_tab+1,x
	sta color_tab+0,x
	inx
	cpx #[color_tab_end-color_tab]
	bne !-
	lda ctemp:#0
	sta color_tab,x

nope:

	lda color_tab+$00
	sta kolor12
	asl
	asl
	asl
	asl
	sta kolor00

	// lda #$30
	// sta kolor00
	// lda #$03
	// sta kolor12

	lda color_tab+$01
	sta DEMO_SCRIPT_ADDRESS+$03B
	asl
	asl
	asl
	asl
	sta kolor01

	// lda #$a0
	// sta kolor01
	// lda #$0a
	// sta DEMO_SCRIPT_ADDRESS+$03B

	lda color_tab+$02
	sta kolor02
	sta DEMO_SCRIPT_ADDRESS+$035
	sta DEMO_SCRIPT_ADDRESS+$039
	sta DEMO_SCRIPT_ADDRESS+$05D
	sta DEMO_SCRIPT_ADDRESS+$07F

	// lda #$0e
	// sta kolor02
	// sta DEMO_SCRIPT_ADDRESS+$035
	// sta DEMO_SCRIPT_ADDRESS+$039
	// sta DEMO_SCRIPT_ADDRESS+$05D
	// sta DEMO_SCRIPT_ADDRESS+$07F

	lda color_tab+$03
	sta kolor10
	sta DEMO_SCRIPT_ADDRESS+$037
	sta DEMO_SCRIPT_ADDRESS+$05F
	sta DEMO_SCRIPT_ADDRESS+$09B
	asl
	asl
	asl
	asl
	sta kolor03

	// lda #$90
	// sta kolor03
	// lda #$09
	// sta kolor10
	// sta DEMO_SCRIPT_ADDRESS+$037
	// sta DEMO_SCRIPT_ADDRESS+$05F
	// sta DEMO_SCRIPT_ADDRESS+$09B

	lda color_tab+$04
	sta DEMO_SCRIPT_ADDRESS+$081
	sta DEMO_SCRIPT_ADDRESS+$0B5
	asl
	asl
	asl
	asl
	sta kolor04

	// lda #$d0
	// sta kolor04
	// lda #$0d
	// sta DEMO_SCRIPT_ADDRESS+$081
	// sta DEMO_SCRIPT_ADDRESS+$0B5

	lda color_tab+$05
	sta kolor05
	sta DEMO_SCRIPT_ADDRESS+$061
	sta DEMO_SCRIPT_ADDRESS+$09D

	// lda #$02
	// sta kolor05
	// sta DEMO_SCRIPT_ADDRESS+$061
	// sta DEMO_SCRIPT_ADDRESS+$09D

	lda color_tab+$06
	sta kolor11
	sta DEMO_SCRIPT_ADDRESS+$099
	sta DEMO_SCRIPT_ADDRESS+$0CB
	sta DEMO_SCRIPT_ADDRESS+$0F3
	asl
	asl
	asl
	asl
	sta kolor06

	// lda #$80
	// sta kolor06
	// lda #$08
	// sta kolor11
	// sta DEMO_SCRIPT_ADDRESS+$099
	// sta DEMO_SCRIPT_ADDRESS+$0CB
	// sta DEMO_SCRIPT_ADDRESS+$0F3

	lda color_tab+$07
	sta DEMO_SCRIPT_ADDRESS+$0CF
	sta DEMO_SCRIPT_ADDRESS+$0DF
	asl
	asl
	asl
	asl
	sta kolor07

	// lda #$10
	// sta kolor07
	// lda #$01
	// sta DEMO_SCRIPT_ADDRESS+$0CF
	// sta DEMO_SCRIPT_ADDRESS+$0DF

	lda color_tab+$08
	sta kolor08
	sta DEMO_SCRIPT_ADDRESS+$083
	sta DEMO_SCRIPT_ADDRESS+$0CD

	// lda #$0c
	// sta kolor08
	// sta DEMO_SCRIPT_ADDRESS+$083
	// sta DEMO_SCRIPT_ADDRESS+$0CD

	lda color_tab+$09
	sta kolor13
	sta DEMO_SCRIPT_ADDRESS+$0A9
	asl
	asl
	asl
	asl
	sta kolor09

	// lda #$b0
	// sta kolor09
	// lda #$0b
	// sta kolor13
	// sta DEMO_SCRIPT_ADDRESS+$0A9

// 	ldx #15
// !:	lda color_tab,x
// 	sta kolor00,x
// 	dex
// 	bpl !-

	lda kolor00 // 30
	sta SCREEN_ADDRESS+$061
	sta SCREEN_ADDRESS+$062
	sta SCREEN_ADDRESS+$08b
	sta SCREEN_ADDRESS+$08c
	sta SCREEN_ADDRESS+$08d
	sta SCREEN_ADDRESS+$0b5
	sta SCREEN_ADDRESS+$0b6
	sta SCREEN_ADDRESS+$0b7
	sta SCREEN_ADDRESS+$0b8
	sta SCREEN_ADDRESS+$0de
	sta SCREEN_ADDRESS+$0df
	sta SCREEN_ADDRESS+$0e0
	sta SCREEN_ADDRESS+$0e1
	sta SCREEN_ADDRESS+$0e2
	sta SCREEN_ADDRESS+$0e3
	sta SCREEN_ADDRESS+$107
	ora kolor02 // 0E
	sta SCREEN_ADDRESS+$089
	sta SCREEN_ADDRESS+$08a
	sta SCREEN_ADDRESS+$0b3
	sta SCREEN_ADDRESS+$0b4
	sta SCREEN_ADDRESS+$0dc
	sta SCREEN_ADDRESS+$0dd
	sta SCREEN_ADDRESS+$105
	sta SCREEN_ADDRESS+$106

	lda kolor00 // 30
	ora kolor10 // 09
	sta SCREEN_ADDRESS+$108
	sta SCREEN_ADDRESS+$109
	sta SCREEN_ADDRESS+$10a
	sta SCREEN_ADDRESS+$130

	lda kolor01 // A0
	sta SCREEN_ADDRESS+$088
	sta SCREEN_ADDRESS+$0af
	sta SCREEN_ADDRESS+$0d6
	sta SCREEN_ADDRESS+$0fd
	sta SCREEN_ADDRESS+$0fe
	sta SCREEN_ADDRESS+$124
	sta SCREEN_ADDRESS+$125
	sta SCREEN_ADDRESS+$14c
	sta SCREEN_ADDRESS+$173
	ora kolor02 // 0E
	sta SCREEN_ADDRESS+$0b0
	sta SCREEN_ADDRESS+$0d7
	sta SCREEN_ADDRESS+$0ff
	sta SCREEN_ADDRESS+$126
	sta SCREEN_ADDRESS+$14d
	sta SCREEN_ADDRESS+$174
	sta SCREEN_ADDRESS+$175

	lda kolor02 // 0E
	sta SCREEN_ADDRESS+$000000B1
	sta SCREEN_ADDRESS+$000000B2
	sta SCREEN_ADDRESS+$000000D8
	sta SCREEN_ADDRESS+$000000D9
	sta SCREEN_ADDRESS+$000000DA
	sta SCREEN_ADDRESS+$000000DB
	sta SCREEN_ADDRESS+$00000100
	sta SCREEN_ADDRESS+$00000101
	sta SCREEN_ADDRESS+$00000102
	sta SCREEN_ADDRESS+$00000103
	sta SCREEN_ADDRESS+$00000104
	sta SCREEN_ADDRESS+$00000127
	sta SCREEN_ADDRESS+$00000128
	sta SCREEN_ADDRESS+$00000129
	sta SCREEN_ADDRESS+$0000012A
	sta SCREEN_ADDRESS+$0000012B
	sta SCREEN_ADDRESS+$0000012C
	sta SCREEN_ADDRESS+$0000012D
	sta SCREEN_ADDRESS+$0000014E
	sta SCREEN_ADDRESS+$0000014F
	sta SCREEN_ADDRESS+$00000150
	sta SCREEN_ADDRESS+$00000151

	lda kolor03 // 90
	sta SCREEN_ADDRESS+$0000010B
	sta SCREEN_ADDRESS+$00000131
	sta SCREEN_ADDRESS+$00000132
	sta SCREEN_ADDRESS+$00000133
	sta SCREEN_ADDRESS+$00000159
	sta SCREEN_ADDRESS+$0000015A
	sta SCREEN_ADDRESS+$0000015B
	sta SCREEN_ADDRESS+$0000015C
	sta SCREEN_ADDRESS+$00000182
	sta SCREEN_ADDRESS+$00000183
	sta SCREEN_ADDRESS+$00000184
	sta SCREEN_ADDRESS+$000001AB
	sta SCREEN_ADDRESS+$000001AC
	sta SCREEN_ADDRESS+$000001D3
	sta SCREEN_ADDRESS+$000001D4
	sta SCREEN_ADDRESS+$000001FC
	sta SCREEN_ADDRESS+$00000225
	sta SCREEN_ADDRESS+$0000024D

	lda kolor04 // D0
	ora kolor02 // 0E
	sta SCREEN_ADDRESS+$0000012E
	sta SCREEN_ADDRESS+$00000152
	sta SCREEN_ADDRESS+$00000153
	sta SCREEN_ADDRESS+$00000154
	sta SCREEN_ADDRESS+$00000155
	sta SCREEN_ADDRESS+$00000176
	sta SCREEN_ADDRESS+$00000177
	sta SCREEN_ADDRESS+$00000178
	sta SCREEN_ADDRESS+$00000179
	sta SCREEN_ADDRESS+$0000019D

	lda kolor04 // D0
	sta SCREEN_ADDRESS+$00000156
	sta SCREEN_ADDRESS+$0000017A
	sta SCREEN_ADDRESS+$0000017B
	sta SCREEN_ADDRESS+$0000017C
	sta SCREEN_ADDRESS+$0000017D
	sta SCREEN_ADDRESS+$0000017E
	sta SCREEN_ADDRESS+$0000019E
	sta SCREEN_ADDRESS+$0000019F
	sta SCREEN_ADDRESS+$000001A0
	sta SCREEN_ADDRESS+$000001A1
	sta SCREEN_ADDRESS+$000001A2
	sta SCREEN_ADDRESS+$000001A3
	sta SCREEN_ADDRESS+$000001A4
	sta SCREEN_ADDRESS+$000001A5
	sta SCREEN_ADDRESS+$000001C6
	sta SCREEN_ADDRESS+$000001C7
	sta SCREEN_ADDRESS+$000001C8
	sta SCREEN_ADDRESS+$000001C9
	sta SCREEN_ADDRESS+$000001CA
	sta SCREEN_ADDRESS+$000001CB
	sta SCREEN_ADDRESS+$000001CC
	sta SCREEN_ADDRESS+$000001CD
	sta SCREEN_ADDRESS+$000001EF
	sta SCREEN_ADDRESS+$000001F0
	sta SCREEN_ADDRESS+$000001F1
	sta SCREEN_ADDRESS+$000001F2
	sta SCREEN_ADDRESS+$000001F3
	sta SCREEN_ADDRESS+$000001F4
	sta SCREEN_ADDRESS+$000001F5
	sta SCREEN_ADDRESS+$00000218
	sta SCREEN_ADDRESS+$00000219
	sta SCREEN_ADDRESS+$0000021A
	sta SCREEN_ADDRESS+$0000021B
	sta SCREEN_ADDRESS+$0000021C
	sta SCREEN_ADDRESS+$00000241
	sta SCREEN_ADDRESS+$00000242
	sta SCREEN_ADDRESS+$00000243
	sta SCREEN_ADDRESS+$00000244
	sta SCREEN_ADDRESS+$0000026A
	sta SCREEN_ADDRESS+$0000026B
	sta SCREEN_ADDRESS+$0000026C
	sta SCREEN_ADDRESS+$00000293
	sta SCREEN_ADDRESS+$00000294
	ora kolor12 // 03
	sta SCREEN_ADDRESS+$0000012F

	lda kolor05 // 02
	sta SCREEN_ADDRESS+$000001A7
	sta SCREEN_ADDRESS+$000001A8
	sta SCREEN_ADDRESS+$000001CF
	sta SCREEN_ADDRESS+$000001D0
	sta SCREEN_ADDRESS+$000001D1
	sta SCREEN_ADDRESS+$000001F7
	sta SCREEN_ADDRESS+$000001F8
	sta SCREEN_ADDRESS+$000001F9
	sta SCREEN_ADDRESS+$000001FA
	sta SCREEN_ADDRESS+$0000021F
	sta SCREEN_ADDRESS+$00000220
	sta SCREEN_ADDRESS+$00000221
	sta SCREEN_ADDRESS+$00000222
	sta SCREEN_ADDRESS+$00000246
	sta SCREEN_ADDRESS+$00000247
	sta SCREEN_ADDRESS+$00000248
	sta SCREEN_ADDRESS+$00000249
	sta SCREEN_ADDRESS+$0000024A
	sta SCREEN_ADDRESS+$0000024B
	sta SCREEN_ADDRESS+$0000026E
	sta SCREEN_ADDRESS+$0000026F
	sta SCREEN_ADDRESS+$00000270
	sta SCREEN_ADDRESS+$00000271
	sta SCREEN_ADDRESS+$00000272
	sta SCREEN_ADDRESS+$00000273
	sta SCREEN_ADDRESS+$00000275
	sta SCREEN_ADDRESS+$00000296
	sta SCREEN_ADDRESS+$00000297
	sta SCREEN_ADDRESS+$00000298
	sta SCREEN_ADDRESS+$000002BD
	ora kolor04 // D0
	sta SCREEN_ADDRESS+$00000157
	sta SCREEN_ADDRESS+$0000017F
	sta SCREEN_ADDRESS+$000001A6
	sta SCREEN_ADDRESS+$000001CE
	sta SCREEN_ADDRESS+$000001F6
	sta SCREEN_ADDRESS+$0000021D
	sta SCREEN_ADDRESS+$0000021E
	sta SCREEN_ADDRESS+$00000245
	sta SCREEN_ADDRESS+$0000026D
	sta SCREEN_ADDRESS+$00000295
	sta SCREEN_ADDRESS+$000002BC
	sta SCREEN_ADDRESS+$000002E4

	lda kolor03 // 90
	ora kolor05 // 02
	sta SCREEN_ADDRESS+$00000158
	sta SCREEN_ADDRESS+$00000180
	sta SCREEN_ADDRESS+$00000181
	sta SCREEN_ADDRESS+$000001A9
	sta SCREEN_ADDRESS+$000001AA
	sta SCREEN_ADDRESS+$000001D2
	sta SCREEN_ADDRESS+$000001FB
	sta SCREEN_ADDRESS+$00000223
	sta SCREEN_ADDRESS+$00000224
	sta SCREEN_ADDRESS+$0000024C

	lda kolor01 // A0
	ora kolor13 // 0B
	sta SCREEN_ADDRESS+$0000019B
	sta SCREEN_ADDRESS+$0000019C

	lda kolor09
	sta SCREEN_ADDRESS+$000001C3
	sta SCREEN_ADDRESS+$000001EB
	sta SCREEN_ADDRESS+$00000213
	sta SCREEN_ADDRESS+$0000023B
	sta SCREEN_ADDRESS+$00000263
	sta SCREEN_ADDRESS+$0000028B

	lda kolor09
	ora kolor08
	sta SCREEN_ADDRESS+$000001C4
	sta SCREEN_ADDRESS+$000001EC
	sta SCREEN_ADDRESS+$00000214
	sta SCREEN_ADDRESS+$0000023C
	sta SCREEN_ADDRESS+$00000264
	sta SCREEN_ADDRESS+$0000028C
	sta SCREEN_ADDRESS+$000002B4

	lda kolor04
	ora kolor08
	sta SCREEN_ADDRESS+$000001C5
	sta SCREEN_ADDRESS+$000001EE
	sta SCREEN_ADDRESS+$00000217
	sta SCREEN_ADDRESS+$00000240
	sta SCREEN_ADDRESS+$00000269
	sta SCREEN_ADDRESS+$00000291
	sta SCREEN_ADDRESS+$00000292
	sta SCREEN_ADDRESS+$000002BA
	sta SCREEN_ADDRESS+$000002BB

	lda kolor08
	sta SCREEN_ADDRESS+$000001ED
	sta SCREEN_ADDRESS+$00000215
	sta SCREEN_ADDRESS+$00000216
	sta SCREEN_ADDRESS+$0000023D
	sta SCREEN_ADDRESS+$0000023E
	sta SCREEN_ADDRESS+$0000023F
	sta SCREEN_ADDRESS+$00000265
	sta SCREEN_ADDRESS+$00000266
	sta SCREEN_ADDRESS+$00000267
	sta SCREEN_ADDRESS+$00000268
	sta SCREEN_ADDRESS+$0000028D
	sta SCREEN_ADDRESS+$0000028E
	sta SCREEN_ADDRESS+$0000028F
	sta SCREEN_ADDRESS+$00000290
	sta SCREEN_ADDRESS+$000002B5
	sta SCREEN_ADDRESS+$000002B6
	sta SCREEN_ADDRESS+$000002B7
	sta SCREEN_ADDRESS+$000002B8
	sta SCREEN_ADDRESS+$000002B9
	sta SCREEN_ADDRESS+$000002DC
	sta SCREEN_ADDRESS+$000002DD
	sta SCREEN_ADDRESS+$000002DE
	sta SCREEN_ADDRESS+$000002DF
	sta SCREEN_ADDRESS+$000002E0
	sta SCREEN_ADDRESS+$000002E1
	sta SCREEN_ADDRESS+$00000304

	lda kolor06
	sta SCREEN_ADDRESS+$0000029C
	sta SCREEN_ADDRESS+$000002C1
	sta SCREEN_ADDRESS+$000002C2
	sta SCREEN_ADDRESS+$000002C3
	sta SCREEN_ADDRESS+$000002E7
	sta SCREEN_ADDRESS+$000002E8
	sta SCREEN_ADDRESS+$000002E9
	sta SCREEN_ADDRESS+$000002EA
	sta SCREEN_ADDRESS+$0000030E
	sta SCREEN_ADDRESS+$0000030F
	sta SCREEN_ADDRESS+$00000310
	sta SCREEN_ADDRESS+$00000311
	sta SCREEN_ADDRESS+$00000336
	sta SCREEN_ADDRESS+$00000337
	sta SCREEN_ADDRESS+$00000338
	sta SCREEN_ADDRESS+$0000035F
	ora kolor05
	sta SCREEN_ADDRESS+$00000274
	sta SCREEN_ADDRESS+$00000299
	sta SCREEN_ADDRESS+$0000029A
	sta SCREEN_ADDRESS+$0000029B
	sta SCREEN_ADDRESS+$000002BE
	sta SCREEN_ADDRESS+$000002BF
	sta SCREEN_ADDRESS+$000002C0
	sta SCREEN_ADDRESS+$000002E5
	sta SCREEN_ADDRESS+$000002E6

	lda kolor07
	sta SCREEN_ADDRESS+$0000030A
	sta SCREEN_ADDRESS+$0000030B
	sta SCREEN_ADDRESS+$0000032E
	sta SCREEN_ADDRESS+$0000032F
	sta SCREEN_ADDRESS+$00000330
	sta SCREEN_ADDRESS+$00000331
	sta SCREEN_ADDRESS+$00000332
	sta SCREEN_ADDRESS+$00000333
	sta SCREEN_ADDRESS+$00000334
	sta SCREEN_ADDRESS+$00000359
	sta SCREEN_ADDRESS+$0000035A
	sta SCREEN_ADDRESS+$0000035B
	sta SCREEN_ADDRESS+$0000035C
	sta SCREEN_ADDRESS+$00000385
	sta SCREEN_ADDRESS+$00000386
	ora kolor08
	sta SCREEN_ADDRESS+$000002E2
	sta SCREEN_ADDRESS+$000002E3
	sta SCREEN_ADDRESS+$00000305
	sta SCREEN_ADDRESS+$00000306
	sta SCREEN_ADDRESS+$00000307
	sta SCREEN_ADDRESS+$00000308
	sta SCREEN_ADDRESS+$00000309

	lda kolor07
	ora kolor11
	sta SCREEN_ADDRESS+$0000030C
	sta SCREEN_ADDRESS+$0000030D
	sta SCREEN_ADDRESS+$00000335
	sta SCREEN_ADDRESS+$0000035D
	sta SCREEN_ADDRESS+$0000035E

	rts

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
fin:	cmp #>(SCREEN_ADDRESS+$300)
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
	.byte $e3,$e0,$09,$ed,$3d,$29,$20,$cd,$c0,$28,$c1,$81,$08
dst_col:
	.byte $3e,$0e,$90,$de,$d3,$92,$02,$dc,$0c,$82,$1c,$18,$80
col_neg:
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
		
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

