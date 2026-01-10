bits 32

global isr_stub_table
extern isr_handler

; Exceptions that push an error code:
;  8  (#DF)
; 10  (#TS)
; 11  (#NP)
; 12  (#SS)
; 13  (#GP)
; 14  (#PF)
; 17  (#AC)
; 21  (#CP)  (Control Protection, if present)
;
; Everything else: we push a fake 0 error code so the C handler sees a uniform frame.

%macro ISR_NOERR 1
global isr_stub_%1
isr_stub_%1:
    push dword 0          ; error_code
    push dword %1         ; vector
    jmp isr_common
%endmacro

%macro ISR_ERR 1
global isr_stub_%1
isr_stub_%1:
    ; CPU already pushed error_code
    push dword %1         ; vector
    jmp isr_common
%endmacro

isr_common:
    ; Stack on entry (top -> bottom):
    ;  vector
    ;  error_code
    ;  eip
    ;  cs
    ;  eflags
    ;
    ; We call: isr_handler(vector, error_code, eip, cs, eflags)

    pushad

    ; Grab original values from the stack.
    ; After pushad, ESP moved by 32 bytes, so we reference [esp + 32 + ...]
    mov eax, [esp + 32 + 0]   ; vector
    mov ebx, [esp + 32 + 4]   ; error_code
    mov ecx, [esp + 32 + 8]   ; eip
    mov edx, [esp + 32 + 12]  ; cs
    mov esi, [esp + 32 + 16]  ; eflags

    ; Push args right-to-left (cdecl)
    push esi                  ; eflags
    push edx                  ; cs
    push ecx                  ; eip
    push ebx                  ; error_code
    push eax                  ; vector
    call isr_handler
    add esp, 20

    popad

    ; Clean up our pushed vector + (real or fake) error_code:
    add esp, 8

    iretd

; ---- Generate stubs 0..255 ----

; 0..7 no error code
ISR_NOERR 0
ISR_NOERR 1
ISR_NOERR 2
ISR_NOERR 3
ISR_NOERR 4
ISR_NOERR 5
ISR_NOERR 6
ISR_NOERR 7

ISR_ERR   8
ISR_NOERR 9
ISR_ERR   10
ISR_ERR   11
ISR_ERR   12
ISR_ERR   13
ISR_ERR   14
ISR_NOERR 15
ISR_NOERR 16
ISR_ERR   17
ISR_NOERR 18
ISR_NOERR 19
ISR_NOERR 20
ISR_ERR   21
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_NOERR 29
ISR_NOERR 30
ISR_NOERR 31

%assign vec 32
%rep 224
    ISR_NOERR vec
%assign vec vec+1
%endrep

; Table of stub addresses used by idt.c
isr_stub_table:
%assign idx 0
%rep 256
    dd isr_stub_%+idx
%assign idx idx+1
%endrep
