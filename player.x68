*-----------------------------------------------------------
* Program Number: player
* Written by    : Michael Hamm
* Date Created  : 10/20/2022
* Description   : This file contains couroutines that
* act on a player object.
*-----------------------------------------------------------

; Snake Part Struct
SNAKE_PART_X EQU 0*4
SNAKE_PART_Y EQU 1*4
PREVIOUS_PART EQU 2*4
NEXT_PART EQU 3*4
SNAKE_PART_STRUCT_SIZE EQU 4

; Player Struct
PLAYER_X_POS EQU 0*4
PLAYER_Y_POS EQU 1*4
PLAYER_X_INPUT EQU 2*4
PLAYER_Y_INPUT EQU 3*4
PLAYER_X_DIRECTION EQU 4*4
PLAYER_Y_DIRECTION EQU 5*4
PLAYER_COLOR EQU 6*4
PLAYER_HEAD EQU 7*4
PLAYER_TAIL EQU 8*4
PLAYER_SCORE EQU 9*4
PLAYER_ATE_FOOD EQU 10*4
PLAYER_SCORE_X EQU 11*4
PLAYER_SCORE_Y EQU 12*4
PLAYER_STRUCT_SIZE EQU 13 

**
* GetPlayerMove
* Gets the players input and sets the move direction based on input
* @param a0: pointer to the player object
* @param a2: player input
GetPlayerMove
        clr.l   PLAYER_X_INPUT(a0)
        clr.l   PLAYER_Y_INPUT(a0)
        
        ; Store x and y direction computation in registers because we may need to throw them out
        ; if they equal the reverse direction of the player
        ; d2 x direction
        ; d3 y direciton
        move.l  PLAYER_X_DIRECTION(a0),d2
        move.l  PLAYER_Y_DIRECTION(a0),d3
        
        ; Computes the reverse direction of player
        ; d4 reverse x
        ; d5 reverse y
        move.l  PLAYER_X_DIRECTION(a0),d4
        muls.w  #-1,d4
        move.l  PLAYER_Y_DIRECTION(a0),d5
        muls.w  #-1,d5

        move.l  #GET_KEY_INPUT_COMMAND,d0
        move.l  (a1),d1
        trap    #15
        
        ; Check if left pressed 
        btst.l  #24,d1
        beq     If_Left_End
        subi.l  #1,PLAYER_X_INPUT(a0)
If_Left_End
        
        ; Check if right pressed 
        btst.l  #16,d1
        beq     If_Right_End
        addi.l  #1,PLAYER_X_INPUT(a0)
If_Right_End
        
        ; Check if down pressed 
        btst.l  #8,d1
        beq     If_Down_End
        subi.l  #1,PLAYER_Y_INPUT(a0)
If_Down_End
        
        ; Check if up pressed 
        btst.l  #0,d1
        beq     If_Up_End
        addi.l  #1,PLAYER_Y_INPUT(a0)
If_Up_End

        ; Calculate direction from input        
        cmp.l   #0,PLAYER_X_INPUT(a0)
        beq     X_Direciton_Update_End
        clr.l   d3  
        move.l  PLAYER_X_INPUT(a0),d2    
X_Direciton_Update_End

        cmp.l   #0,PLAYER_Y_INPUT(a0)
        beq     Y_Direciton_Update_End
        clr.l   d2  
        move.l  PLAYER_Y_INPUT(a0),d3   
Y_Direciton_Update_End

        ; Prevent player from moving backwards into themselves
        
        cmp.l   d2,d4
        bne.l   UpdateMoveDirection
        cmp.l   d3,d5
        beq.l   DontUpdateMoveDirection
                
UpdateMoveDirection
        move.l  d2,PLAYER_X_DIRECTION(a0)
        move.l  d3,PLAYER_Y_DIRECTION(a0)

DontUpdateMoveDirection

        rts

