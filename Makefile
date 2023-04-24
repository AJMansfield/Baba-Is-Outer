PACK_NAME = Baba-Is-Outer

BABA_PATH = /c/Program Files (x86)/Steam/steamapps/common/Baba Is You
BABA_EDIT_PATH = $(BABA_PATH)/Data/Worlds/levels
BABA_INSTALL_PATH = $(BABA_PATH)/Data/Worlds/$(PACK_NAME)

TOOL_DIR = toolchain
SPRITE_DIR = Sprites

ASEPRITE = $(TOOL_DIR)/aseprite.sh --batch
SPRITE_SCRIPT = --script $(TOOL_DIR)/baba_sprite_export.lua

SPRITE_SOURCES = $(wildcard aseprite/*.aseprite)
SPRITE_OBJECTS = $(patsubst aseprite/%.aseprite,$(SPRITE_DIR)/%_0_1.png,$(SPRITE_SOURCES))

$(SPRITE_DIR)/%_0_1.png: aseprite/%.aseprite
	$(ASEPRITE) $< $(SPRITE_SCRIPT)
	mkdir -p $(SPRITE_DIR)
	mv $(patsubst %.aseprite,%_out,$<)/*.png $(SPRITE_DIR)
	rm -d $(patsubst %.aseprite,%_out,$<)

DEPS  = $(wildcard *.l)
DEPS += $(wildcard *.ld)
DEPS += $(wildcard *.png)
DEPS  += world_data.txt
DEPS  += $(wildcard Lua/*)
FILES = $(DEPS)
DEPS  += $(SPRITE_OBJECTS)
FILES += $(wildcard $(SPRITE_DIR)/*.png)

$(PACK_NAME).zip: all
	@for f in $(FILES) ; do \
		echo install -D $$f $(PACK_NAME)/$$f ; \
		install -D $$f $(PACK_NAME)/$$f ; \
	done
	$(TOOL_DIR)/mkzip.sh $(PACK_NAME).zip $(PACK_NAME)

all: $(SPRITE_OBJECTS)

edit: $(PACK_NAME).zip # copy the level data into the level editor world path
	cp -r $(PACK_NAME) -T "$(BABA_EDIT_PATH)"

save: # copy any modified level editor data back into the repo
	$(TOOL_DIR)/save.sh "$(BABA_EDIT_PATH)"

package: $(PACK_NAME).zip

install: $(PACK_NAME).zip
	cp -r $(PACK_NAME) -T "$(BABA_INSTALL_PATH)""

clean:
	rm -f Sprites/*
	rm -f $(PACK_NAME).zip
	rm -rdf $(PACK_NAME)/
	rm -rdf *_out/

.PHONY: all edit save package install clean
