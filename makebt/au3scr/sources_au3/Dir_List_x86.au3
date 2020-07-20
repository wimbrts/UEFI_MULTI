#RequireAdmin
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5 + put file SciTEUser.properties in your UserProfile e.g. C:\Users\User-10

 Author:        WIMB  -  July 20, 2020

 Program:       Dir_List_x64.exe - Version 2.0

 Script Function:

 Credits and Thanks to:
	The program is released "as is" and is free for redistribution, use or changes as long as original author,
	credits part and link to the reboot.pro support forum are clearly mentioned

	Author does not take any responsibility for use or misuse of the program.

#ce ----------------------------------------------------------------------------

Global $TargetSelect = "", $pos_TS, $len_TS, $path_folder = "", $drv = ""

$TargetSelect = FileSelectFolder("Select Path to make Folder and File List from Path ", "")
If @error Then
	MsgBox(48,"ERROR - Path Invalid", "Error - Path Invalid")
Else
	If StringInStr($TargetSelect, "\", 0, -1) = 0 Or StringInStr($TargetSelect, ":", 0, 1) <> 2 Then
		MsgBox(48,"ERROR - Path Invalid", "Drive Invalid  :  Or \ Not found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect)
	Else
		$len_TS = StringLen($TargetSelect)
		$drv = StringLeft($TargetSelect, 1)
		If $len_TS > 3 Then
			$pos_TS = StringInStr($TargetSelect, "\", 0, -1)
			$path_folder = StringRight($TargetSelect, $len_TS - $pos_TS)
			RunWait(@ComSpec & " /c dir /b /s /ad-l /on > " & '"' & @ScriptDir & "\Folder_List_" & $drv & "_" & $path_folder & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "Folder_List_" & $drv & "_" & $path_folder & ".txt", @ScriptDir)
			RunWait(@ComSpec & " /c dir /b /s /a-d-l /on > " & '"' & @ScriptDir & "\File_List_" & $drv & "_" & $path_folder & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "File_List_" & $drv & "_" & $path_folder & ".txt", @ScriptDir)
		Else
			RunWait(@ComSpec & " /c dir /b /s /ad-l /on > " & '"' & @ScriptDir & "\Folder_List_" & $drv & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "Folder_List_" & $drv & ".txt", @ScriptDir)
			RunWait(@ComSpec & " /c dir /b /s /a-d-l /on > " & '"' & @ScriptDir & "\File_List_" & $drv & ".txt" & '"', $TargetSelect, @SW_HIDE)
			ShellExecute("notepad.exe", "File_List_" & $drv & ".txt", @ScriptDir)
		EndIf
	EndIf
EndIf

Exit