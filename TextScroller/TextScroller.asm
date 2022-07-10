;******************************************************************************
;* diablo2oo2's Textscroller Engine                                           *
;******************************************************************************

;---private functions of scroller engine---
ScrollThread		PROTO :DWORD
BlendBitmap			PROTO :DWORD,:DWORD,:DWORD,:DWORD
BlendPixel			PROTO :DWORD,:DWORD,:DWORD
PercentValue		PROTO :DWORD,:DWORD
PercentColor		PROTO :DWORD,:DWORD
GetDIBPixel			PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SetDIBPixel			PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD


;******************************************************************************
;* CODE                                                                       *
;******************************************************************************

.code
;---public---
CreateScroller proc _scrollstruct:dword
	
	LOCAL ThreadID		:DWORD
	
	fn CreateThread,0,0,addr ScrollThread,_scrollstruct,0,addr ThreadID
	fn CloseHandle,eax
	
	ret
CreateScroller endp

PauseScroller proc _scrollstruct:dword
	
	mov eax,_scrollstruct
	assume eax:ptr SCROLLER_STRUCT
	
	mov cl,[eax].scroll_pause
	
	.if cl==0
		inc cl
	.else
		dec cl
	.endif		
	
	mov [eax].scroll_pause,cl
		
	assume eax:nothing
	
	ret
PauseScroller endp


