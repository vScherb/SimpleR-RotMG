#include-once
#include <Array.au3>
;Check if Monitor supports Resolution
;Basic Idea by PACaleala from https://www.autoitscript.com/forum/topic/185017/?do=findComment&comment=1328940
Func _ScreenCompatibility($rw = 800, $rh = 600)
	Local $strComputer = "."
	Local $objWMIService = ObjGet("winmgmts:" & "{impersonationLevel=impersonate}!\\" & $strComputer & "\root\cimv2")
	Local $colItems = $objWMIService.ExecQuery("Select * from CIM_VideoControllerResolution")
	Local $compatible[] = ["0", "0", "0"]
	For $objItem In $colItems
		If $objItem.HorizontalResolution = $rw And $objItem.VerticalResolution = $rh Then
			If $objItem.RefreshRate > $compatible[2] Then
				$compatible[0] = $objItem.HorizontalResolution
				$compatible[1] = $objItem.VerticalResolution
				$compatible[2] = $objItem.RefreshRate
			EndIf
		EndIf
	Next
	If $compatible[2] > 0 Then
		Return $compatible
	Else
		Return -1
	EndIf

EndFunc   ;==>_ScreenCompatibility


;===============================================================================
;
; Function Name: _ChangeScreenRes()
; Description: Changes the current screen geometry, colour and refresh rate.
; Version: 1.0.0.1
; Parameter(s): $i_Width - Width of the desktop screen in pixels. (horizontal resolution)
; $i_Height - Height of the desktop screen in pixels. (vertical resolution)
; $i_BitsPP - Depth of the desktop screen in bits per pixel.
; $i_RefreshRate - Refresh rate of the desktop screen in hertz.
; Requirement(s): AutoIt Beta > 3.1
; Return Value(s): On Success - Screen is adjusted, @ERROR = 0
; On Failure - sets @ERROR = 1
; Forum(s): <a href='http://www.autoitscript.com/forum/index.php?showtopic=20121' class='bbc_url' title=''>http://www.autoitscript.com/forum/index.php?showtopic=20121</a>
; Author(s): Original code - psandu.ro
; Modifications - PartyPooper
;
;===============================================================================

Func _ChangeScreenRes($i_Width = @DesktopWidth, $i_Height = @DesktopHeight, $i_BitsPP = @DesktopDepth, $i_RefreshRate = @DesktopRefresh)
	Local Const $DM_PELSWIDTH = 0x00080000
	Local Const $DM_PELSHEIGHT = 0x00100000
	Local Const $DM_BITSPERPEL = 0x00040000
	Local Const $DM_DISPLAYFREQUENCY = 0x00400000
	Local Const $CDS_TEST = 0x00000002
	Local Const $CDS_UPDATEREGISTRY = 0x00000001
	Local Const $DISP_CHANGE_RESTART = 1
	Local Const $DISP_CHANGE_SUCCESSFUL = 0
	Local Const $HWND_BROADCAST = 0xffff
	Local Const $WM_DISPLAYCHANGE = 0x007E
	If $i_Width = "" Or $i_Width = -1 Then $i_Width = @DesktopWidth ; default to current setting
	If $i_Height = "" Or $i_Height = -1 Then $i_Height = @DesktopHeight ; default to current setting
	If $i_BitsPP = "" Or $i_BitsPP = -1 Then $i_BitsPP = @DesktopDepth ; default to current setting
	If $i_RefreshRate = "" Or $i_RefreshRate = -1 Then $i_RefreshRate = @DesktopRefresh ; default to current setting
	Local $DEVMODE = DllStructCreate("byte[32];int[10];byte[32];int[6]")
	Local $B = DllCall("user32.dll", "int", "EnumDisplaySettings", "ptr", 0, "long", 0, "ptr", DllStructGetPtr($DEVMODE))
	If @error Then
		$B = 0
		SetError(1)
		Return $B
	Else
		$B = $B[0]
	EndIf
	If $B <> 0 Then
		DllStructSetData($DEVMODE, 2, BitOR($DM_PELSWIDTH, $DM_PELSHEIGHT, $DM_BITSPERPEL, $DM_DISPLAYFREQUENCY), 5)
		DllStructSetData($DEVMODE, 4, $i_Width, 2)
		DllStructSetData($DEVMODE, 4, $i_Height, 3)
		DllStructSetData($DEVMODE, 4, $i_BitsPP, 1)
		DllStructSetData($DEVMODE, 4, $i_RefreshRate, 5)
		$B = DllCall("user32.dll", "int", "ChangeDisplaySettings", "ptr", DllStructGetPtr($DEVMODE), "int", $CDS_TEST)
		If @error Then
			$B = -1
		Else
			$B = $B[0]
		EndIf
		Select
			Case $B = $DISP_CHANGE_RESTART
				$DEVMODE = ""
				Return 2
			Case $B = $DISP_CHANGE_SUCCESSFUL
				DllCall("user32.dll", "int", "ChangeDisplaySettings", "ptr", DllStructGetPtr($DEVMODE), "int", $CDS_UPDATEREGISTRY)
				DllCall("user32.dll", "int", "SendMessage", "hwnd", $HWND_BROADCAST, "int", $WM_DISPLAYCHANGE, _
						"int", $i_BitsPP, "int", $i_Height * 2 ^ 16 + $i_Width)
				$DEVMODE = ""
				Return 1
			Case Else
				$DEVMODE = ""
				SetError(1)
				Return $B
		EndSelect
	EndIf
EndFunc   ;==>_ChangeScreenRes
