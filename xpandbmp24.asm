global xpandbmp24

; define input data labels on ebp
%define     image  		    [ebp+8]  		; points to begining of input image
%define     numerator   	[ebp+12]		; points to  scale num
%define     denumenator   	[ebp+16]		; points to sclae den
%define     buffer   	    [ebp+20]		; points to beggining of output image
; define for local data labels on ebp 
%define     width       	[ebp-4]		    ; width of orginal image
%define     height      	[ebp-8]		    ; height of the original image
%define     bwidth    	    [ebp-12]		; widh of orginal in bits
%define     bnwidth 		[ebp-16]		; width of new image in bits
%define     scale   		[ebp-20]		; scale factor
%define     count       	[ebp-24]	    ; counter


; program works in a way that it checks whtether any
; additional pixel need to be drawn and draws them as 
; every n pixel f.e. scale 1.5 makes pixel every second one
; and line every second one as well


xpandbmp24:

    push    ebp                 			; prolog
    mov     ebp, 	esp
    sub     esp,	24

    push    ebx                 			; saving conntent of used registers
    push    esi
    push    edi
    
    mov     esi, 	image     			    ; putting address of image into esi register
	
    mov     eax, 	[esi+0x12]     		    ; from source file 12h = 18 dec width 4 bytes
    mov     width, 	eax				        ; saving the orginal wifth of bmp
    
    mov     edx, 	[esi+0x16]      		; same for orginal hight
    mov     height, 	edx
    
    mul     dword numerator     			; edx:eax   width * numerator
    div     dword denumenator     			; eax = edx:eax / denumenator
    imul    eax,	3
    add     eax, 	3
    and     eax, 	0x0fffffffc			    ; procedure to add potential offset
    mov     bnwidth, eax      			    ; new width of bmp in pixels with offset

    mov     eax, 	width
    imul    eax, 	3
    add     eax, 	3
    and     eax, 	0x0fffffffc
    sub     esp,	24

    push    ebx                 			; saving conntent of used registers
    sub     esp,	24

    push    ebx                 			; saving conntent of used registers
    mov     bwidth, 	eax       			; stores the width of orginal file it bytes + offset

    add     esi, 	54             		    ; moving pointer to beggining of pixel array
    
    mov     edi, 	buffer       			; get address of buffer for output file
    add     edi, 	54            		    ; moving pointer to beggining of pixel array
    
    xor     edx, 	edx            		    ; edx = 0
    mov     eax, 	numerator
    div     dword denumenator
    mov     scale, 	eax       			    ; stores of scale in eax to scale pixels, edx now contains the remainder which we will use
							                ; to calculate if extra pixel coming from remider part is needed
    mov     ebx,	 0           			; this will be increased by remider if its > denumenator it means its time to add pixel

initloop:
    push    esi                 			; saving the source adress of the begining of line in this iteration of loop
    push    ebx                 			; ebx will contain information about remider from previous iterations of hightloop which will be important
    push    edi                 			; saves adress of beggining of current destiation line

    mov     ecx, 	width         		    ; tmp to copy width to count
    mov     count, 	ecx         			; count will store inf about how many pixels we copied
    mov     ebx, 	0				        ; initzialize ebx in width loop to 0

widthloop:    
    mov     ecx,	 scale	   			    ; we want it to scale times bigger so we copy scale time pixels
    lodsd                      	    		; load 4 bytes from esi and put it into eax register increments esi by 4 
    dec     esi                		    	; pixels have only 3 bytes so we need to go back with esi not to lose colors

clonepixel:
    stosd                       			; store eax at the address in edi and increase it by 4
    dec     edi                	    		; pixels have only 3 bytes
    loop    clonepixel         	    		; ecx contains scale so pixels will be copied scale number of times
    
    add     ebx, 	edx          			; increment reminder counter
    cmp     ebx, 	denumenator   			; compares reminder with scale denominator
    jb      nextpixel	    		        ; if remider < denumenator we go to next
    
    sub     ebx, 	denumenator             ; remider >= denumenator we add another pixel and decrement the counter
    stosd                      		    	; copy a source pixel at the destination aditional time
    dec     edi

nextpixel:    
    dec     dword count
    jnz     widthloop                		; loop until end of source line

hightloop:    
    pop     edi                 			; now we will copy our new line from begginig so we pop back begin adress 
    pop     ebx                 			; restore ebx form previous hightloop
    
    mov     esi, 	edi          			; our previous destination becomes a source for clone line
    add     edi, 	bnwidth      			; we want to write to next line

    mov     eax, 	scale				    ; check for scale greater >= 2
    dec     eax          			        ; geting rid of this line we already did
    jz      cloneremainder

clonemore:                                  ; used when scale >= 2
    mov     ecx,	bnwidth      			; we want to copy all bytes in line
    shr     ecx, 	2            			; dwords are 4 byte so divide by 4
    rep     movsd             		    	; repeat ecx number of times movsd which copies 4 bytes from esi to edi and increments them by 4
    
    sub     esi, 	bnwidth      			; move backs esi to the begining of line so the next line can be copied wo worry about padding    
    dec     eax              
    jnz     clonemore         			    ; loop until scale-1 iterations are done

cloneremainder:    
    add     ebx, 	edx          		    ; check if a line should be copied one more time
    cmp     ebx, 	denumenator				
    jb      nextline				        ; edx < denumenator no need to copy 
    
    sub     ebx, 	denumenator			    ; edx >= copy one more line same procedure as above
    mov     ecx, 	bnwidth
    shr     ecx, 	2
    rep     movsd                   		; copy a line one more time

nextline:    
    pop     esi                			    ; restore the base address of the current source line
    add     esi,	 bwidth      			; advance to the next source line

    dec     dword height				    ; dec the hight counter
    jnz     initloop             			; loop until all source lines are processed
    
end:
    pop     edi                			    ; restore the required registers
    pop     esi
    pop     ebx

    mov     esp, 	ebp          			; restors the stack frame
    pop     ebp
    ret
