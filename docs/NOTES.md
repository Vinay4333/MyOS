# MyOS Notes

A running log, one entry per step: what we did, what it does, what we learned, how to verify.
Newest entries at the bottom.

---

## M0 — Environment
- Windows 11 host. Build and run inside **WSL2 (Ubuntu)**.
- Tools: `nasm` 3.01 (assembler), `gcc` 15.2 (C compiler), `make`, `qemu-system-x86_64` 10.2.1 (emulated PC), `gdb` (debugger).
- Repo is edited from Windows; built from `/mnt/c/Users/Vinay Kalyan Gajula/Desktop/Dev Stuff/OS/MyOS`.

---

## M1 / Step 1 — Boot sector that prints `A`
**Files:** `boot/boot.asm`, `Makefile`

**What it does:** 512 bytes the BIOS loads and runs; it prints one character and halts.

**How a PC boots (the part we learned):**
1. CPU powers on in **16-bit real mode** (8086 compatibility), no memory protection, ~1 MB addressable.
2. BIOS initializes hardware, reads disk sector 0 (512 bytes) to physical `0x7C00`, jumps there.
3. BIOS only accepts the sector if bytes 510-511 are `55 AA` (the boot signature).

**Key points in the code:**
- `[org 0x7C00]`: assembler directive, so label addresses match where we're loaded. Emits no code.
- Real-mode address = `segment * 16 + offset`. BIOS leaves segments in unknown state, so we zero `ds/es/ss`.
- Stack starts at `0x7C00` and grows down, into free memory below our code.
- `int 0x10`, `ah=0x0E`: BIOS "teletype" print. BIOS services only exist in real mode.
- `hlt` loop: sleeps the CPU instead of spinning. Cheaper than `jmp $`.
- `dw 0xAA55` is stored `55 AA` because x86 is **little-endian** (low byte first).

**Verify:**
- `make` produces `build/os.img` of exactly 512 bytes; `xxd -s 510 build/os.img` shows `55aa`.
- `make run` opens QEMU and shows a single `A`.

**Experiments to try:** change the character; remove the signature and watch the BIOS refuse to boot.
