;功能：使得在除法溢出发生时，在屏幕中间显示字符串“divide error!”,然后返回dos


assume cs:code,ss:stack

stack segment
	db 128 dup (0)
stack ends

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

;第三步：设置中断向量表
	mov word ptr es:[0*4],200h
	mov word ptr es:[0*4+2],0

;第四步：写检测程序(制造一个除法出错，检测我们写的中断处理程序是否可以实现)
	mov dx,152
	mov ax,0
	mov cx,2
	div cx

;第一步：编写中断处理程序
do0:	jmp short do0start
	db 'divide error!'
do0start:	
	mov ax,cs
	mov ds,ax
	mov si,202h			;设置ds:si指向字符串，这里的前提是我们把处理程序安装在200h开始的内存中
	
	mov ax,0b800
	mov es,ax
	mov di,160*12+34*2
	
	mov cx,13
  dnext:
	mov al,[si]
	mov es:[di],al
	mov es:[di+1],81h		;设置字符显示的颜色
	inc si	
	add di,2
	loop dnext

	mov ah,4c			;返回dos
	int 21h
do0end:nop
code ends
end start