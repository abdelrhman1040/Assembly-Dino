# =================================================================
# PROJECT: DINO RUN (MIPS ASSEMBLY)
# FILE: main.asm (Entry Point)
#GitHub: https://github.com/abdelrhman1040/Assembly-Dino.git
# =================================================================

.data

# -----------------------------------------------------------------
# 1. INCLUDE SPRITESs
# -----------------------------------------------------------------
# Must be included first so labels are available
.include "sprites.asm"

# -----------------------------------------------------------------
# 2. CONSTANTS (.eqv)
# -----------------------------------------------------------------
.eqv COLOR_SKY          0x87CEEB    # Sky Blue
.eqv COLOR_HORIZON      0x006400    # Dark Green
.eqv COLOR_GROUND       0x32CD32    # Light Green
.eqv COLOR_TRANSPARENT  0x00FFFFFF  # Transparency Key (White)
.eqv COLOR_RED          0xFF0000    # Game Over Color

.eqv SCREEN_WIDTH       256       
.eqv SCREEN_HEIGHT      128         
.eqv SPRITE_WIDTH       24             
.eqv SPRITE_HEIGHT      25             
.eqv OBST_WIDTH         32             
.eqv OBST_HEIGHT        19             

# Memory Mapped I/O
.eqv MMIO_VIDEO_BASE    0x10040000
.eqv MMIO_KEY_CTRL      0xffff0000
.eqv MMIO_KEY_DATA      0xffff0004

# Entity Fixed Positions
.eqv POS_DINO_X         5       
.eqv POS_GROUND_Y       91    
.eqv POS_OBSTACLE_Y     97    

# Logo & Sun Dimensions
.eqv STOPLAY_WIDTH      69
.eqv STOPLAY_HEIGHT     5
.eqv STOPLAY_X          93
.eqv STOPLAY_Y          80

.eqv GAMEOVER_WIDTH     69          
.eqv GAMEOVER_HEIGHT    40          

# Sun Dimensions 
.eqv SUN_WIDTH          32
.eqv SUN_HEIGHT         31

# -----------------------------------------------------------------
# 3. GLOBAL VARIABLES
# -----------------------------------------------------------------

# Strings
str_debug_fps:     .asciiz " FPS: "
str_newline:       .asciiz "\n"
msg_final_score:   .asciiz "\nGame Over! Final Score: "

# Configuration: Physics & Difficulty
cfg_jump_duration: .word 700   # Total jump time in ms
cfg_jump_height:   .word 45    # Max jump height in pixels

# Speed Control
cfg_speed_curr:    .word 2     # Current pixels per frame
cfg_speed_max:     .word 15    # Max speed cap
cfg_speed_next_ts: .word 0     # Timestamp for next speed increase
cfg_speed_inc_int: .word 5000  # Interval (ms) to increase speed

# Spawn Control
cfg_spawn_min_ms:  .word 1000  # Min time between obstacles
cfg_spawn_rng_ms:  .word 1500  # Random variance

# Animation Control
cfg_anim_base_del: .word 250   # Base animation delay (ms)
cfg_anim_speed_fac:.word 15    # Animation speed scaling factor

# Game State Variables
state_dino_y_curr: .word 97
state_dino_y_next: .word 97
state_obst_x_curr: .word 256
state_obst_x_next: .word 256
state_obst_active: .word 0     # 0 = Idle, 1 = Moving
state_last_spawn:  .word 0     # Timestamp of last spawn
state_next_delay:  .word 0     # Calculated delay
state_obst_sprite_addr: .word sprite_obstacle 

state_game_active: .word 0     # 0 = Menu, 1 = Playing
score:             .word 0     

# System State
sys_frame_count:   .word 0
sys_fps_timer:     .word 0
sys_time_curr:     .word 0     # Current frame timestamp
sys_time_prev:     .word 0     # Previous frame timestamp

# Rendering Buffers (Shared with graphics.asm)
buf_render_addr:   .word 0     
buf_sprite_addr:   .word 0     
buf_render_width:  .word 0     

.eqv STOPLAY_X     93
.eqv STOPLAY_Y     80
# =================================================================
# TEXT SECTION (MAIN LOGIC)
# =================================================================
.text
.globl main

