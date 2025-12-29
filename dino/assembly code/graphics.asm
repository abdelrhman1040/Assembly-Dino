# =================================================================
# MODULE: GRAPHICS
# DESCRIPTION: Contains all rendering subroutines for Dino Run.
# DEPENDENCIES: Requires constants (SCREEN_WIDTH, MMIO_VIDEO_BASE, etc.)
#               and variables defined in main.asm.
# =================================================================

# -----------------------------------------------------------------
# Function: Init_StaticBackground
# Purpose:  Fills the screen with Sky, Horizon, and Ground colors.
#           Then draws the Sun using the Gfx_DrawSun function.
# -----------------------------------------------------------------
Init_StaticBackground:
    # Save $ra because we are making a nested function call
    addi  $sp, $sp, -4
    sw    $ra, 0($sp)

    li    $t0, MMIO_VIDEO_BASE        # FIX: Changed lw to li

    # 1. Draw Sky (Top 116 rows)
    li    $t1, SCREEN_WIDTH           # FIX: Changed lw to li
    li    $t3, 116                
    mul   $t1, $t1, $t3            
    li    $t2, COLOR_SKY              # FIX: Changed lw to li

bg_sky_loop:
    sw    $t2, 0($t0)
    addi  $t0, $t0, 4            
    subi  $t1, $t1, 1
    bgtz  $t1, bg_sky_loop

    # 2. Draw Horizon Line (1 row)
    li    $t1, SCREEN_WIDTH           # FIX: Changed lw to li
    li    $t2, COLOR_HORIZON          # FIX: Changed lw to li

bg_horizon_loop:
    sw    $t2, 0($t0)
    addi  $t0, $t0, 4            
    subi  $t1, $t1, 1
    bgtz  $t1, bg_horizon_loop

    # 3. Draw Ground (Remaining 11 rows)
    li    $t1, SCREEN_WIDTH
    li    $t3, 11                 
    mul   $t1, $t1, $t3            
    li    $t2, COLOR_GROUND           # FIX: Changed lw to li

bg_ground_loop:
    sw    $t2, 0($t0)
    addi  $t0, $t0, 4            
    subi  $t1, $t1, 1
    bgtz  $t1, bg_ground_loop
    
    # -------------------------------------------------
    # 4. Draw Sun (Standard Function Call)
    # -------------------------------------------------
    li    $a0, 220              # X Position (Right side)
    li    $a2, 5                # Y Position (Top with margin)
    la    $a1, sun              # Sprite Address
    jal   Gfx_DrawSun           # Call Draw Function

    # Restore $ra to return to main
    lw    $ra, 0($sp)
    addi  $sp, $sp, 4
    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_CleanLeftBoundary
# Purpose:  Manually clears artifacts on the leftmost 5 pixels of 
#           the obstacle row caused by wrapping calculations.
# -----------------------------------------------------------------
Gfx_CleanLeftBoundary:
    li    $t8, MMIO_VIDEO_BASE        # FIX: Changed lw to li
    li    $t9, POS_OBSTACLE_Y         # FIX: Changed lw to li
    
    # Safe Multiplication (Load constant to register first)
    li    $at, SCREEN_WIDTH
    mul   $t9, $t9, $at
    
    sll   $t9, $t9, 2
    add   $t8, $t8, $t9           # Row start address
    li    $t9, COLOR_SKY
    li    $a3, OBST_HEIGHT        
    
clba_loop:
    sw    $t9, 0($t8)             # Clear pixel 0
    sw    $t9, 4($t8)             # Clear pixel 1
    sw    $t9, 8($t8)             # Clear pixel 2
    sw    $t9, 12($t8)            # Clear pixel 3
    sw    $t9, 16($t8)            # Clear pixel 4
    addi $t8, $t8, 1024           # Jump to next line (256 * 4)
    subi $a3, $a3, 1
    bgtz $a3, clba_loop
    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_EraseDino
