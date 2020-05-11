#RequireAdmin
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5 + put file SciTEUser.properties in your UserProfile e.g. C:\Users\User-10

 Author:        WIMB  -  Oct 06, 2019

 Program:       Dir_List.exe - Version 1.0

 Script Function:

 Credits and Thanks to:
	The program is released "as is" and is free for redistribution, use or changes as long as original author,
	credits part and link to the reboot.pro support forum are clearly mentioned
	VHD_WIMBOOT - http://reboot.pro/topic/21977-vhd-wimboot-apply-and-capture-of-wim-files-for-os-in-vhd/

	Author does not take any responsibility for use or misuse of the program.

#ce ----------------------------------------------------------------------------

Global $TargetSelect = "", $pos_TS, $len_TS, $path_folder = "", $drv = ""

; RunWait(@ComSpec & " /u /c dir /b /s /ad-l /on > dir_list.txt", @ScriptDir, @SW_HIDE)
; ShellExecute("notepad.exe", "dir_list.txt", @ScriptDir)
; RunWait(@ComSpec & " /u /c dir /b /s /a-d-l /on > file_list.txt", @ScriptDir, @SW_HIDE)
; ShellExecuteWait("notepad.exe", "file_list.txt", @ScriptDir)

; _GUICtrlStatusBar_SetText($hStatus," Select Path to make Folder List from Path", 0)
$TargetSelect = FileSelectFolder("Select Path to make Folder and File List from Path ", "")
If @error Then
	; _GUICtrlStatusBar_SetText($hStatus,"", 0)
	MsgBox(48,"ERROR - Path Invalid", "Error - Path Invalid")
Else
	If StringInStr($TargetSelect, "\", 0, -1) = 0 Or StringInStr($TargetSelect, ":", 0, 1) <> 2 Then
		; _GUICtrlStatusBar_SetText($hStatus,"", 0)
		MsgBox(48,"ERROR - Path Invalid", "Drive Invalid  :  Or \ Not found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect)
	Else
		; _GUICtrlStatusBar_SetText($hStatus," Using Dir Command to Make Folder List - Wait ...", 0)
		$len_TS = StringLen($TargetSelect)
		$drv = StringLeft($TargetSelect, 1)
		If $len_TS > 3 Then
			$pos_TS = StringInStr($TargetSelect, "\", 0, -1)
			$path_folder = StringRight($TargetSelect, $len_TS - $pos_TS)
			RunWait(@ComSpec & " /u /c dir /b /s /ad-l /on > " & '"' & @ScriptDir & "\Folder_List_" & $drv & "_" & $path_folder & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "Folder_List_" & $drv & "_" & $path_folder & ".txt", @ScriptDir)
			RunWait(@ComSpec & " /u /c dir /b /s /a-d-l /on > " & '"' & @ScriptDir & "\File_List_" & $drv & "_" & $path_folder & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "File_List_" & $drv & "_" & $path_folder & ".txt", @ScriptDir)
		Else
			RunWait(@ComSpec & " /u /c dir /b /s /ad-l /on > " & '"' & @ScriptDir & "\Folder_List_" & $drv & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "Folder_List_" & $drv & ".txt", @ScriptDir)
			RunWait(@ComSpec & " /u /c dir /b /s /a-d-l /on > " & '"' & @ScriptDir & "\File_List_" & $drv & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "File_List_" & $drv & ".txt", @ScriptDir)
		EndIf
	EndIf
EndIf
; _GUICtrlStatusBar_SetText($hStatus,"", 0)
