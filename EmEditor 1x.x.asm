.686			
.model flat, stdcall
option casemap :none

;******************************************************************************
;* INCLUDES                                                                   *
;******************************************************************************

include				windows.inc
include				user32.inc
include				kernel32.inc
include				shell32.inc
include				advapi32.inc
include				gdi32.inc
include				comctl32.inc
include				comdlg32.inc
include				masm32.inc
include				macros.asm
include             oleaut32.inc
include             ole32.inc

include				Res\DialogTransparent.inc
include	            HyperLink\HyperLink.inc
include				patchengine\SnR_PatchEngine.asm
include				patchengine\PatchFile.asm
include				patchengine\PatchFile1.asm
include             AboutDlg\ORiON.asm
include             Res\DrawItem.inc
include             TextScroller\TextScroller.inc
include             BmpFrom\BmpFrom.inc

includelib			user32.lib
includelib			kernel32_n.lib
includelib			shell32.lib
includelib			advapi32.lib
includelib			gdi32.lib
includelib			comctl32.lib
includelib			comdlg32.lib
includelib			masm32.lib
includelib          oleaut32.lib
includelib          ole32.lib

;******************************************************************************
;* Для bassmod                                                                *
;******************************************************************************

include             BASSMOD\bassmod.inc

;******************************************************************************
;* PROTOTYPES                                                                 *
;******************************************************************************

DialogProc 	   PROTO :DWORD,:DWORD,:DWORD,:DWORD
DrawItem       PROTO :HWND,:LPARAM
Initial		   PROTO

;******************************************************************************
;* DATA & CONSTANTS                                                           *
;******************************************************************************

.const

MAXSIZE             equ 1024
BTN_PATCH			equ 102
BTN_ABOUT			equ 105
BTN_OPEN			equ 106
BTN_CLOSE			equ 107
IDC_BAK     		equ 108
DATE                equ 110
BAK                 equ 112
BMPS   			    equ 800
PS   			    equ 700
STOP   			    equ 111
STP   			    equ 109

CR_BACKGROUND       equ 00009700h
CR_FOREGROUND       equ 00000000h
CR_HIGHLIGHT        equ 0003FF03h
CR_INPUT            equ 00009700h
CR_INPUT2           equ 0003FF03h
CR_TEXT             equ 00009700h
CR_BUTTON           equ 00FFFFFFh
GfxCharWidth        equ 16

.data

; Logo stuff
LogoWidth           dd 260
LogoHeight          dd 30
dwX                 dd 0
dwY                 dd 0
logofrequency   	real4 5.0
logoamplitude	    real4 1.0
logoamplitude2	    real4 0.0
rectLogo            RECT <0,37,260,37>

; Scroller stuff
ScrollYPos        dd 60         ; Scroller's Y position on the dialog
ScrollSpeed       dd 1          ; Timeout (in milliseconds) for scroller update
frequency	      real4 25.0
amplitude	      real4 5.0
rectScroll        RECT <-(GfxCharWidth + 1),0,278,50>
ScrollLenPixels   dd 0
chrmap            db "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789""'(),.;:+-!?*",0
szScrollText      db "COPY A PATCH IN A FOLDER WITH THE PROGRAM, START IT AND PRESS THE BUTTON 'PATCH'!",0
   
include	            BASSMOD\Music.inc
include	            BmpFrom\LOGO.inc
include	            BmpFrom\BmpScroller.inc
file		    	db 'EmEditor.exe',0
Caption1			db ';)',0
Caption2			db 'Warning',0
Caption3			db 'Error',0
filebak             db '.bak',0
OpenTitle           db 'Select the target file',0
FiltString          db 'EmEditor.exe',0,'EmEditor.exe',0,'All Exe Files *.*',0,'*.exe',0,0
of_About    		db 'About',0
of_Open    			db 'Open',0
of_Patch    		db 'Patch',0
of_Bmps      		db 'Pause',0
of_Close   			db 'Close',0
of_Date   			db 'May 20, 2011',0
of_Bak     			db 'Backup',0
of_Stop     		db 'Stop',0

.data?

hHandCursor   HCURSOR ?

; Logo stuff
hLogoBmp      dd ?
hDCLogo       dd ?
hOldLogo      dd ?  
hBuf          dd ?
hDCBuf        dd ?
hOldBuf       dd ?
hBuf2         dd ?
hDCBuf2       dd ?
hOldBuf2      dd ?
hDC           dd ?

; Scroller stuff
hDCScroll     dd ?
hBmp          dd ?
hOld          dd ?
hOldGfxBmp    dd ?
dwScrollX     dd ?
hDCGfxScroll  dd ?
hGfxScrollBmp dd ?

