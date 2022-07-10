;**********************************************************************************************
;* Example (how to use)                                                                       *
;* ------------------------------------------------------------------------------------------ *
;* search : 2A 45 EB ?? C3 ?? EF                                                              *
;* replace: 2A ?? ?? 10 33 C0 ??                                                              *
;*                                                                                            *
;* .data                                                                                      *
;* SearchPattern   db 02Ah, 045h, 0EBh, 000h, 0C3h, 000h, 0EFh                                *
;* SearchMask      db    0,    0,    0,    1,    0,    1,    0	 (1=Ignore Byte)              *
;*                                                                                            *
;* ReplacePattern  db 02Ah, 000h, 000h, 010h, 033h, 0C0h, 000h                                *
;* ReplaceMask     db    0,    1,    1,    0,    0,    0,    1	 (1=Ignore Byte)              *
;*                                                                                            *
;* .const                                                                                     *
;* PatternSize     equ 7                                                                      *
;*                                                                                            *
;* .code                                                                                      *
;* push -1                       Replace Number (-1=ALL / 2=2nd match ...)                    *
;* push FileSize                 how many bytes to search from beginning from TargetAdress    *
;* push PatternSize              lenght of Pattern                                            *
;* push offset ReplaceMask                                                                    *
;* push offset ReplacePattern                                                                 *
;* push offset SearchMask                                                                     *
;* push offset SearchPattern                                                                  *
;* push TargetAddress            the memory address where the search starts                   *
;* call SearchAndReplace                                                                      *
;*                                                                                            *
;* ReturnValue in eax (1=Success 0=Failed)                                                    *
;**********************************************************************************************

.586					
option casemap :none

SearchAndReplace  PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SearchAndReplace1  PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

.code

SearchAndReplace proc\
	_targetadress:dword,_searchpattern:dword,\
	_searchmask:dword,_replacepattern:dword,
	_replacemask:dword,_patternsize:dword,\
	_searchsize:dword,_patchnumber:dword
			
	LOCAL local_returnvalue	:byte 	;returns if something was patched
	LOCAL local_match	    :dword	;counts how many matches
	
	pushad
	mov local_returnvalue,0
	mov local_match,0
	
	mov edi,_targetadress
	mov esi,_searchpattern
	mov edx,_searchmask
	mov ebx,_patternsize
	xor ecx,ecx
	
	.while ecx!=_searchsize
		@search_again:
		;---check if pattern exceed memory---
		mov eax,ecx		;ecx=raw offset
		add eax,ebx		;raw offset + patternsize
		cmp eax,_searchsize
		ja @return		;if (raw offset + patternsize) > searchsize then bad!
		
		push ecx		;counter
		push esi		;searchpattern
		push edi		;targetaddress
		push edx		;searchmask
		
		mov ecx,ebx		;ebx=patternsize
		@cmp_mask:
		test ecx,ecx
		je @pattern_found
		cmp byte ptr[edx],1	;searchmask
		je @ignore
		lodsb			;load searchbyte to al & inc esi
		scasb			;cmp al,targetadressbyte & inc edi
		jne @skip
		inc edx			;searchmask
		dec ecx			;patternsize
		jmp @cmp_mask
		@ignore:
		inc edi			;targetadress
		inc esi			;searchpattern
		inc edx			;searchmask
		dec ecx			;patternsize
		jmp @cmp_mask
		
		@skip:
		pop edx
		pop edi			;targetadress
		pop esi			;searchpattern
		pop ecx
		
		inc edi			;targetadress
		inc ecx			;counter
	.endw
	;---scanned whole memory size---
	jmp @return	

	@pattern_found:
	inc local_match
	pop edx
	pop edi				;targetadress
	pop esi
	mov eax,_patchnumber
	cmp eax,-1
	je @replace			
	cmp local_match,eax
	je @replace
	pop ecx				;counter
	inc edi				;targetadress
	jmp @search_again
	
	;---replace pattern---
	@replace:
	mov esi,_replacepattern
	mov edx,_replacemask
	
	xor ecx,ecx
	.while ecx!=ebx			;ebx=patternsize
		@cmp_mask_2:
		cmp byte ptr[edx],1
		je @ignore_2
		lodsb			;load replacebyte to al from esi & inc esi
		stosb			;mov byte ptr[edi],al & inc edi
		jmp @nextbyte
		@ignore_2:
		inc edi			;targetadress
		inc esi			;replacepattern
		@nextbyte:
		inc edx			;replacemask
		inc ecx			;counter
	.endw
	mov local_returnvalue,1		;yes, something was patched
	
	;---search again?---
	pop ecx				;counter-->scanned size
	cmp _patchnumber,-1
	jne @return
	sub edi,ebx			;edi=targetadress ; countinue where stopped
	inc edi				;...
	inc ecx				;ecx=counter(pointer to offset)  /bug fixed in v2.07
	mov esi,_searchpattern
	mov edx,_searchmask
	jmp @search_again

	;---return---
	@return:
	popad
	movzx eax,local_returnvalue
	ret
