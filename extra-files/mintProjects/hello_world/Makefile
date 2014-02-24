#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
CURMAKEFILE := $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITMINT)),)
$(error "Please set DEVKITMINT in your environment. export DEVKITMINT=<path to>devkitMINT")
endif

include $(DEVKITMINT)/base_rules

#---------------------------------------------------------------------------------
# ARCH ist the arch option e.g -m68040 -m68020-60 -mcfv4e
# SHORT set to -mshort for builds with sizeof(int)==2
# TYPE is the typ of build set to .prg .app .slb or .a for a library
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# INCLUDES is a list of directories containing extra header files
#---------------------------------------------------------------------------------
ARCH			:=	
SHORT			:=	
TYPE			:=	.app
TARGET		:=	$(shell basename $(CURDIR))
BUILD			:=	build$(ARCH)$(MSHORT)
SOURCES		:=	gfx source data  
INCLUDES		:=	include build
#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------

CFLAGS		:=	$(ARCH) $(MSHORT) -Wall -O2 -ffunction-sections
CFLAGS		+=	$(INCLUDE)
CXXFLAGS		:=	$(CFLAGS) 

ASFLAGS		:=	$(ARCH) $(MSHORT)
LDFLAGS		:=	$(ARCH) $(MSHORT) -Wl,--gc-sections
TOOLFLAGS	:=	-v -v

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
MULTILIB		:= $(shell $(DEVKITMINT)/bin/$(CC) $(ARCH) $(SHORT) -print-multi-directory)

ifeq ($(TYPE),.a)

TARGET	:=	lib/$(MULTILIB)/$(TARGET)$(TYPE)

else

TARGET	:=	$(TARGET)$(ARCH)$(MSHORT)$(TYPE)

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

.PHONY: $(BUILD) clean

#---------------------------------------------------------------------------------
$(BUILD):
	@[ -d $(dir $(TARGET)) ] || mkdir -p $(dir $(TARGET))
	@[ -d $@ ] || mkdir -p $@
	@make --no-print-directory -C $(BUILD) -f $(CURMAKEFILE)
 
#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(OUTPUT) $(OUTPUT:$(suffix $(OUTPUT))=.elf)
	@rmdir -p $(dir $(TARGET)) --ignore-fail-on-non-empty


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

else

all: $(OFILES) $(OUTPUT:$(suffix $(OUTPUT))=.elf) $(OUTPUT)

endif 

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