# Purpose:  Restores background color at Dino's position.
# Inputs:   $a0 = X Position, $a2 = Y Position
# -----------------------------------------------------------------
Gfx_EraseDino:
    li    $t1, MMIO_VIDEO_BASE
    move $t5, $a2                 
    mul   $t5, $t5, SCREEN_WIDTH        
    add   $t5, $t5, $a0           
    sll   $t5, $t5, 2             
    add   $t1, $t1, $t5           
    li    $s0, SCREEN_WIDTH                
    sub   $s0, $s0, SPRITE_WIDTH        
    sll   $s0, $s0, 2             
    li    $t2, SPRITE_HEIGHT                
    li    $t8, COLOR_SKY              

ed_row_loop:
    # Unrolled loop (24 pixels)
    sw    $t8, 0($t1)
    sw    $t8, 4($t1)
    sw    $t8, 8($t1)
    sw    $t8, 12($t1)
    sw    $t8, 16($t1)
    sw    $t8, 20($t1)
    sw    $t8, 24($t1)
    sw    $t8, 28($t1)
    sw    $t8, 32($t1)
    sw    $t8, 36($t1)
    sw    $t8, 40($t1)
    sw    $t8, 44($t1)
    sw    $t8, 48($t1)
    sw    $t8, 52($t1)
    sw    $t8, 56($t1)
    sw    $t8, 60($t1)
    sw    $t8, 64($t1)
    sw    $t8, 68($t1)
    sw    $t8, 72($t1)
    sw    $t8, 76($t1)
    sw    $t8, 80($t1)
    sw    $t8, 84($t1)
    sw    $t8, 88($t1)
    sw    $t8, 92($t1)

    addi $t1, $t1, 96             
    add   $t1, $t1, $s0             
    subi $t2, $t2, 1
    bgtz $t2, ed_row_loop
    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_DrawDino
# Purpose:  Draws Dino sprite handling transparency (skip white).
# Inputs:   $a0 = X Pos, $a2 = Y Pos, $a1 = Sprite Address
# -----------------------------------------------------------------
Gfx_DrawDino:
    li    $t1, MMIO_VIDEO_BASE            
    move $t5, $a2                     
    mul   $t5, $t5, SCREEN_WIDTH                
    add   $t5, $t5, $a0                     
    sll   $t5, $t5, 2                     
    add   $t1, $t1, $t5                     
    li    $s0, SCREEN_WIDTH                      
    sub   $s0, $s0, SPRITE_WIDTH             
    sll   $s0, $s0, 2                     
    move $t0, $a1                     
    li    $t2, SPRITE_HEIGHT                      
    li    $t6, COLOR_TRANSPARENT  

dd_row_loop:
    li    $t3, 3                     # 3 blocks of 8 pixels
dd_col_loop:
    # Unrolled 8-pixel check
    lw    $t4, 0($t0)
    beq   $t4, $t6, skip_pix_1      
    sw    $t4, 0($t1)
    skip_pix_1:
    lw    $t4, 4($t0)
    beq   $t4, $t6, skip_pix_2
    sw    $t4, 4($t1)
    skip_pix_2:
    lw    $t4, 8($t0)
    beq   $t4, $t6, skip_pix_3
    sw    $t4, 8($t1)
    skip_pix_3:
    lw    $t4, 12($t0)
    beq   $t4, $t6, skip_pix_4
    sw    $t4, 12($t1)
    skip_pix_4:
    lw    $t4, 16($t0)
    beq   $t4, $t6, skip_pix_5
    sw    $t4, 16($t1)
    skip_pix_5:
    lw    $t4, 20($t0)
    beq   $t4, $t6, skip_pix_6
    sw    $t4, 20($t1)
    skip_pix_6:
    lw    $t4, 24($t0)
    beq   $t4, $t6, skip_pix_7
    sw    $t4, 24($t1)
    skip_pix_7:
    lw    $t4, 28($t0)
    beq   $t4, $t6, skip_pix_8
    sw    $t4, 28($t1)
    skip_pix_8:
    
    addi $t0, $t0, 32                 
    addi $t1, $t1, 32
    subi $t3, $t3, 1
    bgtz $t3, dd_col_loop
    
    add   $t1, $t1, $s0                 
    subi $t2, $t2, 1
    bgtz $t2, dd_row_loop
    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_EraseObstacle
