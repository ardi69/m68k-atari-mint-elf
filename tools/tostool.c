#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#pragma pack(push, 1)

#define TOSTOOL_VERSION "0.2.0"


#ifdef _MSC_VER
#	ifdef WIN32
#		define BIG_ENDIAN	4321
#		define LITTLE_ENDIAN	1234
#		define BYTE_ORDER	LITTLE_ENDIAN
#	elif !defined(BYTE_ORDER) || !defined(BIG_ENDIAN)
#		error "BYTE_ORDER and/or BIG_ENDIAN is not defined"
#	endif
#else
#	include <sys/param.h>
#endif
#ifndef MAX
//! Get the maximum of two values
#define MAX(a, b)	(((a) > (b)) ? (a) : (b))
#endif

#ifndef MIN
//! Get the minimum of two values
#define MIN(a, b)	(((a) < (b)) ? (a) : (b))
#endif

#define EI_NIDENT       16

typedef struct {
	unsigned char	e_ident[EI_NIDENT];
	uint16_t		e_type;
	uint16_t		e_machine;
	uint32_t		e_version;
	uint32_t		e_entry;
	uint32_t		e_phoff;
	uint32_t		e_shoff;
	uint32_t		e_flags;
	uint16_t		e_ehsize;
	uint16_t		e_phentsize;
	uint16_t		e_phnum;
	uint16_t		e_shentsize;
	uint16_t		e_shnum;
	uint16_t		e_shstrndx;
} Elf32_Ehdr;

#define EI_CLASS	4
#define EI_DATA		5
#define EI_VERSION	6
#define EI_PAD		7
#define EI_NIDENT	16

#define ELFCLASS32	1
#define ELFDATA2MSB	2
#define EV_CURRENT	1

#define ET_EXEC		2
#define EM_68K		4

#define SHT_SYMTAB	2
#define SHT_RELA	4

#define SHF_ALLOC	2

#define ELF32_R_TYPE(x) ((x) & 0xff)

// Reloc enum
#define START_RELOC_NUMBERS(name)   enum name {
#define RELOC_NUMBER(name, number)  name = number,
#define END_RELOC_NUMBERS(name)     name };
START_RELOC_NUMBERS (elf_m68k_reloc_type)
	RELOC_NUMBER (R_68K_NONE, 0)		/* No reloc */
	RELOC_NUMBER (R_68K_32, 1)			/* Direct 32 bit  */
	RELOC_NUMBER (R_68K_16, 2)			/* Direct 16 bit  */
	RELOC_NUMBER (R_68K_8, 3)			/* Direct 8 bit  */
	RELOC_NUMBER (R_68K_PC32, 4)		/* PC relative 32 bit */
	RELOC_NUMBER (R_68K_PC16, 5)		/* PC relative 16 bit */
	RELOC_NUMBER (R_68K_PC8, 6)			/* PC relative 8 bit */
	RELOC_NUMBER (R_68K_GOT32, 7)		/* 32 bit PC relative GOT entry */
	RELOC_NUMBER (R_68K_GOT16, 8)		/* 16 bit PC relative GOT entry */
	RELOC_NUMBER (R_68K_GOT8, 9)		/* 8 bit PC relative GOT entry */
	RELOC_NUMBER (R_68K_GOT32O, 10)		/* 32 bit GOT offset */
	RELOC_NUMBER (R_68K_GOT16O, 11)		/* 16 bit GOT offset */
	RELOC_NUMBER (R_68K_GOT8O, 12)		/* 8 bit GOT offset */
	RELOC_NUMBER (R_68K_PLT32, 13)		/* 32 bit PC relative PLT address */
	RELOC_NUMBER (R_68K_PLT16, 14)		/* 16 bit PC relative PLT address */
	RELOC_NUMBER (R_68K_PLT8, 15)		/* 8 bit PC relative PLT address */
	RELOC_NUMBER (R_68K_PLT32O, 16)		/* 32 bit PLT offset */
	RELOC_NUMBER (R_68K_PLT16O, 17)		/* 16 bit PLT offset */
	RELOC_NUMBER (R_68K_PLT8O, 18)		/* 8 bit PLT offset */
	RELOC_NUMBER (R_68K_COPY, 19)		/* Copy symbol at runtime */
	RELOC_NUMBER (R_68K_GLOB_DAT, 20)	/* Create GOT entry */
	RELOC_NUMBER (R_68K_JMP_SLOT, 21)	/* Create PLT entry */
	RELOC_NUMBER (R_68K_RELATIVE, 22)	/* Adjust by program base */
	/* These are GNU extensions to enable C++ vtable garbage collection.  */
	RELOC_NUMBER (R_68K_GNU_VTINHERIT, 23)
	RELOC_NUMBER (R_68K_GNU_VTENTRY, 24)
	/* TLS static relocations.  */
	RELOC_NUMBER (R_68K_TLS_GD32, 25)
	RELOC_NUMBER (R_68K_TLS_GD16, 26)
	RELOC_NUMBER (R_68K_TLS_GD8, 27)
	RELOC_NUMBER (R_68K_TLS_LDM32, 28)
	RELOC_NUMBER (R_68K_TLS_LDM16, 29)
	RELOC_NUMBER (R_68K_TLS_LDM8, 30)
	RELOC_NUMBER (R_68K_TLS_LDO32, 31)
	RELOC_NUMBER (R_68K_TLS_LDO16, 32)
	RELOC_NUMBER (R_68K_TLS_LDO8, 33)
	RELOC_NUMBER (R_68K_TLS_IE32, 34)
	RELOC_NUMBER (R_68K_TLS_IE16, 35)
	RELOC_NUMBER (R_68K_TLS_IE8, 36)
	RELOC_NUMBER (R_68K_TLS_LE32, 37)
	RELOC_NUMBER (R_68K_TLS_LE16, 38)
	RELOC_NUMBER (R_68K_TLS_LE8, 39)
	RELOC_NUMBER (R_68K_TLS_DTPMOD32, 40)
	RELOC_NUMBER (R_68K_TLS_DTPREL32, 41)
	RELOC_NUMBER (R_68K_TLS_TPREL32, 42)
