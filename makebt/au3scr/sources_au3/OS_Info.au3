
; AutoIt Version: 3.3.8.1 + file SciTEUser.properties in your UserProfile e.g. C:\Documents and Settings\UserXP Or C:\Users\User-7

MsgBox(0, "OS Info", "OS Type = " & @OSTYPE & @CRLF & "OS Version = " & @OSVersion & @CRLF & _
"OS Build = " & @OSBuild & @CRLF & "OS SP = " & @OSServicePack & @CRLF & "OS Architecture = " & @OSArch & @CRLF & _ 
"WINDOWS = " & @WindowsDir & @CRLF & "HomeDrive = " & @HomeDrive & @CRLF & "ProgramFilesDir = " & @ProgramFilesDir & @CRLF & "ProgramsDir = " & @ProgramsDir & @CRLF & _ 
"MyDocumentsDir = " & @MyDocumentsDir & @CRLF & "StartMenuDir = " & @StartMenuDir & @CRLF & "UserProfileDir = " & @UserProfileDir)

MsgBox(0, "TEST OS Info", "End of Program " & @CRLF & @CRLF & "Error Code = " & @error)

;	Local $oFSO = ObjCreate("Scripting.FileSystemObject"), $sTFolder
;	MsgBox(0, "TEST ObjCreate FileSystemObject", "Error = " & @error)
;
;	$sTFolder = $oFSO.GetSpecialFolder(2)
;	MsgBox(0, "TEST $oFSO GetSpecialFolder", "Error = " & @error)
;
;	Local $hOutFile = @TempDir & $oFSO.GetTempName
;	MsgBox(0, "TEST $oFSO GetTempName", "Error = " & @error)
    