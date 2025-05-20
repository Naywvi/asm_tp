section .data
    buffer times 20 db 0
    newline db 10

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    call atoi
    
    mov rbx, rax
    xor r8, r8
    mov r9, 1
    
sum_loop:
    cmp r9, rbx
    jge print_result
    
    add r8, r9
    inc r9
    jmp sum_loop
    
print_result:
    mov rdi, r8
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
