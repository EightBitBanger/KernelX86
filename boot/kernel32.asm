bits 32
global _start32
extern kmain

section .text
_start32:
    cli

    ; Mask PIC so hardware IRQs (timer etc.) don't fire until we're ready.
    mov al, 0xFF
    out 0x21, al
    out 0xA1, al

    ; Install a minimal IDT (all entries zero for now).
    ; This prevents 'random' garbage IDT state; still keep IRQs masked.
    lidt [idt_desc]

    call kmain

.hang:
    cli
    hlt
    jmp .hang

section .data
align 16
idt:
    times 256 dq 0

idt_desc:
    dw idt_end - idt - 1
    dd idt
idt_end:
