*-----------------------------------------------------------
* Program Number: collision
* Written by    : Michael Hamm
* Date Created  : 9/21/2022
* Description   : This file contains coroutines that computes
* collisions with a player
*-----------------------------------------------------------

; Collision Struct
PLAYER_IN_SPOT EQU 0*4
FOOD_IN_SPOT EQU 1*4
COLLISION_STRUCT_SIZE EQU 2

**
* GetPlayerPlayerCollidedWith
* Checks if the provided player collided with another player and returns
* the player that was collided with.
* @param a0: player
* @return a6: player that was collided with. 0 if no collision.
GetPlayerPlayerCollidedWith
        move.l  #0,a6
        
        move.l  PLAYER_HEAD(a0),a1
        
        move.l  SNAKE_PART_X(a1),d0
        move.l  SNAKE_PART_Y(a1),d1
        jsr     GetCollisionMapIndex ; returns d2
        
        lea     CollisionMap,a2
        
        ; Get part in this spot
        add.l   d2,a2  
        move.l  PLAYER_IN_SPOT(a2),a6
        
        rts

**
* GetFoodPlayerCollidedWith
* Checks if the provided player collided with food and returns
* a bool of if the player collided with food.
* @param a0: player
* @return d7: food. bool.       
GetFoodPlayerCollidedWith
        move.l  #0,a6

        move.l  PLAYER_HEAD(a0),a1
        
        move.l  SNAKE_PART_X(a1),d0
        move.l  SNAKE_PART_Y(a1),d1
        jsr     GetCollisionMapIndex ; returns d2
        
        lea     CollisionMap,a2
        
        ; Get part in this spot
        add.l   d2,a2  
        move.l  FOOD_IN_SPOT(a2),d7

        rts


**
* GetCollisionMapIndex
* Given an x and y on the board, computes an index for indexing into the collision map
* @param d0: x
* @param d1: y
* @return d2: y * width * BYTES_IN_LONG + x * BYTES_IN_LONG
GetCollisionMapIndex
        ; d3 = x * 4
        ; d2 = results
        move.l  d1,d2
        muls.w  #NUM_TILES_WIDTH*COLLISION_STRUCT_SIZE*BYTES_IN_LONG,d2
        move.l  d0,d3
        muls.w  #COLLISION_STRUCT_SIZE*BYTES_IN_LONG,d3
        add.l   d3,d2
        rts

**
* SetCollisionMapIndexPlayer
* Sets a player on the collision map at the x,y position provided
* @param d0: x
* @param d1: y
* @param a0: player
SetCollisionMapIndexPlayer
        jsr     GetCollisionMapIndex
        lea     CollisionMap,a1
        
        add.l   d2,a1
        move.l  a0,PLAYER_IN_SPOT(a1)
        rts

**
* SetCollisionMapIndexFood
* Sets a food on the collision map at the x,y position provided
* @param d0: x
* @param d1: y
* @param d3: food. bool
SetCollisionMapIndexFood
        jsr     GetCollisionMapIndex
        lea     CollisionMap,a1
        
        add.l   d2,a1
        move.l  d3,FOOD_IN_SPOT(a1)
        rts

**
* ClearCollisionMapIndex
* Clears the collision map at the x,y position provided
* @param d0: x
* @param d1: y
ClearCollisionMapIndex
        jsr     GetCollisionMapIndex
        lea     CollisionMap,a1
        
        add.l   d2,a1
        clr.l   PLAYER_IN_SPOT(a1)
        clr.l   FOOD_IN_SPOT(a1)
        rts
    
CollisionMap dcb.l NUM_TILES_WIDTH*NUM_TILES_HEIGHT*COLLISION_STRUCT_SIZE,0   

















        






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
