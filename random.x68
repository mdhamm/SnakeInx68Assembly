*-----------------------------------------------------------
* Program Number: random
* Written by    : Michael Hamm
* Date Created  : 10/20/2022
* Description   : Contains functions for computing random numbers
*
*-----------------------------------------------------------

GET_TIME_COMMAND        equ     8

; Dummy variable so that seedRandomNumber is byte aligned 
DUMMY ds.l 0

seedRandomNumber
        movem.l ALL_REG,-(sp)           ;; What does this do?
        clr.l   d6
        move.b  #GET_TIME_COMMAND,d0    ;; What if you used the same seed?
        TRAP    #15

        move.l  d1,RANDOMVAL
        movem.l (sp)+,ALL_REG
        rts

getRandomByteIntoD6
        movem.l d0,-(sp)
        movem.l d1,-(sp)
        movem.l d2,-(sp)
        move.l  RANDOMVAL,d0
       	moveq	#$AF-$100,d1
       	moveq	#18,d2
Ninc0	
	add.l	d0,d0
	bcc	Ninc1
	eor.b	d1,d0
Ninc1
	dbf	d2,Ninc0
	
	move.l	d0,RANDOMVAL
	clr.l	d6
	move.b	d0,d6
	
        movem.l (sp)+,d2
        movem.l (sp)+,d1
        movem.l (sp)+,d0
        rts
        

getRandomLongIntoD6
        movem.l ALL_REG,-(sp)
        jsr     getRandomByteIntoD6
        move.b  d6,d5
        jsr     getRandomByteIntoD6
        lsl.l   #8,d5
        move.b  d6,d5
        jsr     getRandomByteIntoD6
        lsl.l   #8,d5
        move.b  d6,d5
        jsr     getRandomByteIntoD6
        lsl.l   #8,d5
        move.b  d6,d5
        move.l  d5,TEMPRANDOMLONG
        movem.l (sp)+,ALL_REG
        move.l  TEMPRANDOMLONG,d6
        rts

**
* getRandomLongIntoD6Between
* Gets a random integer between a lower and upper bound.
* @param d0: lower bound
* @param d1: upper bound
* @return d6: random integer
getRandomLongIntoD6Between
       movem.l  ALL_REG,-(sp)
       sub.l    d0,d1
       jsr      getRandomLongIntoD6
       andi.l   #$0000FFFF,d6
       divs     d1,d6
       clr.w    d6
       swap     d6
       add.l    d0,d6
       move.l   d6,TEMPRANDOMLONG
       movem.l  (sp)+,ALL_REG
       move.l   TEMPRANDOMLONG,d6
       rts


RANDOMVAL       ds.l    1
TEMPRANDOMLONG  ds.l    1













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
