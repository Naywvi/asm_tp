section .data
    buffer times 65 db 0
    hex_chars db "0123456789ABCDEF"

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    
    mov r8, 16
    
    cmp byte [rdi], '-'
    jne convert_direct
    
    cmp byte [rdi+1], 'b'
    jne exit_error
    
    mov r8, 2
    cmp rcx, 3
    jl exit_error
    
    pop rdi
    
convert_direct:
    call atoi
    mov rbx, rax
    
    mov rdi, rbx
    mov rsi, r8
    call convert_base
    
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

convert_base:
    mov rax, rdi
    mov rbx, rsi
    mov rdi, buffer
    add rdi, 64
    mov byte [rdi], 10
    dec rdi
    mov byte [rdi], 0
    mov rcx, 0
    
convert_loop:
    test rax, rax
    jz convert_done
    
    xor rdx, rdx
    div rbx
    
    mov r9, rdx
    movzx rdx, byte [hex_chars + rdx]
    mov [rdi], dl
    dec rdi
    inc rcx
    
    jmp convert_loop
    
convert_done:
    cmp rcx, 0
    jne print_result
    
    mov byte [rdi], '0'
    dec rdi
    inc rcx
    
print_result:
    inc rdi
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    mov rdx, rcx
    inc rdx
    syscall
    ret
