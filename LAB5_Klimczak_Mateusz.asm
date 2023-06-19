LED EQU P1.7
;;//////// Ustawienie TIMERów ////////;;
;TIMER 0
T0_G EQU 0 ;GATE
T0_C EQU 0 ;COUNTER/-TIMER
T0_M EQU 1 ;MODE (0..3)
TIM0 EQU T0_M+T0_C*4+T0_G*8
;TIMER 1
T1_G EQU 0 ;GATE
T1_C EQU 0 ;COUNTER/-TIMER
T1_M EQU 1 ;MODE (0..3)
TIM1 EQU T1_M+T1_C*4+T1_G*8
TMOD_SET EQU TIM0+TIM1*16
;; 1[ms] = 10 000[ŠS]*(11.0592[MHz]/12) =
;; = 9 216 cykli = 36 * 256
TH0_SET EQU 256-36
TL0_SET EQU 0

;;50 ms
TH1_SET EQU 256-180
TL1_SET EQU 0

;;//////// POCZATEK PROGRAMU ////////
	LJMP BEGIN

;;// PRZERWANIE TIMER0 //
  ORG 0BH
  MOV TH0, #TH0_SET
	LCALL REFRESH
	LCALL ADD_MSEC
	RETI
	NOP
;;///////// /////////

;;// PRZERWANIE TIMER1 //
  ORG 1BH
  MOV TH1, #TH1_SET
	LCALL INIT_TIMER1
	RETI
	NOP
;;///////// /////////

  ORG 100H
;;R2 -> SS [zegara]
;;R1 -> MS * 10 [inaczej out of range]
;;R3 -> rejest liczacy 10 sekund (200ms *50 tików = 10s)
;;R4 -> rejestr liczący 2 sekundy (10 ms *50 tików = 0.5s)

BEGIN:
	LCALL WAIT_ENTER
	MOV R1, #0
	MOV R2, #0
	MOV R3, #200
	LCALL LCD_INIT

  ;;SET TIMER0
	MOV TMOD, #TMOD_SET ;timer 0 liczy czas
	MOV TH0, #TH0_SET 	;timer 0 na 10ms
	MOV TL0, #TL0_SET

	;;SET TIMER1
	MOV TH1, #TH1_SET
	MOV TL1, #TL1_SET

  SETB EA             ;zezwolenie ogolne na przerwania
  SETB ET0            ;zezwolenie na przerwanie
	SETB ET1

  MOV R7, #1
	SETB TR0
	SETB TR1

;;// PRZERWANIE TIMERA //
LOOP:
	LCALL WAIT_ENTER_NW
	CLR TR0
	CLR TR1

	LCALL WAIT_ENTER_NW
	SETB TR0
	SETB TR1

  SJMP LOOP
;;///////// /////////

INIT_TIMER1:
	LCALL CHECK_BUZZ
	LCALL WAIT_BUZZ
	RET

;;// BRZECZYK //
CHECK_BUZZ:
	DJNZ R3, SKIP

	CLR P1.5
	MOV R4, #10

	MOV R3, #200
  RET

WAIT_BUZZ:
	DJNZ R4, SKIP
	SETB P1.5

	RET
;;//////// ////////

;;// AKTUALIZACJA CZASU //
;;1000ms = 1s, res=10ms, liczba <= 256, 
ADD_MSEC:
  INC R1
	CJNE R1, #100, SKIP
	MOV R1, #0
	
ADD_SEC:
	INC R2
	CJNE R2, #100, SKIP
	MOV R2, #0

;;////////  ////////

SKIP:
	RET

REFRESH:
	LCALL LCD_CLR
	MOV A, R2
	LCALL DISP_HEX_BCD
	MOV A, #','
	LCALL WRITE_DATA
  MOV A, R1
	LCALL DISP_HEX_BCD	
	
  RET

DISP_HEX_BCD:
	MOV B, #10
	DIV AB
	SWAP A
	ADD A, B
	LCALL WRITE_HEX

	RET

  SJMP $
  NOP