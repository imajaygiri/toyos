org 0x7c00
bits 16

ORIGIN_MEM equ 0x7c00

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
