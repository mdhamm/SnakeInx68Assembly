*-----------------------------------------------------------
* Program Number: food
* Written by    : Michael Hamm
* Date Created  : 9/21/2022
* Description   : Contains code for spawning food
*-----------------------------------------------------------    

FOOD_COLOR EQU $00FFFFFF

**
* Spawn Food
* Spawns food onto the board in a random place that is available
SpawnFood
        ; Save registers
        movem.l  ALL_REG,-(sp)
        
        ; Compute all posible spawns for food
        move.l  #0,PossibleFoodNum
        
        ; Go through tiles. If tile is empty add to possible spawn location
        ; d6 x index
        ; d7 y index
        clr.l   d6
SpawnFoodXLoop

        clr.l   d7
SpawnFoodYLoop        
        
        ; Setting params d0, d1 for routine
        move.l  d6,d0
        move.l  d7,d1
        jsr     GetCollisionMapIndex
        
        ; Check if tile has a player or food
        lea     CollisionMap,a1
        add.l   d2,a1
        cmp.l   #0,PLAYER_IN_SPOT(a1)
        bne.l   AddAsPossibleFoodDone
        cmp.l   #0,FOOD_IN_SPOT(a1)
        bne.l   AddAsPossibleFoodDone
        
        ; Add tile as possible food spawn
        lea     PossibleFoodSpawns,a2
        move.l  PossibleFoodNum,d4
        muls.w  #TILE_STRUCT_SIZE*BYTES_IN_LONG,d4
        add.l   d4,a2
        move.l  d6,TILE_X(a2)
        move.l  d7,TILE_Y(a2)
        addi.l  #1,PossibleFoodNum
AddAsPossibleFoodDone

        addi.l  #1,d7
        cmpi.l  #NUM_TILES_HEIGHT,d7
        blt.l   SpawnFoodYLoop
SpawnFoodYLoopEnd      

        addi.l  #1,d6
        cmpi.l  #NUM_TILES_WIDTH,d6
        blt.l   SpawnFoodXLoop
SpawnFoodXLoopEnd

        ; Get random available spawn into d6
        move.l  #0,d0
        move.l  PossibleFoodNum,d1
        jsr     getRandomLongIntoD6Between ; Results in d6
        muls.w  #TILE_STRUCT_SIZE*BYTES_IN_LONG,d6 ; Gets byte offset from PossibleFoodSpawns
        lea     PossibleFoodSpawns,a0
        add.l   d6,a0
        
        ; Put width and height in d0, d1 for parameters to SetCollisionMapIndexFood
        move.l  TILE_X(a0),d0
        move.l  TILE_Y(a0),d1
        move.l  #1,d3
        jsr     SetCollisionMapIndexFood
 
        ; Draw Food
        jsr     DrawFood
        
        ; Restore registers
        movem.l  (sp)+,ALL_REG
 
        rts

**
* DrawFood
* Draws good onto the board
* @param a0: Tile
DrawFood
        move.l  #FOOD_COLOR,d1
        move.b  #SET_PEN_COLOR_COMMAND,d0
        trap	#15
	move.b	#SET_FILL_COLOR_COMMAND,d0
	trap	#15

        move.b	#DRAW_RECT_COMMAND,d0
	move.l	TILE_X(a0),d1 ; Left x
	muls.w  #CELL_SIZE,d1
	add.l   #STARTING_TILES_X,d1
	move.l	TILE_Y(a0),d2 ; Upper y
	muls.w  #CELL_SIZE,d2
	add.l   #STARTING_TILES_Y,d2
	move.l	d1,d3 ; Right x
        addi.l  #CELL_SIZE,d3
	move.l  d2,d4 ; Bottom y
        addi.l  #CELL_SIZE,d4	
	trap	#15
        rts
           
PossibleFoodSpawns dcb.l TILE_STRUCT_SIZE*NUM_TILES_WIDTH*NUM_TILES_HEIGHT,0
PossibleFoodNum dc.l 0












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