SearchAndReplace endp

SearchAndReplace1 proc\
 	_targetadress:dword,_searchpattern1:dword,\
   _searchmask1:dword,_replacepattern1:dword,\
	_replacemask1:dword,_patternsize:dword,\
   _searchsize:dword,_patchnumber:dword
			
	LOCAL local_returnvalue	:byte 	;returns if something was patched
	LOCAL local_match	    :dword	;counts how many matches
	
	pushad
	mov local_returnvalue,0
	mov local_match,0
	
	mov edi,_targetadress
	mov esi,_searchpattern1
	mov edx,_searchmask1
	mov ebx,_patternsize
	xor ecx,ecx
	
	.while ecx!=_searchsize
		@search_again:
		;---check if pattern exceed memory---
		mov eax,ecx		;ecx=raw offset
		add eax,ebx		;raw offset + patternsize
		cmp eax,_searchsize
		ja @return		;if (raw offset + patternsize) > searchsize then bad!
		
		push ecx		;counter
		push esi		;searchpattern
		push edi		;targetaddress
		push edx		;searchmask
		
		mov ecx,ebx		;ebx=patternsize
		@cmp_mask:
		test ecx,ecx
		je @pattern_found
		cmp byte ptr[edx],1	;searchmask
		je @ignore
		lodsb			;load searchbyte to al & inc esi
		scasb			;cmp al,targetadressbyte & inc edi
		jne @skip
		inc edx			;searchmask
		dec ecx			;patternsize
		jmp @cmp_mask
		@ignore:
		inc edi			;targetadress
		inc esi			;searchpattern
		inc edx			;searchmask
		dec ecx			;patternsize
		jmp @cmp_mask
		
		@skip:
		pop edx
		pop edi			;targetadress
		pop esi			;searchpattern
		pop ecx
		
		inc edi			;targetadress
		inc ecx			;counter
	.endw
	;---scanned whole memory size---
	jmp @return	

	@pattern_found:
	inc local_match
	pop edx
	pop edi				;targetadress
	pop esi
	mov eax,_patchnumber
	cmp eax,-1
	je @replace			
	cmp local_match,eax
	je @replace
	pop ecx				;counter
	inc edi				;targetadress
	jmp @search_again
	
	;---replace pattern---
	@replace:
	mov esi,_replacepattern1
	mov edx,_replacemask1
	
	xor ecx,ecx
	.while ecx!=ebx			;ebx=patternsize
		@cmp_mask_2:
		cmp byte ptr[edx],1
		je @ignore_2
		lodsb			;load replacebyte to al from esi & inc esi
		stosb			;mov byte ptr[edi],al & inc edi
		jmp @nextbyte
		@ignore_2:
		inc edi			;targetadress
		inc esi			;replacepattern
		@nextbyte:
		inc edx			;replacemask
		inc ecx			;counter
	.endw
	mov local_returnvalue,1		;yes, something was patched
	
	;---search again?---
	pop ecx				;counter-->scanned size
	cmp _patchnumber,-1
	jne @return
	sub edi,ebx			;edi=targetadress ; countinue where stopped
	inc edi				;...
	inc ecx				;ecx=counter(pointer to offset)  /bug fixed in v2.07
	mov esi,_searchpattern1
	mov edx,_searchmask1
	jmp @search_again

	;---return---
	@return:
	popad
	movzx eax,local_returnvalue
	ret
SearchAndReplace1 endp