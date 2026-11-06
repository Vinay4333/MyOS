; boot/boot.asm - the 512-byte boot sector.
; The BIOS loads this to physical address 0x7C00 and jumps to it, in 16-bit
; real mode. See https://wiki.osdev.org/Boot_Sequence
[bits 16]               ; emit 16-bit instructions (CPU is in real mode)
[org 0x7C00]            ; we are loaded at 0x7C00; make label addresses match

start:
    mov [boot_drive], dl ; BIOS passes the boot drive number in dl. Save it
                        ; FIRST, before anything can overwrite dl (needed for
                        ; disk reads later). [org 0x7C00] makes this address right.
    cli                 ; disable interrupts while we set up segments/stack
    xor ax, ax          ; ax = 0
    mov ds, ax          ; data segment  = 0  (address = 0*16 + offset)
    mov es, ax          ; extra segment = 0
    mov ss, ax          ; stack segment = 0
    mov sp, 0x7C00      ; stack grows DOWN from just below our own code
    sti                 ; interrupts back on (the BIOS int 0x10 may need them)
    cld                 ; direction flag = 0: string ops (lodsb) move FORWARD.
                        ; BIOS may leave it set, so never assume.

    mov si, msg_hello   ; si = address of the string to print
    call print_string   ; push return address on the stack, jump to routine

    mov si, msg_test    ; test value: we expect to see 0xBEEF
    call print_string
    mov dx, 0xBEEF
    call print_hex
    mov si, msg_crlf
    call print_string

    mov si, msg_drive   ; boot drive: 0x0080 = first hard disk on a BIOS PC
    call print_string
    xor dx, dx
    mov dl, [boot_drive]
    call print_hex
    mov si, msg_crlf
    call print_string

.hang:
    hlt                 ; sleep the CPU until the next interrupt (saves power)
    jmp .hang           ; ...and sleep again, forever

; ---------------------------------------------------------------------------
; print_string: print a 0-terminated string using BIOS teletype output.
;   in:  si = address of string
;   out: nothing. Clobbers ax, bx (si ends up just past the terminator).
; ---------------------------------------------------------------------------
print_string:
    mov ah, 0x0E        ; BIOS video fn 0Eh: teletype output (print char in al)
    xor bx, bx          ; bh = display page 0, bl = colour (unused in text mode)
.next:
    lodsb               ; al = [si]; si = si + 1
    or al, al           ; set flags from al without changing it (is it 0?)
    jz .done            ; zero terminator -> finished
    int 0x10            ; BIOS prints al (ah is still 0x0E)
    jmp .next
.done:
    ret                 ; pop return address from the stack, jump back

; ---------------------------------------------------------------------------
; print_hex: print a 16-bit value as 4 hex digits (no "0x" prefix).
;   in:  dx = value to print
;   out: nothing. Preserves all registers except dx (dx ends up unchanged,
;        since 4 rotates by 4 bits = a full 16-bit turn).
; ---------------------------------------------------------------------------
print_hex:
    push ax
    push bx
    push cx
    mov cx, 4           ; 4 nibbles in 16 bits
    mov ah, 0x0E        ; BIOS teletype
    xor bx, bx          ; page 0
.digit:
    rol dx, 4           ; rotate left 4: top nibble moves into the low 4 bits
    mov al, dl
    and al, 0x0F        ; keep only the low nibble: 0..15
    add al, '0'         ; 0..9 -> '0'..'9'
    cmp al, '9'
    jbe .print          ; it was 0..9, done converting
    add al, 'A' - '9' - 1   ; 10..15 -> 'A'..'F' (skip the 7 chars between '9' and 'A')
.print:
    int 0x10
    loop .digit         ; cx = cx - 1; jump if cx != 0
    pop cx
    pop bx
    pop ax
    ret

; --- data ------------------------------------------------------------------
boot_drive: db 0                              ; filled in at start
msg_hello:  db 'Hello from MyOS!', 13, 10, 0  ; 13=CR, 10=LF, 0=terminator
msg_test:   db 'Test value:  0x', 0
msg_drive:  db 'Boot drive:  0x', 0
msg_crlf:   db 13, 10, 0

times 510 - ($ - $$) db 0   ; pad with zeros up to byte 510
dw 0xAA55                   ; boot signature; stored little-endian as 55 AA
