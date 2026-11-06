# Roadmap

Each milestone is a series of small steps. Check off as we go.

## M0 — Environment
- [ ] Install WSL2 + Ubuntu
- [ ] Install gcc, nasm, make, qemu-system-x86, gdb
- [ ] Verify: QEMU opens and runs an empty VM

## M1 — Boot sector (16-bit real mode)
- [ ] 512-byte boot sector that hangs forever (what the BIOS actually loads, and the 0xAA55 signature)
- [ ] Print a character via BIOS int 10h
- [ ] Print a string, then hex values (debugging tool for everything after)
- [ ] Read more sectors from disk (int 13h) — a boot sector is too small for anything real

## M2 — Stage 2 and the mode switches
- [ ] Enable the A20 line
- [ ] Query memory map (int 15h, E820) while BIOS is still available
- [ ] Build a GDT, switch to 32-bit protected mode
- [ ] Set up paging, enable PAE, switch to 64-bit long mode
- [ ] Jump into C

## M3 — Kernel hello world
- [ ] Freestanding C kernel, linker script, VGA text output
- [ ] Serial port (COM1) logging — works in QEMU `-serial stdio`
- [ ] `kprintf`, panic with register dump

## M4 — CPU setup
- [ ] Real GDT + TSS, IDT
- [ ] Exceptions (page fault, GPF, double fault) with readable output
- [ ] PIC remap -> APIC, timer interrupt
- [ ] Keyboard (PS/2) interrupt

## M5 — Memory management
- [ ] Physical memory manager (bitmap or buddy allocator) from the E820 map
- [ ] Virtual memory manager, kernel/user split, higher-half kernel
- [ ] Kernel heap (`kmalloc`/`kfree`)

## M6 — Processes
- [ ] Context switch, kernel threads
- [ ] Scheduler (start round-robin; later priority/CFS-like)
- [ ] User mode (ring 3), `syscall`/`sysret`, first syscalls

## M7 — Storage and filesystem
- [ ] ATA/AHCI or virtio-blk driver
- [ ] VFS layer, then own simple filesystem (or FAT32 for interop)
- [ ] ELF loader, run programs from disk

## M8 — Userspace
- [ ] Minimal libc, shell, a few utilities
- [ ] Text-mode, then framebuffer graphics

## M9 — Beyond
- [ ] SMP, networking (virtio-net, TCP/IP), USB, real hardware boot, benchmarks vs. Windows/Linux in `docs/BENCH.md`
