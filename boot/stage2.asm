; boot/stage2.asm - STAGE 2: loaded by stage 1 at 0x7E00.
; We're still in 16-bit real mode with BIOS available. Stage 1 left us with
; segments = 0, a working stack, interrupts on, DF clear, and dl = boot drive.
; This is where the real bootloader work goes (memory map, mode switches...).
[bits 16]
[org 0x7E00]

stage2:
    mov [boot_drive], dl

    mov si, msg_hello
    call print_string

    mov si, msg_drive
    call print_string
    xor dx, dx
    mov dl, [boot_drive]    ; print 0x0080, not 0x??80
    call print_hex
    mov si, msg_crlf
    call print_string

    call detect_memory      ; ask the BIOS for the physical memory map
    jc .no_e820
    call print_memmap
.hang:
    hlt
    jmp .hang

.no_e820:
    mov si, msg_no_e820
    call print_string
    jmp .hang

%include "print16.asm"
%include "hex32.asm"
%include "memmap.asm"

; --- data ------------------------------------------------------------------
boot_drive:  db 0
msg_hello:   db 'Stage 2: running at 0x7E00', 13, 10, 0
msg_drive:   db 'Boot drive:  0x', 0
msg_crlf:    db 13, 10, 0
msg_no_e820: db 'E820 memory map not supported!', 13, 10, 0

; Pad to a whole number of 512-byte sectors (stage 1 reads whole sectors, and
; the Makefile derives the sector count from this file's final size).
times (512 - ($ - $$) % 512) % 512 db 0
