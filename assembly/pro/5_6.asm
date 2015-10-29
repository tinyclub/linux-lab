;功能：用push指令将a段中word数据，逆序存储到b段中

assume cs:code

a segment
	dw 1,2,3,4,5,6,7,8
a ends

b segment
	dw 0,0,0,0,0,0,0,0
b ends

code segment
start: 
	mov ax,a
	mov ds,ax
	mov bx,0
	mov ax,b
	mov ss,ax
	mov sp,16
        mov cx,8
      s:
	push [bx]
	add bx,2
	loop s
	
	mov ah,4ch
	int 21h
code ends
end start
