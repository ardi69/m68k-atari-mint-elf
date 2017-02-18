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
    LONG(0x4d694e54); /* MiNT */
    LONG(0);
    SHORT(0);
  }
  .text :
  {
    .text_start = .;

    LONG(0x203a001a);                  /* g_jump_entry[0] */
    LONG(0x4efb08fa);                  /* g_jump_entry[0] */
    LONG(0x108);                       /* e_info */
    LONG(.data_start - .entry );       /* e_text */
    LONG(.bss_start - .data_start );   /* e_data */
    LONG(.prg_end - .bss_start );      /* e_bss */
    LONG(0);                           /* e_syms */
    LONG(.entry);                      /* e_entry */
    . = . + 0x10;
    LONG(0);                           /* g_stkpos (filled from tostool) */
    LONG(1);                           /* g_symbol_format */
    . = . + 0xAC;
    .entry = .;

    /* slb_head + slb_exports */
    KEEP(*(.slb_head))
    LONG((.slb_export_end - .slb_export_start) / 4);
    .slb_export_start = .;
    KEEP(*(SORT(.gnu.linkonce.slb_export.*)))
    .slb_export_end = .;

    /* .text */
	*(.text)
    *(.text.unlikely .text.*_unlikely)
    *(.text.exit .text.exit.*)
    *(.text.startup .text.startup.*)
    *(.text.hot .text.hot.*)
    *(.text .stub .text.* .gnu.linkonce.t.*)
    *(.rodata .rodata.*)

    /* .ctors */
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
  }
  .data . :
  {
    _etext = .;
    __etext = .;
    .data_start = .;
    *(.data) *(.data.*) *(.gnu.linkonce.d.*) *(.gcc_except_table) *(.gcc_except_table.*)
    ___EH_FRAME_BEGIN__ = . ;
    *(.eh_fram*)
    ___EH_FRAME_END__ = . ;
  }
  .bss . :
  {
    _edata = .;
    __edata = .;
    .bss_start = .;
    *(.bss) *(COMMON) *(.bss.*) *(.gnu.linkonce.b.*)
    .prg_end = .;
  }
  _end = .;
  __end = .;
}
