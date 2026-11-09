; boot/print16.asm - 16-bit real-mode print helpers, shared by both stages.
; %include'd into boot.asm and stage2.asm. Uses BIOS int 0x10, so it only works
; in real mode. Assumes the direction flag is clear (cld).

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
;   out: nothing. Preserves all registers (dx unchanged, since 4 rotates by
;        4 bits = a full 16-bit turn).
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
