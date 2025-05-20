section .data
    buffer times 16 db 0

section .text
    global _start

_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 16
    syscall
    
    mov rdi, buffer
    call atoi
    
    cmp rax, 1
    jle not_prime
    
    cmp rax, 2
    je is_prime
    
    mov r9, rax
    mov r10, 2
    
check_loop:
    mov rax, r9
    xor rdx, rdx
    div r10
    
    cmp rdx, 0
    je not_prime
    
    inc r10
    mov rax, r10
    mul r10
    cmp rax, r9
    jle check_loop
    
is_prime:
    mov rax, 60
    xor rdi, rdi
    syscall

not_prime:
    mov rax, 60
    mov rdi, 1
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
    
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    
    inc rcx
    jmp atoi_loop
    
atoi_end:
    ret
