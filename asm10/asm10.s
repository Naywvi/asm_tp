section .data
    buffer times 20 db 0

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 4
    jl exit_error
    
    pop rdi
    
    pop rdi
    call atoi
    mov rbx, rax
    
    pop rdi
    call atoi
    
    cmp rax, rbx
    jg set_max_to_rax
    jmp check_third
    
set_max_to_rax:
    mov rbx, rax
    
check_third:
    pop rdi
    call atoi
    
    cmp rax, rbx
    jg set_max_to_rax2
    jmp print_max
    
set_max_to_rax2:
    mov rbx, rax
    
print_max:
    mov rdi, rbx
    call print_number
    
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

print_number:
    mov rax, rdi
    mov rbx, 10
    mov rdi, buffer
    add rdi, 19
    mov byte [rdi], 10
    dec rdi
    mov rcx, 1
    
print_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    inc rcx
    test rax, rax
    jnz print_loop
    
    inc rdi
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    mov rdx, rcx
    syscall
    ret
