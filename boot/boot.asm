; boot/boot.asm - the 512-byte boot sector.
; The BIOS loads this to physical address 0x7C00 and jumps to it, in 16-bit
; real mode. See https://wiki.osdev.org/Boot_Sequence
[bits 16]               ; emit 16-bit instructions (CPU is in real mode)
[org 0x7C00]            ; we are loaded at 0x7C00; make label addresses match

start:
    cli                 ; disable interrupts while we set up segments/stack
    xor ax, ax          ; ax = 0
    mov ds, ax          ; data segment  = 0  (address = 0*16 + offset)
    mov es, ax          ; extra segment = 0
    mov ss, ax          ; stack segment = 0
    mov sp, 0x7C00      ; stack grows DOWN from just below our own code
    sti                 ; interrupts back on (the BIOS int 0x10 may need them)

    mov ah, 0x0E        ; BIOS video fn 0Eh: teletype output (print char in al)
    mov al, 'A'
    mov bh, 0           ; display page 0
    int 0x10            ; call into the BIOS

.hang:
    hlt                 ; sleep the CPU until the next interrupt (saves power)
    jmp .hang           ; ...and sleep again, forever

times 510 - ($ - $$) db 0   ; pad with zeros up to byte 510
dw 0xAA55                   ; boot signature; stored little-endian as 55 AA
