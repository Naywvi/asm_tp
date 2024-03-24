section .data
	msg: db "1337", 0x0a	; Declare le string avec un \n
	len: equ $-msg 			; Calcule la taille du string
	
section .text
	global _start

_start:
	mov eax, 0x04
	mov ebx, 0x01
	mov ecx, msg
	mov edx, len
	int 0x80

	; exit
	mov eax, 1;
	mov ebx, 0;
	int 0x80;