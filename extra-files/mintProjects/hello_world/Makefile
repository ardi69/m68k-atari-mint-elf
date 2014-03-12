#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
CURMAKEFILE := $(CURDIR)/$(shell basename $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITMINT)),)
$(error "Please set DEVKITMINT in your environment. export DEVKITMINT=<path to>devkitMINT")
endif

include $(DEVKITMINT)/base_rules

#---------------------------------------------------------------------------------
# ARCH ist the arch option e.g -m68040 -m68020-60 -mcfv4e add -mshort for a short build
#      leaf ARCH empty for a m68000 build
# EXTRA_ARCH like ARCH for extra builds (for mshort add -mshort without space e.g. -m68040-mshort)
# TYPE is the typ of build set to .prg .app .slb or .a for a library
# KEEP_ELF is set "no" to make the elf-file temporary
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# INCLUDES is a list of directories containing extra header files
#---------------------------------------------------------------------------------
ARCH			:=
EXTRA_ARCH	:= 
TYPE			:=	.app
KEEP_ELF		:= yes
TARGET		:=	$(shell basename $(CURDIR))
ARCH_SPEC	:= $(subst $(shell echo ' '),,$(ARCH))
BUILD			:=	build$(ARCH_SPEC)
SOURCES		:=	gfx source data  
INCLUDES		:=	include build

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------

CFLAGS		:=	$(ARCH) -Wall -O2 -fomit-frame-pointer -ffunction-sections
CFLAGS		+=	$(INCLUDE) 
CXXFLAGS		:=	$(CFLAGS) 

ASFLAGS		:=	$(ARCH)
LDFLAGS		:=	$(ARCH) -Wl,--gc-sections
TOOLFLAGS	:=	

#---------------------------------------------------------------------------------
# any extra libraries we wish to link with the project
#---------------------------------------------------------------------------------
LIBS	:= 

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:=	$(LIBMINT)

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------
MULTILIB		:= $(shell $(DEVKITMINT)/bin/$(CC) $(ARCH) -print-multi-directory)

ifeq ($(TYPE),.a)

TARGET	:=	lib/$(MULTILIB)/$(TARGET)$(TYPE)

else

TARGET	:=	$(TARGET)$(ARCH_SPEC)$(TYPE)

endif

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir))
export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.bin)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES	:=	$(BINFILES:.bin=.o) \
						$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
						$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
						$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
						-I$(CURDIR)/$(BUILD)


export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib/$(MULTILIB) -L$(dir)/lib)

.PHONY: $(BUILD) clean rebuild

#---------------------------------------------------------------------------------

$(BUILD): 
	@[ -d $(dir $(TARGET)) ] || mkdir -p $(dir $(TARGET))
	@[ -d $@ ] || mkdir -p $@
	@make --no-print-directory -C $(BUILD) -f $(CURMAKEFILE)
	@$(foreach arch,$(EXTRA_ARCH),make --no-print-directory -f $(CURMAKEFILE) ARCH='$(subst -, -,$(arch))' EXTRA_ARCH=;)

#---------------------------------------------------------------------------------
clean:
	@echo clean $(ARCH_SPEC) ...
	@rm -fr $(BUILD) $(TARGET) $(TARGET:$(suffix $(TARGET))=.elf)
	@[ ! -d $(dir $(TARGET)) ] || [ "x$(dir $(TARGET))" = "x./" ] || echo rmdir -p $(dir $(TARGET)) --ignore-fail-on-non-empty
	@$(foreach arch,$(EXTRA_ARCH),make clean --no-print-directory -f $(CURMAKEFILE) ARCH="$(subst -, -,$(arch))" EXTRA_ARCH=;)

#---------------------------------------------------------------------------------
rebuild: clean $(BUILD)

-include Make.install

#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
ifeq ($(suffix $(OUTPUT)),.slb)

LDFLAGS := -Tm68k_magic_slb.ld -nostdlib $(LDFLAGS)

endif
ifeq ($(suffix $(OUTPUT)),.a)

$(OUTPUT) : $(OFILES)

else ifeq ($(strip $(KEEP_ELF)),yes)

$(OUTPUT) : $(OUTPUT:$(suffix $(OUTPUT))=.elf) 

$(OUTPUT:$(suffix $(OUTPUT))=.elf) : $(OFILES) 

else

$(OUTPUT) : $(OFILES) 

endif 

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
