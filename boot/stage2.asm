; boot/stage2.asm - STAGE 2: loaded by stage 1 at 0x7E00.
; We're still in 16-bit real mode with BIOS available. Stage 1 left us with
; segments = 0, a working stack, interrupts on, DF clear, and dl = boot drive.
; This is where the real bootloader work will go (memory map, mode switches...).
[bits 16]
[org 0x7E00]

stage2:
    push dx             ; remember the boot drive (dl) across the prints below

    mov si, msg_hello
    call print_string

    mov si, msg_addr    ; prove where we are running: expect 0x7E00
    call print_string
    mov dx, stage2      ; address of this very label
    call print_hex
    mov si, msg_crlf
    call print_string

    mov si, msg_drive
    call print_string
    pop dx              ; boot drive back in dl
    xor dh, dh          ; clear the high byte: print 0x0080, not 0x??80
    call print_hex
    mov si, msg_crlf
    call print_string

    mov si, msg_far     ; this string lives in the SECOND sector (offset 512+)
    call print_string   ; it only prints if both sectors were really loaded

.hang:
    hlt
    jmp .hang

%include "print16.asm"

; --- data (first sector) ---------------------------------------------------
msg_hello: db 'Stage 2: hello from 0x7E00!', 13, 10, 0
msg_addr:  db 'Running at:  0x', 0
msg_drive: db 'Boot drive:  0x', 0
msg_crlf:  db 13, 10, 0

times 512 - ($ - $$) db 0   ; pad to exactly one sector; errors if code > 512

; --- second sector ---------------------------------------------------------
msg_far:   db 'Sector 2 of stage 2 loaded OK (read past the first 512 bytes).', 13, 10, 0

times 1024 - ($ - $$) db 0  ; pad to exactly two sectors (stage 1 reads 2)
