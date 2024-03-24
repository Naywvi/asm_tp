section .data
	buf: db "42", 0x0a
	msg: db "1337", 0x0a
	len: equ $-msg

section .text
	global _start

_start:
	mov ebp, esp
	cmp byte [ebp], 2 
	jne not_equal

	add ebp, 8
	mov edx, [ebp]
	xor ecx, ecx

.loop:
	mov al, byte [edx]
	cmp byte [buf + ecx], 0x0a
	je .equal
	cmp al, [buf + ecx]	
	jne not_equal
	inc ecx
	inc edx 
	jmp .loop

.equal:
	; print msg
	mov ebx, 0x01
	mov ecx, msg
	mov edx, len
	mov eax, 0x04
	int 0x80
	
	mov ebx, 0
	jmp exit

not_equal:
	mov ebx, 1

exit:
	mov eax, 0x01
	int 0x80