# Purpose:  Clears the obstacle area (fills with Sky Blue).
#           Calculates clipping logic internally.
# Inputs:   $a0 = X Position
# -----------------------------------------------------------------
Gfx_EraseObstacle:
    # 1. Load dynamic speed to know how wide the "gap" is
    lw    $t0, cfg_speed_curr       # $t0 = Speed (e.g., 2)
    
    # 2. Calculate Start Position for Erasing (Right side of the rock)
    #    Erase_X = Current_X + 32 - Speed
    li    $t9, OBST_WIDTH         # 32
    sub   $t9, $t9, $t0           # Offset = 32 - Speed
    add   $a0, $a0, $t9           # $a0 is now pointing to the tail
    
    # 3. Handle Clipping (If the tail is off-screen)
    li    $t2, SCREEN_WIDTH        
    
    # Check if Start X is negative (Unlikely for tail, but safe check)
    bltz $a0, eo_clip_left
    
    # Check if Width goes beyond screen
    add   $t3, $a0, $t0           # End X
    bgt   $t3, SCREEN_WIDTH, eo_clip_right
    move $t4, $a0                 # No clipping, Start X is fine
    j     eo_start_draw

eo_clip_left:
    # If tail starts off-screen left (rare), adjust width
    add   $t0, $a0, $t0           # Remaining width
    li    $t4, 0                  # Start at 0
    j     eo_start_draw

eo_clip_right:
    # If tail goes off-screen right, reduce width
    sub   $t0, $t2, $a0           # Width = ScreenWidth - X
    move $t4, $a0                 
    
eo_start_draw:
    blez $t0, eo_end              # If width <= 0, draw nothing
    
    # 4. Setup Drawing Loop
    li    $t1, MMIO_VIDEO_BASE
    li    $t5, POS_OBSTACLE_Y          
    mul   $t5, $t5, SCREEN_WIDTH        
    add   $t5, $t5, $t4           # Add X offset
    sll   $t5, $t5, 2             # Convert to bytes
    add   $t1, $t1, $t5           # Final Address
    
    li    $t8, COLOR_SKY          # Erase Color
    li    $t9, 1024               # Stride (256 * 4 bytes)
    li    $a1, OBST_HEIGHT        # Height loop

eo_row_loop:
    move $t6, $t0                 # Pixels to erase in this row (Speed)
    move $t7, $t1                 # Current pointer
    
eo_pixel_loop:
    # Draw pixel
    sw    $t8, 0($t7)
    addi $t7, $t7, 4
    subi $t6, $t6, 1
    bgtz $t6, eo_pixel_loop
    
eo_next_line:
    add   $t1, $t1, $t9           # Move to next line
    subi $a1, $a1, 1
    bgtz $a1, eo_row_loop

eo_end:
    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_DrawObstacle
# Purpose:  Draws obstacle using pre-calculated clipping data found
#           in buffers (buf_render_addr, buf_sprite_addr).
# -----------------------------------------------------------------
Gfx_DrawObstacle:
    lw    $s0, buf_render_width             
    blez $s0, do_end              
    lw    $t1, buf_render_addr
    lw    $t2, buf_sprite_addr
    li    $t3, OBST_HEIGHT                     
    li    $t4, 1024               # Screen Stride
    li    $t5, 128                # Sprite Stride (32*4)
    
do_row_loop:
    move $t6, $s0                        
    move $t7, $t1                        
    move $t8, $t2                        
    
do_unroll_4:
    blt   $t6, 4, do_remainder    
    lw    $t9, 0($t8)
    sw    $t9, 0($t7)
    lw    $t9, 4($t8)
    sw    $t9, 4($t7)
    lw    $t9, 8($t8)
    sw    $t9, 8($t7)
    lw    $t9, 12($t8)
    sw    $t9, 12($t7)
    addi $t7, $t7, 16
    addi $t8, $t8, 16
    subi $t6, $t6, 4                     
    bgtz $t6, do_unroll_4         
    
do_remainder:
    blez $t6, do_next_line               
    lw    $t9, 0($t8)
    sw    $t9, 0($t7)
    addi $t7, $t7, 4
    addi $t8, $t8, 4
    subi $t6, $t6, 1
    bgtz $t6, do_remainder

do_next_line:
    add   $t1, $t1, $t4                   
    add   $t2, $t2, $t5                   
    subi $t3, $t3, 1                      
    bgtz $t3, do_row_loop
