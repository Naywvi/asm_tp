global _start

section .text

_start:
_exit:
    mov rax, 60
    mov rdi, 0
    syscall