hInstance     dd ?
hParentWnd    dd ?
scr			  SCROLLER_STRUCT <>
lf			  LOGFONT <>
OPENFILE      OPENFILENAME <>
rect          RECT <>

; Brushes & pens
hBgColor     HBRUSH ?
hFgColor     HBRUSH ?
hInColor     HBRUSH ?
hIn2Color    HBRUSH ?
hEdge        HPEN   ?

; Font & text
BoldFont     LOGFONT            <?>
sBtnText     TCHAR        16 dup(?)
BackupFile   TCHAR  MAX_PATH dup(?)
FileName     TCHAR  MAX_PATH dup(?)

;******************************************************************************
;* Основной код                                                               *
;******************************************************************************

.code

main:

   mov hInstance,FUNC (GetModuleHandle,0)
    invoke HL 
    invoke GetModuleHandle,0
    invoke InitCommonControls     
    invoke DialogBoxParam,eax,1,0,addr DialogProc,0
    invoke DeleteObject, hEdge
    invoke DeleteObject, hInColor
    invoke DeleteObject, hIn2Color
    invoke DeleteObject, hFgColor
    invoke DeleteObject, hBgColor
    invoke ExitProcess,0


HyperLinkCursor proc hwnd:DWORD,message:DWORD,wparam:DWORD,lparam:DWORD

  .if message==WM_SETCURSOR
    invoke SetCursor,hHandCursor
  .else
    invoke GetWindowLong,hwnd,GWL_USERDATA
    invoke CallWindowProc,eax,hwnd,message,wparam,lparam
  ret
    .endif

  xor eax,eax
  ret
 
HyperLinkCursor endp

DialogProc proc uses ebx esi edi hwnd:dword,message:dword,wparam:dword,lparam:dword
local off_set:DWORD
local pFileMem:DWORD

  .if message == WM_CTLCOLORDLG
  mov eax, hBgColor
  ret
  
  .elseif message == WM_CTLCOLORSTATIC
    invoke GetDlgCtrlID, lparam
    invoke SendMessage, hwnd, WM_GETFONT, 0, 0
    invoke GetObject, eax, SIZEOF LOGFONT, ADDR BoldFont
  mov BoldFont.lfWeight, FW_BOLD
  mov BoldFont.lfItalic, TRUE
    invoke CreateFontIndirect, ADDR BoldFont
    invoke SelectObject, wparam, eax
    invoke SetBkMode, wparam, TRANSPARENT
    invoke SetTextColor, wparam, CR_HIGHLIGHT
  mov eax, hFgColor
  ret 
  
  .elseif message == WM_CTLCOLOREDIT
    invoke SetBkMode, wparam, TRANSPARENT
    invoke SetTextColor, wparam, CR_TEXT
  mov eax, hInColor
  ret    
  
  .elseif message == WM_DRAWITEM
    invoke DrawItem, hwnd, lparam

  .elseif message == WM_TIMER
  mov eax,dwScrollX
  add eax,ScrollLenPixels
  dec dwScrollX
  cmp eax,0
  jge @@skip

  mov eax,rectScroll.right
  mov dwScrollX,eax
  
    @@skip:
    invoke GetStockObject,BLACK_BRUSH
	invoke FillRect,hDCScroll,ADDR rectScroll,eax

  push edi
  mov esi,OFFSET rectScroll
  mov edi,OFFSET rect
  mov ecx,sizeof rect shr 2
  rep movsd
  mov esi,OFFSET szScrollText
  mov eax,dwScrollX
  mov rect.left,eax

  @@more:
  mov eax,rectScroll.left
  mov ecx,rectScroll.right
  .if SDWORD PTR rect.left >= eax && SDWORD PTR rect.left <= ecx
  mov al,byte ptr [esi]
  mov ebx,OFFSET chrmap
  xor ecx,ecx
  .while byte ptr [ebx] != al
  inc ecx
  inc ebx
  .endw
  imul ecx,GfxCharWidth
  mov off_set,ecx
  mov pFileMem,0
  xor ecx,ecx

  .while ecx < GfxCharWidth
  fild rect.left
  fild dwScrollX
  fadd
  fdiv frequency
  fsin
  fmul amplitude
  fild rectScroll.top
  fadd
  fistp rect.top
  add rect.top,10 ; magic Y value for this font - should be tidied...
  	invoke BitBlt,hDCScroll,rect.left,rect.top,1,rectScroll.bottom,hDCGfxScroll,off_set,0,SRCPAINT
  inc rect.left
  inc off_set
  inc pFileMem
  mov ecx,pFileMem
  .endw
  .else
  add rect.left,GfxCharWidth
  .endif
  inc esi
  cmp byte ptr [esi],0
  jne @@more
    
  pop edi
  pop esi

	invoke BitBlt,hDC,5,ScrollYPos,rect.right,rectScroll.bottom,hDCScroll,0,0,SRCCOPY

  	invoke FillRect,hDCBuf,ADDR rectLogo,0
  	invoke FillRect,hDCBuf2,ADDR rectLogo,0
  inc dwX
  mov eax,logofrequency
  .if dwX == eax
  mov dwX,0
  .endif
		    
  xor ecx,ecx
  mov off_set,0
  
  .while ecx < 260
  fild dwX
  fild off_set
  fadd
  fdiv logofrequency
  fsin
    invoke IsDlgButtonChecked,hwnd,STP

  .if eax==BST_CHECKED
  fmul logoamplitude2
  .else
  fmul logoamplitude
  .endif
   
  fistp dwY
  add dwY,3
	invoke BitBlt,hDCBuf,off_set,dwY,1,LogoHeight,hDCLogo,off_set,0,SRCCOPY
  inc off_set
  mov ecx,off_set
  .endw

  xor ecx,ecx
  mov off_set,0
  
  .while ecx < 37
  fild dwX
  fild off_set
  fadd
  fdiv logofrequency
  fsin
  