do_end:
    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_DrawGameOver
# Purpose:  Draws the 69x40 Game Over sprite with transparency.
# Inputs:   $a0 = X Position, $a2 = Y Position
# -----------------------------------------------------------------
Gfx_DrawGameOver:
    # 1. Setup Addresses
    li    $t1, MMIO_VIDEO_BASE        # $t1 = VRAM Base
    
    # Calculate Screen Start Address: Base + (Y * ScreenWidth + X) * 4
    subu $a2,$a2,10
    mul   $t5, $a2, SCREEN_WIDTH      
    add   $t5, $t5, $a0               
    sll   $t5, $t5, 2                 
    add   $t1, $t1, $t5               # $t1 = Current Screen Pixel Pointer

    # Calculate "Next Line" Offset for Screen
    # We need to skip the pixels we didn't draw on the right side of the screen
    li    $s0, SCREEN_WIDTH                
    sub   $s0, $s0, GAMEOVER_WIDTH    # 256 - 69 = 187 pixels to skip
    sll   $s0, $s0, 2                 # Convert to bytes (187 * 4)

    # Setup Sprite Source
    la    $t0, sprite_GAMEOVER        # $t0 = Sprite Data Pointer
    
    # Setup Counters
    li    $t2, GAMEOVER_HEIGHT        # $t2 = Height Counter (40)
    li    $t6, COLOR_TRANSPARENT      # $t6 = Transparency Key (0x00FFFFFF)

dgo_row_loop:
    li    $t3, GAMEOVER_WIDTH         # $t3 = Width Counter (69) - Reset every row

dgo_col_loop:
    lw    $t4, 0($t0)                 # Load pixel from sprite
    
    # --- TRANSPARENCY CHECK ---
    beq   $t4, $t6, dgo_skip_pixel    # If color is White, skip writing
    sw    $t4, 0($t1)                 # Otherwise, write to screen
    
dgo_skip_pixel:
    addi $t0, $t0, 4                 # Increment Sprite Pointer
    addi $t1, $t1, 4                 # Increment Screen Pointer
    
    subi $t3, $t3, 1                 # Decrement width counter
    bgtz $t3, dgo_col_loop           # Continue loop if pixels remain in row

    # End of Row: Jump to start of next line
    add   $t1, $t1, $s0               # Add the offset to wrap to next screen line
    subi $t2, $t2, 1                 # Decrement height counter
    bgtz $t2, dgo_row_loop           # Continue to next row if rows remain

    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_Drawstoplay
# Purpose:  Draws the "STOPLAY" logo.
# Inputs:   $a0 = X, $a2 = Y
# -----------------------------------------------------------------
Gfx_Drawstoplay:
    # 1. Setup Addresses
    li    $t1, MMIO_VIDEO_BASE        # $t1 = VRAM Base
    
    # Calculate Screen Start Address: Base + (Y * ScreenWidth + X) * 4
    # Note: No offset here anymore, using raw $a2
    mul   $t5, $a2, SCREEN_WIDTH      
    add   $t5, $t5, $a0               
    sll   $t5, $t5, 2                 
    add   $t1, $t1, $t5               # $t1 = Current Screen Pixel Pointer

    # Calculate "Next Line" Offset for Screen
    # We need to skip the pixels we didn't draw on the right side of the screen
    li    $s0, SCREEN_WIDTH                
    sub   $s0, $s0, STOPLAY_WIDTH     # 256 - 69 = 187 pixels to skip
    sll   $s0, $s0, 2                 # Convert to bytes (187 * 4)

    # Setup Sprite Source
    la    $t0, stoplay        # $t0 = Sprite Data Pointer
    
    # Setup Counters
    li    $t2, STOPLAY_HEIGHT        # $t2 = Height Counter (40)
    li    $t6, COLOR_TRANSPARENT      # $t6 = Transparency Key (0x00FFFFFF)

dgo_row_loop_stoplay:
    li    $t3, STOPLAY_WIDTH         # $t3 = Width Counter (69) - Reset every row

dgo_col_loop_stoplay:
    lw    $t4, 0($t0)                 # Load pixel from sprite
    
    # --- TRANSPARENCY CHECK ---
    beq   $t4, $t6, dgo_skip_pixel_stoplay  # If color is White, skip writing
    sw    $t4, 0($t1)                 # Otherwise, write to screen
    