;---private---
ScrollThread proc _scrollstruct:dword
	
	LOCAL local_hdc_window		    :DWORD
	LOCAL local_hdc_window_copy	    :DWORD
	LOCAL local_hdc_text		    :DWORD
	LOCAL local_scroll_height	    :DWORD
	LOCAL local_text_len		    :DWORD
	LOCAL local_text_width		    :DWORD
	LOCAL local_text_endpos	     	:DWORD
	LOCAL local_pbmi		        :BITMAPINFO
	LOCAL local_pixels_window_copy	:DWORD
	LOCAL local_pixels_text		    :DWORD
	LOCAL local_sz 			        :SIZEL
	
	
	;---scroller structure---
	mov esi,_scrollstruct
	assume esi:ptr SCROLLER_STRUCT
	
	
	;---wait before draw---
	mov eax,[esi].scroll_wait
	.if eax<500
		mov eax,500
	.endif	
	fn Sleep,eax		;important!
	
	
	;---Textlen---
	fn lstrlen,[esi].scroll_text
	mov local_text_len,eax
	
	
	
	;---get window dc---
	fn GetDC,[esi].scroll_hwnd
	mov local_hdc_window,eax
	
	
	
	;---HDC for text---
	fn GetDC,0
	fn CreateCompatibleDC,eax
	mov local_hdc_text,eax
	
	;---use custom font---
	fn SelectObject,eax,[esi].scroll_hFont
	
	;---get Textheight and width---
	fn GetTextExtentPoint,local_hdc_text,[esi].scroll_text,local_text_len,addr local_sz
	.if eax==TRUE 
	
		m2m local_scroll_height,local_sz.y
		m2m local_text_width,local_sz.x
		
		
		;---..hdc for text---
		fn CreateCompatibleBitmap,local_hdc_window,[esi].scroll_width,local_scroll_height
		fn SelectObject,local_hdc_text,eax
		
		
		lea edi,local_pbmi
		assume edi:ptr BITMAPINFO
		
		fn RtlZeroMemory,edi,sizeof BITMAPINFO
		
		mov [edi].bmiHeader.biSize , sizeof BITMAPINFOHEADER
		m2m [edi].bmiHeader.biWidth , [esi].scroll_width
		m2m [edi].bmiHeader.biHeight , local_scroll_height
		mov [edi].bmiHeader.biPlanes , 1
		mov [edi].bmiHeader.biBitCount , 32	 
		mov [edi].bmiHeader.biCompression , BI_RGB
		
		
		fn CreateDIBSection,local_hdc_text,edi,DIB_RGB_COLORS,addr local_pixels_text,0,0
		fn SelectObject,local_hdc_text,eax
		assume edi:nothing
		
		
		;---HDC for windowcopy---
		fn GetDC,0
		fn CreateCompatibleDC,eax
		mov local_hdc_window_copy,eax
		
		
		
		;---window dib & window copy---
		lea edi,local_pbmi
		
		fn CreateDIBSection,local_hdc_window_copy,edi,DIB_RGB_COLORS,addr local_pixels_window_copy,0,0
		fn SelectObject,local_hdc_window_copy,eax
		
		fn BitBlt,local_hdc_window_copy,0,0,[esi].scroll_width,local_scroll_height,local_hdc_window,[esi].scroll_x,[esi].scroll_y,SRCCOPY
		
		
		;---Set Text Color---
		fn SetBkMode,local_hdc_text,TRANSPARENT
		fn SetTextColor,local_hdc_text,[esi].scroll_textcolor
		
		
		;---for transparent windows---
		fn GetModuleHandle,"user32.dll"
		fn GetProcAddress,eax,"SetLayeredWindowAttributes"
		mov edi,eax
		
		;---calc endposition of text---
		xor eax,eax
		sub eax,local_text_width
		sub eax,8
		mov local_text_endpos,eax
		
		
		;---prepare loop---
		mov ebx,[esi].scroll_width	;ebx=text position
		add ebx,4
		
		
		;---loop---
		@loop:
		
			.if [esi].scroll_pause==0
				
				;---draw background for scroll gfx---
				fn BitBlt,local_hdc_text,0,0,[esi].scroll_width,local_scroll_height,local_hdc_window_copy,0,0,SRCCOPY
				
				;---draw scrolltext on background---
				fn TextOut,local_hdc_text,ebx,0,[esi].scroll_text,local_text_len
				
				;---fade text in and out---
				fn BlendBitmap,local_pixels_text,local_pixels_window_copy,local_scroll_height,[esi].scroll_width
				
				;---draw scrolltext on window---
				fn BitBlt,local_hdc_window,[esi].scroll_x,[esi].scroll_y,[esi].scroll_width,local_scroll_height,local_hdc_text,0,0,SRCCOPY			
		
				dec ebx
			
				.if ebx==local_text_endpos
					;---reset text position to begining---
					mov ebx,[esi].scroll_width
				.endif
				
				
				;---important for transparent window---
				.if edi!=0
					movzx eax,[esi].scroll_alpha
					.if al!=0 && al!=255
						Scall edi,[esi].scroll_hwnd,0,eax,LWA_ALPHA
					.endif
				.endif
			.endif
			
			fn Sleep,30
		
		jmp @loop
		
	.endif
	
	assume esi:nothing
	
	ret
ScrollThread endp


;---Blend Routine---
align 16
BlendBitmap proc uses esi edi ebx _text_dib, _window_copy_dib, _height, _width
	
	LOCAL local_blendvalue	:DWORD
	LOCAL local_fadeout_pos	:DWORD
	
	.const
	FADE_WIDTH	equ 25
	FADE_STEP	equ 4
	
	.code
	mov eax,_width
	
	.if eax>=2*FADE_WIDTH	;only works with minimum width
		
		
		;---calc x-coordinate where to start fade out---
		sub eax,FADE_WIDTH
		mov local_fadeout_pos,eax
		
		
		;---prepare loop--
		xor esi,esi		;x=width
		mov local_blendvalue,0
		
		
		;---blend loop---
		.while esi!=_width
			
			xor edi,edi	;y=height
			
			.while edi!=_height
				
				;---get pixel of scrolltext hdc---
				fn GetDIBPixel,esi,edi,_text_dib,_width,_height
				mov ebx,eax
					
				fn GetDIBPixel,esi,edi,_window_copy_dib,_width,_height
					
				fn BlendPixel,eax,ebx,local_blendvalue
					
				fn SetDIBPixel,esi,edi,_text_dib,_width,_height,eax

				inc edi
			.endw
			
			
			;---for fading---
			.if 	esi<FADE_WIDTH
				add local_blendvalue,FADE_STEP	;4 * 25pixel = 100 %
				
			.elseif esi==FADE_WIDTH
				;---skip non fading area and jump zo fadeout area---
				mov esi,local_fadeout_pos
					
			.elseif esi>local_fadeout_pos
				sub local_blendvalue,FADE_STEP	;4 * 25pixel = 100 %
				
			.endif	
	
			inc esi	
		.endw
	.endif	
	
	ret
