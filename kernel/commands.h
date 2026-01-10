#include <stdint.h>
#include "print.h"

static void cmd_clear_screen(const char* args);

struct Command {
    const char* name;
    const char* help;
    void (*fn)(const char*);
};

static const struct Command commands[] = {
    { "cls",    "Clear the screen",       cmd_clear_screen},
};

static const unsigned int command_count = sizeof(commands) / sizeof(commands[0]);

static void cmd_clear_screen(const char* args) {
    (void)args;
    vga_screen_clear();
}

