section .data
    output db "1337", 10
    output_len equ $ - output

section .text
    global _start

_start:
    pop rcx                 ; argc (nombre d'arguments)
    cmp rcx, 2              ; vérifier qu'il y a au moins un argument
    jne exit_with_error
    
    pop rdi                 ; argv[0] (nom du programme)
    pop rdi                 ; argv[1] (premier argument)
    
    cmp byte [rdi], '4'     ; premier caractère
    jne exit_with_error
    cmp byte [rdi+1], '2'   ; deuxième caractère
    jne exit_with_error
    cmp byte [rdi+2], 0     ; Vérifier que c'est bien la fin de la chaîne
    jne exit_with_error
    
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, output         ; message à afficher
    mov rdx, output_len     ; longueur du message
    syscall
    
    mov rax, 60             ; sys_exit
    mov rdi, 0              ; code de retour 0
    syscall
    
exit_with_error:
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code de retour 1
    syscall
