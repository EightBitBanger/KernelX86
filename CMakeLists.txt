cmake_minimum_required(VERSION 3.20)


project(tinyos C ASM_NASM)

set(KERNEL_SECTORS 32)
set(STAGE2_PAD     4096)

find_program(NASM             nasm             REQUIRED)
find_program(I686_ELF_GCC     i686-elf-gcc     REQUIRED)
find_program(I686_ELF_OBJCOPY i686-elf-objcopy REQUIRED)

math(EXPR KERNEL32_ADDR "0x10000 + ${STAGE2_PAD}")

# Convert build dir to a stable CMake-style path (forward slashes).
file(TO_CMAKE_PATH "${CMAKE_BINARY_DIR}" B)

set(OUT_BOOT_BIN      "${B}/boot/boot.bin")
set(OUT_STAGE2_BIN    "${B}/stage2.bin")
set(OUT_ISR_OBJ       "${B}/kernel/isr.o")
set(OUT_K32_ENTRY_OBJ "${B}/k32_entry.o")
set(OUT_KERNEL32_ELF  "${B}/kernel32.elf")
set(OUT_KERNEL32_BIN  "${B}/kernel32.bin")
set(OUT_IMGTOOL_EXE   "${B}/imgtool.exe")
set(OUT_OS_IMG        "${B}/os.img")

# -------------------------
# Kernel C translation units
# Add more .c files here.
# -------------------------
set(KERNEL_C_SOURCES
    kernel/keyboard.c
    kernel/console.c
    kernel/print.c
    kernel/kstring.c
    kernel/kernel.c
    kernel/idt.c
    kernel/io.c
)

set(KERNEL_C_OBJS)

foreach(src IN LISTS KERNEL_C_SOURCES)
    get_filename_component(src_we "${src}" NAME_WE)
    set(obj "${B}/${src_we}.o")

    add_custom_command(
        OUTPUT "${obj}"
        COMMAND "${I686_ELF_GCC}"
                -m32
                -ffreestanding
                -fno-pic -fno-pie -fno-plt
                -fno-stack-protector
                -nostdlib -nostartfiles -nodefaultlibs
                -O2 -Wall -Wextra
                -c "${CMAKE_SOURCE_DIR}/${src}"
                -o "${obj}"
        DEPENDS "${CMAKE_SOURCE_DIR}/${src}"
        VERBATIM
    )

    list(APPEND KERNEL_C_OBJS "${obj}")
endforeach()

# ---- boot sector (bin) ----
add_custom_command(
    OUTPUT "${OUT_BOOT_BIN}"
    COMMAND "${NASM}" -f bin "${CMAKE_SOURCE_DIR}/boot/boot.asm" -o "${OUT_BOOT_BIN}"
    DEPENDS "${CMAKE_SOURCE_DIR}/boot/boot.asm"
    VERBATIM
)

# ---- stage2 (bin) ----
add_custom_command(
    OUTPUT "${OUT_STAGE2_BIN}"
    COMMAND "${NASM}" -f bin -D KERNEL32=${KERNEL32_ADDR} "${CMAKE_SOURCE_DIR}/boot/stage2.asm" -o "${OUT_STAGE2_BIN}"
    DEPENDS "${CMAKE_SOURCE_DIR}/boot/stage2.asm"
    VERBATIM
)

# ---- 32-bit entry (elf32 obj) ----
add_custom_command(
    OUTPUT "${OUT_K32_ENTRY_OBJ}"
    COMMAND "${NASM}" -f elf32 "${CMAKE_SOURCE_DIR}/boot/kernel32.asm" -o "${OUT_K32_ENTRY_OBJ}"
    DEPENDS "${CMAKE_SOURCE_DIR}/boot/kernel32.asm"
    VERBATIM
)

# ---- ISR stub table + common handler glue (elf32 obj) ----
add_custom_command(
    OUTPUT "${OUT_ISR_OBJ}"
    COMMAND "${NASM}" -f elf32 "${CMAKE_SOURCE_DIR}/kernel/isr.asm" -o "${OUT_ISR_OBJ}"
    DEPENDS "${CMAKE_SOURCE_DIR}/kernel/isr.asm"
    VERBATIM
)

# ---- link kernel32.elf -> kernel32.bin ----
add_custom_command(
    OUTPUT "${OUT_KERNEL32_BIN}"
    COMMAND "${I686_ELF_GCC}"
            -m32
            -nostdlib -nostartfiles -nodefaultlibs
            "-Wl,-T,${CMAKE_SOURCE_DIR}/boot/kernel32.ld"
            "-Wl,--defsym,KERNEL32_ADDR=${KERNEL32_ADDR}"
            "-Wl,-Map,${B}/kernel32.map"
            -o "${OUT_KERNEL32_ELF}"
            "${OUT_K32_ENTRY_OBJ}" "${OUT_ISR_OBJ}" ${KERNEL_C_OBJS}
    COMMAND "${I686_ELF_OBJCOPY}" -O binary "${OUT_KERNEL32_ELF}" "${OUT_KERNEL32_BIN}"
    DEPENDS "${OUT_K32_ENTRY_OBJ}" "${OUT_ISR_OBJ}" ${KERNEL_C_OBJS} "${CMAKE_SOURCE_DIR}/boot/kernel32.ld"
    VERBATIM
    COMMAND_EXPAND_LISTS
)

# ---- imgtool (host tool, OK to build with MinGW gcc.exe) ----
add_custom_command(
    OUTPUT "${OUT_IMGTOOL_EXE}"
    COMMAND "${CMAKE_C_COMPILER}" -O2 "${CMAKE_SOURCE_DIR}/tools/imgtool.c" -o "${OUT_IMGTOOL_EXE}"
    DEPENDS "${CMAKE_SOURCE_DIR}/tools/imgtool.c"
    VERBATIM
)

# ---- build disk image ----
add_custom_command(
    OUTPUT "${OUT_OS_IMG}"
    COMMAND "${OUT_IMGTOOL_EXE}"
            "${OUT_BOOT_BIN}"
            "${OUT_STAGE2_BIN}"
            "${OUT_KERNEL32_BIN}"
            "${STAGE2_PAD}"
            "${KERNEL_SECTORS}"
            "${OUT_OS_IMG}"
    DEPENDS "${OUT_IMGTOOL_EXE}" "${OUT_BOOT_BIN}" "${OUT_STAGE2_BIN}" "${OUT_KERNEL32_BIN}"
    VERBATIM
)

add_custom_target(image ALL DEPENDS "${OUT_OS_IMG}")
