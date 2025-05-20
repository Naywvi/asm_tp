section .bss
    buffer resb 1024
    result resb 1024

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    
    call atoi
    mov r12, rax
    
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 1024
    syscall
    
    mov rbx, rax
    mov rcx, 0
    
process_loop:
    cmp rcx, rbx
    jge print_result
    
    movzx rax, byte [buffer + rcx]
    
    cmp al, 10
    je skip_char
    
    cmp al, 'a'
    jl check_uppercase
    cmp al, 'z'
    jg skip_char
    
    sub al, 'a'
    add al, r12b
    
    while_greater_26_lowercase:
    cmp al, 26
    jl while_less_0_lowercase
    sub al, 26
    jmp while_greater_26_lowercase
    
    while_less_0_lowercase:
    cmp al, 0
    jge lowercase_done
    add al, 26
    jmp while_less_0_lowercase
    
    lowercase_done:
    add al, 'a'
    mov [result + rcx], al
    jmp next_char
    
check_uppercase:
    cmp al, 'A'
    jl skip_char
    cmp al, 'Z'
    jg skip_char
    
    sub al, 'A'
    add al, r12b
    
    while_greater_26_uppercase:
    cmp al, 26
    jl while_less_0_uppercase
    sub al, 26
    jmp while_greater_26_uppercase
    
    while_less_0_uppercase:
    cmp al, 0
    jge uppercase_done
    add al, 26
    jmp while_less_0_uppercase
    
    uppercase_done:
    add al, 'A'
    mov [result + rcx], al
    jmp next_char
    
skip_char:
    mov [result + rcx], al
    
next_char:
    inc rcx
    jmp process_loop
    
print_result:
    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, rbx
    syscall
    
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
