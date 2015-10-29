;功能：在屏幕的中间显示绿色的字符串“welcome to masm!”

assume cs:code,ds:data

data segment
        str	db 'welcome to masm!'
	N       =$-str			;这里用到了课外的知识，请自己参考相关的更全面汇编指令知识
data ends

code segment
start:
	mov ax,data
	mov ds,ax
	mov si,0
	mov ax,0b800h       		;注意：在asm文件中的数据不能以字母开头，所以需要在前面加0
	mov es,ax
	mov di,160*12+30*2
	mov cx,N
   next:
	mov al,[si]
	mov es:[di],al
	mov byte ptr es:[di+1],02h    	;这里需要在前面加上数据的字节属性，标志02在这里是字节
	inc si
	add di,2
	loop next

	mov ah,4ch
	int 21h
code ends
end start