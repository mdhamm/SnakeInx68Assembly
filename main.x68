*-----------------------------------------------------------
* Program Number: main
* Written by    : Michael Hamm
* Date Created  : 10/20/2022
* Description   : This is the main program file. It executes
* the main game loop and plays the two player snake game.
*-----------------------------------------------------------    
 
ALL_REG_MINUS_RETURN            REG     D0-D6/A0-A7
ALL_REG                         REG     D0-D7/A0-A6

; Trap codes
CLEAR_SCREEN_COMMAND            EQU     11
CLEAR_SCREEN_MAGIC_VAL          EQU     $FF00
DRAWING_MODE_TRAP_CODE	        EQU	92
DOUBLE_BUFFERED_MODE	        EQU	17
DELAY_FRAME                     EQU	23
REPAINT_SCREEN_TRAP_CODE	EQU	94
GET_KEY_INPUT_COMMAND           EQU 19
DRAW_RECT_COMMAND               EQU 87
SET_PEN_COLOR_COMMAND           EQU 80
SET_FILL_COLOR_COMMAND          EQU 81
LOAD_WAV                        EQU 71
PLAY_SOUND                      EQU 76

FRAME_DELAY_TIME        EQU     10

; Constants
STARTING_MOVE_SPEED EQU 15
LOOP_SOUND EQU 1

DISPLAY_WIDTH    EQU 800
DISPLAY_HEIGHT   EQU 800
CELL_SIZE EQU 43
P1_COLOR EQU $000000FF
P2_COLOR EQU $00FF0000
P1_SCORE_X EQU 200
P1_SCORE_Y EQU 50
P2_SCORE_X EQU DISPLAY_WIDTH-P1_SCORE_X 
P2_SCORE_Y EQU P1_SCORE_Y
BYTES_IN_LONG   EQU 4
      
POSITION_FRAC_8 EQU 8 ; Frac bits for movement
POSITION_FRAC_1 EQU 1

NUM_TILES_WIDTH EQU 17
NUM_TILES_HEIGHT EQU 15
STARTING_TILES_X EQU 34
STARTING_TILES_Y EQU 127

P1_STARTING_X EQU 1
P1_STARTING_Y EQU 9

P2_STARTING_X EQU NUM_TILES_WIDTH-P1_STARTING_X-1
P2_STARTING_Y EQU P1_STARTING_Y

P1_STARTING_X_DIRECTION EQU 0
P1_STARTING_Y_DIRECTION EQU 1

P2_STARTING_X_DIRECTION EQU P1_STARTING_X_DIRECTION
P2_STARTING_Y_DIRECTION EQU P1_STARTING_Y_DIRECTION

ACCELERATION EQU 1

; Player win screen dimensions
PLAYER_WIN_WIDTH EQU 275
PLAYER_WIN_HEIGHT EQU 143

; Game states
MAIN_MENU_STATE EQU 0
MAIN_GAME_STATE EQU 1
WIN_SCREEN_STATE EQU 2

; Tile Struct
TILE_X EQU 0*4
TILE_Y EQU 1*4
TILE_STRUCT_SIZE EQU 2

; Local variable offsets
MOVE_SPEED EQU 0

START   ORG     $1000        

        ; Set display resolution
        move.b  #SET_OUTPUT_RESOLUTION_TRAP_CODE,d0
        move.l  #DISPLAY_WIDTH,d1
        swap    d1
        move.w  #DISPLAY_HEIGHT,d1
        TRAP    #15

        ; Set double buffered        
        move.b	#DRAWING_MODE_TRAP_CODE,d0
      	move.b	#DOUBLE_BUFFERED_MODE,d1
      	trap	#15
      	
      	; Get random seed
      	jsr     seedRandomNumber
        
GameLoop

        cmpi.l  #MAIN_MENU_STATE,GameState
        bne.l   MainMenuEnd
MainMenuState
        
MainMenuEnd

        cmpi.l  #MAIN_GAME_STATE,GameState
        bne.l   MainGameEnd
MainGameStart    
        ; Draw full background
      	jsr     DrawFullBackground
      	
      	; Play music
        jsr     PlayMusic
      	
      	; Initialize player struct
        jsr     CreatePlayer1
        jsr     CreatePlayer2
        
        jsr     SpawnFood
        jsr     SpawnFood
        
        jsr     SwapBuffers
MainGameLoop

        ; Get player 1 input
        lea     Player1,a0
        lea     Player1Input,a1
        jsr     GetPlayerMove
        ; Get player 2 input
        lea     Player2,a0
        lea     Player2Input,a1
        jsr     GetPlayerMove
        
        jsr     CheckResetButtonPressed
        
        ; Increase timer. a0 address to move speed. d0 integer move speed
        lea     MoveSpeed,a0
        move.l  (a0),d0
        
        ; a1 = move timer. Increase by move speed integer
        lea     MoveTimer,a1
        add.l   d0,(a1) ; Add move speed to position timer
        
        ; Move player if position > 1
        move.l  (a1),d1
        lsr.l   #POSITION_FRAC_8,d1 ; Convert position to fractional
        lsr.l   #POSITION_FRAC_8,d1
        lsr.    #POSITION_FRAC_1,d1
        lsr.l   #2,d1
        cmpi.l  #1,d1 ; Compare fractional pos  to 1
        blt.l   MoveEnd
        
        clr.l   (a1)
        add.l   #ACCELERATION,MoveSpeed ; Increase velocity over time  

        jsr     MovePlayers
        
        jsr     SwapBuffers
        
        cmp.l   #0,Loser
        beq.l   LoserCheckEnd   
        
        ; Change game state to win screen
        lea     GameState,a0
        move.l  #WIN_SCREEN_STATE,(a0)
        jsr     DrawWinner
        jsr     SwapBuffers
        bra.l   MainGameLoopEnd

LoserCheckEnd
        
MoveEnd
        
        bra.l   MainGameLoop
MainGameLoopEnd


MainGameEnd

        cmpi.l  #WIN_SCREEN_STATE,GameState
        bne.l   WinScreenEnd
WinScreenStart
        
        jsr     CheckResetButtonPressed
        
WinScreenEnd

        bra     GameLoop
        
DrawFullBackground
        lea Background, a0
        
        ; Save off all registers
        movem.l ALL_REG_MINUS_RETURN,-(sp)
        ; Pass in paramaters to function. Load in backwards
        move.l #0,-(sp) ; Output y
        move.l #0,-(sp) ; Output x
        move.l #DISPLAY_HEIGHT,-(sp) ; Height
        move.l #DISPLAY_WIDTH,-(sp) ; Width
        move.l #0,-(sp) ; Source y
        move.l #0,-(sp) ; Source x
        move.l a0,-(sp) ; Bmp address

        ; Run function
        jsr DisplayBitMap
        ; Fix the stack
        add.l #DBM_PARAMS_SIZE,sp
        ; Restore all registers
        movem.l (sp)+,ALL_REG_MINUS_RETURN
        
        rts

**
* CreatePlayer1
* This function is called to create the first player and put it onto the game board.
* This functions fills out the memory for Player1. Initializes the struct
* with starting position, color, size, etc.
CreatePlayer1
        lea     Player1,a0
        move.l  #P1_SCORE_X,PLAYER_SCORE_X(a0)
        move.l  #P1_SCORE_Y,PLAYER_SCORE_Y(a0)
        move.l  #P1_STARTING_X,PLAYER_X_POS(a0)
        move.l  #P1_STARTING_Y,PLAYER_Y_POS(a0)
        move.l  #P1_STARTING_X_DIRECTION,PLAYER_X_DIRECTION(a0)
        move.l  #P1_STARTING_Y_DIRECTION,PLAYER_Y_DIRECTION(a0)
        move.l  #P1_COLOR,PLAYER_COLOR(a0)
        clr.l   PLAYER_ATE_FOOD(a0)
        clr.l   PLAYER_TAIL(a0)
        clr.l   PLAYER_HEAD(a0)
        jsr     AddHead
        move.l  #0,PLAYER_SCORE(a0)
        
        jsr     AddHead
        jsr     AddHead       
        
        jsr     DrawScore
        
        rts     

**
* CreatePlayer2
* This function is called to create the first player and put it onto the game board.
* This functions fills out the memory for Player2. Initializes the struct
* with starting position, color, size, etc.        
CreatePlayer2
        lea     Player2,a0
        move.l  #P2_SCORE_X,PLAYER_SCORE_X(a0)
        move.l  #P2_SCORE_Y,PLAYER_SCORE_Y(a0)
        move.l  #P2_STARTING_X,PLAYER_X_POS(a0)
        move.l  #P2_STARTING_Y,PLAYER_Y_POS(a0)
        move.l  #P2_STARTING_X_DIRECTION,PLAYER_X_DIRECTION(a0)
        move.l  #P2_STARTING_Y_DIRECTION,PLAYER_Y_DIRECTION(a0)
        move.l  #P2_COLOR,PLAYER_COLOR(a0)
        clr.l   PLAYER_ATE_FOOD(a0)
        clr.l   PLAYER_TAIL(a0)
        clr.l   PLAYER_HEAD(a0)
        jsr     AddHead
        move.l  #0,PLAYER_SCORE(a0)
        
        jsr     AddHead
        jsr     AddHead
        
        jsr     DrawScore
        
        rts

**
* SwapBuffers
* Swaps the draw buffers
SwapBuffers
	move.b  #REPAINT_SCREEN_TRAP_CODE,d0
      	TRAP    #15
	rts      

**
* DrawWinner
* Draws the winner of the game as a box in the middle of the screen
DrawWinner
        
        lea     Loser,a6
        
        lea     Player2,a5 
        cmp.l   (a6),a5
        beq     Player2WinnerEnd
        lea     Player2Win,a0
Player2WinnerEnd
        
        lea     Player1,a5 
        cmp.l   (a6),a5
        beq     Player1WinnerEnd     
        lea     Player1Win,a0
Player1WinnerEnd
        
        ; Save off all registers
        movem.l ALL_REG_MINUS_RETURN,-(sp)
        ; Pass in paramaters to function. Load in backwards
        move.l #DISPLAY_HEIGHT/2-PLAYER_WIN_HEIGHT/2,-(sp) ; Output y
        move.l #DISPLAY_WIDTH/2-PLAYER_WIN_WIDTH/2,-(sp) ; Output x
        move.l #PLAYER_WIN_HEIGHT,-(sp) ; Height
        move.l #PLAYER_WIN_WIDTH,-(sp) ; Width
        move.l #0,-(sp) ; Source y
        move.l #0,-(sp) ; Source x
        move.l a0,-(sp) ; Bmp address

        ; Run function
        jsr DisplayBitMap
        ; Fix the stack
        add.l #DBM_PARAMS_SIZE,sp
        ; Restore all registers
        movem.l (sp)+,ALL_REG_MINUS_RETURN
                
        rts        

**
* CheckResetButtonPressed
* Checks if the reset button (R) was pressed and if so resets the game
CheckResetButtonPressed
        ; Check for reset button pressed
        move.l  #GET_KEY_INPUT_COMMAND,d0
        move.l  ResetInput,d1
        trap    #15        
        btst.l  #0,d1
        beq     CheckResetButtonPressedEnd
        ; Clear out game memory
        ; Loop through CollisionMap and clear out memory to 0
        lea     CollisionMap,a1
        clr.l   d0
ClearCollisionMapLoop
        move.l  #0,(a1,d0)
        addi.l  #BYTES_IN_LONG,d0
        cmp.l   #NUM_TILES_WIDTH*NUM_TILES_HEIGHT*COLLISION_STRUCT_SIZE*BYTES_IN_LONG,d0
        blt     ClearCollisionMapLoop
        move.l  #0,Loser ; Clear out loser variable
        move.l  #STARTING_MOVE_SPEED,MoveSpeed ; Reset move speed
        move.l  #0,MoveTimer ; Clear out move timer
        move.l  #MAIN_GAME_STATE,GameState ; Reset game state
        bra.l   GameLoop
 
CheckResetButtonPressedEnd
        rts

**
* PlayMusic
* Plays music
PlayMusic
        move.l  #LOAD_WAV,d0
        lea     Song,a1
        trap    #15
        
        move.l  #PLAY_SOUND,d0
        move.l  #LOOP_SOUND,d2
        trap    #15
        rts

**
* RedrawBackground
* Redraws a portion of the screen with the main bitmap background image
* @param d1: x
* @param d2: y
* @param d3: width
* @param d4: height
RedrawBackground
	
	lea Background,a6
        
        ; Save off all registers
        movem.l ALL_REG_MINUS_RETURN,-(sp)
        ; Pass in paramaters to function. Load in backwards
        move.l d2,-(sp) ; Output y
        move.l d1,-(sp) ; Output x
        move.l d4,-(sp) ; Height
        move.l d3,-(sp) ; Width
        move.l d2,-(sp) ; Source y
        move.l d1,-(sp) ; Source x
        move.l a6,-(sp) ; Bmp address

        ; Run function
        jsr DisplayBitMap
        ; Fix the stack
        add.l #DBM_PARAMS_SIZE,sp
        ; Restore all registers
        movem.l (sp)+,ALL_REG_MINUS_RETURN
	
	rts

        INCLUDE player.x68
        INCLUDE collision.x68
        INCLUDE food.x68
        INCLUDE bitmap.x68
        INCLUDE random.x68
        INCLUDE sevenseg.x68

Player1 ds.l PLAYER_STRUCT_SIZE 
Player2 ds.l PLAYER_STRUCT_SIZE

Player1Input dc.l 'A'<<24+'D'<<16+'S'<<8+'W'
Player2Input dc.l 'J'<<24+'L'<<16+'K'<<8+'I'
ResetInput dc.l 0+'R'

MoveSpeed dc.l STARTING_MOVE_SPEED
MoveTimer dc.l 0

Loser dc.l 0

GameState dc.l MAIN_GAME_STATE

Background INCBIN "snake.bmp"
Player1Win INCBIN "player1-win.bmp"
Player2Win INCBIN "player2-win.bmp"

Song dc.b 'song.wav',0

        clr.l   d0    
        END     START
        




































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
