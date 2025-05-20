section .data
    message db "Hello Universe!", 10, 0
    message_len equ $ - message - 1

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    
    mov rax, 2
    mov rsi, 0102o
    mov rdx, 0666o
    syscall
    
    cmp rax, 0
    jl exit_error
    
    mov rdi, rax
    mov rax, 1
    mov rsi, message
    mov rdx, message_len
    syscall
    
    mov rax, 3
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
