#ifndef INTERRUPT_DESCRIPTOR_TABLE_H
#define INTERRUPT_DESCRIPTOR_TABLE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void idt_init(void);

void isr_handler(uint32_t vector, uint32_t error_code, uint32_t eip, uint32_t cs, uint32_t eflags);

#ifdef __cplusplus
}
#endif

#endif