;******************************************************************************
;* Проверка чебокса, пауза музыки и изменение движения логотипа.              *
;******************************************************************************
  
    invoke IsDlgButtonChecked,hwnd,PS

  .if eax==BST_CHECKED
  fmul logoamplitude2
    invoke BASSMOD_MusicPause
  .else
   
  invoke IsDlgButtonChecked,hwnd,STP
  
  .if eax==BST_CHECKED
  fmul logoamplitude2
    invoke BASSMOD_MusicStop
    invoke BASSMOD_MusicSetPosition,0
  .else
   
  fmul logoamplitude
    invoke BASSMOD_MusicPlay
  .endif
  .endif
   
  fistp dwY
  add dwY,5
	invoke BitBlt,hDCBuf2,dwY,off_set,LogoWidth,1,hDCBuf,0,off_set,SRCCOPY
  inc off_set
  mov ecx,off_set
  .endw
   
	invoke BitBlt,hDC,12,27,rectLogo.right,rectLogo.bottom,hDCBuf2,0,0,SRCCOPY

  .elseif message == WM_COMMAND
  mov eax,wparam
  mov edx,wparam
  shr edx,16
  .endif

  mov eax,message

  .if eax==WM_INITDIALOG

    invoke OpenMutex,0,0,0
  .if eax == 0
  mov eax,hwnd
  mov hParentWnd,eax                                        ; Store the main window handle for global use
    invoke BmpFromMemory,addr Logo,addr Logo_Length         ; Load logo bitmap into memory
; invoke BmpFromResource,hInstance,50                       ; Load logo bitmap into resurse
  mov hLogoBmp,eax
  
    invoke BmpFromMemory,addr Scroller,addr Scroller_Length ; Load scroll text bitmap into memory
  mov hGfxScrollBmp,eax                                     ; Save it's handle

; Setup up our text scroller
    invoke SetTimer,hwnd,1,ScrollSpeed,0
    invoke GetDC,hwnd
  mov hDC,eax
    invoke CreateCompatibleDC,eax
  mov hDCScroll,eax
    invoke lstrlen,ADDR szScrollText
  imul eax,GfxCharWidth
  mov ScrollLenPixels,eax
  mov eax,rectScroll.right
  mov dwScrollX,eax
    invoke CreateCompatibleBitmap,hDC,rectScroll.right,rectScroll.bottom
  mov hBmp,eax
    invoke SelectObject,hDCScroll,eax
  mov hOld,eax
    invoke CreateCompatibleDC,hDC
  mov hDCGfxScroll,eax
    invoke SelectObject,hDCGfxScroll,hGfxScrollBmp
  mov hOldGfxBmp,eax

    invoke GetDC,hwnd
  mov hDC,eax
    invoke CreateCompatibleDC,hDC
  mov hDCBuf,eax
    invoke CreateCompatibleBitmap,hDC,260,37
  mov hBuf,eax
    invoke SelectObject,hDCBuf,eax
  mov hOldBuf,eax
    invoke CreateCompatibleDC,hDC
  mov hDCBuf2,eax
    invoke CreateCompatibleBitmap,hDC,260,37
  mov hBuf2,eax
    invoke SelectObject,hDCBuf2,eax
  mov hOldBuf2,eax
    invoke CreateCompatibleDC,hDC
  mov hDCLogo,eax
    invoke SelectObject,hDCLogo,hLogoBmp
  mov hOldLogo,eax
  .endif

	invoke DialogTransparent,hwnd,D_T

;******************************************************************************
;* Параметры бегущей строки                                                   *
;******************************************************************************

  m2m scr.scroll_hwnd,hwnd
  mov scr.scroll_text,chr$("Patch for EmEditor 1x.x")
  mov scr.scroll_x,10
  mov scr.scroll_y,4
  mov scr.scroll_width,265
	invoke lstrcpy,addr lf.lfFaceName,chr$("Tahoma")	
  mov lf.lfHeight,16
  mov lf.lfCharSet,DEFAULT_CHARSET
  mov lf.lfItalic,FALSE
  mov lf.lfWeight,FW_BOLD	
  mov lf.lfQuality,ANTIALIASED_QUALITY
	invoke CreateFontIndirect,addr lf
  mov scr.scroll_hFont,eax
  mov scr.scroll_alpha,D_T
  mov scr.scroll_textcolor,00FFFF03h
	invoke CreateScroller,addr scr

;******************************************************************************
;* Загружаем музыку                                                           *
;******************************************************************************

    invoke BASSMOD_DllMain,hInstance,DLL_PROCESS_ATTACH,0
    invoke BASSMOD_Init,-1,44100,0
    invoke BASSMOD_MusicLoad,TRUE,addr Music,0,0,\
    BASS_MUSIC_SURROUND2+BASS_MUSIC_LOOP+BASS_MUSIC_POSRESET+BASS_MUSIC_RAMPS
    invoke BASSMOD_SetVolume,100
  call BASSMOD_MusicPlay
  
;******************************************************************************
;* Загружаем Курсоры для кнопок                                               *
;******************************************************************************

    invoke LoadCursor,0,IDC_HAND
    mov hHandCursor,eax        

    invoke GetDlgItem,hwnd,BTN_CLOSE
  push eax
    invoke SetWindowLong,eax,GWL_WNDPROC,addr HyperLinkCursor
  pop edx
    invoke SetWindowLong,edx,GWL_USERDATA,eax

    invoke GetDlgItem,hwnd,BTN_OPEN
  push eax
    invoke SetWindowLong,eax,GWL_WNDPROC,addr HyperLinkCursor
  pop edx
    invoke SetWindowLong,edx,GWL_USERDATA,eax

    invoke GetDlgItem,hwnd,BTN_ABOUT
  push eax
    invoke SetWindowLong,eax,GWL_WNDPROC,addr HyperLinkCursor
  pop edx
    invoke SetWindowLong,edx,GWL_USERDATA,eax

    invoke GetDlgItem,hwnd,BTN_PATCH
  push eax
    invoke SetWindowLong,eax,GWL_WNDPROC,addr HyperLinkCursor
  pop edx
    invoke SetWindowLong,edx,GWL_USERDATA,eax

    invoke CreateSolidBrush, CR_BACKGROUND
  mov hBgColor, eax
    invoke CreateSolidBrush, CR_FOREGROUND
  mov hFgColor, eax
    invoke CreateSolidBrush, CR_INPUT
  mov hInColor, eax
    invoke CreateSolidBrush, CR_INPUT2
  mov hIn2Color, eax
    invoke CreatePen, PS_INSIDEFRAME, 1, CR_FOREGROUND
  mov hEdge, eax

;******************************************************************************
;* Уствнавливаем текст на объекты (кнопки и т.п)+включаем чебокс на backup-e  *
;******************************************************************************

    invoke CheckDlgButton,hwnd,IDC_BAK,BST_CHECKED
    invoke SetDlgItemText,hwnd,BTN_ABOUT,addr of_About
    invoke SetDlgItemText,hwnd,BTN_CLOSE,addr of_Close
    invoke SetDlgItemText,hwnd,BTN_PATCH,addr of_Patch
    invoke SetDlgItemText,hwnd,BTN_OPEN,addr of_Open
    invoke SetDlgItemText,hwnd,BMPS,addr of_Bmps
    invoke SetDlgItemText,hwnd,STOP,addr of_Stop
    invoke SetDlgItemText,hwnd,DATE,addr of_Date 
    invoke SetDlgItemText,hwnd,BAK,addr of_Bak

  Switch message
  Case WM_INITDIALOG
  mov link,FUNC (GetDlgItem,hwnd,IDC_HLK)
	invoke SendMessage,link,HL_ACTIVEMOUSE,DELAY,0
	invoke SendMessage,link,HL_CURSOR,FUNC (LoadCursor,hInstance,200),0

