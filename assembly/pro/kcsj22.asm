;;;;;;;;;;;;;;;;;;;;;;;;;说明部分;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;课程设计二全新精简版,已经去掉了不必要的注释和题目没有要求的一些功能(纯代码<=290)
;使用说明：首先准备一张空白软盘，然后在实模式或者虚拟8086模式下对这个文件用masm汇编、连接后，插入软盘，最后运行exe文件即制作一个可以在无系统的状态下启动计算机的软盘
;;;;;;;;;;;;;;;;;;;;;;;;;;程序部分;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
assume cs:code
code segment
;;;;;;;;;;;;;;;;;;;;;;;;;;;安装程序部分;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	anzhts1	db "Install success!",0Dh,0Ah,'$'
	anzhts2	db "install error!" ,0Dh,0Ah,'$'     
start:  ;安装任务程序：把程序写入软盘1扇区开始的2个扇区中,分两次写（为了在启动原有的操作系统时，不至于覆盖现有的程序）
	mov ax,cs				
	mov es,ax
	mov bx,offset cargador   		
	mov ax,0302h				
	mov cx,1
	sub dx,dx
	int 13h
	;检查是否安装成功：直接判断ah和al，如果返回的是0和扇区数，那么安装成功
	mov bx,cs
        mov ds,bx
	cmp ax,2
        jne error
        lea dx,anzhts1
	jmp showts
error:  lea dx,anzhts2
showts: mov ah,9
        int 21h
	;安装完成后返回dos
        mov ah,4ch
        int 21h
;;;;;;;;;;;;;;;;;;;;;任务程序部分;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;任务程序一;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;由于引导操作系统以后，已经把1扇区的内容读入到了0：7c00开始的512个字节处，所以为了保证程序完整的执行，还得把2扇区以后的1个扇区中的数据读入到0：7e00开始的内存区
cargador:
	mov ax,0
	mov es,ax
	mov bx,7e00h  
	mov ax,0201h
	mov cx,2
	sub dx,dx
	int 13h                   
;;;;;;;;;;;;;;;;;;;任务程序二;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;功能：实现题目要求的所有功能;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mysys:  jmp  mysysstart
	unit     db 9,8,7,4,2,0	         ;子程序用到的CMOS RAM的单元地址
	welcom   db "Welcome To The EagleFlying System",0		
        winmenu  db "1)         reset pc              ",0
         	 db "2)         start system          ",0
         	 db "3)         clock                 ",0
         	 db "4)         set clock             ",0
        select   db "Please select one of them        ",0
	coprig	 db "DesignedByEagle,lzu.qq:253087664 ",0
	lengt    equ $-coprig      
mysysstart: 
;;;;;;;;;;;;;;;;;;;主程序部分;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	call cleprint	;初始化清屏
	mov ax,cs	;显示主界面
	mov es,ax
	mov bp,offset welcom-offset cargador+7c00h
	mov dx,040Ah
	mov ax,1300h	
	mov bx,0021h	
	mov cx,7
mains:  push cx
	mov cx,lengt
	int 10h
	inc dh
	add bp,cx
	pop cx
	loop mains
inputs:	mov ah,0	;通过选择1――4进入功能子程序
	int 16h
	cmp al,1+30h
	jb inputs
	cmp al,4+30h
	ja inputs
	sub al,31h
	call setscreen	;调用进入功能子程序的入口程序
	jmp short mysysstart

;;;;;;;;;;;;;;;;;;;;;清除屏幕程序;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cleprint:
         push bx
         push cx
         push es
         mov bx,0b800h
         mov es,bx
         sub bx,bx
         mov cx,2000
   cles: mov word ptr es:[bx],2020h
         add bx,2
         loop cles
         pop es
         pop cx
         pop bx
ret

;;;;;;;;;;;;;;;;;;;;;4个功能子程序的入口程序;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;入口参数：al,只能是1――4;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
setscreen: jmp short setsstart
        subtable dw  offset sub1-offset cargador+7c00h,offset sub2-offset cargador+7c00h,offset sub3-offset cargador+7c00h,offset sub4-offset cargador+7c00h
setsstart:push ax	
	push bx
	call cleprint	;进入功能子程序之前进行屏幕清除工作
       	mov bx,offset subtable-offset cargador+7c00h
	sub ah,ah
	add al,al
	add bx,ax
	call word ptr cs:[bx]
	pop bx
	pop ax
ret	
		
;;;;;;;;;;;;;;;;;设置系统时间;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sub4:	jmp sub4start
	sub4ts db "Set clock,Press enter to save:   ",0
sub4start:
	push ax
	push bx
	push cx
	push dx
	push bp
	mov cx,lengt				;显示提示信息
	mov bp,offset sub4ts-offset cargador+7c00h	
	mov dx,0B09h
	mov ax,1300h	
	mov bx,0021h
	int 10h
	mov bx,0b800h
	mov es,bx			;显示“[”“]”
	mov word ptr es:[160*12+9*2],295bh
	mov word ptr es:[160*12+9*2+13*2],295dh
	mov dx,0C0Ah
	call setclock			 ;调用设置时间子程序
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
ret

