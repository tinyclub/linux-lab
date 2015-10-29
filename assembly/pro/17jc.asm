;功能：检测实验十七的程序，目的是向软盘的0面0道1扇区中写入一些数据，然后读出来，查看是否写正确


assume cs:code
code segment
start:
	mov ax,0				;先用int 7ch写入到把中断向量表中的前512个字节写入到软盘的0面0到1扇区中
	mov es,ax
	mov bx,0
	mov ah,1
	mov al,1
        mov cx,1
	int 7ch

	
        mov ax,3000h
	mov es,ax
	mov bx,0h				;现在用int 7ch又把刚才写过的扇区中的数据读出到0：200h处,可以通过查看0：200处的数据看是否上面是否读正确
	mov ah,0
	mov al,1
        mov cx,1
	int 7ch

	mov ah,4ch
	int 21h
code ends
end start
