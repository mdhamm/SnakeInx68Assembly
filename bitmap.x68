*-----------------------------------------------------------
* Program Number: Bitmap Subroutine
* Written by    : Michael Hamm
* Date Created  : 9/21/2022
* Description   : This file contains a bitmap coroutine that displays 24 or 32 bitmap files onto the screen.
* Ths bitmap coroutine supports bitmaps with a BITMAPINFOHEADER and non-paletted bitmaps only.
*-----------------------------------------------------------

ALL_REG_MINUS_RETURN            REG     D0-D6/A0-A7

BYTES_IN_WORD  EQU 2
BYTES_IN_LONG  EQU 4
BITES_PER_BYTE EQU 8
BITS_TO_BYTE_SHIFT EQU 3

; Trap codes       
PEN_COLOR_TRAP_CODE             EQU     80
DRAW_PIXEL_TRAP_CODE            EQU     82
SET_OUTPUT_RESOLUTION_TRAP_CODE EQU     33
PRINT_STRING_TRAP_CODE          EQU     13

; DisplayBitMap local variables
DBM_LOCAL_IMAGE_WIDTH         EQU 0
DBM_LOCAL_IMAGE_HEIGHT        EQU 4
DBM_LOCAL_ROW_SIZE            EQU 8
DBM_LOCAL_BYTES_PER_PIXEL     EQU 10
DBM_LOCALS_SIZE               EQU 12

; DisplayBitMap parameters
DBM_PARAM_BMP_POINTER         EQU 4+DBM_LOCALS_SIZE
DBM_PARAM_SOURCE_X            EQU 8+DBM_LOCALS_SIZE
DBM_PARAM_SOURCE_Y            EQU 12+DBM_LOCALS_SIZE
DBM_PARAM_SELECTED_WIDTH      EQU 16+DBM_LOCALS_SIZE
DBM_PARAM_SELECTED_HEIGHT     EQU 20+DBM_LOCALS_SIZE
DBM_PARAM_OUTPUT_X            EQU 24+DBM_LOCALS_SIZE
DBM_PARAM_OUTPUT_Y            EQU 28+DBM_LOCALS_SIZE
DBM_PARAMS_SIZE               EQU 28

; Swap16 parameters
Swap16_DATA EQU 6
Swap16_PARAMS_SIZE EQU 4

; Swap16 parameters
Swap32_DATA EQU 4
Swap32_PARAMS_SIZE EQU 4

; Bitmap offsets
BITMAP_STARTING_ADDRESS_OFFSET  EQU $0A
DIB_HEADER_OFFSET               EQU $0E
BITMAP_WIDTH_OFFSET             EQU $12
BITMAP_HEIGHT_OFFSET            EQU $16
BITMAP_BITS_PER_PIXEL_OFFSET    EQU $1C
BITMAP_PALETTE_COLORS_OFFSET    EQU $2E

; Bitmap constants
SUPPORTED_DIB_HEADER_VERSION    EQU 40
BITS_PER_PIXEL_24 EQU 24
BITS_PER_PIXEL_32 EQU 32

**
* Swap16
*
* Swaps the least significant bytes. e.g. 0x0102 -> 0x0201
* @param data(word): word to swap bytes
* @return long: Swapped data in d7 register
* @note: Params are should be placed on stack in reverse order before calling this subroutine.
* Params should be padded to the nearest long.
**
Swap16
       move.w Swap16_DATA(sp),d7
       move.w d7,d1
       lsl.w #8,d7
       lsr.w #8,d1
       move.b d1,d7
       
       rts

**
* Swap32
*
* Endian Swaps the bytes of a long. e.g. 0x01020304 -> 0x04030201
* @param data(long): long to swap bytes
* @return long: Swapped data in d7 register
* @note: Params are should be placed on stack in reverse order before calling this subroutine.
* Params should be padded to the nearest long.
**
Swap32
        move.l Swap32_DATA(sp),d7
      
        ;; Call swap 16
        ; Pass in parameters
        move.w d7,-(sp)
        sub.l #BYTES_IN_WORD,sp ; Padding
        jsr Swap16
        ; Fix the stack
        add.l #Swap16_PARAMS_SIZE,sp
      
        ; Swap words in long
        swap d7

        ;; Call swap 16
        ; Pass in parameters
        move.w d7,-(sp)
        sub.l #BYTES_IN_WORD,sp ; Padding
        jsr Swap16
        ; Fix the stack
        add.l #Swap16_PARAMS_SIZE,sp

        rts     
        
**
* DisplayBitMap
*
* Draws a bitmap to the screen
* @param Source x(long): x coordinate of the source image
* @param Source y(long): y coordinate of the source image
* @Param Source width(long): width to draw
* @param Source height(long): height to draw
* @param Output x(long): x coordinate of the output screen
* @param Output y(long): y coordinate of the output screen
**
DisplayBitMap