# =================================================================
# MAIN ENTRY POINT
# =================================================================
main:
    # 1. Initialize Static Graphics
    jal Init_StaticBackground 
    
    # 2. Draw "STOPLAY" Logo initially
    li    $a0, STOPLAY_X
    li    $a2, STOPLAY_Y
    jal   Gfx_Drawstoplay

    # 3. Initialize Game State
    sw    $zero, state_game_active
    
    # 4. Initialize System Timers
    li    $v0, 30                 # Get System Time
    syscall 
    move $s6, $a0                 # $s6 = Main Loop Timer Base
    sw    $a0, state_last_spawn   
    sw    $a0, sys_fps_timer
    sw    $zero, sys_frame_count

    # 5. Initialize Difficulty
    lw    $t0, cfg_speed_inc_int
    add   $t0, $t0, $s6           
    sw    $t0, cfg_speed_next_ts

    # 6. Initialize First Spawn Delay
    lw    $a1, cfg_spawn_rng_ms
    li    $v0, 42                 
    syscall
    lw    $t0, cfg_spawn_min_ms    
    add   $a0, $a0, $t0
    sw    $a0, state_next_delay

    # 7. Initialize Registers & Positions
    li    $s2, 0                  
    li    $s3, 0                  # Jump Flag
    li    $s4, 0                  # Jump Start Time
    li    $s5, 0                  # Dead Flag

    li    $t0, POS_GROUND_Y
    sw    $t0, state_dino_y_curr
    sw    $t0, state_dino_y_next
    li    $t0, 256
    sw    $t0, state_obst_x_curr
    sw    $t0, state_obst_x_next
    sw    $zero, score            
    li    $t0, 2                  
    sw    $t0, cfg_speed_curr     

    # Jump to loop
    j     Game_Loop

# =================================================================
# MAIN GAME LOOP
# =================================================================
Game_Loop:
    
    # --- 1. Delta Time Calculation ---
    li    $v0, 30
    syscall
    move $s7, $a0                 # $s7 = Current Frame Timestamp
    sub   $t9, $s7, $s6           # $t9 = Delta Time
    move $s6, $s7                 # Reset loop timer

    # --- 2. Update Score & Difficulty ---
    lw    $t8, state_game_active  
    beqz $t8, Skip_Score_And_Diff 

    # Score Update
    lw    $t0, score                
    lw    $t1, cfg_speed_curr       
    add   $t0, $t0, $t1             
    sw    $t0, score                

    # Difficulty Progression
    lw    $t0, cfg_speed_next_ts
    blt   $s7, $t0, Skip_Score_And_Diff      

    # Set next increase time
    lw    $t1, cfg_speed_inc_int
    add   $t0, $s7, $t1
    sw    $t0, cfg_speed_next_ts

    # Increase Speed
    lw    $t2, cfg_speed_curr
    lw    $t3, cfg_speed_max
    bge   $t2, $t3, Skip_Score_And_Diff 
    
    addi $t2, $t2, 1              
    sw   $t2, cfg_speed_curr              

Skip_Score_And_Diff:
    # --- 3. FPS Debug (Optional) ---
    lw    $t0, sys_frame_count
    addi $t0, $t0, 1
    sw    $t0, sys_frame_count
    
    lw    $t1, sys_fps_timer
    sub   $t2, $s7, $t1
    blt   $t2, 1000, System_SkipFPSPrint
    
    # Print FPS
    li    $v0, 4
    la    $a0, str_debug_fps
    syscall
    li    $v0, 1
    lw    $a0, sys_frame_count
    syscall
    li    $v0, 4
    la    $a0, str_newline
    syscall
    
    sw    $zero, sys_frame_count
    sw    $s7, sys_fps_timer
    
