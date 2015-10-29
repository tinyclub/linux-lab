;功能：在dos下，按下“A”键后，除非不再松开，如果松开，就显示满屏幕的“A”



assume cs:code

stack segment
	db 128 dup(0)
stack ends

code segment
start:
	mov ax,stack
	mov ss,ax
	mov sp,128
	push cs
	pop ds
	mov ax,0
	mov es,ax
	mov si,offset in9
	mov di,204h
	mov cx,offset in9end-offset in9
	cld
	rep movsb
	
	push es:[9*4];
	pop  es:[200h];
	push es:[9*4+2];
	pop es:[202h]

	cli
	mov word ptr es:[9*4],204h
	mov word ptr es:[9*4+2],0
	sti

	mov ah,4ch
	int 21h

						;新的中断例程的实现
in9:
	push ax
	push bx
	push cx
	push es

 	in al,60h				;从60端口读取数据
	
	pushf
	call dword ptr cs:[200h]		;调用原来的中断例程
	
	cmp al,9eh
	jne in9ret

	mov ax,0b800h				;如果松开了‘A’键，那么显示全屏幕的‘A’
	mov es,ax
	mov bx,0
	mov cx,2000
s:
	mov byte ptr es:[bx],'A'
	add bx,2
	loop s
in9ret:
	pop es
	pop cx
	pop bx
	pop ax
	iret
in9end:nop

code ends
end start
	