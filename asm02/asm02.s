section .data
    output db "1337", 10
    output_len equ $ - output
    buf times 4 db 0

section .text
    global _start

_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, buf
    mov rdx, 4
    syscall
    
    cmp byte [buf], '4'
    jne exit_with_error
    cmp byte [buf+1], '2'
    jne exit_with_error
    cmp byte [buf+2], 10
    jne exit_with_error
    
    mov rax, 1
    mov rdi, 1
    mov rsi, output
    mov rdx, output_len
    syscall
    
    mov rax, 60
    mov rdi, 0
    syscall
    
exit_with_error:
    mov rax, 60
    mov rdi, 1
    syscall
