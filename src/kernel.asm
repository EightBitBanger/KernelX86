[bits 16]
section .data
    
    keyboard_string db 32
    
    keyboard_string_length db 1
    
    
section .text
    
    org 0x0200
    
kernel_main:
    
    ; Initializer list
    mov byte [keyboard_string_length], 0
    
    call console_clear_screen
    
    ; Print kernel message
    mov si, msgKernelInitiate
    call console_print
    
    mov dl, 0 ; Position
    mov dh, 1 ; Line
    call console_set_position
    
    ; Print prompt
    mov si, msgConsolePrompt
    call console_print
    
    
loop:
    
; Get characters from the keyboard using int 16h (BIOS)
keyboard_check:
    mov ah, 00h        ; BIOS function to read a key
    int 16h            ; Character is returned in AL
    
    ; Enter pressed
    cmp al, 0Dh
    je keyboard_press_enter
    
    ; Add the character to the string
    lea di, [keyboard_string]
    mov bl, [keyboard_string_length]  ; Load current counter value
    add di, bx         ; Move DI to the correct position in the string
    
    mov [di], al       ; Store the character in the string buffer
    
    inc byte [keyboard_string_length]
    
    ; Print the character
    mov ah, 0x0E
    mov bl, 0x0f
    int 0x10
    
    jmp keyboard_check
    
    
keyboard_press_enter:
    
    ; Carriage return
    mov al, 0x0D
    mov ah, 0x0E
    mov bl, 0x0f
    int 0x10
    
    ; Line feed
    mov al, 10
    int 0x10
    
    ; Function lookup
    mov cx, [keyboard_string_length]
    lea si, [keyboard_string]
    
    ; Clear screen
    lea di, [command_cls]
    call string_compare
    
    cmp ax, 0                ; Check if result is 0 (equal)
    je command_cls_ptr       ; Jump if equal
    
    
command_return:
    
    ; Print prompt
    mov si, msgConsolePrompt
    call console_print
    
    mov byte [keyboard_string_length], 0
    
    jmp keyboard_check
    
    
    
    
    
    
command_cls_ptr:
    
    call console_clear_screen
    
    mov dl, 0
    mov dh, 0
    
    call console_set_position
    
    jmp command_return
    
    
%include "src/console.asm"
%include "src/keyboard.asm"
    
    
section .data
    
    command_cls db 'cls'
    
%include "src/strings.asm"
    
    
    
