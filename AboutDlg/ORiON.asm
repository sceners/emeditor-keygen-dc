;include         winmm.inc
;includelib      winmm.lib

DlgAbout 	PROTO :DWORD,:DWORD,:DWORD,:DWORD

.const
IDD_ABOUT	equ	1000
IDB_EXIT	equ	1001

.data
String	db 'ADMIN@CRACK',0Ah
		db 'PRESENTTS',0Ah
		db 'Patch for',0Ah
		db 'EmEditor 1x.x',0Ah										
		db 0Ah
		db 'SNR PatchEngine - diablo2oo2',0Ah
		db 0Ah
		db 'Have a nice day :)',0Ah
		db 0Ah
		db 0Ah,0
		
aTahoma 	    db 'Tahoma',0
hFont		    dd 0
dword_40E510	dd 0
number	        dd 0 
dword_40CCA0	dd 0
dword_40CCA4	dd 0
dword_40CCB8	dd 0
dword_40CD24	dd 0
				dd 1F2h	dup(0)
dword_40DCC4	dd 0
				dd 1F3h	dup(0)
dword_40D4F0	dd 0
dword_40D4F4	dd 0
				dd 1F3h	dup(0)

.data?
handle	        dd	?
ScrollMainDC	HDC	?
ScrollBackDC	HDC	?
Tick	        dd	?
ScrollBitmap	HBITMAP	?

dword_40CD18	dd	?
Rect		    RECT <>
Paint	        PAINTSTRUCT	<>

dword_40E498	dd	?
TextLen	        dd	?
dword_40E508	dd	?
dword_40E50C	dd	?
GoDown	        db	?
dword_40E504	dd	?

.code

align dword	
DlgAbout proc hwin:DWORD,umsg:DWORD,wparam:DWORD,lparam:DWORD
	mov	eax,umsg
	push hwin
	pop handle
	.if	eax == WM_INITDIALOG
		call InitScroller
		
	.elseif eax==WM_LBUTTONUP
		invoke KillTimer,hwin,7Bh
		invoke KillTimer,hwin,141h
		invoke DeleteObject,ScrollMainDC
		invoke DeleteObject,ScrollBackDC
		invoke EndDialog,hwin,0
	.elseif eax==WM_TIMER
		call	SetupScroll
		call	DrawStars
		call	ScrollMain
		call	UpdateScroll
	.endif
	xor	eax,eax
	ret
DlgAbout endp

align dword
_rand proc
	mov eax,Tick
	imul eax,eax,0343FDh
	add eax,0269EC3h
	mov Tick,eax
	sar eax,010h
	and eax,07FFFh
	ret
_rand EndP

align dword
InitScroller Proc
	mov	edi, offset String
	or	ecx, 0FFFFFFFFh
	xor	eax, eax
	xor	edx, edx
	mov	esi, 1
	repne scasb
	not	ecx
	dec	ecx
	mov	TextLen, esi
	jz	short loc_401C7C

loc_401C58:
	cmp	byte ptr String[edx], 0Ah
	jnz	short loc_401C62
	inc	esi

loc_401C62:
	mov	edi, offset String
	or	ecx, 0FFFFFFFFh
	xor	eax, eax
	inc	edx
	repne scasb
	not	ecx
	dec	ecx
	cmp	edx, ecx
	jb	short loc_401C58
	mov	TextLen, esi

loc_401C7C:
	mov	dword_40E508, 0FFFFFFD8h
	mov	dword_40E50C, 0A0h
	mov	GoDown, 0
	mov	dword_40E504, 0
	
	call	FirstSetup
	xor	esi, esi

loc_401CA8:
	call	_rand
	cdq
	mov	ecx, 15Eh
	idiv	ecx
	mov	edi, edx
	call	_rand
	cdq
	mov	ecx, 0AFh
	idiv	ecx
	lea	edx, [edi+edx-15Eh]
	mov	dword_40CD24[esi*4], edx
	call	_rand
	cdq
	mov	ecx, 0A0h
	idiv	ecx
	mov	edi, edx
	call	_rand
	cdq
	mov	ecx, 50h
	idiv	ecx
	lea	eax, [esi+4Bh]
	mov	dword_40DCC4[esi*4], eax
	inc	esi
	cmp	esi, 1F4h
	lea	edx, [edi+edx-0A0h]
	mov	dword_40D4F0[esi*4], edx
	jl	short loc_401CA8
	
	invoke SetTimer,handle,123,5,0
	invoke SetTimer,handle,321,143000,0
	
	Ret
