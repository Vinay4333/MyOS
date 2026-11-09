; boot/hex32.asm - 32/64-bit hex printing, built on print_hex. Stage 2 only
; (stage 1 has no spare bytes). Include AFTER print16.asm.
; In 16-bit real mode we can still use 32-bit registers (eax, edx...): NASM adds
; the 0x66 operand-size prefix automatically. Needs a 386+ CPU.

; print_hex32: print edx as 8 hex digits. Preserves all registers.
print_hex32:
    ror edx, 16         ; swap halves: the HIGH word is now in dx
    call print_hex      ; print the high 16 bits
    ror edx, 16         ; swap back: low word in dx, edx restored
    call print_hex      ; print the low 16 bits
    ret

; print_hex64: print the 64-bit little-endian value at [si] as 16 hex digits.
;   in: si = address of 8 bytes. Preserves all registers except si.
print_hex64:
    push edx
    mov edx, [si + 4]   ; little-endian: the HIGH dword is at the higher address
    call print_hex32
    mov edx, [si]       ; then the low dword
    call print_hex32
    pop edx
    ret
