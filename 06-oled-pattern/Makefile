TRIPLE = armv6m-none-none-eabi
ELF2UF2 = swift ../Tools/elf2uf2.swift

.PHONY: build release clean

build:
	swift build --triple $(TRIPLE) --toolset toolset.json
	$(ELF2UF2) .build/$(TRIPLE)/debug/Application .build/firmware.uf2

release:
	swift build --triple $(TRIPLE) --toolset toolset.json -c release
	$(ELF2UF2) .build/$(TRIPLE)/release/Application .build/firmware.uf2

clean:
	swift package clean
