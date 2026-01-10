#ifndef PRINT_H
#define PRINT_H

#include <stdint.h>

void print(const char* str);

void vga_screen_clear(void);
void vga_set_cursor(uint8_t x, uint8_t y);
void vga_cursor_disable(void);
void vga_cursor_enable(void);

void put_char_at(uint8_t x, uint8_t y, char ch, uint8_t color);

#endif
