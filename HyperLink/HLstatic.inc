HL				    PROTO
;Messages
HL_CURSOR			equ 	WM_USER+1 	; wParam == cursor icon
HL_BKCOLOR			equ 	WM_USER+2	; wParam == Background color
HL_COLORTEXT		equ	    WM_USER+3	; wParam == color no active, lParam == color active
HL_ACTIVEMOUSE		equ	    WM_USER+4	; wParam == delay noactive/active in milliseconds
;HL_UNACTIVEMOUSE	equ	    WM_USER+5	; wParam == 0, lParam == 0
;HL_FONT			equ 	WM_USER+6	; wParam == hFont