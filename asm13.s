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
    
check_loop:
    cmp rcx, rbx
    jge is_palindrome
    
    mov dl, [buffer + rcx]
    cmp dl, [buffer + rbx]
    jne not_palindrome
    
    inc rcx
    dec rbx
    jmp check_loop
    
is_palindrome:
    mov rax, 60
    xor rdi, rdi
    syscall
    
not_palindrome:
    mov rax, 60
    mov rdi, 1
    syscall
