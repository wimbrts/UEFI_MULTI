Local $Pstart

$Pstart = _FileFind('\PStart\PStart.exe')
IF Not @error Then
	ShellExecute($Pstart, '', StringRegExpReplace($Pstart, "(^.*)\\(.*)", "\1"))
EndIf

Exit
;===================================================================================================
Func _FileFind($Searchfile)
	Local $LETTER
	
	$LETTER = DriveGetDrive('all')
	IF @error Then Return SetError(1) ; very strange
	For $L = 1 To $LETTER[0]
		IF StringInStr('A: B:', $LETTER[$L]) OR StringInStr(DriveStatus($LETTER[$L]), 'NOTREADY') Then ContinueLoop ; don't check floppy's and inaccessible drives to avoid "No Disk" error
		IF FileExists($LETTER[$L] & $Searchfile) Then Return $LETTER[$L] & $Searchfile
	Next
	Return SetError(2) ; File wasn't found
EndFunc
;===================================================================================================