dgo_skip_pixel_stoplay:
    addi $t0, $t0, 4                 # Increment Sprite Pointer
    addi $t1, $t1, 4                 # Increment Screen Pointer
    
    subi $t3, $t3, 1                 # Decrement width counter
    bgtz $t3, dgo_col_loop_stoplay          # Continue loop if pixels remain in row

    # End of Row: Jump to start of next line
    add   $t1, $t1, $s0               # Add the offset to wrap to next screen line
    subi $t2, $t2, 1                 # Decrement height counter
    bgtz $t2, dgo_row_loop_stoplay          # Continue to next row if rows remain

    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_EraseStoplay
# Purpose:  Overwrites the STOPLAY logo area with Sky Blue.
# Inputs:   $a0 = X Position, $a2 = Y Position (Relative 0)
# -----------------------------------------------------------------
Gfx_EraseStoplay:
    # 1. Calculate Start Address
    li    $t1, MMIO_VIDEO_BASE        # $t1 = VRAM Base
        
    mul   $t5, $a2, SCREEN_WIDTH      
    add   $t5, $t5, $a0               
    sll   $t5, $t5, 2                 
    add   $t1, $t1, $t5               # $t1 = Current Screen Pixel Pointer

    # 2. Setup Loop Parameters
    li    $t2, STOPLAY_HEIGHT         # Height (40)
    li    $t8, COLOR_SKY              # Fill Color
    
    # Offset to jump to next line
    li    $t9, SCREEN_WIDTH                
    sub   $t9, $t9, STOPLAY_WIDTH     # 256 - 69 = 187
    sll   $t9, $t9, 2                 # Bytes to skip

erase_stoplay_row:
    li    $t3, STOPLAY_WIDTH          # Width (69)

erase_stoplay_col:
    sw    $t8, 0($t1)                 # Write Sky Color
    addi $t1, $t1, 4                 # Next Pixel
    subi $t3, $t3, 1
    bgtz $t3, erase_stoplay_col
    
    # Jump to next line
    add   $t1, $t1, $t9
    subi $t2, $t2, 1
    bgtz $t2, erase_stoplay_row

    jr    $ra

# =================================================================
# SUBROUTINES: SCORE DISPLAY
# =================================================================

# -----------------------------------------------------------------
# Function: Show_OnScreen_Score
# Purpose:  Takes the score, divides by 100, and draws 10 digits
#           formatted like "0000000521" centered above Game Over.
# -----------------------------------------------------------------
Show_OnScreen_Score:
    addi  $sp, $sp, -16
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)        # Holds the remaining score value
    sw    $s1, 8($sp)        # Loop counter
    sw    $s2, 12($sp)       # Current X position

    # 1. Prepare Score (Divide by 100 as per your logic)
    lw    $t0, score
    li    $t1, 100
    div   $t0, $t1
    mflo  $s0                # $s0 = Real Score (e.g., 521)

    # 2. Calculate X Position to start drawing (Working Right-to-Left)
    # We want 10 digits. Each is 5px wide + 1px gap = 6px total width.
    # Total width = 60px. Center of screen is 128.
    # Start Left X = 128 - 30 = 98.
    # End Right X  = 98 + (9 * 6) = 152.
    li    $s2, 152           # Start drawing at the rightmost digit position
    li    $t9, 3             # Y Position (Fixed)

    # 3. Loop 10 times to draw 10 digits
    li    $s1, 10            # Counter

Score_Loop:
    # Get the last digit: digit = number % 10
    li    $t0, 10
    div   $s0, $t0
    mfhi  $t1                # $t1 = Digit (0-9)
    mflo  $s0                # $s0 = Remaining number (number / 10)

    # Look up the sprite address in digit_table
    la    $t2, digit_table
    sll   $t1, $t1, 2        # Multiply index by 4 (word size)
    add   $t2, $t2, $t1
    lw    $a1, 0($t2)        # $a1 = Address of sprite_X

    # Draw the digit
    move  $a0, $s2           # Set X
    move  $a2, $t9           # Set Y
    jal   Gfx_DrawDigit

    # Move Cursor Left for the next digit
    subi  $s2, $s2, 6        # 5px width + 1px spacing
    
    # Decrement Loop
    subi  $s1, $s1, 1
    bgtz  $s1, Score_Loop

    # Restore and Return
    lw    $s2, 12($sp)
    lw    $s1, 8($sp)
    lw    $s0, 4($sp)
    lw    $ra, 0($sp)
    addi  $sp, $sp, 16
    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_DrawDigit