**
* MovePlayers
* Moves the players on the board in their move directions.
* Calculates collisions with other players, food, and grows and shrinks the body of players
MovePlayers
        
        ; Remove tails of players
        lea     Player1,a0
        jsr     RemoveTail
        lea     Player2,a0
        jsr     RemoveTail
        
        ; Add head of players
        lea     Player1,a0
        jsr     AddHead
        
        lea     Loser,a6
        cmp.l   #0,(a6) 
        bne.l   MovePlayersEnd
        
        lea     Player2,a0
        jsr     AddHead
        
MovePlayersEnd
        
        rts

**
* UndrawTail
* Removes the tail from a player in memory and physically undraws it from the
* board
* @param a0: player
UndrawTail

        ; Remove the tail from the linked list
        move.l  PLAYER_TAIL(a0),a1
        ; x
        move.l  SNAKE_PART_X(a1),d1
        muls.w  #CELL_SIZE,d1
        add.l   #STARTING_TILES_X,d1
        ; y
        move.l  SNAKE_PART_Y(a1),d2
        muls.w  #CELL_SIZE,d2
        add.l   #STARTING_TILES_Y,d2
        ; width
        move.l  #CELL_SIZE+1,d3
        ; height
        move.l  #CELL_SIZE+1,d4
       
        ; Redraw the background 
        jsr RedrawBackground

        rts
    
**
* GetNextPos
* Calculates the players next position based off their move direction
* Calculations stored in the player object's members
* @param a0: player
GetNextPos

        ; Update position
        move.l  PLAYER_X_DIRECTION(a0),d0
        add.l   d0,PLAYER_X_POS(a0)
        move.l  PLAYER_Y_DIRECTION(a0),d0
        sub.l   d0,PLAYER_Y_POS(a0)

        cmp.l   #0,PLAYER_X_POS(a0)
        bge.l   Wrap_Left_End
        move.l  #NUM_TILES_WIDTH-1,PLAYER_X_POS(a0)
Wrap_Left_End
        cmp.l   #NUM_TILES_WIDTH,PLAYER_X_POS(a0)
        blt.l   Wrap_Right_End
        move.l  #0,PLAYER_X_POS(a0)
Wrap_Right_End

        cmp.l   #0,PLAYER_Y_POS(a0)
        bge.l   Wrap_Bottom_End
        move.l  #NUM_TILES_HEIGHT-1,PLAYER_Y_POS(a0)
Wrap_Bottom_End
        cmp.l   #NUM_TILES_HEIGHT,PLAYER_Y_POS(a0)
        blt.l   Wrap_Top_End
        move.l  #0,PLAYER_Y_POS(a0)
Wrap_Top_End
        
        rts

**
* DrawPlayer
* Draws the head of the player on the board
* @param a0: player     
DrawPlayer        
        move.l  PLAYER_COLOR(a0),d1
        move.b  #SET_PEN_COLOR_COMMAND,d0
        trap	#15
	move.b	#SET_FILL_COLOR_COMMAND,d0
	trap	#15

        move.l  PLAYER_HEAD(a0),a1

        move.b	#DRAW_RECT_COMMAND,d0
	move.l	SNAKE_PART_X(a1),d1 ; Left x
	muls.w  #CELL_SIZE,d1
	add.l   #STARTING_TILES_X,d1
	move.l	SNAKE_PART_Y(a1),d2 ; Upper y
	muls.w  #CELL_SIZE,d2
	add.l   #STARTING_TILES_Y,d2
	move.l	d1,d3 ; Right x
        addi.l  #CELL_SIZE,d3
	move.l  d2,d4 ; Bottom y
        addi.l  #CELL_SIZE,d4	
	trap	#15

        rts
 
**
* AddHead
* Adds head on the body of the snake and draws it to the board.
* If adding a head causing a collision to occur, it is processed in this function.
* @param a0: player       
AddHead
        jsr     GetNextPos

        ; Create new node
        jsr     NewNextSnakePart
        move.l  PLAYER_X_POS(a0),SNAKE_PART_X(a1)
        move.l  PLAYER_Y_POS(a0),SNAKE_PART_Y(a1)
        clr.l   PREVIOUS_PART(a1)
        move.l  PLAYER_HEAD(a0),NEXT_PART(a1)
        
        ; Set old head's previous to new node  
        move.l  PLAYER_HEAD(a0),a2
        beq.l   SetOldHeadPrevious
        move.l  a1,PREVIOUS_PART(a2)
        
