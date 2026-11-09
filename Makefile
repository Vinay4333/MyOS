ASM  := nasm
QEMU := qemu-system-x86_64

all: build/os.img

# Stage 1 (exactly 512 bytes) and stage 2 (exactly 1024 bytes). -I lets
# %include "print16.asm" find the shared file.
build/boot.bin: boot/boot.asm boot/print16.asm
	@mkdir -p build
	$(ASM) -f bin -I boot/ $< -o $@

build/stage2.bin: boot/stage2.asm boot/print16.asm
	@mkdir -p build
	$(ASM) -f bin -I boot/ $< -o $@

# The disk image is just the two binaries back to back: LBA 0 = stage 1,
# LBA 1-2 = stage 2.
build/os.img: build/boot.bin build/stage2.bin
	cat $^ > $@

run: build/os.img
	$(QEMU) -drive format=raw,file=build/os.img

clean:
	rm -rf build

.PHONY: all run clean
