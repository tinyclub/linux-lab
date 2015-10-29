;功能：动态的显示日期和时间


assume cs:code,ds:data

data segment
	ts db "Now, The Date and Time is:",0Dh,0Ah,'$'
	unit db 9,8,7,4,2,0
data ends

code segment
start:
	mov ax,data
	mov ds,ax
	lea dx,ts	;显示提示
	mov ah,9
	int 21h

	mov ax,0b800h	;置显示的行与列
	mov es,ax
	mov bx,3*160

        mov byte ptr es:[bx+4],'/'       ;在年、月、日之间加上‘/’，在时、分、秒之间写上‘：’
        mov byte ptr es:[bx+10],47
        mov byte ptr es:[bx+22],':'
	mov byte ptr es:[bx+28],58

	
dynxs:	mov di,0		;增加的功能1：通过循环的读取动态的显示时间信息
	mov si,offset unit

	mov cx,6		;********原来的设计要求************
s:	
	push cx
	mov al,[si]		;从CMOS RAM相应的内存单元中读出年月日，时分秒
	out 70h,al
	in al,71h
	mov ah,al
	mov cl,4
	shr ah,cl		;得到每中时间数据的十位
	and al,00001111b	;得到每种时间数据的各位

	add ah,30h		
	add al,30h
	mov byte ptr es:[bx+di],ah
	mov byte ptr es:[bx+di+1],02	;设置显示的颜色
	mov byte ptr es:[bx+di+2],al
	mov byte ptr es:[bx+di+3],02
        
	add di,6
	inc si
	pop cx
	loop s			;**********************************
	
	in al,60h		;增加的功能2：按下ESC时返回dos
	cmp al,01
	je away

	jmp short dynxs
away:	
	mov ax,4c00h
	int 21h
code ends
end start 