System_SkipFPSPrint:

    # =============================================================
    # LOGIC UPDATE (Call Module)
    # =============================================================
    # This updates state variables but DOES NOT draw
    jal   Update_Game_Logic

    # =============================================================
    # RENDER PREPARATION (CLIPPING)
    # =============================================================
    # We prepare clipping data for the *Next* frame position of the obstacle
    lw    $a0, state_obst_x_next          
    li    $t0, OBST_WIDTH             
    li    $t1, 0                     # Sprite Offset X
    li    $t2, SCREEN_WIDTH                   
    
    # Check Left Clipping
    bltz $a0, Clip_Left
    # Check Right Clipping
    addi $t3, $a0, OBST_WIDTH
    bgt   $t3, SCREEN_WIDTH, Clip_Right
    j     Store_RenderParams

Clip_Left:
    sub   $t1, $zero, $a0            # Offset start into sprite
    addi $t0, $a0, OBST_WIDTH        # Remaining width to draw
    li    $a0, 0                     # Screen X = 0
    j     Store_RenderParams

Clip_Right:
    sub   $t0, $t2, $a0              # Width = ScreenWidth - X
    
Store_RenderParams:
    # 1. Calculate VRAM Address
    li    $t4, MMIO_VIDEO_BASE
    li    $t5, POS_OBSTACLE_Y
    mul   $t5, $t5, SCREEN_WIDTH            
    add   $t5, $t5, $a0               
    sll   $t5, $t5, 2                 
    add   $t4, $t4, $t5
    sw    $t4, buf_render_addr
    
    # 2. Calculate Sprite Source Address
    lw    $t5, state_obst_sprite_addr
    mul   $t6, $t1, 4                 
    add   $t5, $t5, $t6
    sw    $t5, buf_sprite_addr
    
    # 3. Store Width
    sw    $t0, buf_render_width

    # =============================================================
    # DRAWING PHASE 
    # =============================================================
    
    # 1. Erase Old Obstacle (at curr X)
    lw    $a0, state_obst_x_curr      
    jal   Gfx_EraseObstacle

    # 2. Draw New Obstacle (at next X, using params above)
    jal   Gfx_DrawObstacle

    # 3. Erase Old Dino
    li    $a0, POS_DINO_X           
    lw    $a2, state_dino_y_curr
    jal   Gfx_EraseDino

    # 4. Draw New Dino
    li    $a0, POS_DINO_X           
    lw    $a2, state_dino_y_next
    
    # --- Dino Animation Logic ---
    lw    $t0, state_dino_y_next
    bne   $t0, POS_GROUND_Y, Anim_JumpFrame
    
    # Sync Animation Speed
    lw    $t5, cfg_anim_base_del            
    lw    $t6, cfg_speed_curr       
    lw    $t7, cfg_anim_speed_fac            
    mul   $t8, $t6, $t7              
    sub   $t1, $t5, $t8              # New Delay

    # Clamp min delay
    li    $t9, 30                     
    bge   $t1, $t9, Anim_SkipClamp
    move $t1, $t9                     
Anim_SkipClamp:

    # Toggle Frame
    divu $s7, $t1                 
    mflo $t0
    andi $t0, $t0, 1                 
    
    beqz $t0, Anim_RunFrame1
    la    $a1, sprite_dino_run_2
    j     Anim_ExecuteDraw
Anim_RunFrame1:
    la    $a1, sprite_dino_run_1
    j     Anim_ExecuteDraw
Anim_JumpFrame:
    la    $a1, sprite_dino_jump        
Anim_ExecuteDraw:
    jal   Gfx_DrawDino              

    # 5. Commit State (Next becomes Curr)
    lw    $t0, state_dino_y_next
    sw    $t0, state_dino_y_curr
    lw    $t0, state_obst_x_next
    sw    $t0, state_obst_x_curr

    # =============================================================
    # FRAME CAP (TARGET 60 FPS)
    # =============================================================
    li    $v0, 30
    syscall
    sub   $t0, $a0, $s7             # Processing time
    li    $t1, 16                   # 16ms target
    sub   $a0, $t1, $t0             
    blez $a0, Loop_End          
    li    $v0, 32                   # Sleep
    syscall
Loop_End:
    j     Game_Loop

# =================================================================
# INCLUDE MODULES
# =================================================================
# IMPORTANT: These must be at the END of the file so execution
# starts at 'main' and doesn't fall through into subroutines.

.include "graphics.asm"
.include "logic.asm"
.include "sound.asm"
