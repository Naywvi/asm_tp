section .data
	result db 4 dup(' ')

section .text
	global _start

_start:
	mov ebp, esp
	add ebp, 4
	mov edx, 0

.restart:
	mov ebx, 0
	add edx, 4
	mov eax, [ebp + edx]

.loop:
	mov cl, byte [eax]
	cmp cl, 0
	je .done
	sub cl, 0x30
	imul ebx, 10
	add ebx, ecx
	inc eax
	jmp .loop

.done:
	push ebx
	cmp edx, 8
	jne .restart

	pop eax
	pop ecx
	add eax, ecx

	xor edx, edx
	xor ecx, ecx
	mov ebx, 10

.to_decimal:
	xor edx, edx
	div ebx
	push edx
	inc ecx
	cmp eax, 0
	jne .to_decimal

	xor edx, edx

.to_string:
	pop eax
	dec ecx
	add al, 0x30
	mov byte [result + edx], al
	inc edx
	cmp ecx, 0
	jne .to_string
	mov byte [result + edx], 0x0a
	mov ebx, 0x01
	mov ecx, result
	mov edx, 4
	mov eax, 0x04
	int 0x80

.exit:
	mov ebx, 0x00
	mov eax, 0x01
	int 0x80