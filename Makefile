
all: Sprites

Sprites:
	$(MAKE) -C aseprite

.PHONY: all install fetch Sprites

FILES  = $(wildcard *.l)
FILES += $(wildcard *.ld)
FILES += $(wildcard *.png)
FILES += world_data.txt
DIRS += Sprites

install: all $(FILES) $(DIRS)
	install -d '/c/Program Files (x86)/Steam/steamapps/common/Baba Is You/Data/Worlds/levels'
	install $(FILES) '/c/Program Files (x86)/Steam/steamapps/common/Baba Is You/Data/Worlds/levels'
	cp -r $(DIRS) '/c/Program Files (x86)/Steam/steamapps/common/Baba Is You/Data/Worlds/levels/'

fetch: 
	cp '/c/Program Files (x86)/Steam/steamapps/common/Baba Is You/Data/Worlds/levels/'/*.l .
	cp '/c/Program Files (x86)/Steam/steamapps/common/Baba Is You/Data/Worlds/levels/'/*.ld .
	cp '/c/Program Files (x86)/Steam/steamapps/common/Baba Is You/Data/Worlds/levels/'/*.png .
	cp '/c/Program Files (x86)/Steam/steamapps/common/Baba Is You/Data/Worlds/levels/'/world_data.txt .

package: all $(FILES) $(DIRS)
	install -d Baba-is-Outer
	install $(FILES) Baba-is-Outer
	cp -r $(DIRS) Baba-is-Outer