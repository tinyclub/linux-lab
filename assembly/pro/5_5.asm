;功能：将a段和b段中的数据依次相加，将结果保存到c段中

assume cs:code

a segment
	db 1,2,3,4,5,6,7,8
a ends

b segment
	db 1,2,3,4,5,6,7,8
b ends
 
c segment 
	db 0,0,0,0,0,0,0,0
c ends

code segment
start: 
	mov ax,a
	mov ds,ax
	mov bx,0
        mov cx,8
      s:
	mov ax,[bx]
	add ax,[bx+16]	
	mov [bx+32],ax
	inc bx
	loop s
	
	mov ah,4ch
	int 21h
code ends
end start
