; boot/memmap.asm - ask the BIOS for the physical memory map (E820) and show it.
; Needs print16.asm and hex32.asm included first. BIOS-only: real mode.
; Ref: https://wiki.osdev.org/Detecting_Memory_(x86)#BIOS_Function:_INT_0x15,_EAX_=_0xE820

MMAP_COUNT   equ 0x8FF0     ; word: number of entries found
MMAP_ENTRIES equ 0x9000     ; array of 24-byte entries, kept for the kernel later
MMAP_MAX     equ 64         ; stop here so we can never overrun into other memory
E820_MAGIC   equ 0x534D4150 ; 'SMAP', required in edx, echoed back in eax

; ---------------------------------------------------------------------------
; detect_memory: fill MMAP_ENTRIES using int 0x15 / eax=0xE820.
;   out: CF=0 success (MMAP_COUNT set), CF=1 E820 unsupported/failed.
;   Clobbers eax, ebx, ecx, edx, di. (We avoid bp: some BIOSes trash it.)
; ---------------------------------------------------------------------------
detect_memory:
    xor ebx, ebx            ; continuation value: 0 = "give me the first entry"
    mov di, MMAP_ENTRIES    ; es:di = where the BIOS writes the entry (es = 0)
    mov word [MMAP_COUNT], 0
.next:
    mov dword [di + 20], 1  ; pre-set the "extended attributes" dword so that a
                            ; BIOS that ignores it still looks valid (ACPI 3.0)
    mov eax, 0xE820         ; function: query system address map
    mov edx, E820_MAGIC     ; 'SMAP' signature
    mov ecx, 24             ; our buffer is 24 bytes per entry
    int 0x15
    jc .carry               ; CF: unsupported (first call) or end of list (later)
    cmp eax, E820_MAGIC     ; BIOS must echo 'SMAP' back; otherwise it's not E820
    jne .fail
    inc word [MMAP_COUNT]
    add di, 24              ; next slot in our array
    test ebx, ebx           ; ebx = 0 means that was the LAST entry
    jz .done
    cmp word [MMAP_COUNT], MMAP_MAX
    jb .next                ; DON'T touch ebx: the BIOS needs it back unchanged
.done:
    clc
    ret
.carry:
    cmp word [MMAP_COUNT], 0
    jne .done               ; carry after >= 1 entry just means "end of list"
.fail:
    stc
    ret

; ---------------------------------------------------------------------------
; print_memmap: print every entry as BASE / LENGTH / TYPE, then total usable.
;   Clobbers eax, bx, cx, si, di, edx.
; ---------------------------------------------------------------------------
print_memmap:
    mov si, msg_mmap_hdr
    call print_string
    mov dword [mem_total], 0
    mov cx, [MMAP_COUNT]    ; rows to print (cx is preserved by our print_hex)
    mov di, MMAP_ENTRIES
.row:
    mov si, di              ; base: 8 bytes at [di]
    call print_hex64
    mov si, msg_sep
    call print_string
    lea si, [di + 8]        ; length: 8 bytes at [di+8]
    call print_hex64
    mov si, msg_sep
    call print_string
    mov edx, [di + 16]      ; type: dword at [di+16]
    call print_type
    mov si, msg_crlf
    call print_string

    cmp dword [di + 16], 1  ; type 1 = usable RAM: add to the running total.
    jne .skip               ; (low dword only: fine below 4 GiB, which is all
    mov eax, [di + 8]       ;  we can see at this stage)
    add [mem_total], eax
.skip:
    add di, 24
    loop .row               ; cx--; repeat while cx != 0

    mov si, msg_total
    call print_string
    mov edx, [mem_total]
    call print_hex32
    mov si, msg_bytes
    call print_string
    ret

; print_type: print the name of E820 region type edx (1..5, else "unknown").
print_type:
    mov si, t_unknown
    cmp edx, 1
    jb .print
    cmp edx, 5
    ja .print
    mov bx, dx              ; type 1..5 -> index 0..4 into the pointer table
    dec bx
    shl bx, 1               ; each table entry is a 2-byte pointer
    mov si, [type_names + bx]
.print:
    call print_string
    ret

; --- data ------------------------------------------------------------------
mem_total:    dd 0
msg_mmap_hdr: db 'BASE              LENGTH            TYPE', 13, 10, 0
msg_sep:      db '  ', 0
msg_total:    db 'Usable RAM:  0x', 0
msg_bytes:    db ' bytes', 13, 10, 0
type_names:   dw t_usable, t_reserved, t_acpi_rec, t_acpi_nvs, t_bad
t_usable:     db '1 usable', 0
t_reserved:   db '2 reserved', 0
t_acpi_rec:   db '3 ACPI reclaimable', 0
t_acpi_nvs:   db '4 ACPI NVS', 0
t_bad:        db '5 bad memory', 0
t_unknown:    db '? unknown', 0
