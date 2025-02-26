global _start

section .bss
    buffer resb 8 ;resb = reserve byte

section .data
    msg: db "1337", 0 ;db = double byte

section .text

_start:
;sys_read
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 8
    syscall

    mov al, [buffer]
    cmp al, x34
    jne _error
    
;sys_write
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, 6
    syscall
    
_exit:
    mov rax, 60
    mov rdi, 0
    syscall