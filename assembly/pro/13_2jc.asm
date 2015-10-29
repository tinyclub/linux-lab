;实验13的第二个中断例程的检测程序
assume cs:code
code segment
start:
	mov ax,0b800h
	mov es,ax
	mov bp,160*12
	mov di,0
	mov bx,offset s-offset se
	mov cx,80
s:
	mov byte ptr es:[bp+di],'!'
	mov byte ptr es:[bp+di+1],4
	add di,2
	int 7ch
se:nop
	mov ax,4c00h
	int 21h
code ends
end start