;******************************************************************************
;* Ниже замена цвеца на ссылке. Фон, и наведение мыши. Данные в .data         *
;******************************************************************************

	invoke SendMessage,link,HL_BKCOLOR,COLORBKG,0
	invoke SendMessage,link,HL_COLORTEXT,COLOR,COLOR1

  Case WM_COMMAND		
  Switch wparam
  endsw	
  return 0 
  
  .elseif eax==WM_COMMAND
  mov eax,wparam
 
  .if eax==BTN_PATCH

	invoke exist,addr file
  .if eax==0	
 
;******************************************************************************
;* Открываем Файл                                                             *
;******************************************************************************

  mov OPENFILE.lStructSize,SIZEOF OPENFILE 
  mov eax,hwnd 
  mov OPENFILE.hwndOwner,eax
  mov OPENFILE.lpstrFilter,OFFSET FiltString
  mov OPENFILE.lpstrFile,OFFSET FileName
  mov OPENFILE.nMaxFile,SIZEOF FileName
  mov OPENFILE.Flags,OFN_FILEMUSTEXIST+\
   OFN_NONETWORKBUTTON+OFN_PATHMUSTEXIST+\
   OFN_LONGNAMES+OFN_EXPLORER+OFN_HIDEREADONLY
  mov OPENFILE.lpstrTitle,OFFSET OpenTitle
    invoke GetOpenFileName,OFFSET OPENFILE

  .if eax==1
	jmp F_Backup
  .elseif eax==0
    jmp @end
  .endif

  .else

  F_Backup:
	invoke exist,addr filebak

  .if eax==0
	invoke IsDlgButtonChecked,hwnd,IDC_BAK

  .if eax==BST_CHECKED
  	invoke exist,addr file

  .if eax==1
  	invoke SetFileAttributes,addr file,FILE_ATTRIBUTE_NORMAL
    invoke lstrcpy,addr BackupFile,addr file
    invoke lstrcat,addr BackupFile,addr filebak
    invoke CopyFile,addr file,addr BackupFile,1
  .else
    invoke SetFileAttributes,addr FileName,FILE_ATTRIBUTE_NORMAL  
    invoke lstrcpy,addr BackupFile,addr FileName
    invoke lstrcat,addr BackupFile,addr filebak
    invoke CopyFile,addr FileName,addr BackupFile,1
  .endif
  .endif
  .endif
  
;******************************************************************************
;* Прыгаем в PatchFile.asm                                                    *
;******************************************************************************

    invoke exist,addr file
  .if eax==1
  	invoke PatchFile,addr file
  .else
    invoke PatchFile,OFFSET FileName
  .endif

  .if eax==1
  	jmp @Susses
  .elseif eax==0
    invoke exist,addr file
  .if eax==1
  	invoke PatchFile1,addr file
  .else
    invoke PatchFile1,OFFSET FileName
  .endif
  .endif
  .endif

;******************************************************************************
;* Проверяем патченые байты и выводим соответствующие сообщения               *
;******************************************************************************

  .if eax==1
    jmp @Susses
  .elseif eax==0
    jmp @Failed

   @Susses:
	invoke MessageBox,hwnd,chr$("Patch successfull!"),\
	addr Caption1,MB_ICONQUESTION+MB_TOPMOST
    jmp @end
   @Failed:
	invoke MessageBox,hwnd,chr$("Patch failed!"),addr Caption3,MB_ICONERROR+MB_TOPMOST
   @end:
  .endif
  .endif
  .endif


;******************************************************************************
;* Закрываем патч                                                             *
;******************************************************************************

  .if eax==BTN_CLOSE
  	invoke BASSMOD_Free
	invoke BASSMOD_DllMain,hInstance,DLL_PROCESS_DETACH,0
	invoke EndDialog,hwnd,0

;******************************************************************************
;* Открываем ABOUT                                                            *
;******************************************************************************

  .elseif eax==BTN_ABOUT
    invoke DialogBoxParam,hInstance,IDD_ABOUT,hwnd,addr DlgAbout,0		

;******************************************************************************
;* А тут перетаскиваем диалог мышью в любом месте                             *
;******************************************************************************

  .elseif message==WM_LBUTTONDOWN
    invoke SendMessage,hwnd,WM_NCLBUTTONDOWN,HTCAPTION,0
  .endif

 xor eax,eax
 ret

DialogProc endp

end main