
TOOLDIR = ../toolchain
OUTDIR = ../Sprites

ASEPRITE = $(TOOLDIR)/aseprite.sh --batch
ASE_SCRIPT = --script $(TOOLDIR)/baba_sprite_export.lua

SOURCES = $(wildcard *.aseprite)
OBJECTS = $(patsubst %.aseprite,$(OUTDIR)/%_0_1.png,$(SOURCES))

all: $(OBJECTS)

$(OUTDIR)/%_0_1.png: %.aseprite
	$(ASEPRITE) $< $(ASE_SCRIPT)
	mkdir -p $(OUTDIR)
	mv $(patsubst %.aseprite,%_out,$<)/*.png $(OUTDIR)
	rm -d $(patsubst %.aseprite,%_out,$<)


.PHONY: all