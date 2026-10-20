TARGET_EXEC:=zelda3
ROM:=tables/zelda3.sfc
SRCS:=$(wildcard src/*.c snes/*.c) third_party/gl_core/gl_core_3_1.c third_party/opus-1.3.1-stripped/opus_decoder_amalgam.c
OBJS:=$(SRCS:%.c=%.o)
PYTHON:=/usr/bin/env python3
CC?=cc
SDL2_CONFIG?=sdl2-config
CLANG_NONPROTOTYPE_FLAG:=$(shell $(CC) -Wdeprecated-non-prototype -E -x c /dev/null >/dev/null 2>&1 && echo -Wno-error=deprecated-non-prototype)
CFLAGS:=$(if $(CFLAGS),$(CFLAGS),-O2 -Werror $(CLANG_NONPROTOTYPE_FLAG)) -I .
CFLAGS:=${CFLAGS} $(shell $(SDL2_CONFIG) --cflags) -DSYSTEM_VOLUME_MIXER_AVAILABLE=0

RG35XXXH_CFLAGS?=-O3 -mcpu=cortex-a53 -mtune=cortex-a53 -Werror -Wno-error=format-truncation

ifeq (${OS},Windows_NT)
    WINDRES:=windres
    RES:=zelda3.res
    SDLFLAGS:=-Wl,-Bstatic $(shell $(SDL2_CONFIG) --static-libs)
else
    SDLFLAGS:=$(shell $(SDL2_CONFIG) --libs) -lm
endif

.PHONY: all clean clean_obj clean_gen rg35xxx-h

all: $(TARGET_EXEC) zelda3_assets.dat

# Build only the RG35XXX-H executable. Generate zelda3_assets.dat on the PC.
rg35xxx-h: CFLAGS += $(RG35XXXH_CFLAGS)
rg35xxx-h: $(TARGET_EXEC)

$(TARGET_EXEC): $(OBJS) $(RES)
	$(CC) $^ -o $@ $(LDFLAGS) $(SDLFLAGS)
%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

$(RES): src/platform/win32/zelda3.rc
	@echo "Generating Windows resources"
	@$(WINDRES) $< -O coff -o $@

zelda3_assets.dat:
	@echo "Extracting game resources"
	$(PYTHON) assets/restool.py --extract-from-rom

clean: clean_obj clean_gen
clean_obj:
	@$(RM) $(OBJS) $(TARGET_EXEC)
clean_gen:
	@$(RM) $(RES) zelda3_assets.dat tables/zelda3_assets.dat tables/*.txt tables/*.png tables/sprites/*.png tables/*.yaml
	@rm -rf tables/__pycache__ tables/dungeon tables/img tables/overworld tables/sound
