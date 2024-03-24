section .text
	global _start

_start:
	mov eax, 1 	; syscall 'exit'
	mov ebx, 0 	; Code d'erreur
	int 0x80 