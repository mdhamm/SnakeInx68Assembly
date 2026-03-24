*-----------------------------------------------------------
* Program Number: sevenseg
* Written by    : Michael Hamm
* Date Created  : 10/20/2022
* Description   : Draws a seven segement led onto the screen
*-----------------------------------------------------------

SEGMENT_LONG_SIZE EQU 15
SEGMENT_SHORT_SIZE EQU 5
DIGIT_SPACING EQU 10
NUM_SEGEMENTS EQU 7
DIGIT_COLOR EQU $00FFFFFF

SEGEMENT_X      EQU 0*BYTES_IN_LONG
SEGEMENT_Y      EQU 1*BYTES_IN_LONG
SEGEMENT_WIDTH  EQU 2*BYTES_IN_LONG
SEGEMENT_HEIGHT  EQU 3*BYTES_IN_LONG
SEGMENT_COORD_ELEMENT_SIZE EQU 4 

DRAW_DIGIT_LOCAL_X EQU 0*BYTES_IN_LONG
DRAW_DIGIT_LOCAL_Y EQU 1*BYTES_IN_LONG
DRAW_DIGIT_LOCAL_DIGIT EQU 2*BYTES_IN_LONG
DRAW_DIGIT_LOCAL_SIZE   EQU 3*BYTES_IN_LONG


**
* DrawNumber
* Draws a number at the x,y
* @param d0: number
* @param d1: x
* @param d2: y
DrawNumber
        movem.l ALL_REG,-(sp)
 
        move.l  d0,d3
        
DrawNumberLoop
        ; d3 running number
        ; d6 remainder
        divs    #10,d3
        move.l  d3,d6
        andi.l  #$0000FFFF,d3
        clr.w   d6
        swap    d6

        ; Draw single digit
        move.l  d6,d0
        jsr     DrawDigit 
 
        ; Keep drawing digits until no more
        ; Add offset next digits x and y
        subi.l  #SEGMENT_LONG_SIZE,d1
        subi.l  #DIGIT_SPACING,d1

        cmp.l   #0,d3
        bne.l   DrawNumberLoop     
        
        movem.l (sp)+,ALL_REG
        rts
        
**
* DrawDigit
* Draws a single digit at the x,y
* @param d0: digit 0-9
* @param d1: x
* @param d2: y        
DrawDigit

        movem.l ALL_REG,-(sp)
        
        move.l  #SEGMENT_LONG_SIZE+1,d3
        move.l  #SEGMENT_LONG_SIZE*2+1,d4
        jsr     RedrawBackground
        
        ; Add local variables to the stack
        move.l  d0,-(sp) ; digit
        move.l  d2,-(sp) ; y
        move.l  d1,-(sp) ; x
        
        ; Gets segements of number. store in d5
        lea     SEGEMENTS,a0
        muls.w  #BYTES_IN_LONG,d0
        add.l   d0,a0
        move.l  (a0),d5
        
        ; Get segement info array
        lea     SEGMENTCOORDS,a1
        
        ; Set Color
        move.l  #DIGIT_COLOR,d1
        move.b  #SET_PEN_COLOR_COMMAND,d0
        trap	#15
	move.b	#SET_FILL_COLOR_COMMAND,d0
	trap	#15
        
        ; d6 = which segement is being drawn. counter from 0 to 7
        clr.l   d6
        
DrawNextSegment
        
        btst.l  #0,d5
        beq.l   DrawSegementEnd
        
	; Draw segement
        move.l  SEGEMENT_X(a1),d1 ; Left x
        add.l   DRAW_DIGIT_LOCAL_X(sp),d1 ; Add global x
        move.l  SEGEMENT_Y(a1),d2 ; Upper y
        add.l   DRAW_DIGIT_LOCAL_Y(sp),d2 ; Add global y
        move.l  d1,d3 ; Right x
        add.l   SEGEMENT_WIDTH(a1),d3 ; Add width
        move.l  d2,d4 ; Bottom y
        add.l   SEGEMENT_HEIGHT(a1),d4 ; Add height
        
        move.b	#DRAW_RECT_COMMAND,d0   
        trap	#15
        
DrawSegementEnd

        lsr.l   #1,d5
        addi.l  #1,d6
        add.l   #SEGMENT_COORD_ELEMENT_SIZE*BYTES_IN_LONG,a1
        
        cmp.l   #NUM_SEGEMENTS,d6
        blt.l   DrawNextSegment
        
        
        ; Pop off local variables
        add.l   #DRAW_DIGIT_LOCAL_SIZE,sp
        
        movem.l (sp)+,ALL_REG
        rts

SEGEMENTS
        dc.l    $7E ;0
        dc.l    $30 ;1
        dc.l    $6D ;2
        dc.l    $79 ;3
        dc.l    $33 ;4
        dc.l    $5B ;5
        dc.l    $5F ;6
        dc.l    $70 ;7
        dc.l    $7F ;8
        dc.l    $7B ;9
        
SEGMENTCOORDS ; rel x, rel y, width, height
        dc.l    0,                                      SEGMENT_LONG_SIZE-SEGMENT_SHORT_SIZE/2,       SEGMENT_LONG_SIZE,      SEGMENT_SHORT_SIZE ; G
        dc.l    0,                                      0,                                            SEGMENT_SHORT_SIZE,     SEGMENT_LONG_SIZE ; F
        dc.l    0,                                      SEGMENT_LONG_SIZE,                            SEGMENT_SHORT_SIZE,     SEGMENT_LONG_SIZE ; E
        dc.l    0,                                      SEGMENT_LONG_SIZE*2-SEGMENT_SHORT_SIZE,       SEGMENT_LONG_SIZE,      SEGMENT_SHORT_SIZE ; D
        dc.l    SEGMENT_LONG_SIZE-SEGMENT_SHORT_SIZE,   SEGMENT_LONG_SIZE,                            SEGMENT_SHORT_SIZE,     SEGMENT_LONG_SIZE ; C
        dc.l    SEGMENT_LONG_SIZE-SEGMENT_SHORT_SIZE,   0,                                            SEGMENT_SHORT_SIZE,     SEGMENT_LONG_SIZE ; B
        dc.l    0,                                      0,                                            SEGMENT_LONG_SIZE,      SEGMENT_SHORT_SIZE ; A
   




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
