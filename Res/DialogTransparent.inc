;invoke DialogTransparent,hwnd,D_T

DialogTransparent	PROTO :DWORD,:DWORD

.const

D_T	equ 200

.code

DialogTransparent proc _dialoghandle:dword,_value:dword
	
	pushad
	
	invoke GetModuleHandle,chr$("user32.dll")
	invoke GetProcAddress,eax,chr$("SetLayeredWindowAttributes")
	.if eax!=0
		;---yes, its win2k/xp system---
		mov edi,eax
		invoke GetWindowLong,_dialoghandle,GWL_EXSTYLE	;get EXSTYLE
		
		.if _value==255
			xor eax,WS_EX_LAYERED	;remove WS_EX_LAYERED
		.else
			or eax,WS_EX_LAYERED	;eax = oldstlye + new style(WS_EX_LAYERED)
		.endif
		
		invoke SetWindowLong,_dialoghandle,GWL_EXSTYLE,eax
		
		.if _value<255
			push LWA_ALPHA
			push _value						;set level of transparency
			push 0							;transparent color
			push _dialoghandle				;window handle
			call edi						;call SetLayeredWindowAttributes
		.endif	
	.endif
	
	popad
	ret
DialogTransparent endp