#include "idt.h"
#include "print.h"

typedef struct __attribute__((packed)) {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  zero;
    uint8_t  type_attr;
    uint16_t offset_high;
} idt_entry_t;

typedef struct __attribute__((packed)) {
    uint16_t limit;
    uint32_t base;
} idt_ptr_t;

static idt_entry_t g_idt[256];
static idt_ptr_t   g_idtr;

extern uint32_t isr_stub_table[256];

static void idt_set_gate(uint32_t index, uint32_t handler_addr) {
    idt_entry_t* entry = &g_idt[index];

    entry->offset_low  = (uint16_t)(handler_addr & 0xFFFF);
    entry->selector    = 0x08;      /* kernel code segment */
    entry->zero        = 0;
    entry->type_attr   = 0x8E;      /* present, ring0, 32-bit interrupt gate */
    entry->offset_high = (uint16_t)((handler_addr >> 16) & 0xFFFF);
}

static void idt_load(const idt_ptr_t* idtr) {
    __asm__ __volatile__("lidt (%0)" :: "r"(idtr));
}

void idt_init(void) {
    for (uint32_t index = 0; index < 256; index++) {
        idt_set_gate(index, isr_stub_table[index]);
    }

    g_idtr.limit = (uint16_t)(sizeof(g_idt) - 1);
    g_idtr.base  = (uint32_t)(uintptr_t)&g_idt[0];

    idt_load(&g_idtr);
}

/* Minimal default handler: print vector + halt forever */
static char hex_digit(uint32_t value) {
    value &= 0xF;
    if (value < 10) return (char)('0' + value);
    return (char)('A' + (value - 10));
}

static void print_hex32(uint32_t value) {
    char buffer[11];
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint32_t nibble = 0; nibble < 8; nibble++) {
        uint32_t shift = (7 - nibble) * 4;
        buffer[2 + nibble] = hex_digit(value >> shift);
    }
    buffer[10] = 0;
    print(buffer);
}

void isr_handler(uint32_t vector,
                 uint32_t error_code,
                 uint32_t eip,
                 uint32_t cs,
                 uint32_t eflags) {
    (void)cs;
    (void)eflags;

    print("\nEXCEPTION vector=");
    print_hex32(vector);
    print(" err=");
    print_hex32(error_code);
    print(" eip=");
    print_hex32(eip);
    print("\nHALT\n");

    __asm__ __volatile__("cli");
    for (;;) {
        __asm__ __volatile__("hlt");
    }
}
