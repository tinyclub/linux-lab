;功能：把datasg段中的每个单词的前四个字母改为大写字母


assume cs:codesg,ss:stacksg,ds:datasg

stacksg segment
	dw 0,0,0,0,0,0,0,0
stacksg ends

datasg segment
	db '1,display       '
	db '2,brows         '
	db '3,replace       '
	db '4,modify        '
datasg ends

codesg segment
start:
	mov ax,datasg
	mov ds,ax
	mov ax,stacksg
	mov ss,ax
	mov sp,16
	mov bx,2
	sub si,si

	mov cx,4		;外循环
  next0:
	push cx			;与“pop cx”配合保护外层循环中的cx值
	
	mov cx,4		;内循环
  next1:	
        and byte ptr [bx+si],11011111b
	inc si
	loop next1
	
	pop cx
        sub si,si
	add bx,16
	loop next0

	mov ah,4ch
	int 21h
codesg ends
end start
