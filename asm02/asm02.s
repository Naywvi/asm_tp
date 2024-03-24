section .data
	buf: db "42", 0x0a
	msg: db "1337", 0x0a
	len: equ $-msg
	max: equ $-buf

section .bss
	str: resb 10 ; 10 bytes d'allocation de mémoire

section .text
	global _start

_start:
	mov ebx, 0 		
	mov ecx, str 	
	mov edx, 10 	
	mov eax, 0x03 	; syscall id read
	int 0x80

	xor ecx, ecx

.loop:
	mov al, [buf + ecx]
	cmp al, 0x0a
	je .test_size
	cmp byte [str + ecx], al	; Comparer les string
	jne .not_equal
	inc ecx
	jmp .loop

.test_size:
	cmp byte[str + ecx], 0x0a
	jne .not_equal
	jmp .equal

.equal:
	; print msg
	mov ebx, 0x01
	mov ecx, msg
	mov edx, len
	mov eax, 0x04
	int 0x80

	mov ebx, 0
	jmp exit

.not_equal:
	mov ebx, 1

exit:
	mov eax, 0x01
	int 0x80