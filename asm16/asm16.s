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

section .text
    global _start

_start:
    pop rcx             ; Nombre d'arguments
    cmp rcx, 2          ; Au moins 2 arguments (programme + chemin)
    jl print_usage
    
    pop rdi             ; Ignorer le nom du programme
    pop rdi             ; Chemin de asm01
    
    ; Copier le chemin dans path_buffer
    mov rsi, path_buffer
    call copy_string
    
    ; Créer le chemin pour le fichier source (.s)
    mov rdi, path_buffer
    mov rsi, asm_src_path
    call copy_string
    
    mov rdi, asm_src_path
    call get_string_length
    
    mov rdi, asm_src_path
    add rdi, rax
    mov rsi, asm_suffix
    call copy_string
    
    ; Créer le fichier source
    mov rax, 2
    mov rdi, asm_src_path
    mov rsi, 1101o      ; O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0644o      ; Permissions
    syscall
    
    cmp rax, 0
    jl error
    
    mov rdi, rax        ; Descripteur de fichier
    mov rax, 1          ; sys_write
    mov rsi, source     ; Contenu à écrire
    mov rdx, source_len ; Longueur du contenu
    syscall
    
    mov rax, 3          ; sys_close
    syscall
    
    ; Préparer les arguments pour nasm
    mov qword [nasm_args + 24], asm_src_path
    
    ; Préparer les arguments pour ld
    mov qword [ld_args + 16], path_buffer
    
    ; Compiler avec nasm
    mov rax, 59         ; sys_execve
    mov rdi, nasm_cmd   ; Commande à exécuter
    mov rsi, nasm_args  ; Arguments
    xor rdx, rdx        ; Environnement
    syscall
    
    ; Si nasm ne s'exécute pas normalement, on passe ici
    ; Compiler avec ld
    mov rax, 59         ; sys_execve
    mov rdi, ld_cmd     ; Commande à exécuter
    mov rsi, ld_args    ; Arguments
    xor rdx, rdx        ; Environnement
    syscall
    
    ; Si tout va bien, on ne devrait jamais arriver ici car execve ne retourne
    ; qu'en cas d'erreur
    xor rdi, rdi        ; Code de retour 0
    jmp exit
    
print_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, err_args
    mov rdx, err_args_len
    syscall
    
error:
    mov rdi, 1          ; Code de retour 1
    
exit:
    mov rax, 60         ; sys_exit
    syscall

; Fonction pour copier une chaîne de caractères
; rdi = source, rsi = destination
copy_string:
    xor rcx, rcx
    
copy_loop:
    mov al, [rdi + rcx]
    mov [rsi + rcx], al
    inc rcx
    test al, al
    jnz copy_loop
    
    ret

; Fonction pour obtenir la longueur d'une chaîne de caractères
; rdi = chaîne, retourne la longueur dans rax
get_string_length:
    xor rax, rax
    
length_loop:
    cmp byte [rdi + rax], 0
    je length_done
    inc rax
    jmp length_loop
    
length_done:
    ret

section .data
    nasm_cmd db "/usr/bin/nasm", 0
    nasm_args dq nasm_cmd
              dq nasm_arg1
              dq nasm_arg2
              dq 0
              dq 0
    
    nasm_arg1 db "-f", 0
    nasm_arg2 db "elf64", 0
    
    ld_cmd db "/usr/bin/ld", 0
    ld_args dq ld_cmd
            dq ld_arg1
            dq 0
            dq ld_arg3
            dq 0
    
    ld_arg1 db "-o", 0
    ld_arg3 db "asm01.o", 0
