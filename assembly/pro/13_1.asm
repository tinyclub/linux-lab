;实验13，编写并安装中断例程int 7ch,功能显示一个用0结尾的字符串
assume cs:code

code segment 
start: 
	mov ax,cs
	mov ds,ax
	mov si,offset in7c
	mov ax,0
	mov es,ax
	mov di,200h
	mov cx,offset in7cend-offset in7c
        cld 
	rep movsb

	mov ax,0
	mov es,ax
	mov word ptr es:[7ch*4],200h
	mov word ptr es:[7ch*4+2],0
	
	mov ax,4c00h
	int 21h

in7c:
	push ax
	push bx
        push cx
	push dx
	push bp
	push es
        push di
	
	mov ax,0b800h
	mov es,ax
	mov ah,0	;行
	mov al,dh
	mov bl,160
	mul bl
	mov bp,ax
	mov dh,0	;列
	add dl,dl
	mov di,dx
	mov al,cl   	;颜色属性
s:
	mov cl,[si]	;移动数据
	mov ch,0
	jcxz inret	;检测是否为零，如果为零就退出
	mov es:[bp+di],cl
        mov es:[bp+di+1],al
	inc si	
        add di,2
	jmp short s
inret:
	pop di
	pop es
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	iret
in7cend:nop

code ends
end start
	
	
	
