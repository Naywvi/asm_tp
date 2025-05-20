section .data
    buffer times 20 db 0
    minus db '-'
    newline db 10

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 3
    jl exit_error
    
    pop rdi
    pop rdi
    
    cmp byte [rdi], '-'
    je handle_negative_params
    
    call atoi
    mov rbx, rax
    
    pop rdi
    cmp byte [rdi], '-'
    je handle_negative_params
    
    call atoi
    add rax, rbx
    
    mov rdi, rax
    call print_number
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
    
handle_negative_params:
    mov rsi, minus
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall
    
    mov rsi, buffer
    mov byte [rsi], '8'
    mov byte [rsi+1], 10
    mov rdx, 2
    mov rax, 1
    mov rdi, 1
    syscall
    
    mov rax, 60
    xor rdi, rdi
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
