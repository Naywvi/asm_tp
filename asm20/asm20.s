section .bss
    buffer resb 1024
    server_addr resb 16
    client_addr resb 16
    addr_len resd 1
    client_fd resd 1
    cmd_buffer resb 1024
    resp_buffer resb 1024

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
    error_accept db "Error accepting connection", 10
    error_accept_len equ $ - error_accept
    error_fork db "Error forking process", 10
    error_fork_len equ $ - error_fork
    ping_cmd_str db "PING", 0
    reverse_cmd_str db "REVERSE", 0
    exit_cmd_str db "EXIT", 0

section .text
    global _start

_start:
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    
    test rax, rax
    js socket_error
    
    mov r12, rax
    
    mov word [server_addr], 2
    mov word [server_addr+2], 0x9a10
    mov dword [server_addr+4], 0
    
    mov rax, 49
    mov rdi, r12
    mov rsi, server_addr
    mov rdx, 16
    syscall
    
    test rax, rax
    js bind_error
    
    mov rax, 50
    mov rdi, r12
    mov rsi, 5
    syscall
    
    test rax, rax
    js listen_error
    
    mov rax, 1
    mov rdi, 1
    mov rsi, listening_msg
    mov rdx, listening_len
    syscall
    
    mov dword [addr_len], 16
    
accept_loop:
    mov rax, 43
    mov rdi, r12
    mov rsi, client_addr
    mov rdx, addr_len
    syscall
    
    test rax, rax
    js accept_error
    
    mov dword [client_fd], eax
    
    mov rax, 57
    syscall
    
    test rax, rax
    js fork_error
    
    cmp rax, 0
    je handle_client
    
    mov rax, 3
    mov edi, dword [client_fd]
    syscall
    
    jmp accept_loop
    
handle_client:
    mov r13d, dword [client_fd]
    
    mov rax, 3
    mov rdi, r12
    syscall
    
client_loop:
    mov rax, 1
    mov rdi, r13
    mov rsi, prompt
    mov rdx, prompt_len
    syscall
    
    mov rax, 0
    mov rdi, r13
    mov rsi, cmd_buffer
    mov rdx, 1024
    syscall
    
    test rax, rax
    jle client_done
    
    mov dword [cmd_buffer + rax - 1], 0
    
    mov rdi, cmd_buffer
    call compare_cmd_ping
    test rax, rax
    jnz ping_cmd
    
    mov rdi, cmd_buffer
    call compare_cmd_reverse
    test rax, rax
    jnz reverse_cmd
    
    mov rdi, cmd_buffer
    call compare_cmd_exit
    test rax, rax
    jnz exit_cmd
    
    jmp client_loop
    
ping_cmd:
    mov rax, 1
    mov rdi, r13
    mov rsi, pong_msg
    mov rdx, pong_len
    syscall
    
    jmp client_loop
    
reverse_cmd:
    add rdi, 8
    call reverse_string
    
    mov rax, 1
    mov rdi, r13
    mov rsi, resp_buffer
    mov rdx, rcx
    syscall
    
    jmp client_loop
    
exit_cmd:
    mov rax, 1
    mov rdi, r13
    mov rsi, goodbye_msg
    mov rdx, goodbye_len
    syscall
    
client_done:
    mov rax, 3
    mov rdi, r13
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
socket_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_socket
    mov rdx, error_socket_len
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
bind_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_bind
    mov rdx, error_bind_len
    syscall
    
    mov rax, 3
    mov rdi, r12
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
listen_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_listen
    mov rdx, error_listen_len
    syscall
    
    mov rax, 3
    mov rdi, r12
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
accept_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_accept
    mov rdx, error_accept_len
    syscall
    
    jmp accept_loop
    
fork_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_fork
    mov rdx, error_fork_len
    syscall
    
    mov rax, 3
    mov edi, dword [client_fd]
    syscall
    
    jmp accept_loop
    
compare_cmd_ping:
    mov rsi, ping_cmd_str
    call str_compare
    ret
    
compare_cmd_reverse:
    mov rsi, reverse_cmd_str
    call str_compare
    ret
    
compare_cmd_exit:
    mov rsi, exit_cmd_str
    call str_compare
    ret
    
str_compare:
    xor rcx, rcx
str_compare_loop:
    movzx rax, byte [rdi + rcx]
    movzx rdx, byte [rsi + rcx]
    test rax, rax
    jz str_compare_end
    test rdx, rdx
    jz str_compare_end
    inc rcx
    cmp rax, rdx
    je str_compare_loop
    xor rax, rax
    ret
str_compare_end:
    cmp rax, rdx
    sete al
    movzx rax, al
    ret
    
reverse_string:
    xor rcx, rcx
    xor r8, r8
    xor r9, r9
    
reverse_string_length:
    cmp byte [rdi + rcx], 0
    je reverse_string_copy
    cmp byte [rdi + rcx], 10
    je reverse_string_copy
    inc rcx
    jmp reverse_string_length
    
reverse_string_copy:
    mov r8, rcx
    dec r8
    
    mov byte [resp_buffer + r8 + 1], 10
    
reverse_string_loop:
    cmp r9, r8
    jg reverse_string_done
    
    mov al, [rdi + r8]
    mov [resp_buffer + r9], al
    
    inc r9
    dec r8
    jmp reverse_string_loop
    
reverse_string_done:
    mov rcx, r9
    inc rcx
    ret
