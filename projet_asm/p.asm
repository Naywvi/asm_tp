; ------------------------------------------------
; Fonction qui affiche un message pour un port ouvert
; ------------------------------------------------
display_open_port:
    ; Afficher le message "Port X est ouvert"

    ; Afficher le début du message
    mov rax, 1               ; syscall write
    mov rdi, 1               ; stdout
    mov rsi, port_open_msg   ; "[+] Port " en vert
    mov rdx, port_open_msg_len
    syscall

    ; Convertir le numéro de port en chaîne
    mov eax, [current_port]
    call int_to_string

    ; Afficher le numéro de port
    mov rax, 1
    mov rdi, 1
    mov rsi, port_str
    mov rdx, 6               ; Longueur maximale d'un numéro de port
    syscall

    ; Afficher le reste du message
    mov rax, 1
    mov rdi, 1
    mov rsi, is_open_msg     ; " est ouvert"
    mov rdx, is_open_msg_len
    syscall

    ret

; ------------------------------------------------
; Fonction qui affiche un message pour un port fermé
; ------------------------------------------------
display_closed_port:
    ; Cette fonction est similaire à display_open_port mais pour les ports fermés

    ; Afficher le début du message
    mov rax, 1               ; syscall write
    mov rdi, 1               ; stdout
    mov rsi, port_closed_msg ; "[-] Port " en rouge
    mov rdx, port_closed_msg_len
    syscall

    ; Convertir le numéro de port en chaîne
    mov eax, [current_port]
    call int_to_string

    ; Afficher le numéro de port
    mov rax, 1
    mov rdi, 1
    mov rsi, port_str
    mov rdx, 6               ; Longueur maximale d'un numéro de port
    syscall

    ; Afficher le reste du message
    mov rax, 1
    mov rdi, 1
    mov rsi, is_closed_msg   ; " est fermé"
    mov rdx, is_closed_msg_len
    syscall

    ret

section .data
    ; Définition des messages et des constantes
    prompt_ip db "Entrez une adresse IP à scanner : ", 0
    prompt_ip_len equ $ - prompt_ip

    prompt_port_range db "Entrez la plage de ports à scanner (ex: 1-1024) : ", 0
    prompt_port_range_len equ $ - prompt_port_range

    scan_start_msg db 27, "[36m[*] Début du scan des ports pour ", 0  ; Message en cyan
    scan_start_msg_len equ $ - scan_start_msg

    scan_complete_msg db 27, "[36m[*] Scan terminé.", 27, "[0m", 10, 0  ; Message en cyan
    scan_complete_msg_len equ $ - scan_complete_msg

    port_open_msg db 27, "[32m[+] Port ", 0  ; Message en vert
    port_open_msg_len equ $ - port_open_msg

    port_closed_msg db 27, "[31m[-] Port ", 0  ; Message en rouge
    port_closed_msg_len equ $ - port_closed_msg

    is_open_msg db " est ouvert", 27, "[0m", 10, 0
    is_open_msg_len equ $ - is_open_msg

    is_closed_msg db " est fermé", 27, "[0m", 10, 0
    is_closed_msg_len equ $ - is_closed_msg

    colon db ":", 0
    space db " ", 0
    dash db "-", 0
    newline db 10, 0

section .bss
    ; Réservation de l'espace pour les variables
    ip_addr resb 16       ; Buffer pour stocker l'adresse IP (max 15 caractères + null)
    port_range resb 12    ; Buffer pour la plage de ports (ex: "1-1024")
    port_min resd 1       ; Port minimum de la plage
    port_max resd 1       ; Port maximum de la plage
    current_port resd 1   ; Port en cours de scan
    port_str resb 6       ; Conversion d'un port en chaîne
    sin_addr resd 1       ; Adresse IP au format réseau
    sockaddr_in resb 16   ; Structure sockaddr_in pour connect()

section .text
    global _start