# Purpose:  Draws a 5x7 digit sprite.
#           Special Handling: The digits provided use 
#           0x00FFFFFF for White (Visible) and 0x00000000 for Black (Transparent).
# Inputs:   $a0 = X, $a2 = Y, $a1 = Sprite Address
# -----------------------------------------------------------------
Gfx_DrawDigit:
    li    $t1, MMIO_VIDEO_BASE
    
    # Calculate Screen Address: Base + (Y * 256 + X) * 4
    mul   $t5, $a2, SCREEN_WIDTH
    add   $t5, $t5, $a0
    sll   $t5, $t5, 2
    add   $t1, $t1, $t5      # $t1 = VRAM Pointer

    move  $t0, $a1           # $t0 = Sprite Pointer
    li    $t2, 7             # Height = 7 rows
    
    # Calculate screen offset to jump to next line (256 width - 5 sprite width) * 4
    li    $t8, 251            
    sll   $t8, $t8, 2        # $t8 = 1004 bytes skip

row_digit_loop:
    li    $t3, 5             # Width = 5 pixels

col_digit_loop:
    lw    $t4, 0($t0)        # Load Pixel from Sprite
    
    # Check Transparency: If pixel is Black (0), do not draw
    beqz  $t4, skip_digit_pixel 
    
    # If pixel is not black, draw it
    sw    $t4, 0($t1)        

skip_digit_pixel:
    addi  $t0, $t0, 4        # Next Sprite Pixel
    addi  $t1, $t1, 4        # Next Screen Pixel
    subi  $t3, $t3, 1
    bgtz  $t3, col_digit_loop

    # End of Row: Wrap to next line
    add   $t1, $t1, $t8      # Jump screen pointer
    subi  $t2, $t2, 1
    bgtz  $t2, row_digit_loop

    jr    $ra

# -----------------------------------------------------------------
# Function: Gfx_DrawSun
# Purpose:  Draws the Sun sprite at specific X, Y coordinates.
# Inputs:   $a0 = X, $a2 = Y, $a1 = Sprite Address
# -----------------------------------------------------------------
Gfx_DrawSun:
    # 1. Calculate Screen Start Address
    # Address = Base + (Y * ScreenWidth + X) * 4
    li    $t1, MMIO_VIDEO_BASE
    mul   $t5, $a2, SCREEN_WIDTH    # Y * Width
    add   $t5, $t5, $a0             # + X
    sll   $t5, $t5, 2               # * 4 (Bytes)
    add   $t1, $t1, $t5             # $t1 = Screen Pointer

    # 2. Setup Data
    move  $t0, $a1                  # $t0 = Sprite Pointer
    li    $t2, SUN_HEIGHT           # FIX: Changed lw to li
    li    $s1, SUN_WIDTH            # FIX: Changed lw to li

    # 3. Calculate "Stride" (Offset to jump to next line)
    # Stride = (Screen_Width - Sprite_Width) * 4 bytes
    li    $t8, SCREEN_WIDTH
    sub   $t8, $t8, $s1             
    sll   $t8, $t8, 2               

sun_draw_row:
    move  $t3, $s1                  # Reset width counter for this row

sun_draw_col:
    lw    $t4, 0($t0)               # Load pixel from sprite
    sw    $t4, 0($t1)               # Draw pixel to screen
    
    addi  $t0, $t0, 4               # Next Sprite Pixel
    addi  $t1, $t1, 4               # Next Screen Pixel
    subi  $t3, $t3, 1
    bgtz  $t3, sun_draw_col         # Continue column loop

    # End of Row: Jump to start of next line
    add   $t1, $t1, $t8             # Add stride
    subi  $t2, $t2, 1
    bgtz  $t2, sun_draw_row         # Continue row loop

    jr    $ra