#include "print.h"
#include "io.h"

#define VGA_TEXT_ADDR   0xB8000u
#define VGA_COLS        80u
#define VGA_ROWS        25u

static volatile uint16_t* const vga_addr = (volatile uint16_t*)VGA_TEXT_ADDR;

static uint8_t cursor_x = 0;
static uint8_t cursor_y = 0;


static void vga_set_cursor_pos(uint8_t x, uint8_t y) {
    uint16_t pos = (uint16_t)y * (uint16_t)VGA_COLS + (uint16_t)x;

    io_write(0x3D4, 0x0F);
    io_write(0x3D5, (uint8_t)(pos & 0xFF));

    io_write(0x3D4, 0x0E);
    io_write(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

static void vga_set_cursor_shape(uint8_t start_scanline, uint8_t end_scanline) {
    io_write(0x3D4, 0x0A);
    uint8_t curStart = io_read(0x3D5);
    io_write(0x3D5, (uint8_t)((curStart & 0xC0u) | (start_scanline & 0x1Fu)));

    io_write(0x3D4, 0x0B);
    io_write(0x3D5, (uint8_t)(end_scanline & 0x1Fu));
}

void vga_cursor_disable(void) {
    io_write(0x3D4, 0x0A);
    io_write(0x3D5, 0x20);
}

void vga_cursor_enable_underscore(void) {
    vga_set_cursor_shape(14, 15);
}

void console_set_cursor(uint8_t x, uint8_t y) {
    if (x >= VGA_COLS) x = VGA_COLS - 1;
    if (y >= VGA_ROWS) y = VGA_ROWS - 1;

    cursor_x = x;
    cursor_y = y;
    vga_set_cursor_pos(cursor_x, cursor_y);
}

void put_char_at(uint8_t x, uint8_t y, char ch, uint8_t color) {
    uint16_t cell = (uint16_t)ch | ((uint16_t)color << 8);
    vga_addr[(uint16_t)y * (uint16_t)VGA_COLS + (uint16_t)x] = cell;
}

static void newline(void) {
    cursor_x = 0;
    if (cursor_y + 1 < (uint8_t)VGA_ROWS) {
        cursor_y++;
        return;
    }

    for (uint16_t row = 1; row < VGA_ROWS; row++) {
        for (uint16_t col = 0; col < VGA_COLS; col++) {
            vga_addr[(row - 1) * VGA_COLS + col] = vga_addr[row * VGA_COLS + col];
        }
    }

    for (uint16_t col = 0; col < VGA_COLS; col++) {
        vga_addr[(VGA_ROWS - 1) * VGA_COLS + col] = (uint16_t)' ' | ((uint16_t)0x0Fu << 8);
    }
}

static void backspace(void) {
    if (cursor_x == 0) {
        if (cursor_y == 0) 
            return;
        cursor_y--;
        cursor_x = (uint8_t)(VGA_COLS - 1);
    } else {
        cursor_x--;
    }
    put_char_at(cursor_x, cursor_y, ' ', 0x0Fu);
}

void vga_screen_clear(void) {
    for (uint16_t row = 0; row < VGA_ROWS; row++) {
        for (uint16_t col = 0; col < VGA_COLS; col++) {
            vga_addr[row * VGA_COLS + col] = (uint16_t)' ' | ((uint16_t)0x0Fu << 8);
        }
    }

    cursor_x = 0;
    cursor_y = 0;
    vga_set_cursor_pos(cursor_x, cursor_y);
}

void print(const char* str) {
    if (!str) return;

    while (*str) {
        char ch = *str++;

        if (ch == '\n') {
            newline();
            continue;
        }
        if (ch == '\r') {
            cursor_x = 0;
            continue;
        }
        if (ch == '\t') {
            uint8_t next = (uint8_t)((cursor_x + 4u) & ~3u);
            while (cursor_x < next) {
                put_char_at(cursor_x, cursor_y, ' ', 0x0Fu);
                cursor_x++;
                if (cursor_x >= VGA_COLS) {
                    newline();
                    break;
                }
            }
            continue;
        }
        if (ch == '\b') {
            backspace();
            continue;
        }

        put_char_at(cursor_x, cursor_y, ch, 0x0Fu);
        cursor_x++;

        if (cursor_x >= VGA_COLS) {
            newline();
        }
    }

    vga_set_cursor_pos(cursor_x, cursor_y);
}
