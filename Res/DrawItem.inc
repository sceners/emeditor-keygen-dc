DrawItem PROC hWnd: HWND, lParam: LPARAM
  push esi
  mov esi, lParam
  assume esi: ptr DRAWITEMSTRUCT

  .if [esi].itemState & ODS_SELECTED
    invoke SelectObject, [esi].hdc, hIn2Color
  .else
    invoke SelectObject, [esi].hdc, hInColor
  .endif

  invoke SelectObject, [esi].hdc, hEdge

  invoke FillRect, [esi].hdc, ADDR [esi].rcItem, hFgColor
  invoke RoundRect, [esi].hdc, [esi].rcItem.left, [esi].rcItem.top, [esi].rcItem.right, [esi].rcItem.bottom, 6, 6

  .if [esi].itemState & ODS_SELECTED
    invoke OffsetRect, ADDR [esi].rcItem, 1, 1
  .endif

  ; Write the text
  invoke GetDlgItemText, hWnd, [esi].CtlID, ADDR sBtnText, SIZEOF sBtnText
  invoke SetBkMode, [esi].hdc, TRANSPARENT
  invoke SetTextColor, [esi].hdc, CR_BUTTON
  invoke DrawText, [esi].hdc, ADDR sBtnText, -1, ADDR [esi].rcItem, DT_CENTER or DT_VCENTER or DT_SINGLELINE

  .IF [esi].itemState & ODS_SELECTED
    INVOKE OffsetRect, ADDR [esi].rcItem, -1, -1
  .ENDIF

  ; Draw the focus rectangle
  .if [esi].itemState & ODS_FOCUS
    invoke InflateRect, ADDR [esi].rcItem, -3, -3
    ;INVOKE DrawFocusRect, [esi].hdc, ADDR [esi].rcItem
  .endif

  assume esi:nothing
  pop esi
  mov eax, TRUE
  ret
DrawItem ENDP