END_RELOC_NUMBERS (R_68K_max)
#undef START_RELOC_NUMBERS
#undef RELOC_NUMBER
#undef END_RELOC_NUMBERS

// Reloc names
#define START_RELOC_NUMBERS(name) static const char *name (unsigned long rtype) { switch (rtype) {
#define RELOC_NUMBER(name, number) case number: return #name;
#define END_RELOC_NUMBERS(name) default: return NULL; } }
START_RELOC_NUMBERS (elf_m68k_reloc_name)
	RELOC_NUMBER (R_68K_NONE, 0)		/* No reloc */
	RELOC_NUMBER (R_68K_32, 1)			/* Direct 32 bit  */
	RELOC_NUMBER (R_68K_16, 2)			/* Direct 16 bit  */
	RELOC_NUMBER (R_68K_8, 3)			/* Direct 8 bit  */
	RELOC_NUMBER (R_68K_PC32, 4)		/* PC relative 32 bit */
	RELOC_NUMBER (R_68K_PC16, 5)		/* PC relative 16 bit */
	RELOC_NUMBER (R_68K_PC8, 6)			/* PC relative 8 bit */
	RELOC_NUMBER (R_68K_GOT32, 7)		/* 32 bit PC relative GOT entry */
	RELOC_NUMBER (R_68K_GOT16, 8)		/* 16 bit PC relative GOT entry */
	RELOC_NUMBER (R_68K_GOT8, 9)		/* 8 bit PC relative GOT entry */
	RELOC_NUMBER (R_68K_GOT32O, 10)		/* 32 bit GOT offset */
	RELOC_NUMBER (R_68K_GOT16O, 11)		/* 16 bit GOT offset */
	RELOC_NUMBER (R_68K_GOT8O, 12)		/* 8 bit GOT offset */
	RELOC_NUMBER (R_68K_PLT32, 13)		/* 32 bit PC relative PLT address */
	RELOC_NUMBER (R_68K_PLT16, 14)		/* 16 bit PC relative PLT address */
	RELOC_NUMBER (R_68K_PLT8, 15)		/* 8 bit PC relative PLT address */
	RELOC_NUMBER (R_68K_PLT32O, 16)		/* 32 bit PLT offset */
	RELOC_NUMBER (R_68K_PLT16O, 17)		/* 16 bit PLT offset */
	RELOC_NUMBER (R_68K_PLT8O, 18)		/* 8 bit PLT offset */
	RELOC_NUMBER (R_68K_COPY, 19)		/* Copy symbol at runtime */
	RELOC_NUMBER (R_68K_GLOB_DAT, 20)	/* Create GOT entry */
	RELOC_NUMBER (R_68K_JMP_SLOT, 21)	/* Create PLT entry */
	RELOC_NUMBER (R_68K_RELATIVE, 22)	/* Adjust by program base */
	/* These are GNU extensions to enable C++ vtable garbage collection.  */
	RELOC_NUMBER (R_68K_GNU_VTINHERIT, 23)
	RELOC_NUMBER (R_68K_GNU_VTENTRY, 24)
	/* TLS static relocations.  */
	RELOC_NUMBER (R_68K_TLS_GD32, 25)
	RELOC_NUMBER (R_68K_TLS_GD16, 26)
	RELOC_NUMBER (R_68K_TLS_GD8, 27)
	RELOC_NUMBER (R_68K_TLS_LDM32, 28)
	RELOC_NUMBER (R_68K_TLS_LDM16, 29)
	RELOC_NUMBER (R_68K_TLS_LDM8, 30)
	RELOC_NUMBER (R_68K_TLS_LDO32, 31)
	RELOC_NUMBER (R_68K_TLS_LDO16, 32)
	RELOC_NUMBER (R_68K_TLS_LDO8, 33)
	RELOC_NUMBER (R_68K_TLS_IE32, 34)
	RELOC_NUMBER (R_68K_TLS_IE16, 35)
	RELOC_NUMBER (R_68K_TLS_IE8, 36)
	RELOC_NUMBER (R_68K_TLS_LE32, 37)
	RELOC_NUMBER (R_68K_TLS_LE16, 38)
	RELOC_NUMBER (R_68K_TLS_LE8, 39)
	RELOC_NUMBER (R_68K_TLS_DTPMOD32, 40)
	RELOC_NUMBER (R_68K_TLS_DTPREL32, 41)
	RELOC_NUMBER (R_68K_TLS_TPREL32, 42)