BlendBitmap endp



align 16
GetDIBPixel proc _x,_y,_pDIBits,_width,_height

	mov eax,_width
	mov ecx,_height

	sub ecx,_y
	dec ecx
	mul ecx
	shl eax,2 ; adjust for DWORD size
	push eax ; push the result onto the stack

	mov eax,_x
	shl eax,2 ; adjust for DWORD size
	pop ecx ; pop the scan line offset off the stack
	add eax,ecx

	add eax,_pDIBits ; add the offset to the DIB bit
	mov eax,[eax]

	RET
GetDIBPixel endp


align 16
SetDIBPixel proc _x,_y,_pDIBits,_width,_height,_color

	mov eax,_width
	mov ecx,_height

	cmp _x,eax
	jae @exit
	
	cmp _y,ecx
	jae @exit

	sub ecx,_y
	dec ecx
	mul ecx
	shl eax,2 ; adjust for DWORD size
	mov edx,eax

	mov eax,_x
	shl eax,2 ; adjust for DWORD size
	add eax,edx

	add eax,_pDIBits ; add the offset to the DIB bit
	mov ecx,_color
	mov [eax],ecx

	@exit:
	RET
SetDIBPixel endp


align 16
BlendPixel proc uses esi edi ebx _sourcepixel:dword,_overpixel:dword,_transparency:dword
	
	;---parameters---
	;_sourcepixel  : Pixel of Backgroundimage
	;_overpixel    : Pixel which overlaps the sourcepixel
	;_transparency : 5 - 90 %  (using 100 % is stupid)
	
	;---Color Format---
	; 00 00 00 00
	; xx BB GG RR
	
	.if _transparency<100
		
		mov eax,_overpixel
		.if eax!=_sourcepixel
			
			;---calc new colors of _sourcepixel---
			mov eax,100
			sub eax,_transparency
			
			fn PercentColor,_sourcepixel,eax
			mov ebx,eax
			
			
			;---calc new colors of _overpixel---	
			fn PercentColor,_overpixel,_transparency
			
			
			;---add each color---
			xor esi,esi
			
			.while esi!=3
				
				movzx edx,al
				movzx ecx,bl
				
				add edx,ecx
				.if edx>255
					mov dl,255
				.endif
				
				mov al,dl
					
				ror eax,8
				ror ebx,8
				
				inc esi
			.endw
			
			rol eax,3*8
		.else	
			mov eax,_overpixel
		.endif	
	.else	
		mov eax,_overpixel
	
	.endif
	
	ret
BlendPixel endp


align 16
PercentValue proc _value:dword,_percent:dword

	mov eax,_value
	mul _percent
	mov ecx,100
	xor edx,edx
	div ecx
	ret

PercentValue endp


align 16
PercentColor proc uses esi edi ebx _color:dword,_percent:dword
	
	;---reduce color by certain percent---
	
	mov ebx,_color
	
	;---Red--
	movzx eax,bl
	
	fn PercentValue,eax,_percent
	mov edi,eax
	
	
	;---Green---
	ror ebx,8
	movzx eax,bl
	fn PercentValue,eax,_percent
	
	ror edi,8 
	mov edx,edi
	mov dl,al
	mov edi,edx
	
	
	;---Blue---
	ror ebx,8
	movzx eax,bl
	fn PercentValue,eax,_percent
	
	ror edi,8 
	mov edx,edi
	mov dl,al
	mov edi,edx
	
	
	;---return new color value---
	rol edi,16
	mov eax,edi
	
	ret
PercentColor endp