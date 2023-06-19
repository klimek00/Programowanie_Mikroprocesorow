LED EQU P1.7
;********* Ustawienie TIMERów *********
;TIMER 0
T0_G EQU 0 ;GATE
T0_C EQU 0 ;COUNTER/-TIMER
T0_M EQU 1 ;MODE (0..3)
TIM0 EQU T0_M+T0_C*4+T0_G*8
;TIMER 1
T1_G EQU 0 ;GATE
T1_C EQU 0 ;COUNTER/-TIMER
T1_M EQU 0 ;MODE (0..3)
TIM1 EQU T1_M+T1_C*4+T1_G*8
TMOD_SET EQU TIM0+TIM1*16
;50[ms] = 50 000[ŠS]*(11.0592[MHz]/12) =
; = 46 080 cykli = 180 * 256
TH0_SET EQU 256-180
TL0_SET EQU 0
;**************************************
	LJMP BEGIN
TEXT: DB '00:00', 0
	ORG 100H
	
;;R3 -> HH [zegara]
;;R2 -> MM
;;R1 -> SS
;;R6 -> MM [alarmu]
;;R7 -> HH [alarmu]
;;R0 -> pozycja kursora [rejestr tymczasowy]
;;R5 -> zliczanie do sekundy 

;;80H -> pierwszy znak LCD.
;;81H -> poczatek LCD
BEGIN:
	CLR RS0
	CLR RS1
	LCALL LCD_INIT
	LCALL REFRESH

	;;SET DATE
	;HH
	MOV R0, #80H
	LCALL INS
	MOV R3, A	

	;MM
	MOV R0, #83H
	LCALL INS
	MOV R2, A

	;SS
	MOV R0, #86H
	LCALL INS
	MOV R1, A

	LCALL WAIT_ENTER
	LCALL LCD_CLR
	
	;;SET ALARM TIME
	;;wrzuc do datapointer adres tekstu
	MOV DPTR, #TEXT
	LCALL WRITE_TEXT
	MOV R0, #80H
	LCALL INS
	MOV R7, A	

	MOV R0, #83H
	LCALL INS
	MOV R6, A
	
	LCALL WAIT_ENTER
	LCALL LCD_CLR

	;;SET TIMER
	MOV TMOD, #TMOD_SET ;timer 0 -	 liczy czas
	MOV TH0, #TH0_SET 	;timer 0 na 10ms
	MOV TL0, #TL0_SET
	SETB TR0 						;uruchom timer

;dodaj sekundy, odswiez czas, na koncu alarm sprawdz 
LOOP:

	LCALL ADD_SEC
	LCALL REFRESH
	LCALL CHECK_ALARM

	MOV R5,#20 				;odczekaj czas
TIME_N10:
	JNB TF0, $ 					;czekaj, aż Timer 0 odliczy 50ms
	MOV TH0, #TH0_SET 		;TH0 na 50ms
	CLR TF0 						;zerowanie flagi timera 0
	DJNZ R5, TIME_N10 		;odczekanie N*50ms (20 *50ms)
	SJMP LOOP


REFRESH:
	LCALL LCD_CLR
	MOV A, R3
	LCALL DISP_HEX_BCD
	MOV A, #':'
	LCALL WRITE_DATA
	MOV A, R2
	LCALL DISP_HEX_BCD
	MOV A, #':'
	LCALL WRITE_DATA
	MOV A, R1
	LCALL DISP_HEX_BCD
	
	RET

CHECK_ALARM:
;;sprawdz godziny 
	CLR C
	MOV A, R7
	SUBB A, R3
	JNZ SKIP

;;sprawdz minuty
	CLR C
	MOV A, R6
	SUBB A, R2
	JNZ SKIP 

;;sprawdz czy sekundy 00
	SUBB A, R1
	JNZ SKIP

	MOV R4, #0
ALARM_RING:
	CLR P1.5
	CLR P1.7

	MOV A, #10
	LCALL DELAY_100MS

	;;dodaj zalegle sekundy 
	INC R1
	LCALL REFRESH
	MOV A, #10
	LCALL DELAY_100MS
	INC R1
	LCALL REFRESH

	SETB P1.5
	SETB P1.7

	RET

ADD_SEC:
	INC R1
	CJNE R1, #60, SKIP
	MOV R1, #0
	
ADD_MIN:
	INC R2
	CJNE R2, #60, SKIP
	MOV R2, #0

ADD_HOUR:
	INC R3
	CJNE R3, #24, SKIP
	MOV R3, #0

	RET

SKIP:
	RET

INS:
	MOV A, R0
	LCALL WRITE_INSTR
	LCALL WAIT_KEY
	MOV B, A
	LCALL WRITE_HEX
	MOV A, B
	MOV B, #10
	MUL AB
	MOV B, A
	LCALL WAIT_KEY
	ADD A, B
	;podobno mozna stosem ale nie chce mi sie myslec
	MOV R5, A

	;;wyslij instrukcje do wyswietlacza -> ustaw kursor pod adresem R3
	MOV A, R0
	LCALL WRITE_INSTR 
	MOV A, R5
	LCALL DISP_HEX_BCD
	MOV A, R5
	
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