END_RELOC_NUMBERS (R_68K_max)


#define ELF32_R_SYM(x)  ((x) >> 8)


#define ELF32_ST_BIND(x)  ((x) >> 4)
#define STB_LOCAL  0
#define STB_GLOBAL 1
#define STB_WEAK   2

#define ELF32_ST_TYPE(x)  ((x) & 0x0f)
#define STT_NOTYPE  0
#define STT_OBJECT  1
#define STT_FUNC    2
#define STT_SECTION 3
#define STT_FILE    4
#define STT_COMMON  5
#define STT_TLS     6


typedef struct {
	uint32_t	p_type;
	uint32_t	p_offset;
	uint32_t	p_vaddr;
	uint32_t	p_paddr;
	uint32_t	p_filesz;
	uint32_t	p_memsz;
	uint32_t	p_flags;
	uint32_t	p_align;
} Elf32_Phdr;

typedef struct
{
	uint32_t	s_name;
	uint32_t	s_type;
	uint32_t	s_flags;
	uint32_t	s_addr;
	uint32_t	s_offset;
	uint32_t	s_size;
	uint32_t	s_link;
	uint32_t	s_info;
	uint32_t	s_addralign;
	uint32_t	s_entsize;
} Elf32_Shdr;

typedef struct {
	uint32_t	r_offset;
	uint32_t	r_info;
	int32_t		r_addend;
} Elf32_Rela;

typedef struct {
	uint32_t	st_name;
	uint32_t	st_value;
	uint32_t	st_size;
	uint8_t		st_info;
	uint8_t		st_other;
	uint16_t	st_shndx;
} Elf32_Sym;

#define PT_LOAD	1
#define PF_R	4
#define PF_W	2
#define PF_X	1

/* Standard GEMDOS program flags.  */
#define _MINT_F_FASTLOAD      0x01    /* Don't clear heap.  */
#define _MINT_F_ALTLOAD       0x02    /* OK to load in alternate RAM.  */
#define _MINT_F_ALTALLOC      0x04    /* OK to malloc from alt. RAM.  */
#define _MINT_F_BESTFIT       0x08    /* Load with optimal heap size.  */
/* The memory flags are mutually exclusive.  */
#define _MINT_F_MEMPROTECTION 0xf0    /* Masks out protection bits.  */
#define _MINT_F_MEMPRIVATE    0x00    /* Memory is private.  */
#define _MINT_F_MEMGLOBAL     0x10    /* Read/write access to mem allowed.  */
#define _MINT_F_MEMSUPER      0x20    /* Only supervisor access allowed.  */
#define _MINT_F_MEMREADABLE   0x30    /* Any read access OK.  */
#define _MINT_F_SHTEXT        0x800   /* Program's text may be shared */

/* Option flags.  */
static uint32_t prg_flags = (_MINT_F_FASTLOAD | _MINT_F_ALTLOAD | _MINT_F_ALTALLOC | _MINT_F_MEMPRIVATE);
static int32_t  stack_size = 0;

int verbosity = 0;
int have_gc_sections = 0;
int have_ld_hijacker = 0;

#if BYTE_ORDER == BIG_ENDIAN

#define swap32(x) (x)
#define swap16(x) (x)

#else

static inline uint32_t swap32(uint32_t v)
{
	return (v >> 24) |
		((v >> 8)  & 0x0000FF00) |
		((v << 8)  & 0x00FF0000) |
		(v << 24);
}

static inline uint16_t swap16(uint16_t v)
{
	return (v >> 8) | (v << 8);
}

#endif /* BIG_ENDIAN */

typedef struct
{
	uint16_t ph_branch;        /* Branch zum Anfang des Programms  */
	/* (muß 0x601a sein!)               */

	uint32_t ph_tlen;          /* Länge  des TEXT - Segments       */
	uint32_t ph_dlen;          /* Länge  des DATA - Segments       */
	uint32_t ph_blen;          /* Länge  des BSS  - Segments       */
	uint32_t ph_slen;          /* Länge  der Symboltabelle         */
	uint32_t ph_res1;          /* reserviert, sollte 0 sein        */
	uint32_t ph_prgflags;      /* Programmflags                    */
	uint16_t ph_absflag;       /* 0 = Relozierungsinf. vorhanden   */
} TOS_hdr;


typedef struct {
	TOS_hdr		header;
	Elf32_Shdr	*shdrs;
	uint16_t	shnum;
	char		*shstrtab;
	uint32_t	program_off;
	uint32_t	program_size;
	uint32_t	stack_pos;
	int32_t		stack_size;
	uint32_t	slb_version_pos;
	uint16_t	have_ext_program_header;
	uint16_t	is_slb;
	uint8_t		*relas;
	uint32_t	rela_size;
	FILE *elf;
} TOS_map;


