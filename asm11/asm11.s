section .data
    buffer times 1024 db 0
    result times 20 db 0
    vowels db "aAeEiIoOuUyY", 0

section .text
    global _start

_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 1024
    syscall
    
    mov rbx, 0
    mov rdi, buffer
    
count_loop:
    movzx rax, byte [rdi]
    cmp al, 0
    je end_count
    cmp al, 10
    je end_count
    
    push rdi
    mov rdi, rax
    call is_vowel
    pop rdi
    
    add rbx, rax
    
    inc rdi
    jmp count_loop
    
end_count:
    mov rdi, rbx
    call print_number
    
    mov rax, 60
    xor rdi, rdi
    syscall
    
is_vowel:
    xor rcx, rcx
    mov rsi, vowels
    
vowel_loop:
    movzx rax, byte [rsi + rcx]
    cmp al, 0
    je not_vowel
    
    cmp al, dil
    je found_vowel
    
    inc rcx
    jmp vowel_loop
    
found_vowel:
    mov rax, 1
    ret
    
not_vowel:
    xor rax, rax
    ret

print_number:
    mov rax, rdi
    mov rbx, 10
    mov rdi, result
    add rdi, 19
    mov byte [rdi], 10
    dec rdi
    mov rcx, 1
    
print_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    inc rcx
    test rax, rax
    jnz print_loop
    
    inc rdi
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    mov rdx, rcx
    syscall
    ret
