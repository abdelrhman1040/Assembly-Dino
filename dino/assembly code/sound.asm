# =================================================================
# MODULE: SOUND
# DESCRIPTION: Handles MIDI sound effects (Jump beep & Crash melody).
# =================================================================

# -----------------------------------------------------------------
# Function: Play_Sound_Jump
# Purpose:  Plays a short high-pitched beep when jumping.
#           Instrument: Marimba (12) for an arcade feel.
# -----------------------------------------------------------------
Play_Sound_Jump:
    li    $v0, 31        # Service 31: MIDI Out
    li    $a0, 75        # Pitch (0-127): 75 is a high note
    li    $a1, 100       # Duration: 100 ms
    li    $a2, 12        # Instrument: 12 (Marimba)
    li    $a3, 100       # Volume (0-127)
    syscall
    jr    $ra

# -----------------------------------------------------------------
# Function: Play_Sound_Crash (Mario Death Style)
# Purpose:  Plays a descending melody resembling Mario's death sound.
#           Uses syscall 32 (Sleep) to separate notes.
#           Instrument: Square Wave (80) for NES/Retro style.
# -----------------------------------------------------------------
Play_Sound_Crash:
    # Save $ra because we use syscall 32 which *might* clobber temp registers 
    # (though usually safe, it's good practice in complex melodies)
    # But here simple leaf function logic applies since syscalls are kernel traps.
    
    # --- Note 1 (High E) ---
    li    $v0, 31        # MIDI Out
    li    $a0, 76        # Pitch (E)
    li    $a1, 100       # Duration (ms)
    li    $a2, 80        # Instrument: 80 (Square Wave)
    li    $a3, 127       # Volume (Max)
    syscall

    # Wait a bit
    li    $v0, 32        # Sleep
    li    $a0, 100       # 100ms delay
    syscall

    # --- Note 2 (C) ---
    li    $v0, 31
    li    $a0, 72        # Pitch (C)
    li    $a1, 100
    li    $a2, 80
    li    $a3, 127
    syscall

    # Wait
    li    $v0, 32
    li    $a0, 100
    syscall

    # --- Note 3 (A) ---
    li    $v0, 31
    li    $a0, 69        # Pitch (A)
    li    $a1, 100
    li    $a2, 80
    li    $a3, 127
    syscall

    # Wait
    li    $v0, 32
    li    $a0, 100
    syscall

    # --- Note 4 (Low E - Long) ---
    li    $v0, 31
    li    $a0, 64        # Pitch (Low E)
    li    $a1, 400       # Longer duration
    li    $a2, 80
    li    $a3, 127
    syscall
    
    # Wait for the final note to finish before returning control
    # This prevents the Game Over screen from appearing instantly while sound plays
    li    $v0, 32
    li    $a0, 400
    syscall

    jr    $ra