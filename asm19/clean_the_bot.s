section .data
    sh_cmd db "/bin/sh", 0
    sh_arg db "-c", 0
    
    command db "lsof -i :1337,4242 | grep -v PID | awk '{print $2}' | xargs kill -9 2>/dev/null || true", 0
    
    success_msg db "Killed processes listening on ports 1337 and 4242", 10
    success_len equ $ - success_msg

section .text
    global _start

_start:
    mov rax, 57         ; sys_fork
    syscall
    
    test rax, rax
    jnz parent          ; Parent process
    
    ; In child process, execute the shell command
    mov rax, 59         ; sys_execve
    mov rdi, sh_cmd     ; /bin/sh
    
    ; Set up arguments array
    push 0              ; NULL terminator
    push command        ; The command string
    push sh_arg         ; -c
    push sh_cmd         ; /bin/sh
    mov rsi, rsp        ; Point to the arguments array
    
    xor rdx, rdx        ; No environment variables
    syscall
    
    ; If execve returns, it failed
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; Exit code 1
    syscall
    
parent:
    ; Parent process waits for child to finish
    xor r10, r10
    xor rdx, rdx
    xor rsi, rsi
    mov rdi, rax
    mov rax, 61         ; sys_wait4
    syscall
    
    ; Display success message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, success_msg
    mov rdx, success_len
    syscall
    
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; Exit code 0
    syscall
