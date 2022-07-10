;include    windows.inc
;include    kernel32.inc
;include    user32.inc
;include    Comctl32.inc
;include    gdi32.inc

;includelib kernel32.lib
;includelib user32.lib
;includelib Comctl32.lib
;includelib gdi32.lib
;include    macros.asm

;******************************************************************************
;* INCLUDES                                                                   *
;******************************************************************************

include    HyperLink\HLstatic.inc
includelib HyperLink\HLstatic.lib

.const

IDC_HLK		    equ 1003
DELAY			dd 20
COLOR 		    dd 00FFFF03h
COLOR1		    dd 004BFFFBh
COLORBKG		dd 00000000h

.data

link			dd 0
