section .data
    buf times 16 db 0

section .text
    global _start

_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, buf
    mov rdx, 16
    syscall
    
    mov rdi, buf
    call atoi
    
    cmp rax, -1
    je bad_input
    
    test rax, 1
    jz exit_success
    
    mov rax, 60
    mov rdi, 1
    syscall
    
exit_success:
    mov rax, 60
    mov rdi, 0
    syscall
    
bad_input:
    mov rax, 60
    mov rdi, 2
    syscall
    
atoi:
    xor rax, rax
    xor rcx, rcx
    
atoi_loop:
    movzx rdx, byte [rdi + rcx]
    cmp dl, 10
    je atoi_end
    cmp dl, 0
    je atoi_end
    
    cmp dl, '0'
    jl invalid_char
    cmp dl, '9'
    jg invalid_char
    
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    
    inc rcx
    jmp atoi_loop
    
invalid_char:
    mov rax, -1
    ret
    
atoi_end:
    ret
