section .text
	global _start

_start:
	mov ebp, esp
	add ebp, 8

	mov eax, [ebp]
	xor ebx, ebx

.loop:
	mov cl, byte [eax]
	cmp ecx, 0
	je .done_converting
	sub cl, 0x30
	imul ebx, 10
	add ebx, ecx
	inc eax
	jmp .loop

.done_converting:
	mov ecx, 2

.prime_test:
	cmp ecx, ebx
	je .is_prime
	mov eax, ebx
	xor edx, edx 
	div ecx
	cmp edx, 0 
	je .not_prime
	inc ecx
	jmp .prime_test

.is_prime:
	xor ebx, ebx
	jmp .exit

.not_prime:
	mov ebx, 0x01

.exit:
	mov eax, 0x01
	int 0x80