InitScroller EndP

align dword
FirstSetup	proc
	invoke GetDC,handle
	mov ScrollMainDC,eax
	invoke GetWindowRect,handle,addr Rect
	invoke CreateCompatibleDC,ScrollMainDC
	mov ScrollBackDC,eax		
	invoke CreateCompatibleBitmap,ScrollMainDC,Rect.left,Rect.top
	mov	ScrollBitmap, eax
	invoke SelectObject,ScrollBackDC,ScrollBitmap
	invoke DeleteObject,ScrollBitmap
	invoke DeleteObject,addr Rect
	ret
FirstSetup	endp

align dword
DrawStars	proc	
		push ebx
		mov	ebx, SetPixelV
		push	 esi
		push	 edi
		xor	edi, edi

loc_40141B:
		mov  eax, dword_40CD24[edi*4]
		mov	 esi, dword_40DCC4[edi*4]
		push 0		; COLORREF
		lea	 eax, [eax+eax*2]
		lea	 eax, [eax+eax*4]
		lea	 eax, [eax+eax*4]
		shl	 eax, 1
		cdq
		idiv esi
		mov	 ecx, eax
		mov	 eax, dword_40D4F4[edi*4]
		imul eax, 64h
		cdq
		idiv esi
		add	 ecx, 0AFh
		mov	 dword_40CCA0, ecx
		add	 eax, 50h
		mov	 dword_40CCA4, eax
		push eax ; int
		mov	 eax, ScrollBackDC
		push ecx ; int
		push eax ; HDC
		call ebx ; SetPixelV
		mov	 eax, dword_40DCC4[edi*4]
		lea	 ecx, [eax-1]
		mov	eax, dword_40CD24[edi*4]
		mov	dword_40DCC4[edi*4], ecx
		lea	eax, [eax+eax*2]
		lea	eax, [eax+eax*4]
		lea	eax, [eax+eax*4]
		shl	eax, 1
		cdq
		idiv	ecx
		mov	esi, eax
		mov	eax, dword_40D4F4[edi*4]
		imul	eax, 64h
		cdq
		idiv	ecx
		add	esi, 0FFh
		mov	dword_40CCA0, esi
		add	eax, 70h
		cmp	ecx, 0FFh
		mov	dword_40CCA4, eax
		jl	short loc_4014BE
		mov	edx, 32h
		jmp	short loc_4014C5

loc_4014BE:
		mov	edx, 131h
		sub	edx, ecx

loc_4014C5:
		mov	ecx, edx
		mov	dword_40CCB8, edx
		and	ecx, 0FFh
		mov	edx, ecx
		shl	edx, 8
		or	edx, ecx
		shl	edx, 8
		or	edx, ecx
		push	edx		; COLORREF
		push	eax		; int
		mov	eax, ScrollBackDC
		push	esi		; int
		push	eax		; HDC
		call	ebx ; SetPixelV
		cmp	dword_40DCC4[edi*4], 1
		jg	short loc_401552
		call	_rand
		cdq
		mov	ecx, 15Eh
		idiv	ecx
		mov	esi, edx
		call	_rand
		cdq
		mov	ecx, 0AFh
		idiv	ecx
		lea	edx, [esi+edx-15Eh]
		mov	dword_40CD24[edi*4], edx
		call	_rand
		cdq
		mov	ecx, 0A0h
		idiv	ecx
		mov	esi, edx
		call	_rand
		cdq
		mov	ecx, 0F0h
		idiv	ecx
		lea	eax, [edi+4Bh]
		mov	dword_40DCC4[edi*4], eax
		lea	edx, [esi+edx-0A0h]
		mov	dword_40D4F4[edi*4], edx

loc_401552:
		inc	edi
		cmp	edi, 1F4h
		jl	loc_40141B
		pop	edi
		pop	esi
		pop	ebx
		ret
DrawStars	endp

