
; Function to wait for a key press
wait_for_key: 
    xor ah, ah           ; BIOS function 00 (get key)
    int 0x16             ; Call BIOS interrupt
    ret
    
    
; Function to print a character to the screen
print_character:
    ; The character is in AL after wait_for_key
    mov ah, 0x0E        ; BIOS teletype function
    int 0x10            ; Print the character in AL
    ret
    
    
    
