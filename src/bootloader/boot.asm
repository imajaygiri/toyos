org 0x7c00
bits 16
ORIGIN_MEM equ 0x7c00

jmp short main
nop

bdb_oem:                        db "MSWIN4.1"
bdb_bytes_per_sector:           dw 512
bdb_sectors_per_cluster:        db 1
bdb_reserved_sectors:           dw 1
bdb_fat_count:                  db 2
bdb_dir_entries_count:          dw 0x0E0
bdb_total_sectors:              dw 2880
bdb_media_descriptor_type:      db 0x0f0
bdb_sectors_per_fat:            dw 9
bdb_sector_per_track:           dw 18
bdb_heads:                      dw 2
bdb_hidden_sectors:             dd 2 
bdb_large_sectors_count:        dd 0

ebr_driver_number:              db 0
                                db 0

ebr_signature:                  db 29H
ebr_volume_id:                  db 12h,34h,56h,78h
ebr_volume_label:               db "MYOS       "
ebr_system_id:                  db "FAT12   "



main: 
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp, ORIGIN_MEM

    mov si, os_boot_msg 
    call print
    hlt

halt: 
    jmp halt
    

print:
     push si
     push ax
     push bx


print_loop:
    lodsb  ; loads char to al pointed by si(source index reg)
    or al, al
    jz print_done
    ; if not end of string, do bios int to print
    mov ah, 0x0e ; printing char to string 
    mov bh, 0 ; page no as argument
    int 0x10 ; video print

    jmp print_loop

print_done: 
    pop bx
    pop ax
    pop si


os_boot_msg: db "Welcome to myos", 0x0d, 0x0a,0

times 510-($-$$) db 0x0
dw 0xaa55
