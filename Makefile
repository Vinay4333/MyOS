ASM := nasm
QEMU := qemu-system-x86_64

all: build/os.img

build/boot.bin: boot/boot.asm
	@mkdir -p build
	$(ASM) -f bin $< -o $@

build/os.img: build/boot.bin
	cp $< $@

run: build/os.img
	$(QEMU) -drive format=raw,file=build/os.img

clean:
	rm -rf build

.PHONY: all run clean
