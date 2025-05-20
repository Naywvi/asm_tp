section .data
    msg db "1", "3", "3", "7", 10
    len equ $ - msg

section .text
    global _start
    
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, len
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall
