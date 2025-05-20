section .bss
    path_buffer resb 256
    asm_src_path resb 256

section .data
    source db "global _start", 10
           db "section .data", 10
           db "    msg db ", 34, "H4CK", 34, ", 0", 10
           db "section .text", 10
           db "_start:", 10
           db "    mov rax, 1", 10
           db "    mov rdi, 1", 10
           db "    mov rsi, msg", 10
           db "    mov rdx, 4", 10
           db "    syscall", 10
           db "    mov rax, 60", 10
           db "    mov rdi, 0", 10
           db "    syscall", 10
    source_len equ $ - source
    
    err_args db "Usage: ./asm16 <path_to_asm01>", 10
    err_args_len equ $ - err_args
    
    asm_suffix db ".s", 0
    nasm_cmd db "/bin/nasm", 0
    nasm_arg1 db "-f", 0
    nasm_arg2 db "elf64", 0
    
    ld_cmd db "/bin/ld", 0
    ld_arg1 db "-o", 0
    ld_arg3 db "asm01.o", 0
    
    nasm_args dq nasm_cmd
              dq nasm_arg1
              dq nasm_arg2
              dq 0
              dq 0
    
    ld_args dq ld_cmd
            dq ld_arg1
            dq 0
            dq ld_arg3
            dq 0

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 2
    jl print_usage
    
    pop rdi
    pop rdi
    
    mov rsi, path_buffer
    call copy_string
    
    mov rdi, path_buffer
    mov rsi, asm_src_path
    call copy_string
    
    mov rdi, asm_src_path
    call get_string_length
    
    mov rdi, asm_src_path
    add rdi, rax
    mov rsi, asm_suffix
    call copy_string
    
    mov rax, 2
    mov rdi, asm_src_path
    mov rsi, 1101o
    mov rdx, 0644o
    syscall
    
    cmp rax, 0
    jl error
    
    mov r12, rax
    
    mov rax, 1
    mov rdi, r12
    mov rsi, source
    mov rdx, source_len
    syscall
    
    mov rax, 3
    mov rdi, r12
    syscall
    
    mov rdi, asm_src_path
    call execute_nasm_and_ld
    
    xor rdi, rdi
    jmp exit
    
print_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, err_args
    mov rdx, err_args_len
    syscall
    
error:
    mov rdi, 1
    
exit:
    mov rax, 60
    syscall

copy_string:
    xor rcx, rcx
    
copy_loop:
    mov al, [rdi + rcx]
    mov [rsi + rcx], al
    inc rcx
    test al, al
    jnz copy_loop
    
    ret

get_string_length:
    xor rax, rax
    
length_loop:
    cmp byte [rdi + rax], 0
    je length_done
    inc rax
    jmp length_loop
    
length_done:
    ret

execute_nasm_and_ld:
    mov [nasm_args + 24], rdi
    
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r9, rax
    
    mov rax, 57
    syscall
    
    test rax, rax
    jnz parent_wait
    
    mov rax, 59
    mov rdi, nasm_cmd
    mov rsi, nasm_args
    xor rdx, rdx
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
parent_wait:
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    mov rax, 61
    syscall
    
    mov rdi, path_buffer
    mov [ld_args + 16], rdi
    
    mov rax, 57
    syscall
    
    test rax, rax
    jnz parent_wait2
    
    mov rax, 59
    mov rdi, ld_cmd
    mov rsi, ld_args
    xor rdx, rdx
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall
    
parent_wait2:
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    mov rax, 61
    syscall
    
    ret
