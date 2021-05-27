GameLoop:
    ; Loop will bounce the ball from side to side,
    ; the player must hit the right button when the ball is in the last slot on each end
    call DrawScore
    call DrawBall
    call WaitForInputs
    call ResetPresses

    ld a, [BALL_SLOT] ; Current slot
    cp 1
    jr z, .slot1      ; If current slot == 1 jump to .slot1
    cp 6
    jr z, .slot6      ; Else If current slot == 6 jump to .slot6
.otherSlot            ; Else the rest of the slots are treated the same way
    ; If the player got a hit in a non end slot then its game over
    ld a, [LEFT_HIT]
    cp 0
    jp nz, GameOver
    ld a, [RIGHT_HIT]
    cp 0
    jp nz, GameOver
    ; Otherwise the ball continues
    ld a, [BALL_DIRECTION]
    cp 1
    jr z, .slotRight
    jr .slotLeft
.slot1
    ; If the player doesn't get a hit in an end slot then its game over
    ld a, [LEFT_HIT]
    cp 0
    jp z, GameOver
    ; Otherwise reset the hit and the ball continues
    call ResetHit

    ld a, 1
    ld [BALL_DIRECTION], a
    call IncrementScore
    jr .slotRight
.slot6
    ; If the player doesn't get a hit in an end slot then its game over
    ld a, [RIGHT_HIT]
    cp 0
    jp z, GameOver
    call ResetHit

    xor a ; let a == 0
    ld [BALL_DIRECTION], a
    call IncrementScore
    jr .slotLeft
.slotLeft
    ld a, [BALL_SLOT]
    dec a
    ld [BALL_SLOT], a
    call UpdateBallPostion
    jr GameLoop
.slotRight
    ld a, [BALL_SLOT]
    inc a
    ld [BALL_SLOT], a
    call UpdateBallPostion
    jr GameLoop

WaitForInputs:
    ld a, [BALL_DELAY]  ; Lower delay == faster ball
    ld b, a
.loop:
    halt
    nop

    call .setHits

    dec b
    ld a, b
    cp 0
    jr nz, .loop

    ret

.setHits
    call ReadKeys
    push af ; Store key status so it can be used twice
    and KEY_A
    cp 0
    call nz, SetRightHit
    pop af
    and KEY_LEFT
    cp 0
    call nz, SetLeftHit
    ret

;Modifies AF
SetLeftHit:
    ld a, [LEFT_STILL_PRESSED] ; If the player hasn't lifted the key yet, don't set a hit
    cp 1
    ret z

    ld a, 1
    ld [LEFT_HIT], a
    ld [LEFT_STILL_PRESSED], a
    ret

;Modifies AF
SetRightHit:
    ld a, [RIGHT_STILL_PRESSED] ; If the player hasn't lifted the key yet, don't set a hit
    cp 1
    ret z

    ld a, 1
    ld [RIGHT_HIT], a
    ld [RIGHT_STILL_PRESSED], a
    ret

;Modifies AF
ResetHit:
    xor a
    ld [LEFT_HIT], a
    ld [RIGHT_HIT], a
    ret

;Modifies AF
ResetPresses:
    call ReadKeys
    push af ; Store key status so it can be used twice
    and KEY_A
    cp 0
    call z, .resetRightPress ; Only clear the press tracker if the button isn't currently pressed
    pop af
    and KEY_LEFT
    cp 0
    call z, .resetLeftPress ; Only clear the press tracker if the button isn't currently pressed
    ret
.resetRightPress
    xor a
    ld [RIGHT_STILL_PRESSED], a
    ret
.resetLeftPress
    xor a
    ld [LEFT_STILL_PRESSED], a
    ret

; Modifies ABCDE
DrawScore:
    ld a, [SCORE]
    ld b, $65 ; tile number of 0 character on the title screen
    ld c, 0   ; draw to background
    ld d, 9   ; X position
    ld e, 3  ; Y position
    call RenderTwoDecimalNumbers
    ret

