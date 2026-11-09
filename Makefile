ASM  := nasm
QEMU := qemu-system-x86_64

# Every asm file in boot/ (they %include each other); any change rebuilds both.
BOOT_SRC := $(wildcard boot/*.asm)

all: build/os.img

# Stage 2 first: its size decides how many sectors stage 1 must read.
build/stage2.bin: $(BOOT_SRC)
	@mkdir -p build
	$(ASM) -f bin -I boot/ boot/stage2.asm -o $@

# Stage 1 is exactly 512 bytes. -D passes the sector count of stage 2 into it
# so we never have to keep two numbers in sync by hand.
build/boot.bin: $(BOOT_SRC) build/stage2.bin
	$(ASM) -f bin -I boot/ -DSTAGE2_SECTORS=$$(( $$(stat -c %s build/stage2.bin) / 512 )) boot/boot.asm -o $@

# The disk image is just the two binaries back to back: LBA 0 = stage 1,
# LBA 1.. = stage 2.
build/os.img: build/boot.bin build/stage2.bin
	cat $^ > $@

run: build/os.img
	$(QEMU) -drive format=raw,file=build/os.img

clean:
	rm -rf build

.PHONY: all run clean
