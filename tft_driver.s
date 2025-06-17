	;Islam nafea shaban


	AREA MYDATA, DATA, READONLY


RCC_BASE	EQU		0x40021000 ;this register is responsible for enabling certain ports, by making the clock affect the target port.
RCC_APB2ENR		EQU		RCC_BASE + 0x18
	
GPIOA_BASE EQU 0x40010800	;Base of port A
GPIOA_CRL  EQU  GPIOA_BASE+ 0X00   ;CONGIGURE TYPE AND SPEED OF PINS 0->7
GPIOA_CRH  EQU	GPIOA_BASE+ 0X04   ;CONFIGURE TYPE AND SPEED OF PINS 8->15
GPIOA_ODR  EQU  GPIOA_BASE+ 0X0C   ; REGISTER TO PUT YOUR DATA AS OUTPUT 
GPIOA_IDR  EQU  GPIOA_BASE+ 0X08

GPIOB_BASE EQU 0x40010C00   ;Base of port B
GPIOB_CRL  EQU  GPIOB_BASE+ 0X00 
GPIOB_CRH  EQU	GPIOB_BASE+ 0X04
GPIOB_ODR  EQU  GPIOB_BASE+ 0X0C
GPIOB_IDR  EQU  GPIOB_BASE+ 0X08



INTERVAL EQU 0x566004		;just a number to perform the delay. this number takes roughly 1 second to decrement until it reaches 0




;the following are pins connected from the TFT to BLUEPILL board
;RD = PB10		Read pin	--> to read from touch screen input 
;WR = PB11		Write pin	--> to write data/command to display
;RS = PB12		Command pin	--> to choose command or data to write
;CS = PB15		Chip Select	--> to enable the TFT, lol	(active low)
;RST= PB8		Reset		--> to reset the TFT (active low)
;D0-7 = PA 0-7	Data BUS	--> Put your command or data on this bus



;just some color codes, 16-bit colors coded in RGB 565
BLACK	EQU   	0x0000
BLUE 	EQU  	0x001F
RED  	EQU  	0xF800
RED2   	EQU 	0x4000
GREEN 	EQU  	0x07E0
CYAN  	EQU  	0x07FF
MAGENTA EQU 	0xF81F
YELLOW	EQU  	0xFFE0
WHITE 	EQU  	0xFFFF
GREEN2 	EQU 	0x2FA4
CYAN2 	EQU  	0x07FF

	
	

	AREA	MYCODE, CODE, READONLY
	ENTRY


	EXPORT LCD_COMMAND_WRITE
	EXPORT LCD_DATA_WRITE
	EXPORT LCD_INIT
	EXPORT ADDRESS_SET
	EXPORT DRAWPIXEL
	EXPORT DRAW_RECTANGLE_FILLED
	EXPORT DRAW_triangle 
	EXPORT SETUP
	








;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ FUNCTIONS' DEFINITIONS @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



	



;#####################################################################################################################################################################
LCD_WRITE
	;this function takes what is inside r2 and writes it to the tft
	;this function writes 8 bits only
	;later we will choose whether those 8 bits are considered a command, or just pure data
	;your job is to just write 8-bits (regardless if data or command) to PE0-7 and set WR appropriately
	;arguments: R2 = data to be written to the D0-7 bus

	;TODO: PUSH THE NEEDED REGISTERS TO SAVE THEIR CONTENTS. HINT: Push any register you will modify inside the function, and LR 
	 
	PUSH{R0-R12,LR}


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETTING WR to 0 ;;;;;;;;;;;;;;;;;;;;;
	;TODO: RESET WR TO 0
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#11
    mvn R1,R1    ;ONES COMPLEMENT OF R1  
	AND r3,r3,r1
	str r3,[r0]

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	;;;;;;;;;;;;; HERE YOU PUT YOUR DATA which is in R2 TO PE0-7 ;;;;;;;;;;;;;;;;;
	;TODO: SET PE0-7 WITH THE LOWER 8-bits of R2
	;only write the lower byte to PE0-7
	 LDR  R0,=GPIOA_ODR
	 STRB R2,[R0]

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	;;;;;;;;;;;;;;;;;;;;;;;;;; SETTING WR to 1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TODO: SET WR TO 1 AGAIN (ie make a rising edge)
	LDR r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#0X0B
	ORR r3,r1
	str r3,[r0]
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	;TODO: POP THE REGISTERS YOU JUST PUSHED, and PC
	POP{R0-R12,PC}
	
