
BUILDDIR = build/Sprites
TOOLDIR = ../toolchain

ASEPRITE = $(TOOLDIR)/aseprite.sh
FLAGS = --batch --script $(TOOLDIR)/baba_sprite_export.lua

SOURCES = $(wildcard *.aseprite)
OBJECTS = $(patsubst %.aseprite,$(BUILDDIR)/%_0_1.png,$(SOURCES))

all: $(OBJECTS)

$(BUILDDIR)/%_0_1.png: %.aseprite
	$(ASEPRITE) $(FLAGS) $@

.PHONY: all 