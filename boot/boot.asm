; boot/boot.asm - STAGE 1: the 512-byte boot sector.
; The BIOS loads this to physical address 0x7C00 and jumps to it, in 16-bit
; real mode. Its only job: load stage 2 from the disk and jump to it.
; See https://wiki.osdev.org/Boot_Sequence
[bits 16]               ; emit 16-bit instructions (CPU is in real mode)
[org 0x7C00]            ; we are loaded at 0x7C00; make label addresses match

STAGE2_ADDR    equ 0x7E00   ; right after this sector; free RAM up to ~0x7FFFF
%ifndef STAGE2_SECTORS      ; passed by the Makefile: size of stage2.bin / 512
    %error "STAGE2_SECTORS not defined: build with make, not by hand"
%endif
STAGE2_LBA     equ 1        ; LBA 0 = this sector, so stage 2 starts at LBA 1

start:
    mov [boot_drive], dl ; BIOS passes the boot drive number in dl. Save it
                        ; FIRST, before anything can overwrite dl.
    cli                 ; disable interrupts while we set up segments/stack
    xor ax, ax          ; ax = 0
    mov ds, ax          ; data segment  = 0  (address = 0*16 + offset)
    mov es, ax          ; extra segment = 0
    mov ss, ax          ; stack segment = 0
    mov sp, 0x7C00      ; stack grows DOWN from just below our own code
    sti                 ; interrupts back on (BIOS int 0x10/0x13 may need them)
    cld                 ; direction flag = 0: string ops move FORWARD.

    mov si, msg_stage1
    call print_string

    ; --- read stage 2 from disk using BIOS "extended read" (LBA) -----------
    mov ah, 0x42        ; int 0x13 fn 42h: extended read sectors (LBA)
    mov dl, [boot_drive]; which disk
    mov si, dap         ; ds:si -> Disk Address Packet describing the read
    int 0x13            ; do it. On failure: CF=1 and ah=error code
    jc disk_error

    mov dl, [boot_drive]; hand the boot drive to stage 2 in dl
    jmp STAGE2_ADDR     ; jump into stage 2; we never come back

disk_error:
    mov dx, ax          ; save error code (ah) before print_string clobbers ax
    mov si, msg_diskerr
    call print_string
    call print_hex      ; print dx; the error code is the HIGH byte (e.g. 0x0100)
.hang:
    hlt
    jmp .hang

%include "print16.asm"  ; print_string, print_hex (shared with stage 2)

; --- data ------------------------------------------------------------------
boot_drive:  db 0
msg_stage1:  db 'Stage 1: loading stage 2...', 13, 10, 0
msg_diskerr: db 'Disk read error 0x', 0

; Disk Address Packet: 16 bytes, tells the BIOS what to read and where to put it.
align 4
dap:
    db 0x10                 ; size of this packet (16 bytes)
    db 0                    ; reserved, must be 0
    dw STAGE2_SECTORS       ; how many sectors to read
    dw STAGE2_ADDR          ; destination offset...
    dw 0x0000               ; ...and destination segment (0000:7E00 = 0x7E00)
    dq STAGE2_LBA           ; first sector to read (64-bit LBA)

times 510 - ($ - $$) db 0   ; pad with zeros up to byte 510
dw 0xAA55                   ; boot signature; stored little-endian as 55 AA
