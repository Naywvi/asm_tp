global _start

section .data
    msg: db "1337", 0

section .text

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, 6
    syscall

_exit:
    mov rax, 60
    mov rdi, 0
    syscall
