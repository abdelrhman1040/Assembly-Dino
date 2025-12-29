# =================================================================
# MODULE: LOGIC & PHYSICS
# DESCRIPTION: Handles Input, Physics, Game State, and Collision.
# =================================================================

# -----------------------------------------------------------------
# Procedure: Update_Game_Logic
# Purpose:   Master function that runs all logic for one frame.
#            1. Checks Input
#            2. Updates Dino Physics
#            3. Updates Obstacle Movement
#            4. Checks Collisions
# Returns:   Updates state variables in memory. 
#            If collision occurs, it JUMPS to Game_Over (does not return).
# -----------------------------------------------------------------
Update_Game_Logic:
    # Save $ra just in case we make nested calls (though usually we jump)
    addi  $sp, $sp, -4
    sw    $ra, 0($sp)

    # --- 1. Input Handling ---
    # Check MMIO Control Bit
    li    $t0, MMIO_KEY_CTRL
    lw    $t1, 0($t0)
    andi  $t1, $t1, 1             
    beqz  $t1, Logic_PhysicsStep  # No input, proceed to physics

    # Check MMIO Data (Key Value)
    li    $t0, MMIO_KEY_DATA
    lw    $t1, 0($t0)

    # Check for 's' to START game
    beq   $t1, 115, Input_StartGame   # 115 = 's'
    b     Input_CheckJump             # Check for Spacebar

Input_StartGame:
    lw    $t2, state_game_active
    bnez  $t2, Logic_PhysicsStep      # If already active, ignore
    
    # ACTIVATE GAME
    li    $t2, 1
    sw    $t2, state_game_active
    
    # Erase STOPLAY Logo
    li    $a0, STOPLAY_X
    li    $a2, STOPLAY_Y
    jal   Gfx_EraseStoplay
    b     Logic_PhysicsStep

Input_CheckJump:
    bne   $t1, 32, Logic_PhysicsStep  # 32 = Spacebar
    bnez  $s3, Logic_PhysicsStep      # Ignore if already jumping
    
    # Start Jump
    jal   Play_Sound_Jump
    li    $s3, 1                      # Set Jump Flag
    move  $s4, $s7                    # Store Jump Start Time ($s7 is current time from main)

Logic_PhysicsStep:
    # --- 2. Dino Physics (Parabolic) ---
    beqz  $s3, Logic_DinoOnGround         
    
    # Calculate time elapsed (t)
    sub   $t0, $s7, $s4               
    
    # Load Physics Config
    lw    $t1, cfg_jump_duration      # T
    lw    $t2, cfg_jump_height        # H

    # Check if jump ended
    bge   $t0, $t1, Logic_DinoLand
    
    # Parabolic Formula: Y = (4 * H * t * (T - t)) / T^2
    sub   $t3, $t1, $t0               # (T - t)
    mul   $t4, $t0, $t3               # t * (T-t)
    sll   $t5, $t2, 2                 # 4 * H
    mul   $t6, $t5, $t4               # Numerator
    mul   $t7, $t1, $t1               # Denominator (T^2)
    div   $t6, $t7                    
    mflo  $t8                         # Calculated Y Offset
    
    # Apply height relative to ground
    li    $t9, POS_GROUND_Y
    sub   $t9, $t9, $t8               
    sw    $t9, state_dino_y_next             
    j     Logic_ObstacleStep

Logic_DinoLand:
    li    $s3, 0                      # Reset Jump Flag
    li    $t5, POS_GROUND_Y        
    sw    $t5, state_dino_y_next
    j     Logic_ObstacleStep

Logic_DinoOnGround:
    li    $t5, POS_GROUND_Y        
    sw    $t5, state_dino_y_next

Logic_ObstacleStep:
    # --- 3. Obstacle Logic ---
    # If Game Not Active, disable obstacles
    lw    $t0, state_game_active
    beqz  $t0, Logic_ObstacleIdle 

    lw    $t0, state_obst_active
    bnez  $t0, Logic_MoveObstacle

    # Spawn Check
    lw    $t1, state_last_spawn
    sub   $t2, $s7, $t1                
    lw    $t3, state_next_delay
    blt   $t2, $t3, Logic_ObstacleIdle 
    
    # Activate Obstacle
    li    $t0, 1
    sw    $t0, state_obst_active
    li    $t0, 256
    sw    $t0, state_obst_x_next
    j     Logic_Collisions

Logic_ObstacleIdle:
    li    $t0, 256
    sw    $t0, state_obst_x_next
    j     Logic_Collisions

Logic_MoveObstacle:
    # Move X left by current speed
    lw    $t2, state_obst_x_curr              
    lw    $t1, cfg_speed_curr         
    sub   $t2, $t2, $t1               
    
    # Boundary Check (Off-screen left)
    li    $t3, -32                      
    bge   $t2, $t3, Logic_FinalizeObstacle
    
    # --- Reset Obstacle (Passed Screen) ---
    li    $t0, 0
    sw    $t0, state_obst_active
    li    $t2, 256                      
    
    # Clean Left Edge Artifacts (Visual cleanup)
    sw    $t1, -4($sp)                # Save temp
    jal   Gfx_CleanLeftBoundary
    lw    $t1, -4($sp)                # Restore temp
    
    sw    $t2, state_obst_x_curr              
    sw    $s7, state_last_spawn
          
    # Random Sprite Selection
    li    $v0, 42                     # Syscall: Random Int Range
    li    $a0, 0                      # ID
    li    $a1, 2                      # Range [0, 2)
    syscall
    
    beqz   $a0, Select_Sprite_1
    la     $t0, sprite_obstacle_2
    j      Store_Sprite_Selection
    
Select_Sprite_1:
    la     $t0, sprite_obstacle

Store_Sprite_Selection:
    sw     $t0, state_obst_sprite_addr
   
    # Calculate Next Random Spawn Delay
    lw     $a1, cfg_spawn_rng_ms        
    li     $v0, 42
    syscall
    lw     $t0, cfg_spawn_min_ms        
    add    $a0, $a0, $t0                 
    sw     $a0, state_next_delay

Logic_FinalizeObstacle:
    sw     $t2, state_obst_x_next       

Logic_Collisions:
    # --- 4. Collision Detection ---
    # Safety: If Game not active, skip
    lw     $t0, state_game_active
    beqz   $t0, Logic_Return

    # Load Positions
    lw     $t0, state_obst_x_curr       
    lw     $t1, state_dino_y_curr       

    # Check X Range: (5 < x < 28)
    ble    $t0, 5, Logic_Return      # Safe (behind dino)
    bge    $t0, 28, Logic_Return     # Safe (ahead of dino)

    # Check Y Range: (86 < y < 91)
    ble    $t1, 86, Logic_Return     # Safe (Dino jumping high enough)

    # >>> COLLISION DETECTED >>>
    j      Game_Over

Logic_Return:
    lw    $ra, 0($sp)
    addi  $sp, $sp, 4
    jr    $ra

# =================================================================
# GAME OVER ROUTINE (Terminal State)
# =================================================================
Game_Over:
    # 1. SETUP OBSTACLE DRAWING (Manual Clipping for Crash Scene)
    lw     $a0, state_obst_x_curr     
    li     $t0, OBST_WIDTH
    li     $t1, 0                     # Sprite Offset X
    li     $t2, SCREEN_WIDTH

    # Clipping Logic
    bltz   $a0, GO_Clip_Left
    addi   $t3, $a0, OBST_WIDTH
    bgt    $t3, SCREEN_WIDTH, GO_Clip_Right
    j      GO_Store_Params

GO_Clip_Left:
    sub    $t1, $zero, $a0
    addi   $t0, $a0, OBST_WIDTH
    li     $a0, 0
    j      GO_Store_Params

GO_Clip_Right:
    sub    $t0, $t2, $a0

GO_Store_Params:
    # Calculate VRAM Address for Crash Obstacle
    li     $t4, MMIO_VIDEO_BASE
    li     $t5, POS_OBSTACLE_Y
    mul    $t5, $t5, SCREEN_WIDTH
    add    $t5, $t5, $a0
    sll    $t5, $t5, 2
    add    $t4, $t4, $t5
    sw     $t4, buf_render_addr

    # Calculate Sprite Source
    lw     $t5, state_obst_sprite_addr
    mul    $t6, $t1, 4
    add    $t5, $t5, $t6
    sw     $t5, buf_sprite_addr

    # Store Width
    sw     $t0, buf_render_width

    # Draw Obstacle (No Erase)
    jal    Gfx_DrawObstacle

    # 2. DRAW DINO (On top of rock)
    li     $a0, POS_DINO_X             
    lw     $a2, state_dino_y_curr      

    li     $t0, POS_GROUND_Y
    beq    $a2, $t0, GO_DrawRun        
    la     $a1, sprite_dino_jump       
    j      GO_ExecuteDraw
GO_DrawRun:
    la     $a1, sprite_dino_run_1      
GO_ExecuteDraw:
    jal    Gfx_DrawDino

    # 3. Play Crash Sound
    jal    Play_Sound_Crash

    # 4. Draw "Game Over" Sprite (Centered)
    # X = (256 - 69) / 2 = 93
    li     $a0, 93
    # Y = (128 - 40) / 2 = 44
    li     $a2, 44
    jal    Gfx_DrawGameOver
    
    # 5. Draw On-Screen Score
    jal    Show_OnScreen_Score
    
    # 6. Draw "Press S to Start"
    li     $a0, STOPLAY_X              
    li     $a2, STOPLAY_Y           
    jal    Gfx_Drawstoplay
    
    # 7. Console Debug Message
    li     $v0, 4
    la     $a0, msg_final_score
    syscall

    lw     $t0, score          
    li     $t1, 100            
    div    $t0, $t1            
    mflo   $a0                 
    li     $v0, 1              
    syscall
    
    # 8. Infinite Loop (Freeze)
Freeze:
    li    $t0, 0xFFFF0000        # keyboard status

freeze_wait:
    lw    $t1, 0($t0)            
    beq   $t1, $zero, freeze_wait     

    lw    $t2, 4($t0)            # read char
    li    $t3, 's'               
    beq   $t2, $t3, main         # RESTART GAME (Jumps back to main.asm)

    j     freeze_wait
