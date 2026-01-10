#include <stdint.h>

#include "idt.h"
#include "keyboard.h"
#include "print.h"
#include "console.h"

void kmain(void) {
    idt_init();
    vga_screen_clear();
    
    console_init();
    
    print("kernel 0.0.1\n\n");
    console_prompt();
    
    while (1) {
        if (!kb_has_data())
            continue;
        
        console_handle_scancode(kb_read_scancode());
    }
}
