section .data
    listen_msg db "Listening on port 4242", 10
    listen_len equ $ - listen_msg
    
    prompt db "Type a command: "
    prompt_len equ $ - prompt
    
    pong_msg db "PONG", 10
    pong_len equ $ - pong_msg
    
    goodbye_msg db "Goodbye!", 10
    goodbye_len equ $ - goodbye_msg
    
    newline db 10
    
    ping_cmd db "PING"
    ping_len equ $ - ping_cmd
    
    exit_cmd db "EXIT"
    exit_len equ $ - exit_cmd
    
    reverse_cmd db "REVERSE "
    reverse_len equ $ - reverse_cmd

    debug_open db "Debug: Socket opened", 10
    debug_open_len equ $ - debug_open
    
    debug_bind db "Debug: Socket bound", 10
    debug_bind_len equ $ - debug_bind
    
    debug_listen db "Debug: Listening started", 10
    debug_listen_len equ $ - debug_listen

section .bss
    buffer resb 1024
    work_buffer resb 1024
    
    server_fd resd 1
    client_fd resd 1
    
    sockaddr_in resb 16
    client_addr resb 16
    addr_len resd 1

section .text
global _start

_start:
    mov eax, 41
    mov edi, 2
    mov esi, 1
    xor edx, edx
    syscall
    
    test eax, eax
    js exit_error
    
    mov dword [server_fd], eax
    
    mov eax, 1
    mov edi, 1
    mov esi, debug_open
    mov edx, debug_open_len
    syscall
    
    mov eax, 54
    mov edi, dword [server_fd]
    mov esi, 1
    mov edx, 2
    lea r10, [option_val]
    mov r8d, 4
    syscall
    
    mov word [sockaddr_in], 2
    mov word [sockaddr_in+2], 0x9a10
    mov dword [sockaddr_in+4], 0
    mov dword [sockaddr_in+8], 0
    mov dword [sockaddr_in+12], 0
    
    mov eax, 49
    mov edi, dword [server_fd]
    mov esi, sockaddr_in
    mov edx, 16
    syscall
    
    test eax, eax
    js exit_error
    
    mov eax, 1
    mov edi, 1
    mov esi, debug_bind
    mov edx, debug_bind_len
    syscall
    
    mov eax, 50
    mov edi, dword [server_fd]
    mov esi, 5
    syscall
    
    test eax, eax
    js exit_error
    
    mov eax, 1
    mov edi, 1
    mov esi, debug_listen
    mov edx, debug_listen_len
    syscall
    
    mov eax, 1
    mov edi, 1
    mov esi, listen_msg
    mov edx, listen_len
    syscall
    
    mov dword [addr_len], 16
    
accept_loop:
    mov eax, 43
    mov edi, dword [server_fd]
    mov esi, client_addr
    mov edx, addr_len
    syscall
    
    test eax, eax
    js accept_loop
    
    mov dword [client_fd], eax
    
    mov eax, 57
    syscall
    
    test eax, eax
    js close_client
    jz handle_client
    
    mov eax, 3
    mov edi, dword [client_fd]
    syscall
    
    jmp accept_loop
    
close_client:
    mov eax, 3
    mov edi, dword [client_fd]
    syscall
    
    jmp accept_loop
    
handle_client:
    mov eax, 3
    mov edi, dword [server_fd]
    syscall
    
client_loop:
    mov eax, 1
    mov edi, dword [client_fd]
    mov esi, prompt
    mov edx, prompt_len
    syscall
    
    mov eax, 0
    mov edi, dword [client_fd]
    mov esi, buffer
    mov edx, 1024
    syscall
    
    test eax, eax
    jle client_done
    
    mov ecx, eax
    mov byte [buffer + eax - 1], 0
    
    mov esi, buffer
    mov edi, ping_cmd
    mov edx, ping_len
    call str_compare
    test eax, eax
    jnz handle_ping
    
    mov esi, buffer
    mov edi, exit_cmd
    mov edx, exit_len
    call str_compare
    test eax, eax
    jnz handle_exit
    
    mov esi, buffer
    mov edi, reverse_cmd
    mov edx, reverse_len
    call str_startswith
    test eax, eax
    jnz handle_reverse
    
    jmp client_loop
    
handle_ping:
    mov eax, 1
    mov edi, dword [client_fd]
    mov esi, pong_msg
    mov edx, pong_len
    syscall
    
    jmp client_loop
    
handle_exit:
    mov eax, 1
    mov edi, dword [client_fd]
    mov esi, goodbye_msg
    mov edx, goodbye_len
    syscall
    
client_done:
    mov eax, 3
    mov edi, dword [client_fd]
    syscall
    
    mov eax, 60
    xor edi, edi
    syscall
    
handle_reverse:
    mov esi, buffer
    add esi, reverse_len
    mov edi, work_buffer
    
copy_loop:
    mov al, [esi]
    mov [edi], al
    test al, al
    jz copy_done
    
    inc esi
    inc edi
    jmp copy_loop
    
copy_done:
    mov esi, work_buffer
    call strlen
    
    mov ecx, eax
    mov esi, work_buffer
    mov edi, buffer
    call reverse
    
    mov byte [buffer + eax], 10
    inc eax
    
    mov edx, eax
    mov eax, 1
    mov edi, dword [client_fd]
    mov esi, buffer
    syscall
    
    jmp client_loop
    
exit_error:
    mov eax, 60
    mov edi, 1
    syscall
    
str_compare:
    xor ecx, ecx
    
str_cmp_loop:
    cmp ecx, edx
    jge str_cmp_equal
    
    mov al, [esi + ecx]
    cmp al, [edi + ecx]
    jne str_cmp_not_equal
    
    inc ecx
    jmp str_cmp_loop
    
str_cmp_equal:
    mov eax, 1
    ret
    
str_cmp_not_equal:
    xor eax, eax
    ret
    
str_startswith:
    call str_compare
    ret
    
strlen:
    xor eax, eax
    
strlen_loop:
    cmp byte [esi + eax], 0
    je strlen_done
    
    inc eax
    jmp strlen_loop
    
strlen_done:
    ret
    
reverse:
    mov eax, ecx
    dec ecx
    xor edx, edx
    
reverse_loop:
    cmp edx, eax
    jge reverse_done
    
    mov bl, [esi + ecx]
    mov [edi + edx], bl
    
    inc edx
    dec ecx
    
    cmp ecx, 0
    jl reverse_done
    jmp reverse_loop
    
reverse_done:
    mov byte [edi + edx], 0
    mov eax, edx
    ret

section .data
    option_val dd 1
