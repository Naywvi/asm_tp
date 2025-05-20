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
    ; Create socket
    mov eax, 41         ; socket
    mov edi, 2          ; AF_INET
    mov esi, 1          ; SOCK_STREAM
    xor edx, edx        ; IPPROTO_IP
    syscall
    
    test eax, eax
    js exit_error
    
    mov dword [server_fd], eax
    
    ; Prepare sockaddr_in structure
    mov word [sockaddr_in], 2        ; AF_INET
    mov word [sockaddr_in+2], 0x9a10 ; Port 4242 (network byte order)
    mov dword [sockaddr_in+4], 0     ; INADDR_ANY
    mov dword [sockaddr_in+8], 0     ; Padding
    mov dword [sockaddr_in+12], 0    ; Padding
    
    ; Bind socket
    mov eax, 49         ; bind
    mov edi, dword [server_fd]
    mov esi, sockaddr_in
    mov edx, 16         ; sizeof(sockaddr_in)
    syscall
    
    test eax, eax
    js exit_error
    
    ; Listen for connections
    mov eax, 50         ; listen
    mov edi, dword [server_fd]
    mov esi, 5          ; backlog
    syscall
    
    test eax, eax
    js exit_error
    
    ; Print listening message
    mov eax, 1          ; write
    mov edi, 1          ; STDOUT
    mov esi, listen_msg
    mov edx, listen_len
    syscall
    
    ; Accept connections loop
    mov dword [addr_len], 16
    
accept_loop:
    mov eax, 43         ; accept
    mov edi, dword [server_fd]
    mov esi, client_addr
    mov edx, addr_len
    syscall
    
    test eax, eax
    js accept_loop
    
    mov dword [client_fd], eax
    
    ; Fork to handle client
    mov eax, 57         ; fork
    syscall
    
    test eax, eax
    js close_client
    jz handle_client    ; Child process
    
    ; Parent process
    mov eax, 3          ; close
    mov edi, dword [client_fd]
    syscall
    
    jmp accept_loop
    
close_client:
    mov eax, 3          ; close
    mov edi, dword [client_fd]
    syscall
    
    jmp accept_loop
    
handle_client:
    ; Child process handles client
    mov eax, 3          ; close
    mov edi, dword [server_fd]
    syscall
    
client_loop:
    ; Send prompt
    mov eax, 1          ; write
    mov edi, dword [client_fd]
    mov esi, prompt
    mov edx, prompt_len
    syscall
    
    ; Receive command
    mov eax, 0          ; read
    mov edi, dword [client_fd]
    mov esi, buffer
    mov edx, 1024
    syscall
    
    test eax, eax
    jle client_done
    
    mov ecx, eax
    mov byte [buffer + eax - 1], 0   ; Strip newline
    
    ; Check for PING command
    mov esi, buffer
    mov edi, ping_cmd
    mov edx, ping_len
    call str_compare
    test eax, eax
    jnz handle_ping
    
    ; Check for EXIT command
    mov esi, buffer
    mov edi, exit_cmd
    mov edx, exit_len
    call str_compare
    test eax, eax
    jnz handle_exit
    
    ; Check for REVERSE command
    mov esi, buffer
    mov edi, reverse_cmd
    mov edx, reverse_len
    call str_startswith
    test eax, eax
    jnz handle_reverse
    
    jmp client_loop
    
handle_ping:
    mov eax, 1          ; write
    mov edi, dword [client_fd]
    mov esi, pong_msg
    mov edx, pong_len
    syscall
    
    jmp client_loop
    
handle_exit:
    mov eax, 1          ; write
    mov edi, dword [client_fd]
    mov esi, goodbye_msg
    mov edx, goodbye_len
    syscall
    
client_done:
    mov eax, 3          ; close
    mov edi, dword [client_fd]
    syscall
    
    mov eax, 60         ; exit
    xor edi, edi        ; Exit code 0
    syscall
    
handle_reverse:
    ; Copy text after "REVERSE " to work buffer
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
    ; Get length of string to reverse
    mov esi, work_buffer
    call strlen
    
    ; Reverse the string
    mov ecx, eax
    mov esi, work_buffer
    mov edi, buffer
    call reverse
    
    ; Add newline
    mov byte [buffer + eax], 10
    inc eax
    
    ; Send reversed string
    mov edx, eax
    mov eax, 1          ; write
    mov edi, dword [client_fd]
    mov esi, buffer
    syscall
    
    jmp client_loop
    
exit_error:
    mov eax, 60         ; exit
    mov edi, 1          ; Exit code 1
    syscall
    
; String functions
; Compare two strings up to length
; esi = str1, edi = str2, edx = length
; Returns eax=1 if equal, eax=0 if not
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
    
; Check if string starts with prefix
; esi = string, edi = prefix, edx = prefix length
; Returns eax=1 if starts with, eax=0 if not
str_startswith:
    call str_compare
    ret
    
; Get length of null-terminated string
; esi = string
; Returns eax = length
strlen:
    xor eax, eax
    
strlen_loop:
    cmp byte [esi + eax], 0
    je strlen_done
    
    inc eax
    jmp strlen_loop
    
strlen_done:
    ret
    
; Reverse a string
; esi = source string, edi = destination buffer, ecx = length
; Returns eax = length of reversed string
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
