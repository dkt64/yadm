# YADM (Yet Another Demo Maker) by DKT / Samar Productions @ 2020

## RAM LAYOUT

BMP $4000-$6000 Bitmapa
SCR $6000-$6400 Kolory dla hires
SPR $6400-$8000 Miejsce na sprajty
TAB $8000-$8100 Skrypt

## TABELA ROZKAZÓW

### Rozkaz                     Wartość         Parametr                  Opis
SCRIPT_VIC               = $00-$2F         Rejestr VIC               Sterowanie rejestrami VIC
SCRIPT_PTR               = $80-$87         Nr sprajta                Sterowanie wskaźnikami sprajtów
SCRIPT_CMD_D012          = $90             Linia rastra              Czekanie na linię rastra
SCRIPT_CMD_SYNC          = $91             -                         VSYNC
SCRIPT_CMD_NEWLINE       = $92             Opóźnienie                Czekanie na kolejną pozycję rastra + delay (eliminacja glitch)
SCRIPT_CMD_IRQ           = $93             Linia rastra              Nowe przerwanie
SCRIPT_CMD_INC           = $A0             Numer bajtu w skrypcie    Zwiększenie (INC) na bajcie w skrypcie
SCRIPT_CMD_DEC           = $A1             Numer bajtu w skrypcie    Zmniejszenie (DEC) na bajcie w skrypcie
SCRIPT_CMD_JMP           = $FE             Numer bajtu w skrypcie    Skok do nowej pozycji w skrypcie (AND #$FE tylko parzyste wartości)
SCRIPT_CMD_END           = $FF             Linia rastra              Koniec skryptu (skok do początku)
SCRIPT_DATA              = $00-$FF         Parametr                  Wartość parametru

## PRZYKŁAD
```
	* = TAB "Demo script"

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
```
## TODO
- rozkaz: zmiana banku
- wyliczanie adresu wskaźników do sprajtów na podstawie D018
