
; Print a string
; si = Pointer to the string
console_print:
    lodsb                ; Load the next byte from the string into AL
    cmp al, 0            ; Check for null terminator
    je .print_return     ; If zero, we're done
    mov ah, 0x0E         ; BIOS teletype output function
    mov bl, 0x0f         ; Attribute color
    int 0x10             ; Call BIOS interrupt
    jmp console_print    ; Repeat for next character
.print_return:
    ret                  ; Return from the print function
    
    
; Set the console cursor position
; dl - Position
; dh - Line
console_set_position:
    mov ah, 0x02        ; Function to set cursor position
    mov bh, 0           ; Page number
    int 0x10            ; Call BIOS interrupt
    ret
    
    
; Set console text and background color
; bl = Color attribute
console_set_color:
    mov ah, 0x0B        ; Function to set background and foreground color
    mov bh, 0           ; Page number (0)
    int 0x10            ; Call BIOS interrupt
    ret
    
    
; Clear the display
console_clear_screen:
    
    ; Set video mode text 80 x 25
    mov ax, 0x0003
    int 0x10
    
    mov ah, 0x0C        ; Function to write character and attribute
    mov al, ' '         ; Character to write (space)
    mov bh, 0           ; Page number (0)
    mov cx, 80 * 25     ; Number of characters to write (80 columns * 25 rows)
    int 0x10            ; Call BIOS interrupt to fill the screen
    
    ret
    
    
    ; Compare two strings of a given length
; Inputs:
;   DS:SI -> Pointer to the first string
;   DS:DI -> Pointer to the second string
;   CX    -> Length of the strings to compare
; Output:
;   Returns 0 if strings are equal, non-zero if they are different

string_compare:
    ; Check if the length is zero (CX == 0)
    ; If so, they are equal by default
    cmp cx, 0
    je .equal
    
.compare_loop:
    mov al, [si]
    mov bl, [di]
    
    cmp al, bl
    
    jne .different
    
    inc si
    inc di
    
    dec cx
    jnz .compare_loop
    
.equal:
    ; Strings are equal (return 0)
    xor ax, ax
    ret
    
.different:
    ; Strings are different (return non-zero)
    mov ax, 1
    ret
    
    