DBM_HeaderCheck_Start       
        ; Local variables
        move.w  #0,-(sp) ; Row Size
        move.w  #0,-(sp) ; Bits Per Pixel
        move.l  #0,-(sp) ; File Height
        move.l  #0,-(sp) ; File Width
        
        ; Check that file is a bitmap  
        move.l  DBM_PARAM_BMP_POINTER(sp),a0
        move.w  (a0),d0
        cmp.w   #$424D,d0
        beq     DBM_HeaderCheck_End

        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     NotABitmapText,a1
        trap    #15         
        
        bra.w DisplayBitMap_End
DBM_HeaderCheck_End

DBM_VersionCheck_Start

        ; Check we have the right dib header
        move.l  DIB_HEADER_OFFSET(a0),d0
        
        ;; Call swap 16 on dib header size
        ; Pass in parameters
        move.l  d0,-(sp)
        jsr     Swap32
        ; Fix the stack
        add.l   #Swap32_PARAMS_SIZE,sp
        
        cmp.l   #SUPPORTED_DIB_HEADER_VERSION,d7
        beq     DBM_VersionCheck_End
 
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     UnsupportedDIBText,a1
        trap    #15  
 
        bra.w   DisplayBitMap_End
DBM_VersionCheck_End

DBM_BPPCheck_Start       
        ; Check that bits per pixels is supported
        
        ;; Call swap 32 on bits per pixel
        ; Pass in parameters
        move.w  BITMAP_BITS_PER_PIXEL_OFFSET(a0),-(sp)
        sub.l   #BYTES_IN_WORD,sp ; Padding
        jsr     Swap16
        ; Fix the stack
        add.l   #Swap16_PARAMS_SIZE,sp
        
        ; Check if 24 bpp
        cmp.w   #BITS_PER_PIXEL_24,d7
        beq     DBM_BPPCheck_End
        ; Check if 32 bpp
        cmp.w   #BITS_PER_PIXEL_32,d7
        beq     DBM_BPPCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     UnsupportedBPPText,a1
        trap    #15 
        
        bra.w   DisplayBitMap_End      
DBM_BPPCheck_End
        
        ; Convert bits to bytes
        asr.w   #BITS_TO_BYTE_SHIFT,d7        
        move.w  d7,DBM_LOCAL_BYTES_PER_PIXEL(sp)
        
        ; Get width image        
        move.l  BITMAP_WIDTH_OFFSET(a0),DBM_LOCAL_IMAGE_WIDTH(sp)
        ;; Call swap 32 on width
        ; Pass in parameters
        move.l  DBM_LOCAL_IMAGE_WIDTH(sp),-(sp)
        jsr     Swap32
        ; Fix the stack
        add.l   #Swap32_PARAMS_SIZE,sp
        ; Update width local variable with swapped version       
        move.l  d7,DBM_LOCAL_IMAGE_WIDTH(sp)
        
        ; Get height of image
        move.l  BITMAP_HEIGHT_OFFSET(a0),DBM_LOCAL_IMAGE_HEIGHT(sp)
        ;; Call swap 32 on height
        ; Pass in parameters
        move.l  DBM_LOCAL_IMAGE_HEIGHT(sp),-(sp)
        jsr     Swap32
        ; Fix the stack
        add.l   #Swap32_PARAMS_SIZE,sp 
        ; Update height local variable with swapped version
        move.l  d7,DBM_LOCAL_IMAGE_HEIGHT(sp)
        
        ;; Sanity checks on input
        

DBM_PaletteCheck_Start
        ; Check there is no color palete
        
        move.l  BITMAP_PALETTE_COLORS_OFFSET(a0),d0
        beq.l   DBM_PaletteCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     UnsupportedPaletteText,a1
        trap    #15 
        
        bra.w   DisplayBitMap_End
DBM_PaletteCheck_End

        
DBM_WidthPosCheck_Start
        ; Check width_param >= 0

        move.l  DBM_PARAM_SELECTED_WIDTH(sp),d0
        bge     DBM_WidthPosCheck_End
         
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     NegativeWidthParamText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_WidthPosCheck_End 

DBM_HeightPosCheck_Start
        ; Check height_param >= 0

        move.l  DBM_PARAM_SELECTED_HEIGHT(sp),d0
        bge     DBM_HeightPosCheck_End
         
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     NegativeHeightParamText,a1
        trap    #15
        
        bra.w DisplayBitMap_End
DBM_HeightPosCheck_End       