; Modifies AF
UpdateBallPostion:
    ld a, [BALL_SLOT]
    cp 6
    jr z, .slot6
    cp 5
    jr z, .slot5
    cp 4
    jr z, .slot4
    cp 3
    jr z, .slot3
    cp 2
    jr z, .slot2
    cp 1
    jr z, .slot1
.slot6
    ld a, BALL_SLOT_6
    jr .write
.slot5
    ld a, BALL_SLOT_5
    jr .write
.slot4
    ld a, BALL_SLOT_4
    jr .write
.slot3
    ld a, BALL_SLOT_3
    jr .write
.slot2
    ld a, BALL_SLOT_2
    jr .write
.slot1
    ld a, BALL_SLOT_1
.write
    ld [BALL_POSITION], a

    ret

; Modifies AF
DrawBall:

    ; Write y positions
    ld a, BALL_HEIGHT        ; Y location
    ld [SPRITES_START], a    ; Top Left
    ld [SPRITES_START+4], a  ; Top Middle
    ld [SPRITES_START+8], a  ; Top Right
    add 8                    ; The bottom row is 8 pixels down
    ld [SPRITES_START+12], a ; Bottom Left
    ld [SPRITES_START+16], a ; Bottom Middle
    ld [SPRITES_START+20], a ; Bottom Right

    ; Write x positions
    ld a, [BALL_POSITION]    ; X location
    ld [SPRITES_START+1], a  ; Top Left
    ld [SPRITES_START+13], a ; Bottom Left
    add 8                    ; Middle column is 8 pixels across
    ld [SPRITES_START+5], a  ; Top Middle
    ld [SPRITES_START+17], a ; Bottom Middle
    add 7                    ; Right column is 7 pixels across
    ld [SPRITES_START+9], a  ; Top Right
    ld [SPRITES_START+21], a ; Bottom Right

    ; Write sprite numbers
    ld a, TOP_WHOLE_BALL_PART
    ld [SPRITES_START+2], a  ; Top Left
    ld [SPRITES_START+6], a  ; Top Middle

    ld a, TOP_HALF_BALL_PART
    ld [SPRITES_START+10], a ; Top Right

    ld a, BOTTOM_WHOLE_BALL_PART
    ld [SPRITES_START+14], a ; Bottom Left
    ld [SPRITES_START+18], a ; Bottom Middle

    ld a, BOTTOM_HALF_BALL_PART
    ld [SPRITES_START+22], a ; Bottom Right

    ld a, %10000             ; Flags - Use alt palette
    ld [SPRITES_START+3], a
    ld [SPRITES_START+7], a
    ld [SPRITES_START+11], a
    ld [SPRITES_START+15], a
    ld [SPRITES_START+19], a
    ld [SPRITES_START+23], a

    ret

; Modifies AF
IncrementScore:
    ld a, [SCORE]
    inc a
    daa
    ld [SCORE], a
    call IncreaseSpeed
    ret

; Modifies AF
IncreaseSpeed: ; If the score matches any of the cutoffs below the speed will increase
    ld a, [SCORE]
    cp $2
    jr z, .increase
    cp $4
    jr z, .increase
    cp $6
    jr z, .increase
    cp $8
    jr z, .increase
    cp $10
    jr z, .increase
    cp $12
    jr z, .increase
    cp $15
    jr z, .increase
    cp $20
    jr z, .increase
    cp $25
    jr z, .increase
    cp $30
    jr z, .increase
    cp $40
    jr z, .increase
    cp $50
    jr z, .increase
    cp $60
    jr z, .increase
    cp $70
    jr z, .increase
    cp $80
    jr z, .increase
    cp $90
    jr z, .increase
    ret
.increase
    ld a, [BALL_DELAY]
    dec a
    ld [BALL_DELAY], a
    ret

GameOver:
; Compare player's score with high score and save new high score if it's higher 
    ld a, [SCORE]
    ld b, a 
    
    call EnableSaveData
    ld a, [SRAM_HIGH_SCORE]
    
    cp b 
    call c, .newHighScore
    
    call DisableSaveData
    
    ; Resets the game  
    jp GingerBreadBegin 
    
; Local function for writing high score to SRAM     
.newHighScore:
    ld a, b 
    ld [SRAM_HIGH_SCORE], a 
    ret
