;功能：一个包含多个功能子程序的中断处理程序


assume cs:code,ds:data

data segment
        db  '(1)clear print             ',0
        db  '(2)set frontclolor         ',0
        db  '(3)set backclolor          ',0
        db  '(4)scroll up with one line ',0
    	db  'Select one of the function ',0
    ts  db  'Set the color wiht 0~9     ',0
   len  equ $-ts
data ends 

code segment
start:
	mov ax,data		;显示主选单
	mov ds,ax
	mov si,0
        mov dh,8
	mov dl,10
	mov cx,5
   next:
	push cx
	mov cl,84h
	call show_str
	add si,len
	add dh,2
	pop cx
	loop next
				;选择子功能号
 input:
	mov ah,1
	int 21h
	
	cmp al,1+30h
	jb input
	cmp al,4+30h
	ja input
	sub al,31h
	call setscreen

	mov ah,4ch		;返回dos
	int 21h

;各个子程序的入口子程序
setscreen: jmp short setstart
	table: dw sub1,sub2,sub3,sub4
setstart:
	push bx
	
	mov bl,al
	sub bh,bh
	add bx,bx
	call  word ptr table[bx] 
		
	pop bx
ret

;清除屏幕子程序 
sub1:
	push bx
	push cx
	push es 
	
	mov bx,0b800h
	mov es,bx
	mov bx,0
	mov cx,2000
 s1next:
	mov byte ptr es:[bx],' '
	mov byte ptr es:[bx+1],0
	add bx,2
	loop s1next

	pop es
	pop cx
	pop bx
ret

;设置前景色
sub2:   
	push bx
	push cx
	push dx
	push es
	push ds
	push si
		
	mov bx,data		;显示主选单
	mov ds,bx
	mov si,offset ts
        mov dh,4
	mov dl,10
	mov cl,02
	call show_str

	call selcolor

	mov bx,0b800h
	mov es,bx
	mov bx,0
	mov cx,2000
 s2next:
	and byte ptr es:[bx+1],11111000b
	or es:[bx+1],al
	add bx,2
	loop s2next
 
	pop si
	pop ds
	pop es
	pop dx
	pop cx
	pop bx 
ret
;设置背景色
sub3:	
	push ax
	push bx
	push cx
	push dx
	push es
	push ds
	push si
	
	mov bx,data		;显示主选单
	mov ds,bx
	mov si,offset ts
        mov dh,4
	mov dl,10
	mov cl,02
	call show_str
	call selcolor

	mov cl,4
	shl al,cl	
	mov bx,0b800h
	mov es,bx
	mov bx,0
	mov cx,2000
 s3next:
	and byte ptr es:[bx+1],10001111b
	or es:[bx+1],al
	add bx,2
	loop s3next
	
	pop si
	pop ds
	pop es
	pop dx
	pop cx
	pop bx 
	pop ax
ret
;向上滚动一行
sub4:	
	push bx
	push cx
	push ds
	push si
	
	mov cx,0b800h
	mov ds,cx
	mov si,0
	mov bx,0

	mov cx,24
s4next:
	push cx
	mov cx,80
s4next1:
	mov ax,[bx+si+160]
	mov [bx+si],ax 
	add si,2
	loop s4next1
	add bx,2
	pop cx
	loop s4next

 	pop si
	pop ds
	pop cx
	pop bx
ret


;选择颜色参数子程序
;出口参数：al，颜色属性
selcolor: 
	mov ah,1	
	int 21h

	sub al,30h
	cmp al,0
	jb selcolor
	cmp al,7
	ja selcolor 
ret
;显示字符串子程序
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
code ends
end start
