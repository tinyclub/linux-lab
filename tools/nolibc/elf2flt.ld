/* This linker script is used to produce a tighter ELF program in preparation
   for conversion to the flat format.  It takes inputs (e.g. ELF objects) and
   arranges their sections in the order the runtime expects.  See the GNU linker
   script documentation for more details on the file format.
   https://sourceware.org/binutils/docs/ld/Scripts.html

   It is dynamically processed by ld-elf2flt before being passed to GNU ld which
   links the final ELF image (which is then passed to elf2flt to create the flat
   program).

   The "elf2flt.ld.in" file has @FOO@ symbols replaced when the elf2flt project
   itself is built.  These should ideally be kept to a minimum to make it easier
   to read & understand this script.

   The lines below that start with "FOO:" tags are custom ld-elf2flt logic and
   *not* part of the linker script language.  When ld-elf2flt runs, based on its
   flags, it will either delete the entire line or the tag itself.

   The tags currently defined are as follows (in no particular order).

   R_RODAT:
   W_RODAT:
     By default, the read-only data (.rodata) input sections are placed into the
     writable output data segment (via the output .data section) and before any
     other input data sections.  The -move-rodata option moves the .rodata input
     to the read-only output text segment (via the output .text section).

     Thus, R_RODAT lines are kept by default, while W_RODAT lines are removed.

   TOR:
     The --enable-emit-ctor-dtor configure setting.

     By default, all TOR lines are removed.

   SINGLE_LINK:
     The --disable-emit-relocs configure setting.

     By default, all SINGLE_LINK are kept.
 */

ENTRY (_start)

MEMORY {
	flatmem : ORIGIN = 0x0, LENGTH = 0xfffffff
}

PHDRS {
	text PT_LOAD ;
	data PT_LOAD ;
}

