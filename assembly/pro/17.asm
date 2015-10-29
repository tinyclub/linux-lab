;功能：编写新的int 7ch中断，实现通过逻辑扇区对软盘进行读写


assume cs:code
code segment
start:
	mov ax,cs			;安装中断处理程序
	mov ds,ax
	mov si,offset int7c
	mov ax,0
	mov es,ax
	mov di,200h
	mov cx,offset int7cend-offset int7c
        cld 
	rep movsb

	mov ax,0			;设置中断向量表
	mov es,ax
	mov word ptr es:[7ch*4],200h
	mov word ptr es:[7ch*4+2],0
	
	mov ax,4c00h			;返回dos
	int 21h

					;设置新int7ch中断处理程序
;中断处理程序说明
;入口参数：ah:0  表示读，1表示写，al:表示要读写的扇区数
;          cx：要读写的逻辑扇区号(这里翻译成物理扇区号为：dh,ch,cl);因为是对软盘进行读写，所以dl固定为0
;	   es:bx指向存储读出数据或写入数据的内存区
;实际入口参数：ah,al,cx,es:bx       一共需要的参数有：ah,al,dh,dl,ch,cl,es:bx
int7c:	
	push ax
	push bx
	push cx
	push dx
	push es
	
	push ax				;因为下面有寄存器冲突，这里先保存ax和bx中的数据
	push bx
	
	sub dx,dx			;把cx翻译成dh，ch，cl
	mov ax,cx			;求dh
	mov bx,1440
	div bx
	mov bx,dx
	mov dh,al
	push dx

	sub dx,dx
	mov ax,bx			;求ch
	mov bx,18
	div bx
	mov bx,dx
	mov ch,al
	
	inc bx				;求cl
	mov cl,bl 
	
	pop dx
	pop bx
	pop ax	
	mov dl,0
	add ah,2
	int 13h

	pop es
	pop dx
	pop cx
	pop bx
	pop ax
        iret
int7cend:nop
code ends
end start
