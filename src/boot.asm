[bits 16]
section .text
    
    org 0x7C00
    
start:
    
    mov ah, 0x02        ; BIOS function to read sectors
    
    mov al, 1           ; Number of sectors to read
    mov ch, 0           ; Cylinder
    mov cl, 2           ; Sector (2)
    mov dh, 0           ; Head
    
    mov bx, 0x0200      ; Load from address
    
    int 0x13            ; Call BIOS to read sector
    
    jmp 0x0200          ; Jump to the loaded kernel
    
; Fill the remaining space with zeros (to make the bootloader exactly 512 bytes)
times 510 - ($ - $$) db 0
dw 0xAA55              ; Boot signature

