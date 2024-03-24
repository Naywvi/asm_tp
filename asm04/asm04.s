section .bss
	buf: resb 5

section .text
	global _start

_start:
	mov ebx, 0x00
	mov ecx, buf
	mov edx, 5
	mov eax, 0x03
	int 0x80

	xor ecx, ecx

.loop:
	inc ecx
	mov al, byte [buf + ecx]
	cmp al, 0x0a 
	jne .loop
	mov al, byte [buf + ecx - 1]
	sub al, 0x30

	and eax, 1
	cmp eax, 0
	jne .odd

	mov ebx, 0x00
	jmp .exit

.odd:
	mov ebx, 0x01
	
.exit:
	mov eax, 0x01
	int 0x80