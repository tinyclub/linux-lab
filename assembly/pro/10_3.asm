;功能：数值显示


assume cs:code,ds:data

data segment
	db 11 dup(0)
data ends

code segment
start:
	mov ax,data
	mov ds,ax
	mov dx,0
	mov ax,65532
	call dtoc
	mov dh,15
	mov dl,12
	mov cl,84h
	call show_str

	mov ah,4ch
	int 21h

;子程序说明
;参数：1，要转换的十进制数码的高16位和低16位：dx，ax
;      2，ds:si指向字符串的首地址
dtoc:
	push ax
	push cx
	push dx
	
	mov si,11-2
  dnext:
	mov cx,10
	call divdw
	add cx,30h
	
	mov [si],cl
	dec si
	cmp dx,0
	jne dnext
	cmp ax,0
	jne dnext
	inc si
	
        pop dx
	pop cx
	pop ax
ret
;子程序说明：
;入口参数：字符串显示的行与列dh,dl;字符串显示的颜色cl
;功能：屏幕的屏幕的dh行dl列，显示颜色为cl的字符串
show_str:                      		;显示字符串子程序入口
	push ax				;与pop指令结合进行相关寄存器的保护工作						
	push dx
	push cx
	push es
	push di
	push si
	
	mov ax,0b800h			;子程序体
	mov es,ax
	
	sub ax,ax
	mov al,160
	mul dh
	sub dh,dh
	add dl,dl
	add ax,dx
	mov di,ax

	mov al,cl
	sub cx,cx
  snext:
	mov cl,[si]	
	jcxz sret
	mov es:[di],cl
	mov es:[di+1],al
	inc si
	add di,2
	jmp short snext
   sret:	
	pop si
	pop di
	pop es
	pop cx
	pop dx
	pop ax	
ret	
;子程序说明：
;入口参数：被除数得高16位dx；被除数得低16位ax；除数cx
;返回参数：商得高16位dx；低16位ax；余数cx
;功能：32位除法
divdw:
	jmp short divstart
	datareg dw  4 dup (0)
divstart:
	push bx
	push ds
	push si

	cmp dx,cx		;通过这里实现兼容没有溢出的除法
	jb divnoflo

	mov bx,cs
	mov ds,bx
	mov si,offset datareg

	mov [si],ax             ;保存低16位L
	mov ax,dx		;求H/N,得到int(H/N)和rem(H/N),分别保存在ax和dx当中
	sub dx,dx		;***这个语句非常重要，对dx清零，避免溢出
	div cx
	mov [si+2],dx		;保存rem(H/N)
	mov bx,512		;求得int(H/N)*65536
	mul bx
	mov bx,128
	mul bx
	mov [si+4],ax		;保存int(H/N)*65536
	mov [si+6],dx
	mov ax,[si+2]		;求得rem(H/N)*65536
	mov bx,512
	mul bx
	mov bx,128
	mul bx
	add ax,[si]		;求得rem(H/N)*65536＋L
	div cx			;求得[rem(H/N)*65536＋L]/N ***注意这里进行的除法不能清除dx,这里不可能会溢出
	
	mov cx,dx		;求得结果得余数
	add ax,[si+4]		;求得结果的低16位
	mov dx,[si+6]		;求得结果得高16位 
	jmp short dsret
divnoflo:
	div cx
	mov cx,dx
	sub dx,dx
  dsret:
	pop si
	pop ds
	pop bx
ret
code ends
end start