void print_options() {
	fprintf(stdout, "  --[no-]fastload             Enable/Disable not cleaning the heap on startup\n");
	fprintf(stdout, "  --[no-]altram,\n");
	fprintf(stdout, "  --[no-]fastram              Enable/Disable loading into alternate RAM\n");
	fprintf(stdout, "  --[no-]altalloc,\n");
	fprintf(stdout, "  --[no-]fastalloc            Enable/Disable malloc from alternate RAM\n");
	fprintf(stdout, "  --[no-]best-fit             Enable/Disable loading with optimal heap size\n");
	fprintf(stdout, "  --[no-]sharable-text,\n");
	fprintf(stdout, "  --[no-]shared-text,\n");
	fprintf(stdout, "  --[no-]baserel              Enable/Disable sharing the text segment\n");
	fprintf(stdout, "\n");
	fprintf(stdout, "The following memory options are mutually exclusive:\n");
	fprintf(stdout, "  --private-memory            Process memory is not accessible\n");
	fprintf(stdout, "  --global-memory             Process memory is readable and writable\n");
	fprintf(stdout, "  --super-memory              Process memory is accessible in supervisor mode\n");
	fprintf(stdout, "  --readonly-memory,\n");
	fprintf(stdout, "  --readable-memory           Process memory is readable but not writable\n");
	fprintf(stdout, "\n");
	fprintf(stdout, "  --prg-flags <value>         Set all the flags with an integer raw value\n");
	fprintf(stdout, "  --stack <size>              Override the stack size (suffix k or M allowed)\n");
}

void usage(const char *name) {
	fprintf(stdout, "Usage: %s [options] [--] elf-file tos-file\n", name);
	fprintf(stdout, " Convert an ELF file to a TOS file (by segments)\n");
	fprintf(stdout, " Options:\n");
	fprintf(stdout, "  -h, --help                  Show this help\n");
	fprintf(stdout, "  -v                          Be more verbose (twice for even more)\n");
	print_options();
}

#define die(x, ...) do{ fprintf(stderr, x "\n", ##__VA_ARGS__); exit(1); }while(0)
#define perrordie(x) do{ perror(x); exit(1); }while(0)

