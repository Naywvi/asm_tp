section .data
    elf_magic db 0x7F, "ELF", 0
    buffer times 16 db 0

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    
    mov rax, 2
    xor rsi, rsi
    xor rdx, rdx
    syscall
    
    cmp rax, 0
    jl exit_error
    
    mov rdi, rax
    mov rsi, buffer
    mov rdx, 16
    xor rax, rax
    syscall
    
    mov rax, 3
    syscall
    
    cmp byte [buffer], 0x7F
    jne not_elf
    
    cmp byte [buffer+1], 'E'
    jne not_elf
    
    cmp byte [buffer+2], 'L'
    jne not_elf
    
    cmp byte [buffer+3], 'F'
    jne not_elf
    
    cmp byte [buffer+4], 2
    jne not_elf
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
not_elf:
    mov rax, 60
    mov rdi, 1
    syscall
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