;#####################################################################################################################################################################











;#####################################################################################################################################################################
LCD_COMMAND_WRITE
	;this function writes a command to the TFT, the command is read from R2
	;it writes LOW to RS first to specify that we are writing a command not data.
	;then it normally calls the function LCD_WRITE we just defined above
	;arguments: R2 = data to be written on D0-7 bus

	;TODO: PUSH ANY NEEDED REGISTERS
		PUSH{R0-R12,LR}
	

	;;;;;;;;;;;;;;;;;;;;;;;;;; SETTING RD to 1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TODO: SET RD HIGH (we won't need reading anyways, but we must keep read pin to high, which means we will not read anything)
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#0X0A
	ORR r3,r1
	str r3,[r0]
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	;;;;;;;;;;;;;;;;;;;;;;;;; SETTING RS to 0 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TODO: SET RS TO 0 (to specify that we are writing commands not data on the D0-7 bus)
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#0X0C
    MVN R1,R1;          ONES COMPLEMENT OF R1 
	AND r3,r1
	str r3,[r0]
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;TODO: CALL FUNCTION LCD_WRITE
	 BL LCD_WRITE


	;TODO: POP ALL REGISTERS YOU PUSHED
		POP{R0-R12,PC}
;#####################################################################################################################################################################






;#####################################################################################################################################################################
LCD_DATA_WRITE
	;this function writes Data to the TFT, the data is read from R2
	;it writes HIGH to RS first to specify that we are writing actual data not a command.
	;arguments: R2 = data

	;TODO: PUSH ANY NEEDED REGISTERS
		PUSH{R0-R12,LR}


	;;;;;;;;;;;;;;;;;;;;;;;;;; SETTING RD to 1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TODO: SET RD HIGH (we won't need reading anyways, but we must keep read pin to high, which means we will not read anything)
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#0X0A
	ORR r3,r1
	str r3,[r0]
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	



	;;;;;;;;;;;;;;;;;;;; SETTING RS to 1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TODO: SET RS TO 1 (to specify that we are sending actual data not a command on the D0-7 bus)
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#0X0C
	ORR r3,r1
	str r3,[r0]
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	;TODO: CALL FUNCTION LCD_WRITE
	BL LCD_WRITE

	;TODO: POP ANY REGISTER YOU PUSHED
	POP{R0-R12,PC}
;#####################################################################################################################################################################




; REVISE WITH YOUR TA THE LAST 3 FUNCTIONS (LCD_WRITE, LCD_COMMAND_WRITE AND LCD_DATA_WRITE BEFORE PROCEEDING)




;#####################################################################################################################################################################
LCD_INIT
	;This function executes the minimum needed LCD initialization measures
	;Only the necessary Commands are covered
	;Eventho there are so many more in the DataSheet

	;TODO: PUSH ANY NEEDED REGISTERS
	PUSH{R0-R12,LR}

	;;;;;;;;;;;;;;;;; HARDWARE RESET (putting RST to high then low then high again) ;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;TODO: SET RESET PIN TO HIGH
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#8
	ORR r3,r1
	str r3,[r0]

	;TODO: DELAY FOR SOME TIME (USE ANY FUNCTION AT THE BOTTOM OF THIS FILE)
	BL delay_half_second

	;TODO: RESET RESET PIN TO LOW
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#8
    MVN R1,R1;          ONES COMPLEMENT OF R1 
	AND r3,r1
	str r3,[r0]

	;TODO: DELAY FOR SOME TIME (USE ANY FUNCTION AT THE BOTTOM OF THIS FILE)
	BL delay_half_second

	;TODO: SET RESET PIN TO HIGH AGAIN
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#8
	ORR r3,r1
	str r3,[r0]

	;TODO: DELAY FOR SOME TIME (USE ANY FUNCTION AT THE BOTTOM OF THIS FILE)
	BL delay_half_second
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;






	;;;;;;;;;;;;;;;;; PREPARATION FOR WRITE CYCLE SEQUENCE (setting CS to high, then configuring WR and RD, then resetting CS to low) ;;;;;;;;;;;;;;;;;;
	;TODO: SET CS PIN HIGH
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#15
	ORR r3,r1
	str r3,[r0]

	;TODO: SET WR PIN HIGH
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#11
	ORR r3,r1
	str r3,[r0]

	;TODO: SET RD PIN HIGH
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#10
	ORR r3,r1
	str r3,[r0]

	;TODO: SET CS PIN LOW
	ldr r0,=GPIOB_ODR
	ldr r3,[r0]
	ldr r1,=1
	lsl r1,#15
    MVN R1,R1;          ONES COMPLEMENT OF R1 
	AND r3,r1
	str r3,[r0]
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	




	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SOFTWARE INITIALIZATION SEQUENCE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;ISSUE THE "SET CONTRAST" COMMAND, ITS HEX CODE IS 0xC5
	MOV R2, #0xC5
	BL LCD_COMMAND_WRITE

	;THIS COMMAND REQUIRES 2 PARAMETERS TO BE SENT AS DATA, THE VCOM H, AND THE VCOM L
	;WE WANT TO SET VCOM H TO A SPECIFIC VOLTAGE WITH CORRESPONDS TO A BINARY CODE OF 1111111 OR 0x7F HEXA
	;SEND THE FIRST PARAMETER (THE VCOM H) NEEDED BY THE COMMAND, WITH HEX 0x7F, PARAMETERS ARE SENT AS DATA BUT COMMANDS ARE SENT AS COMMANDS
	MOV R2, #0x7F
	BL LCD_DATA_WRITE

	;WE WANT TO SET VCOM L TO A SPECIFIC VOLTAGE WITH CORRESPONDS TO A BINARY CODE OF 00000000 OR 0x00 HEXA
	;SEND THE SECOND PARAMETER (THE VCOM L) NEEDED BY THE CONTRAST COMMAND, WITH HEX 0x00, PARAMETERS ARE SENT AS DATA BUT COMMANDS ARE SENT AS COMMANDS
	MOV R2, #0x00
	BL LCD_DATA_WRITE


	;MEMORY ACCESS CONTROL AKA MADCLT | DATASHEET PAGE 127
	;WE WANT TO SET MX (to draw from left to right) AND SET MV (to configure the TFT to be in horizontal landscape mode, not a vertical screen)
	;TODO: ISSUE THE COMMAND MEMORY ACCESS CONTROL, HEXCODE 0x36
	mov R2,#0x36
	BL LCD_COMMAND_WRITE
	

	;TODO: SEND ONE NEEDED PARAMETER ONLY WITH MX AND MV SET TO 1. HOW WILL WE SEND PARAMETERS? AS DATA OR AS COMMAND?
    mov R2,#0x28
	BL LCD_DATA_WRITE


	;COLMOD: PIXEL FORMAT SET | DATASHEET PAGE 134
	;THIS COMMAND LETS US CHOOSE WHETHER WE WANT TO USE 16-BIT COLORS OR 18-BIT COLORS.
	;WE WILL ALWAYS USE 16-BIT COLORS
	;TODO: ISSUE THE COMMAND COLMOD
	mov R2,#0x3A
	BL LCD_COMMAND_WRITE

	;TODO: SEND THE NEEDED PARAMETER WHICH CORRESPONDS TO 16-BIT RGB AND 16-BIT MCU INTERFACE FORMAT
	mov R2,#0x55
	BL LCD_DATA_WRITE
	
	
	;SLEEP OUT | DATASHEET PAGE 101
	;TODO: ISSUE THE SLEEP OUT COMMAND TO EXIT SLEEP MODE (THIS COMMAND TAKES NO PARAMETERS, JUST SEND THE COMMAND)
	mov R2,#0x11
	BL LCD_COMMAND_WRITE

	;NECESSARY TO WAIT 5ms BEFORE SENDING NEXT COMMAND
	;I WILL WAIT FOR 10MSEC TO BE SURE
	;TODO: DELAY FOR AT LEAST 10ms
	BL delay_10_milli_second


	;DISPLAY ON | DATASHEET PAGE 109
	;TODO: ISSUE THE COMMAND, IT TAKES NO PARAMETERS
    mov R2,#0x29
	BL LCD_COMMAND_WRITE	


	;COLOR INVERSION OFF | DATASHEET PAGE 105
	;NOTE: SOME TFTs HAS COLOR INVERTED BY DEFAULT, SO YOU WOULD HAVE TO INVERT THE COLOR MANUALLY SO COLORS APPEAR NATURAL
	;MEANING THAT IF THE COLORS ARE INVERTED WHILE YOU ALREADY TURNED OFF INVERSION, YOU HAVE TO TURN ON INVERSION NOT TURN IT OFF.
	;TODO: ISSUE THE COMMAND, IT TAKES NO PARAMETERS
	mov R2,#0x20
	BL LCD_COMMAND_WRITE



	;MEMORY WRITE | DATASHEET PAGE 245
	;WE NEED TO PREPARE OUR TFT TO SEND PIXEL DATA, MEMORY WRITE SHOULD ALWAYS BE ISSUED BEFORE ANY PIXEL DATA SENT
	;TODO: ISSUE MEMORY WRITE COMMAND
	mov R2,#0x2C
	BL LCD_COMMAND_WRITE


	;TODO: POP ALL PUSHED REGISTERS
	
	POP{R0-R12,PC}
;#####################################################################################################################################################################


	B SKIP_THIS_LABEL
	LTORG
SKIP_THIS_LABEL



; REVISE THE FUNCTION LCD_INIT WITH YOUR TA BEFORE PROCEEDING






;#####################################################################################################################################################################
ADDRESS_SET
	;THIS FUNCTION TAKES X1, X2, Y1, Y2
	;IT ISSUES COLUMN ADDRESS SET TO SPECIFY THE START AND END COLUMNS (X1 AND X2)
	;IT ISSUES PAGE ADDRESS SET TO SPECIFY THE START AND END PAGE (Y1 AND Y2)
	;THIS FUNCTION JUST MARKS THE PLAYGROUND WHERE WE WILL ACTUALLY DRAW OUR PIXELS, MAYBE TARGETTING EACH PIXEL AS IT IS.
	;R0 = X1
	;R1 = X2
	;R3 = Y1
	;R4 = Y2

	;PUSHING ANY NEEDED REGISTERS
	PUSH {R0-R4, LR}
	

	;COLUMN ADDRESS SET | DATASHEET PAGE 110
	MOV R2, #0x2A
	BL LCD_COMMAND_WRITE

	;TODO: SEND THE FIRST PARAMETER (HIGHER 8-BITS OF THE STARTING COLUMN, AKA HIGHER 8-BITS OF X1)
	MOV R2,R0,LSR#8
	BL LCD_DATA_WRITE

	;TODO: SEND THE SECOND PARAMETER (LOWER 8-BITS OF THE STARTING COLUMN, AKA LOWER 8-BITS OF X1)
	MOV R2,R0
	BL LCD_DATA_WRITE


	;TODO: SEND THE THIRD PARAMETER (HIGHER 8-BITS OF THE ENDING COLUMN, AKA HIGHER 8-BITS OF X2)
	MOV R2,R1,LSR#8
	BL LCD_DATA_WRITE


	;TODO: SEND THE FOURTH PARAMETER (LOWER 8-BITS OF THE ENDING COLUMN, AKA LOWER 8-BITS OF X2)
	MOV R2,R1
	BL LCD_DATA_WRITE



	;PAGE ADDRESS SET | DATASHEET PAGE 110
	MOV R2, #0x2B
	BL LCD_COMMAND_WRITE

	;TODO: SEND THE FIRST PARAMETER (HIGHER 8-BITS OF THE STARTING PAGE, AKA HIGHER 8-BITS OF Y1)
	MOV R2,R3,LSL#8
	BL LCD_DATA_WRITE

	;TODO: SEND THE SECOND PARAMETER (LOWER 8-BITS OF THE STARTING PAGE, AKA LOWER 8-BITS OF Y1)
	MOV R2,R3
	BL LCD_DATA_WRITE


	;TODO: SEND THE THIRD PARAMETER (HIGHER 8-BITS OF THE ENDING PAGE, AKA HIGHER 8-BITS OF Y2)
	MOV R2,R4,LSL#8
	BL LCD_DATA_WRITE

	;TODO: SEND THE FOURTH PARAMETER (LOWER 8-BITS OF THE ENDING PAGE, AKA LOWER 8-BITS OF Y2)
	MOV R2,R4
	BL LCD_DATA_WRITE
	

	;MEMORY WRITE
	MOV R2, #0x2C
	BL LCD_COMMAND_WRITE


	;POPPING ALL REGISTERS I PUSHED
	POP {R0-R4, PC}
;#####################################################################################################################################################################



;#####################################################################################################################################################################
DRAWPIXEL
	PUSH {R0-R4, r10, LR}
	;THIS FUNCTION TAKES X AND Y AND A COLOR AND DRAWS THIS EXACT PIXEL
	;NOTE YOU HAVE TO CALL ADDRESS SET ON A SPECIFIC PIXEL WITH LENGTH 1 AND WIDTH 1 FROM THE STARTING COORDINATES OF THE PIXEL, THOSE STARTING COORDINATES ARE GIVEN AS PARAMETERS
	;THEN YOU SIMPLY ISSUE MEMORY WRITE COMMAND AND SEND THE COLOR
	;R0 = X
	;R1 = Y
	;R10 = COLOR

	;CHIP SELECT ACTIVE, WRITE LOW TO CS
	LDR r3, =GPIOB_ODR
	LDR r4, [r3]
	AND r4, r4, #0xFFFF7FFF
	STR r4, [r3]

	;TODO: SETTING PARAMETERS FOR FUNC 'ADDRESS_SET' CALL, THEN CALL FUNCTION ADDRESS SET
	;NOTE YOU MIGHT WANT TO PERFORM PARAMETER REORDERING, AS ADDRESS SET FUNCTION TAKES X1, X2, Y1, Y2 IN R0, R1, R3, R4 BUT THIS FUNCTION TAKES X,Y IN R0 AND R1
	
	;R0 = X1
	;R1 = X2
	;R3 = Y1
	;R4 = Y2
	
	mov r5,r1
    add r1,r0,#1 ;R0=X1, R1=R0+1
	MOV R3,R5
	add R4,R3,#1 ;R3=Y1,R4=Y1+1
	
	BL ADDRESS_SET
	


	
	;MEMORY WRITE
	MOV R2, #0x2C
	BL LCD_COMMAND_WRITE


	;SEND THE COLOR DATA | DATASHEET PAGE 114
	;HINT: WE SEND THE HIGHER 8-BITS OF THE COLOR FIRST, THEN THE LOWER 8-BITS
	;HINT: WE SEND THE COLOR OF ONLY 1 PIXEL BY 2 DATA WRITES, THE FIRST TO SEND THE HIGHER 8-BITS OF THE COLOR, THE SECOND TO SEND THE LOWER 8-BITS OF THE COLOR
	;REMINDER: WE USE 16-BIT PER PIXEL COLOR
	;TODO: SEND THE SINGLE COLOR, PASSED IN R10
	  
	MOV R2,R10,LSR #8 ;SENDING HEIGHER 8 BITS
    BL LCD_DATA_WRITE
	
	MOV R2,R10        ;SENDING LOWER  8 BITS
	BL LCD_DATA_WRITE
	
	
	POP {R0-R4, r10, PC}
;#####################################################################################################################################################################


;	REVISE THE PREVIOUS TWO FUNCTIONS (ADDRESS_SET AND DRAW_PIXEL) WITH YOUR TA BEFORE PROCEEDING








;##########################################################################################################################################
DRAW_RECTANGLE_FILLED
	;TODO: IMPLEMENT THIS FUNCTION ENTIRELY, AND SPECIFY THE ARGUMENTS IN COMMENTS, WE DRAW A RECTANGLE BY SPECIFYING ITS TOP-LEFT AND LOWER-RIGHT POINTS, THEN FILL IT WITH THE SAME COLOR
	;X1 = [] r0
	;Y1 = [] r1
	;X2 = [] r3
	;Y2 = [] r4
	;COLOR = [] r10
	 PUSH {R0-R4, r10, LR}
	 
		MOV R6,R0
	
INNER_RECT_FILLED1

		BL DRAWPIXEL
		ADD R0,R0,#1
		CMP R0,R3
		
		BLT INNER_RECT_FILLED1
		
		MOV R0,R6
		ADD R1,R1,#1
		CMP R1,R4
		BLT INNER_RECT_FILLED1
		



	POP {R0-R4, r10, PC}

DRAW_triangle  
	;TODO: IMPLEMENT THIS FUNCTION ENTIRELY, AND SPECIFY THE ARGUMENTS IN COMMENTS, WE DRAW A TRIANGLE  BY SPECIFYING ITS TOP AND LOWER POINTS, THEN FILL IT WITH THE SAME COLOR
	;X1 = [] r0
	;Y1 = [] r1
	;X2 = [] r3
	;Y2 = [] r4
	;COLOR = [] r10
	PUSH {R0-R4, r10, LR}
	
	MOV R7, R1
	
INNER_TRIANGLE_FILLED_1
	
	  BL DRAWPIXEL
	  
	  ADD R1, R1 ,#1
	  CMP R1, R4
	  BLT INNER_TRIANGLE_FILLED_1
 
	  ADD R7,#1


	
	  ADD R0, R0 , #1
	  MOV R1, R7
	  SUB R4, #1
	  BL DRAWPIXEL
	  
	  CMP R1, R4
	  
	  BLT INNER_TRIANGLE_FILLED_1
	 
	  
	  
	  
	




	POP {R0-R4, r10, PC}
;##########################################################################################################################################













;#####################################################################################################################################################################
SETUP
	;THIS FUNCTION ENABLES PORT E, MARKS IT AS OUTPUT, CONFIGURES SOME GPIO
	;THEN FINALLY IT CALLS LCD_INIT (HINT, USE THIS SETUP FUNCTION DIRECTLY IN THE MAIN)
	PUSH {R0-R12, LR}

	;Make the clock affect port B by enabling the corresponding bit (the third bit) in RCC_AHB1ENR register
	LDR R0, =RCC_APB2ENR         ; Address of RCC_APB2ENR register
    LDR R1, [R0]                 ; Read the current value of RCC_APB2ENR
	MOV R2, #3
    ORR R1, R1, R2, LSL #2        ; Set bit 2 and 3 to enable GPIOA&B clock
    STR R1, [R0]                 ; Write the updated value back to RCC_APB2ENR
	
	
	;Make the GPIOA PINS 0->7 mode as output (0001 for each pin)
	LDR r0, =GPIOA_CRL
	mov r1, #0x11111111
	STR r1, [r0]
	;Make the GPIOA PINS 0->7 mode as OUTput (0001 for each pin)
	LDR r0, =GPIOB_CRL
	mov r1, #0x11111111
	STR r1, [r0]
	
	;Make the GPIOB PINS 8->15 mode as output (0001 for each pin)
	LDR r0, =GPIOB_CRH
	mov r1, #0x11111111
	STR r1, [r0]
	
	

	BL LCD_INIT

	POP {R0-R12, PC}
;#####################################################################################################################################################################






; HELPER DELAYS IN THE SYSTEM, YOU CAN USE THEM DIRECTLY


;##########################################################################################################################################
delay_1_second
	;this function just delays for 1 second
	PUSH {R8, LR}
	LDR r8, =INTERVAL
delay_loop
	SUBS r8, #1
	CMP r8, #0
	BGE delay_loop
	POP {R8, PC}
;##########################################################################################################################################




;##########################################################################################################################################
delay_half_second
	;this function just delays for half a second
	PUSH {R8, LR}
	LDR r8, =INTERVAL
delay_loop1
	SUBS r8, #2
	CMP r8, #0
	BGE delay_loop1

	POP {R8, PC}
;##########################################################################################################################################


;##########################################################################################################################################
delay_milli_second
	;this function just delays for a millisecond
	PUSH {R8, LR}
	LDR r8, =INTERVAL
delay_loop2
	SUBS r8, #1000
	CMP r8, #0
	BGE delay_loop2

	POP {R8, PC}
;##########################################################################################################################################



;##########################################################################################################################################
delay_10_milli_second
	;this function just delays for 10 millisecondS
	PUSH {R8, LR}
	LDR r8, =INTERVAL
delay_loop3
	SUBS r8, #100
	CMP r8, #0
	BGE delay_loop3

	POP {R8, PC}
;##########################################################################################################################################



Draw_ship_1
	PUSH {R0-R12, LR}
     
;	MOV R0, #5
;	MOV R1, #36
;	MOV R3, #205
;	MOV R4, #236
;	BL ADDRESS_SET
 
    ;LDR R5,=ship
	MOV R7,#1000

	MOV R2, #0x2C
	BL LCD_COMMAND_WRITE

IMAGE_LOOP

	LDR R6, [R5], #2


	MOV R2, R6
	LSR R2, #8
	BL LCD_DATA_WRITE
	MOV R2, R6
	BL LCD_DATA_WRITE

	SUBS R7, R7, #1
	CMP R7, #0
	BNE IMAGE_LOOP


	POP {R0-R12, PC}

Draw_ship_2
	PUSH {R0-R12, LR}
     
	MOV R0, #5
	MOV R1, #76
	MOV R3, #10
	MOV R4, #68
	BL ADDRESS_SET
 
   ; LDR R5,=enemy
	MOV R7,#4000

	MOV R2, #0x2C
	BL LCD_COMMAND_WRITE

IMAGE_LOOP1

	LDR R6, [R5], #2


	MOV R2, R6
	LSR R2, #8
	BL LCD_DATA_WRITE
	MOV R2, R6
	BL LCD_DATA_WRITE

	SUBS R7, R7, #1
	CMP R7, #0
	BNE IMAGE_LOOP1


	POP {R0-R12, PC}
	END
		