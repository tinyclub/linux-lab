;功能：显示字符串子程序机器检测程序


assume cs:code,ds:data

data segment
        db 'welcome to masm!',0
data ends

code segment
start:
	mov ax,data
	mov ds,ax
	mov si,0

	mov dh,8
	mov dl,3
	mov cl,2
	call show_str

        mov ax,4c00h
	int 21h

;子程序说明：
;入口参数：字符串显示的行与列dh,dl;字符串显示的颜色cl;ds:si指向字符串的首地址
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
  next:
	mov cl,[si]	
	jcxz sret
	mov es:[di],cl
	mov es:[di+1],al
	inc si
	add di,2
	jmp short next
   sret:	
	pop si
	pop di
	pop es
	pop cx
	pop dx
	pop ax	

ret					;子程序返回
code ends
end start
