section .data
    port1 db "1337", 0
    port2 db "4242", 0
    netstat_cmd db "/bin/netstat", 0
    grep_cmd db "/bin/grep", 0
    awk_cmd db "/usr/bin/awk", 0
    xargs_cmd db "/usr/bin/xargs", 0
    kill_cmd db "/bin/kill", 0
    
    arg_n db "-n", 0
    arg_p db "-p", 0
    arg_u db "-u", 0
    arg_t db "-t", 0
    arg_a db "-a", 0
    
    grep_port1 db "--", 0
    grep_port2 db "--", 0
    
    awk_arg db "{print $7}", 0
    xargs_arg db "-9", 0
    
    sh_cmd db "/bin/sh", 0
    sh_arg db "-c", 0
    command db "netstat -tunap | grep -E ':1337|:4242' | awk '{print $7}' | cut -d/ -f1 | grep -v '-' | sort -u | xargs -r kill -9", 0
    
    success_msg db "Killed processes listening on ports 1337 and 4242", 10
    success_len equ $ - success_msg
    error_msg db "Error executing shell command", 10
    error_len equ $ - error_msg

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
    
    ; Check if the child exited successfully
    test rdx, rdx
    jz success
    
    ; Child failed, display error message
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; Exit code 1
    syscall
    
success:
    ; Display success message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, success_msg
    mov rdx, success_len
    syscall
    
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; Exit code 0
    syscall
