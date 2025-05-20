section .text
    global _start

_start:
    pop rax
    cmp rax, 2
    jl exit
    
    pop rax
    pop rdi
    call print_string
    
exit:
    mov rax, 60
    xor rdi, rdi
    syscall

print_string:
    push rdi
    xor rcx, rcx
    
strlen_loop:
    cmp byte [rdi + rcx], 0
    je strlen_done
    inc rcx
    jmp strlen_loop
    
strlen_done:
    mov rax, 1
    mov rdi, 1
    pop rsi
    mov rdx, rcx
    syscall
    ret
