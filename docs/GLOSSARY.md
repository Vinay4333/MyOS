# Glossary

Terms in the order we meet them.

- **BIOS**: firmware on the motherboard that initializes hardware at power-on and loads the boot sector.
- **Real mode**: the 16-bit mode every x86 CPU starts in. No protection, ~1 MB of memory.
- **Boot sector**: the first 512 bytes of the disk; the BIOS loads it to `0x7C00` and runs it.
- **Boot signature**: bytes `55 AA` at offsets 510-511 that mark a sector as bootable.
- **Segment register** (`ds`, `es`, `ss`, `cs`): in real mode, physical address = `segment * 16 + offset`.
- **Stack**: memory used for calls and temporary values; on x86 it grows downward.
- **Interrupt** (`int N`): a numbered call into a handler. In real mode, `int 0x10` calls BIOS video services.
- **`hlt`**: instruction that sleeps the CPU until the next interrupt.
- **Little-endian**: multi-byte values are stored low byte first, so `0xAA55` is stored as `55 AA`.
- **QEMU**: software that emulates a whole PC so we can boot our OS safely.
