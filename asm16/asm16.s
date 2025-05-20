section .data
    buffer times 4096 db 0

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    
    mov rax, 2
    mov rsi, 2
    mov rdx, 0644o
    syscall
    
    cmp rax, 0
    jl exit_error
    
    mov r8, rax
    
    mov rdi, rax
    xor rax, rax
    mov rsi, buffer
    mov rdx, 4096
    syscall
    
    mov r9, rax
    
    xor r10, r10
    
find_loop:
    cmp r10, r9
    jge exit_error
    
    lea rdi, [buffer + r10]
    
    cmp byte [rdi], '1'
    jne next_pos
    
    cmp byte [rdi+1], '3'
    jne next_pos
    
    cmp byte [rdi+2], '3'
    jne next_pos
    
    cmp byte [rdi+3], '7'
    jne next_pos
    
    mov byte [rdi], 'H'
    mov byte [rdi+1], '4'
    mov byte [rdi+2], 'C'
    mov byte [rdi+3], 'K'
    
    mov rax, 8
    mov rdi, r8
    xor rsi, rsi
    xor rdx, rdx
    syscall
    
    mov rax, 1
    mov rdi, r8
    mov rsi, buffer
    mov rdx, r9
    syscall
    
    mov rax, 3
    mov rdi, r8
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
next_pos:
    inc r10
    jmp find_loop
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
