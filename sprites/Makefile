
SOURCEDIR = .
BUILDDIR = build/Sprites
TOOLDIR = ../toolchain

AESPRITE = /c/Program Files\ (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe
FLAGS = --batch --script $(TOOLDIR)/baba_sprite_export.lua

SOURCES = $(wildcard $(SOURCEDIR)/*.aesprite)
OBJECTS = $(pathsubst $(SOURCEDIR)/%.aesprite,$(BUILDDIR)/%_0_1.png,$(SPRITE_SOURCES))

sprites: $(SPRITE_OBJECTS)
build/Sprites/*_0_1.png: sprites/%.aesprite

