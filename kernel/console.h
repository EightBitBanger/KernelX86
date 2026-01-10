#ifndef CONSOLE_H
#define CONSOLE_H

#include <stdint.h>

void console_init(void);

void console_handle_scancode(uint8_t scancode);
void console_prompt(void);

#endif