void ferrordie(FILE *f, const char *str)
{
	if(ferror(f)) {
		fprintf(stderr, "Error while ");
		perrordie(str);
	} else if(feof(f)) {
		fprintf(stderr, "EOF while %s\n", str);
		exit(1);
	} else {
		fprintf(stderr, "Unknown error while %s\n", str);
		exit(1);
	}
}
int rela_cmp (const void *v1, const void *v2)
{
	return (int) ((*((uint32_t *) v1)) - (*((uint32_t *) v2)));
}
void *read_elf_segment(TOS_map *map, uint32_t idx, const char *errorstr, uint32_t *size) {
	void *ret = 0;
	uint32_t num = swap32(map->shdrs[idx].s_size);
	uint32_t off = swap32(map->shdrs[idx].s_offset);

	if((ret = (char*)malloc(num))==0)
		die("failed to allocate memory\n");

	if(fseek(map->elf, off, SEEK_SET) < 0)
		ferrordie(map->elf, errorstr);
	if(fread(ret, 1, num, map->elf) != num)
		ferrordie(map->elf, errorstr);
	if(size) *size=num;
	return ret;
}
void read_elf_segments(TOS_map *map, const char *elf)
{
	int read;
	uint32_t i,j;
	Elf32_Ehdr ehdr;
	Elf32_Phdr phdr;
	uint32_t e_entry = 0;

	if(verbosity >= 2)
		fprintf(stderr, "Reading ELF file...\n");

	map->elf = fopen(elf, "rb");
	if(!map->elf)
		perrordie("Could not open ELF file");

	read = fread(&ehdr, sizeof(ehdr), 1, map->elf);
	if(read != 1)
		ferrordie(map->elf, "reading ELF header");

	if(memcmp(&ehdr.e_ident[0], "\177ELF", 4))
		die("Invalid ELF header");
	if(ehdr.e_ident[EI_CLASS] != ELFCLASS32)
		die("Invalid ELF class");
	if(ehdr.e_ident[EI_DATA] != ELFDATA2MSB)
		die("Invalid ELF byte order");
	if(ehdr.e_ident[EI_VERSION] != EV_CURRENT)
		die("Invalid ELF ident version");
	if(swap32(ehdr.e_version) != EV_CURRENT)
		die("Invalid ELF version");
	if(swap16(ehdr.e_type) != ET_EXEC)
		die("ELF is not an executable");
	if(swap16(ehdr.e_machine) != EM_68K)
		die("Machine is not 68K");

	e_entry = swap32(ehdr.e_entry);

	if(verbosity >= 2)
		fprintf(stderr, "Valid ELF header found\n");

	//////////////////////////////////////////////////////////////////////////
	// program header
	//////////////////////////////////////////////////////////////////////////
	uint16_t phnum = swap16(ehdr.e_phnum);
	uint32_t phoff = swap32(ehdr.e_phoff);

	if(!phnum || !phoff)
		die("ELF has no program headers");
	if(phnum > 1)
		die("ELF has more as one program header");

	if(swap16(ehdr.e_phentsize) != sizeof(Elf32_Phdr))
		die("Invalid program header entry size");

	if(fseek(map->elf, phoff, SEEK_SET) < 0)
		ferrordie(map->elf, "reading ELF program headers");
	read = fread(&phdr, sizeof(Elf32_Phdr), 1, map->elf);
	if(read != 1)
		ferrordie(map->elf, "reading ELF program headers");

	if(swap32(phdr.p_type) != PT_LOAD)
		die("wrong program header type\n");
	map->program_off = swap32(phdr.p_offset);
	map->program_size = swap32(phdr.p_filesz);

	uint32_t head[2];
	if(fseek(map->elf, map->program_off, SEEK_SET) < 0)
		ferrordie(map->elf, "reading program headers");
	if(fread(head, sizeof(uint32_t), 2, map->elf)!=2)
		ferrordie(map->elf, "reading program headers");
	if(swap32(head[0]) == 0x203a001a || swap32(head[1]) == 0x4efb08fa) {
		map->have_ext_program_header = e_entry ? e_entry : 0xe4;
		if(fseek(map->elf, 0xe4-8, SEEK_CUR) < 0)
			ferrordie(map->elf, "reading program headers");
		if(fread(head, sizeof(uint32_t), 2, map->elf)!=2)
			ferrordie(map->elf, "reading program headers");
	} else if(e_entry) {
		fprintf(stderr, "Warning: entry point given but no extended program header. Entry point ignored\n");
		e_entry = 0;
	}
	if(swap32(head[0]) == 0x70004afc) { // slb
		map->is_slb = 1;
	}
	if(e_entry && e_entry != 0xe4 && map->is_slb) {
		fprintf(stderr, "Warning: entry point given but a slb header detected. Entry point ignored\n");
		map->have_ext_program_header = 0xe4;
	}

	//////////////////////////////////////////////////////////////////////////
	// section headers
	//////////////////////////////////////////////////////////////////////////
	map->shnum = swap16(ehdr.e_shnum);
	uint32_t shoff = swap32(ehdr.e_shoff);

	if(!map->shnum || !shoff)
		die("ELF has no section headers");

	if(swap16(ehdr.e_shentsize) != sizeof(Elf32_Shdr))
		die("Invalid section header entry size");

	if((map->shdrs = (Elf32_Shdr*)malloc(map->shnum * sizeof(Elf32_Shdr)))==0)
		die("failed to allocate memory\n");

	if(fseek(map->elf, shoff, SEEK_SET) < 0)
		ferrordie(map->elf, "reading ELF section headers");
	read = fread(map->shdrs, sizeof(Elf32_Shdr), map->shnum, map->elf);
	if(read != map->shnum)
		ferrordie(map->elf, "reading ELF section headers");

	//////////////////////////////////////////////////////////////////////////
	// .shstrtab
	//////////////////////////////////////////////////////////////////////////
	uint16_t shstrndx = swap16(ehdr.e_shstrndx);
	if(map->shnum <= shstrndx)
		die("section strtab index out of range\n");

	map->shstrtab = (char*)read_elf_segment(map, shstrndx, "reading ELF section .shstrtab", 0);

	//////////////////////////////////////////////////////////////////////////
	// section .mint_prg_info
	//////////////////////////////////////////////////////////////////////////
	if(strcmp(&map->shstrtab[swap32(map->shdrs[1].s_name)], ".mint_prg_info"))
		die("section .mint_prg_info not found\n");
	if(swap32(map->shdrs[1].s_size) != sizeof(map->header))
		die("section .mint_prg_info wrong size %i (should be %i)\n", swap32(map->shdrs[1].s_size), sizeof(map->header));
	if(fseek(map->elf, swap32(map->shdrs[1].s_offset), SEEK_SET) < 0)
		ferrordie(map->elf, "reading section .mint_prg_info");
	read = fread(&map->header, sizeof(map->header), 1, map->elf);
	if(read != 1)
		ferrordie(map->elf, "reading section .mint_prg_info");
	if(map->is_slb && map->header.ph_blen==0)
		map->header.ph_blen=swap32(2); // MagiC SLB dont work with empty bss secment

	if(map->header.ph_prgflags /*.startup_size*/ == 0 && !map->is_slb && e_entry == 0) {
		if(have_ld_hijacker) {
			if(have_gc_sections) {
				fprintf(stderr, "Error: No entry point found! The '.text' section of the first linked file was removed with high probability. Use the '-Map'-linker option to create a map file to verify correct linking! To force an entry point ");
				if(map->have_ext_program_header)
					fprintf(stderr, "use the '-e' linker option, ");
				fprintf(stderr, "put your entry in section '.text.entry.mint' or use a '*crt0*.o' file\n");
				exit(1);
			}
		} else {
			// use of --gc-sections unknown
			fprintf(stderr, "Warning: no entry point found! Your program is possibly not runable. Use the '-Map'-linker option to create a map file to verify correct linking! To force an entry point ");
			if(map->have_ext_program_header)
				fprintf(stderr, "use the '-e' linker option, ");
			fprintf(stderr, "put your entry in section '.text.entry.mint' or use a '*crt0*.o' file\n");
		}

	}

	//////////////////////////////////////////////////////////////////////////
	// sections .symtab
	//////////////////////////////////////////////////////////////////////////

	uint32_t sym_num=0;
	Elf32_Sym *syms=0;
	char *sym_names=0;

	for(i = 0; i < map->shnum; i++) {
		if(swap32(map->shdrs[i].s_type) == SHT_SYMTAB) {
			syms = (Elf32_Sym*) read_elf_segment(map, i, "reading symtab", &sym_num);
			sym_num /= sizeof(Elf32_Sym);
			sym_names = (char*) read_elf_segment(map, swap32(map->shdrs[i].s_link), "reading strtab", 0);
			break;
		}
	}
	if(syms && sym_names) {
		for(i = 0; i < sym_num; i++) {
			if(!strcmp("__stksize", &sym_names[swap32(syms[i].st_name)]))
				map->stack_pos = swap32(syms[i].st_value);
			else if(!strcmp("_slb_version", &sym_names[swap32(syms[i].st_name)]))
				map->slb_version_pos = swap32(syms[i].st_value);
		}
		if(map->stack_pos) {
			if(fseek(map->elf, map->program_off + map->stack_pos, SEEK_SET) < 0)
				ferrordie(map->elf, "reading _stksize");
			if(fread(&map->stack_size, sizeof(uint32_t), 1, map->elf)!=1)
				ferrordie(map->elf, "reading _stksize");
			map->stack_size = (int32_t)swap32((uint32_t)map->stack_size);
		}
	}

	//////////////////////////////////////////////////////////////////////////
	// sections .rela.*
	//////////////////////////////////////////////////////////////////////////
	uint32_t rela_count=0;
	for(i = 0; i < map->shnum; i++) {
		if(swap32(map->shdrs[i].s_type) == SHT_RELA && swap32(map->shdrs[swap32(map->shdrs[i].s_info)].s_flags) & SHF_ALLOC)
			rela_count += swap32(map->shdrs[i].s_size)/sizeof(Elf32_Rela);
	}
	uint32_t *rela_start=0, *rela_end=0, error=0;
	if(rela_count) {
		rela_end = rela_start = (uint32_t*)malloc(rela_count * sizeof(uint32_t));
		if(rela_end == 0) die("failed to allocate memory\n");
		for(i = 0; i < map->shnum; i++) {
			Elf32_Rela *tmp_relas;
			if(swap32(map->shdrs[i].s_type) == SHT_RELA && swap32(map->shdrs[swap32(map->shdrs[i].s_info)].s_flags) & SHF_ALLOC) {
				char *s_name = &map->shstrtab[swap32(map->shdrs[i].s_name)];
				uint32_t s_size = swap32(map->shdrs[i].s_size);
				if(verbosity >=2 ) fprintf(stderr, "search rela's from %s\n", s_name);
				if((tmp_relas = (Elf32_Rela*)malloc(s_size))==0)
					die("failed to allocate memory\n");
				if(fseek(map->elf, swap32(map->shdrs[i].s_offset), SEEK_SET) < 0)
					ferrordie(map->elf, "reading rela's");
				read = fread(tmp_relas, 1, s_size, map->elf);
				if(read != s_size)
					ferrordie(map->elf, "reading rela's");
				for(j=0; j <s_size/sizeof(Elf32_Rela); j++)
				{
					uint32_t r_type = ELF32_R_TYPE(swap32(tmp_relas[j].r_info));
					uint32_t r_offset = swap32(tmp_relas[j].r_offset);
					uint32_t r_sym = ELF32_R_SYM(swap32(tmp_relas[j].r_info));
					Elf32_Sym *sym = syms ? &syms[r_sym] : NULL;
					const char *sym_name = (sym && sym_names) ? &sym_names[swap32(sym->st_name)] : "";
					if (r_type == R_68K_32) {
						uint32_t use_rela = 1;
						if(r_offset & 1) {
							error = 1;
							fprintf(stderr, "Error: rela an odd position detected (not supported by atari/mint) offset = %#x symbol = %s in %s\n", r_offset, sym_name, s_name);
						}
						if(sym && tmp_relas[j].r_addend == 0) {
							if(ELF32_ST_BIND(sym->st_info) == STB_WEAK) {
								/* ignore relas for unrefernced weak symbols e.g. empty slb_export slots */
								if(fseek(map->elf, map->program_off + r_offset, SEEK_SET) < 0)
									ferrordie(map->elf, "reading unrefernced weak");
								if(fread(&use_rela, sizeof(uint32_t), 1, map->elf)!=1)
									ferrordie(map->elf, "reading unrefernced weak");
								if(!use_rela && verbosity >=2)
									fprintf(stderr, "ignore relocation for unreferenced week symbol %s @0x%X\n", sym_name, r_offset);
							}
						}
						if(use_rela)
							*rela_end++ = r_offset;
					} else if(r_type != R_68K_NONE && r_type != R_68K_PC32 && r_type != R_68K_PC16 && r_type != R_68K_PC8) {
						fprintf(stderr, "Warning: got unexpected relocation type %s (offset=%#X%s%s) - left unhandled\n", elf_m68k_reloc_name(r_type), r_offset, *sym_name ? "; sym=":"", sym_name);
					}
				}
				free(tmp_relas);
			}
		}
		if(error) exit(1);
		rela_count = rela_end-rela_start;
		qsort(rela_start, rela_count, sizeof(uint32_t), rela_cmp);
		uint32_t bytes = 4; /* First entry is a long.  */
		for (i = 1; i < rela_count; i++) {
			uint32_t diff = rela_start[i] - rela_start[i - 1];
			bytes += (diff + 253) / 254;
		}
		bytes++; /* Last entry is (byte) 0 if there are some relocations.  */
		uint8_t *ptr;
		map->rela_size = bytes;
		if((map->relas = ptr = (uint8_t*)malloc(bytes))==0)
			die("failed to allocate memory\n");
		/* Now fill the array.  */
		*((uint32_t*)ptr) = swap32(rela_start[0]);
		ptr += 4;
		for (i = 1; i < rela_count; i++) {
			uint32_t diff = rela_start[i] - rela_start[i - 1];
			while (diff > 254) {
				*ptr++ = 1;
				diff -= 254;
			}
			*ptr++ = (uint8_t) diff;
		}
		*ptr = 0;
	}

}


