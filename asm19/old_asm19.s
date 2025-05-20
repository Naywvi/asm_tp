section .bss
    buffer resb 1024
    server_addr resb 16
    client_addr resb 16
    addr_len resd 1

section .data
    filename db "messages", 0
    listening_msg db 27, "[38;5;221m⏳ Listening on port 1337", 27, "[0m", 10
    listening_len equ $ - listening_msg
    error_socket db "Error creating socket", 10
    error_socket_len equ $ - error_socket
    error_bind db "Error binding socket", 10
    error_bind_len equ $ - error_bind
    error_file db "Error opening log file", 10
    error_file_len equ $ - error_file
    msg_received db "Message received and logged", 10
    msg_received_len equ $ - msg_received

section .text
    global _start

_start:
    mov rax, 41
    mov rdi, 2
    mov rsi, 2
    mov rdx, 0
    syscall
    
    test rax, rax
    js socket_error
    
    mov r12, rax
    
    mov word [server_addr], 2
    mov word [server_addr+2], 0x3905
    mov dword [server_addr+4], 0
    
    mov rax, 49
    mov rdi, r12
    mov rsi, server_addr
    mov rdx, 16
    syscall
    
    test rax, rax
    js bind_error
    
    mov rax, 2
    mov rdi, filename
    mov rsi, 1090       ; O_WRONLY | O_CREAT | O_APPEND (0x442)
    mov rdx, 0666       ; permissions: rw-rw-rw-
    syscall
    
    test rax, rax
    js file_error
    
    mov r13, rax
    
    mov rax, 1
    mov rdi, 1
    mov rsi, listening_msg
    mov rdx, listening_len
    syscall
    
    mov dword [addr_len], 16
    
    jmp receive_loop
    
socket_error:
    mov rax, 1
    mov rdi, 2          ; stderr
    mov rsi, error_socket
    mov rdx, error_socket_len
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
bind_error:
    mov rax, 1
    mov rdi, 2          ; stderr
    mov rsi, error_bind
    mov rdx, error_bind_len
    syscall
    
    mov rax, 3
    mov rdi, r12
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
file_error:
    mov rax, 1
    mov rdi, 2          ; stderr
    mov rsi, error_file
    mov rdx, error_file_len
    syscall
    
    mov rax, 3
    mov rdi, r12
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
receive_message:
    mov r14, rax
    
    mov byte [buffer + r14], 10
    inc r14
    
    mov rax, 1
    mov rdi, r13
    mov rsi, buffer
    mov rdx, r14
    syscall
    
receive_loop:
    mov rax, 45
    mov rdi, r12
    mov rsi, buffer
    mov rdx, 1024
    mov r10, 0
    mov r8, client_addr
    mov r9, addr_len
    syscall
    
    test rax, rax
    js receive_loop
    
    jmp receive_message