DBM_PosXCheck_Start        
        ; Check source_x_param >= 0
                
        move.l  DBM_LOCAL_IMAGE_WIDTH(sp),d0
        move.l  DBM_PARAM_SOURCE_X(sp),d1
 
        bge     DBM_PosXCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     NegativeSourceXParamText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_PosXCheck_End        


DBM_XPWLTWCheck_Start
        ; Check source_x_parm + width_param <= width_height
            
        add.l   DBM_PARAM_SELECTED_WIDTH(sp),d1
        cmp.l   d0,d1
        ble     DBM_XPWLTWCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     OverflowSourceXText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_XPWLTWCheck_End

DBM_PosYCheck_Start
        ; Check source_y_param >= 0
                
        move.l  DBM_LOCAL_IMAGE_HEIGHT(sp),d0
        move.l  DBM_PARAM_SOURCE_Y(sp),d1
   
        bge     DBM_PosYCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     NegativeSourceYParamText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_PosYCheck_End        


DBM_YPHLTHCheck_Start
        ; Check source_y_param + height_param <= image_height

        add.l   DBM_PARAM_SELECTED_HEIGHT(sp),d1
        cmp.l   d0,d1
        ble     DBM_YPHLTHCheck_End 
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     OverflowSourceYText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_YPHLTHCheck_End    
   
        ; Get output width and height
        ; output width  -> d2
        ; output height -> d3

        move.b  #SET_OUTPUT_RESOLUTION_TRAP_CODE,d0
        move.l  #0,d1 ; 0 in d1 gets the dimensions rather than setting
        TRAP    #15
        
        ; Width stored in upper 16, height in lower 16
        move.w  d1,d3
        swap    d1
        move.w  d1,d2


DBM_PosOXCheck_Start
        ; Check output_x_param >= 0
        move.l  DBM_PARAM_OUTPUT_X(sp),d0
   
        bge     DBM_PosOXCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     NegativeOutputXParamText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_PosOXCheck_End


DBM_XPWLTOWCheck_Start
        ; Check source_x_parm + width_param <= otuput_width
            
        add.l   DBM_PARAM_SELECTED_WIDTH(sp),d0
        cmp.l   d2,d0
        ble     DBM_XPWLTOWCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     OverflowOutputXText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_XPWLTOWCheck_End

DBM_PosOYCheck_Start
        ; Check output_y_param >= 0
        move.l  DBM_PARAM_OUTPUT_Y(sp),d0
   
        bge     DBM_PosOYCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     NegativeOutputXParamText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_PosOYCheck_End


DBM_YPHLTOHCheck_Start
        ; Check source_y_parm + height_param <= output_height
            
        add.l   DBM_PARAM_SELECTED_HEIGHT(sp),d0
        cmp.l   d3,d0
        ble     DBM_YPHLTOHCheck_End
        
        ; Print error
        move.l  #PRINT_STRING_TRAP_CODE,d0
        lea     OverflowOutputYText,a1
        trap    #15
        
        bra.w   DisplayBitMap_End
DBM_YPHLTOHCheck_End

     
        ; Gets the bitmap starting address and stores it in to a2
        ; Gets starting address from bitmap file and swaps 32
        ; Pass in parameters
        move.l  BITMAP_STARTING_ADDRESS_OFFSET(a0),-(sp)
        jsr     Swap32
        ; Fix the stack
        add.l   #Swap32_PARAMS_SIZE,sp
        move.l  d7,a2 ; Puts swapped starting address offset into a2
        add.l   a0,a2 ; Add file address to pixel data offset
        
        
        ; Compute row size. Row size accounts for padding. Compute in d0.
        ; Row Size = (bytes_per_pixel * image_width) + ((bytes_per_pixel * image_width) % 4) 
        move.w  DBM_LOCAL_BYTES_PER_PIXEL(sp),d0 
        muls.w  DBM_LOCAL_IMAGE_WIDTH+BYTES_IN_WORD(sp),d0 ; (bytes_per_pixel * image_width)
        move.l  d0,d1 ; Compute modulus 4 in remainder
        divs.w  #BYTES_IN_LONG,d1
        swap    d1 ; Get remainder on right side
        add.w   d1,d0 ; Adds remainder to row size
        move.w  d0,DBM_LOCAL_ROW_SIZE(sp) ; Stores in local variable
        

        
        ; Loop through pixels and draw to screen.

        ; Loop from 0 to height param
        ; d3 = y_index from [0,height_param)
       
        clr.l   d3 ; Intialize y index to 0
        
        ; If y_index == height_param skip loop
        cmp.l   DBM_PARAM_SELECTED_HEIGHT(sp),d3
        beq     DBM_YLoop_End
        
