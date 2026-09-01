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

ebr_drive_number:              db 0
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
    mov sp, ORIGIN_MEM ; moved sp to 0x7c00

	;    AH = 02
	; AL = number of sectors to read	(1-128 dec.)
	; CH = track/cylinder number  (0-1023 dec., see below)
	; CL = sector number  (1-17 dec.)
	; DH = head number  (0-15 dec.)
	; DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
	; ES:BX = pointer to buffer
	;
	;
	; on return:
	; AH = status  (see INT 13,STATUS)
	; AL = number of sectors read
	; CF = 0 if successful
	;    = 1 if error


    mov dl, byte [ebr_drive_number]
    mov ax, 1 ; this is lba convert it to chs
    mov cl, 1 ; sector number 1
    mov bx, 0x7e00 ; buffer, poiter to memory location on disk
    call disk_read ; fxn to read disk


    mov si, os_boot_msg 
    call print
    hlt

halt: 
    jmp halt

lba_to_chs:
    ; convert lba index to CHA form
    ;input: LBA index in AX
    ;output: 
    ; cx[bits 0 - 5]: sector number
    ; cx[bits 5-15]: cylinder
    ; dh: head
    push ax
    push dx

    xor dx, dx
    ; lba index is in AX = 1
    ; sector = (lba % sector_per_track) + 1
    ; remainder is in dx
    div word [bdb_sector_per_track] 
    inc dx ; this will give sector dx(remainder) + 1(inc dx) = sector
    mov cx, dx ; now cx stores sector


    xor dx, dx
    ; head: (lba / sector_per_track) % number of head
    ; cylinder: (lba / sector_per_track) / number of head
    ; we have (lba/sector_per_track) result in ax
    div word [bdb_heads]
    
    mov dh , dl ;head:  moving lower val of dx to dl
    mov ch, al
    shl ah, 6
    or cl , ah ; cylinder

    pop dx
    pop ax

    ret

    
disk_read:
    ; preserve register value 
    push ax
    push bx
    push cx
    push dx
    push di

    push cx         ; SAVE cx (which holds the sector count) because lba_to_chs overwrites it!
    call lba_to_chs
    pop ax          ; POP the saved sector count into ax. This sets AL to the number of sectors to read!
    
    mov ah, 0x02 ; to read disk mov 02h to ah
    mov di, 3 ; counter to try atleast 3 times


    
retry:
    stc ; set the carry as bios does not set the CF
    int 13h ; bios read disk interupt
    ; check CF if it succeeded in
    jnc done_read ; if CF = 0 

    call disk_reset
    dec di ; decrement the counter
    test di,di ; if di is zero
    jnz retry ; if not zero

fail_disk_read:
    mov si, read_fail_msg ; mov failure_msg_string to si
    call print
    hlt
    ; if some how hlt fail , jmp to infite loop
    jmp halt

disk_reset:
    pusha
    mov ah,0
    stc ; to check if disk reset succeded 
    int 13h
    jc fail_disk_read ; if cf = 1
    popa
    ret

done_read:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

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
read_fail_msg: db "Failed to read the disk",0x0d, 0x0a,0


times 510-($-$$) db 0x0
dw 0xaa55
