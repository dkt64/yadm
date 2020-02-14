/*

Makra

*/

//====================================================================

	.macro DEBUG_D020(kol) {
	#if DEBUG
	lda #kol
	sta $d020
	#endif
	}

//====================================================================

	.macro DEBUG_DECD020() {
	#if DEBUG
	dec $d020
	#endif
	}

//====================================================================

	.macro DEBUG_INCD020() {
	#if DEBUG
	dec $d020
	#endif
	}

//====================================================================

	.macro Sync() {
	lda $d011
	bpl *-3
	lda $d011
	bmi *-3
	}

//====================================================================
	.macro IrqEntry(address) {
	sta address+0
	stx address+1
	sty address+2
	lda $01
	sta address+3
	lda #$35
	sta $01	
	lsr $d019
	}

//====================================================================

	.macro IrqExit(address) {
	lda address+3
	sta $01
	ldy address+2
	ldx address+1
	lda address+0
	rti
	}

//====================================================================
	.macro IrqEntry2(address) {
	sta address+0
	stx address+1
	sty address+2
	lsr $d019
	}

//====================================================================

	.macro IrqExit2(address) {
	ldy address+2
	ldx address+1
	lda address+0
	rti
	}

//====================================================================

	.macro IrqSetup(line, address) {
	lda #line
	sta $d012
	lda #<address
	sta $fffe
	lda #>address
	sta $ffff
	}

//====================================================================

	.macro IrqSetup2(address) {
	lda #<address
	sta $fffe
	lda #>address
	sta $ffff
	}

//====================================================================

	.macro FillMem(val, dst, pages, zp) {
	ldx #pages
	lda #<dst
	sta zp+0
	lda #>dst
	sta zp+1
	ldy #0
!:	lda #val
!:	sta (zp),y
	iny
	bne !-
	inc zp+1
	dex
	bne !--
	}

//====================================================================

	.macro CopyMem(src, dst, pages, zp) {
	ldx #pages
	lda #<src
	sta zp+0
	lda #>src
	sta zp+1
	lda #<dst
	sta zp+2
	lda #>dst
	sta zp+3
	ldy #0
!:	lda (zp),y
	sta (zp+2),y
	iny
	bne !-
	inc zp+1
	inc zp+3
	dex
	bne !-
	}

//====================================================================

	.macro SetD018(charset, screen) {   
	lda	#[[screen & $3FFF] / 64] | [[charset & $3FFF] / 1024]
	sta	$D018
	}

//====================================================================

	.macro ClearScreen(screen, clearByte) {
	ldx #0
	lda #clearByte
!:	sta screen + $000,x
	sta screen + $100,x
	sta screen + $200,x
	sta screen + $300,x
	inx
	bne !-
	}

//====================================================================

	.macro ClearColorRam(clearByte) {
	ldx #0
	lda #clearByte
!:	sta $D800 + $000,x
	sta $D800 + $100,x
	sta $D800 + $200,x
	sta $D800 + $300,x
	inx
	bne !-
	}

//====================================================================
//---------------------------------
// repetition commands 
//---------------------------------
.macro ensureImmediateArgument(arg) {
	.if (arg.getType()!=AT_IMMEDIATE)	.error "The argument must be immediate!" 
}
.pseudocommand asl x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) asl
}
.pseudocommand lsr x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) lsr
}
.pseudocommand rol x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) rol
}
.pseudocommand ror x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) ror
}

.pseudocommand pla x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) pla
}

.pseudocommand nop x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) nop
}

.pseudocommand pause cycles {
	:ensureImmediateArgument(cycles)
	.var x = floor(cycles.getValue())
	.if (x<2) .error "Cant make a pause on " + x + " cycles"

	// Take care of odd cyclecount	
	.if ([x&1]==1) {
		bit $ea
		.eval x=x-3
	}	
	
	// Take care of the rest
	.if (x>0)
		:nop #x/2
}

