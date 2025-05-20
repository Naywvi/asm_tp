section .bss
    buffer resb 1024
    server_addr resb 16
    client_addr resb 16
    addr_len resd 1
    client_fd resd 1

section .data
    listening_msg db 27, "[38;5;221m⏳ Listening on port 4242", 27, "[0m", 10
    listening_len equ $ - listening_msg
    prompt db "Type a command: "
    prompt_len equ $ - prompt
    pong_msg db "PONG", 10
    pong_len equ $ - pong_msg
    goodbye_msg db "Goodbye!", 10
    goodbye_len equ $ - goodbye_msg
    error_socket db "Error creating socket", 10
    error_socket_len equ $ - error_socket
    error_bind db "Error binding socket", 10
    error_bind_len equ $ - error_bind
    error_listen db "Error listening", 10
    error_listen_len equ $ - error_listen
    ping_str db "PING", 0
    exit_str db "EXIT", 0
    reverse_str db "REVERSE ", 0

section .text
    global _start

_start:
    ; Create socket
    mov rax, 41 
    mov rdi, 2   ; AF_INET
    mov rsi, 1   ; SOCK_STREAM
    mov rdx, 0   ; Protocol
    syscall
    
    cmp rax, 0
    jl socket_error
    
    mov r12, rax ; Save socket descriptor
    
    ; Set socket option
    mov rax, 54  ; setsockopt
    mov rdi, r12 ; socket
    mov rsi, 1   ; SOL_SOCKET
    mov rdx, 2   ; SO_REUSEADDR
    lea r10, [option_value] ; option value (1)
    mov r8, 4    ; option length
    syscall
    
    ; Set up server address
    mov word [server_addr], 2       ; AF_INET
    mov word [server_addr+2], 0x9a10 ; Port 4242 (network byte order)
    mov dword [server_addr+4], 0    ; INADDR_ANY
    
    ; Bind socket
    mov rax, 49  ; bind
    mov rdi, r12 ; socket
    mov rsi, server_addr ; address
    mov rdx, 16  ; address length
    syscall
    
    cmp rax, 0
    jl bind_error
    
    ; Listen
    mov rax, 50  ; listen
    mov rdi, r12 ; socket
    mov rsi, 10  ; backlog
    syscall
    
    cmp rax, 0
    jl listen_error
    
    ; Print listening message
    mov rax, 1   ; write
    mov rdi, 1   ; stdout
    mov rsi, listening_msg ; buffer
    mov rdx, listening_len ; length
    syscall
    
    ; Accept loop
    mov dword [addr_len], 16
accept_loop:
    mov rax, 43  ; accept
    mov rdi, r12 ; socket
    mov rsi, client_addr ; client address
    mov rdx, addr_len ; address length
    syscall
    
    cmp rax, 0
    jl accept_loop ; Try again
    
    mov r13, rax ; Save client socket descriptor
    
    mov rax, 57  ; fork
    syscall
    
    cmp rax, 0
    jl accept_loop ; Error, try next connection
    
    je handle_client ; Child process
    
    ; Parent process
    mov rax, 3   ; close
    mov rdi, r13 ; client socket
    syscall
    
    jmp accept_loop
    
