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

RunWait(@ComSpec & " /u /c dir /b /s /ad-l /on > dir_list.txt", @ScriptDir, @SW_HIDE)
ShellExecute("notepad.exe", "dir_list.txt", @ScriptDir)
RunWait(@ComSpec & " /u /c dir /b /s /a-d-l /on > file_list.txt", @ScriptDir, @SW_HIDE)
ShellExecuteWait("notepad.exe", "file_list.txt", @ScriptDir)