#define BLOCK (1024*1024)

void fcpy(FILE *dst, FILE *src, uint32_t dst_off, uint32_t src_off, uint32_t size)
{
	int left = size;
	int read;
	int written;
	int block;
	void *blockbuf;

	if(fseek(src, src_off, SEEK_SET) < 0)
		ferrordie(src, "reading ELF segment data");
	if(fseek(dst, dst_off, SEEK_SET) < 0)
		ferrordie(dst, "writing TOS segment data");

	blockbuf = malloc(MIN(BLOCK, left));

	while(left) {
		block = MIN(BLOCK, left);
		read = fread(blockbuf, 1, block, src);
		if(read != block) {
			free(blockbuf);
			ferrordie(src, "reading ELF segment data");
		}
		written = fwrite(blockbuf, 1, block, dst);
		if(written != block) {
			free(blockbuf);
			ferrordie(dst, "writing TOS segment data");
		}
		left -= block;
	}
	free(blockbuf);
}


void write_tos(TOS_map *map, const char *tos)
{
	FILE *tosf;
	int written;

	if(verbosity >= 2)
		fprintf(stderr, "writing TOS file...\n");

	tosf = fopen(tos, "w+b");
	if(!tosf)
		perrordie("Could not open TOS file");

	if(verbosity >= 2)
		fprintf(stderr, "writing TOS header ...\n");
	if(map->is_slb && (prg_flags & _MINT_F_BESTFIT)==0) {
		fprintf(stderr, "Warning: target is shared library force --best-fit ...\n");
		prg_flags |= _MINT_F_BESTFIT;
	}
	map->header.ph_prgflags = swap32(prg_flags);
	written = fwrite(&map->header, sizeof(TOS_hdr), 1, tosf);
	if(written != 1)
		ferrordie(tosf, "writing TOS header");

	if(verbosity >= 2)
		fprintf(stderr, "writing TEXT & DATA segment ...\n");
	fcpy(tosf, map->elf, ftell(tosf), map->program_off, map->program_size);

	if(verbosity >= 2)
		fprintf(stderr, "writing tpa relocation ...\n");
	uint32_t dummy=0;
	uint8_t *relas = (uint8_t*)&dummy;
	uint32_t rela_size = 4;
	if(map->relas && map->rela_size) {
		relas = map->relas;
		rela_size = map->rela_size;
	}
	written = fwrite(relas, rela_size, 1, tosf);
	if(written != 1)
		ferrordie(tosf, "writing tpa relocation");

	if(map->is_slb && map->slb_version_pos) {
		uint32_t val;
		if(fseek(tosf, 0x1c + map->slb_version_pos, SEEK_SET) < 0)
			ferrordie(tosf, "fixing slb-stuff");
		if(fread(&val, sizeof(val), 1, tosf) != 1)
			ferrordie(tosf, "fixing slb-stuff");
		if(fseek(tosf, 0x1c + 0x8 + map->have_ext_program_header, SEEK_SET) < 0)
			ferrordie(tosf, "fixing slb-stuff");
		if(fwrite(&val, sizeof(uint32_t), 1, tosf) != 1)
			ferrordie(tosf, "fixing slb-stuff");
	}

	if(map->stack_pos) {
		uint32_t val;
		if(map->have_ext_program_header) {
			if(fseek(tosf, 0x1c + 0x30, SEEK_SET) < 0)
				ferrordie(tosf, "writing _stksize pos");
			val = swap32(map->stack_pos+0x1c);
			if(fwrite(&val, sizeof(uint32_t), 1, tosf)!=1)
				ferrordie(tosf, "writing _stksize pos");
		}
		if(stack_size) {
			if(verbosity >= 1) {
				if(map->stack_size != stack_size)
					fprintf(stderr, "change stack-size from %i to %i\n", map->stack_size, stack_size);
			}
			val = swap32(stack_size);
			if(fseek(tosf, map->stack_pos+0x1c, SEEK_SET) < 0)
				ferrordie(tosf, "writing __stksize");
			if(fwrite(&val, sizeof(uint32_t), 1, tosf)!=1)
				ferrordie(tosf, "writing __stksize");
		}
	} else if(stack_size)
		fprintf(stderr, "Warning: symbol '_stksize' not found - ignoring stack size %i\n", stack_size);

	if(verbosity >= 2)
		fprintf(stderr, "All done!\n");

	fclose(map->elf);
	fclose(tosf);
}
static inline void set_prg_flags(uint32_t mask, uint32_t value, int no) {
	prg_flags &= ~mask;
	if(no==0) prg_flags |= value;
}
int main(int argc, char **argv)
{
	char **arg;
	if(argc < 2) {
		usage(argv[0]);
		return 1;
	}
	arg = &argv[1];
	argc--;

	while(argc && *arg[0] == '-') {
		int unrecognized_option = 0;
		if(!strcmp(*arg, "-h") || !strcmp(*arg, "--help")) {
			usage(argv[0]);
			return 0;
		} else if(!strcmp(*arg, "--target-help")) {
			print_options();
			return 0;
		} else if(!strcmp(*arg, "--gc-sections")) {
			// hidden option
			have_gc_sections = 1;
		} else if(!strcmp(*arg, "--ld-hijacker")) {
			// hidden option
			have_ld_hijacker = 1;
		} else if(!strcmp(*arg, "-v")) {
			verbosity++;
			if(verbosity == 1) fprintf(stdout, "tostool v" TOSTOOL_VERSION " (c) by ardisoft (Armin Diedering)\n");
		} else if(!strcmp(*arg, "--")) {
			arg++;
			argc--;
			break;
		} else if(!strncmp(*arg, "--", 2) || !strncmp(*arg, "-m", 2)) { // enable --oprion an -moption
			char *p = (*arg)+2;
			if (arg[0][1] == '-' && *p == 'm') ++p; // enable --moption to
			int no=0;
			if(!strcmp(p, "private-memory"))
				set_prg_flags(_MINT_F_MEMPROTECTION, _MINT_F_MEMPRIVATE, no);
			else if(!strcmp(p, "global-memory"))
				set_prg_flags(_MINT_F_MEMPROTECTION, _MINT_F_MEMGLOBAL, no);
			else if(!strcmp(p, "super-memory"))
				set_prg_flags(_MINT_F_MEMPROTECTION, _MINT_F_MEMSUPER, no);
			else if(!strcmp(p, "readonly-memory") || !strcmp(p, "readable-memory"))
				set_prg_flags(_MINT_F_MEMPROTECTION, _MINT_F_MEMREADABLE, no);
			else if(!strcmp(p, "prg-flags")) {
				if(argc==1) {
					fprintf(stderr, "Unrecognized option %s\n", *arg);
					usage(argv[0]);
					return 1;
				}
				arg++;
				argc--;
				char* tail;
				unsigned long flag_value = strtoul (*arg, &tail, 0);
				if (*tail != '\0')
					fprintf(stderr, "Warning: ignoring invalid program flags %s\n", *arg);
				else
					prg_flags = flag_value;
			} else if(!strcmp(p, "stack")) {
				if(argc==1) {
					fprintf(stderr, "Unrecognized option %s\n", *arg);
					usage(argv[0]);
					return 1;
				}
				arg++;
				argc--;
				char* tail;
				unsigned long size = strtoul (*arg, &tail, 0);
				if (*tail == 'K' || *tail == 'k') {
					size *= 1024;
					++tail;
				} else if (*tail == 'M' || *tail == 'm') {
					size *= 1024*1024;
					++tail;
				}
				if (*tail != '\0')
					fprintf(stderr, "Warning: ignoring invalid stack size %s\n", *arg);
				else
					stack_size = size;
			} else {
				if(!strncmp(p, "no-", 3)) {
					no = 1;
					p+=3;
				}
				if(!strcmp(p,"fastload"))
					set_prg_flags(_MINT_F_FASTLOAD, _MINT_F_FASTLOAD, no);
				else if(!strcmp(p,"altram") || !strcmp(p,"fastram"))
					set_prg_flags(_MINT_F_ALTLOAD, _MINT_F_ALTLOAD, no);
				else if(!strcmp(p,"altalloc") || !strcmp(p,"fastalloc"))
					set_prg_flags(_MINT_F_ALTALLOC, _MINT_F_ALTALLOC, no);
				else if(!strcmp(p,"best-fit"))
					set_prg_flags(_MINT_F_BESTFIT, _MINT_F_BESTFIT, no);
				else if(!strcmp(p,"sharable-text") || !strcmp(p,"shared-text") || !strcmp(p,"baserel"))
					set_prg_flags(_MINT_F_SHTEXT, _MINT_F_SHTEXT, no);
				else
					unrecognized_option = 1;
			}
		} else
			unrecognized_option = 1;
		if(unrecognized_option) {
			fprintf(stderr, "Unrecognized option %s\n", *arg);
			usage(argv[0]);
			return 1;
		}
		arg++;
		argc--;
	}
	if(argc != 2) {
		usage(argv[0]);
		return 1;
	}

	const char *elf_file = arg[0];
	const char *tos_file = arg[1];

	TOS_map map;

	memset(&map, 0, sizeof(map));

	read_elf_segments(&map, elf_file);
//	map_tos(&map);
	write_tos(&map, tos_file);

	return 0;
}