handle_client:
    ; Child process handles client connection
    mov rax, 3   ; close
    mov rdi, r12 ; server socket
    syscall
    
    ; Client handling loop
    client_loop:
        ; Send prompt
        mov rax, 1   ; write
        mov rdi, r13 ; client socket
        mov rsi, prompt ; buffer
        mov rdx, prompt_len ; length
        syscall
        
        ; Read command
        mov rax, 0   ; read
        mov rdi, r13 ; client socket
        mov rsi, buffer ; buffer
        mov rdx, 1024 ; buffer size
        syscall
        
        cmp rax, 0
        jle client_done ; EOF or error
        
        ; Null-terminate command
        mov byte [buffer + rax - 1], 0
        
        ; Check for PING command
        mov rdi, buffer
        mov rsi, ping_str
        call string_compare
        cmp rax, 0
        jne handle_ping
        
        ; Check for EXIT command
        mov rdi, buffer
        mov rsi, exit_str
        call string_compare
        cmp rax, 0
        jne handle_exit
        
        ; Check for REVERSE command
        mov rdi, buffer
        mov rsi, reverse_str
        call string_starts_with
        cmp rax, 0
        jne handle_reverse
        
        ; Command not recognized, continue
        jmp client_loop
        
    handle_ping:
        mov rax, 1   ; write
        mov rdi, r13 ; client socket
        mov rsi, pong_msg ; buffer
        mov rdx, pong_len ; length
        syscall
        jmp client_loop
        
    handle_exit:
        mov rax, 1   ; write
        mov rdi, r13 ; client socket
        mov rsi, goodbye_msg ; buffer
        mov rdx, goodbye_len ; length
        syscall
        jmp client_done
        
    handle_reverse:
        lea rdi, [buffer + 8] ; Skip "REVERSE "
        call reverse_string
        mov rax, 1   ; write
        mov rdi, r13 ; client socket
        mov rsi, buffer ; buffer
        mov rdx, rcx  ; length
        syscall
        jmp client_loop
        
    client_done:
        mov rax, 3   ; close
        mov rdi, r13 ; client socket
        syscall
        
        mov rax, 60  ; exit
        xor rdi, rdi ; status code 0
        syscall
        
socket_error:
    mov rax, 1   ; write
    mov rdi, 2   ; stderr
    mov rsi, error_socket ; buffer
    mov rdx, error_socket_len ; length
    syscall
    
    mov rax, 60  ; exit
    mov rdi, 1   ; status code 1
    syscall
    
bind_error:
    mov rax, 1   ; write
    mov rdi, 2   ; stderr
    mov rsi, error_bind ; buffer
    mov rdx, error_bind_len ; length
    syscall
    
    mov rax, 3   ; close
    mov rdi, r12 ; socket
    syscall
    
    mov rax, 60  ; exit
    mov rdi, 1   ; status code 1
    syscall
    
listen_error:
    mov rax, 1   ; write
    mov rdi, 2   ; stderr
    mov rsi, error_listen ; buffer
    mov rdx, error_listen_len ; length
    syscall
    
    mov rax, 3   ; close
    mov rdi, r12 ; socket
    syscall
    
    mov rax, 60  ; exit
    mov rdi, 1   ; status code 1
    syscall
    
; Helper functions
string_compare:
    mov rcx, 0
compare_loop:
    mov al, [rdi + rcx]
    mov dl, [rsi + rcx]
    cmp al, 0
    je compare_end
    cmp dl, 0
    je compare_end
    cmp al, dl
    jne compare_not_equal
    inc rcx
    jmp compare_loop
compare_end:
    cmp al, dl
    jne compare_not_equal
    mov rax, 1  ; Strings are equal
    ret
compare_not_equal:
    mov rax, 0  ; Strings are not equal
    ret
    
string_starts_with:
    mov rcx, 0
starts_with_loop:
    mov al, [rsi + rcx]
    cmp al, 0
    je starts_with_equal
    mov dl, [rdi + rcx]
    cmp dl, 0
    je starts_with_not_equal
    cmp al, dl
    jne starts_with_not_equal
    inc rcx
    jmp starts_with_loop
starts_with_equal:
    mov rax, 1  ; String starts with prefix
    ret
starts_with_not_equal:
    mov rax, 0  ; String doesn't start with prefix
    ret
    
reverse_string:
    ; Count length of string
    mov rcx, 0
length_loop:
    cmp byte [rdi + rcx], 0
    je reverse_logic
    inc rcx
    jmp length_loop
    
reverse_logic:
    mov rdx, rcx  ; Save length
    mov rcx, 0    ; Counter for reversed string
    dec rdx       ; Last character index
    
    ; Add original string reversed to buffer
reverse_loop:
    cmp rdx, 0
    jl reverse_done
    mov al, [rdi + rdx]
    mov [buffer + rcx], al
    inc rcx
    dec rdx
    jmp reverse_loop
    
reverse_done:
    mov byte [buffer + rcx], 10  ; Add newline
    inc rcx
    ret

section .data
    option_value dd 1