//====================================================================
// HELP
//====================================================================
/*

$d011/53265/VIC+17:  Control Register 1
+----------+---------------------------------------------------+
| Bit  7   |    Raster Position Bit 8 from $D012               |
| Bit  6   |    Extended Color Text Mode: 1 = Enable           |
| Bit  5   |    Bitmap Mode: 1 = Enable                        |
| Bit  4   |    Blank Screen to Border Color: 0 = Blank        |
| Bit  3   |    Select 24/25 Row Text Display: 1 = 25 Rows     |
| Bits 2-0 |    Smooth Scroll to Y Dot-Position (0-7)          |
+----------+---------------------------------------------------+
Default Value: $9B/155 (%10011011).

$d016/53270/VIC+22:  Control Register 2
+----------+---------------------------------------------------+
| Bits 7-6 |    Unused                                         |
| Bit  5   |    Reset-Bit: 1 = Stop VIC (no Video Out, no RAM  |
|          |                   refresh, no bus access)         |
| Bit  4   |    Multi-Color Mode: 1 = Enable (Text or Bitmap)  |
| Bit  3   |    Select 38/40 Column Text Display: 1 = 40 Cols  |
| Bits 2-0 |    Smooth Scroll to X Dot-Position (0-7)          |
+----------+---------------------------------------------------+
Default Value: $08/8 (%00001000).

$d018/53272/VIC+24:   Memory Control Register
+----------+---------------------------------------------------+
| Bits 7-4 |   Video Matrix Base Address (inside VIC)          |
| Bit  3   |   Bitmap-Mode: Select Base Address (inside VIC)   |
| Bits 3-1 |   Character Dot-Data Base Address (inside VIC)    |
| Bit  0   |   Unused                                          |
+----------+---------------------------------------------------+
Default Value: $14/20 (%00010100).

$d01B/53275/VIC+27:  Sprite to Background Display Priority
+----------+---------------------------------------------------+
| Bit  x   |   Sprite x: 0 = Sprite has higher Priority        |
+----------+---------------------------------------------------+
Higher Priority means sprite is in front of everything.
Lower Priority means sprite is behind bit-combinations starting with
1 (e.g. %1 in hires mode and %1x in multi-color mode) and in front of
bit combinations starting with 0 (e.g. %0 in hires mode and %0x in
multi-color mode). So we get the following priority-tables:
Hires: Bit=0 < Sprite < Bit=1 ; Multi-Color: Bit=00 < Sprite < Bit = 10
                                             Bit=01 <        < Bit = 11

VIC's 16 Colors:

  0/$0 = Black           8/$8  = Orange
  1/$1 = White           9/$9  = Brown
  2/$2 = Red             10/$A = Light Red
  3/$3 = Cyan            11/$B = Dark Grey
  4/$4 = Purple          12/$C = Grey
  5/$5 = Green           13/$D = Light Green
  6/$6 = Blue            14/$E = Light Blue
  7/$7 = Yellow          15/$F = Light Grey

 sorted by Brightness:

   White
   Yellow      Light Green
   Cyan        Light Grey
   Green       Light Red
   Grey        Light Blue
   Purple      Orange
   Red         Dark Grey
   Blue        Brown
   Black

+-------------------------+
| VIC Bit Interpretations |
+-------------------------+
This map shows you which bit-combination forces VIC to get
the color-data from which location for all the different modes.
+---------------+----------------------------------------------------------+
| Charset-Hires |  0 = Background ($D021)      1 = Color-RAM               |
+---------------+----------------------------------------------------------+
| Charset-MC    | 00 = Background ($D021)     01 = MC-Color1 ($D022)       |
|               | 10 = MC-Color2  ($D023)     11 = Color-RAM               |
+---------------+----------------------------------------------------------+
| Bitmap-Hires  |  0 = LN Screen-RAM           1 = HN Screen-RAM           |
+---------------+----------------------------------------------------------+
| Bitmap-MC     | 00 = Background ($D021)     01 = HN Screen-RAM           |
|               | 10 = LN Screen-RAM          11 = Color-RAM               |
+---------------+----------------------------------------------------------+
| Sprite-Hires  |  0 = Background ($D021)      1 = Sprite-Color ($D027..)  |
+---------------+----------------------------------------------------------+
| Sprite-MC     | 00 = Background ($D021)     01 = Sprite-MC-Color1 ($D025)|
|               | 10 = Sprite-Color ($D027..) 11 = Sprite-MC-Color2 ($D026)|
+---------------+----------------------------------------------------------+
LN = Low-Nybble ; HN = High-Nybble

Register description:
$d000/53248/VIC+0        Sprite 0 X Pos
$d001/53249/VIC+1        Sprite 0 Y Pos
$d002/53250/VIC+2        Sprite 1 X Pos
$d003/53251/VIC+3        Sprite 1 Y Pos
$d004/53252/VIC+4        Sprite 2 X Pos
$d005/53253/VIC+5        Sprite 2 Y Pos
$d006/53254/VIC+6        Sprite 3 X Pos
$d007/53255/VIC+7        Sprite 3 Y Pos
$d008/53256/VIC+8        Sprite 4 X Pos
$d009/53257/VIC+9        Sprite 4 Y Pos
$d00A/53258/VIC+10       Sprite 5 X Pos
$d00B/53259/VIC+11       Sprite 5 Y Pos
$d00C/53260/VIC+12       Sprite 6 X Pos
$d00D/53261/VIC+13       Sprite 6 Y Pos
$d00E/53262/VIC+14       Sprite 7 X Pos
$d00F/53263/VIC+15       Sprite 7 Y Pos
$d010/53264/VIC+16       Sprites 0-7 MSB of X coordinate
$d011/53265/VIC+17       Control Register 1
$d012/53266/VIC+18       Raster Position
$d013/53267/VIC+19       Latch X Pos
$d014/53268/VIC+20       Latch Y Pos
$d015/53269/VIC+21       Sprite display Enable
$d016/53270/VIC+22       Control Register 2
$d017/53271/VIC+23       Sprites Expand 2x Vertical (Y)
$d018/53272/VIC+24       Memory Control Register
$d019/53273/VIC+25       Interrupt Request Register (IRR)
$d01A/53274/VIC+26       Interrupt Mask Register (IMR)
$d01B/53275/VIC+27       Sprite to Background Display Priority
$d01C/53276/VIC+28       Sprites Multi-Color Mode Select
$d01D/53277/VIC+29       Sprites Expand 2x Horizontal (X)
$d01E/53278/VIC+30       Sprite to Sprite Collision Detect
$d01F/53279/VIC+31       Sprite to Background Collision Detect
$d020/53280/VIC+32       Border Color
$d021/53281/VIC+33       Background Color 0
$d022/53282/VIC+34       Background Color 1, Multi-Color Register 0
$d023/53283/VIC+35       Background Color 2, Multi-Color Register 1
$d024/53284/VIC+36       Background Color 3
$d025/53285/VIC+37       Sprite Multi-Color Register 0
$d026/53286/VIC+38       Sprite Multi-Color Register 1
$d027/53287/VIC+39       Sprite 0 Color
$d028/53288/VIC+40       Sprite 1 Color
$d029/53289/VIC+41       Sprite 2 Color
$d02A/53290/VIC+42       Sprite 3 Color
$d02B/53291/VIC+43       Sprite 4 Color
$d02C/53292/VIC+44       Sprite 5 Color
$d02D/53293/VIC+45       Sprite 6 Color
$d02E/53294/VIC+46       Sprite 7 Color

*/
