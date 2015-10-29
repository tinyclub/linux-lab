;实验13第一个中断例程的检测程序
assume cs:code

data segment
	db "welcome to masm!",0
data ends

code segment
start:
	mov dh,10
	mov dl,10
	mov cl,2
	mov ax,data
	mov ds,ax
	mov si,0
        int 7ch
	mov ax,4c00h
	int 21h
code ends
end start 