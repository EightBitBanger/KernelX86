#include "console.h"
#include "commands.h"
#include "print.h"
#include "kstring.h"

static const char scancode_to_ascii[128] = {
    0,  27, '1','2','3','4','5','6','7','8','9','0','-','=', '\b',
    '\t','q','w','e','r','t','y','u','i','o','p','[',']','\n', 0,
    'a','s','d','f','g','h','j','k','l',';','\'','`', 0,'\\',
    'z','x','c','v','b','n','m',',','.','/', 0, '*', 0, ' '
};

void k_memset(char* dst, char v, unsigned int count) {
    for (unsigned int i = 0; i < count; i++)
        dst[i] = v;
}


#define CONSOLE_LINE_MAX 128

static char line[CONSOLE_LINE_MAX];
static unsigned int line_len;

static void console_putc(char c) {
    char out[2] = { c, 0 };
    print(out);
}

void console_prompt(void) {
    print("c>");
}

static void console_backspace(void) {
    if (line_len == 0)
        return;

    line_len--;
    line[line_len] = 0;

    print("\b \b");
}

static void console_push_char(char c) {
    if (line_len + 1 >= CONSOLE_LINE_MAX)
        return;

    line[line_len++] = c;
    line[line_len] = 0;
    console_putc(c);
}

static const char* skip_spaces(const char* s) {
    while (*s == ' ' || *s == '\t')
        s++;
    return s;
}

static unsigned int token_len(const char* s) {
    unsigned int i = 0;
    while (s[i] && s[i] != ' ' && s[i] != '\t')
        i++;
    return i;
}

static void console_execute(const char* input) {
    const char* s = skip_spaces(input);
    if (*s == 0)
        return;

    unsigned int len = token_len(s);

    char cmd[32];
    if (len >= sizeof(cmd))
        len = sizeof(cmd) - 1;

    for (unsigned int i = 0; i < len; i++)
        cmd[i] = s[i];
    cmd[len] = 0;

    const char* args = skip_spaces(s + len);

    for (unsigned int i = 0; i < command_count; i++) {
        if (kstreq(cmd, commands[i].name)) {
            commands[i].fn(args);
            return;
        }
    }

    print("Bad command or filename\n\n");
}


void console_init(void) {
    k_memset(line, 0, sizeof(line));
    line_len = 0;
}

void console_handle_scancode(uint8_t scancode) {
    if (scancode & 0x80)
        return;

    char ch = scancode_to_ascii[scancode];
    if (!ch)
        return;

    if (ch == '\n') {
        print("\n");
        console_execute(line);
        k_memset(line, 0, sizeof(line));
        line_len = 0;
        console_prompt();
        return;
    }

    if (ch == '\b') {
        console_backspace();
        return;
    }

    if (ch == '\t') {
        console_push_char(' ');
        return;
    }

    if (ch == 27) { /* ESCAPE */
        return;
    }

    console_push_char(ch);
}
