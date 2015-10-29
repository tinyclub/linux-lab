;功能：编写中断处理程序实现loop的功能

assume cs:code

code segment
start:
	mov ax,cs			;安装中断处理程序
	mov ds,ax
	mov si,offset lp
	mov ax,0
	mov es,ax
	mov di,200h
	mov cx,offset lpend-offset lp
	cld 
	rep movsb

	mov ax,0			;设置中断向量表
	mov es,ax
	mov word ptr es:[7ch*4],200h
	mov word ptr es:[7ch*4+2],0

	mov ax,4c00h
	int 21h
					;编写中断处理程序
lp:
	push bp
	mov bp,sp
	dec cx		;cx=cx-1，如果cx等于0，那么不需要修改se的偏移地址，直接取出段地址和偏移地址并退出
	jcxz lpret
	add [bp+2],bx	;se的偏移地址加上转移地址等于s的偏移地址,注：这里是因为在使用int指令调用中断处理程序的时候保存了s的偏移地址等数据
lpret:
	pop bp
	iret            ;pop ip----pop cs----popf(由于在每次调用中断之前已经压栈拉，顺序刚好和这里的相反)
lpend:nop
	
code ends
end start	