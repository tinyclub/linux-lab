;功能：把"mov ax,4c00h"之前的指令复制到内存的0：200处

assume cs:code
code segment
copystart: 
	mov ax,code              ;这里补充的是code，因为我们要复制的数据的起始地址是cs:0
	mov ds,ax
	mov ax,0020h
	mov es,ax
	mov bx,0
        mov cx,offset copyend-offset copystart  ;这里通过offset指令求得两个标号偏移地址之差去求所要传送的数据长度
      s:
	mov al,[bx]
	mov es:[bx],al
	inc bx
	loop s
copyend:
	mov ax,4c00h
	int 21h
code ends
end
