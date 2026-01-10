#ifndef KEYBOARD_H
#define KEYBOARD_H

uint8_t kb_has_data(void);
uint8_t kb_read_scancode(void);

uint8_t kb_in(uint16_t port);

void kb_out(uint16_t port, uint8_t value);

#endif
