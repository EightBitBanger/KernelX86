bits 16
org 0x7C00

; Loads the next KERNEL_SECTORS sectors from disk using INT 13h extensions (LBA)
; into 0x1000:0000 (physical 0x10000), then jumps there.

KERNEL_LOAD_SEG  equ 0x1000
KERNEL_LOAD_OFF  equ 0x0000
KERNEL_SECTORS   equ 32

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    ; --- Check INT 13h Extensions present (EDD) ---
    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, [boot_drive]
    int 0x13
    jc  no_ext
    cmp bx, 0xAA55
    jne no_ext
    test cx, 0x0001
    jz  no_ext

    ; --- Build Disk Address Packet (DAP) ---
    mov word [dap_sectors], KERNEL_SECTORS
    mov word [dap_off],     KERNEL_LOAD_OFF
    mov word [dap_seg],     KERNEL_LOAD_SEG
    mov dword [dap_lba_lo], 1          ; LBA 1 = sector immediately after boot sector
    mov dword [dap_lba_hi], 0

    ; --- Read sectors using AH=42h ---
    mov si, dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc  disk_error

    jmp KERNEL_LOAD_SEG:KERNEL_LOAD_OFF

no_ext:
    mov si, err_noext
    jmp print_and_halt

disk_error:
    mov si, err_disk
    jmp print_and_halt

print_and_halt:
.print:
    lodsb
    test al, al
    jz  .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

boot_drive db 0

err_noext db "No INT13h extensions (LBA)!", 13, 10, 0
err_disk  db "Disk read error (LBA)!", 13, 10, 0

; Disk Address Packet (DAP)
dap:
    db 0x10              ; size
    db 0x00              ; reserved
dap_sectors:
    dw 0                 ; sectors
dap_off:
    dw 0                 ; buffer offset
dap_seg:
    dw 0                 ; buffer segment
dap_lba_lo:
    dd 0                 ; LBA low dword
dap_lba_hi:
    dd 0                 ; LBA high dword

times 510-($-$$) db 0
dw 0xAA55
