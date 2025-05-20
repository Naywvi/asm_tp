section .bss
    buffer resb 1024
    server_addr resb 16
    addr_len resd 1

section .data
    message db "Hello, server!", 0
    message_len equ $ - message - 1
    timeout_msg db "Timeout: no response from server", 10
    timeout_len equ $ - timeout_msg
    response_prefix db "message: ", 34
    response_prefix_len equ $ - response_prefix
    response_suffix db 34, 10
    response_suffix_len equ $ - response_suffix

section .text
    global _start

_start:
    ; Create UDP socket
    mov rax, 41         ; sys_socket
    mov rdi, 2          ; AF_INET
    mov rsi, 2          ; SOCK_DGRAM
    mov rdx, 0          ; Protocol
    syscall
    
    ; Check for error
    cmp rax, 0
    jl exit_error
    
    ; Save socket fd
    mov r12, rax
    
    ; Set socket to non-blocking mode
    mov rax, 54         ; sys_setsockopt
    mov rdi, r12        ; socket fd
    mov rsi, 1          ; SOL_SOCKET
    mov rdx, 21         ; SO_SNDTIMEO
    lea r10, [timeval]  ; optval
    mov r8, 16          ; optlen
    syscall
    
    ; Set up server address
    mov word [server_addr], 2        ; AF_INET
    mov word [server_addr+2], 0x3905 ; Port 1337 (network byte order)
    mov dword [server_addr+4], 0x0100007f ; IP 127.0.0.1 (network byte order)
    
    ; Send message to server
    mov rax, 44         ; sys_sendto
    mov rdi, r12        ; socket fd
    mov rsi, message    ; buffer
    mov rdx, message_len ; buffer length
    mov r10, 0          ; flags
    mov r8, server_addr ; server address
    mov r9, 16          ; address length
    syscall
    
    ; Check for error
    cmp rax, 0
    jl exit_error
    
    ; Set receive timeout
    mov rax, 54         ; sys_setsockopt
    mov rdi, r12        ; socket fd
    mov rsi, 1          ; SOL_SOCKET
    mov rdx, 20         ; SO_RCVTIMEO
    lea r10, [timeval]  ; optval
    mov r8, 16          ; optlen
    syscall
    
    ; Receive response
    mov dword [addr_len], 16
    mov rax, 45         ; sys_recvfrom
    mov rdi, r12        ; socket fd
    mov rsi, buffer     ; buffer
    mov rdx, 1024       ; buffer length
    mov r10, 0          ; flags
    mov r8, server_addr ; source address
    mov r9, addr_len    ; address length
    syscall
    
    ; Check if timeout occurred
    cmp rax, 0
    jle timeout
    
    ; Save received bytes count
    mov r13, rax
    
    ; Print response prefix
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, response_prefix
    mov rdx, response_prefix_len
    syscall
    
    ; Print response
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, buffer
    mov rdx, r13
    syscall
    
    ; Print response suffix
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, response_suffix
    mov rdx, response_suffix_len
    syscall
    
    ; Close socket
    mov rax, 3          ; sys_close
    mov rdi, r12
    syscall
    
    ; Exit with code 0
    mov rax, 60         ; sys_exit
    mov rdi, 0
    syscall
    
timeout:
    ; Print timeout message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, timeout_msg
    mov rdx, timeout_len
    syscall
    
    ; Close socket
    mov rax, 3          ; sys_close
    mov rdi, r12
    syscall
    
    ; Exit with code 1
    mov rax, 60         ; sys_exit
    mov rdi, 1
    syscall
    
exit_error:
    ; Exit with code 1
    mov rax, 60         ; sys_exit
    mov rdi, 1
    syscall

section .data
    timeval:
        dq 1            ; 1 second
        dq 0            ; 0 microseconds
