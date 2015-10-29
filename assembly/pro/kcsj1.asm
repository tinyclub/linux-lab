;功能：课程设计一，显示一个公司的一些数据，具体见《汇编语言》课程设计一


assume cs:codesg,ds:data

data segment
	db 11 dup (0)

  	db '1975','1976','1977','1978','1979','1980','1981','1982','1983'
  	db '1984','1985','1986','1987','1988','1989','1990','1991','1992'
  	db '1993','1994','1995'

  	dd 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,197514
  	dd 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000

  	dw 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5635,8226
  	dw 11542,14430,15257,17800
data ends

codesg segment

start:
      mov ax,data  			  
      mov ds,ax
      sub si,si
      mov dh,2

      sub bx,bx  			;注意：这里引入bx是为了很好的控制一次循环过后si的增量保持在4	 
      mov cx,21
 next:
      push cx
      
      mov di,dx				;***这里为了控制dh不受其他操作的影响
      mov cl,02h			;初始化颜色属性
      
      mov dl,0				
      mov ax,[si+11]                  ;移动年份数据
      mov ds:[0],ax
      mov ax,[si+2+11]
      mov ds:[2],ax   
      mov byte ptr ds:[4],0
      push si				;***这里是为了控制外面的si不受内部的操作影响
      sub si,si
      call show_str
      pop si
         					
      mov ax,[si+84+11]			;移动总收入数据
      mov dx,[si+86+11]
      push si
      call dtoc
      mov dx,di
      mov dl,20
      call show_str
      pop si 
      
      	   					                
      sub si,bx                   
      mov ax,[si+168+11]                ;移动雇员人数数据
      mov bp,ax				;***暂存ax，做为下面的操作的除数
      sub dx,dx
      add si,bx
      push si     
      call dtoc
      mov dx,di
      mov dl,40
      call show_str
      pop si

      mov ax,[si+84+11]                    ;进行除法操作，移动人均收入数据
      mov dx,[si+86+11]
      div bp
      sub dx,dx
      push si
      call dtoc
      mov dx,di
      mov dl,60
      call show_str
      pop si
      			             
      add si,4
      inc dh
      add bx,2 	
      pop cx	           
      loop next

      mov ah,4ch
      int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;子程序区;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;子程序说明
;参数：1，要转换的十进制数码的高16位和低16位：dx，ax
;      2，ds:si指向字符串的首地址
dtoc:
	push ax
	push cx
	push dx

	mov si,9
  dnext:
	mov cx,10
	call divdw
	add cx,30h
	
	mov [si],cl
	dec si
	cmp dx,0
	jne dnext
	cmp ax,0
	jne dnext
	inc si
	
	pop dx
	pop cx
	pop ax
ret
;子程序说明：
;入口参数：字符串显示的行与列dh,dl;字符串显示的颜色cl
;功能：屏幕的屏幕的dh行dl列，显示颜色为cl的字符串
show_str:                      		;显示字符串子程序入口
	push ax				;与pop指令结合进行相关寄存器的保护工作						
	push dx
	push cx
	push es
	push di
	push si
	
	mov ax,0b800h			;子程序体
	mov es,ax
	
	sub ax,ax
	mov al,160
	mul dh
	sub dh,dh
	add dl,dl
	add ax,dx
	mov di,ax

	mov al,cl
	sub cx,cx
  snext:
	mov cl,[si]	
	jcxz sret
	mov es:[di],cl
	mov es:[di+1],al
	inc si
	add di,2
	jmp short snext
   sret:	
	pop si
	pop di
	pop es
	pop cx
	pop dx
	pop ax	
ret	
;子程序说明：
;入口参数：被除数得高16位dx；被除数得低16位ax；除数cx
;返回参数：商得高16位dx；低16位ax；余数cx
;功能：32位除法
divdw:
	jmp short divstart
	datareg dw  4 dup (0)
divstart:
	push bx
	push ds
	push si

	cmp dx,cx		;通过这里实现兼容没有溢出的除法
	jb divnoflo

	mov bx,cs
	mov ds,bx
	mov si,offset datareg

	mov [si],ax             ;保存低16位L
	mov ax,dx		;求H/N,得到int(H/N)和rem(H/N),分别保存在ax和dx当中
	sub dx,dx		;***这个语句非常重要，对dx清零，避免溢出
	div cx
	mov [si+2],dx		;保存rem(H/N)
	mov bx,512		;求得int(H/N)*65536
	mul bx
	mov bx,128
	mul bx
	mov [si+4],ax		;保存int(H/N)*65536
	mov [si+6],dx
	mov ax,[si+2]		;求得rem(H/N)*65536
	mov bx,512
	mul bx
	mov bx,128
	mul bx
	add ax,[si]		;求得rem(H/N)*65536＋L
	div cx			;求得[rem(H/N)*65536＋L]/N ***注意这里进行的除法不能清除dx,这里不可能会溢出
	
	mov cx,dx		;求得结果得余数
	add ax,[si+4]		;求得结果的低16位
	mov dx,[si+6]		;求得结果得高16位 
	jmp short dsret
divnoflo:
	div cx
	mov cx,dx
	sub dx,dx
  dsret:
	pop si
	pop ds
	pop bx
ret
codesg ends
 end start 
