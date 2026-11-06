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
    cld                 ; direction flag = 0: string ops (lodsb) move FORWARD.
                        ; BIOS may leave it set, so never assume.

    mov si, msg_hello   ; si = address of the string to print
    call print_string   ; push return address on the stack, jump to routine

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

; --- data ------------------------------------------------------------------
msg_hello: db 'Hello from MyOS!', 13, 10, 0   ; 13=CR, 10=LF, 0=terminator

times 510 - ($ - $$) db 0   ; pad with zeros up to byte 510
dw 0xAA55                   ; boot signature; stored little-endian as 55 AA