SetOldHeadPrevious
        
        ; Set player head to new node
        move.l  a1,PLAYER_HEAD(a0)
        
        cmp.l   #0,PLAYER_TAIL(a0)
        bne.l   SetTailIfNull
        move.l  PLAYER_HEAD(a0),PLAYER_TAIL(a0)
SetTailIfNull

        jsr     DrawPlayer
       
        ; Get player collided with
        jsr     GetPlayerPlayerCollidedWith
        ; If player collided with another player set the Loser variable and return
        cmp.l   #0,a6
        beq.l   PlayerWithPlayerCollisionEnd
        move.l  a0,Loser
PlayerWithPlayerCollisionEnd

        ; If player collided with food grow the player
        jsr     GetFoodPlayerCollidedWith
        cmp.l   #0,d7
        beq.l   PlayerWithFoodCollisionEnd
        move.l  #1,PLAYER_ATE_FOOD(a0)
        add.l   #1,PLAYER_SCORE(a0)
        jsr     DrawScore
        jsr     SpawnFood
        ; Remove food from tiles
        move.l  PLAYER_X_POS(a0),d0
        move.l  PLAYER_Y_POS(a0),d1
        jsr     ClearCollisionMapIndex

PlayerWithFoodCollisionEnd
       
        ; Add head to collision map
        move.l  SNAKE_PART_X(a1),d0
        move.l  SNAKE_PART_Y(a1),d1
        jsr     SetCollisionMapIndexPlayer
AddHeadToCollisionMapEnd
       
        rts

**
* RemoveTail
* Removes the tail from the player's linked list and undraws it from the screen
* If a player previously ate last move, then the tail is not removed.
* @param a0: player
RemoveTail
        
        ; Do not remove the tail if last tick they ate food
        cmp.l   #1,PLAYER_ATE_FOOD(a0)
        bne     RemoteTailNormalPath
        clr.l   PLAYER_ATE_FOOD(a0)
        bra.l   RemoveTailEnd
RemoteTailNormalPath
        
        jsr     UndrawTail
        
        ; a1 tail part
        ; a2 tail-1 part
        move.l  PLAYER_TAIL(a0),a1
        move.l  PREVIOUS_PART(a1),a2
        beq.l   SetTailMinus1Next
        clr.l   NEXT_PART(a2)
SetTailMinus1Next
        move.l  a2,PLAYER_TAIL(a0)
        bne.l   SetHeadNullIfTailEqHead
        clr.l   PLAYER_HEAD(a0)
SetHeadNullIfTailEqHead

        move.l  SNAKE_PART_X(a1),d0
        move.l  SNAKE_PART_Y(a1),d1
        jsr     ClearCollisionMapIndex
        
RemoveTailEnd        
        
        rts

**
*
*
DrawScore
        move.l  PLAYER_SCORE(a0),d0
      	move.l  PLAYER_SCORE_X(a0),d1
      	move.l  PLAYER_SCORE_Y(a0),d2
      	jsr     DrawNumber
        rts

**
* Creates a new snake part object in memory
* @param a0: player
* @return a1. ptr to new snake part object
NewNextSnakePart
        lea     NextAvailableSnakePart,a2
        move.l  (a2),a1
        addi.l  #SNAKE_PART_STRUCT_SIZE*BYTES_IN_LONG,(a2)
        cmp.l   #SnakeParts+NUM_TILES_WIDTH*NUM_TILES_HEIGHT*SNAKE_PART_STRUCT_SIZE*BYTES_IN_LONG,(a2)
        bne.l   NextSnakePartWrapAround_End
        move.l  #SnakeParts,(a2)
NextSnakePartWrapAround_End

        rts        

SnakeParts ds.l NUM_TILES_WIDTH*NUM_TILES_HEIGHT*SNAKE_PART_STRUCT_SIZE
NextAvailableSnakePart dc.l SnakeParts+0       

















        








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
