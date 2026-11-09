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

---

## M1 / Step 2 — `print_string`
**Files:** `boot/boot.asm`

**What it does:** a reusable routine that prints a 0-terminated string via BIOS `int 0x10`; boots and shows `Hello from MyOS!`.

**What we learned:**
- A string is bytes in memory; a `0` byte marks the end (same as C strings).
- `lodsb`: `al = [si]; si++` in one instruction. `si` is the conventional "read pointer" register.
- `cld` clears the **direction flag** so `lodsb` goes forward. BIOS may leave it set, so we set it ourselves. Never assume firmware state.
- `call` pushes the return address on the stack and jumps; `ret` pops it. First real use of the stack from Step 1.
- `or al, al` tests for zero without changing `al`; `jz` jumps if it was zero.
- Newline needs both CR (13) and LF (10).
- Calling convention (ours, informal): argument in a register, document which registers are clobbered in the routine's header comment.

**Verify:** `make run` shows `Hello from MyOS!`. `strings build/os.img` shows the text.

**Experiments:** remove the `0` terminator (prints garbage past the string); call the routine twice with different strings.

---

## M1 / Step 3 — `print_hex` and the boot drive
**Files:** `boot/boot.asm`

**What it does:** `print_hex` prints a 16-bit value in `dx` as 4 hex digits. Boot prints `0xBEEF` (test) and the boot drive number (`0x0080`).

**What we learned:**
- 1 hex digit = 4 bits = a **nibble**. That is why hex is the natural way to read binary data.
- `rol dx, 4` rotates the top nibble into the bottom; `and al, 0x0F` isolates it. Four rotations of 4 bits restore `dx`.
- Nibble to ASCII: add `'0'`; if the result is past `'9'`, add 7 more to jump the gap to `'A'`.
- `loop` = `cx--; if (cx != 0) jump`.
- **Save registers you use** (`push`/`pop`) so the caller's values survive. Better convention than "clobbers".
- The BIOS passes the **boot drive number in `dl`** at entry. `0x80` = first hard disk. Save it before anything overwrites `dl`; we need it to read the disk.

**Verify:** `make run` shows `Test value:  0xBEEF` and `Boot drive:  0x0080`.

**Experiments:** try `0x09AF` (digits + letters); break the `'A' - '9' - 1` adjustment; overwrite `dl` before saving it.

---

## M1 / Step 4 — Two-stage boot: read stage 2 from disk
**Files:** `boot/boot.asm` (stage 1), `boot/stage2.asm` (new), `boot/print16.asm` (new, shared), `Makefile`

**What it does:** stage 1 (the 512-byte boot sector) reads stage 2 (2 sectors) from disk into `0x7E00` and jumps to it. Stage 2 prints its own address, the boot drive, and a string stored in *its* second sector, proving both sectors loaded.

**Why two stages:** 512 bytes is too small for a real bootloader. Stage 1 only loads; stage 2 has room for the real work (memory map, mode switches, kernel loading).

**What we learned:**
- **CHS vs LBA.** CHS (cylinder/head/sector) mirrors old floppy geometry and fails on big disks. LBA numbers sectors 0,1,2,... from the start. We use BIOS `int 0x13`, `ah=0x42` (extended read, LBA).
- **Disk Address Packet (DAP):** 16-byte struct the BIOS reads via `ds:si`: size (0x10), reserved, sector count, destination offset, destination segment, 64-bit start LBA.
- **Carry flag = BIOS error signal.** After `int 0x13`, `CF=1` means failure and `ah` holds the code; `jc` branches on it. Always check it.
- **Error codes are BIOS-specific.** An out-of-range LBA gave `0x01` (invalid parameter) on SeaBIOS, not `0x04` (sector not found) as expected. Don't rely on specific codes.
- Disk layout: LBA 0 = stage 1, LBA 1-2 = stage 2. The Makefile builds each separately and `cat`s them into `os.img`.
- `%include` + `-I boot/` shares code between stages. `[org]` must match where the code is actually loaded, or every label address is wrong.
- `times N - ($ - $$) db 0` pads to an exact size and makes NASM error if the code grew past it. Stage 1 must stay <= 510 bytes.
- Stage 1 hands the boot drive to stage 2 in `dl`, the same convention the BIOS used with us.

**Memory map so far:** `0x7C00-0x7DFF` stage 1 (stack grows down from `0x7C00`), `0x7E00-0x81FF` stage 2.

**Verify:** `make run` shows stage 1 message, then `Running at:  0x7E00`, `Boot drive:  0x0080`, and the "Sector 2 ... loaded OK" line.

**Experiments done:** `STAGE2_LBA = 4` (past end of image) gave `Disk read error 0x0100`. Also try `STAGE2_SECTORS = 1` (last line disappears).
