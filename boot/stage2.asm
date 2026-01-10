bits 16
org 0x0000

start:
    cli

    ; stage2 is loaded at CS=0x1000 (physical 0x10000)
    ; DS must match CS so [gdt_desc] points at the right memory.
    mov ax, cs
    mov ds, ax

    ; Simple stack (interrupts remain disabled until we have an IDT)
    xor ax, ax
    mov ss, ax
    mov sp, 0x9000

    call enable_a20

    ; Patch GDTR.base = (CS<<4) + gdt
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, gdt
    mov dword [gdt_desc + 2], eax

    ; Patch far jump target to linear address of pm_entry
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, pm_entry
    mov dword [pm_far_jmp + 2], eax   ; offset32 field

    lgdt [gdt_desc]

    mov eax, cr0
    or  eax, 1
    mov cr0, eax

    ; Far jump to flush prefetch queue and load CS selector 0x08.
pm_far_jmp:
    db 0x66, 0xEA          ; jmp ptr16:32
    dd 0                   ; patched above: linear address of pm_entry
    dw 0x08                ; code segment selector

; 32-bit protected mode
bits 32
pm_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9FC00

    ; Jump to the 32-bit kernel entry at an absolute linear address.
    mov eax, KERNEL32
    jmp eax

.hang:
    cli
    hlt
    jmp .hang

; Aux functions
bits 16
enable_a20:
    in  al, 0x92
    or  al, 2
    out 0x92, al
    ret

align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF

gdt_desc:
    dw gdt_end - gdt - 1
    dd 0
gdt_end:

%ifndef KERNEL32
%define KERNEL32 0x00000000
%endif
