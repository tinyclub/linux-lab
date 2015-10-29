;功能：32为除法实现


assume cs:code

code segment
start:
	mov dx,128
	mov ax,0
	mov cx,128
	call divdw

	mov ah,4ch
	int 21h

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



	