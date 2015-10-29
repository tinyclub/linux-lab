;功能说明：向内存0：200~0：23f依次传送0~63

assume cs:code		    ;这里assume为了把cs和code联系起来；assume的功能是把某个段的段超越与某个段寄存器联系起来
			    
code segment
 	mov bx,0	    ;一个循环程序通常包括：(1)循环初始化部分。(2)循环体。(3)循环参数修改部分。(4)循环控制部分。
	mov ds,bx	    
	mov cx,40h	    
   next:
	mov ds:[bx+200h],bx
	inc bx		    ;这里的功能相当于"(bx)=(bx)+1"
        loop next

	mov ah,4ch	    :这里调用dos的int 21h中的4ch号功能返回dos
	int 21h
code ends		    ;这里的ends标记代码段的结束
end			    ;end标记整个程序段的结束	
