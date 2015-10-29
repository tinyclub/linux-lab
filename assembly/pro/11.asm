;功能：编写一个子程序，将包含任意字符，以0结尾的字符串中的小写字母转变成大写字母

assume cs:code

data segment
	db "Beginner's All-purpose Symblic Instruction Code.",0
data ends

code segment
  start:
	mov ax,data
	mov ds,ax
	mov si,0
	call letterc

	mov ah,4ch
	int 21h

;子程序说明
;参数：ds:si指向字符串的入口地址
;功能：将包含任意字符的字符串中的小写字母转变成大写字母
letterc:
	push cx
	push si

  lnext:
	sub ch,ch
	mov cl,[si]
	jcxz lret
	cmp cl,'a'
	jb  plusi
        cmp cl,'z'
	ja  plusi
        and byte ptr [si],11011111b
 plusi:
	inc si
	jmp short lnext 
 lret:  
	pop si
	pop cx     	
ret	
code ends
end start