SECTIONS {

	.text 0x0 : {
		. = . + 4;
		. = ALIGN(0x4) ;
		_stext = . ;
		*(.literal .text)
		*(.literal.* .text.*)
		*(.gnu.warning)
		*(.stub)
		*(.gnu.linkonce.literal.*)
		*(.gnu.linkonce.t*)
		*(.glue_7t)
		*(.glue_7)
		*(.jcr)
		*(.init.literal)
		KEEP (*(.init))
		*(.fini.literal)
		KEEP (*(.fini))

		*(.rodata)
		*(.rodata1)
		*(.rodata.*)
		*(.gnu.linkonce.r*)

		/* .ARM.extab name sections containing exception unwinding information */
		*(.ARM.extab* .gnu.linkonce.armextab.*)
		/* This is special code area at the end of the normal
		   text section.  It contains a small lookup table at
		   the start followed by the code pointed to by entries
		   in the lookup table.  */
		. = ALIGN (4) ;
		PROVIDE(__ctbp = .);
		*(.call_table_data)
		*(.call_table_text)
	} > flatmem :text

	/* .ARM.exidx name sections containing index entries for section unwinding */
	/* .ARM.exidx is sorted, so has to go in its own output section.  */
	__exidx_start = .;
	.ARM.exidx :
	{
		*(.ARM.exidx* .gnu.linkonce.armexidx.*)
	} > flatmem
	__exidx_end = .;
	_etext = . ;

	.data ALIGN(0x20): {
		_sdata = . ;
		__data_start = . ;
		data_start = . ;
		*(.got.plt)
		*(.got)
		FILL(0) ;
		. = ALIGN(0x20) ;
		LONG(-1)
		. = ALIGN(0x20) ;
		__global_pointer$ = . + 0x800 ;
		*(.data)
		*(.data1)
		*(.data.*)
		*(.gnu.linkonce.d*)

		/* Microblaze has .sdata and .sbss (small bss).  They must
		   be contiguous, so please don't move any of this. JW */
		_ssrw = . ;
		*(.sdata)
		*(.sdata.*)
		*(.sbss)			/* Don't move this! */
		*(.gnu.linkonce.sb*)
		_essrw = . ;

		_ssrw_size = _essrw - _ssrw;
		PROVIDE(_SDA_BASE_ = _ssrw + (_ssrw_size / 2));

		*(.gnu.linkonce.s.*)
		*(__libc_atexit)
		*(__libc_subinit)
		*(__libc_subfreeres)

		/* microblaze-specific read-only small data area
		   and associated locating symbols */
		_ssro = . ;
		*(.sdata2)
		_essro = . ;
		_ssro_size = _essro - _ssro;
		PROVIDE(_SDA2_BASE_ = _ssro + (_ssro_size / 2));

		. = ALIGN(4) ;

		PROVIDE (__preinit_array_start = .);
		KEEP (*(.preinit_array))
		PROVIDE (__preinit_array_end = .);

		PROVIDE (__init_array_start = .);
		KEEP (*(SORT(.init_array.*)))
		KEEP (*(.init_array))
		PROVIDE (__init_array_end = .);

		PROVIDE (__fini_array_start = .);
		KEEP (*(.fini_array))
		KEEP (*(SORT(.fini_array.*)))
		PROVIDE (__fini_array_end = .);
	} > flatmem :data

	.note.ABI-tag : { *(.note.ABI-tag) } > flatmem
	.eh_frame_hdr : { *(.eh_frame_hdr) } > flatmem
	.eh_frame : { KEEP(*(.eh_frame)) } > flatmem
	.gcc_except_table : {
		KEEP(*(.gcc_except_table))
		KEEP(*(.gcc_except_table.*))
	} >flatmem

	. = ALIGN(0x10) ;
	_edata = . ;

	.bss : {
		. = ALIGN(0x4) ;
		_sbss = ALIGN(0x4) ;
		__bss_start = . ;
		*(.dynsbss)
		*(.sbss)
		*(.sbss.*)
		*(.scommon)
		*(.dynbss)
		*(.bss)
		*(.bss.*)
		*(.bss*)
		*(.gnu.linkonce.b*)
		*(COMMON)
		. = ALIGN(0x10) ;
		_ebss = . ;
		_end = . ;
		end = . ;
	} > flatmem

	.stack : {
		. = ALIGN(0x4);
		_stack_start = .;
	} > flatmem

	.junk 0 : { *(.rel*) *(.rela*) }
	/DISCARD/ : { *(.note.GNU-stack) }
	/* Stabs debugging sections.    */
	.stab 0 : { *(.stab) }
	.stabstr 0 : { *(.stabstr) }
	.stab.excl 0 : { *(.stab.excl) }
	.stab.exclstr 0 : { *(.stab.exclstr) }
	.stab.index 0 : { *(.stab.index) }
	.stab.indexstr 0 : { *(.stab.indexstr) }
	.comment 0 : { *(.comment) }
	/* DWARF debug sections.
	   Symbols in the DWARF debugging sections are relative to the beginning
	   of the section so we begin them at 0.  */
	/* DWARF 1 */
	.debug          0 : { *(.debug) }
	.line           0 : { *(.line) }
	/* GNU DWARF 1 extensions */
	.debug_srcinfo  0 : { *(.debug_srcinfo) }
	.debug_sfnames  0 : { *(.debug_sfnames) }
	/* DWARF 1.1 and DWARF 2 */
	.debug_aranges  0 : { *(.debug_aranges) }
	.debug_pubnames 0 : { *(.debug_pubnames) }
	/* DWARF 2 */
	.debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
	.debug_abbrev   0 : { *(.debug_abbrev) }
	.debug_line     0 : { *(.debug_line) }
	.debug_frame    0 : { *(.debug_frame) }
	.debug_str      0 : { *(.debug_str) }
	.debug_loc      0 : { *(.debug_loc) }
	.debug_macinfo  0 : { *(.debug_macinfo) }
	/* SGI/MIPS DWARF 2 extensions */
	.debug_weaknames 0 : { *(.debug_weaknames) }
	.debug_funcnames 0 : { *(.debug_funcnames) }
	.debug_typenames 0 : { *(.debug_typenames) }
	.debug_varnames  0 : { *(.debug_varnames) }
}