;;;;;;;;;;;;;;;;;;;设置系统时间子程序;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;入口参数：显示时间的起始行与列dh,dl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
setclock:
	push ax
	push bx
	push cx
	push dx
	mov ah,2	;定位光标的初始位置
	mov bx,0024h
	int 10h
setcls:	mov ah,0	;输入数字控制修改时间和日期
	int 16h
	cmp al,0+30h		
	jb no0to9	
	cmp al,9+30h
	ja no0to9
	cmp dl,21	;限制输入的字符的个数为21-10+1个,10为初始的显示位置	
	ja setcls
	mov ah,9	;在光标处显示字符一次，并且光标后移
	mov cx,1
	int 10h
	inc dl
	mov ah,2	
	int 10h
        jmp setcls
no0to9: cmp ah,0eh
	je backspace
	cmp ah,1ch
	je enter
	cmp ah,1		
	je setcret
        jmp short setcls		
backspace:		;如果是退个键，那么清除当前位并且使得光标前移
	cmp dl,10
	je short setcls
	dec dl	        ;重新定位光标，并且删除一个字符
	mov ah,2		
	int 10h
	mov al,' '
	mov ah,9
	int 10h
        jmp short setcls
enter:	call savetocmos
        jmp short setcls
setcret:pop dx
	pop cx
	pop bx
	pop ax
ret

;;;;;;;;;;;;;;;;;;savetocmos;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
savetocmos:
	push ax
	push cx
	push di
	push es
	push si
	mov ax,0b800h		;初始化设置
	mov es,ax
	mov di,160*12+10*2	
	mov si,offset unit-offset cargador+7c00h
	mov al,dl
	sub al,9
	shr al,1
	sub cx,cx
	mov cl,al
savs:	push cx
	mov ah,es:[di]		;取得十位
	sub ah,30h
	mov cl,4
	shl ah,cl		
	mov al,es:[di+2]	;取得个位
	sub al,30h
	add ah,al		;得到两位的BCD码
	mov al,cs:[si]		;定位CMOS RAM的单元号
	out 70h,al
	mov al,ah
	out 71h,al		;把对应的字符值写入到相应的内存单元中
	add di,4
	inc si
	pop cx	
	loop savs
	pop si
	pop es
	pop di
	pop cx
	pop ax
ret

;;;;;;;;;;;;;动态显示系统当前的时间;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sub3:	jmp sub3start
	sub3ts db "NOW,The date and the time is:    ",0
sub3start:
	push ax
	push bx
	push cx
	push dx
	push bp
	mov cx,lengt				;显示提示信息
	mov bp,offset sub3ts-offset cargador+7c00h	
	mov dh,11
	mov ax,1300h	
	mov bx,0021h
	int 10h
	mov bl,21h				;动态显示当前时间
sub3s:  call showclock    			;调用显示时间子程序
	in al,60h
	cmp al,3bh
	je chcolor
	cmp al,1
	jne sub3s
	jmp  subret
chcolor:inc bl
	jmp  sub3s
subret:	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
ret

;;;;;;;;;;;;;;;;;;;;显示当前时间程序;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;入口参数：dh,dl显示时间的初始地址,这里固定为12和10;bl为显示的颜色;;;;;
showclock:
	push ax
	push cx
	push es
	push di
	push si
	mov ax,0b800h
	mov es,ax
	mov di,160*12+10*2	
	mov cx,2
shows:  mov word ptr es:[di+4],212fh
        mov word ptr es:[di+22],0A13ah
	add di,6
	loop shows
	sub di,12
	mov si,offset unit-offset cargador+7c00h
	mov cx,6
shos:	push cx
	mov al,cs:[si]	          ;读一个单元的数据	
	out 70h,al
	in al,71h
	mov ah,al
	mov cl,4
	shr ah,cl		
	and al,0Fh	
	or ax,03030h		
	mov es:[di],ah
	mov es:[di+1],bl	
	mov es:[di+2],al
	mov es:[di+3],bl
	add di,6
	inc si
	pop cx
	loop shos	
	pop si
	pop di
	pop es
	pop cx
	pop ax
ret

;;;;;;;;;;;;;;;;;;引导现有的操作系统;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sub2:	mov bx,7c00h  
	mov ax,0201h
	mov cx,0001h
	mov dx,0080h
	int 13h
      	mov ax,7c00h	
	jmp ax

;;;;;;;;;;;;;;;;;重新启动计算机;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sub1:	mov ax,0ffffh
        mov bx,0
        push ax
        push bx
        retf
;;;;;;;;;;;;;;;;;;;任务程序部分完;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
code ends
end start
;;;;;;;;;;;;;;;;;;;;;版权声明;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;在不使用到商业用途的前提下，"版权不要，翻版不究",目的是能够和大家共享资源，共同提高
;渴望与大家交流，qq:253087664  email:tunzhj03@st.lzu.edu.cn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;