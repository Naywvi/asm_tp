section .data
    buffer times 20 db 0
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
    je exit_negative

    call atoi
    mov rbx, rax

    pop rdi
    cmp byte [rdi], '-'
    je exit_negative

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
exit_negative:
    mov rax, 60
    mov rdi, 0
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
    mov rdi, buffer
    xor rcx, rcx
    mov r8, 10
    
print_loop:
    xor rdx, rdx
    div r8
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz print_loop
    
    mov rdi, buffer
    xor rdx, rdx
    
reverse_loop:
    cmp rdx, rcx
    je print_newline
    pop rax
    mov [rdi + rdx], al
    inc rdx
    jmp reverse_loop
    
print_newline:
    mov byte [rdi + rdx], 10
    inc rdx
    
    mov rax, 1
    mov rsi, buffer
    mov rdi, 1
    syscall
    ret
