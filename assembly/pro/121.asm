;功能：使得在除法溢出发生时，在屏幕中间显示字符串“divide error!”,然后返回dos


assume cs:code

data segment
	dw 4 dup (0)
data ends

code segment
start:
;第二步：安装中断处理程序
	mov ax,cs
	mov ds,ax
	mov si,offset do0		;设置ds:si指向源地址
	mov ax,0
	mov es,ax
	mov di,200h			;设置es:di指向目标地址	
	mov cx,offset do0end-offset do0 ;设置传输长度
	cld				;设置传输方向为正
        rep movsb		

;第三步：保存原有的中断向量（在中断内部进行了恢复操作），设置中断向量表，
	mov ax,data
	mov ds,ax
	mov si,0
	mov ax,es:[0*4];
	mov [si],ax
	mov ax,es:[0*4+2]
	mov [si+2],ax
	
	cli				;在设置中断的过程中屏蔽其它可屏蔽中断，防止在设置中断向量表时出错
	mov word ptr es:[0*4],200h
	mov word ptr es:[0*4+2],0
	sti

;第四步：写检测程序(制造一个除法出错，检测我们写的中断处理程序是否可以实现)
	mov dx,152
	mov ax,0
	mov cx,2
	div cx

;第一步：编写中断处理程序
do0:	jmp short do0start
	db 'divide error!'
do0start:
	push ax				;保护相关的寄存器
	push ds
	push si
	push es
	push di
	
	mov ax,cs
	mov ds,ax
	mov si,202h			;设置ds:si指向字符串，这里的前提是我们把处理程序安装在200h开始的内存中
	
        mov ax,0b800h
	mov es,ax
	mov di,160*12+34*2
	
	mov cx,13
  dnext:
	mov al,[si]
	mov es:[di],al
        mov byte ptr es:[di+1],81h       ;设置字符显示的颜色
	inc si	
	add di,2
	loop dnext

	pop di
	pop es
	pop si
	pop ds
	pop ax

	mov ax,data			;恢复原有的中断
	mov ds,ax	
	mov si,0
	mov ax,0
	mov es,ax
	mov ax,[si];
	mov es:[0*4],ax
	mov ax,[si+2]
	mov es:[0*4+2],ax

	mov ah,4ch			;返回dos
	int 21h
do0end:nop
code ends
end start
