section .data
    pattern db "1337", 0
    replacement db "H4CK", 0
    buffer times 4096 db 0

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    
    mov rax, 2
    mov rsi, 2          
    xor rdx, rdx
    syscall
    
    cmp rax, 0
    jl exit_error
    
    mov r8, rax         
    
    mov rdi, rax
    mov rax, 0
    mov rsi, buffer
    mov rdx, 4096
    syscall
    
    mov r9, rax         
    
    mov r10, 0          
    
search_loop:
    cmp r10, r9
    jge exit_error
    
    mov r11d, dword [buffer + r10]
    
    cmp r11b, '1'
    jne next_byte
    
    cmp byte [buffer + r10 + 1], '3'
    jne next_byte
    
    cmp byte [buffer + r10 + 2], '3'
    jne next_byte
    
    cmp byte [buffer + r10 + 3], '7'
    jne next_byte
    
    mov byte [buffer + r10], 'H'
    mov byte [buffer + r10 + 1], '4'
    mov byte [buffer + r10 + 2], 'C'
    mov byte [buffer + r10 + 3], 'K'
    
    mov rdi, r8
    mov rax, 8          
    xor rsi, rsi        
    xor rdx, rdx        
    syscall
    
    mov rdi, r8
    mov rax, 1
    mov rsi, buffer
    mov rdx, r9
    syscall
    
    mov rdi, r8
    mov rax, 3
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
next_byte:
    inc r10
    jmp search_loop
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
