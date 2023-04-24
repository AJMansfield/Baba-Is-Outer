PACK_NAME = Baba-Is-Outer

BABA_PATH = /c/Program Files (x86)/Steam/steamapps/common/Baba Is You/
BABA_EDIT_PATH = $(BABA_PATH)/Data/Worlds/levels
BABA_INSTALL_PATH = $(BABA_PATH)/Data/Worlds/$(PACK_NAME)

TOOL_DIR = toolchain
SPRITE_DIR = Sprites

ASEPRITE = $(TOOL_DIR)/aseprite.sh --batch
SPRITE_SCRIPT = --script $(TOOL_DIR)/baba_sprite_export.lua

SPRITE_SOURCES = $(wildcard aseprite/*.aseprite)
SPRITE_OBJECTS = $(patsubst aseprite/%.aseprite,$(SPRITE_DIR)/%_0_1.png,$(SPRITE_SOURCES))

$(SPRITE_DIR)/%_*_*.png: aseprite/%.aseprite
	$(ASEPRITE) $< $(SPRITE_SCRIPT)
	mkdir -p $(SPRITE_DIR)
	mv $(patsubst %.aseprite,%_out,$<)/*.png $(SPRITE_DIR)
	rm -d $(patsubst %.aseprite,%_out,$<)

FILES  = $(wildcard *.l)
FILES += $(wildcard *.ld)
FILES += $(wildcard *.png)
FILES += world_data.txt
FILES += $(wildcard $(SPRITE_DIR)/*.png)
FILES += $(wildcard Lua/*)

$(PACK_NAME).zip: all $(FILES)
	@for f in $(FILES) ; do \
		echo install -D $$f $(PACK_NAME)/$$f ; \
		install -D $$f $(PACK_NAME)/$$f ; \
	done
	$(TOOL_DIR)/mkzip.sh $(PACK_NAME).zip $(PACK_NAME)
	rm -rd $(PACK_NAME)/


all: $(SPRITE_OBJECTS)

edit: $(PACK_NAME).zip # copy the level data into the level editor world path
	tar -xf $(PACK_NAME).zip $(BABA_EDIT_PATH)

save: # copy any modified level editor data back into the repo
	cp "$(BABA_EDIT_PATH)/*.l" "$(BABA_EDIT_PATH)/*.ld" "$(BABA_EDIT_PATH)/*.png" "$(BABA_EDIT_PATH)/world_data.txt" .

package: $(PACK_NAME).zip

install: $(PACK_NAME).zip
	tar -xf $(PACK_NAME).zip $(BABA_INSTALL_PATH)

clean:
	rm Sprites/*
	rm $(PACK_NAME).zip
	rm -rd $(PACK_NAME)/
	rm -rd *_out/

.PHONY: all edit save package install clean
