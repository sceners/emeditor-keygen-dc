PatchFile			PROTO :DWORD

.const

PATTERNSIZE			equ sizeof SearchPattern

.data

;******************************************************************************
;* Данные для поиска и замены                                                 *
;******************************************************************************

; WinRar.exe

SearchPattern			db 055h,08Bh,0ECh,081h,0ECh,000h,000h,000h,000h,057h,08Bh,045h,000h,089h,045h
SearchMask			db    0,   0,   0,   0,	  0,   1,   1,   1,   1,   0,   0,	 0,   1,   0,   0,   ;(1=Ignore Byte)

ReplacePattern			db 0C3h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
ReplaceMask			db    0,   1,   1,   1,	  1,   1,   1,   1,   1,   1,   1,	 1,   1,   1,   1,	 ;(1=Ignore Byte)

.code

PatchFile proc _targetfile   :DWORD

	LOCAL local_hFile	     :DWORD
	LOCAL local_hFileMapping :DWORD
	LOCAL local_hViewOfFile  :DWORD
	LOCAL local_retvalue	 :DWORD
	LOCAL local_filesize	 :DWORD

	pushad
	mov local_retvalue,0

	invoke CreateFile,_targetfile,GENERIC_READ+GENERIC_WRITE,FILE_SHARE_WRITE,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL+FILE_ATTRIBUTE_HIDDEN,0
	.if eax!=INVALID_HANDLE_VALUE

		mov local_hFile,eax
		invoke CreateFileMapping,eax,0,PAGE_READWRITE,0,0,0
		
		    .if eax!=NULL
		    mov local_hFileMapping,eax

			invoke MapViewOfFile,eax,FILE_MAP_WRITE,0,0,0
			.if eax!=NULL

				mov local_hViewOfFile,eax
				invoke GetFileSize,local_hFile,0
				mov local_filesize,eax

				push 1
				push local_filesize
				push PATTERNSIZE
				push offset ReplaceMask
				push offset ReplacePattern
				push offset SearchMask
				push offset SearchPattern
				push local_hViewOfFile
				call SearchAndReplace
				mov local_retvalue,eax

				invoke UnmapViewOfFile,local_hViewOfFile
			.endif
			invoke CloseHandle,local_hFileMapping
		.endif
		invoke CloseHandle,local_hFile
	.endif
	popad
	mov eax,local_retvalue
	ret

PatchFile endp