DBM_YLoop
        
        
        ; Loop from 0 to width param 
        ; d4 = x index from [0,width param)
    
        clr.l   d4 ; Initialize x index to 0
        
        ; If x_index == width_param skip loop
        cmp.l   DBM_PARAM_SELECTED_WIDTH(sp),d4
        beq     DBM_XLoop_End
DBM_XLoop
        
        ; Get source pixel address. Put into a2
        
        ; Starting address is start_address + source_image_offset
        ; where
        ; source_image_offset = ((image_height-1-y)*row_size + (x*BPP))
        ; y = (source_y + y_index)
        ; x = (source_y + x_index)
        
        ; Compute y into d0
        move.l  DBM_PARAM_SOURCE_Y(sp),d0 ; source_y -> y
        add.l   d3,d0 ; source_y + y_index -> y

        ; Compute x into d1
        move.l  DBM_PARAM_SOURCE_X(sp),d1 ; source_x -> x
        add.l   d4,d1 ; source_x + x_index -> x
        
        ; Compute x*BPP into d2
        move.l  d1,d2 ; x -> d2
        muls.w  DBM_LOCAL_BYTES_PER_PIXEL(sp),d2 ; x*BPP -> d2
        
        ; Compute source_image_offset into d5
        move.l  DBM_LOCAL_IMAGE_HEIGHT(sp),d5 ; image_height
        subi.l  #1,d5 ; -1
        sub.l   d0,d5 ; -y
        muls.w  DBM_LOCAL_ROW_SIZE(sp),d5 ; * row_size
        add.l   d2,d5 ; + (x*BPP)
        
        ; start_address + source_image_offset -> a3
        move.l  a2,a3
        add.l   d5,a3
        
        ; d0-d2,d5 reusable

        ; Get color from pixel address. Store in d1
        clr.l   d1
        move.b  (a3),d1 ; Blue
        lsl.l   #BITES_PER_BYTE,d1
        move.b  1(a3),d1 ; Green
        lsl.l   #BITES_PER_BYTE,d1
        move.b  2(a3),d1 ; Red

        ; Set pen color. Uses d1
        move.l  #PEN_COLOR_TRAP_CODE,d0 ; Set the proper trap code to set the pen color
        trap    #15
        
        ; Compute output x and y for drawing
        ; y = (output_y + y_index)
        ; x = (output_x + x_index)
        
        ; Compute output y in d2
        move.l  DBM_PARAM_OUTPUT_Y(sp),d2 ; output_y -> y
        add.l   d3,d2 ; output_y + y_index -> y

        ; Compute output x in d1
        move.l  DBM_PARAM_OUTPUT_X(sp),d1 output_x -> x
        add.l   d4,d1 output_x + x_index -> x
        
        ; Draw pixel at x,y coordinates. Uses d1 and d2
        move.l  #DRAW_PIXEL_TRAP_CODE,d0 
        trap    #15
        
        ; Increment y_index
        addi.l  #1,d4
        
        ; Keep looping if x index < width param
        cmp.l   DBM_PARAM_SELECTED_WIDTH(sp),d4
        bne     DBM_XLoop
DBM_XLoop_End

        ; Increment x_index
        addi.l  #1,d3
        
        ; Keep looping if y index < height param
        cmp.l   DBM_PARAM_SELECTED_HEIGHT(sp),d3
        bne     DBM_YLoop 
DBM_YLoop_End        



DisplayBitMap_End
        ; Pop off local variables
        add #DBM_LOCALS_SIZE,sp
        rts
        
NotABitmapText	         dc.b 'The file provided is not a bitmap.',0
UnsupportedDIBText	 dc.b 'The DIB header provided is unsupported. Expected BITMAPINFOHEADER (40).',0
UnsupportedBPPText       dc.b 'Unsupported bits per pixel. Only 24 and 32 bits supported.',0
NegativeWidthParamText   dc.b 'Width parameter must be greater than or equal to 0.',0
NegativeHeightParamText  dc.b 'Height parameter must be greater then or equal to 0.',0
NegativeSourceXParamText dc.b 'Source x parameter must be greater than or equal to 0.',0
NegativeSourceYParamText dc.b 'Source y parameter must be greater than or equal to 0.',0
NegativeOutputXParamText dc.b 'Output x parameter must be greater than or equal to 0.',0
NegativeOutputYParamText dc.b 'Output y parameter must be greater than or equal to 0.',0
OverflowSourceXText      dc.b 'x_source_param + width_param > image_width.',0
OverflowSourceYText      dc.b 'y_source_param + height_param > image_height.',0
OverflowOutputXText      dc.b 'x_output_param + width_param > output_width.',0
OverflowOutputYText      dc.b 'y_output_param + height_param > output_height.',0
UnsupportedPaletteText   dc.b 'Bitmaps with color palettes are unsupported',0











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
