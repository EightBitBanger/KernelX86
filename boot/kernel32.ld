ENTRY(_start32)

PHDRS
{
  text PT_LOAD FLAGS(5);
  data PT_LOAD FLAGS(6);
}

SECTIONS
{
  . = KERNEL32_ADDR;

  .text : {
    *(.text*)
  } :text

  .rodata : {
    *(.rodata*)
  } :text

  .data : {
    *(.data*)
  } :data

  .bss : {
    *(COMMON)
    *(.bss*)
  } :data
}