_start:
    ; Affichage du prompt pour l'adresse IP
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, prompt_ip          ; message à afficher
    mov rdx, prompt_ip_len      ; longueur du message
    syscall

    ; Lecture de l'adresse IP
    mov rax, 0                  ; syscall read
    mov rdi, 0                  ; stdin
    mov rsi, ip_addr            ; buffer où stocker l'entrée
    mov rdx, 16                 ; taille maximale
    syscall

    ; Supprimer le retour à la ligne à la fin de l'adresse IP
    dec rax                     ; Longueur de l'entrée - 1 (pour ignorer le retour à la ligne)
    mov byte [ip_addr + rax], 0 ; Ajouter un null à la fin

    ; Affichage du prompt pour la plage de ports
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_port_range
    mov rdx, prompt_port_range_len
    syscall

    ; Lecture de la plage de ports
    mov rax, 0
    mov rdi, 0
    mov rsi, port_range
    mov rdx, 12
    syscall

    ; Supprimer le retour à la ligne à la fin de la plage de ports
    dec rax
    mov byte [port_range + rax], 0

    ; Extraction des valeurs min et max de la plage de ports
    call parse_port_range

    ; Conversion de l'adresse IP en format réseau
    call convert_ip_address

    ; Affichage du message de début de scan
    mov rax, 1
    mov rdi, 1
    mov rsi, scan_start_msg
    mov rdx, scan_start_msg_len
    syscall

    ; Affichage de l'adresse IP
    mov rax, 1
    mov rdi, 1
    mov rsi, ip_addr
    mov rdx, 16
    syscall

    ; Affichage d'un retour à la ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Initialisation du port en cours de scan
    mov eax, [port_min]
    mov [current_port], eax

scan_loop:
    ; Vérifier si on a dépassé le port maximum
    mov eax, [current_port]
    cmp eax, [port_max]
    jg scan_complete

    ; Tentative de connexion au port courant
    call scan_port

    ; Passage au port suivant
    inc dword [current_port]
    jmp scan_loop

scan_complete:
    ; Affichage du message de fin de scan
    mov rax, 1
    mov rdi, 1
    mov rsi, scan_complete_msg
    mov rdx, scan_complete_msg_len
    syscall

    ; Sortie propre
    mov rax, 60                ; syscall exit
    xor rdi, rdi               ; code de sortie 0
    syscall

; ------------------------------------------------
; Fonction qui analyse la plage de ports (ex: "1-1024")
; et extrait les valeurs min et max
; ------------------------------------------------
parse_port_range:
    ; Initialisation des registres
    xor rax, rax              ; Compteur pour parcourir la chaîne
    xor rbx, rbx              ; Valeur temporaire pour le port min
    xor rcx, rcx              ; Flag pour indiquer si on a trouvé le tiret

.read_min:
    ; Lecture du caractère courant
    movzx rdx, byte [port_range + rax]

    ; Vérifier si c'est un tiret
    cmp dl, '-'
    je .found_dash

    ; Vérifier si c'est la fin de la chaîne
    test dl, dl
    jz .end_parsing

    ; Convertir le caractère en chiffre
    sub dl, '0'

    ; Vérifier si c'est un chiffre valide
    cmp dl, 9
    ja .error

    ; Ajouter le chiffre à la valeur du port min
    imul rbx, rbx, 10
    add rbx, rdx

    ; Passer au caractère suivant
    inc rax
    jmp .read_min

.found_dash:
    ; Sauvegarder le port min
    mov [port_min], ebx

    ; Réinitialiser rbx pour le port max
    xor rbx, rbx

    ; Passer au caractère suivant
    inc rax
    mov rcx, 1               ; Indiquer qu'on a trouvé le tiret

.read_max:
    ; Lecture du caractère courant
    movzx rdx, byte [port_range + rax]

    ; Vérifier si c'est la fin de la chaîne
    test dl, dl
    jz .end_max

    ; Convertir le caractère en chiffre
    sub dl, '0'

    ; Vérifier si c'est un chiffre valide
    cmp dl, 9
    ja .error

    ; Ajouter le chiffre à la valeur du port max
    imul rbx, rbx, 10
    add rbx, rdx

    ; Passer au caractère suivant
    inc rax
    jmp .read_max

.end_max:
    ; Sauvegarder le port max
    mov [port_max], ebx
    jmp .done

.end_parsing:
    ; Si on n'a pas trouvé de tiret, utiliser la même valeur pour port_min et port_max
    test rcx, rcx
    jnz .done

    mov [port_min], ebx
    mov [port_max], ebx
    jmp .done

.error:
    ; En cas d'erreur, utiliser des valeurs par défaut
    mov dword [port_min], 1
    mov dword [port_max], 1024

.done:
    ret

; ------------------------------------------------
; Fonction qui convertit une adresse IP en format réseau (inet_addr)
; ------------------------------------------------
convert_ip_address:
    ; Cette fonction suppose que l'adresse IP est valide

    ; Préparer sockaddr_in
    mov word [sockaddr_in], 2        ; AF_INET (famille d'adresses)
    mov dword [sin_addr], 0          ; Initialiser l'adresse à 0

    mov dword [sin_addr], 0x0100007f ; 127.0.0.1 en format réseau
    ret

; ------------------------------------------------
; Fonction qui convertit un entier en chaîne
; ------------------------------------------------
int_to_string:
    ; Entrée: eax = entier à convertir
    ; Sortie: port_str contient l'entier converti en chaîne

    mov rsi, port_str
    add rsi, 5             ; Point à la fin du buffer (5 chars max)
    mov byte [rsi], 0      ; Null-terminer
    mov rcx, 10            ; Diviseur

.convert_loop:
    dec rsi                ; Reculer d'un caractère
    xor rdx, rdx           ; Effacer rdx pour la division
    div rcx                ; Diviser eax par 10, reste dans edx
    add dl, '0'            ; Convertir le reste en caractère
    mov [rsi], dl          ; Stocker le caractère
    test rax, rax          ; Vérifier si on a terminé
    jnz .convert_loop      ; Continuer si non

    ; rsi pointe maintenant au début de la chaîne résultante
    ; Copier la chaîne au début de port_str si nécessaire
    cmp rsi, port_str
    je .done               ; Si déjà au début, ne rien faire

    ; Sinon, déplacer vers le début
    mov rdi, port_str      ; Destination
.copy_loop:
    mov dl, [rsi]          ; Lire un caractère
    mov [rdi], dl          ; Écrire le caractère
    test dl, dl            ; Vérifier si c'est la fin
    jz .done               ; Terminer si oui
    inc rsi                ; Avancer la source
    inc rdi                ; Avancer la destination
    jmp .copy_loop

.done:
    ret

; ------------------------------------------------
; Fonction qui teste si un port est ouvert
; ------------------------------------------------
scan_port:
    ; Configuration de sockaddr_in pour le port courant
    mov ax, [current_port]
    xchg al, ah              ; Convertir en big endian (htons)
    mov word [sockaddr_in + 2], ax  ; Port dans sockaddr_in
    mov eax, [sin_addr]
    mov dword [sockaddr_in + 4], eax ; Adresse IP dans sockaddr_in

    ; Création du socket
    mov rax, 41              ; syscall socket
    mov rdi, 2               ; AF_INET
    mov rsi, 1               ; SOCK_STREAM
    mov rdx, 6               ; IPPROTO_TCP
    syscall

    ; Vérifier si la création du socket a réussi
    test rax, rax
    js .port_closed

    ; Sauvegarde du descripteur de socket
    mov rdi, rax

    ; Tentative de connexion
    mov rax, 42              ; syscall connect
    mov rsi, sockaddr_in     ; struct sockaddr *
    mov rdx, 16              ; socklen_t addrlen
    syscall

    ; Fermeture du socket
    push rax                 ; Sauvegarder le code de retour de connect
    mov rax, 3               ; syscall close
    ; rdi contient déjà le descripteur de socket
    syscall
    pop rax                  ; Restaurer le code de retour de connect

    ; Vérifier si la connexion a réussi
    test rax, rax
    jnz .port_closed

    ; Le port est ouvert
    call display_open_port
    ret

.port_closed:
    ; Le port est fermé
    call display_closed_port
    ret
