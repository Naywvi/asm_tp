section .data
    ; Messages
    listen_msg db 27, "[38;5;221m⏳ Listening on port 4242", 27, "[0m", 10
    listen_msg_len equ $ - listen_msg
    
    prompt db "Type a command: "
    prompt_len equ $ - prompt
    
    pong_msg db "PONG", 10
    pong_len equ $ - pong_msg
    
    goodbye_msg db "Goodbye!", 10
    goodbye_len equ $ - goodbye_msg
    
    ; Commands
    ping_cmd db "PING", 0
    exit_cmd db "EXIT", 0
    reverse_cmd db "REVERSE ", 0
    
    ; Error messages
    error_socket db "Error: Cannot create socket", 10
    error_socket_len equ $ - error_socket
    
    error_bind db "Error: Cannot bind to port", 10
    error_bind_len equ $ - error_bind
    
    error_listen db "Error: Cannot listen", 10
    error_listen_len equ $ - error_listen
    
    ; Socket option
    socket_option dd 1

section .bss
    server_socket resq 1
    client_socket resq 1
    server_addr resb 16
    client_addr resb 16
    addr_len resd 1
    buffer resb 1024

section .text
global _start

_start:
    ; Create socket
    mov rax, 41         ; sys_socket
    mov rdi, 2          ; AF_INET
    mov rsi, 1          ; SOCK_STREAM
    mov rdx, 0          ; Protocol
    syscall
    
    ; Check for error
    test rax, rax
    js socket_error
    
    ; Save socket descriptor
    mov [server_socket], rax
    
    ; Set SO_REUSEADDR option
    mov rax, 54         ; sys_setsockopt
    mov rdi, [server_socket]
    mov rsi, 1          ; SOL_SOCKET
    mov rdx, 2          ; SO_REUSEADDR
    lea r10, [socket_option]
    mov r8, 4           ; Option length
    syscall
    
    ; Set up server address
    mov word [server_addr], 2       ; AF_INET
    mov word [server_addr+2], 0x9a10 ; Port 4242 (network byte order)
    mov dword [server_addr+4], 0     ; INADDR_ANY
    
    ; Bind socket
    mov rax, 49         ; sys_bind
    mov rdi, [server_socket]
    mov rsi, server_addr
    mov rdx, 16         ; Address length
    syscall
    
    ; Check for error
    test rax, rax
    js bind_error
    
    ; Start listening
    mov rax, 50         ; sys_listen
    mov rdi, [server_socket]
    mov rsi, 5          ; Backlog queue size
    syscall
    
    ; Check for error
    test rax, rax
    js listen_error
    
    ; Print listening message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, listen_msg
    mov rdx, listen_msg_len
    syscall
    
    ; Accept connections loop
    accept_loop:
        mov dword [addr_len], 16
        
        ; Accept a connection
        mov rax, 43     ; sys_accept
        mov rdi, [server_socket]
        mov rsi, client_addr
        mov rdx, addr_len
        syscall
        
        ; Check for error
        test rax, rax
        js accept_loop  ; Try again on error
        
        ; Save client socket
        mov [client_socket], rax
        
        ; Fork to handle client
        mov rax, 57     ; sys_fork
        syscall
        
        ; Check fork result
        test rax, rax
        js accept_loop  ; Error, continue accepting
        jz handle_client ; Child process handles client
        
        ; Parent process continues
        mov rax, 3      ; sys_close
        mov rdi, [client_socket]
        syscall
        
        jmp accept_loop

; Handle client in child process
handle_client:
    ; Close server socket in child
    mov rax, 3          ; sys_close
    mov rdi, [server_socket]
    syscall
    
    ; Client communication loop
    client_loop:
        ; Send prompt
        mov rax, 1      ; sys_write
        mov rdi, [client_socket]
        mov rsi, prompt
        mov rdx, prompt_len
        syscall
        
        ; Receive command
        mov rax, 0      ; sys_read
        mov rdi, [client_socket]
        mov rsi, buffer
        mov rdx, 1024
        syscall
        
        ; Check for EOF or error
        test rax, rax
        jle client_done
        
        ; Null-terminate the command and save length
        mov rcx, rax
        dec rcx
        mov byte [buffer + rcx], 0
        
        ; Check for PING command
        mov rdi, buffer
        mov rsi, ping_cmd
        call compare_strings
        cmp rax, 1
        je handle_ping
        
        ; Check for EXIT command
        mov rdi, buffer
        mov rsi, exit_cmd
        call compare_strings
        cmp rax, 1
        je handle_exit
        
        ; Check for REVERSE command
        mov rdi, buffer
        mov rsi, reverse_cmd
        call starts_with
        cmp rax, 1
        je handle_reverse
        
        ; Unknown command, loop back for another
        jmp client_loop
        
    ; PING command handler
    handle_ping:
        mov rax, 1      ; sys_write
        mov rdi, [client_socket]
        mov rsi, pong_msg
        mov rdx, pong_len
        syscall
        jmp client_loop
        
    ; EXIT command handler
    handle_exit:
        mov rax, 1      ; sys_write
        mov rdi, [client_socket]
        mov rsi, goodbye_msg
        mov rdx, goodbye_len
        syscall
        ; Fall through to client_done
        
    ; Client disconnection handler
    client_done:
        mov rax, 3      ; sys_close
        mov rdi, [client_socket]
        syscall
        
        mov rax, 60     ; sys_exit
        xor rdi, rdi    ; Return code 0
        syscall
        
    ; REVERSE command handler
    handle_reverse:
        add rdi, 8      ; Skip "REVERSE "
        call reverse_string
        
        mov rax, 1      ; sys_write
        mov rdi, [client_socket]
        mov rsi, buffer
        mov rdx, rcx
        syscall
        jmp client_loop

; Error handlers
socket_error:
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    mov rsi, error_socket
    mov rdx, error_socket_len
    syscall
    
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; Error code
    syscall
    
bind_error:
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    mov rsi, error_bind
    mov rdx, error_bind_len
    syscall
    
    mov rax, 3          ; sys_close
    mov rdi, [server_socket]
    syscall
    
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; Error code
    syscall
    
listen_error:
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    mov rsi, error_listen
    mov rdx, error_listen_len
    syscall
    
    mov rax, 3          ; sys_close
    mov rdi, [server_socket]
    syscall
    
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; Error code
    syscall

; Helper functions
; Compare two strings (rdi = string1, rsi = string2)
; Returns 1 if equal, 0 if not
compare_strings:
    xor rcx, rcx
compare_loop:
    mov al, [rdi + rcx]
    mov dl, [rsi + rcx]
    
    cmp al, 0
    je compare_end      ; If we hit null in string1
    
    cmp dl, 0
    je compare_not_equal ; If we hit null in string2 but not string1
    
    cmp al, dl
    jne compare_not_equal ; Characters don't match
    
    inc rcx
    jmp compare_loop
    
compare_end:
    cmp dl, 0           ; Both null? Then equal
    jne compare_not_equal
    
    mov rax, 1          ; Strings match
    ret
    
compare_not_equal:
    xor rax, rax        ; Strings don't match
    ret

; Check if string starts with prefix (rdi = string, rsi = prefix)
; Returns 1 if string starts with prefix, 0 if not
starts_with:
    xor rcx, rcx
starts_with_loop:
    mov al, [rsi + rcx] ; Get prefix character
    cmp al, 0
    je starts_with_yes  ; End of prefix - we matched all of it
    
    mov dl, [rdi + rcx] ; Get string character
    cmp dl, 0
    je starts_with_no   ; End of string before end of prefix
    
    cmp al, dl
    jne starts_with_no  ; Characters don't match
    
    inc rcx
    jmp starts_with_loop
    
starts_with_yes:
    mov rax, 1
    ret
    
starts_with_no:
    xor rax, rax
    ret

; Reverse a string (rdi = string to reverse)
; Result stored in buffer, length in rcx
reverse_string:
    xor rcx, rcx
    
    ; Find length of string
length_loop:
    cmp byte [rdi + rcx], 0
    je do_reverse
    inc rcx
    jmp length_loop
    
do_reverse:
    mov rdx, rcx        ; Save length
    xor r8, r8          ; Output position
    
    ; Add characters in reverse
reverse_loop:
    cmp rdx, 0
    je add_newline
    
    dec rdx
    mov al, [rdi + rdx]
    mov [buffer + r8], al
    inc r8
    jmp reverse_loop
    
add_newline:
    mov byte [buffer + r8], 10 ; Add newline
    inc r8
    mov rcx, r8         ; Save final length
    ret