align dword
SetupScroll proc
	invoke GetWindowRect,handle,addr Rect
	invoke BeginPaint,handle,addr Paint
	invoke BitBlt,ScrollBackDC,0,0,Rect.right,Rect.bottom,0,0,0,BLACKNESS
	invoke EndPaint,handle,addr Paint
	invoke DeleteObject,addr Paint
	invoke DeleteObject,addr Rect
	ret
SetupScroll	endp

align dword
ScrollMain	proc
		mov	ecx, dword_40E510
		mov	edx, dword_40E508
		mov	eax, dword_40E50C
		add	ecx, edx
		mov	dl, GoDown
		mov	Rect.left, ecx
		mov	ecx, TextLen
		mov	Rect.top, eax
		test	dl, dl
		lea	ecx, [ecx+ecx*4+10h]
;******************************************************************************
;* ������ ���� ��� ����������� ������ �� ������� ����                         *
;******************************************************************************		
		mov	Rect.right, 140h
		lea	ecx, [eax+ecx*4]
		mov	Rect.bottom, ecx
		jnz	short loc_4012FC
		mov	edx, dword_40E504
		cmp	edx, 3
		jz	short loc_4012D4
		test	edx, edx
		jnz	short loc_4012E6

loc_4012D4:
		dec	eax
		mov	dword_40E504, 1
		mov	dword_40E50C, eax
		jmp	short loc_4012ED


loc_4012E6:
		inc	edx
		mov	dword_40E504, edx

loc_4012ED:
		neg	ecx
		cmp	eax, ecx
		jge	short loc_401332
		mov	GoDown, 1
		jmp	short loc_401332


loc_4012FC:
		mov	ecx, dword_40E504
		cmp	ecx, 3
		jz	short loc_40130B
		test	ecx, ecx
		jnz	short loc_40131D

loc_40130B:
		inc	eax
		mov	dword_40E504, 1
		mov	dword_40E50C, eax
		jmp	short loc_401324


loc_40131D:
		inc	ecx
		mov	dword_40E504, ecx

loc_401324:
		cmp	eax, 0D0h
		jle	short loc_401332
		mov	GoDown, 0

loc_401332:
		mov	edx, ScrollBackDC
		push	esi
		push	edi
		
		;nHeight = -MulDiv(PointSize, GetDeviceCaps(hDC, LOGPIXELSY), 72);
	
		push	48h		; nDenominator
		push	5Ah		; int
		push	edx		; HDC
		call	GetDeviceCaps
		
		invoke GetDeviceCaps,ScrollBackDC,LOGPIXELSY
		push	eax		; nNumerator
		push	8		; nNumber
		call	MulDiv
		
		push	offset aTahoma	; "Tahoma"
		push	0		; DWORD
		push	0		; DWORD
		push	0		; DWORD
		push	0		; DWORD
		push	0		; DWORD
		push	0		; DWORD
		push	0		; DWORD
		push	0		; DWORD
		push	2BCh	; int
		push	0		; int
		push	0		; int
		neg	    eax
		push	0		; int
		push    eax		; int
		mov	number,eax
		call CreateFontA
		mov	hFont,eax

;******************************************************************************
;* ����������� ����� ������ � ABOUT                                           *
;******************************************************************************
		
		invoke SelectObject,ScrollBackDC,hFont
		invoke SetTextColor,ScrollBackDC,00FFFF03h
		invoke SetBkColor,ScrollBackDC,00FF5353h
		invoke SetBkMode,ScrollBackDC,TRANSPARENT
		
		mov	edi, offset String
		or	ecx, 0FFFFFFFFh
		xor	eax, eax
		repne scasb
		not	ecx
		dec	ecx
		invoke DrawText,ScrollBackDC,addr String,ecx,addr Rect,DT_CENTER
		invoke DeleteObject,hFont
		invoke DeleteObject,addr Rect
		pop	edi
		pop	esi
		ret
ScrollMain	endp

align dword
UpdateScroll proc
	invoke GetDC,handle
	mov	ScrollMainDC, eax
	invoke GetWindowRect,handle,addr Rect
	invoke BeginPaint,handle,addr Paint
	invoke BitBlt,ScrollMainDC,0,0,Rect.right,Rect.bottom,ScrollBackDC,0,0,SRCCOPY
	invoke EndPaint,handle,addr Paint
	invoke DeleteObject,addr Paint
	invoke DeleteObject,addr Rect
	ret
UpdateScroll endp