section .data
    output db "1337", 10
    output_len equ $ - output

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jne exit_with_error
    
    pop rdi
    pop rdi
    
    cmp byte [rdi], '4'
    jne exit_with_error
    cmp byte [rdi+1], '2'
    jne exit_with_error
    cmp byte [rdi+2], 0
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
