section .data
    buffer times 20 db 0

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 3
    jl exit_error
    
    pop rdi
    pop rdi
    call atoi
    mov rbx, rax
    
    pop rdi
    call atoi
    
    add rax, rbx
    
    mov rdi, rax
    call itoa
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

atoi:
    xor rax, rax
    xor rcx, rcx
    
atoi_loop:
    movzx rdx, byte [rdi + rcx]
    cmp dl, 0
    je atoi_end
    
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    
    inc rcx
    jmp atoi_loop
    
atoi_end:
    ret

itoa:
    mov rax, rdi
    mov rbx, 10
    mov rdi, buffer
    add rdi, 19
    mov byte [rdi], 0
    mov rcx, 1
    
itoa_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    inc rcx
    test rax, rax
    jnz itoa_loop
    
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    mov rdx, rcx
    syscall
    ret
