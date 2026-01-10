#include <stdint.h>
#include "keyboard.h"
#include "io.h"

uint8_t kb_has_data(void) {
    return (io_read(0x64) & 0x01u) != 0;
}

uint8_t kb_read_scancode(void) {
    return io_read(0x60);
}
