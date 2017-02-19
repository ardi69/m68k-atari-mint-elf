/* Default linker script, for normal executables */
OUTPUT_FORMAT(elf32-m68k)
SECTIONS
{
  .mint_prg_info (INFO) :
  {
    SHORT(0x601a);
    LONG(.data_start - .text_start );
    LONG(.bss_start - .data_start );
    LONG(.prg_end - .bss_start );
    LONG(0);
    LONG(0);
    LONG(0);
    SHORT(0);
  }
  .text :
  {
    .text_start = .;
    .entry = .;
    KEEP(*(.text.entry.mint)) KEEP(*crt0*.o(.text)) KEEP(*startup.o(.text))
    .startup_size = . - .entry;

    *(.text.unlikely .text.*_unlikely)
    *(.text.exit .text.exit.*)
    *(.text.startup .text.startup.*)
    *(.text.hot .text.hot.*)
    *(.text .stub .text.* .gnu.linkonce.t.*)
    *(.rodata .rodata.*)

    /* .ctors */
    . = ALIGN(4);
    ___CTOR_LIST__ = .;
    LONG((___CTOR_END__ - ___CTOR_LIST__) / 4 - 2);
    KEEP (*(.ctors))
    KEEP (*(SORT(.ctors.*)))
    LONG(0);
    ___CTOR_END__ = .;
    /* .dtors */
   ___DTOR_LIST__ = .;
    LONG((___DTOR_END__ - ___DTOR_LIST__) / 4 - 2);
    KEEP (*(.dtors))
    KEEP (*(SORT(.dtors.*)))
    LONG(0);
    ___DTOR_END__ = .;
    ___EH_FRAME_BEGIN__ = . ;
    *(.eh_frame .eh_frame.*)
    ___EH_FRAME_END__ = . ;
  }
  .data . :
  {
    _etext = .;
    __etext = .;
    .data_start = .;
    *(.data) *(.data.*) *(.gnu.linkonce.d.*) *(.gcc_except_table) *(.gcc_except_table.*)
  }
  .bss . :
  {
    _edata = .;
    __edata = .;
    .bss_start = .;
    *(.bss) *(COMMON) *(.bss.*) *(.gnu.linkonce.b.*)
  }
  _end = .;
  __end = .;
  .prg_end = .;
}
