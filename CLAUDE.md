# MyOS — rules for working in this repo

This is a from-scratch x86_64 operating system, built as a learning project the hard way.
Stack: NASM assembly + C, own BIOS bootloader (real -> protected -> long mode), built and run in WSL2 with QEMU.

## Teaching rules (most important)
1. **Explain before building.** For every step: first say *what we are about to do* and *what it does / why it exists*, then write the code.
2. **One small step at a time.** Each step must end in something runnable or observable (a char on screen, a register dump, a QEMU boot). No big-bang commits.
3. **No black boxes.** No bootloader, libc, or third-party kernel code. If we need a tool (nasm, gcc, qemu, make), it is a build tool only. Everything that runs inside the OS is ours.
4. **Comment the "why"**, especially for hardware magic numbers (ports, MSRs, flags, descriptor bits). Cite the spec (Intel SDM vol/section, OSDev wiki page) when it helps.
5. **Show the user how to verify** each step (command to run, what they should see, what a failure looks like).
7. **Define jargon on first use.** The user knows roughly 60-70% of OS/hardware terms. The first time a term appears (A20, GDT, MSR, PAE...), give a one-line plain-English definition. Don't re-define it later, but do add it to `docs/GLOSSARY.md`.
6. **Hand-work first, then abstract.** Do things the raw way once so the user understands, and only then wrap them in helpers.

## Engineering rules
- Build from WSL2 (Ubuntu). Targets live in the `Makefile`; `make run` boots in QEMU, `make debug` attaches gdb.
- Layout: `boot/` (asm bootloader), `kernel/` (C + asm kernel), `docs/` (notes per milestone), `tools/` (build helpers).
- Kernel C flags: freestanding, no stdlib, no red zone, `-mno-sse` until we deliberately enable SIMD, warnings as errors.
- Commit once per working step with a message saying what the step *taught* (e.g. "boot: enter protected mode"). Do not commit broken boots.
- Keep notes **per step**, not just per milestone. After every step, append an entry to `docs/NOTES.md` (files touched, what it does, what we learned, how to verify, experiments) and add new terms to `docs/GLOSSARY.md`. The notes update ships in the same commit as the step.

## Efficiency goals (vs. Windows)
Measure, don't claim. Every milestone should record numbers in `docs/BENCH.md` once there is something to measure.
Design bets, in order of realism:
1. **Boot time / footprint:** tiny kernel, no legacy driver cruft; target boot-to-shell in well under a second in QEMU and a RAM footprint in single-digit MB.
2. **Syscall and context-switch latency:** lean syscall path (`syscall`/`sysret`), O(1) scheduler.
3. **Memory:** no background services by default; everything optional is opt-in.
4. **Scope honesty:** we will not beat Windows at hardware support, app compatibility or security hardening. We can beat it on simplicity, latency, and footprint for what we do support.
