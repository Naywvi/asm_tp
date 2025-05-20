section .data
    buffer times 1024 db 0

section .text
    global _start

_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 1024
    syscall
    
    mov r8, rax
    dec r8
    
    cmp byte [buffer + r8], 10
    jne skip_newline
    dec r8
    
skip_newline:
    mov rcx, 0
    mov rbx, r8
    
reverse_loop:
    cmp rcx, rbx
    jge end_reverse
    
    mov dl, [buffer + rcx]
    mov dh, [buffer + rbx]
    mov [buffer + rcx], dh
    mov [buffer + rbx], dl
    
    inc rcx
    dec rbx
    jmp reverse_loop
    
end_reverse:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, r8
    inc rdx
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall
