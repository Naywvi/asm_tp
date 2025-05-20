section .data
    buffer times 8192 db 0

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl exit_error
    
    pop rdi
    pop rdi
    
    mov rax, 2
    mov rsi, 2          ; O_RDWR
    mov rdx, 0644o      ; Mode
    syscall
    
    cmp rax, 0
    jl exit_error
    
    mov r8, rax         ; Save file descriptor
    
    ; Read file
    mov rdi, rax
    xor rax, rax
    mov rsi, buffer
    mov rdx, 8192
    syscall
    
    mov r9, rax         ; Save file size
    
    ; Search for "1337" in the executable
    xor r10, r10        ; Offset counter
    
find_loop:
    cmp r10, r9
    jge exit_error
    
    mov al, [buffer + r10]
    cmp al, '1'
    jne next_byte
    
    mov al, [buffer + r10 + 1]
    cmp al, '3'
    jne next_byte
    
    mov al, [buffer + r10 + 2]
    cmp al, '3'
    jne next_byte
    
    mov al, [buffer + r10 + 3]
    cmp al, '7'
    jne next_byte
    
    ; Found it - replace with "H4CK"
    mov byte [buffer + r10], 'H'
    mov byte [buffer + r10 + 1], '4'
    mov byte [buffer + r10 + 2], 'C'
    mov byte [buffer + r10 + 3], 'K'
    
    ; Seek to the beginning of the file
    mov rax, 8
    mov rdi, r8
    xor rsi, rsi
    xor rdx, rdx
    syscall
    
    ; Write the modified content
    mov rax, 1
    mov rdi, r8
    mov rsi, buffer
    mov rdx, r9
    syscall
    
    ; Close the file
    mov rax, 3
    mov rdi, r8
    syscall
    
    ; Exit successfully
    mov rax, 60
    xor rdi, rdi
    syscall
    
next_byte:
    inc r10
    jmp find_loop
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
