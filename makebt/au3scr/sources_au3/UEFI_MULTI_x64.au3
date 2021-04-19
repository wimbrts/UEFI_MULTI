#RequireAdmin
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5 + file SciTEUser.properties in your UserProfile e.g. C:\Documents and Settings\UserXP Or C:\Users\User-10

 Author:        WIMB  -  April 10, 2021

 Program:       UEFI_MULTI_x64.exe - Version 5.8 in rule 195
	can be used to Make Mult-Boot USB-drives by using Boot Image Files (IMG ISO WIM or VHD)
	Booting with Windows Boot Manager Menu and /or Grub2 Boot Manager in MBR BIOS or UEFI mode - with Grub4dos support in MBR BIOS mode
	can be used to to Install IMG or ISO or WIM or VHD Files as Boot Option on Harddisk or USB-drive
	can be used to Copy Content Folder or Source Drive to Target Drive Or Folder - Allows to copy USB-drives

	Running in XP/7/8/10 Environment and in LiveXP PE or 7/8/10 PE Environment

 Script Function:
	Install Boot Image File on Harddisk or USB-Drive
	Enables to Launch Boot Image from Grub4dos menu.lst
	Useful as Escape Boot Option for System Backup and Restore with WinNTSetup
	or to boot with PE to prepare your Harddisk for Install of Windows XP or Windows 7/8/10

	Install as Boot Option on Harddisk or USB-drive of:
	- BartPE / UBCD4Win / LiveXP - IMG or ISO files booting from RAMDISK
	- Parted Magic - Acronis - LiveXP_RAM - CD - ISO File
	- Superfloppy Image files e.g. to boot 15 MB FreeDOS or 25 MB MS-DOS floppy images
	- XP Recovery Console Image RECONS.img booting from RAMDISK
	- 7pe_x86_E.iso - Win7 PE booting from RAMDISK
	- XP*.vhd - XP VHD Image file booting as FILEDISK or RAMDISK using WinVBlock or FiraDisk driver
	- W7*.vhd - Win7 VHD file booting as FILEDISK or RAMDISK using WinVBlock or FiraDisk driver
	- boot.wim - 7/8/10 Recovery or WinPE booting from RAMDISK

 Credits and Thanks to:
	JFX for making WinNTSetup4 to Install Windows 2k/XP/2003/Vista/7/8/10 x86/x64 - https://msfn.org/board/topic/149612-winntsetup-v41/
	karyonix for making FiraDisk driver- http://reboot.pro/topic/8804-firadisk-latest-00130/
	Sha0 for making WinVBlock driver - http://reboot.pro/topic/8168-winvblock/
	Olof Lagerkvist for ImDisk virtual disk driver - http://www.ltr-data.se/opencode.html#ImDisk and http://reboot.pro/index.php?showforum=59
	Dariusz Stanislawek for the DS File Ops Kit (DSFOK) - http://members.ozemail.com.au/~nulifetv/freezip/freeware/
	cdob and maanu to Fix Win7 for booting from USB - http://reboot.pro/topic/14186-usb-hdd-boot-and-windows-7-sp1/

	Uwe Sieber for making ListUsbDrives - http://www.uwe-sieber.de/english.html
	a1ive for making Grub2 Boot Manager - https://github.com/a1ive/grub/releases and http://reboot.pro/topic/22400-grub4dos-for-uefi/
	a1ive for making Grub2 File Manager - https://github.com/a1ive/grub2-filemanager/releases
	ValdikSS for making Super UEFIinSecureBoot Disk v3 - https://github.com/ValdikSS/Super-UEFIinSecureBoot-Disk/releases
	Matthias Saou - thias - for making glim - https://github.com/thias/glim
	chenall, yaya, tinybit and Bean for making Grub4dos - https://github.com/chenall/grub4dos/releases and http://grub4dos.chenall.net/categories/downloads/
	yaya2007 for making UEFI Grub4dos - https://github.com/chenall/grub4dos/releases and http://grub4dos.chenall.net/categories/downloads/
	alacran for support and info - http://reboot.pro/topic/21957-making-the-smallest-win10-install-wimboot-mode-on-512-mb-vhd/
		and http://reboot.pro/topic/21972-reducing-wimboot-source-wim-file-using-lzx-compression-and-vhd-using-gzip-or-lz4-compression-to-save-room-and-also-load-faster-on-ram/
	alacran for starting topic on Reducing Win10 - http://reboot.pro/topic/22383-reducing-win10-and-older-oss-footprint/
	cdob for making WinSxS_reduce with base_winsxs.cmd - http://reboot.pro/topic/22281-get-alladafluff-out/page-3#entry215317

	The program is released "as is" and is free for redistribution, use or changes as long as original author,
	credits part and link to the reboot.pro and MSFN support forum are clearly mentioned
	USB Format Tool and UEFI_MULTI - http://reboot.pro/topic/22254-usb-format-tool-and-uefi-multi/
	USB Format Tool and UEFI_MULTI - https://msfn.org/board/topic/181311-usb-format-tool-and-uefi_multi/
	Download from wimb GitHub - https://github.com/wimbrts - https://github.com/wimbrts/USB_FORMAT/releases - https://github.com/wimbrts/UEFI_MULTI/releases

	More Info on booting Win 7 VHD from grub4dos menu by using FiraDisk Or WinVBlock driver:
	http://reboot.pro/topic/9830-universal-hdd-image-files-for-xp-and-windows-7/ Or http://www.911cd.net/forums//index.php?showtopic=23553
	Boot Windows 7 from USB - http://reboot.pro/index.php?showforum=77
	Boot Windows 7 from USB - karyonix - http://reboot.pro/index.php?showtopic=9196
	http://reboot.pro/topic/9830-universal-hdd-image-files-for-xp-and-windows-7/

	Author does not take any responsibility for use or misuse of the program.

#ce ----------------------------------------------------------------------------

#include <guiconstants.au3>
#include <ProgressConstants.au3>
#include <GuiConstantsEx.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#Include <GuiStatusBar.au3>
#include <Array.au3>
#Include <String.au3>
#include <Process.au3>
#include <Date.au3>

Opt('MustDeclareVars', 1)
Opt("GuiOnEventMode", 1)
Opt("TrayIconHide", 1)

; Setting variables
Global $TargetDrive="", $ProgressAll, $Paused, $g4d_vista=1, $ntfs_bs=1, $bs_valid=0, $g4d_w7vhd_flag=1, $Firmware = "UEFI", $PartStyle = "MBR", $SysStyle = "MBR"
Global $btimgfile="", $pe_nr=1, $hStatus, $pausecopy=0, $TargetSpaceAvail=0, $TargetSize, $TargetFree, $FSvar_WinDrvDrive="", $g4d=0, $bm_flag = 0, $g4dmbr=0
Global $hGuiParent, $GO, $EXIT, $SourceDir, $Source, $TargetSel, $Target, $image_file="", $img_fext="", $grldrUpd, $g4d_bcd, $xp_bcd, $g4d_default = 0
Global $BTIMGSize=0, $IMG_File, $IMG_FileSelect, $ImageType, $ImageSize, $NTLDR_BS=1, $refind, $Menu_Type, $g2_inst=1, $Add_Grub2_Sys
Global $NoVirtDrives, $FixedDrives, $w78sys=0, $bootsdi = "", $windows_bootsdi = "", $sdi_path = "", $FSvar_TargetDrive="", $mbr_gpt_vhd_flag = "MBR"
Global $vhdfolder = "", $vhdfile_name = "", $vhdfile_name_only = "", $img_folder = "", $PSize = "1.5 GB", $Part12_flag = 0, $diskpart_error = 0, $vhd_hid_efi = 0, $vhd_rev_layout = 0

Global $driver_flag=3, $vhdmp=0, $SysWOW64=0, $WinFol="\Windows", $PE_flag = 0, $WinDir_PE="D:\Windows", $WinDir_PE_flag=0, $WimOnSystemDrive = 0
Global $bcdedit="", $winload = "winload.exe", $store = "", $DistLang = "en-US", $WinLang = "en-US", $bcdboot_flag = 0, $ventoy = 0, $grub2 = 0, $Target_MBR_FAT32 = 0

Global $bcd_guid_outfile = "makebt\bs_temp\crea_bcd_guid.txt", $sdi_guid_outfile = "makebt\bs_temp\crea_sdi_guid.txt"

Global $Combo_EFI, $Combo_Folder, $Upd_MBR, $Boot_w8, $Boot_vhd, $vhd_cnt=0, $dt

Global $AddContentBrowse, $AddContentSource, $ContentSize=0, $TotalSourceSize=0, $ContentSource, $GUI_ContentSize, $content_folder="", $NrCpdFiles

Global $vhd_f32_drive = "", $tmpdrive="", $WinDrv, $WinDrvSel, $WinDrvSize, $WinDrvFree, $WinDrvFileSys, $WinDrvSpaceAvail=0, $WinDrvDrive="", $DriveSysType="Fixed", $DriveType="Fixed"

Global $inst_disk="", $inst_part="", $sys_disk="", $sys_part="", $usbsys=0, $usbfix=0, $BusType = "", $BusSys = "", $Target_Device, $Target_Type, $Sys_Device, $Sys_Type

Global $OS_drive = StringLeft(@WindowsDir, 2)

Global $str = "", $bt_files[26] = ["\makebt\dsfo.exe", "\makebt\dsfi.exe", "\makebt\listusbdrives\ListUsbDrives.exe", "\makebt\Exclude_Copy_USB.txt", "\makebt\menu_Win_ISO.lst", _
"\makebt\grldr.mbr", "\makebt\grldr", "\makebt\menu.lst", "\makebt\menu_Linux.lst", "\UEFI_MAN\efi", "\UEFI_MAN\efi_mint", "\makebt\Linux_ISO_Files.txt", "\makebt\grub.exe", _
"\WofCompress\x64\WofCompress.exe", "\WofCompress\x86\WofCompress.exe", "\makebt\menu_distro.lst", "\UEFI_MAN\grub\grub_distro.cfg", _
"\UEFI_MAN\EFI\grub\menu.lst", "\UEFI_MAN\grub\grub.cfg", "\UEFI_MAN\grub\grub_Linux.cfg", "\UEFI_MAN\grub\core.img", "\UEFI_MAN\EFI\grub\ntfs_x64.efi", _
"\UEFI_MAN\EFI\Boot\bootx64_g4d.efi", "\UEFI_MAN\EFI\Boot\bootia32_g4d.efi", "\UEFI_MAN\EFI\Boot\grubx64_real.efi", "\UEFI_MAN\EFI\Boot\grubia32_real.efi"]

;~ 	If @OSArch <> "X86" Then
;~ 	   MsgBox(48, "ERROR - Environment", "In x64 environment use UEFI_MULTI_x64.exe ")
;~ 	   Exit
;~ 	EndIf

For $str In $bt_files
	If Not FileExists(@ScriptDir & $str) Then
		MsgBox(48, "ERROR - Missing File", "File " & $str & " NOT Found ")
		Exit
	EndIf
Next

If FileExists(@ScriptDir & "\makebt\bs_temp") Then DirRemove(@ScriptDir & "\makebt\bs_temp",1)
If Not FileExists(@ScriptDir & "\makebt\bs_temp") Then DirCreate(@ScriptDir & "\makebt\bs_temp")
If Not FileExists(@ScriptDir & "\makebt\backups") Then DirCreate(@ScriptDir & "\makebt\backups")

If Not FileExists(@ScriptDir & "\makebt\Boot_XP") Then DirCreate(@ScriptDir & "\makebt\Boot_XP")

If FileExists(@ScriptDir & "\makebt\vhd_temp") Then DirRemove(@ScriptDir & "\makebt\vhd_temp",1)
If Not FileExists(@ScriptDir & "\makebt\vhd_temp") Then DirCreate(@ScriptDir & "\makebt\vhd_temp")

If Not FileExists(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN") And @OSArch = "X86" Then
	If FileExists($OS_drive & "\BOOTFONT.BIN") And @OSVersion = "WIN_XP" Then
		FileCopy($OS_drive & "\BOOTFONT.BIN", @ScriptDir & "\makebt\Boot_XP\", 1)
		FileSetAttrib(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN", "-RSH")
	EndIf
EndIf

If Not FileExists(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM") Then
	If FileExists($OS_drive & "\NTDETECT.COM") And @OSVersion = "WIN_XP" And @OSArch = "X86" Then
		FileCopy($OS_drive & "\NTDETECT.COM", @ScriptDir & "\makebt\Boot_XP\", 1)
		FileSetAttrib(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM", "-RSH")
	EndIf
EndIf

If Not FileExists(@ScriptDir & "\makebt\Boot_XP\NTLDR") Then
	If FileExists($OS_drive & "\NTLDR") And @OSVersion = "WIN_XP" And @OSArch = "X86" Then
		FileCopy($OS_drive & "\NTLDR", @ScriptDir & "\makebt\Boot_XP\", 1)
		FileSetAttrib(@ScriptDir & "\makebt\Boot_XP\NTLDR", "-RSH")
	EndIf
EndIf

If Not FileExists(@ScriptDir & "\makebt\xcopy.exe") Then
	If FileExists(@WindowsDir & "\system32\xcopy.exe") And @OSVersion = "WIN_XP" And @OSArch = "X86" Then
		FileCopy(@WindowsDir & "\system32\xcopy.exe", @ScriptDir & "\makebt\", 1)
	EndIf
EndIf

If StringLeft(@SystemDir, 1) = "X" Then
	$PE_flag = 1
Else
	$PE_flag = 0
EndIf

$WinDir_PE_flag=0
If $PE_flag = 1 Then
	If FileExists("C:\Windows\Boot") Then
		$WinDir_PE = "C:\Windows"
	ElseIf FileExists("D:\Windows\Boot") Then
		$WinDir_PE = "D:\Windows"
	ElseIf FileExists("E:\Windows\Boot") Then
		$WinDir_PE = "E:\Windows"
	ElseIf FileExists(@WindowsDir & "\Boot") Then
		$WinDir_PE = @WindowsDir
		$WinDir_PE_flag=1
	Else
		$WinDir_PE = "D:\Windows"
	EndIf
EndIf

_Mount_EFI()

; HotKeySet("{PAUSE}", "TogglePause")
; HotKeySet("{ESC}", "TogglePause")

; Creating GUI and controls
$hGuiParent = GUICreate(" UEFI_MULTI x64 - Make Multi-Boot USB ", 400, 430, -1, -1, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
GUISetOnEvent($GUI_EVENT_CLOSE, "_Quit")

If $PE_flag = 1 Then
	GUICtrlCreateGroup("Sources   - Version 5.8  -   OS = " & @OSVersion & " " & @OSArch & "  " & $Firmware & "  PE", 15, 10, 370, 235)
Else
	GUICtrlCreateGroup("Sources   - Version 5.8  -   OS = " & @OSVersion & " " & @OSArch & "  " & $Firmware, 15, 10, 370, 235)
EndIf

$ImageType = GUICtrlCreateLabel( "", 280, 29, 104, 15, $ES_READONLY)
$ImageSize = GUICtrlCreateLabel( "", 225, 29, 50, 15, $ES_READONLY)

GUICtrlCreateLabel( "Boot Image - VHD or WIM or Win ISO", 32, 29)
$IMG_File = GUICtrlCreateInput("", 32, 45, 303, 20, $ES_READONLY)
$IMG_FileSelect = GUICtrlCreateButton("...", 341, 46, 26, 18)
GUICtrlSetTip($IMG_File, " Make entry in Boot Manager Menu on Boot Drive for VHD or WIM file " & @CRLF _
& " Make entry in Grub4dos Menu on Boot Drive for VHD or Win ISO file " & @CRLF _
& " PE WIM or Win ISO can be located in folder on Boot or System Drive " & @CRLF _
& " VHD can be in folder and must be located on NTFS System Drive e.g. " & @CRLF _
& " XP*.vhd  Or  W7*.vhd - WinVBlock or FiraDisk - VHD - IMG" & @CRLF _
& " Win 8/10 VHD - SVBus RAMDISK and MS FILEDISK - VHD - IMG" & @CRLF _
& " PE 7/8/10 WIM  boot.wim  - PE in RAMDISK - WinPE - WIM" & @CRLF _
& " PE Win 7/8/10 ISO - Grub4dos only - Repair Or WinNTSetup - CD - ISO" & @CRLF _
& " NOT for Linux ISO - Copy Linux ISO manually to folder images ")

GUICtrlSetOnEvent($IMG_FileSelect, "_img_fsel")

GUICtrlCreateLabel( "Size  = ", 234, 72, 130, 15, $ES_READONLY)
$GUI_ContentSize = GUICtrlCreateLabel( "", 270, 72, 105, 15, $ES_READONLY)

GUICtrlCreateLabel("Copy to", 32, 72, 90, 15)
$Combo_Folder = GUICtrlCreateCombo("", 32, 88, 90, 24, $CBS_DROPDOWNLIST)
GUICtrlSetData($Combo_Folder,"Boot Drive|Folder on B|System Drive|Folder on S", "Folder on B")
GUICtrlSetTip($Combo_Folder, " Content of Folder or Drive is Copied to USB Target Drive " & @CRLF _
& " Or Source Folder is Copied as Folder to USB Target Drive ")

GUICtrlCreateLabel("Content Folder", 130, 72, 100, 15)
$AddContentSource = GUICtrlCreateInput("", 130, 88, 205, 20, $ES_READONLY)
$AddContentBrowse = GUICtrlCreateButton("...", 341, 89, 26, 18)
GUICtrlSetTip($AddContentBrowse, " Select Content Folder or Source Drive " & @CRLF _
& " for Copy to USB Target Drive ")
GUICtrlSetOnEvent($AddContentBrowse,"GetContentSource")

GUICtrlCreateLabel( "VHD", 32, 136, 30, 15)

$Menu_Type = GUICtrlCreateCombo("", 66, 131, 105, 24, $CBS_DROPDOWNLIST)
GUICtrlSetData($Menu_Type,"XP - WinVBlock|XP - FiraDisk|78 - WinVBlock|78 - FiraDisk|10 - SVBus", "10 - SVBus")
GUICtrlSetTip($Menu_Type, " Select Boot Menu Type for VHD - IMG file " & @CRLF _
& " Make Grub4dos Menu for XP or Win7/8/10 VHD " & @CRLF _
& " with WinVBlock or FiraDisk or SVBus Driver ")

$Upd_MBR = GUICtrlCreateCheckbox("", 204, 138, 17, 17)
GUICtrlCreateLabel( "Update MBR Boot Code", 228, 140)
GUICtrlSetTip($Upd_MBR, @CRLF &  " *** Force Update MBR Boot Code - Applied Only for USB-Disk *** " _
& @CRLF & @CRLF & "  Windows 10 MBR Boot Code is applied and Replaces Grub4dos code by using bootsect.exe " _
& @CRLF & @CRLF & "  BIOS: Win XP Format BootSector will invoke NTLDR as BootLoader with boot.ini Menu " _
& @CRLF & "  BIOS: Win 7/8/10 Format will invoke BOOTMGR as BootLoader with Boot Manager Menu " & @CRLF _
& @CRLF & "  UEFI: Win 8/10 x64 file EFI\Boot\bootx64.efi on FAT32 gives EFI Boot Manager Menu " & @CRLF)

$Boot_w8 = GUICtrlCreateCheckbox("", 204, 113, 17, 17)
GUICtrlSetTip($Boot_w8, " Make Boot Manager Menu for Win 7/8/10 System" & @CRLF _
& " Use bcdboot to make BCD entry in EFI and  Boot " & @CRLF _
& " Requires in Win 7/8 OS User Account Control = OFF ")
GUICtrlCreateLabel( "Add 7/8/10 to Boot Manager", 228, 115)

$grldrUpd = GUICtrlCreateCheckbox("", 204, 163, 17, 17)
GUICtrlSetTip($grldrUpd, " Update Grub4dos grldr Version on Boot Drive " & @CRLF _
& " Forces Update grldr.mbr for Grub4dos in Boot Manager Menu " & @CRLF _
& " Forces Update a1ive Grub2 File Manager grubfm.iso " & @CRLF _
& " Forces Update a1ive UEFI Grub2 and UEFI Grub4dos ")
GUICtrlCreateLabel( "Update Grub4dos UEFI Grub2", 228, 165)

$Boot_vhd = GUICtrlCreateCheckbox("", 32, 163, 17, 17)
GUICtrlSetTip($Boot_vhd, " Make Boot Manager Menu for 7/8/10 VHD " & @CRLF _
& " Use bcdboot to make BCD entry in EFI and  Boot " & @CRLF _
& " In 7/8 Requires User Account Control = OFF ")
GUICtrlCreateLabel( "Add VHD to Boot Manager", 56, 165)

$g4d_bcd = GUICtrlCreateCheckbox("", 32, 188, 17, 17)
GUICtrlSetTip($g4d_bcd, " Add Grub4dos to Boot Manager Menu - BIOS mode " & @CRLF _
& " Always done when grldr.mbr is not found on Boot Drive " & @CRLF _
& " For XP/7/8 WinVBlock or FiraDisk VHD and Linux ISO " & @CRLF _
& " In 7/8 Requires User Account Control = OFF ")
GUICtrlCreateLabel( "Add G4d to Boot Manager", 56, 190)

$xp_bcd = GUICtrlCreateCheckbox("", 32, 213, 17, 17)
GUICtrlSetTip($xp_bcd, " Add Start XP to Boot Manager Menu - BIOS mode " & @CRLF _
& " Boot Drive booting with bootmgr " & @CRLF _
& " In 7/8 Requires User Account Control = OFF ")
GUICtrlCreateLabel( "Add XP  to Boot Manager", 56, 215, 130, 15)

$Add_Grub2_Sys = GUICtrlCreateCheckbox("", 204, 188, 17, 17)
GUICtrlSetTip($Add_Grub2_Sys, " Add a1ive Grub2 System Folder 12 MB - 1000 Files Often Unneeded " _
& @CRLF & "    x64     UEFI - Add grub\x86_64-efi " _
& @CRLF & "    ia32    UEFI - Add grub\i386-efi " _
& @CRLF & " Legacy MBR - Add grub\i386-pc " _
& @CRLF & " Grub2 System Not available in case of Mint UEFI ")
GUICtrlCreateLabel( "Add Grub2 System Folder", 228, 190)

$refind = GUICtrlCreateCheckbox("", 204, 213, 17, 17)
GUICtrlSetTip($refind, " Add Grub2 Boot Manager for UEFI and MBR mode and Linux ISO " & @CRLF _
& " - Mint   UEFI - Only for some Linux ISO Files in images folder " & @CRLF _
& " - Super UEFI Secure - use Addon with a1ive Grub2 Boot Manager " & @CRLF _
& "   and Grub2 Live ISO Multiboot Menu for All Linux in iso folder " & @CRLF _
& " - MBR - use Addon to Install a1ive Grub2 Boot Manager - All Linux ISO " & @CRLF _
& " - Keep AIO UEFI files and Add a1ive Grub2 File Manager to AIO\grubfm ")
GUICtrlCreateLabel( "Grub2 M", 328, 215)
$Combo_EFI = GUICtrlCreateCombo("", 228, 212, 90, 24, $CBS_DROPDOWNLIST)

If Not FileExists(@ScriptDir & "\UEFI_MAN\grub_a1\grub-install.exe") Or Not FileExists(@ScriptDir & "\UEFI_MAN\EFI\Boot\MokManager.efi") Then
	GUICtrlSetData($Combo_EFI,"Mint   UEFI", "Mint   UEFI")
Else
	GUICtrlSetData($Combo_EFI,"Mint   UEFI|Super UEFI|Mint + MBR|Super + MBR|MBR  Only", "Mint   UEFI")
EndIf
GUICtrlSetTip($Combo_EFI, " Add Grub2 Boot Manager for UEFI and MBR mode and Linux ISO " & @CRLF _
& " - Mint   UEFI - Only for some Linux ISO Files in images folder " & @CRLF _
& " - Super UEFI Secure - use Addon with a1ive Grub2 Boot Manager " & @CRLF _
& "   and Grub2 Live ISO Multiboot Menu for All Linux in iso folder " & @CRLF _
& " - MBR - use Addon to Install a1ive Grub2 Boot Manager - All Linux ISO " & @CRLF _
& " - Keep AIO UEFI files and Add a1ive Grub2 File Manager to AIO\grubfm ")

GUICtrlCreateGroup("Target", 15, 252, 370, 89)

GUICtrlCreateLabel( "Boot  Drive", 32, 273)
$Target = GUICtrlCreateInput("", 110, 270, 40, 20, $ES_READONLY)
$TargetSel = GUICtrlCreateButton("...", 156, 271, 26, 18)
GUICtrlSetTip($Target, " Select your USB Boot Drive - Active FAT32 for WIM file " & @CRLF _
& " GO will Make WIM and VHD Entry in Boot Manager Menu on Boot Drive " & @CRLF _
& " and Make VHD Entry in UEFI Grub2 and UEFI Grub4dos Menu ")
GUICtrlSetOnEvent($TargetSel, "_target_drive")
$TargetSize = GUICtrlCreateLabel( "", 198, 264, 90, 15, $ES_READONLY)
$TargetFree = GUICtrlCreateLabel( "", 198, 281, 90, 15, $ES_READONLY)
$Target_Device = GUICtrlCreateLabel( "", 295, 264, 85, 15, $ES_READONLY)
$Target_Type = GUICtrlCreateLabel( "", 295, 281, 89, 15, $ES_READONLY)

GUICtrlCreateLabel( "System Drive", 32, 315)
$WinDrv = GUICtrlCreateInput("", 110, 312, 40, 20, $ES_READONLY)
$WinDrvSel = GUICtrlCreateButton("...", 156, 313, 26, 18)
GUICtrlSetTip($WinDrv, " Select your USB System Drive - NTFS for VHD Or PE WIM file " & @CRLF _
& " VHD must be located on NTFS System Drive " & @CRLF _
& " PE WIM can be located on FAT32 Boot Drive Or on NTFS System Drive " & @CRLF _
& " GO will Make entry for VHD or PE WIM in Boot Manager Menu on Boot Drive ")
GUICtrlSetOnEvent($WinDrvSel, "_WinDrv_drive")
$WinDrvSize = GUICtrlCreateLabel( "", 198, 306, 100, 15, $ES_READONLY)
$WinDrvFree = GUICtrlCreateLabel( "", 198, 323, 100, 15, $ES_READONLY)
$Sys_Device = GUICtrlCreateLabel( "", 295, 306, 85, 15, $ES_READONLY)
$Sys_Type = GUICtrlCreateLabel( "", 295, 323, 89, 15, $ES_READONLY)

$GO = GUICtrlCreateButton("GO", 235, 360, 70, 30)
GUICtrlSetTip($GO,  " GO will Make entry for PE WIM Or VHD in Windows Boot Manager Menu " & @CRLF _
& " And for VHD with SVBus Driver make entry in Grub4dos Menu " & @CRLF _
& " And make entry in UEFI Grub2 and UEFI Grub4dos Menu " & @CRLF _
& " VHD must be located on NTFS System Drive " & @CRLF _
& " PE WIM can be located on FAT32 Boot Drive Or on NTFS System Drive ")
$EXIT = GUICtrlCreateButton("EXIT", 320, 360, 60, 30)
GUICtrlSetState($GO, $GUI_DISABLE)
GUICtrlSetOnEvent($GO, "_Go")
GUICtrlSetOnEvent($EXIT, "_Quit")

$ProgressAll = GUICtrlCreateProgress(16, 368, 203, 16, $PBS_SMOOTH)

$hStatus = _GUICtrlStatusBar_Create($hGuiParent, -1, "", $SBARS_TOOLTIPS)
Global $aParts[3] = [310, 350, -1]
_GUICtrlStatusBar_SetParts($hStatus, $aParts)

_GUICtrlStatusBar_SetText($hStatus," First Select USB Target Drives and then Sources", 0)

If FileExists(@ScriptDir & "\UEFI_MAN\EFI\Boot\MokManager.efi") And FileExists(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubx64_real.efi") Then
	GUICtrlSetData($Combo_EFI, "Super UEFI")
EndIf

DisableMenus(1)

GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
GUICtrlSetState($grldrUpd, $GUI_UNCHECKED + $GUI_DISABLE)

GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
GUICtrlSetState($Boot_w8, $GUI_UNCHECKED + $GUI_DISABLE)

GUICtrlSetState($g4d_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
GUICtrlSetState($xp_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)

GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
GUICtrlSetState($WinDrvSel, $GUI_ENABLE)

GUICtrlSetState($Menu_Type, $GUI_DISABLE)

GUISetState(@SW_SHOW)

If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" And $PE_flag = 0 Then
	; OK
Else
	If $PE_flag = 1 And @OSArch <> "X86" Then
		; PE OK
	Else
		If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch = "X86" Then
			MsgBox(48, "WARNING - OS Invalid to make x64 EFI Boot Manager ", "OS = " & @OSVersion & " " & @OSArch & "  " & $Firmware & @CRLF _
			& @CRLF & "Cannot make Windows x64 EFI Boot Manager " & @CRLF _
			& @CRLF & "Instead Use Win 10 x64 Or Win 8.1 x64 as OS" & @CRLF _
			& @CRLF & "Or Proceed with Windows x86 EFI Manager " & @CRLF _
			& @CRLF & "Or Select Super UEFI as Grub2 Manager ", 0)
		Else
			MsgBox(48, "WARNING - OS Invalid to make x64 EFI Boot Manager ", "OS = " & @OSVersion & " " & @OSArch & "  " & $Firmware & @CRLF _
			& @CRLF & "Cannot make Windows x64 EFI Boot Manager " & @CRLF _
			& @CRLF & "Instead Use Win 10 x64 Or Win 8.1 x64 as OS" & @CRLF _
			& @CRLF & "Or Proceed and Select Super UEFI as Grub2 Manager ", 0)
		EndIf
	EndIf
EndIf

;===================================================================================================
While 1
	CheckGo()
    Sleep(300)
WEnd   ;==> Loop
;===================================================================================================
Func CheckGo()

	If $WinDrvDrive <> "" And $TargetDrive <> "" Then
		GUICtrlSetState($GO, $GUI_ENABLE)
		If $btimgfile = "" Then
			_GUICtrlStatusBar_SetText($hStatus," Select Boot Image Or Use GO to Make Multi-Boot Drive", 0)
		Else
			_GUICtrlStatusBar_SetText($hStatus," Use GO to Make Multi-Boot USB-Drive", 0)
		EndIf
	Else
		If GUICtrlRead($GO) = $GUI_ENABLE Then
			GUICtrlSetState($GO, $GUI_DISABLE)
			_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
		EndIf
	EndIf
EndFunc ;==> _CheckGo
;===================================================================================================
Func _Mount_EFI()
	Local $TempDrives[4] = ["Z:", "Y:", "S:", "T:"], $AllDrives, $efi_drive = "Z:", $efi_temp_drive, $efi_valid = 0, $index_alldrives, $firm_val=0

	SystemFileRedirect("On")
	$Firmware = _WinAPI_GetFirmwareEnvironmentVariable()
	If $Firmware = "UEFI" Then
		$AllDrives = DriveGetDrive( "all" )

		;  _ArrayDisplay($AllDrives)

		FOR $efi_temp_drive IN $TempDrives
			If Not FileExists($efi_temp_drive & "\nul") Then
				$efi_valid = 1
				For $index_alldrives = 1 to $AllDrives[0]
					If $efi_temp_drive = $AllDrives[$index_alldrives] Then
						$efi_valid = 0
					;	MsgBox(48,"Invalid Drive " & $i, "Invalid Drive " & $AllDrives[$i])
					EndIf
				Next
				If $efi_valid Then
					$efi_drive = $efi_temp_drive
					ExitLoop
				EndIf
			Else
				$efi_valid = 0
			EndIf
		NEXT

		If $efi_valid Then
			$firm_val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\mountvol.exe " & $efi_drive & " /s", @ScriptDir, @SW_HIDE)
	;~ 			If $firm_val <> 0 Then
	;~ 				MsgBox(48, " Error Mounting EFI as Drive " & $efi_drive, " MountVol Error = " & $firm_val & @CRLF & @CRLF _
	;~ 				& " EFI Drive was Mounted already ")
	;~ 			EndIf
		Else
			MsgBox(48, " Unable to Mount EFI Drive ", " No Free Drive Letter Z Y S T " & @CRLF & @CRLF _
			& " Unable to Mount EFI Drive ", 3)
		EndIf
	EndIf
	SystemFileRedirect("Off")
EndFunc ;==> _Mount_EFI
;===================================================================================================
Func _Quit()
	Local $ikey
    If @GUI_WinHandle = $hGuiParent Then
		If Not $pausecopy Then DisableMenus(1)
	    GUICtrlSetState($EXIT, $GUI_DISABLE)
		$ikey = MsgBox(48+4+256, " STOP Program ", " STOP Program ? ")
		If $ikey = 6 Then
			Exit
		Else
			If Not $pausecopy Then DisableMenus(0)
			If $TargetDrive = "" Then
				DisableMenus(0)
			EndIf
			GUICtrlSetState($EXIT, $GUI_ENABLE)
			Return
		EndIf
    Else
        GUIDelete(@GUI_WinHandle)
    EndIf
EndFunc   ;==> _Quit
;===================================================================================================
Func SystemFileRedirect($Wow64Number)
	If @OSArch = "X64" Then
		Local $WOW64_CHECK = DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "ptr*", 0)
		If Not @error Then
			If $Wow64Number = "On" And $WOW64_CHECK[1] <> 1 Then
				DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "int", 1)
			ElseIf $Wow64Number = "Off" And $WOW64_CHECK[1] <> 0 Then
				DllCall("kernel32.dll", "int", "Wow64EnableWow64FsRedirection", "int", 1)
			EndIf
		EndIf
	EndIf
EndFunc   ;==> SystemFileRedirect
;===================================================================================================
Func _GetDrivePartitionStyle($sDrive = "C")
    Local $tDriveLayout = DllStructCreate('dword PartitionStyle;' & _
            'dword PartitionCount;' & _
            'byte union[40];' & _
            'byte PartitionEntry[8192]')
    Local $hDrive = DllCall("kernel32.dll", "handle", "CreateFileW", _
            "wstr", "\\.\" & $sDrive & ":", _
            "dword", 0, _
            "dword", 0, _
            "ptr", 0, _
            "dword", 3, _ ; OPEN_EXISTING
            "dword", 0, _
            "ptr", 0)
    If @error Or $hDrive[0] = Ptr(-1) Then Return SetError(@error, @extended, 0) ; INVALID_HANDLE_VALUE
    DllCall("kernel32.dll", "int", "DeviceIoControl", _
            "hwnd", $hDrive[0], _
            "dword", 0x00070050, _
            "ptr", 0, _
            "dword", 0, _
            "ptr", DllStructGetPtr($tDriveLayout), _
            "dword", DllStructGetSize($tDriveLayout), _
            "dword*", 0, _
            "ptr", 0)
    DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hDrive[0])
    Switch DllStructGetData($tDriveLayout, "PartitionStyle")
        Case 0
            Return "MBR"
        Case 1
            Return "GPT"
        Case 2
            Return "RAW"
        Case Else
            Return "UNKNOWN"
    EndSwitch
EndFunc   ;==>_GetDrivePartitionStyle
;===================================================================================================
Func _WinAPI_GetFirmwareEnvironmentVariable()
    DllCall("kernel32.dll", "dword", _
            "GetFirmwareEnvironmentVariableW", "wstr", "", _
            "wstr", "{00000000-0000-0000-0000-000000000000}", "wstr", "", "dword", 4096)
    Local $iError = DllCall("kernel32.dll", "dword", "GetLastError")
    Switch $iError[0]
        Case 1
            Return "LEGACY"
        Case 998
            Return "UEFI"
        Case Else
            Return "UEFI"
    EndSwitch
EndFunc   ;==>_WinAPI_GetFirmwareEnvironmentVariable
;===================================================================================================
Func _img_fsel()
	Local $len, $pos, $posfol, $img_fname="", $btpos, $valid=0, $pos3=0, $pos4=0, $pos5=0, $noxpmbr = 0, $pos1=0, $pos2=0

	DisableMenus(1)
	GUICtrlSetData($ImageType, "")
	GUICtrlSetData($ImageSize, "")
	GUICtrlSetData($IMG_File, "")
	GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
	$btimgfile = ""
	$vhdfolder = ""
	$vhdfile_name = ""
	$vhdfile_name_only = ""
	$image_file=""
	$img_fext=""
	$bootsdi = ""
	$BTIMGSize=0
	$img_folder = ""
	If FileExists(@ScriptDir & "\makebt\bs_temp") Then DirRemove(@ScriptDir & "\makebt\bs_temp",1)
	If Not FileExists(@ScriptDir & "\makebt\bs_temp") Then DirCreate(@ScriptDir & "\makebt\bs_temp")

	$btimgfile = FileOpenDialog("Select Boot Image File on USB Target Drive", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "Boot Image Files ( *.vhdx; *.vhd; *.wim; *.img; *.ima; *.iso; *.is_; *.im_; )")
	If @error Then
		$btimgfile = ""
		DisableMenus(0)
		Return
	EndIf

	If StringLeft($btimgfile, 2) <> $WinDrvDrive And StringLeft($btimgfile, 2) <> $TargetDrive Then
		MsgBox(48,"ERROR - Boot Image is Not on Boot Or System Drive", "Boot Image File Selection Invalid" & @CRLF & @CRLF & "Selected Boot Image File = " & $btimgfile & @CRLF & @CRLF _
		& "Copy Boot Image to Root Or Folder max 8 chars on " & @CRLF & @CRLF _
		& "USB Boot Drive " & $TargetDrive & "  Or  VHD on NTFS System Drive " & $WinDrvDrive)
		$btimgfile = ""
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($btimgfile, " ", 0, -1)
	If $pos Then
		MsgBox(48,"WARNING - Image Path FileName Invalid", "Image Path Invalid - Space Found" & @CRLF & @CRLF & "Selected Image = " & $btimgfile & @CRLF & @CRLF _
		& "Solution - Use simple Image Path without Spaces ")
		$btimgfile = ""
		DisableMenus(0)
		Return
	EndIf

	$len = StringLen($btimgfile)
	$pos = StringInStr($btimgfile, "\", 0, -1)
	$image_file = StringRight($btimgfile, $len-$pos)
	If $pos <> 3 Then
		$posfol = StringInStr($btimgfile, "\", 0, -2)
		If $posfol <> 3 Or $pos > 12 Then
			MsgBox(48,"ERROR - Boot Image File Selection Not Valid", "Boot Image Not in root Or rootfolder max 8 chars" & @CRLF & @CRLF & "Selected Boot Image = " & $btimgfile & @CRLF & @CRLF _
			& "Select Boot Image in folder max 8 chars Or in root of " & @CRLF & @CRLF _
			& "USB Boot Drive " & $TargetDrive & "  Or  System Drive " & $WinDrvDrive)
			$image_file = ""
			$btimgfile = ""
			DisableMenus(0)
			Return
		Else
			$img_folder = StringMid($btimgfile, 4, $pos - $posfol - 1)
		EndIf
	EndIf

	$len = StringLen($image_file)
	$pos = StringInStr($image_file, ".", 0, -1)
	$img_fext = StringRight($image_file, $len-$pos)
	$img_fname = StringLeft($image_file, $pos-1)
	If $img_fext = "iso" Or $img_fext = "is_" Then
		If $len > 30 Or StringRegExp($img_fname, "[^A-Z0-9a-z-_.]") Or StringRegExp($img_fext, "[^A-Za-z_]") Then
			MsgBox(48, " FileName NOT Valid ", "Selected = " & $image_file & @CRLF & @CRLF & "Max 26.3 FileName with  " & @CRLF & "Characters 0-9 A-Z a-z - _  ")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			DisableMenus(0)
			Return
		EndIf
	ElseIf $img_fext = "img" Or $img_fext = "im_" Or $img_fext = "ima" Then
		If $len > 12 Or StringRegExp($img_fname, "[^A-Z0-9a-z-_]") Or StringRegExp($img_fext, "[^A-Za-z_]") Then
			MsgBox(48, " File or FileName NOT Valid ", "Selected = " & $image_file & @CRLF & @CRLF _
			& "IMG FileNames must be conform DOS 8.3 " & @CRLF & "Allowed Characters 0-9 A-Z a-z - _  ")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			DisableMenus(0)
			Return
		EndIf
	Else
	EndIf
	$BTIMGSize = FileGetSize($btimgfile)
	$BTIMGSize = Round($BTIMGSize / 1024 / 1024)
	GUICtrlSetData($ImageSize, $BTIMGSize & " MB")

	If $img_fext = "vhd" Or $img_fext = "vhdx" Then
		If StringLeft($btimgfile, 2) <> $WinDrvDrive Then
			MsgBox(48,"ERROR - VHD is Not on System Drive", "VHD File Selection Invalid" & @CRLF & @CRLF & "Selected VHD File = " & $btimgfile & @CRLF & @CRLF _
			& "Copy VHD to Root Or Folder max 8 chars on System Drive " & $WinDrvDrive)
			GUICtrlSetData($ImageSize, "")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			$BTIMGSize=0
			$img_folder = ""
			DisableMenus(0)
			Return
		EndIf
		If $img_fext = "vhdx" Then
			If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" Then
				; OK
			Else
				MsgBox(48,"ERROR - Old Windows Version", "VHDX Only Supported in Win 8/10" & @CRLF & @CRLF & "Selected VHD File = " & $btimgfile)
				GUICtrlSetData($ImageSize, "")
				$image_file = ""
				$img_fext=""
				$btimgfile = ""
				$BTIMGSize=0
				$img_folder = ""
				DisableMenus(0)
				Return
			EndIf
		EndIf

		$pos = StringInStr($btimgfile, "\", 0, -1)
		If $pos <> 3 Then
			$posfol = StringInStr($btimgfile, "\", 0, -2)
			If $posfol <> 3 Or $pos > 12 Then
				MsgBox(48,"ERROR - VHD File Selection Not Valid", "VHD Not in root Or rootfolder max 8 chars" & @CRLF & @CRLF & "Selected VHD File = " & $btimgfile & @CRLF & @CRLF _
				& "Select VHD in folder max 8 chars Or in root of System Drive " & $WinDrvDrive)
				GUICtrlSetData($ImageSize, "")
				$image_file = ""
				$img_fext=""
				$btimgfile = ""
				$BTIMGSize=0
				$img_folder = ""
				DisableMenus(0)
				Return
			Else
				$vhdfolder = StringMid($btimgfile, 4, $pos - $posfol - 1)
				$vhdfile_name = StringMid($btimgfile, $posfol + 1)
				$vhdfile_name_only = StringMid($btimgfile, $pos + 1)
			EndIf
		Else
			$vhdfile_name = StringMid($btimgfile, 4)
			$vhdfile_name_only = StringMid($btimgfile, $pos + 1)
		EndIf

		$valid = 1
		GUICtrlSetData($ImageType, "VHD - IMG")
		If StringLeft($vhdfile_name_only, 2) = "XP" Then
			GUICtrlSetData($Menu_Type,"XP - WinVBlock")
		Else
			GUICtrlSetData($Menu_Type,"10 - SVBus")
		EndIf
		If @OSVersion <> "WIN_VISTA" And @OSVersion <> "WIN_2003" And @OSVersion <> "WIN_XP" And @OSVersion <> "WIN_XPe" And @OSVersion <> "WIN_2000" Then
			If StringLeft($vhdfile_name_only, 2) = "XP" Then
				GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
			Else
				GUICtrlSetState($Boot_vhd, $GUI_CHECKED + $GUI_ENABLE)
			EndIf
		EndIf
	ElseIf $img_fext = "iso" Or $img_fext = "is_" Then
		If $PartStyle = "GPT" Then
			MsgBox(48,"ERROR - GPT as Boot Drive Not Valid", "Grub4dos Not supported for GPT Drive" & @CRLF & @CRLF & "Selected ISO File = " & $btimgfile & @CRLF & @CRLF _
			& "Select MBR Boot Drive " & @CRLF & @CRLF _
			& "Boot Drive = " & $TargetDrive & "    System Drive = " & $WinDrvDrive)
			GUICtrlSetData($ImageSize, "")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			$BTIMGSize=0
			$img_folder = ""
			DisableMenus(0)
			Return
		EndIf

		RunWait(@ComSpec & " /c makebt\dsfo.exe " & '"' & $btimgfile & '"' & " 43008 512 makebt\bs_temp\iso_43008_512.bs", @ScriptDir, @SW_HIDE)
		$pos3 = HexSearch(@ScriptDir & "\makebt\bs_temp\iso_43008_512.bs", "WINSXS", 16, 0)
		If $pos3 Then
			If StringLeft($btimgfile, 2) <> $TargetDrive Then
				MsgBox(48,"ERROR - BartPE ISO is Not on USB Boot Drive", "ISO File Selection Invalid" & @CRLF & @CRLF & "Selected ISO File = " & $btimgfile & @CRLF & @CRLF _
				& "Copy ISO to Root Or Folder max 8 chars on Boot Drive " & $TargetDrive)
				GUICtrlSetData($ImageSize, "")
				$image_file = ""
				$img_fext=""
				$btimgfile = ""
				$BTIMGSize=0
				$img_folder = ""
				DisableMenus(0)
				Return
			EndIf
			GUICtrlSetData($ImageType, "BartPE - ISO")
			If $BTIMGSize < 500 Then $valid = 1
		Else
			If StringLeft($btimgfile, 2) <> $WinDrvDrive And StringLeft($btimgfile, 2) <> $TargetDrive Then
				MsgBox(48,"ERROR - ISO is Not on USB Boot Or System Drive", "ISO File Selection Invalid" & @CRLF & @CRLF & "Selected ISO File = " & $btimgfile & @CRLF & @CRLF _
				& "Copy ISO to Root Or Folder max 8 chars on " & @CRLF & @CRLF _
				& "Boot Drive " & $TargetDrive & "  Or  System Drive " & $WinDrvDrive)
				GUICtrlSetData($ImageSize, "")
				$image_file = ""
				$img_fext=""
				$btimgfile = ""
				$BTIMGSize=0
				$img_folder = ""
				DisableMenus(0)
				Return
			EndIf
			$pos4 = HexSearch(@ScriptDir & "\makebt\bs_temp\iso_43008_512.bs", "SOURCES", 16, 0)
			If $pos4 Then
				GUICtrlSetData($ImageType, "WinPE - ISO")
				If $BTIMGSize < 2000 Then $valid = 1
			Else
				GUICtrlSetData($ImageType, "CD - ISO")
				$valid = 1
			EndIf
		EndIf
	ElseIf $img_fext = "wim" Then
		SystemFileRedirect("On")
		If FileExists(@WindowsDir & "\system32\bcdedit.exe") Then
			$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
		Else
			GUICtrlSetData($ImageType, "")
			GUICtrlSetData($ImageSize, "")
			GUICtrlSetData($IMG_File, "")
			$btimgfile = ""
			$image_file=""
			$img_fext=""
			$bootsdi = ""
			$BTIMGSize=0
			$img_folder = ""
			SystemFileRedirect("Off")
			MsgBox(48, "WARNING - bcdedit.exe is missing ", "Unable to Add WIM to Boot Manager Menu " & @CRLF & @CRLF _
			& "Need Windows 7/8/10 Or PE to Add WIM to Boot Manager " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or PE ", 5)
			DisableMenus(0)
			Return
		EndIf
		If StringLeft($btimgfile, 2) <> $WinDrvDrive And StringLeft($btimgfile, 2) <> $TargetDrive Then
			MsgBox(48,"ERROR - WIM is Not on USB Boot Or System Drive", "WIM File Selection Invalid" & @CRLF & @CRLF & "Selected WIM File = " & $btimgfile & @CRLF & @CRLF _
			& "Copy WIM to Root Or Folder max 8 chars on " & @CRLF & @CRLF _
			& "Boot Drive " & $TargetDrive & "  Or  System Drive " & $WinDrvDrive)
			GUICtrlSetData($ImageSize, "")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			$BTIMGSize=0
			$img_folder = ""
			DisableMenus(0)
			Return
		EndIf
		MsgBox(48, " Info - boot.sdi Ramdisk File is needed ", "Continue with OK and use the FileSelector " & @CRLF & @CRLF _
		& "Select your boot.sdi Ramdisk File in Boot Or WinPE folder " & @CRLF & @CRLF _
		& "If Cancel then Windows\Boot\DVD\PCAT\boot.sdi can be used ", 0)
		$bootsdi = FileOpenDialog("Select boot.sdi Ramdisk File in Boot Or WinPE folder", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "RAMDISK boot.sdi File ( *.sdi; )")
		If @error Or $bootsdi = "" Then
			$bootsdi = ""
			If FileExists(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi") Then
				$windows_bootsdi = @WindowsDir & "\Boot\DVD\PCAT\boot.sdi"
			ElseIf FileExists(@WindowsDir & "\system32\boot.sdi") Then
				$windows_bootsdi = @WindowsDir & "\system32\boot.sdi"
			Else
				MsgBox(48, "WARNING - boot.sdi Not found ", "Boot\boot.sdi Ramdisk File may be needed " & @CRLF & @CRLF _
				& " Next time Boot with Windows 7/8/10 or 7/8/10 PE ")
			EndIf
		EndIf
		SystemFileRedirect("Off")
		; MsgBox(48, "wim selected", "$bootsdi = " & $bootsdi & "  $windows_bootsdi = " & $windows_bootsdi)

		$valid = 1
		GUICtrlSetData($ImageType, "WinPE - WIM")
	Else
		If $PartStyle = "GPT" Then
			MsgBox(48,"ERROR - GPT as Boot Drive Not Valid", "Grub4dos Not supported for GPT Drive" & @CRLF & @CRLF & "Selected ISO File = " & $btimgfile & @CRLF & @CRLF _
			& "Select MBR Boot Drive " & @CRLF & @CRLF _
			& "Boot Drive = " & $TargetDrive & "    System Drive = " & $WinDrvDrive)
			GUICtrlSetData($ImageSize, "")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			$BTIMGSize=0
			$img_folder = ""
			DisableMenus(0)
			Return
		EndIf

		If StringLeft($btimgfile, 2) <> $TargetDrive Then
			MsgBox(48,"ERROR - IMG is Not on USB Boot Drive", "IMG File Selection Invalid" & @CRLF & @CRLF & "Selected IMG File = " & $btimgfile & @CRLF & @CRLF _
			& "Copy IMG to Root Or Folder max 8 chars on Boot Drive " & $TargetDrive)
			GUICtrlSetData($ImageSize, "")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			$BTIMGSize=0
			$img_folder = ""
			DisableMenus(0)
			Return
		EndIf

		RunWait(@ComSpec & " /c makebt\dsfo.exe " & '"' & $btimgfile & '"' & " 0 512 makebt\bs_temp\img_512.bs", @ScriptDir, @SW_HIDE)
		$pos1 = HexSearch(@ScriptDir & "\makebt\bs_temp\img_512.bs", "NTFS", 16, 0)
		$pos2 = HexSearch(@ScriptDir & "\makebt\bs_temp\img_512.bs", "FAT", 16, 0)
		If $pos1 Or $pos2 Then
			If $BTIMGSize >= 500 And $BTIMGSize < 3600 Then
				$valid = 0
				MsgBox(48, " WARNING - SuperFloppy Image - MBR is missing ", "Selected = " & $btimgfile & @CRLF & @CRLF _
				& "Image Size = " & $BTIMGSize & " MB " & @CRLF & @CRLF _
				& "SuperFloppy Image - NTFS or FAT in BootSector Found " & @CRLF & @CRLF _
				& "Image Not Bootable from FiraDisk RAMDISK ", 0)
				GUICtrlSetData($ImageSize, "")
				$image_file = ""
				$img_fext=""
				$btimgfile = ""
				$BTIMGSize=0
				$img_folder = ""
				DisableMenus(0)
				Return
			EndIf
			; FAT BootSector
			If $pos2 = 55 Then
				$btpos = HexSearch(@ScriptDir & "\makebt\bs_temp\img_512.bs", "NTLDR", 16, 0)
				If $btpos = 418 And $BTIMGSize < 16 Then
					GUICtrlSetData($ImageType, "XP Rec Cons - IMG")
					$valid = 1
				EndIf
				$btpos = HexSearch(@ScriptDir & "\makebt\bs_temp\img_512.bs", "SETUPLDRBIN", 16, 0)
				If $btpos = 418 And $BTIMGSize < 16 Then
					GUICtrlSetData($ImageType, "XP Rec Cons - IMG")
					$valid = 1
				EndIf
				$btpos = HexSearch(@ScriptDir & "\makebt\bs_temp\img_512.bs", "KERNEL  SYS", 16, 0)
				If $btpos = 498 And $BTIMGSize < 16 Then
					GUICtrlSetData($ImageType, "FreeDOS - IMG")
					$valid = 1
				EndIf
				$btpos = HexSearch(@ScriptDir & "\makebt\bs_temp\img_512.bs", "IO      SYS", 16, 0)
				If $btpos = 473 And $BTIMGSize < 26 Then
					GUICtrlSetData($ImageType, "MS-DOS - IMG")
					$valid = 1
				EndIf
			EndIf
			; NTFS BootSector
			If $pos1 = 4 And Not $valid Then
				GUICtrlSetData($ImageType, "LiveXP BootSDI - IMG")
				If $BTIMGSize < 500 Then $valid = 1
			EndIf
		Else
			; Unknown Boot Image
			$valid = 0
		EndIf
	EndIf

	$FSvar_WinDrvDrive = DriveGetFileSystem($WinDrvDrive)

	If $FSvar_WinDrvDrive = "FAT32" And $BTIMGSize > 4000 Then
		MsgBox(48, "WARNING -FAT32 limit is 4 GB", "Image Size = " & $BTIMGSize & " MB " _
		& @CRLF & @CRLF & "System Drive " & $WinDrvDrive & " has FileSystem " & $FSvar_WinDrvDrive _
		& @CRLF & @CRLF & "NTFS FileSystem needed for Size > 4 GB ")
		$valid = 0
		GUICtrlSetData($ImageSize, "")
		GUICtrlSetData($ImageType, "")
		GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
		$vhdfolder = ""
		$vhdfile_name = ""
		$vhdfile_name_only = ""
		$image_file = ""
		$img_fext=""
		$btimgfile = ""
		$BTIMGSize=0
		$img_folder = ""
		DisableMenus(0)
		Return
	EndIf

	If GUICtrlRead($ImageType) = "VHD - IMG" And $img_fext = "vhd" Then
		If $FSvar_WinDrvDrive = "FAT32" Then
			MsgBox(48, "WARNING - Only Booting as RAMDISK supported", "VHD requires NTFS for Booting as FILEDISK " _
			& @CRLF & @CRLF & "System Drive " & $WinDrvDrive & " has FileSystem " & $FSvar_WinDrvDrive _
			& @CRLF & @CRLF & "VHD Booting from RAMDISK is supported ")
		EndIf
	EndIf

	If GUICtrlRead($ImageType) = "LiveXP BootSDI - IMG" Or GUICtrlRead($ImageType) = "BartPE - ISO" Or GUICtrlRead($ImageType) = "XP Rec Cons - IMG" Then
		If Not FileExists(@ScriptDir & "\makebt\srsp1\setupldr.bin") Then
			MsgBox(48, "WARNING - Missing Server 2003 SP1 Files setupldr.bin", "Files \makebt\srsp1\setupldr.bin NOT Found " _
			& @CRLF & @CRLF & "Copy File Winbuilder\Workbench\Common\BootSDI\setupldr.bin " _
			& @CRLF & @CRLF & "And ramdisk.sys to makebt\srsp1 folder ")
			$valid = 0
			GUICtrlSetData($ImageSize, "")
			GUICtrlSetData($ImageType, "")
			$image_file = ""
			$img_fext=""
			$btimgfile = ""
			$BTIMGSize=0
			$img_folder = ""
			DisableMenus(0)
			Return
		EndIf
	EndIf

	If GUICtrlRead($ImageType) = "LiveXP BootSDI - IMG" Then
		$pos2 = StringInStr($btimgfile, "\", 0, -2)
		If $pos2 Then
			If FileExists(StringLeft($btimgfile, $pos2) & "WIMs") Then
				MsgBox(48, " WIMs Folder Found - BootSDI.img NOT Valid as RAMBOOT IMAGE ", "Selected Image = " & $btimgfile & @CRLF & @CRLF _
				& "Use LiveXP_RAM.iso File containing WIMs as RAMBOOT IMAGE " & @CRLF & @CRLF _
				& "Or Make BootSDI.img without using WimPack in WinBuilder ")
				$valid = 0
				GUICtrlSetData($ImageSize, "")
				GUICtrlSetData($ImageType, "")
				$image_file = ""
				$img_fext=""
				$btimgfile = ""
				$BTIMGSize=0
				$img_folder = ""
				DisableMenus(0)
				Return
			EndIf
		EndIf
		If $BTIMGSize < 5 Then $valid = 0
	EndIf

	If $valid Then
		GUICtrlSetData($IMG_File, $btimgfile)
		GUICtrlSetData($ImageSize, $BTIMGSize & " MB")
		GUICtrlSetState($GO, $GUI_FOCUS)
	Else
		MsgBox(48, " Image File NOT Supported ", "Selected = " & $image_file & @CRLF & @CRLF _
		& "Image Size = " & $BTIMGSize & " MB " & @CRLF & @CRLF _
		& "Incompatible Image Type ")
		GUICtrlSetData($ImageSize, "")
		GUICtrlSetData($ImageType, "")
		GUICtrlSetData($IMG_File, "")
		$image_file = ""
		$img_fext=""
		$btimgfile = ""
		$BTIMGSize=0
		$img_folder = ""
	EndIf
	DisableMenus(0)
EndFunc   ;==> _img_fsel
;===================================================================================================
Func _target_drive()
	Local $TargetSelect, $Tdrive, $FSvar, $valid = 0, $ValidDrives, $RemDrives
	Local $NoDrive[3] = ["A:", "B:", "X:"], $FileSys[2] = ["NTFS", "FAT32"]
	Local $pos, $fs_ok=0

	$DriveType="Fixed"
	DisableMenus(1)
	GUICtrlSetState($GO, $GUI_DISABLE)
	$ValidDrives = DriveGetDrive( "FIXED" )
	_ArrayPush($ValidDrives, "")
	_ArrayPop($ValidDrives)
	$RemDrives = DriveGetDrive( "REMOVABLE" )
	_ArrayPush($RemDrives, "")
	_ArrayPop($RemDrives)
	_ArrayConcatenate($ValidDrives, $RemDrives)
	; _ArrayDisplay($ValidDrives)

	$PartStyle = "MBR"
	$TargetDrive = ""
	$FSvar=""
	$TargetSpaceAvail = 0
	$Target_MBR_FAT32 = 0
	GUICtrlSetData($Target, "")
	GUICtrlSetData($TargetSize, "")
	GUICtrlSetData($TargetFree, "")
	GUICtrlSetData($Target_Device, "")
	GUICtrlSetData($Target_Type, "")
	GUICtrlSetData($Combo_Folder,"Folder on B")

	$TargetSelect = FileSelectFolder("Select your USB Boot Drive - Active Drive for Boot Files", "")
	If @error Then
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		; DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($TargetSelect, "\", 0, -1)
	If $pos = 0 Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - No Backslash Found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		; DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($TargetSelect, " ", 0, -1)
	If $pos Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - Space Found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect & @CRLF & @CRLF _
		& "Solution - Use simple Path without Spaces ")
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		; DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($TargetSelect, ":", 0, 1)
	If $pos <> 2 Then
		MsgBox(48,"ERROR - Path Invalid", "Drive Invalid - : Not found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		; DisableMenus(0)
		Return
	EndIf

	$Tdrive = StringLeft($TargetSelect, 2)
	FOR $d IN $ValidDrives
		If $d = $Tdrive Then
			$valid = 1
			ExitLoop
		EndIf
	NEXT
	FOR $d IN $NoDrive
		If $d = $Tdrive Then
			$valid = 0
			MsgBox(48, "ERROR - Drive NOT Valid", " Drive A: B: and X: NOT Valid as Boot Drive ", 3)
			; DisableMenus(0)
			GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
			GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
			Return
		EndIf
	NEXT
	If $valid And DriveStatus($Tdrive) <> "READY" Then
		$valid = 0
		; MsgBox(48, "ERROR - Drive NOT Ready", "Drive NOT READY", 3)
		MsgBox(48, "WARNING - Drive NOT Ready", "Drive NOT READY " & @CRLF & @CRLF & "First Format Target Boot Drive  ", 0)
		; DisableMenus(0)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		Return
	EndIf
	If Round(DriveSpaceTotal($Tdrive)) < 100 Then
		$valid = 0
		MsgBox(48, "ERROR - Drive Size Less 100 MB", "Selected Drive is too small " & @CRLF _
		& @CRLF & "Drive Size = " & Round(DriveSpaceTotal($Tdrive)) & " MB " & @CRLF _
		& @CRLF & "In Win 8/10 Make FAT32 Boot partition at least 100 MB ")
		; DisableMenus(0)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		Return
	EndIf
	If $valid Then
		; $DriveType=DriveGetType($Tdrive)
		$FSvar = DriveGetFileSystem( $Tdrive )
		FOR $d IN $FileSys
			If $d = $FSvar Then
				$fs_ok = 1
				ExitLoop
			Else
				$fs_ok = 0
			EndIf
		NEXT
		IF Not $fs_ok Then
			MsgBox(48, "WARNING - Invalid FileSystem", "NTFS Or FAT32 FileSystem NOT Found" & @CRLF _
			& @CRLF & "Continue and First Format Target Boot Drive ", 3)
			GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
			GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
			Return
		EndIf
	EndIf
	$PartStyle = _GetDrivePartitionStyle(StringLeft($Tdrive, 1))
	If $PartStyle = "RAW" Then
		$valid = 0
		MsgBox(48, "ERROR - Drive NOT Valid", "Selected Drive is RAW" & @CRLF _
		& @CRLF & "Continue and First Format Target Boot Drive ", 3)
		; DisableMenus(0)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		Return
	EndIf
	If $PartStyle = "UNKNOWN" Then
		$valid = 0
		MsgBox(48, "ERROR - Drive NOT Valid", "Selected Drive is UNKNOWN" & @CRLF _
		& @CRLF & "Make Partition and First Format Target Boot Drive ", 3)
		; DisableMenus(0)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		Return
	EndIf
	If $valid Then
		$TargetDrive = $Tdrive
		GUICtrlSetData($Target, $TargetDrive)
		$TargetSpaceAvail = Round(DriveSpaceFree($TargetDrive))
		$PartStyle = _GetDrivePartitionStyle(StringLeft($TargetDrive, 1))
		GUICtrlSetData($TargetSize, $FSvar & "    " & Round(DriveSpaceTotal($TargetDrive) / 1024, 1) & " GB")
		GUICtrlSetData($TargetFree, "FREE  = " & Round(DriveSpaceFree($TargetDrive) / 1024, 1) & " GB")
		$Firmware = _WinAPI_GetFirmwareEnvironmentVariable()
		If $FSvar <> "FAT32" And $Firmware = "UEFI" And $PartStyle = "MBR" Then
			MsgBox(48, "WARNING - Boot Drive OK for BIOS ", "Target Boot Drive has " & $FSvar & " - OK for BIOS only " & @CRLF _
			& @CRLF & "UEFI Firmware needs FAT32 Target Boot Drive" & @CRLF _
			& @CRLF & "Firmware = " & $Firmware & "     Drive = " & $PartStyle & "    " & DriveGetType($TargetDrive, 3) & "   " & StringLeft(DriveGetType($TargetDrive), 5) & "   " & DriveGetType($TargetDrive, 2))
		EndIf
		; MsgBox(64, "Partition Style and Firmware", "Partition Style = " & $PartStyle & @CRLF _
		; & @CRLF & "Firmware = " & $Firmware)
		If FileExists($TargetDrive & "\ventoy") Then
			$ventoy = 1
			GUICtrlSetData($Combo_Folder,"Folder on S")
		EndIf
		If $FSvar = "FAT32" And $PartStyle = "MBR" Then
			$Target_MBR_FAT32 = 1
		EndIf
		If $WinDrvDrive <> "" And $TargetDrive <> "" Then
			_ListUsb_UEFI()
		EndIf
		$FSvar_TargetDrive = DriveGetFileSystem($TargetDrive)
		GUICtrlSetState($WinDrvSel, $GUI_FOCUS)
	EndIf
	If Not CheckSize() Then
		MsgBox(48, "ERROR - System Drive NOT Valid", " NOT Enough FreeSpace")
		$TargetDrive = ""
		$TargetSpaceAvail = 0
		GUICtrlSetData($Target, "")
		GUICtrlSetData($TargetSize, "")
		GUICtrlSetData($TargetFree, "")
	EndIf
	_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
	DisableMenus(0)
EndFunc   ;==> _target_drive
;===================================================================================================
Func _WinDrv_drive()
	Local $WinDrvSelect, $Tdrive, $FSvar, $valid = 0, $ValidDrives, $RemDrives
	Local $NoDrive[3] = ["A:", "B:", "X:"], $FileSys[2] = ["NTFS", "FAT32"]
	Local $pos

	DisableMenus(1)
	$ValidDrives = DriveGetDrive( "FIXED" )
	_ArrayPush($ValidDrives, "")
	_ArrayPop($ValidDrives)
	$RemDrives = DriveGetDrive( "REMOVABLE" )
	_ArrayPush($RemDrives, "")
	_ArrayPop($RemDrives)
	_ArrayConcatenate($ValidDrives, $RemDrives)
	; _ArrayDisplay($ValidDrives)

	$WinDrvDrive = ""
	GUICtrlSetData($WinDrv, "")
	GUICtrlSetData($WinDrvFileSys, "")
	GUICtrlSetData($WinDrvSize, "")
	GUICtrlSetData($WinDrvFree, "")
	GUICtrlSetData($Sys_Device, "")
	GUICtrlSetData($Sys_Type, "")

	GUICtrlSetState($Boot_w8, $GUI_UNCHECKED + $GUI_DISABLE)
	$w78sys=0

	$WinDrvSelect = FileSelectFolder("Select your USB System Drive - NTFS for VHD or 7/8 System", "")
	If @error Then
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)
		GUICtrlSetState($TargetSel, $GUI_ENABLE)
		; DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($WinDrvSelect, "\", 0, -1)
	If $pos = 0 Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - No Backslash Found" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)
		GUICtrlSetState($TargetSel, $GUI_ENABLE)
		; DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($WinDrvSelect, " ", 0, -1)
	If $pos Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - Space Found" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect & @CRLF & @CRLF _
		& "Solution - Use simple Path without Spaces ")
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)
		GUICtrlSetState($TargetSel, $GUI_ENABLE)
		; DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($WinDrvSelect, ":", 0, 1)
	If $pos <> 2 Then
		MsgBox(48,"ERROR - Path Invalid", "Drive Invalid - : Not found" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)
		GUICtrlSetState($TargetSel, $GUI_ENABLE)
		; DisableMenus(0)
		Return
	EndIf

	$Tdrive = StringLeft($WinDrvSelect, 2)
	FOR $d IN $ValidDrives
		If $d = $Tdrive Then
			$valid = 1
			ExitLoop
		EndIf
	NEXT
	FOR $d IN $NoDrive
		If $d = $Tdrive Then
			$valid = 0
			MsgBox(48, "ERROR - Drive NOT Valid", " Drive A: B: and X: ", 3)
			; DisableMenus(0)
			GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)
			GUICtrlSetState($TargetSel, $GUI_ENABLE)
			Return
		EndIf
	NEXT
	If $valid And DriveStatus($Tdrive) <> "READY" Then
		$valid = 0
		MsgBox(48, "ERROR - Drive NOT Ready", "Drive NOT READY", 3)
		; DisableMenus(0)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)
		GUICtrlSetState($TargetSel, $GUI_ENABLE)
		Return
	EndIf
	If $valid Then
		$FSvar = DriveGetFileSystem( $Tdrive )
		FOR $d IN $FileSys
			If $d = $FSvar Then
				$WinDrvFileSys = $d
				$valid = 1
				ExitLoop
			Else
				$valid = 0
			EndIf
		NEXT
		IF Not $valid Then
			MsgBox(48, "ERROR - Invalid FileSystem", " NTFS or FAT32 FileSystem NOT Found ", 3)
			; DisableMenus(0)
			GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)
			GUICtrlSetState($TargetSel, $GUI_ENABLE)
			Return
		EndIf
	EndIf
	If $valid Then
		$WinDrvDrive = StringLeft($WinDrvSelect, 2)

		GUICtrlSetData($WinDrv, $WinDrvDrive)
		$WinDrvSpaceAvail = Round(DriveSpaceFree($WinDrvDrive))
		GUICtrlSetData($WinDrvSize, $FSvar & "     " & Round(DriveSpaceTotal($WinDrvDrive) / 1024, 1) & " GB")
		GUICtrlSetData($WinDrvFree, "FREE  = " & Round(DriveSpaceFree($WinDrvDrive) / 1024, 1) & " GB")
		$SysStyle = _GetDrivePartitionStyle(StringLeft($WinDrvDrive, 1))

		If $WinDrvDrive <> "" And $TargetDrive <> "" Then
			_ListUsb_UEFI()
		EndIf
		If @OSVersion <> "WIN_VISTA" And @OSVersion <> "WIN_2003" And @OSVersion <> "WIN_XP" And @OSVersion <> "WIN_XPe" And @OSVersion <> "WIN_2000" Then
			SystemFileRedirect("On")
			If FileExists($WinDrvDrive & $WinFol & "\system32\bcdboot.exe") And FileExists($WinDrvDrive & $WinFol & "\Boot") And FileExists($WinDrvDrive & $WinFol & "\System32\DriverStore\FileRepository") Then
				GUICtrlSetState($Boot_w8, $GUI_UNCHECKED + $GUI_ENABLE)
				$w78sys=1
			EndIf
			SystemFileRedirect("Off")
		EndIf
		GUICtrlSetState($IMG_FileSelect, $GUI_FOCUS)

		;	If $FSvar <> "NTFS" Then
		;		MsgBox(48, "WARNING - Target System Drive is NOT NTFS ", "Target System Drive has " & $FSvar & " FileSystem " & @CRLF _
		;		& @CRLF & "OK for USB-Stick booting WIM or ISO " & @CRLF _
		;		& @CRLF & "VHD needs NTFS Target System Drive ")
		;	EndIf

	EndIf
	DisableMenus(0)
EndFunc   ;==> _WinDrv_drive
;===================================================================================================
Func _wim_menu()
	Local $val=0, $len, $pos, $img_fname="", $sdi_file = ""
	Local $guid, $guid_def = "", $pos1, $pos2, $ramdisk_guid = "", $pe_guid = "", $efi_pe_guid = "", $efi_ramdisk_guid = ""
	Local $file, $line

	; already set in _GO
	; SystemFileRedirect("On")

	; MsgBox(48, "wim_menu", "$bootsdi = "& $bootsdi & "  $windows_bootsdi = "& $windows_bootsdi)

	If FileExists(@WindowsDir & "\system32\bcdedit.exe") Then
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
	Else
		MsgBox(48, "WARNING - bcdedit.exe is missing ", "Unable to Add WIM to Boot Manager Menu " & @CRLF & @CRLF _
		& "Need Windows 7/8/10 Or 7/8/10 PE to Add WIM to Boot Manager " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 7/8/10 PE ", 5)
		Return
	EndIf

	$len = StringLen($image_file)
	$pos = StringInStr($image_file, ".", 0, -1)
	; $img_fext = StringRight($image_file, $len-$pos)
	$img_fname = StringLeft($image_file, $pos-1)

	If $bootsdi <> "" Then
		$len = StringLen($bootsdi)
		$pos = StringInStr($bootsdi, "\", 0, -1)
		$sdi_file = StringRight($bootsdi, $len-$pos)
	ElseIf $windows_bootsdi <> "" Then
		$len = StringLen($windows_bootsdi)
		$pos = StringInStr($windows_bootsdi, "\", 0, -1)
		$sdi_file = StringRight($windows_bootsdi, $len-$pos)
	Else
		$sdi_file = "boot.sdi"
	EndIf

	If $WimOnSystemDrive = 1 Then
		$len = StringLen($btimgfile)
		$pos = StringInStr($btimgfile, "\", 0, -1)
		$sdi_path = StringMid(StringLeft($btimgfile, $pos), 3)
		; MsgBox(48, "sdipath", $WinDrvDrive & $sdi_path & $sdi_file)

		If Not FileExists($WinDrvDrive & $sdi_path & $sdi_file) Then
			If $bootsdi <> "" Then
				FileCopy($bootsdi, $WinDrvDrive & $sdi_path, 1)
			ElseIf $windows_bootsdi <> "" Then
				FileCopy($windows_bootsdi, $WinDrvDrive & $sdi_path, 1)
			Else
			EndIf
		EndIf
	Else
		$len = StringLen($btimgfile)
		$pos = StringInStr($btimgfile, "\", 0, -1)
		$sdi_path = StringMid(StringLeft($btimgfile, $pos), 3)
		; MsgBox(48, "sdipath", $WinDrvDrive & $sdi_path & $sdi_file)

		If Not FileExists($TargetDrive & "\Boot\" & $sdi_file) Then
			If $bootsdi <> "" Then
				FileCopy($bootsdi, $TargetDrive & "\Boot\", 9)
			ElseIf $windows_bootsdi <> "" Then
				FileCopy($windows_bootsdi, $TargetDrive & "\Boot\", 9)
			Else
			EndIf
		EndIf
	EndIf

	; save deault bcd setting in $guid_def
	If FileExists($TargetDrive & "\Boot\BCD") Then
		$store = $TargetDrive & "\Boot\BCD"
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /enum {default} /v > makebt\bs_temp\bcd_default_out.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\bcd_default_out.txt", 0)
		$line = FileReadLine($file, 4)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 Then
			$guid_def = StringMid($line, $pos1, $pos2-$pos1+1)
		EndIf
	EndIf

	; Add boot.wim - 7/8 Recovery or WinPE booting from RAMDISK

	_GUICtrlStatusBar_SetText($hStatus," Add " & $image_file & " to Boot Manager on Boot Drive " & $TargetDrive & " - wait .... ", 0)
	sleep(1000)

	$store = $TargetDrive & "\Boot\BCD"
	If Not FileExists($TargetDrive & "\Boot\BCD") And $PartStyle = "MBR" Then
		DirCopy(@WindowsDir & "\Boot\PCAT", $TargetDrive & "\Boot", 1)
		DirCopy(@WindowsDir & "\Boot\Fonts", $TargetDrive & "\Boot\Fonts", 1)
		DirCopy(@WindowsDir & "\Boot\Resources", $TargetDrive & "\Boot\Resources", 1)
		If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi") Then
			FileCopy(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi", $TargetDrive & "\Boot\", 1)
		EndIf
		sleep(1000)
		FileMove($TargetDrive & "\Boot\bootmgr", $TargetDrive & "\bootmgr", 1)
		FileMove($TargetDrive & "\Boot\bootnxt", $TargetDrive & "\BOOTNXT", 1)
		sleep(1000)
		If Not FileExists($TargetDrive & "\bootmgr") And FileExists($OS_drive & "\bootmgr") Then
			FileCopy($OS_drive & "\bootmgr", $TargetDrive & "\", 1)
		EndIf

		RunWait(@ComSpec & " /c " & $bcdedit & " /createstore " & $store, $TargetDrive & "\", @SW_HIDE)
		sleep(1000)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {bootmgr}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} description " & '"' & "Boot Manager" & '"', $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 20", $TargetDrive & "\", @SW_HIDE)
		sleep(1000)
	EndIf
	If FileExists($TargetDrive & "\Boot\BCD") And $PartStyle = "MBR" Then
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create /device > makebt\bs_temp\sdi_guid.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\sdi_guid.txt", 0)
		$line = FileReadLine($file)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 Then
			$ramdisk_guid = StringMid($line, $pos1, $pos2-$pos1+1)
			If $WimOnSystemDrive = 1 Then
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $ramdisk_guid & " ramdisksdidevice partition=" & $WinDrvDrive, $TargetDrive & "\", @SW_HIDE)
;~ 				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
;~ 				& $store & " /set " & $ramdisk_guid & " ramdisksdipath " & StringMid($bootsdi, 3), $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $ramdisk_guid & " ramdisksdipath " & $sdi_path & $sdi_file, $TargetDrive & "\", @SW_HIDE)
			Else
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $ramdisk_guid & " ramdisksdidevice boot", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $ramdisk_guid & " ramdisksdipath \Boot\" & $sdi_file, $TargetDrive & "\", @SW_HIDE)
			EndIf
		EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create /application osloader > makebt\bs_temp\pe_guid.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\pe_guid.txt", 0)
		$line = FileReadLine($file)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 And $ramdisk_guid <> "" Then
			$pe_guid = StringMid($line, $pos1, $pos2-$pos1+1)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " DESCRIPTION " & $img_fname & "-WIM", $TargetDrive & "\", @SW_HIDE)
			If $WimOnSystemDrive = 1 Then
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $pe_guid & " device ramdisk=[" & $WinDrvDrive & "]" & StringMid($btimgfile, 3) & "," & $ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $pe_guid & " osdevice ramdisk=[" & $WinDrvDrive & "]" & StringMid($btimgfile, 3) & "," & $ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set {default} bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
			Else
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $pe_guid & " device ramdisk=[boot]" & StringMid($btimgfile, 3) & "," & $ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $pe_guid & " osdevice ramdisk=[boot]" & StringMid($btimgfile, 3) & "," & $ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
			EndIf
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " systemroot \Windows", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " detecthal on", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " winpe Yes", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /displayorder " & $pe_guid & " /addfirst", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " NoIntegrityChecks 1", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " loadoptions DISABLE_INTEGRITY_CHECKS", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $pe_guid & " testsigning on", $TargetDrive & "\", @SW_HIDE)
			; on usb set wim default else reset original default
			; sleep(2000)
			If $DriveType="Removable" Or $usbfix Then
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /default " & $pe_guid, $TargetDrive & "\", @SW_HIDE)
			Else
				If $guid_def <> "" Then
					RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /default " & $guid_def, $TargetDrive & "\", @SW_HIDE)
				EndIf
			EndIf
		EndIf
		; If $DriveType="Removable" Or $usbfix Then
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} nointegritychecks on", $TargetDrive & "\", @SW_HIDE)
		; EndIf
		; to get PE ProgressBar and Win 8 Boot Manager Menu displayed and waiting for User Selection
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /bootems {emssettings} ON", $TargetDrive & "\", @SW_HIDE)
	EndIf

	; and for efi
	$store = $TargetDrive & "\EFI\Microsoft\Boot\BCD"
	If Not FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
		DirCopy(@WindowsDir & "\Boot\EFI", $TargetDrive & "\EFI\Microsoft\Boot", 1)
		DirCopy(@WindowsDir & "\Boot\Fonts", $TargetDrive & "\EFI\Microsoft\Boot\Fonts", 1)
		DirCopy(@WindowsDir & "\Boot\Resources", $TargetDrive & "\EFI\Microsoft\Boot\Resources", 1)
		If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\EFI\boot.sdi") Then
			FileCopy(@WindowsDir & "\Boot\DVD\EFI\boot.sdi", $TargetDrive & "\Boot\", 1)
		EndIf
		sleep(1000)
		If Not FileExists($TargetDrive & "\EFI\Boot\bootx64.efi") And FileExists(@WindowsDir & "\Boot\EFI\bootmgfw.efi") Then
			FileCopy(@WindowsDir & "\Boot\EFI\bootmgfw.efi", $TargetDrive & "\EFI\Boot\", 9)
			If @OSArch <> "X86" Then
				FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootx64.efi", 1)
			Else
				FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootia32.efi", 1)
			EndIf
		EndIf

		RunWait(@ComSpec & " /c " & $bcdedit & " /createstore " & $store, $TargetDrive & "\", @SW_HIDE)
		sleep(1000)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {bootmgr}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} description " & '"' & "Boot Manager" & '"', $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 20", $TargetDrive & "\", @SW_HIDE)
		sleep(1000)
	EndIf
	If FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
		; RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {ramdiskoptions}", @ScriptDir, @SW_HIDE)
		; efi_ramdisk_guid = "{ramdiskoptions}"
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create /device > makebt\bs_temp\efi_sdi_guid.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\efi_sdi_guid.txt", 0)
		$line = FileReadLine($file)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 Then
			$efi_ramdisk_guid = StringMid($line, $pos1, $pos2-$pos1+1)
			If $WimOnSystemDrive = 1 Then
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_ramdisk_guid & " ramdisksdidevice partition=" & $WinDrvDrive, $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_ramdisk_guid & " ramdisksdipath " & $sdi_path & $sdi_file, $TargetDrive & "\", @SW_HIDE)
			Else
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_ramdisk_guid & " ramdisksdidevice boot", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_ramdisk_guid & " ramdisksdipath \Boot\" & $sdi_file, $TargetDrive & "\", @SW_HIDE)
			EndIf
		EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create /application osloader > makebt\bs_temp\efi_pe_guid.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\efi_pe_guid.txt", 0)
		$line = FileReadLine($file)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 Then
			$efi_pe_guid = StringMid($line, $pos1, $pos2-$pos1+1)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " DESCRIPTION " & $img_fname & "-WIM", $TargetDrive & "\", @SW_HIDE)
			If $WimOnSystemDrive = 1 Then
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_pe_guid & " device ramdisk=[" & $WinDrvDrive & "]" & StringMid($btimgfile, 3) & "," & $efi_ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_pe_guid & " osdevice ramdisk=[" & $WinDrvDrive & "]" & StringMid($btimgfile, 3) & "," & $efi_ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set {default} bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
						Else
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_pe_guid & " device ramdisk=[boot]" & StringMid($btimgfile, 3) & "," & $efi_ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $efi_pe_guid & " osdevice ramdisk=[boot]" & StringMid($btimgfile, 3) & "," & $efi_ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
			EndIf
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " systemroot \Windows", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " detecthal on", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " winpe Yes", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /displayorder " & $efi_pe_guid & " /addfirst", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " NoIntegrityChecks 1", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " loadoptions DISABLE_INTEGRITY_CHECKS", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $efi_pe_guid & " testsigning on", $TargetDrive & "\", @SW_HIDE)
			; on usb set wim default
			; sleep(2000)
			If $DriveType="Removable" Or $usbfix Then
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /default " & $efi_pe_guid, $TargetDrive & "\", @SW_HIDE)
			EndIf
		EndIf
		; If $DriveType="Removable" Or $usbfix Then
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} nointegritychecks on", $TargetDrive & "\", @SW_HIDE)
		; EndIf
		; to get PE ProgressBar and Win 8 Boot Manager Menu displayed and waiting for User Selection
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /bootems {emssettings} ON", $TargetDrive & "\", @SW_HIDE)
	EndIf
	sleep(1000)

	; SystemFileRedirect("Off")

EndFunc   ;==> _wim_menu
;===================================================================================================
Func _vhd_menu()
	Local $val=0, $len, $pos, $img_fname="", $AutoPlay_Data=""
	Local $guid, $guid_def = "", $pos1, $pos2, $iPID, $Rand_NR = 100
	Local $vhd_boot = "", $dev_nr_1 = "", $dev_nr_2 = "", $part_nr_1 = "", $part_nr_2 = "", $FSvar_1 = "", $FSvar_2 = ""
	Local $file, $line, $linesplit[20], $vhd_found=0, $vhd_win="", $any_drive="", $count=0, $count_mp=0, $vhd_mp=0, $vhd_efi = 0, $dev_nr_efi = ""

	$vhd_f32_drive = ""
	$tmpdrive = ""
	$diskpart_error = 0
	$mbr_gpt_vhd_flag = "MBR"
	$vhd_hid_efi = 0
	$vhd_rev_layout = 0

	If @OSVersion = "WIN_VISTA" Or @OSVersion = "WIN_2003" Or @OSVersion = "WIN_XP" Or @OSVersion = "WIN_XPe" Or @OSVersion = "WIN_2000" Then
		MsgBox(48, "WARNING - OS Version is Not Valid ", "Need Windows 7/8/10 Or 7/8/10 PE to Make VHD Boot Manager " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 7/8/10 PE ", 5)
		Return
	EndIf
	; already set in _GO
	; SystemFileRedirect("On")

	If Not FileExists(@WindowsDir & "\system32\diskpart.exe") Then
		; SystemFileRedirect("Off")
		MsgBox(48, "ERROR - DiskPart Not Found ", " system32\diskpart.exe needed to Make VHD Boot Manager " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 7/8/10 PE ", 3)
		Return
	EndIf

	If FileExists(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt")

	RunWait(@ComSpec & " /c reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay" & " > makebt\vhd_temp\Reg_DisableAutoPlay.txt", @ScriptDir, @SW_HIDE)

	$file = FileOpen(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt", 0)
	While 1
		$line = FileReadLine($file)
		If @error = -1 Then ExitLoop
		If $line <> "" Then
			$line = StringStripWS($line, 7)
			$linesplit = StringSplit($line, " ")
			; _ArrayDisplay($linesplit)
			If $linesplit[1] = "DisableAutoplay" Then
				$AutoPlay_Data = $linesplit[3]
			EndIf
		EndIf
	Wend
	FileClose($file)

	; MsgBox(48, "Info AutoPlay ", "  " & @CRLF & @CRLF & " AutoPlay_Data = " & $AutoPlay_Data, 0)

	$len = StringLen($vhdfile_name)
	$pos = StringInStr($vhdfile_name, ".", 0, -1)
	; $img_fext = StringRight($vhdfile_name, $len-$pos)
	$img_fname = StringLeft($vhdfile_name, $pos-1)

	If FileExists(@ScriptDir & "\makebt\vhd_temp\attach_srcvhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\attach_srcvhd.txt")
	If FileExists(@ScriptDir & "\makebt\vhd_temp\detach_srcvhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\detach_srcvhd.txt")

	If Not FileExists($WinDrvDrive & "\" & $vhdfile_name) Then
		; SystemFileRedirect("Off")
		MsgBox(48, "ERROR - VHD File Not Found ", $WinDrvDrive & "\" & $vhdfile_name & " File Not Found " & @CRLF & @CRLF & " Unable to Make BootManager Menu ", 3)
		Return
	EndIf

	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 1 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Disabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 1 ", 0)
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," Attaching Source VHD " & $WinDrvDrive & "\" & $vhdfile_name, 0)
	; GUICtrlSetData($ProgressAll, 10)

	sleep(1000)
	$NoVirtDrives = DriveGetDrive( "FIXED" )
	; _ArrayDisplay($NoVirtDrives)
	sleep(1000)

	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\attach_srcvhd.txt","select vdisk file=" & $WinDrvDrive & "\" & $vhdfile_name)
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\attach_srcvhd.txt","attach vdisk")
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\attach_srcvhd.txt","exit")

	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_srcvhd.txt","select vdisk file=" & $WinDrvDrive & "\" & $vhdfile_name)
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_srcvhd.txt","detach vdisk")
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_srcvhd.txt","exit")

	$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\attach_srcvhd.txt", @ScriptDir, @SW_HIDE)
	If $val <> 0 Then
		; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
		EndIf
		; SystemFileRedirect("Off")
		MsgBox(48, " STOP - Error DiskPart", " Attach Source VHD -  DiskPart Error = " & $val & @CRLF & @CRLF _
		& " Use Disk Mananagement to Detach Source VHD ", 3)
		Return
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," Source VHD Attached - wait .... ", 0)

	If FileExists(@ScriptDir & "\makebt\vhdlist.txt") Then
		FileCopy(@ScriptDir & "\makebt\vhdlist.txt", @ScriptDir & "\makebt\vhdlist_bak.txt", 1)
		FileDelete(@ScriptDir & "\makebt\vhdlist.txt")
	EndIf

	sleep(1000)
	$FixedDrives = DriveGetDrive( "FIXED" )
	; _ArrayDisplay($FixedDrives)

	RunWait(@ComSpec & " /c makebt\listusbdrives\ListUsbDrives.exe -a > makebt\vhdlist.txt", @ScriptDir, @SW_HIDE)

	$file = FileOpen(@ScriptDir & "\makebt\vhdlist.txt", 0)
	If $file <> -1 Then
		$count = 0
		$vhd_mp = 0
		$vhd_efi = 0
		$any_drive = ""
		$vhd_found = 0
		$vhd_boot = ""
		$vhd_win = ""
		While 1
			$line = FileReadLine($file)
			If @error = -1 Then ExitLoop
			If $line <> "" Then
				$count = $count + 1
				$linesplit = StringSplit($line, "=")
				$linesplit[1] = StringStripWS($linesplit[1], 3)
				If $linesplit[1] = "MountPoint" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					$any_drive = $linesplit[2]
					$vhd_mp = 0
				EndIf
				If $vhd_mp = 1 And $linesplit[1] = "Device Number" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					If $vhd_found = 1 Then
						$dev_nr_1 = $linesplit[2]
					EndIf
					If $vhd_found = 2 Then
						$dev_nr_2 = $linesplit[2]
					EndIf
				EndIf
				If $vhd_mp = 1 And $linesplit[1] = "Partition Number" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					If $vhd_found = 1 Then
						$part_nr_1 = $linesplit[2]
					EndIf
					If $vhd_found = 2 Then
						$part_nr_2 = $linesplit[2]
					EndIf
				EndIf
				If $vhd_efi = 1 And $linesplit[1] = "Device Number" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					$dev_nr_efi = $linesplit[2]
				EndIf

				If $linesplit[1] = "Bus Type" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					If $linesplit[2] = "BusType15" And $any_drive = "none" Then
						$vhd_efi = 1
					Else
						$vhd_efi = 0
					EndIf
					If $linesplit[2] = "BusType15" And StringLen($any_drive) = 3 Then
						For $i = 1 to $FixedDrives[0]
							For $d = 1 to $NoVirtDrives[0]
								If $FixedDrives[$i] = $NoVirtDrives[$d] Then
									ContinueLoop 2
								EndIf
							Next
							If $FixedDrives[$i]=StringLeft($any_drive, 2) Then
								$vhd_found = $vhd_found + 1
								$vhd_mp = 1
								If $vhd_found = 1 Then
									$vhd_boot = StringLeft($any_drive, 2)
									$vhd_win = StringLeft($any_drive, 2)
								EndIf
								If $vhd_found = 2 Then
									$vhd_win = StringLeft($any_drive, 2)
								EndIf
								; MsgBox(0, "VHD Drive Found", " VHD Drive " & $vhd_found & " = " & $vhd_boot & @CRLF & @CRLF _
								; & " VHD Drive " & $vhd_found & " = " & $vhd_win & @CRLF & @CRLF & " ", 0)
								ExitLoop
							EndIf
						Next
					EndIf
				EndIf
			EndIf
		Wend
		FileClose($file)
	EndIf

	; MsgBox(0, "VHD Drive Found", " VHD Partitions = " & $vhd_found & @CRLF & @CRLF _
	; & " VHD 1 = " & $vhd_boot & "  Device = " & $dev_nr_1 & "  Partition = " & StringLeft($part_nr_1, 1) & @CRLF & @CRLF _
	; & " VHD 2 = " & $vhd_win & "  Device = " & $dev_nr_2 & "  Partition = " & StringLeft($part_nr_2, 1), 0)

	; In case of 2 partitions found on same VHD Device Number
	If $vhd_found = 2 And $dev_nr_1 = $dev_nr_2 Then
		$Part12_flag = 2
		If StringLeft($part_nr_1, 1) = "1" And StringLeft($part_nr_2, 1) = "2" Then
			$FSvar_1 = DriveGetFileSystem($vhd_boot)
			$FSvar_2 = DriveGetFileSystem($vhd_win)
			If $FSvar_1 = "FAT32" And $FSvar_2 = "NTFS" And FileExists($vhd_win & $WinFol) Then
				$vhd_f32_drive = $vhd_boot
				$tmpdrive = $vhd_win
			ElseIf $FSvar_1 = "NTFS" And $FSvar_2 = "FAT32" And FileExists($vhd_boot & $WinFol) Then
				$vhd_f32_drive = $vhd_win
				$tmpdrive = $vhd_boot
				$vhd_rev_layout = 1
			Else
				$tmpdrive = ""
				; should not occur
				; MsgBox(0, "VHD Drive - NOT OK",  " VHD Drive = " & $vhd_win, 0)
			EndIf
		; In case of reverse drive letter sequence
		ElseIf StringLeft($part_nr_1, 1) = "2" And StringLeft($part_nr_2, 1) = "1" Then
			$FSvar_1 = DriveGetFileSystem($vhd_win)
			$FSvar_2 = DriveGetFileSystem($vhd_boot)
			If $FSvar_1 = "FAT32" And $FSvar_2 = "NTFS" And FileExists($vhd_boot & $WinFol) Then
				$vhd_f32_drive = $vhd_win
				$tmpdrive = $vhd_boot
			ElseIf $FSvar_1 = "NTFS" And $FSvar_2 = "FAT32" And FileExists($vhd_win & $WinFol) Then
				$vhd_f32_drive = $vhd_boot
				$tmpdrive = $vhd_win
				$vhd_rev_layout = 1
			Else
				$tmpdrive = ""
				; should not occur
				; MsgBox(0, "VHD Drive - NOT OK",  " VHD Drive = " & $vhd_win, 0)
			EndIf
		; case GPT MS Reserved = Part 1
		ElseIf StringLeft($part_nr_1, 1) = "2" And StringLeft($part_nr_2, 1) = "3" Then
			$FSvar_1 = DriveGetFileSystem($vhd_boot)
			$FSvar_2 = DriveGetFileSystem($vhd_win)
			If $FSvar_1 = "FAT32" And $FSvar_2 = "NTFS" And FileExists($vhd_win & $WinFol) Then
				$vhd_f32_drive = $vhd_boot
				$tmpdrive = $vhd_win
			ElseIf $FSvar_1 = "NTFS" And $FSvar_2 = "FAT32" And FileExists($vhd_boot & $WinFol) Then
				$vhd_f32_drive = $vhd_win
				$tmpdrive = $vhd_boot
				$vhd_rev_layout = 1
			Else
				$tmpdrive = ""
				; should not occur
				; MsgBox(0, "VHD Drive - NOT OK",  " VHD Drive = " & $vhd_win, 0)
			EndIf
		; In case of reverse drive letter sequence
		ElseIf StringLeft($part_nr_1, 1) = "3" And StringLeft($part_nr_2, 1) = "2" Then
			$FSvar_1 = DriveGetFileSystem($vhd_win)
			$FSvar_2 = DriveGetFileSystem($vhd_boot)
			If $FSvar_1 = "FAT32" And $FSvar_2 = "NTFS" And FileExists($vhd_boot & $WinFol) Then
				$vhd_f32_drive = $vhd_win
				$tmpdrive = $vhd_boot
			ElseIf $FSvar_1 = "NTFS" And $FSvar_2 = "FAT32" And FileExists($vhd_win & $WinFol) Then
				$vhd_f32_drive = $vhd_boot
				$tmpdrive = $vhd_win
				$vhd_rev_layout = 1
			Else
				$tmpdrive = ""
				; should not occur
				; MsgBox(0, "VHD Drive - NOT OK",  " VHD Drive = " & $vhd_win, 0)
			EndIf
		Else
			$tmpdrive = ""
			; should not occur
			; MsgBox(0, "VHD Drive - NOT OK",  " VHD Drive = " & $vhd_win, 0)
		EndIf
	ElseIf $vhd_found = 1 Then
		$Part12_flag = 1
		$FSvar_1 = DriveGetFileSystem($vhd_win)
		If $vhd_win <> "" And $FSvar_1 = "NTFS"  And FileExists($vhd_win & $WinFol) Then
			$tmpdrive = $vhd_win
			If $dev_nr_efi = $dev_nr_1 Then
				$vhd_hid_efi = 1
				; MsgBox(0, "VHD Drive - GPT UEFI",  " VHD Drive = " & $vhd_win & "   Device = " & $dev_nr_efi, 0)
			EndIf
		Else
			$tmpdrive = ""
			; should not occur
			; MsgBox(0, "VHD Drive - NOT OK",  " VHD Drive = " & $vhd_win, 0)
		EndIf
		; MsgBox(0, "VHD Drive - OK",  " VHD Drive = " & $vhd_win, 0)
	Else
		$Part12_flag = 0
		$tmpdrive = ""
		; should not occur
		; MsgBox(0, "VHD Drive - NOT OK",  " VHD Drive = " & $vhd_win, 0)
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," Analysing Drivers in VHD - Wait .... ", 0)

	If $tmpdrive = "" Then
		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_srcvhd.txt", @ScriptDir, @SW_HIDE)
		If $val <> 0 Then
			MsgBox(48, " Error DiskPart", " Detach Source VHD -  DiskPart Error = " & $val & @CRLF & @CRLF _
			& " Use Disk Mananagement to Detach Source VHD ", 3)
		EndIf
		; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
		EndIf
		MsgBox(48, " STOP - VHD Drive Not Found - Invalid FileSystem ", " Unable to Add VHD to Boot Manager ",  & @CRLF & @CRLF _
		& " VHD must have NTFS Or FAT32 + NTFS FileSystem " & $vhdfile, 5)
		_GUICtrlStatusBar_SetText($hStatus," ", 0)
		; GUICtrlSetData($ProgressAll, 0)
		; SystemFileRedirect("Off")
		; DisableMenus(0)
		Return
	EndIf

	; vhd has MBR or GPT ?
	$mbr_gpt_vhd_flag = _GetDrivePartitionStyle(StringLeft($tmpdrive, 1))


	If GUICtrlRead($Menu_Type) = "XP - WinVBlock" Then
		If Not FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") Then
			If FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Then
				MsgBox(48, "WARNING - WinVBlock Driver Not Installed in Source ", $tmpdrive & $WinFol & "\system32\drivers\firadisk.sys is Found " & @CRLF & @CRLF _
				& " Change Grub4dos VHD Menu Type to XP - FiraDisk ", 5)
				GUICtrlSetData($Menu_Type,"XP - FiraDisk")
			Else
				; MsgBox(48, "WARNING - WinVBlock and FiraDisk Driver Not Installed in Source ", " Unable to make Grub4dos Boot Menu for Win7 VHD ", 3)
				$g4d_w7vhd_flag=0
			EndIf
		EndIf
	EndIf

	If GUICtrlRead($Menu_Type) = "XP - FiraDisk" Then
		If Not FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Then
			If FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") Then
				MsgBox(48, "WARNING - FiraDisk Driver Not Installed in Source ", $tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys is Found " & @CRLF & @CRLF _
				& " Change Grub4dos VHD Menu Type to XP - WinVBlock ", 5)
				GUICtrlSetData($Menu_Type,"XP - WinVBlock")
			Else
				; MsgBox(48, "WARNING - WinVBlock and FiraDisk Driver Not Installed in Source ", " Unable to make Grub4dos Boot Menu for Win7 VHD ", 3)
				$g4d_w7vhd_flag=0
			EndIf
		EndIf
	EndIf

	If GUICtrlRead($Menu_Type) = "78 - WinVBlock" Then
		If Not FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") Then
			If FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Then
				MsgBox(48, "WARNING - WinVBlock Driver Not Installed in Source ", $tmpdrive & $WinFol & "\system32\drivers\firadisk.sys is Found " & @CRLF & @CRLF _
				& " Change Grub4dos VHD Menu Type to 78 - FiraDisk ", 5)
				GUICtrlSetData($Menu_Type,"78 - FiraDisk")
			Else
				; MsgBox(48, "WARNING - WinVBlock and FiraDisk Driver Not Installed in Source ", " Unable to make Grub4dos Boot Menu for Win7 VHD ", 3)
				$g4d_w7vhd_flag=0
			EndIf
		EndIf
	EndIf

	If GUICtrlRead($Menu_Type) = "78 - FiraDisk" Then
		If Not FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Then
			If FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") Then
				MsgBox(48, "WARNING - FiraDisk Driver Not Installed in Source ", $tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys is Found " & @CRLF & @CRLF _
				& " Change Grub4dos VHD Menu Type to 78 - WinVBlock ", 5)
				GUICtrlSetData($Menu_Type,"78 - WinVBlock")
			Else
				; MsgBox(48, "WARNING - WinVBlock and FiraDisk Driver Not Installed in Source ", " Unable to make Grub4dos Boot Menu for Win7 VHD ", 3)
				$g4d_w7vhd_flag=0
			EndIf
		EndIf
	EndIf

	;	If Not FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") And Not FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Then
	;		; MsgBox(48, "WARNING - WinVBlock and FiraDisk Driver Not Installed in Source ", " Unable to make Grub4dos Boot Menu for Win7 VHD ", 3)
	;		$g4d_w7vhd_flag=0
	;	EndIf

	If FileExists($tmpdrive & $WinFol & "\system32\drivers\svbusx86.sys") Or FileExists($tmpdrive & $WinFol & "\system32\drivers\svbusx64.sys") Then
		$driver_flag = 3
		$g4d_w7vhd_flag=1
	ElseIf FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Or FileExists($tmpdrive & $WinFol & "\system32\drivers\firadi64.sys") Then
		$driver_flag = 2
		$g4d_w7vhd_flag=1
	ElseIf FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") Or FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk64.sys")Then
		$driver_flag = 1
		$g4d_w7vhd_flag=1
	Else
		$driver_flag = 0
		$g4d_w7vhd_flag=1
	EndIf

	If FileExists($tmpdrive & $WinFol & "\system32\drivers\vhdmp.sys") Then
		$vhdmp=1
	Else
		If GUICtrlRead($Boot_vhd) = $GUI_CHECKED Then
			GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
			MsgBox(48, "WARNING - VHD driver Not Found ", "\system32\drivers\vhdmp.sys" & " VHD driver Not Found " _
			& @CRLF & @CRLF & " Unable to Add VHD to BootManager Menu ", 3)
		EndIf
	EndIf

	If FileExists($tmpdrive & $WinFol & "\SysWOW64") Then
		$SysWOW64=1
	EndIf

	_DetectLang()

	_WinLang()

	If GUICtrlRead($Boot_vhd) = $GUI_CHECKED And $vhdmp=1 And $FSvar_WinDrvDrive="NTFS" Then
		; in Win 8/10 x64 OS then bcdboot with option /f ALL must be used, otherwise entry is not made
		If FileExists(@WindowsDir & "\system32\bcdboot.exe") And Not FileExists($TargetDrive & "\Boot\BCD") And $PartStyle = "MBR" Then
			$bcdboot_flag = 1
			If $PE_flag = 1 Then
				If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
					_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
				Else
					_GUICtrlStatusBar_SetText($hStatus," Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $TargetDrive, @ScriptDir, @SW_HIDE)
				EndIf
			Else
				If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
					_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
				Else
					_GUICtrlStatusBar_SetText($hStatus," Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive, @ScriptDir, @SW_HIDE)
				EndIf
			EndIf
			sleep(2000)
		EndIf
		If FileExists(@WindowsDir & "\system32\bcdboot.exe") And Not FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
			$bcdboot_flag = 1
			If $PE_flag = 1 Then
				If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
					_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $TargetDrive & " /f UEFI", @ScriptDir, @SW_HIDE)
				Else
					MsgBox(48,"WARNING - Win 8/10 x64 OS Needed", "EFI BCD Missing on Boot Drive " & $TargetDrive & @CRLF & @CRLF & "Win 8/10 x64 OS needed to Make EFI BCD", 5)
				EndIf
			Else
				If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
					_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive & " /f UEFI", @ScriptDir, @SW_HIDE)
				Else
					MsgBox(48,"WARNING - Win 8/10 x64 OS Needed", "EFI BCD Missing on Boot Drive " & $TargetDrive & @CRLF & @CRLF & "Win 8/10 x64 OS needed to Make EFI BCD", 5)
				EndIf
			EndIf
			sleep(2000)
		EndIf
		If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($TargetDrive & "\Boot\BCD") And $PartStyle = "MBR" Then
			_GUICtrlStatusBar_SetText($hStatus," Add VHD entry to BCD on Boot Drive " & $TargetDrive, 0)
			If Not FileExists($TargetDrive & "\Boot\bootvhd.dll") And FileExists(@WindowsDir & "\Boot\PCAT\bootvhd.dll") Then
				FileCopy(@WindowsDir & "\Boot\PCAT\bootvhd.dll", $TargetDrive & "\Boot\", 1)
			EndIf
			$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
			$store = $TargetDrive & "\Boot\BCD"
			$winload = "winload.exe"
			$bcd_guid_outfile = "makebt\bs_temp\bcd_boot_usb.txt"

			_BCD_BootDrive_VHD_Entry()

			sleep(1000)
			FileSetAttrib($TargetDrive & "\Boot", "-RSH", 1)
			FileSetAttrib($TargetDrive & "\bootmgr", "-RSH")
		EndIf
		If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
			_GUICtrlStatusBar_SetText($hStatus," Add VHD entry to BCD on Boot Drive " & $TargetDrive, 0)
			$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
			$store = $TargetDrive & "\EFI\Microsoft\Boot\BCD"
			$winload = "winload.efi"
			$bcd_guid_outfile = "makebt\bs_temp\bcd_efi_usb.txt"

			_BCD_BootDrive_VHD_Entry()

		EndIf
	EndIf

	$Rand_NR = Random(100, 999, 1)

	If $vhd_f32_drive <> "" And FileExists($vhd_f32_drive & "\nul") Then
		If FileExists(@WindowsDir & "\system32\bcdboot.exe") Then
			; in win8 x64 OS then Win8x64 bcdboot with option /f ALL must be used, otherwise entry is not made
			If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
				_GUICtrlStatusBar_SetText($hStatus," UEFI x64 - Make Boot Manager in VHD_F32 - wait .... ", 0)
				$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $vhd_f32_drive & " /f ALL", @ScriptDir, @SW_HIDE)
			Else
				_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager in VHD_F32 - wait .... ", 0)
				$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $vhd_f32_drive, @ScriptDir, @SW_HIDE)
			EndIf
			Sleep(1000)
		EndIf
		; Rename NTFS folder EFI and Boot as x-EFI and x-Boot needed to prevent boot_image)handle Not found in booting UEFI Grub4dos - better UnCompress with WofCompress
		If FileExists($tmpdrive & "\EFI") Then DirMove($tmpdrive & "\EFI", $tmpdrive & "\x-" & $Rand_NR & "-EFI", 1)
		If FileExists($tmpdrive & "\Boot") Then DirMove($tmpdrive & "\Boot", $tmpdrive & "\x-" & $Rand_NR & "-Boot", 1)
	Else
		If $vhd_hid_efi = 0 Then
			_BCD_Inside_VHD()
		Else
			; 2 partition VHD with Hidden EFI partition - type GPT - UEFI WinNTSetup
			; Rename NTFS folder EFI and Boot as x-EFI and x-Boot needed to prevent boot_image_handle Not found in booting UEFI Grub4dos
			If FileExists($tmpdrive & "\EFI") Then DirMove($tmpdrive & "\EFI", $tmpdrive & "\x-" & $Rand_NR & "-EFI", 1)
			If FileExists($tmpdrive & "\Boot") Then DirMove($tmpdrive & "\Boot", $tmpdrive & "\x-" & $Rand_NR & "-Boot", 1)
		EndIf
	EndIf

	; UnCompress EFI folder inside VHD - needed for UEFI booting from RAMDISK of 1 Partition VHD - UEFI Grub2 and UEFI Grub4dos
	If FileExists($tmpdrive & "\EFI") Then
		_GUICtrlStatusBar_SetText($hStatus," WOF UnCompress of " & $tmpdrive & "\EFI" & " - wait .... ", 0)
		Sleep(500)
		If @OSArch = "X86" Then
			$iPID = Run(@ComSpec & " /k WofCompress\x86\WofCompress.exe -u -path:" & '"' & $tmpdrive & "\EFI" & '"', @ScriptDir, @SW_HIDE)
		Else
			$iPID = Run(@ComSpec & " /k WofCompress\x64\WofCompress.exe -u -path:" & '"' & $tmpdrive & "\EFI" & '"', @ScriptDir, @SW_HIDE)
		EndIf
		ProcessWaitClose($iPID, 1)
	EndIf

	; UnCompress Boot folder inside VHD
	If FileExists($tmpdrive & "\Boot") Then
		_GUICtrlStatusBar_SetText($hStatus," WOF UnCompress of " & $tmpdrive & "\Boot" & " - wait .... ", 0)
		Sleep(500)
		If @OSArch = "X86" Then
			$iPID = Run(@ComSpec & " /k WofCompress\x86\WofCompress.exe -u -path:" & '"' & $tmpdrive & "\Boot" & '"', @ScriptDir, @SW_HIDE)
		Else
			$iPID = Run(@ComSpec & " /k WofCompress\x64\WofCompress.exe -u -path:" & '"' & $tmpdrive & "\Boot" & '"', @ScriptDir, @SW_HIDE)
		EndIf
		ProcessWaitClose($iPID, 1)
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," Detaching Source VHD " & $WinDrvDrive & "\" & $vhdfile_name & " - wait .... ", 0)

	; GUICtrlSetData($ProgressAll, 10)
	$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_srcvhd.txt", @ScriptDir, @SW_HIDE)
	If $val <> 0 Then
		; SystemFileRedirect("Off")
		MsgBox(48, " Error DiskPart", " Detach Source VHD -  DiskPart Error = " & $val, 3)
		; Return
	EndIf

	; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
	EndIf

	; SystemFileRedirect("Off")

EndFunc   ;==> _vhd_menu
;===================================================================================================
Func _ListUsb_UEFI()
	Local $linesplit[20], $file, $line, $pos1, $pos2

	Local $mptarget=0, $mpsystem=0, $count = 0, $count_none = 0, $BusType_none = "", $disk_none = "", $part_none = "", $Target_Found = 0

	$DriveType=DriveGetType($TargetDrive)
	$DriveSysType=DriveGetType($WinDrvDrive)

	If FileExists(@ScriptDir & "\makebt\usblist.txt") Then
		FileCopy(@ScriptDir & "\makebt\usblist.txt", @ScriptDir & "\makebt\usblist_bak.txt", 1)
		FileDelete(@ScriptDir & "\makebt\usblist.txt")
	EndIf
	; Sleep(2000)

	RunWait(@ComSpec & " /c makebt\listusbdrives\ListUsbDrives.exe -a > makebt\usblist.txt", @ScriptDir, @SW_HIDE)

	$inst_disk=""
	$inst_part=""
	$sys_disk=""
	$sys_part=""
	$BusType = ""
	$BusSys = ""
	$usbfix=0
	$usbsys=0
	$file = FileOpen(@ScriptDir & "\makebt\usblist.txt", 0)
	If $file <> -1 Then
		$count = 0
		$mptarget = 0
		$mpsystem = 0
		$count_none = 0
		While 1
			$line = FileReadLine($file)
			If @error = -1 Then ExitLoop
			If $line <> "" Then
				$count = $count + 1
				$linesplit = StringSplit($line, "=")
				$linesplit[1] = StringStripWS($linesplit[1], 3)
				If $linesplit[1] = "MountPoint" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					If $linesplit[2] = $TargetDrive & "\" Then
						$mptarget = 1
						$Target_Found = 1
						; MsgBox(0, "TargetDrive Found - OK", " TargetDrive = " & $linesplit[2], 3)
					ElseIf $linesplit[2] = "none" Then
						$mptarget = 3
						$count_none = $count_none + 1
					Else
						$mptarget = 0
					EndIf
					If $linesplit[2] = $WinDrvDrive & "\" Then
						$mpsystem = 1
						; MsgBox(0, "SystemDrive Found - OK", " SystemDrive = " & $linesplit[2], 3)
					Else
						$mpsystem = 0
					EndIf
				EndIf
				If $mptarget = 1 Then
					If $linesplit[1] = "Bus Type" And $linesplit[0] = 2 Then
						$linesplit[2] = StringStripWS($linesplit[2], 3)
						$BusType = $linesplit[2]
						If $linesplit[2] = "USB" Then
							$usbfix = 1
						Else
							$usbfix = 0
						EndIf
						;	MsgBox(0, "TargetDrive USB or HDD ?", " Bus Type = " & $linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Device Number" And $linesplit[0] = 2 Then
						$inst_disk = StringStripWS($linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Partition Number" Then
						$inst_part = StringLeft(StringStripWS($linesplit[2], 3), 1)
					EndIf
				EndIf
				If $mptarget = 3 Then
					If $linesplit[1] = "Bus Type" And $linesplit[0] = 2 Then
						$linesplit[2] = StringStripWS($linesplit[2], 3)
						$BusType_none = $linesplit[2]
					EndIf
					If $linesplit[1] = "Device Number" And $linesplit[0] = 2 Then
						$disk_none = StringStripWS($linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Partition Number" Then
						$part_none = StringLeft(StringStripWS($linesplit[2], 3), 1)
					EndIf
				EndIf
				If $mpsystem = 1 Then
					If $linesplit[1] = "Bus Type" And $linesplit[0] = 2 Then
						$linesplit[2] = StringStripWS($linesplit[2], 3)
						$BusSys = $linesplit[2]
						If $linesplit[2] = "USB" Then
							$usbsys = 1
						Else
							$usbsys = 0
						EndIf
						;	MsgBox(0, "SystemDrive USB or HDD ?", " Bus Type = " & $linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Device Number" And $linesplit[0] = 2 Then
						$sys_disk = StringStripWS($linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Partition Number" Then
						$sys_part = StringLeft(StringStripWS($linesplit[2], 3), 1)
					EndIf
				EndIf
			EndIf
		Wend
		FileClose($file)
	EndIf

	If $Target_Found = 1 Then
		GUICtrlSetData($Target_Device, $PartStyle & "  hd " & $inst_disk & "  p " & $inst_part)
		GUICtrlSetData($Target_Type, $BusType & "  " &  StringLeft($DriveType, 5) & "  " & DriveGetType($TargetDrive, 2))
	ElseIf $count_none = 1 Then
		$BusType = $BusType_none
		GUICtrlSetData($Target_Device, $PartStyle & "  hd " & $disk_none & "  p " & $part_none)
		GUICtrlSetData($Target_Type, $BusType_none & "  " &  StringLeft($DriveType, 5) & "  " & DriveGetType($TargetDrive, 2))
	Else
		GUICtrlSetData($Target_Device, "")
		GUICtrlSetData($Target_Type, "")
	EndIf

	GUICtrlSetData($Sys_Device, $SysStyle & "  hd " & $sys_disk & "  p " & $sys_part)
	GUICtrlSetData($Sys_Type, $BusSys & "  " &  StringLeft($DriveSysType, 5) & "  " & DriveGetType($WinDrvDrive, 2))

EndFunc   ;==> __ListUsb_UEFI
;===================================================================================================
Func _Go()
	Local $val=0, $len, $pos, $ikey, $mkimg_err = 0

	Local $fhan, $mbrsrc, $bcd_create_flag=0

	; Local $file, $line, $linesplit[20], $mptarget=0, $mpsystem=0
	Local $notactiv=0, $xpmbr=0, $count, $activebyte = "00", $bkp, $headbkp

	Local $FileList, $sl, $dest

	_GUICtrlStatusBar_SetText($hStatus," Checking Drives - wait  ....", 0)
	GUICtrlSetData($ProgressAll, 5)
	DisableMenus(1)

;~ 		If Not FileExists(@ScriptDir & "\UEFI_MAN\grub_a1\grub-install.exe") Or Not FileExists(@ScriptDir & "\UEFI_MAN\grubfm.iso") _
;~ 			Or Not FileExists(@ScriptDir & "\UEFI_MAN\EFI\Boot\MokManager.efi") And GUICtrlRead($refind) = $GUI_CHECKED And GUICtrlRead($Combo_EFI) <> "Mint   UEFI" Then
;~ 			MsgBox(16, "  STOP - Addon is Missing", "Addon for Grub2 Manager is Missing " & @CRLF & @CRLF _
;~ 			& "Download UEFI_MULTI-Nr-addon-glim-agFM.zip from https://github.com/wimbrts " & @CRLF & @CRLF _
;~ 			& "Use R-mouse 7-zip menu and Extract here to Add to UEFI_MULTI-Nr   folder " & @CRLF & @CRLF _
;~ 			& "Confirm 4x Overwrites with Yes and use UEFI_MULTI again with Addon ")
;~ 			_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
;~ 			GUICtrlSetData($ProgressAll, 0)
;~ 			DisableMenus(0)
;~ 			Return
;~ 		EndIf

	If DriveStatus($WinDrvDrive) <> "READY" Then
		MsgBox(48, "ERROR - USB Boot Drive NOT Ready", "Drive NOT READY - First Format USB Boot Drive ", 3)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
		Return
	EndIf
	If DriveStatus($TargetDrive) <> "READY" Then
		MsgBox(48, "ERROR - USB System Drive NOT Ready", "Drive NOT READY - First Format USB System Drive ", 3)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
		Return
	EndIf

	If GUICtrlRead($ImageType) = "LiveXP BootSDI - IMG" Or GUICtrlRead($ImageType) = "BartPE - ISO" Or GUICtrlRead($ImageType) = "XP Rec Cons - IMG" Then
		If Not FileExists(@ScriptDir & "\makebt\srsp1\setupldr.bin") Then
			MsgBox(48, "STOP - Missing Server 2003 SP1 Files setupldr.bin", "Files \makebt\srsp1\setupldr.bin NOT Found " _
			& @CRLF & @CRLF & "Copy File Winbuilder\Workbench\Common\BootSDI\setupldr.bin " _
			& @CRLF & @CRLF & "And ramdisk.sys to USB_XP_Setup\makebt\srsp1 folder ")
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
			Return
		EndIf
		If Not FileExists($TargetDrive & "\NTDETECT.COM") And Not FileExists(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM") And Not FileExists(@ScriptDir & "\makebt\ntdetect.com") Then
			MsgBox(48, "STOP - File NTDETECT.COM Needed ", "Solution - Run UEFI_MULTI once in XP OS " & @CRLF & @CRLF _
				& "Or Copy modified ntdetect.com to makebt folder ", 0)
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
			Return
		EndIf
	EndIf

	If GUICtrlRead($ImageType) = "LiveXP BootSDI - IMG" Or GUICtrlRead($ImageType) = "BartPE - ISO" Then
		For $i = 1 To 9
			If Not FileExists($TargetDrive & "\RMLD" & $i) Then
				$pe_nr = $i
				ExitLoop
			EndIf
			If $i = 9 Then
				MsgBox(48, "Error - Return", " Too many RAMBOOT Image Files on System Drive, Max = 9 " & @CRLF _
				&  " Remove Some RAMBOOT Loader File RMLDx from your System Drive " &  $TargetDrive)
				GUICtrlSetData($ProgressAll, 0)
				DisableMenus(0)
				_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
				Return
			EndIf
		Next
	EndIf

	If FileExists($TargetDrive & "\grldr") And Not FileExists($TargetDrive & "\menu.lst") And GUICtrlRead($grldrUpd) = $GUI_UNCHECKED Then
		MsgBox(48, "WARNING - SUSPECT CONFIG ERROR ", " grldr found without menu.lst " & @CRLF & @CRLF _
		& " Unable to Add Grub4dos to BootManager Menu" & @CRLF & @CRLF _
		& " Use Update Grub4dos grldr Checkbox to solve problem ", 0)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
		Return
	EndIf

	Local $oTest = ObjCreate("Scripting.FileSystemObject"), $FSObjFlag=0

	If @error Then
		$FSObjFlag=1
	EndIf

	; Done already in line 108
	; If FileExists(@ScriptDir & "\makebt\bs_temp") Then DirRemove(@ScriptDir & "\makebt\bs_temp",1)
	; If Not FileExists(@ScriptDir & "\makebt\bs_temp") Then DirCreate(@ScriptDir & "\makebt\bs_temp")

	; GUICtrlSetData($ProgressAll, 10)

	If Not CheckSize() Then
		MsgBox(48, "ERROR - OverFlow ", " Boot  Image  File = " & $BTIMGSize & " MB" & @CRLF _
		& " Source   Folder   = " & $ContentSize & " MB" & @CRLF _
		& " Boot   Drive Free = " & $TargetSpaceAvail & " MB" & @CRLF _
		& " System Drive Free = " & $WinDrvSpaceAvail & " MB" & @CRLF)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		GUICtrlSetState($TargetSel, $GUI_FOCUS)
		_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
		Return
	Endif

	GUICtrlSetData($ProgressAll, 10)

	Sleep(1000)

	$FSvar_TargetDrive = DriveGetFileSystem($TargetDrive)

	_ListUsb_UEFI()

	If $BusType <> "USB" And $PartStyle = "GPT" And $FSvar_TargetDrive <> "FAT32" Then
		MsgBox(48, "ERROR - Boot Drive Not Valid", "Boot Drive must be FAT32 for Internal HDD with GPT part " & @CRLF & @CRLF & _
		"Target Boot Drive = " & $TargetDrive & "   HDD = " & $inst_disk & "   PART = " & $inst_part & @CRLF & @CRLF _
		& "FileSystem = " & $FSvar_TargetDrive & "   Bus Type = " & $BusType & "   Partitioning = " & $PartStyle, 0)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
		Return
	EndIf

	If $usbfix = 0 Then
		$ikey = MsgBox(48+4+256, "WARNING - Boot Drive is NOT USB", "Boot Drive is NOT USB Drive" & @CRLF & @CRLF & _
		"Target Boot Drive = " & $TargetDrive & "   HDD = " & $inst_disk & "   PART = " & $inst_part & @CRLF & @CRLF _
		& "Modify the Booting of your Computer ? " & @CRLF & @CRLF _
		& "Are You Sure ? - This is an Internal Harddisk ! ")
		If $ikey <> 6 Then
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			_GUICtrlStatusBar_SetText($hStatus," First Select Target Drives and then Sources", 0)
			Return
		EndIf
	EndIf

	GUICtrlSetData($ProgressAll, 20)
	_GUICtrlStatusBar_SetText($hStatus," Checking MBR BootCode - Wait ... ", 0)

	; MsgBox(0, "TargetDrive - OK", $TargetDrive & "\" & " Drive was found " & @CRLF & "Device Number = " & $inst_disk & @CRLF & "Partition Number = " & $inst_part, 0)

;~ 		If $inst_disk = "" Or $inst_part = "" Then
;~ 			MsgBox(48, "WARNING - Target Drive is NOT Valid", "Device Number NOT Found in makebt\usblist.txt" & @CRLF & @CRLF & _
;~ 			"Target Drive = " & $TargetDrive & "   HDD = " & $inst_disk & "   PART = " & $inst_part)
;~ 			Exit
;~ 		EndIf

	If $inst_disk <> "" And $inst_part <> "" And $PartStyle = "MBR" Then
		RunWait(@ComSpec & " /c makebt\dsfo.exe \\.\PHYSICALDRIVE" & $inst_disk & " 0 512 makebt\bs_temp\hd_" & $inst_disk & ".mbr", @ScriptDir, @SW_HIDE)

		$fhan = FileOpen(@ScriptDir & "\makebt\bs_temp\hd_" & $inst_disk & ".mbr", 16)
		If $fhan = -1 Then
			MsgBox(48, "WARNING - MBR NOT FOUND", "Unable to open file makebt\bs_temp\hd_" & $inst_disk & ".mbr", 0)
			Exit
		EndIf

		$mbrsrc = FileRead($fhan)
		FileClose($fhan)
		If $inst_part > 0  And $inst_part < 5  Then
			$activebyte = StringMid($mbrsrc, 895 + ($inst_part-1)*32, 2)
		EndIf
		If $activebyte <> "80" Then $notactiv=1

		$xpmbr = 0
		$g4dmbr = 0

		$xpmbr = HexSearch(@ScriptDir & "\makebt\bs_temp\hd_" & $inst_disk & ".mbr", "33C08ED0BC007C", 16, 1)
		; test for grub4dos in MBR
		If Not $xpmbr Then $g4dmbr = HexSearch(@ScriptDir & "\makebt\bs_temp\hd_" & $inst_disk & ".mbr", "EB5E80052039", 16, 1)
		If Not $xpmbr And Not $g4dmbr Then $g4dmbr = HexSearch(@ScriptDir & "\makebt\bs_temp\hd_" & $inst_disk & ".mbr", "33C0EB5C80002039", 16, 1)
		If Not $xpmbr And Not $g4dmbr Then $g4dmbr = HexSearch(@ScriptDir & "\makebt\bs_temp\hd_" & $inst_disk & ".mbr", "33C0EB5C90000000", 16, 1)
		; ventoy and Super have "EB6390000000"
		If Not $xpmbr And Not $g4dmbr Then $ventoy = HexSearch(@ScriptDir & "\makebt\bs_temp\hd_" & $inst_disk & ".mbr", "EB6390000000", 16, 1)
		If Not $xpmbr And Not $g4dmbr Then $grub2 = HexSearch(@ScriptDir & "\makebt\bs_temp\hd_" & $inst_disk & ".mbr", "EB6390D0BC00", 16, 1)

		; Make backup of mbr 1sthead
		$dt = StringReplace(_NowCalc(), "/", "", 0)
		$dt = StringReplace($dt, ":", "", 0)
		$dt = StringReplace($dt, " ", "-", 0)
		$bkp = "mbrdisk" & $inst_disk & "-" & $dt & ".dat"
		$headbkp = "mbrheaddisk" & $inst_disk & "-" & $dt & ".dat"

		RunWait(@ComSpec & " /c makebt\dsfo.exe \\.\PHYSICALDRIVE" & $inst_disk & " 0 512 makebt\backups\" & $bkp, @ScriptDir, @SW_HIDE)
		RunWait(@ComSpec & " /c makebt\dsfo.exe \\.\PHYSICALDRIVE" & $inst_disk & " 0 32256 makebt\backups\" & $headbkp, @ScriptDir, @SW_HIDE)
	EndIf

	If FileExists($TargetDrive & "\ventoy") Then
		$ventoy = 1
	EndIf

	; Keep Ventoy MBR and Ventoy Grub2
	If $ventoy Then
		GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
		GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)
	EndIf

	Sleep(2000)
	SystemFileRedirect("On")

	; Set Active TargetDrive only for USB Fixed Disk with MBR Partition - BIOS mode booting requires Active Drive
	If $usbfix And $DriveType <> "Removable" And $inst_disk <> "" And $inst_part <> "" And $PartStyle = "MBR" And $notactiv Then
		; MsgBox(0, "MBR Disk and Partition", " Disk = " & $inst_disk & @CRLF & " Part = " & $inst_part, 3)

		If FileExists(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt")

		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","select disk " & $inst_disk)
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","select partition " & $inst_part)
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","active")
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","exit")

		If FileExists(@WindowsDir & "\system32\diskpart.exe") Then
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\set_usb_active.txt", @ScriptDir, @SW_HIDE)
		EndIf
	EndIf

	If $DriveType<>"Removable" And $usbfix=0 Then
		GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
	EndIf
	; Force Update MBR BootCode
	If GUICtrlRead($Upd_MBR) = $GUI_CHECKED Then
		$xpmbr=0
		$g4dmbr=0
		$grub2=0
	EndIf

	If $xpmbr=0 And $g4dmbr=0 And $grub2=0 And $inst_disk <> "" And $inst_part <> "" And $PartStyle = "MBR" Then
		; Only for fixed USB drives having MBR and partition table Forced Update MBR Boot Code
		If $DriveType <> "Removable" And $usbfix And $ventoy=0 And FileExists(@WindowsDir & "\system32\bootsect.exe") Then
			; Use bootsect.exe instead of MBRFIX.exe
			If GUICtrlRead($Upd_MBR) = $GUI_UNCHECKED Then
				$ikey = MsgBox(48+4+256, "WARNING - USB has Unknown MBR BootSector ", " Use bootsect.exe to Update MBR and BootSector " & @CRLF & @CRLF _
				& " Yes = USB change MBR and BootSector to BOOTMGR Type " & @CRLF & @CRLF _
				& " No  = Keep MBR and BootSector of partition ")
				If $ikey = 6 Then
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bootsect.exe /nt60 " & $TargetDrive & " /mbr", @ScriptDir, @SW_HIDE)
					$xpmbr=1
					$g4dmbr=0
					$grub2=0
				EndIf
			Else
				$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bootsect.exe /nt60 " & $TargetDrive & " /mbr", @ScriptDir, @SW_HIDE)
				$xpmbr=1
				$g4dmbr=0
				$grub2=0
			EndIf
		Else
			GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
		;	MsgBox(48, "WARNING - Keep MBR and BootSector", " MBR BootCode remains Unchanged " & @CRLF & " Continue with FileCopy ", 3)
		EndIf
	EndIf

	SystemFileRedirect("Off")

	_GUICtrlStatusBar_SetText($hStatus," Check BootSector Target Drive " & $TargetDrive & " - Wait ... ", 0)
	GUICtrlSetData($ProgressAll, 30)
	Sleep(2000)

	_Copy_BSU()
	If $bs_valid = 0 Then
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		_GUICtrlStatusBar_SetText($hStatus," First Select Target Drive and then Sources", 0)
		Return
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," Checking Boot Files - Wait ... ", 0)
	GUICtrlSetData($ProgressAll, 40)

	If $usbfix Then
		If FileExists(@ScriptDir & "\makebt\autorun.inf") And Not FileExists($TargetDrive & "\autorun.inf") Then FileCopy(@ScriptDir & "\makebt\autorun.inf", $TargetDrive & "\")
		If FileExists(@ScriptDir & "\makebt\Uefi_Multi.ico") And Not FileExists($TargetDrive & "\Uefi_Multi.ico") Then FileCopy(@ScriptDir & "\makebt\Uefi_Multi.ico", $TargetDrive & "\")
	EndIf

	If $usbsys Then
		If FileExists(@ScriptDir & "\makebt\autorun.inf") And Not FileExists($WinDrvDrive & "\autorun.inf") Then FileCopy(@ScriptDir & "\makebt\autorun.inf", $WinDrvDrive & "\")
		If FileExists(@ScriptDir & "\makebt\Uefi_Multi.ico") And Not FileExists($WinDrvDrive & "\Uefi_Multi.ico") Then FileCopy(@ScriptDir & "\makebt\Uefi_Multi.ico", $WinDrvDrive & "\")
	EndIf

	SystemFileRedirect("On")

	; Create Windows BootManager Menu on USB if BCD Not exist
	If $DriveType="Removable" Or $usbfix Then
		If Not FileExists($TargetDrive & "\Boot\BCD") Or Not FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
			If FileExists(@WindowsDir & "\system32\bcdboot.exe") Then
				Sleep(2000)
				_WinLang()
				$bcdboot_flag = 1
				$g4d_default = 1
				If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And $PE_flag = 0 Then
					_GUICtrlStatusBar_SetText($hStatus," UEFI - Make Boot Manager Menu on USB " & $TargetDrive & " - wait .... ", 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
				Else
					If $PE_flag = 1 Then
						_GUICtrlStatusBar_SetText($hStatus," PE - Make Boot Manager Menu on USB " & $TargetDrive & " - wait .... ", 0)
						If $WinDir_PE_flag=0 Then
							$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $WinDir_PE & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
						Else
							$bcd_create_flag=1
							_BCD_Create()
						EndIf
					Else
						_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager Menu on USB Drive " & $TargetDrive & " - wait .... ", 0)
						$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive, @ScriptDir, @SW_HIDE)
					EndIf
				EndIf
				Sleep(1000)
				If FileExists($TargetDrive & "\Boot\BCD") Then
					RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
					& $TargetDrive & "\Boot\BCD" & " /set {default} bootmenupolicy legacy", @ScriptDir, @SW_HIDE)
					$store = $TargetDrive & "\Boot\BCD"
					$sdi_guid_outfile = "makebt\bs_temp\crea_sdi_guid.txt"
					$bcd_guid_outfile = "makebt\bs_temp\crea_pe_guid.txt"
					If $bcd_create_flag=0 Then _pe_boot_menu()
				EndIf
				If FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
					RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
					& $TargetDrive & "\EFI\Microsoft\Boot\BCD" & " /set {default} bootmenupolicy legacy", @ScriptDir, @SW_HIDE)
					$store = $TargetDrive & "\EFI\Microsoft\Boot\BCD"
					$sdi_guid_outfile = "makebt\bs_temp\crea_efi_sdi_guid.txt"
					$bcd_guid_outfile = "makebt\bs_temp\crea_efi_pe_guid.txt"
					If $bcd_create_flag=0 Then _pe_boot_menu()
				EndIf
				If FileExists($TargetDrive & "\Boot") Then FileSetAttrib($TargetDrive & "\Boot", "-RSH", 1)
				If FileExists($TargetDrive & "\bootmgr") Then FileSetAttrib($TargetDrive & "\bootmgr", "-RSH")
			EndIf
		EndIf
		; UEFI x64 Fix bootx64.efi and UEFI x86 Fix bootia32.efi
		If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And Not FileExists($TargetDrive & "\EFI\Boot\bootx64.efi") And @OSArch = "X64" Then
			If FileExists(@WindowsDir & "\Boot\EFI\bootmgfw.efi") And FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
				FileCopy(@WindowsDir & "\Boot\EFI\bootmgfw.efi", $TargetDrive & "\EFI\Boot\", 9)
				FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootx64.efi", 1)
			EndIf
		EndIf
		If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And Not FileExists($TargetDrive & "\EFI\Boot\bootia32.efi") And @OSArch = "X86" Then
			If FileExists(@WindowsDir & "\Boot\EFI\bootmgfw.efi") And FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
				FileCopy(@WindowsDir & "\Boot\EFI\bootmgfw.efi", $TargetDrive & "\EFI\Boot\", 9)
				FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootia32.efi", 1)
			EndIf
		EndIf
	Else
		If FileExists(@WindowsDir & "\system32\bcdedit.exe") And $PartStyle = "MBR" Then
			$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

			If Not FileExists($TargetDrive & "\Boot\BCD") Then
				Sleep(2000)
				DirCopy(@WindowsDir & "\Boot\PCAT", $TargetDrive & "\Boot", 1)
				DirCopy(@WindowsDir & "\Boot\Fonts", $TargetDrive & "\Boot\Fonts", 1)
				DirCopy(@WindowsDir & "\Boot\Resources", $TargetDrive & "\Boot\Resources", 1)
				If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi") Then
					FileCopy(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi", $TargetDrive & "\Boot\", 1)
				EndIf
				FileMove($TargetDrive & "\Boot\bootmgr", $TargetDrive & "\bootmgr", 1)
				FileMove($TargetDrive & "\Boot\bootnxt", $TargetDrive & "\BOOTNXT", 1)

				$store = $TargetDrive & "\Boot\BCD"
				RunWait(@ComSpec & " /c " & $bcdedit & " /createstore " & $store, $TargetDrive & "\", @SW_HIDE)
				sleep(1000)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {bootmgr}", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} description " & '"' & "Windows Boot Manager" & '"', $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} inherit {globalsettings}", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 20", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} toolsdisplayorder {memdiag}", $TargetDrive & "\", @SW_HIDE)
				; sleep(1000)

;~ 					$winload = "winload.exe"
;~ 					$bcd_guid_outfile = "makebt\bs_temp\hdd_crea_win_guid.txt"
;~ 					_win_boot_menu()

				$sdi_guid_outfile = "makebt\bs_temp\hdd_crea_sdi_guid.txt"
				$bcd_guid_outfile = "makebt\bs_temp\hdd_crea_pe_guid.txt"
				_pe_boot_menu()

				_mem_boot_menu()

				$g4d_default = 1
				$bcdboot_flag = 1

			EndIf

			If Not FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
				Sleep(2000)
				DirCopy(@WindowsDir & "\Boot\EFI", $TargetDrive & "\EFI\Microsoft\Boot", 1)
				DirCopy(@WindowsDir & "\Boot\Fonts", $TargetDrive & "\EFI\Microsoft\Boot\Fonts", 1)
				DirCopy(@WindowsDir & "\Boot\Resources", $TargetDrive & "\EFI\Microsoft\Boot\Resources", 1)
				If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\EFI\boot.sdi") Then
					FileCopy(@WindowsDir & "\Boot\DVD\EFI\boot.sdi", $TargetDrive & "\Boot\", 1)
				EndIf
				If FileExists(@WindowsDir & "\Boot\EFI\bootmgfw.efi") Then
					FileCopy(@WindowsDir & "\Boot\EFI\bootmgfw.efi", $TargetDrive & "\EFI\Boot\", 9)
					If @OSArch <> "X86" Then
						FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootx64.efi", 1)
					Else
						FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootia32.efi", 1)
					EndIf
				EndIf

				$store = $TargetDrive & "\EFI\Microsoft\Boot\BCD"
				RunWait(@ComSpec & " /c " & $bcdedit & " /createstore " & $store, $TargetDrive & "\", @SW_HIDE)
				sleep(1000)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {bootmgr}", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} description " & '"' & "UEFI Windows Boot Manager" & '"', $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} inherit {globalsettings}", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 20", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} toolsdisplayorder {memdiag}", $TargetDrive & "\", @SW_HIDE)
				; sleep(1000)

;~ 					$winload = "winload.exe"
;~ 					$bcd_guid_outfile = "makebt\bs_temp\hdd_crea_efi_win_guid.txt"
;~ 					_win_boot_menu()

				$sdi_guid_outfile = "makebt\bs_temp\hdd_crea_efi_sdi_guid.txt"
				$bcd_guid_outfile = "makebt\bs_temp\hdd_crea_efi_pe_guid.txt"
				_pe_boot_menu()

				_mem_boot_menu()

				; $g4d_default = 1
				$bcdboot_flag = 1

			EndIf
		EndIf
	EndIf

	SystemFileRedirect("Off")

	GUICtrlSetData($ProgressAll, 50)
	Sleep(2000)

	; Update existing grldr and grldr.mbr - Set Grub4dos entry default
	If GUICtrlRead($grldrUpd) = $GUI_CHECKED And $PartStyle = "MBR" Then
		If $DriveType="Removable" Or $usbfix Then $g4d_default = 1
		; If FileExists($TargetDrive & "\grldr") Then
		; 	FileSetAttrib($TargetDrive & "\grldr", "-RSH")
		; 	FileCopy($TargetDrive & "\grldr", $TargetDrive & "\grldr_old")
		; EndIf
		FileCopy(@ScriptDir & "\makebt\grldr", $TargetDrive & "\", 1)
		FileCopy(@ScriptDir & "\makebt\grub.exe", $TargetDrive & "\", 1)
		If FileExists($TargetDrive & "\grldr.mbr") Then FileCopy(@ScriptDir & "\makebt\grldr.mbr", $TargetDrive & "\", 1)
		; No forced update of menu.lst
		;	If FileExists($TargetDrive & "\menu.lst") Then
		;		FileSetAttrib($TargetDrive & "\menu.lst", "-RSH")
		;		FileCopy($TargetDrive & "\menu.lst", $TargetDrive & "\menu_old.lst")
		;	EndIf
		;	FileCopy(@ScriptDir & "\makebt\menu.lst", $TargetDrive & "\", 1)
		;	FileCopy(@ScriptDir & "\makebt\menu_Linux.lst", $TargetDrive & "\", 1)
		If FileExists(@ScriptDir & "\UEFI_MAN\grubfm.iso") And $ventoy=0 Then FileCopy(@ScriptDir & "\UEFI_MAN\grubfm.iso", $TargetDrive & "\", 1)
		If FileExists(@ScriptDir & "\UEFI_MAN\grub\core.img") And $ventoy=0 Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\core.img", $TargetDrive & "\grub\", 9)
	EndIf
	; Force Update UEFI Grub2 and UEFI Grub4dos
	If GUICtrlRead($grldrUpd) = $GUI_CHECKED Then
		If FileExists($TargetDrive & "\EFI\Boot\grubx64_real.efi") Then	FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubx64_real.efi", $TargetDrive & "\EFI\Boot\", 9)
		If FileExists($TargetDrive & "\EFI\Boot\grubia32_real.efi") Then FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubia32_real.efi", $TargetDrive & "\EFI\Boot\", 9)
		If FileExists($TargetDrive & "\EFI\Boot\bootx64_g4d.efi") Then FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\bootx64_g4d.efi", $TargetDrive & "\EFI\Boot\", 9)
		If FileExists($TargetDrive & "\EFI\Boot\bootia32_g4d.efi") Then	FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\bootia32_g4d.efi", $TargetDrive & "\EFI\Boot\", 9)
		If FileExists($TargetDrive & "\EFI\grub\ntfs_x64.efi") Then	FileCopy(@ScriptDir & "\UEFI_MAN\EFI\grub\ntfs_x64.efi", $TargetDrive & "\EFI\grub\", 9)
		If FileExists($TargetDrive & "\EFI\grub\tools")	Then DirCopy(@ScriptDir & "\UEFI_MAN\EFI\grub\tools", $TargetDrive & "\EFI\grub\tools", 1)
		If FileExists($TargetDrive & "\grub\vdiskchain") And FileExists(@ScriptDir & "\UEFI_MAN\grub\vdiskchain") And $ventoy=0 Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\vdiskchain", $TargetDrive & "\grub\", 9)
		If FileExists($TargetDrive & "\grub\ipxe.krn") And FileExists(@ScriptDir & "\UEFI_MAN\grub\ipxe.krn") And $ventoy=0 Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\ipxe.krn", $TargetDrive & "\grub\", 9)
	EndIf

	If $PartStyle = "MBR" Then
		If FileExists($TargetDrive & "\menu.lst") Then FileSetAttrib($TargetDrive & "\menu.lst", "-RSH")
		If Not FileExists($TargetDrive & "\grldr") Then FileCopy(@ScriptDir & "\makebt\grldr", $TargetDrive & "\", 1)
		If Not FileExists($TargetDrive & "\grub.exe") Then FileCopy(@ScriptDir & "\makebt\grub.exe", $TargetDrive & "\", 1)
		If Not FileExists($TargetDrive & "\menu.lst") Then FileCopy(@ScriptDir & "\makebt\menu.lst", $TargetDrive & "\", 1)
		If Not FileExists($TargetDrive & "\menu_distro.lst") Then FileCopy(@ScriptDir & "\makebt\menu_distro.lst", $TargetDrive & "\", 1)
		If Not FileExists($TargetDrive & "\menu_Linux.lst") Then FileCopy(@ScriptDir & "\makebt\menu_Linux.lst", $TargetDrive & "\", 1)
		If Not FileExists($TargetDrive & "\menu_Win_ISO.lst") Then FileCopy(@ScriptDir & "\makebt\menu_Win_ISO.lst", $TargetDrive & "\", 1)
		If Not FileExists($TargetDrive & "\grubfm.iso") And FileExists(@ScriptDir & "\UEFI_MAN\grubfm.iso") And $ventoy=0 Then FileCopy(@ScriptDir & "\UEFI_MAN\grubfm.iso", $TargetDrive & "\", 1)
		If Not FileExists($TargetDrive & "\grub\core.img") And $ventoy=0 Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\core.img", $TargetDrive & "\grub\", 9)
		; Support vdiskchain for Linux in VHD
		If Not FileExists($TargetDrive & "\grub\vdiskchain") And $ventoy=0 Then
			If FileExists(@ScriptDir & "\UEFI_MAN\grub\vdiskchain") Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\vdiskchain", $TargetDrive & "\grub\", 9)
		EndIf
		If Not FileExists($TargetDrive & "\grub\ipxe.krn") And $ventoy=0 Then
			If FileExists(@ScriptDir & "\UEFI_MAN\grub\ipxe.krn") Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\ipxe.krn", $TargetDrive & "\grub\", 9)
		EndIf
	EndIf

	; support UEFI Grub2
	If Not FileExists($TargetDrive & "\grub\grub.cfg") Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\grub.cfg", $TargetDrive & "\grub\", 9)
	If Not FileExists($TargetDrive & "\grub\grub_Linux.cfg") Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\grub_Linux.cfg", $TargetDrive & "\grub\", 9)
	If Not FileExists($TargetDrive & "\grub\grub_distro.cfg") Then FileCopy(@ScriptDir & "\UEFI_MAN\grub\grub_distro.cfg", $TargetDrive & "\grub\", 9)

	; support UEFI Grub4dos
	; If $DriveType="Removable" Or $usbfix Or $PartStyle = "GPT" Then
		If Not FileExists($TargetDrive & "\EFI\grub\menu.lst") Then
			FileCopy(@ScriptDir & "\UEFI_MAN\EFI\grub\menu.lst", $TargetDrive & "\EFI\grub\menu.lst", 9)
		EndIf
	; EndIf

	; requires sufficient space - available on USB - May be Not on internal EFI drive
	If $DriveType="Removable" Or $usbfix Then
		; support UEFI Grub2
		If Not FileExists($TargetDrive & "\EFI\Boot\grubx64_real.efi") Then
			FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubx64_real.efi", $TargetDrive & "\EFI\Boot\", 9)
		EndIf
		If Not FileExists($TargetDrive & "\EFI\Boot\grubia32_real.efi") Then
			FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubia32_real.efi", $TargetDrive & "\EFI\Boot\", 9)
		EndIf
		If FileExists(@ScriptDir & "\UEFI_MAN\EFI\grub\ntfs_x64.efi") And Not FileExists($TargetDrive & "\EFI\grub\ntfs_x64.efi") Then
			FileCopy(@ScriptDir & "\UEFI_MAN\EFI\grub\ntfs_x64.efi", $TargetDrive & "\EFI\grub\", 9)
		EndIf
		If FileExists(@ScriptDir & "\UEFI_MAN\EFI\grub\tools") And Not FileExists($TargetDrive & "\EFI\grub\tools") Then
			DirCopy(@ScriptDir & "\UEFI_MAN\EFI\grub\tools", $TargetDrive & "\EFI\grub\tools", 1)
		EndIf

		; support UEFI Grub4dos
		If Not FileExists($TargetDrive & "\EFI\Boot\bootx64_g4d.efi") Then
			FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\bootx64_g4d.efi", $TargetDrive & "\EFI\Boot\", 9)
		EndIf
		If Not FileExists($TargetDrive & "\EFI\Boot\bootia32_g4d.efi") Then
			FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\bootia32_g4d.efi", $TargetDrive & "\EFI\Boot\", 9)
		EndIf
	EndIf

	; make folder images for Linux ISO files
	If $ventoy=0 Then
		If $PartStyle = "MBR" Then
			If Not FileExists($TargetDrive & "\images") Then DirCreate($TargetDrive & "\images")
			If Not FileExists($TargetDrive & "\images\Linux_ISO_Files.txt") Then FileCopy(@ScriptDir & "\makebt\Linux_ISO_Files.txt", $TargetDrive & "\images\", 1)
			If Not FileExists($TargetDrive & "\images\kali-linux\persistence.7z") Then FileCopy(@ScriptDir & "\images\kali-linux\persistence.7z", $TargetDrive & "\images\kali-linux\", 9)
			If Not FileExists($TargetDrive & "\images\linuxmint\writable.7z") Then FileCopy(@ScriptDir & "\images\linuxmint\writable.7z", $TargetDrive & "\images\linuxmint\", 9)
			If Not FileExists($TargetDrive & "\images\porteus\data.7z") Then FileCopy(@ScriptDir & "\images\porteus\data.7z", $TargetDrive & "\images\porteus\", 9)
			If Not FileExists($TargetDrive & "\images\ubuntu\writable.7z") Then FileCopy(@ScriptDir & "\images\ubuntu\writable.7z", $TargetDrive & "\images\ubuntu\", 9)
		EndIf
	Else
		If Not FileExists($WinDrvDrive & "\images") Then DirCreate($WinDrvDrive & "\images")
		If Not FileExists($WinDrvDrive & "\images\Linux_ISO_Files.txt") Then FileCopy(@ScriptDir & "\makebt\Linux_ISO_Files.txt", $WinDrvDrive & "\images\", 1)
		If Not FileExists($TargetDrive & "\images\kali-linux\persistence.7z") Then FileCopy(@ScriptDir & "\images\kali-linux\persistence.7z", $TargetDrive & "\images\kali-linux\", 9)
		If Not FileExists($TargetDrive & "\images\linuxmint\writable.7z") Then FileCopy(@ScriptDir & "\images\linuxmint\writable.7z", $TargetDrive & "\images\linuxmint\", 9)
		If Not FileExists($TargetDrive & "\images\porteus\data.7z") Then FileCopy(@ScriptDir & "\images\porteus\data.7z", $TargetDrive & "\images\porteus\", 9)
		If Not FileExists($TargetDrive & "\images\ubuntu\writable.7z") Then FileCopy(@ScriptDir & "\images\ubuntu\writable.7z", $TargetDrive & "\images\ubuntu\", 9)
		FileCopy(@ScriptDir & "\UEFI_MAN\efi_mint\boot\grub_Linux.cfg", $TargetDrive & "\", 8)
	EndIf

	; NTLDR BootSector XP
	If $g4d_vista = 0 And $PartStyle = "MBR" Then
		If FileExists($TargetDrive & "\boot.ini") Then
			FileSetAttrib($TargetDrive & "\boot.ini", "-RSH")
			FileCopy($TargetDrive & "\boot.ini", $TargetDrive & "\boot_ini.txt", 1)
			IniWrite($TargetDrive & "\boot.ini", "Operating Systems", "C:\grldr", '"Start Grub4dos - XP Menu"')
			IniWrite($TargetDrive & "\boot.ini", "Boot Loader", "Timeout", 20)
		Else
			IniWriteSection($TargetDrive & "\boot.ini", "Boot Loader", "Timeout=20" & @LF & _
			"Default=C:\grldr")
			IniWrite($TargetDrive & "\boot.ini", "Operating Systems", "C:\grldr", '"Start Grub4dos - XP Menu"')
		EndIf

		If Not FileExists($TargetDrive & "\BOOTFONT.BIN") And FileExists(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN") Then
			FileCopy(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN", $TargetDrive & "\", 1)
		EndIf

	;	use modified ntdetect if exists in makebt folder
		If Not FileExists($TargetDrive & "\NTDETECT.COM") Then
			If FileExists(@ScriptDir & "\makebt\ntdetect.com") Then
				FileCopy(@ScriptDir & "\makebt\ntdetect.com", $TargetDrive & "\", 1)
			Else
				If FileExists(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM") Then FileCopy(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM", $TargetDrive & "\", 1)
			EndIf
		EndIf

		If Not FileExists($TargetDrive & "\ntldr") And FileExists(@ScriptDir & "\makebt\Boot_XP\NTLDR") Then
			FileCopy(@ScriptDir & "\makebt\Boot_XP\NTLDR", $TargetDrive & "\", 1)
		EndIf
	EndIf

	GUICtrlSetData($ProgressAll, 55)

	If $ContentSource <> "" Then
		If GUICtrlRead($Combo_Folder) = "Folder on B" And $content_folder = "Programs" And FileExists(@ScriptDir & "\makebt\CDUsb.y") Then
			If Not FileExists($TargetDrive & "\CDUsb.y") Then FileCopy(@ScriptDir & "\makebt\CDUsb.y", $TargetDrive & "\", 1)
		EndIf
		If Not $FSObjFlag Then
			$pausecopy = 1
			_GUICtrlStatusBar_SetText($hStatus," Preparing FileList Content Source", 0)
			GUICtrlSetData($ProgressAll, 0)
			$NrCpdFiles = 0

			$FileList = _FileSearch($ContentSource, "*.*", 0, @ScriptDir & "\makebt\Exclude_Copy_USB.txt")
			$sl = StringLen($ContentSource)
			If GUICtrlRead($Combo_Folder) = "Folder on B" And $content_folder <> "" Then
				$dest = $TargetDrive & "\" & $content_folder
			ElseIf GUICtrlRead($Combo_Folder) = "Folder on S" And $content_folder <> "" Then
				$dest = $WinDrvDrive & "\" & $content_folder
			ElseIf GUICtrlRead($Combo_Folder) = "System Drive" Then
				$dest = $WinDrvDrive
			Else
				$dest = $TargetDrive
			EndIf
			; _ArrayDisplay($FileList)
			_CopyDirWithProgress($FileList, $dest, $sl, $FileList[0], 1)

			$pausecopy = 0
		Else
			_GUICtrlStatusBar_SetText($hStatus," Copying " & $content_folder & " to " & $TargetDrive & " - wait .... ", 0)
			_GUICtrlStatusBar_SetText($hStatus,"", 1)
			_GUICtrlStatusBar_SetText($hStatus,"", 2)
			GUICtrlSetData($ProgressAll, 70)
			MsgBox(0, "WARNING - Using DirCopy", "Copy Progress Indicator NOT Available in LiveXP " & @CRLF & @CRLF & "Will use DirCopy without FileList Counter ", 3)
			If $ContentSource <> ""  Then
				If GUICtrlRead($Combo_Folder) = "Folder on B" And $content_folder <> "" Then
					DirCopy($ContentSource, $TargetDrive& "\" & $content_folder, 1)
				ElseIf GUICtrlRead($Combo_Folder) = "Folder on S" And $content_folder <> "" Then
					DirCopy($ContentSource, $WinDrvDrive& "\" & $content_folder, 1)
				ElseIf GUICtrlRead($Combo_Folder) = "System Drive" Then
					DirCopy($ContentSource, $WinDrvDrive, 1)
				Else
					DirCopy($ContentSource, $TargetDrive, 1)
				EndIf
			EndIf
			GUICtrlSetData($ProgressAll, 100)
		EndIf
	EndIf

	GUICtrlSetData($ProgressAll, 60)

	Sleep(1000)
	_GUICtrlStatusBar_SetText($hStatus,"", 1)
	_GUICtrlStatusBar_SetText($hStatus,"", 2)

	SystemFileRedirect("On")

	If @OSVersion <> "WIN_VISTA" And @OSVersion <> "WIN_2003" And @OSVersion <> "WIN_XP" And @OSVersion <> "WIN_XPe" And @OSVersion <> "WIN_2000" Then
		If GUICtrlRead($Boot_w8) = $GUI_CHECKED Then
			$bcdboot_flag = 1
			If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
				_GUICtrlStatusBar_SetText($hStatus," UEFI x64 Add Win 8/10 to BootManager on " & $TargetDrive & " - wait .... ", 0)
				If $PartStyle = "MBR" Then
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $WinDrvDrive & $WinFol & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
				Else
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $WinDrvDrive & $WinFol & " /s " & $TargetDrive & " /f UEFI", @ScriptDir, @SW_HIDE)
				EndIf
			ElseIf FileExists($WinDrvDrive & $WinFol & "\system32\bcdboot.exe") And FileExists($WinDrvDrive & $WinFol & "\Boot") And FileExists($WinDrvDrive & $WinFol & "\System32\config\DRIVERS") And @OSArch <> "X86" Then
				_GUICtrlStatusBar_SetText($hStatus," Add Win 8/10 to BootManager on Boot Drive " & $TargetDrive & " - wait .... ", 0)
				If $PartStyle = "MBR" Then
					$val = RunWait(@ComSpec & " /c " & $WinDrvDrive & $WinFol & "\system32\bcdboot.exe " & $WinDrvDrive & $WinFol & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
				Else
					$val = RunWait(@ComSpec & " /c " & $WinDrvDrive & $WinFol & "\system32\bcdboot.exe " & $WinDrvDrive & $WinFol & " /s " & $TargetDrive & " /f UEFI", @ScriptDir, @SW_HIDE)
				EndIf
			Else
				_GUICtrlStatusBar_SetText($hStatus," Add Win 7/8 to BootManager on Boot Drive " & $TargetDrive & " - wait .... ", 0)
				$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $WinDrvDrive & $WinFol & " /s " & $TargetDrive, @ScriptDir, @SW_HIDE)
			EndIf
			Sleep(2000)
			If FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
				RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
				& $TargetDrive & "\EFI\Microsoft\Boot\BCD" & " /set {default} bootmenupolicy legacy", @ScriptDir, @SW_HIDE)
				If FileExists($WinDrvDrive & $WinFol & "\SysWOW64") And FileExists($WinDrvDrive & $WinFol & "\System32\drivers\firadisk.sys") Then
					RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
					& $TargetDrive & "\EFI\Microsoft\Boot\BCD" & " /set {default} testsigning on", @ScriptDir, @SW_HIDE)
				EndIf
			EndIf
			If FileExists($TargetDrive & "\Boot\BCD") Then
				RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
				& $TargetDrive & "\Boot\BCD" & " /set {default} bootmenupolicy legacy", @ScriptDir, @SW_HIDE)
				If FileExists($WinDrvDrive & $WinFol & "\SysWOW64") And FileExists($WinDrvDrive & $WinFol & "\System32\drivers\firadisk.sys") Then
					RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
					& $TargetDrive & "\Boot\BCD" & " /set {default} testsigning on", @ScriptDir, @SW_HIDE)
				EndIf
				If FileExists($TargetDrive & "\Boot") Then FileSetAttrib($TargetDrive & "\Boot", "-RSH", 1)
				If FileExists($TargetDrive & "\bootmgr") Then FileSetAttrib($TargetDrive & "\bootmgr", "-RSH")
			EndIf
		EndIf
		; to get PE ProgressBar and Win 8 Boot Manager Menu displayed and waiting for User Selection
		If FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
			RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
			& $TargetDrive & "\EFI\Microsoft\Boot\BCD" & " /bootems {emssettings} ON", @ScriptDir, @SW_HIDE)
		EndIf
		If FileExists($TargetDrive & "\Boot\BCD") Then
			RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdedit.exe" & " /store " _
			& $TargetDrive & "\Boot\BCD" & " /bootems {emssettings} ON", @ScriptDir, @SW_HIDE)
		EndIf
	EndIf

	SystemFileRedirect("Off")

	; Only on USB Drives
	If $usbfix And GUICtrlRead($refind) = $GUI_CHECKED And $PartStyle = "MBR" And $ventoy=0 Then
		; Keep AIO files if present
		If Not FileExists($TargetDrive & "\AIO\grub\grub.cfg") And Not FileExists($TargetDrive & "\AIO\grub\Main.cfg") Then
			If GUICtrlRead($Combo_EFI) <> "MBR  Only" Then
				If FileExists($TargetDrive & "\EFI\Boot\bootx64.efi") And Not FileExists($TargetDrive & "\EFI\Boot\bootx64_win.efi") Then
					FileMove($TargetDrive & "\EFI\Boot\bootx64.efi", $TargetDrive & "\EFI\Boot\bootx64_win.efi", 1)
				EndIf
				If GUICtrlRead($Combo_EFI) = "Super UEFI" Or GUICtrlRead($Combo_EFI) = "Super + MBR" And FileExists($TargetDrive & "\EFI\Boot\bootia32.efi") And Not FileExists($TargetDrive & "\EFI\Boot\bootia32_win.efi") Then
					FileMove($TargetDrive & "\EFI\Boot\bootia32.efi", $TargetDrive & "\EFI\Boot\bootia32_win.efi", 1)
				EndIf
				If Not FileExists($TargetDrive & "\EFI\Microsoft\Boot\bootmgfw.efi") And @OSArch = "X64" Then
					If FileExists(@WindowsDir & "\Boot\EFI\bootmgfw.efi") And FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
						FileCopy(@WindowsDir & "\Boot\EFI\bootmgfw.efi", $TargetDrive & "\EFI\Microsoft\Boot\", 0)
					EndIf
				EndIf
				If FileExists($TargetDrive & "\EFI\Boot\grubx64.efi") And Not FileExists($TargetDrive & "\EFI\Boot\org-grubx64.efi") Then
					FileMove($TargetDrive & "\EFI\Boot\grubx64.efi", $TargetDrive & "\EFI\Boot\org-grubx64.efi", 1)
				EndIf
			EndIf
			; Settings "Mint   UEFI|Super UEFI|Mint + MBR|Super + MBR|MBR  Only"
			If GUICtrlRead($Combo_EFI) = "Mint   UEFI" Or GUICtrlRead($Combo_EFI) = "Mint + MBR" Then
				_GUICtrlStatusBar_SetText($hStatus," Adding Linux Mint Grub2 EFI Manager - wait .... ", 0)
				DirCopy(@ScriptDir & "\UEFI_MAN\efi_mint", $TargetDrive & "\efi", 1)
				If FileExists($TargetDrive & "\boot\grub\grub.cfg") Then
					FileMove($TargetDrive & "\boot\grub\grub.cfg", $TargetDrive & "\boot\grub\org-grub.cfg", 1)
				EndIf
				FileCopy(@ScriptDir & "\UEFI_MAN\boot\grub\grub.cfg", $TargetDrive & "\boot\grub\", 9)
				FileCopy(@ScriptDir & "\UEFI_MAN\boot\grub\grub_Linux.cfg", $TargetDrive & "\boot\grub\", 9)
				; If Not FileExists($TargetDrive & "\grubfm.iso") And FileExists(@ScriptDir & "\UEFI_MAN\grubfm.iso") Then FileCopy(@ScriptDir & "\UEFI_MAN\grubfm.iso", $TargetDrive & "\", 1)
			ElseIf GUICtrlRead($Combo_EFI) = "Super UEFI" Or GUICtrlRead($Combo_EFI) = "Super + MBR" Then
				_GUICtrlStatusBar_SetText($hStatus," Adding Super Grub2 EFI Manager - wait .... ", 0)
				; DirCopy(@ScriptDir & "\UEFI_MAN\efi", $TargetDrive & "\efi", 1)
				DirCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot", $TargetDrive & "\EFI\Boot", 1)
				If FileExists(@ScriptDir & "\UEFI_MAN\EFI\grub\ntfs_x64.efi") Then FileCopy(@ScriptDir & "\UEFI_MAN\EFI\grub\ntfs_x64.efi", $TargetDrive & "\EFI\grub\", 9)
				If Not FileExists($TargetDrive & "\EFI\memtest86") And FileExists(@ScriptDir & "\UEFI_MAN\EFI\memtest86") Then
					DirCopy(@ScriptDir & "\UEFI_MAN\EFI\memtest86", $TargetDrive & "\EFI\memtest86", 1)
				EndIf

				If FileExists(@ScriptDir & "\UEFI_MAN\grub_a1") And GUICtrlRead($Add_Grub2_Sys) = $GUI_CHECKED Then
					DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\x86_64-efi", $TargetDrive & "\grub\x86_64-efi", 1)
					DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\i386-efi", $TargetDrive & "\grub\i386-efi", 1)
					DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\locale", $TargetDrive & "\grub\locale", 1)
 					DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\fonts", $TargetDrive & "\grub\fonts", 1)
				EndIf
				;	If FileExists(@ScriptDir & "\UEFI_MAN\grub2") Then
				;		GUICtrlSetData($ProgressAll, 75)
				;		_GUICtrlStatusBar_SetText($hStatus," Adding Grub2Win for BIOS mode - wait .... ", 0)
				;		DirCopy(@ScriptDir & "\UEFI_MAN\grub2", $TargetDrive & "\grub2", 1)
				;	EndIf
				If FileExists(@ScriptDir & "\UEFI_MAN\ENROLL_THIS_KEY_IN_MOKMANAGER.cer") Then FileCopy(@ScriptDir & "\UEFI_MAN\ENROLL_THIS_KEY_IN_MOKMANAGER.cer", $TargetDrive & "\", 1)
				; If Not FileExists($TargetDrive & "\grubfm.iso") And FileExists(@ScriptDir & "\UEFI_MAN\grubfm.iso") Then FileCopy(@ScriptDir & "\UEFI_MAN\grubfm.iso", $TargetDrive & "\", 1)
				; DirCopy(@ScriptDir & "\UEFI_MAN\iso", $TargetDrive & "\iso", 1)
			Else
				; Nothing
			EndIf
		Else
			If FileExists($TargetDrive & "\boot\grub\grub.cfg") Then
				FileMove($TargetDrive & "\boot\grub\grub.cfg", $TargetDrive & "\boot\grub\org-grub.cfg", 1)
			EndIf
			If FileExists($TargetDrive & "\EFI\grub\grub.cfg") Then
				FileMove($TargetDrive & "\EFI\grub\grub.cfg", $TargetDrive & "\EFI\grub\org-grub.cfg", 1)
			EndIf
			If FileExists(@ScriptDir & "\UEFI_MAN\loadfm") Then FileCopy(@ScriptDir & "\UEFI_MAN\loadfm", $TargetDrive & "\AIO\grubfm", 9)
			If FileExists(@ScriptDir & "\UEFI_MAN\grubfm.iso") Then FileCopy(@ScriptDir & "\UEFI_MAN\grubfm.iso", $TargetDrive & "\AIO\grubfm", 9)
			If FileExists(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubfmx64.efi") Then FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubfmx64.efi", $TargetDrive & "\AIO\grubfm", 9)
			If FileExists(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubfmia32.efi") Then FileCopy(@ScriptDir & "\UEFI_MAN\EFI\Boot\grubfmia32.efi", $TargetDrive & "\AIO\grubfm", 9)
			If Not FileExists($TargetDrive & "\EFI\memtest86") And FileExists(@ScriptDir & "\UEFI_MAN\EFI\memtest86") Then
				DirCopy(@ScriptDir & "\UEFI_MAN\EFI\memtest86", $TargetDrive & "\EFI\memtest86", 1)
			EndIf
			If Not FileExists($TargetDrive & "\grub\x86_64-efi") And FileExists(@ScriptDir & "\UEFI_MAN\grub_a1") And GUICtrlRead($Add_Grub2_Sys) = $GUI_CHECKED  Then
				DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\x86_64-efi", $TargetDrive & "\grub\x86_64-efi", 1)
				DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\i386-efi", $TargetDrive & "\grub\i386-efi", 1)
 				DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\locale", $TargetDrive & "\grub\locale", 1)
 				DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\fonts", $TargetDrive & "\grub\fonts", 1)
			EndIf
		EndIf

		; MBR BIOS mode cases - Install Grub2 in MBR
		If GUICtrlRead($Combo_EFI) = "Mint + MBR" Or GUICtrlRead($Combo_EFI) = "Super + MBR" Or GUICtrlRead($Combo_EFI) = "MBR  Only" And FileExists(@ScriptDir & "\UEFI_MAN\grub_a1\grub-install.exe") And $inst_disk <> "" Then
			_GUICtrlStatusBar_SetText($hStatus," Adding a1ive Grub2 Manager in MBR - wait .... ", 0)
			; Grub2 Install OK if $g2_inst = 0
			$g2_inst = RunWait(@ComSpec & " /c UEFI_MAN\grub_a1\grub-install.exe  --boot-directory=" & $TargetDrive & "\ --target=i386-pc //./PHYSICALDRIVE" & $inst_disk, @ScriptDir, @SW_HIDE)
			;	MsgBox(48, "Grub2 in MBR", "Grub2 Installed in MBR - $g2_inst = " & $g2_inst & @CRLF & @CRLF _
			;	& "Target Drive = " & $TargetDrive & "   HDD = " & $inst_disk & @CRLF & @CRLF & "Bus Type = " & $BusType & "   Drive Type = " & $DriveType)
			$grub2=1
		EndIf

		; Add Grub2 System not available or not needed
		If GUICtrlRead($Combo_EFI) = "Mint   UEFI" And $g2_inst = 1 Then
			GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
		EndIf

		; If FileExists($TargetDrive & "\grub\grub.cfg") And Not FileExists($TargetDrive & "\grub\org-grub.cfg") Then
		; 	FileMove($TargetDrive & "\grub\grub.cfg", $TargetDrive & "\grub\org-grub.cfg", 1)
		; EndIf

		If FileExists(@ScriptDir & "\UEFI_MAN\grub_glim") And GUICtrlRead($Combo_EFI) <> "Mint   UEFI" Then
			DirCopy(@ScriptDir & "\UEFI_MAN\grub_glim", $TargetDrive & "\grub", 1)
		EndIf
		; MBR BIOS mode Grub2 System support
		If $g2_inst = 0 Or GUICtrlRead($Add_Grub2_Sys) = $GUI_CHECKED And Not FileExists($TargetDrive & "\grub\i386-pc") And FileExists(@ScriptDir & "\UEFI_MAN\grub_a1") Then
			_GUICtrlStatusBar_SetText($hStatus," Adding MBR BIOS a1ive Grub2 System - wait .... ", 0)
			DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\i386-pc", $TargetDrive & "\grub\i386-pc", 1)
			If Not FileExists($TargetDrive & "\grub\fonts") Then
				DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\locale", $TargetDrive & "\grub\locale", 1)
				DirCopy(@ScriptDir & "\UEFI_MAN\grub_a1\fonts", $TargetDrive & "\grub\fonts", 1)
			EndIf
		EndIf
		If Not FileExists($TargetDrive & "\iso") And FileExists(@ScriptDir & "\UEFI_MAN\iso") And GUICtrlRead($Combo_EFI) <> "Mint   UEFI" Then DirCopy(@ScriptDir & "\UEFI_MAN\iso", $TargetDrive & "\iso", 1)
		; make folder images for Linux ISO files
		If Not FileExists($TargetDrive & "\images") Then DirCreate($TargetDrive & "\images")
		If Not FileExists($TargetDrive & "\images\Linux_ISO_Files.txt") Then FileCopy(@ScriptDir & "\makebt\Linux_ISO_Files.txt", $TargetDrive & "\images\", 1)
		If Not FileExists($TargetDrive & "\images\kali-linux\persistence.7z") Then FileCopy(@ScriptDir & "\images\kali-linux\persistence.7z", $TargetDrive & "\images\kali-linux\", 9)
		If Not FileExists($TargetDrive & "\images\linuxmint\writable.7z") Then FileCopy(@ScriptDir & "\images\linuxmint\writable.7z", $TargetDrive & "\images\linuxmint\", 9)
		If Not FileExists($TargetDrive & "\images\porteus\data.7z") Then FileCopy(@ScriptDir & "\images\porteus\data.7z", $TargetDrive & "\images\porteus\", 9)
		If Not FileExists($TargetDrive & "\images\ubuntu\writable.7z") Then FileCopy(@ScriptDir & "\images\ubuntu\writable.7z", $TargetDrive & "\images\ubuntu\", 9)
		; Add \AIO\grub\grub2win to \Boot\BCD Menu for BIOS support of Grub2
		If FileExists($TargetDrive & "\AIO\grub\grub2win") Then
			_bcd_grub2()
		EndIf
		;	If FileExists($TargetDrive & "\grub2\g2bootmgr\gnugrub.kernel.bios") Then
		;		_bcd_grub2win()
		;	EndIf
	Else
		GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
		GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)
	EndIf

	; Old code to Add grub2win to internal MBR HDD Boot\BCD - case "Other" - now case "MBR  Only"
;~ 				If FileExists($TargetDrive & "\grub2\g2bootmgr\gnugrub.kernel.bios") Then
;~ 					_bcd_grub2win()
;~ 				EndIf
;~ 			ElseIf $usbfix=0 And $Target_MBR_FAT32 = 1 And GUICtrlRead($refind) = $GUI_CHECKED Then
;~ 				If GUICtrlRead($Combo_EFI) = "Other" Then
;~ 					If FileExists(@ScriptDir & "\UEFI_MAN\grub2") Then
;~ 						GUICtrlSetData($ProgressAll, 75)
;~ 						_GUICtrlStatusBar_SetText($hStatus," Adding Grub2Win for BIOS mode - wait .... ", 0)
;~ 						DirCopy(@ScriptDir & "\UEFI_MAN\grub2", $TargetDrive & "\grub2", 1)
;~ 					EndIf
;~ 					DirCopy(@ScriptDir & "\UEFI_MAN\iso", $TargetDrive & "\iso", 1)
;~ 					If FileExists($TargetDrive & "\grub2\g2bootmgr\gnugrub.kernel.bios") Then
;~ 						_bcd_grub2win()
;~ 					EndIf
;~ 				EndIf
;~ 			Else
;~ 				GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)
;~ 			EndIf

	SystemFileRedirect("On")

	GUICtrlSetData($ProgressAll, 70)

	$FSvar_WinDrvDrive = DriveGetFileSystem($WinDrvDrive)

	If $btimgfile <> "" Then

		If GUICtrlRead($ImageType) = "WinPE - WIM" And StringLeft($btimgfile, 2) = $WinDrvDrive Then $WimOnSystemDrive = 1
		If GUICtrlRead($ImageType) = "WinPE - WIM" And StringLeft($btimgfile, 2) = $TargetDrive Then $WimOnSystemDrive = 0

		If GUICtrlRead($ImageType) = "XP Rec Cons - IMG" And $PartStyle = "MBR" Then
			_GUICtrlStatusBar_SetText($hStatus," Making  Entry in Grub4dos Boot Menu - wait ....", 0)
			_RC_IMG()
		ElseIf GUICtrlRead($ImageType) = "FreeDOS - IMG" Or GUICtrlRead($ImageType) = "MS-DOS - IMG" And $PartStyle = "MBR" Then
			_GUICtrlStatusBar_SetText($hStatus," Making  Entry in Grub4dos Boot Menu - wait ....", 0)
			If FileExists($TargetDrive & "\menu.lst") Then _g4d_sf_img_menu()
		ElseIf GUICtrlRead($ImageType) = "LiveXP BootSDI - IMG" Or GUICtrlRead($ImageType) = "BartPE - ISO" And $PartStyle = "MBR" Then
			_GUICtrlStatusBar_SetText($hStatus," Making  Entry in Grub4dos Boot Menu - wait ....", 0)
			_BT_IMG()
		ElseIf GUICtrlRead($ImageType) = "CD - ISO" Or GUICtrlRead($ImageType) = "WinPE - ISO" And $PartStyle = "MBR" Then
			_GUICtrlStatusBar_SetText($hStatus," Making  Entry in Grub4dos Boot Menu - wait ....", 0)
			If FileExists($TargetDrive & "\menu.lst") Then _g4d_cd_iso_menu()
		ElseIf GUICtrlRead($ImageType) = "WinPE - WIM" Then
			_wim_menu()
		Else
			If GUICtrlRead($ImageType) = "VHD - IMG" Then
				If @OSVersion <> "WIN_VISTA" And @OSVersion <> "WIN_2003" And @OSVersion <> "WIN_XP" And @OSVersion <> "WIN_XPe" And @OSVersion <> "WIN_2000" Then
					If $img_fext = "vhd" Or $img_fext = "vhdx" Then
						_vhd_menu()
						Sleep(1000)
						; VHDX incompatible with Grub4dos
						If $img_fext = "vhdx" Then $g4d_w7vhd_flag=0
						_UEFI_RAMOS()
					EndIf
				EndIf
				If $g4d_w7vhd_flag=1 And $PartStyle = "MBR"  And $mbr_gpt_vhd_flag = "MBR" Then
					_GUICtrlStatusBar_SetText($hStatus," Making  Entry in Grub4dos Boot Menu - wait ....", 0)
					If FileExists($TargetDrive & "\menu.lst") Then _g4d_hdd_img_menu()
				EndIf
			EndIf
		EndIf
	EndIf

	Sleep(2000)

	If $PartStyle = "MBR" Then
		_bcd_menu()
	Else
		GUICtrlSetState($g4d_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($xp_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
	EndIf

	If FileExists($TargetDrive & "\bootmgr") Then
		FileSetAttrib($TargetDrive & "\Boot", "-RSH", 1)
		FileSetAttrib($TargetDrive & "\bootmgr", "-RSH")
	EndIf

	; Add always Boot\boot.sdi for PE WIM and Boot\bootvhd.dll for booting VHD in BIOS mode
	If FileExists($TargetDrive & "\Boot\BCD") And $PartStyle = "MBR" Then
		If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi") Then
			FileCopy(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi", $TargetDrive & "\Boot\", 9)
		EndIf
		If Not FileExists($TargetDrive & "\Boot\bootvhd.dll") And FileExists(@WindowsDir & "\Boot\PCAT\bootvhd.dll") Then
			FileCopy(@WindowsDir & "\Boot\PCAT\bootvhd.dll", $TargetDrive & "\Boot\", 9)
		EndIf
	EndIf

	SystemFileRedirect("Off")

	GUICtrlSetData($ProgressAll, 80)
	Sleep(1000)

	If GUICtrlRead($ImageType) = "LiveXP BootSDI - IMG" Or GUICtrlRead($ImageType) = "BartPE - ISO" Or GUICtrlRead($ImageType) = "XP Rec Cons - IMG" Then
		If Not FileExists($TargetDrive & "\BOOTFONT.BIN") Then
			MsgBox(48, "WARNING - XP File BOOTFONT.BIN is Missing ", "Solution - Run UEFI_MULTI once in XP OS " & @CRLF & @CRLF _
			& " Or add BOOTFONT.BIN manually to makebt\Boot_XP folder " & @CRLF & @CRLF _
			& " Add BOOTFONT.BIN manually to Boot Drive " & $TargetDrive, 0)
		EndIf
	EndIf

	; NTLDR BootSector and NT MBR
	If $g4d_vista=0 And $xpmbr=1 And $grub2=0 And $PartStyle = "MBR" Or GUICtrlRead($xp_bcd) = $GUI_CHECKED Then
		If Not FileExists($TargetDrive & "\NTLDR") Then
			MsgBox(48, "WARNING - File NTLDR Needed to Enable Boot XP ", " Missing File makebt\Boot_XP\NTLDR " & @CRLF & @CRLF _
			& " Solution - Run UEFI_MULTI once in XP OS " & @CRLF & @CRLF _
			& " Or add NTLDR manually to makebt\Boot_XP folder " & @CRLF & @CRLF _
			& " Enable Boot XP - Add NTLDR manually to Boot Drive " & $TargetDrive, 0)
		EndIf
	EndIf

	GUICtrlSetData($ProgressAll, 100)

	If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" Then
		If FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") And Not FileExists($TargetDrive & "\EFI\Boot\bootx64.efi") Then
			_GUICtrlStatusBar_SetText($hStatus," WARNING - UEFI x64 needs file bootx64.efi ", 0)
			MsgBox(64, " WARNING - UEFI x64 needs file bootx64.efi ", " UEFI x64 needs file efi\boot\bootx64.efi " & @CRLF & @CRLF _
			& $TargetDrive & "\EFI\Boot\bootx64.efi is missing on Target Boot Drive " & @CRLF & @CRLF _
			& " Get from Win 8/10 x64 OS file Windows\Boot\EFI\bootmgfw.efi " & @CRLF & @CRLF _
			& " Copy file bootmgfw.efi as bootx64.efi in " & $TargetDrive & "\EFI\Boot" )
		EndIf
	EndIf
;~ 		If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And Not FileExists($TargetDrive & "\EFI\Boot\bootia32.efi") And Not FileExists($TargetDrive & "\EFI\Boot\bootx64.efi") Then
;~ 			_GUICtrlStatusBar_SetText($hStatus," WARNING - UEFI x86 needs file bootia32.efi ", 0)
;~ 			MsgBox(64, " WARNING - UEFI x86 needs file bootia32.efi ", " BIOS boot OK, but UEFI x86 needs file efi\boot\bootia32.efi " & @CRLF & @CRLF _
;~ 			& $TargetDrive & "\EFI\Boot\bootia32.efi is missing on Target Boot Drive " & @CRLF & @CRLF _
;~ 			& " Get from Win 8/10 x86 OS file Windows\Boot\EFI\bootmgfw.efi " & @CRLF & @CRLF _
;~ 			& " Copy file bootmgfw.efi as bootia32.efi in " & $TargetDrive & "\EFI\Boot" )
;~ 		EndIf


	If $driver_flag = 0 And StringRight($vhdfile_name, 4) = ".vhd" And $BTIMGSize < 15000 Then
		MsgBox(48, "WARNING - SVBus Driver Missing ", " SVBus driver is needed for booting from RAMDISK " & @CRLF _
		& @CRLF & " First Boot as FILEDISK from Windows Boot Manager " & @CRLF _
		& @CRLF & " 1. Install SVBus EVRootCA Registry Fix in runnung Windows " & @CRLF _
		& @CRLF & " 2. Install SVBus Driver as Admin " & @CRLF _
		& @CRLF & " - use R-mouse on instx64.exe in SVBus-signed_2 folder " & @CRLF _
		& @CRLF & " - Reboot first as FILEDISK from Windows Boot Manager ")
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," End of Program Or Again ?", 0)
	$ikey = MsgBox(48+4+256, " END OF PROGRAM Or Again ? ", " End of Program  - OK - Enter to Finish " & @CRLF _
	& @CRLF & " After Reboot Select Boot Image from Menu " & @CRLF _
	& @CRLF & " Run Again to Add Other Boot Image ? ")

	If $ikey = 6 Then
		GUICtrlSetData($ImageType, "")
		GUICtrlSetData($ImageSize, "")
		GUICtrlSetData($IMG_File, "")
		$btimgfile = ""
		$vhdfolder = ""
		$vhdfile_name = ""
		$vhdfile_name_only = ""
		$image_file=""
		$img_fext=""
		$bootsdi = ""
		$BTIMGSize=0
		$img_folder = ""

		$ContentSource = ""
		$content_folder = ""
		GUICtrlSetData($AddContentSource, "")
		$ContentSize=0
		GUICtrlSetData($GUI_ContentSize, "")

		GUICtrlSetData($ProgressAll, 0)
		GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED)
		GUICtrlSetState($grldrUpd, $GUI_UNCHECKED)

		GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Boot_w8, $GUI_UNCHECKED + $GUI_DISABLE)
		$w78sys=0

		GUICtrlSetState($g4d_bcd, $GUI_UNCHECKED)
		GUICtrlSetState($xp_bcd, $GUI_UNCHECKED)
		GUICtrlSetState($Add_Grub2_Sys, $GUI_UNCHECKED)
		GUICtrlSetState($refind, $GUI_UNCHECKED)

		GUICtrlSetState($TargetSel, $GUI_ENABLE)
		GUICtrlSetState($WinDrvSel, $GUI_ENABLE)

		GUICtrlSetState($Menu_Type, $GUI_DISABLE)

		DisableMenus(0)
	Else
		Exit
	EndIf

EndFunc ;==> _Go
;===================================================================================================
Func _Copy_BSU()
	Local $pos=0, $ntpos=0, $bmpos=0, $ikey, $grpos=0

	$g4d = 0
	$g4d_vista = 2

;	If FileExists(@ScriptDir & "\makebt\bs_temp") Then DirRemove(@ScriptDir & "\makebt\bs_temp",1)
	If Not FileExists(@ScriptDir & "\makebt\bs_temp") Then DirCreate(@ScriptDir & "\makebt\bs_temp")

	RunWait(@ComSpec & " /c makebt\dsfo.exe \\.\" & $TargetDrive & " 0 512 makebt\bs_temp\Back512.bs", @ScriptDir, @SW_HIDE)

	$pos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "NTFS", 16, 0)
	;
	; NTFS BootSector
	If $pos = 4 Then
		$ntfs_bs = 1
		RunWait(@ComSpec & " /c makebt\dsfo.exe \\.\" & $TargetDrive & " 0 8192 makebt\bs_temp\Back8192.bs", @ScriptDir, @SW_HIDE)
		; Search N T L D R
		$ntpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back8192.bs", "4E0054004C0044005200", 16, 1)
		If $ntpos = 515 Then
			$bs_valid = 1
			$g4d_vista = 0
		;	MsgBox(0, "Valid BootSector - NTFS - N T L D R", "NTFS  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF & "N T L D R  Found at OFFSET  " & $ntpos-1 & "  ", 0)
		Else
			; Search B O O T M G R
			$bmpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back8192.bs", "42004F004F0054004D0047005200", 16, 1)
			If $bmpos = 515 Then
				$bs_valid = 1
				$g4d_vista = 1
				; MsgBox(0, "Valid BootSector - NTFS - B O O T M G R", "NTFS  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF & "B O O T M G R  Found at OFFSET  " & $bmpos-1 & "  ", 0)
			Else
				; Search grldr - Offset = 474 = 0x1DA so that $grpos = 475
				$grpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back8192.bs", "grldr", 16, 0)
				If $grpos Then
					$g4d = 1
					$bs_valid = 3
					MsgBox(0, "Valid BootSector - NTFS - grldr", "NTFS  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF  _
					& "grldr  Found at OFFSET  " & $grpos-1 & "  " & @CRLF & @CRLF & " Continue with FileCopy to USB ", 5)
				Else
					$bs_valid = 0
					$ikey = MsgBox(48+4, "NTFS BootSector - NOT Valid for MultiBoot Menu", "N T L D R  or  B O O T M G R  or grldr NOT Found in BootSector  " & @CRLF & @CRLF _
					& "Yes = STOP - Solution: First Format USB-Drive " & @CRLF & " No = Continue with FileCopy to USB ", 0)
					If $ikey = 7 Then $bs_valid = 2
				EndIf
			EndIf
		EndIf
	Else
		$ntfs_bs = 0
	EndIf
	;
	; FAT BootSector
	If $ntfs_bs = 0 Then
		$pos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "FAT", 16, 0)
		If $pos = 55 Then
			$ntpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "NTLDR", 16, 0)
			If $ntpos = 418 Then
				$bs_valid = 1
				$g4d_vista = 0
			;	MsgBox(0, "Valid BootSector - FAT - NTLDR", "FAT  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF & "NTLDR  Found at OFFSET  " & $ntpos-1 & "  ", 0)
			Else
				$bmpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "BOOTMGR", 16, 0)
				; FAT16 has BOOTMGR at OFFSET=417 so that $bmpos=418 - Equal pos as NTLDR
				If $bmpos = 418 Then
					$bs_valid = 1
					$g4d_vista = 1
				;	MsgBox(0, "Valid BootSector - FAT - BOOTMGR", "FAT  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF & "BOOTMGR  Found at OFFSET  " & $bmpos-1 & "  ", 0)
				Else
					; Search grldr
					$grpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "GRLDR", 16, 0)
					If $grpos Then
						$g4d = 1
						$bs_valid = 3
						MsgBox(0, "Valid BootSector - FAT - GRLDR", "FAT  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF  _
						& "GRLDR  Found at OFFSET  " & $grpos-1 & "  " & @CRLF & @CRLF & " Continue with FileCopy to USB ", 5)
					Else
						$bs_valid = 0
						; case of IO.SYS - MSDOS BootSector
						$ikey = MsgBox(48+4, "STOP - FAT BootSector - NOT Valid for MultiBoot Menu", "NTLDR or BOOTMGR or GRLDR NOT Found in BootSector  " & @CRLF & @CRLF _
						& "Yes = STOP - Solution: First Format USB-Drive " & @CRLF & " No = Continue with FileCopy to USB ", 0)
						If $ikey = 7 Then $bs_valid = 2
					EndIf
				EndIf
			EndIf
		ElseIf $pos = 83 Then
			$ntpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "NTLDR", 16, 0)
			If $ntpos = 369 Then
				$bs_valid = 1
				$g4d_vista = 0
			;	MsgBox(0, "Valid BootSector - FAT32 - NTLDR", "FAT32  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF & "NTLDR  Found at OFFSET  " & $ntpos-1 & "  ", 0)
			Else
				$bmpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "BOOTMGR", 16, 0)
				; FAT32 has BOOTMGR at OFFSET=361 so that $bmpos=362 - Different pos as NTLDR
				If $bmpos Then
					$bs_valid = 1
					$g4d_vista = 1
				;	MsgBox(0, "Valid BootSector - FAT32 - BOOTMGR", "FAT32  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF & "BOOTMGR  Found at OFFSET  " & $bmpos-1 & "  ", 0)
				Else
					; Search grldr
					$grpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "GRLDR", 16, 0)
					If $grpos Then
						$g4d = 1
						$bs_valid = 3
						MsgBox(0, "Valid BootSector - FAT32 - GRLDR", "FAT32  Found at OFFSET  " & $pos-1 & "  " & @CRLF & @CRLF _
						& "GRLDR  Found at OFFSET  " & $grpos-1 & "  " & @CRLF & @CRLF & " Continue with FileCopy to USB ", 5)
					Else
						$bs_valid = 0
						$ikey = MsgBox(48+4, "STOP - FAT32 BootSector - NOT Valid for MultiBoot Menu", "NTLDR or BOOTMGR or GRLDR NOT Found in BootSector  " & @CRLF & @CRLF _
						& "Yes = STOP - Solution: First Format USB-Drive " & @CRLF & " No = Continue with FileCopy to USB ", 0)
						If $ikey = 7 Then $bs_valid = 2
					EndIf
				EndIf
			EndIf
		Else
			$bs_valid = 0
			$ikey = MsgBox(48+4, "STOP - Unknown Type BootSector", "NTFS or FAT or FAT32  NOT Found in BootSector  " & @CRLF & @CRLF _
			& "Yes = STOP - Solution: First Format USB-Drive " & @CRLF & " No = Continue with FileCopy to USB ", 0)
			If $ikey = 7 Then $bs_valid = 2
		EndIf
	EndIf
	;
	; Don't Change BOOTMGR BootSector to XP NTLDR BootSector for boot.ini Menu
	If $DriveType="Removable" Or $usbfix And $bs_valid = 1 And $g4d_vista = 1 Then
		If @OSVersion = "WIN_2003" Or @OSVersion = "WIN_XP" Or @OSVersion = "WIN_XPe" Or @OSVersion = "WIN_2000" And Not FileExists($TargetDrive & "\Boot\BCD") Then
			MsgBox(0, "WARNING - BOOTMGR Found in USB-BootSector ", " XP needs NTLDR BootSector " & @CRLF & @CRLF _
			& " BootSect.exe can be used to Change USB-BootSector ", 5)
;~ 			$ikey = MsgBox(48+4, "WARNING - BOOTMGR Found in USB-BootSector ", " Change of USB-BootSector might be needed " & @CRLF & @CRLF _
;~ 			& " BootSect.exe is used to Change USB-BootSector " & @CRLF & @CRLF _
;~ 			& " Yes = Change USB-BootSector to NTLDR Type for boot.ini Menu " & @CRLF & @CRLF _
;~ 			& " No  = Keep BOOTMGR  in USB-BootSector for BOOTMGR Menu ")
;~ 			If $ikey = 6 Then
;~ 				_GUICtrlStatusBar_SetText($hStatus," BootSect.exe makes NTLDR-type BootSector - Wait ... ", 0)
;~ 				RunWait(@ComSpec & " /c makebt\BootSect.exe /nt52 " & $TargetDrive & " /force", @ScriptDir, @SW_HIDE)
;~ 				Sleep(5000)
;~ 				If $ntfs_bs = 1 Then
;~ 					FileMove(@ScriptDir & "\makebt\bs_temp\Back8192.bs", @ScriptDir & "\makebt\bs_temp\BS_Backup.bs", 1)
;~ 					RunWait(@ComSpec & " /c makebt\dsfo.exe \\.\" & $TargetDrive & " 0 8192 makebt\bs_temp\Back8192.bs", @ScriptDir, @SW_HIDE)
;~ 					; Search N T L D R
;~ 					$ntpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back8192.bs", "4E0054004C0044005200", 16, 1)
;~ 					If $ntpos Then
;~ 						$g4d_vista = 0
;~ 					Else
;~ 						; Should NOT occur
;~ 						MsgBox(48, "STOP - Invalid BootSector", " USB-Drive will NOT be Bootable  " & @CRLF & @CRLF & " Solution: First Format USB-Drive  ", 0)
;~ 						$bs_valid = 0
;~ 						Return
;~ 					EndIf
;~ 				Else
;~ 					FileMove(@ScriptDir & "\makebt\bs_temp\Back512.bs", @ScriptDir & "\makebt\bs_temp\BS_Backup.bs", 1)
;~ 					RunWait(@ComSpec & " /c makebt\dsfo.exe \\.\" & $TargetDrive & " 0 512 makebt\bs_temp\Back512.bs", @ScriptDir, @SW_HIDE)
;~ 					$ntpos = HexSearch(@ScriptDir & "\makebt\bs_temp\Back512.bs", "NTLDR", 16, 0)
;~ 					If $ntpos Then
;~ 						$g4d_vista = 0
;~ 					Else
;~ 						; Should NOT occur
;~ 						MsgBox(48, "STOP - Invalid BootSector", " USB-Drive will NOT be Bootable  " & @CRLF & @CRLF & " Solution: First Format USB-Drive  ", 0)
;~ 						$bs_valid = 0
;~ 						Return
;~ 					EndIf
;~ 				EndIf
;~ 			Else
;~ 				; MsgBox(48, "WARNING - BOOTMGR BootSector", " Bootable USB-Drive with BOOTMGR Menu  " & @CRLF & @CRLF & " Continue with FileCopy to USB ", 0)
;~ 				$g4d_vista = 1
;~ 			EndIf
		EndIf
	EndIf
EndFunc   ;==> _Copy_BSU
;===================================================================================================
Func _BT_IMG()
	Local $len, $pos, $hd_cd
	Local $path_image_file=""

	If $img_folder = "" Then
		$path_image_file= $image_file
	Else
		$path_image_file= $img_folder & "\" & $image_file
	EndIf

	$len = StringLen($image_file)
	$pos = StringInStr($image_file, ".", 0, -1)
	$img_fext = StringRight($image_file, $len-$pos)

	$hd_cd = "/rdexportashd"
	If $img_fext = "iso" Then $hd_cd = "/rdexportascd"
	If $img_fext = "is_" Then $hd_cd = "/rdexportascd"


	If FileExists($TargetDrive & "\RMLD" & $pe_nr) Then	FileSetAttrib($TargetDrive & "\RMLD" & $pe_nr, "-RSH")
	If FileExists($TargetDrive & "\ramx" & $pe_nr & ".sif") Then FileSetAttrib($TargetDrive & "\ramx" & $pe_nr & ".sif", "-RSH")
	FileCopy(@ScriptDir & "\makebt\srsp1\setupldr.bin", $TargetDrive & "\RMLD" & $pe_nr, 1)
	FileSetAttrib($TargetDrive & "\RMLD" & $pe_nr, "-RSH")
	HexReplace($TargetDrive & "\RMLD" & $pe_nr, "46DA7403", "46DAEB1A", 0, 16, 1)
	HexReplace($TargetDrive & "\RMLD" & $pe_nr, "winnt.sif", "ramx" & $pe_nr & ".sif", 0, 16, 0)
	IniWriteSection($TargetDrive & "\ramx" & $pe_nr & ".sif", "SetupData", 'BootDevice="ramdisk(0)"' _
	& @LF & 'BootPath="\i386\System32\"' & @LF & "OsLoadOptions=" _
	& '"' & "/noguiboot /fastdetect /minint " & $hd_cd & " /rdpath=" & $path_image_file & '"')

	If Not FileExists($TargetDrive & "\BOOTFONT.BIN") Then
		If FileExists(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN") Then FileCopy(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN", $TargetDrive & "\", 1)
	EndIf

;	use modified ntdetect if exists in makebt folder
	If Not FileExists($TargetDrive & "\NTDETECT.COM") Then
		IF FileExists(@ScriptDir & "\makebt\ntdetect.com") Then
			FileCopy(@ScriptDir & "\makebt\ntdetect.com", $TargetDrive & "\", 1)
		Else
			FileCopy(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM", $TargetDrive & "\", 1)
		EndIf
	EndIf

	If GUICtrlRead($g4d_bcd) = $GUI_UNCHECKED And GUICtrlRead($xp_bcd) = $GUI_UNCHECKED And GUICtrlRead($grldrUpd) = $GUI_UNCHECKED Then
		If $g4d Or $g4dmbr <> 0 Then
			_g4d_bt_img_menu()
			Return
		EndIf
	EndIf
	If FileExists($TargetDrive & "\grldr") And FileExists($TargetDrive & "\menu.lst") And $g4d_vista = 0 And GUICtrlRead($grldrUpd) = $GUI_UNCHECKED Then
		_g4d_bt_img_menu()
		Return
	EndIf

	If FileExists($TargetDrive & "\menu.lst") Then _g4d_bt_img_menu()

	If $g4d_vista <> 0 Then
		If Not FileExists($TargetDrive & "\BOOTFONT.BIN") Or Not FileExists($TargetDrive & "\NTDETECT.COM") Then
			MsgBox(48, "WARNING - Missing File on Target Drive", " BOOTFONT.BIN Or NTDETECT.COM Not Found " & @CRLF & @CRLF _
			& " Solution: Manually Add NTDETECT.COM to Target Drive ", 0)
		EndIf
	EndIf

EndFunc   ;==> _BT_IMG
;===================================================================================================
Func _RC_IMG()
	Local $len, $pos, $hd_cd
	Local $path_image_file=""

	If $img_folder = "" Then
		$path_image_file= $image_file
	Else
		$path_image_file= $img_folder & "\" & $image_file
	EndIf

	$len = StringLen($image_file)
	$pos = StringInStr($image_file, ".", 0, -1)
	$img_fext = StringRight($image_file, $len-$pos)
	$hd_cd = "/rdexportashd"
;	If $img_fext = "iso" Then $hd_cd = "/rdexportascd"
;	If $img_fext = "is_" Then $hd_cd = "/rdexportascd"

	If FileExists($TargetDrive & "\RCLDR") Then	FileSetAttrib($TargetDrive & "\RCLDR", "-RSH")
	If FileExists($TargetDrive & "\rcons.sif") Then FileSetAttrib($TargetDrive & "\rcons.sif", "-RSH")
	FileCopy(@ScriptDir & "\makebt\srsp1\setupldr.bin", $TargetDrive & "\RCLDR", 1)
	FileSetAttrib($TargetDrive & "\RCLDR", "-RSH")
	HexReplace($TargetDrive & "\RCLDR", "46DA7403", "46DAEB1A", 0, 16, 1)
	HexReplace($TargetDrive & "\RCLDR", "winnt.sif", "rcons.sif", 0, 16, 0)
	IniWriteSection($TargetDrive & "\rcons.sif", "SetupData", 'BootDevice="ramdisk(0)"' _
	& @LF & 'BootPath="\i386\"' & @LF & "OsLoadOptions=" _
	& '"' & "/noguiboot /fastdetect " & $hd_cd & " /rdpath=" & $path_image_file & '"' _
	& @LF & 'SetupSourceDevice = \device\harddisk0\partition1')

	If Not FileExists($TargetDrive & "\BOOTFONT.BIN") Then
		If FileExists(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN") Then FileCopy(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN", $TargetDrive & "\", 1)
	EndIf

;	use modified ntdetect if exists in makebt folder
	If Not FileExists($TargetDrive & "\NTDETECT.COM") Then
		IF FileExists(@ScriptDir & "\makebt\ntdetect.com") Then
			FileCopy(@ScriptDir & "\makebt\ntdetect.com", $TargetDrive & "\", 1)
		Else
			FileCopy(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM", $TargetDrive & "\", 1)
		EndIf
	EndIf

	If FileExists(@ScriptDir & "\makebt\CATCH22") Then DirCopy(@ScriptDir & "\makebt\CATCH22", $TargetDrive & "\CATCH22", 1)

	If GUICtrlRead($g4d_bcd) = $GUI_UNCHECKED And GUICtrlRead($xp_bcd) = $GUI_UNCHECKED And GUICtrlRead($grldrUpd) = $GUI_UNCHECKED Then
		If $g4d Or $g4dmbr <> 0 Then
			_g4d_rc_img_menu()
			Return
		EndIf
	EndIf
	If FileExists($TargetDrive & "\grldr") And FileExists($TargetDrive & "\menu.lst") And $g4d_vista = 0 And GUICtrlRead($grldrUpd) = $GUI_UNCHECKED Then
		_g4d_rc_img_menu()
		Return
	EndIf

	If FileExists($TargetDrive & "\menu.lst") Then _g4d_rc_img_menu()

	If $g4d_vista <> 0 Then
		If Not FileExists($TargetDrive & "\BOOTFONT.BIN") Or Not FileExists($TargetDrive & "\NTDETECT.COM") Then
			MsgBox(48, "WARNING - Missing File on Target Drive", " BOOTFONT.BIN Or NTDETECT.COM Not Found " & @CRLF & @CRLF _
			& " Solution: Manually Add NTDETECT.COM to Target Drive ", 0)
		EndIf
	EndIf

EndFunc   ;==> _RC_IMG
;===================================================================================================
Func TogglePause()
	$Paused = NOT $Paused
    While $Paused
        Sleep(100)
        ToolTip('Script is "Paused"',220,410)
	WEnd
    ToolTip("")
EndFunc ;==>TogglePause()
;===================================================================================================
Func DisableMenus($endis)
	If $endis = 0 Then
		$endis = $GUI_ENABLE
	Else
		$endis = $GUI_DISABLE
	EndIf

	If $WinDrvDrive <> "" And $TargetDrive <> "" Then
		GUICtrlSetState($IMG_FileSelect, $endis)
		GUICtrlSetState($IMG_File, $endis)
		GUICtrlSetState($AddContentBrowse, $endis)
		GUICtrlSetState($AddContentSource, $endis)
		GUICtrlSetState($Combo_Folder, $endis)
		GUICtrlSetState($grldrUpd, $endis)
		If $PartStyle <> "MBR" Then
			GUICtrlSetState($g4d_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
			GUICtrlSetState($xp_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
			GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
			GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
			GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)
			GUICtrlSetState($Combo_EFI, $GUI_DISABLE)
		Else
			GUICtrlSetState($g4d_bcd, $endis)
			GUICtrlSetState($xp_bcd, $endis)
			If $BusType <> "USB" Then
				GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
				GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
				GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)
				GUICtrlSetState($Combo_EFI, $GUI_DISABLE)
			Else
				GUICtrlSetState($Upd_MBR, $endis)
				If FileExists(@ScriptDir & "\UEFI_MAN\grub_a1") Then
					GUICtrlSetState($Add_Grub2_Sys, $endis)
				Else
					GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
				EndIf
				GUICtrlSetState($refind, $endis)
				GUICtrlSetState($Combo_EFI, $endis)
			EndIf
		EndIf
	Else
		GUICtrlSetState($IMG_FileSelect, $GUI_DISABLE)
		GUICtrlSetState($IMG_File, $GUI_DISABLE)
		GUICtrlSetState($AddContentBrowse, $GUI_DISABLE)
		GUICtrlSetState($AddContentSource, $GUI_DISABLE)
		GUICtrlSetState($Combo_Folder, $GUI_DISABLE)
		GUICtrlSetState($grldrUpd, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($g4d_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($xp_bcd, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
		GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Combo_EFI, $GUI_DISABLE)
	EndIf

	; Keep Ventoy MBR and Ventoy Grub2
	If $ventoy Then
		GUICtrlSetState($Upd_MBR, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Add_Grub2_Sys, $GUI_DISABLE + $GUI_UNCHECKED)
		GUICtrlSetState($refind, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Combo_EFI, $GUI_DISABLE)
	EndIf

	If @OSVersion <> "WIN_VISTA" And @OSVersion <> "WIN_2003" And @OSVersion <> "WIN_XP" And @OSVersion <> "WIN_XPe" And @OSVersion <> "WIN_2000" Then
		If StringLeft($image_file, 2) = "XP" And $img_fext = "vhd" Then
			GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
		Else
			If $img_fext = "vhd" Or $img_fext = "vhdx" Then
				GUICtrlSetState($Boot_vhd, $endis)
			Else
				GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
			EndIf
		EndIf
		If $w78sys=1 Then
			GUICtrlSetState($Boot_w8, $endis)
		Else
			GUICtrlSetState($Boot_w8, $GUI_UNCHECKED + $GUI_DISABLE)
		EndIf
	Else
		GUICtrlSetState($Boot_vhd, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Boot_w8, $GUI_UNCHECKED + $GUI_DISABLE)
	EndIf

	If GUICtrlRead($ImageType) = "VHD - IMG" Then
		GUICtrlSetState($Menu_Type, $endis)
	Else
		GUICtrlSetState($Menu_Type, $GUI_DISABLE)
	EndIf

	GUICtrlSetState($WinDrvSel, $endis)
	GUICtrlSetState($WinDrv, $endis)
	GUICtrlSetState($TargetSel, $endis)
	GUICtrlSetState($Target, $endis)
	GUICtrlSetState($GO, $GUI_DISABLE)

	GUICtrlSetData($IMG_File, $btimgfile)
	GUICtrlSetData($AddContentSource, $ContentSource)
	GUICtrlSetData($Target, $TargetDrive)
	GUICtrlSetData($WinDrv, $WinDrvDrive)

EndFunc ;==>DisableMenus
;===================================================================================================
Func HexSearch($fl, $str1, $bin = 0, $ind = 0)
	Local $src, $file, $strpos=0
	; $bin=16 for hex search, $ind=0 for StringToHex conversion
	If $bin = 16 And $ind = 0 Then
		$str1 = _StringToHex($str1)
	EndIf
	$file = FileOpen($fl, $bin)
	If $file = -1 Then
		MsgBox(48, "Error", "Unable to open " & $fl & " for Search ", 3)
		Return 0
	EndIf
	$src = FileRead($file)
	FileClose($file)
	$strpos = StringInStr($src, $str1)
	If $bin = 16 Then $strpos = Int($strpos / 2)
	Return $strpos
	; Not Found Returns $strpos=0
	; $strpos=1 is the first byte - substract 1 for comparison with TinyHexer and gsar
	; In TinyHexer and gsar the first byte has position 0
EndFunc
;===================================================================================================
Func HexReplace($fl, $str1, $str2, $flag = 0, $bin = 0, $ind = 0)
	Local $hOut, $src, $file
	;flag- The number of times to replace the searchstring, 0 for all
	;$bin- 16 for hex editing
	If $bin = 16 And $ind = 0 Then
		$str1 = _StringToHex($str1)
		$str2 = _StringToHex($str2)
	EndIf
	$file = FileOpen($fl, $bin)
	If $file = -1 Then
		MsgBox(16, "Error", "Unable to open " & $fl & " for editing, Aborting in 10 seconds...", 10)
		Exit
	EndIf
	$src = FileRead($file)
	FileClose($file)
;	FileMove($fl, $fl & ".bak", 8)
	$src = StringReplace($src, $str1, $str2, $flag)
	If $src = "" Then
		MsgBox(16, "Error", "Something wont wrong whille editing " & $fl)
	EndIf
	$hOut = FileOpen($fl, $bin + 2)
    FileWrite($hOut , $src)
    FileClose($hOut)
	Return @extended
EndFunc
;===================================================================================================
Func _g4d_bt_img_menu()
	Local $entry_image_file=""

 	If $img_folder = "" Then
		$entry_image_file= $image_file
	Else
		$entry_image_file= $img_folder & "/" & $image_file
	EndIf

	FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title PE " & $pe_nr & " - " & $entry_image_file & " - RAMDISK - " & $BTIMGSize & " MB")
	FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /RMLD" & $pe_nr)
	FileWriteLine($TargetDrive & "\menu.lst", "chainloader /RMLD" & $pe_nr)
EndFunc   ;==> _g4d_bt_img_menu
;===================================================================================================
Func _g4d_rc_img_menu()
	Local $entry_image_file=""

	If $img_folder = "" Then
		$entry_image_file= $image_file
	Else
		$entry_image_file= $img_folder & "/" & $image_file
	EndIf

	FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title XP Recovery Console - " & $entry_image_file & " - RAMDISK - " & $BTIMGSize & " MB")
	FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /RCLDR")
	FileWriteLine($TargetDrive & "\menu.lst", "chainloader /RCLDR")
	FileWriteLine($TargetDrive & "\menu.lst", "#####################################################################")
	FileWriteLine($TargetDrive & "\menu.lst", "# write string cmdcons to memory 0000:7C03 in 2 steps:")
	FileWriteLine($TargetDrive & "\menu.lst", "#####################################################################")
	FileWriteLine($TargetDrive & "\menu.lst", "# step 1. Write 4 chars cmdc at 0000:7C03")
	FileWriteLine($TargetDrive & "\menu.lst", "write 0x7C03 0x63646D63")
	FileWriteLine($TargetDrive & "\menu.lst", "# step 2. Write 3 chars ons and an ending null at 0000:7C07")
	FileWriteLine($TargetDrive & "\menu.lst", "write 0x7C07 0x00736E6F")
EndFunc   ;==> _g4d_rc_img_menu
;===================================================================================================
Func _g4d_sf_img_menu()
	Local $entry_image_file=""

	If $img_folder = "" Then
		$entry_image_file= $image_file
	Else
		$entry_image_file= $img_folder & "/" & $image_file
	EndIf

	FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title SuperFLoppy Image - " & $entry_image_file & " - " & $BTIMGSize & " MB")
	FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
	FileWriteLine($TargetDrive & "\menu.lst", "map --mem /" & $entry_image_file & " (fd0)")
	FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
	FileWriteLine($TargetDrive & "\menu.lst", "chainloader (fd0)+1")
	FileWriteLine($TargetDrive & "\menu.lst", "rootnoverify (fd0)")
EndFunc   ;==> _g4d_sf_img_menu
;===================================================================================================
Func _g4d_cd_iso_menu()
	Local $entry_image_file=""

	If $img_folder = "" Then
		$entry_image_file= $image_file
	Else
		$entry_image_file= $img_folder & "/" & $image_file
	EndIf

	If $DriveType="Removable" Or GUICtrlRead($ImageType) = "WinPE - ISO" Then
		FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - ISO - " & $BTIMGSize & " MB")
		FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
		FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (0xff)")
	Else
		FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - ISO or ISO from RAM - " & $BTIMGSize & " MB")
		FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
		FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (0xff) || map --mem /" & $entry_image_file & " (0xff)")
	EndIf
	FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
	FileWriteLine($TargetDrive & "\menu.lst", "root (0xff)")
	If GUICtrlRead($ImageType) = "WinPE - ISO" Then
		FileWriteLine($TargetDrive & "\menu.lst", "chainloader (0xff)/BOOTMGR || chainloader (0xff)/bootmgr")
	Else
		FileWriteLine($TargetDrive & "\menu.lst", "chainloader (0xff)")
	EndIf
EndFunc   ;==> _g4d_cd_iso_menu
;===================================================================================================
Func _g4d_hdd_img_menu()
	Local $entry_image_file=""

	; $entry_image_file = $image_file

	If $vhdfolder = "" Then
		$entry_image_file= $vhdfile_name
	Else
		$entry_image_file= $vhdfolder & "/" & $vhdfile_name_only
	EndIf

	If GUICtrlRead($Menu_Type) = "XP - WinVBlock" Or GUICtrlRead($Menu_Type) = "78 - WinVBlock" Then
		If $FSvar_WinDrvDrive="NTFS" Or GUICtrlRead($Menu_Type) = "XP - WinVBlock" Then
			FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - WinVBlock FILEDISK - " & $BTIMGSize & " MB")
			FileWriteLine($TargetDrive & "\menu.lst", "# Sector-mapped disk")
			FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (hd0)")
			FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
			FileWriteLine($TargetDrive & "\menu.lst", "root (hd0,0)")
			If GUICtrlRead($Menu_Type) = "XP - WinVBlock" Then
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /ntldr")
			Else
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
			EndIf
		EndIf

		FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - WinVBlock RAMDISK  - " & $BTIMGSize & " MB")
		FileWriteLine($TargetDrive & "\menu.lst", "# Sector-mapped disk")
		FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
		FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem /" & $entry_image_file & " (hd0)")
		FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
		FileWriteLine($TargetDrive & "\menu.lst", "root (hd0,0)")
		If GUICtrlRead($Menu_Type) = "XP - WinVBlock" Then
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /ntldr")
		Else
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
		EndIf

	ElseIf GUICtrlRead($Menu_Type) = "10 - SVBus" Then
		If  $driver_flag = 3 Or $driver_flag = 0 Then
			If $DriveSysType="Removable" Or $usbsys Then
				If $FSvar_WinDrvDrive="NTFS" Then
					FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,0)/" & $entry_image_file & "] (hd0,0)/" & $entry_image_file & " - SVBus  FILEDISK - " & $BTIMGSize & " MB - map as (hd-1)")
					FileWriteLine($TargetDrive & "\menu.lst", "map (hd0,0)/" & $entry_image_file & " (hd-1)")
					FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
					If $vhd_rev_layout = 0 Then
						FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
					Else
						FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,1)")
					EndIf
					FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
				EndIf
				FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,0)/" & $entry_image_file & "] (hd0,0)/" & $entry_image_file & " - SVBus  RAMDISK  - " & $BTIMGSize & " MB - map as (hd-1)")
				FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem (hd0,0)/" & $entry_image_file & " (hd-1)")
				FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
				If $vhd_rev_layout = 0 Then
					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
				Else
					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,1)")
				EndIf
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
				If $FSvar_WinDrvDrive="NTFS" Then
					FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,1)/" & $entry_image_file & "] (hd0,1)/" & $entry_image_file & " - SVBus  FILEDISK - " & $BTIMGSize & " MB - map as (hd-1)")
					FileWriteLine($TargetDrive & "\menu.lst", "map (hd0,1)/" & $entry_image_file & " (hd-1)")
					FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
					If $vhd_rev_layout = 0 Then
						FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
					Else
						FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,1)")
					EndIf
					FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
				EndIf
				FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,1)/" & $entry_image_file & "] (hd0,1)/" & $entry_image_file & " - SVBus  RAMDISK  - " & $BTIMGSize & " MB - map as (hd-1)")
				FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem (hd0,1)/" & $entry_image_file & " (hd-1)")
				FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
				If $vhd_rev_layout = 0 Then
					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
				Else
					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,1)")
				EndIf
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
			Else
				If $FSvar_WinDrvDrive="NTFS" Then
					FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - SVBus  FILEDISK - " & $BTIMGSize & " MB - map as (hd)")
					FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
					FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (hd)")
					FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
					If $vhd_rev_layout = 0 Then
						FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
					Else
						FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,1)")
					EndIf
					FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
				EndIf
				FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - SVBus  RAMDISK  - " & $BTIMGSize & " MB - map as (hd)")
				FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
				FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem /" & $entry_image_file & " (hd)")
				FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
				If $vhd_rev_layout = 0 Then
					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
				Else
					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,1)")
				EndIf
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
			EndIf
		EndIf
		If  $driver_flag = 2 Then
			If $FSvar_WinDrvDrive="NTFS" Then
				FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - FiraDisk  FILEDISK - " & $BTIMGSize & " MB")
				FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
				FileWriteLine($TargetDrive & "\menu.lst", "map --heads=2 --sectors-per-track=18 --mem (md)0x800+4 (99)")
				FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (hd0)")
				FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
				FileWriteLine($TargetDrive & "\menu.lst", "write (99) [FiraDisk]\nStartOptions=disk,vmem=find:/" & $entry_image_file & ",boot;\n\0")
				FileWriteLine($TargetDrive & "\menu.lst", "rootnoverify (hd0,0)")
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
				FileWriteLine($TargetDrive & "\menu.lst", "map --status")
				FileWriteLine($TargetDrive & "\menu.lst", "pause Press any key . . .")
			EndIf
			FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - FiraDisk  RAMDISK  - " & $BTIMGSize & " MB")
			FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem /" & $entry_image_file & " (hd0)")
			FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
			FileWriteLine($TargetDrive & "\menu.lst", "root (hd0,0)")
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
		EndIf
		If  $driver_flag = 1 Then
			If $FSvar_WinDrvDrive="NTFS" Then
				FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - WinVBlock FILEDISK - " & $BTIMGSize & " MB")
				FileWriteLine($TargetDrive & "\menu.lst", "# Sector-mapped disk")
				FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
				FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (hd0)")
				FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
				FileWriteLine($TargetDrive & "\menu.lst", "root (hd0,0)")
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
			EndIf
			FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - WinVBlock RAMDISK  - " & $BTIMGSize & " MB")
			FileWriteLine($TargetDrive & "\menu.lst", "# Sector-mapped disk")
			FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem /" & $entry_image_file & " (hd0)")
			FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
			FileWriteLine($TargetDrive & "\menu.lst", "root (hd0,0)")
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
		EndIf
	Else

		If $FSvar_WinDrvDrive="NTFS" Or GUICtrlRead($Menu_Type) = "XP - FiraDisk" Then
			FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - FiraDisk  FILEDISK - " & $BTIMGSize & " MB")
			FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\menu.lst", "map --heads=2 --sectors-per-track=18 --mem (md)0x800+4 (99)")
			FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (hd0)")
			FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
			FileWriteLine($TargetDrive & "\menu.lst", "write (99) [FiraDisk]\nStartOptions=disk,vmem=find:/" & $entry_image_file & ",boot;\n\0")
			FileWriteLine($TargetDrive & "\menu.lst", "rootnoverify (hd0,0)")
			If GUICtrlRead($Menu_Type) = "XP - FiraDisk" Then
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /ntldr")
			Else
				FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
			EndIf
			FileWriteLine($TargetDrive & "\menu.lst", "map --status")
			FileWriteLine($TargetDrive & "\menu.lst", "pause Press any key . . .")
		EndIf

		FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - FiraDisk  RAMDISK  - " & $BTIMGSize & " MB")
		FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
		FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem /" & $entry_image_file & " (hd0)")
		FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
		FileWriteLine($TargetDrive & "\menu.lst", "root (hd0,0)")
		If GUICtrlRead($Menu_Type) = "XP - FiraDisk" Then
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /ntldr")
		Else
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
		EndIf

	EndIf
EndFunc   ;==> _g4d_hdd_img_menu
;===================================================================================================
Func _UEFI_RAMOS()
	Local $entry_image_file=""

	; $entry_image_file = $image_file

	If $vhdfolder = "" Then
		$entry_image_file= $vhdfile_name
	Else
		$entry_image_file= $vhdfolder & "/" & $vhdfile_name_only
	EndIf
	$PSize = Round($BTIMGSize / 1024, 1) & " GB"

	; UEFI booting from RAMDISK needs fixed vhd with 2 partitions
	If StringRight($vhdfile_name, 4) = ".vhd" And FileExists($TargetDrive & "\EFI\grub\menu.lst") And $Part12_flag = 2 Then

		If $driver_flag = 3 Or $driver_flag = 0 Then
			_GUICtrlStatusBar_SetText($hStatus," Making UEFI Grub4dos Menu on Target Boot Drive " & $TargetDrive, 0)
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", @CRLF & "title Boot  /" & $entry_image_file & " - UEFI Grub4dos  SVBus  RAMDISK  - " & $PSize)
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", "find --set-root --ignore-floppies --ignore-cd /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", "map --mem --top /" & $entry_image_file & " (hd)")
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", "chainloader (hd-1)")
		EndIf
	EndIf

	If StringRight($vhdfile_name, 4) = ".vhd" And FileExists($TargetDrive & "\grub\grub.cfg") And $Part12_flag = 2 Then

		If $driver_flag = 3 Or $driver_flag = 0 Then
			_GUICtrlStatusBar_SetText($hStatus," Making UEFI Grub2 Menu on Target Boot Drive " & $TargetDrive, 0)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", @CRLF & "menuentry " & '"' & "Boot /" & $entry_image_file & " - UEFI Grub2  SVBus  RAMDISK  - " & $PSize & '"' & " {")
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  search --file --set=vhd_drive --no-floppy /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  map --mem --rt ($vhd_drive)/" & $entry_image_file)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  boot")
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "}")
		EndIf
	EndIf

	; UEFI booting from RAMDISK needs fixed vhd with 1 partition
	If StringRight($vhdfile_name, 4) = ".vhd" And FileExists($TargetDrive & "\EFI\grub\menu.lst") And $Part12_flag = 1 Then

		If $driver_flag = 3 Or $driver_flag = 0 Then
			_GUICtrlStatusBar_SetText($hStatus," Making UEFI Grub4dos Menu on Target Boot Drive " & $TargetDrive, 0)
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", @CRLF & "title Boot  /" & $entry_image_file & " - UEFI Grub4dos  SVBus  RAMDISK  - " & $PSize)
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", "load /EFI/grub/ntfs_x64.efi")
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", "find --set-root --ignore-floppies --ignore-cd /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", "map --mem --top /" & $entry_image_file & " (hd)")
			FileWriteLine($TargetDrive & "\EFI\grub\menu.lst", "chainloader (hd-1)")
		EndIf
	EndIf

	If StringRight($vhdfile_name, 4) = ".vhd" And FileExists($TargetDrive & "\grub\grub.cfg") And $Part12_flag = 1 Then

		If $driver_flag = 3 Or $driver_flag = 0 Then
			_GUICtrlStatusBar_SetText($hStatus," Making UEFI Grub2 Menu on Target Boot Drive " & $TargetDrive, 0)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", @CRLF & "menuentry " & '"' & "Boot /" & $entry_image_file & " - UEFI Grub2  SVBus  RAMDISK  - " & $PSize & '"' & " {")
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  efiload /EFI/grub/ntfs_x64.efi")
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  search --file --set=vhd_drive --no-floppy /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  map --mem --rt ($vhd_drive)/" & $entry_image_file)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  boot")
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "}")

			FileWriteLine($TargetDrive & "\grub\grub.cfg", @CRLF & "menuentry " & '"' & "Boot /" & $entry_image_file & " - UEFI Grub2 ntboot SVBus  RAMDISK  - " & $PSize & '"' & " {")
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  search --file --set=vhd_drive --no-floppy /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  map --mem --rt ($vhd_drive)/" & $entry_image_file)
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "  ntboot --win --highest=no --efi=(vd0,1)/EFI/Microsoft/Boot/bootmgfw.efi --winload=\\Windows\\System32\\winload.efi (vd0,1)")
			FileWriteLine($TargetDrive & "\grub\grub.cfg", "}")
		EndIf
	EndIf

EndFunc   ;==> _UEFI_RAMOS
;===================================================================================================
Func _bcd_menu()
	Local $file, $line, $guid, $pos1, $pos2

	; already set in _GO
	; SystemFileRedirect("On")

	If FileExists(@WindowsDir & "\system32\bcdedit.exe") Then
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
	Else
		$bcdedit = ""
	EndIf
	If FileExists($TargetDrive & "\Boot\BCD") And $bcdedit <> "" Then
		$store = $TargetDrive & "\Boot\BCD"

		If GUICtrlRead($g4d_bcd) = $GUI_CHECKED Or Not FileExists($TargetDrive & "\grldr.mbr") Then
			_GUICtrlStatusBar_SetText($hStatus," Making  Grub4dos Entry in Boot Manager Menu - wait ....", 0)
			If Not FileExists($TargetDrive & "\grldr.mbr") Or GUICtrlRead($grldrUpd) = $GUI_CHECKED Then FileCopy(@ScriptDir & "\makebt\grldr.mbr", $TargetDrive & "\", 1)

			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /create /d " & '"' & "Grub4dos Menu" & '"' & " /application bootsector > makebt\bs_temp\bcd_out.txt", @ScriptDir, @SW_HIDE)
			$file = FileOpen(@ScriptDir & "\makebt\bs_temp\bcd_out.txt", 0)
			$line = FileReadLine($file)
			FileClose($file)
			$pos1 = StringInStr($line, "{")
			$pos2 = StringInStr($line, "}")
			If $pos2-$pos1=37 Then
				$guid = StringMid($line, $pos1, $pos2-$pos1+1)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $guid & " device boot", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /set " & $guid & " path \grldr.mbr", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
				& $store & " /displayorder " & $guid & " /addlast", $TargetDrive & "\", @SW_HIDE)
				If $g4d_default = 1 Then
					RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
					& $store & " /default " & $guid, $TargetDrive & "\", @SW_HIDE)
				EndIf
			EndIf
		EndIf
		Sleep(1000)

		If GUICtrlRead($xp_bcd) = $GUI_CHECKED Then
			_GUICtrlStatusBar_SetText($hStatus," Making  XP Entry in Boot Manager Menu - wait ....", 0)
			If Not FileExists($TargetDrive & "\boot.ini") Then
				IniWriteSection($TargetDrive & "\boot.ini", "Boot Loader", "Timeout=20" & @LF & _
				"Default=multi(0)disk(0)rdisk(0)partition(2)" & $WinFol)
				IniWriteSection($TargetDrive & "\boot.ini", "Operating Systems", _
				"multi(0)disk(0)rdisk(0)partition(1)" & $WinFol & "=" & '"Start Windows XP HD-0 Partition 1"' & " /noexecute=optin /fastdetect")
				IniWrite($TargetDrive & "\boot.ini", "Operating Systems", "multi(0)disk(0)rdisk(0)partition(2)" & $WinFol, _
				'"Start Windows XP HD-0 Partition 2"' & " /noexecute=optin /fastdetect")
				IniWrite($TargetDrive & "\boot.ini", "Operating Systems", "multi(0)disk(0)rdisk(1)partition(1)" & $WinFol, _
				'"Start Windows XP HD-1 Partition 1"' & " /noexecute=optin /fastdetect")
				IniWrite($TargetDrive & "\boot.ini", "Operating Systems", "multi(0)disk(0)rdisk(1)partition(2)" & $WinFol, _
				'"Start Windows XP HD-1 Partition 2"' & " /noexecute=optin /fastdetect")
				IniWrite($TargetDrive & "\boot.ini", "Operating Systems", "C:\grldr", '"Start Grub4dos - XP Menu"')
			EndIf
			If Not FileExists($TargetDrive & "\BOOTFONT.BIN") Then
				FileCopy(@ScriptDir & "\makebt\Boot_XP\BOOTFONT.BIN", $TargetDrive & "\", 1)
			EndIf

		;	use modified ntdetect if exists in makebt folder
			If Not FileExists($TargetDrive & "\NTDETECT.COM") Then
				IF FileExists(@ScriptDir & "\makebt\ntdetect.com") Then
					FileCopy(@ScriptDir & "\makebt\ntdetect.com", $TargetDrive & "\", 1)
				Else
					FileCopy(@ScriptDir & "\makebt\Boot_XP\NTDETECT.COM", $TargetDrive & "\", 1)
				EndIf
			EndIf

			If Not FileExists($TargetDrive & "\ntldr") Then
				FileCopy(@ScriptDir & "\makebt\Boot_XP\NTLDR", $TargetDrive & "\", 1)
			EndIf
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /create {ntldr} /d " & '"' & "Start Windows XP" & '"', $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set {ntldr} device boot", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set {ntldr} path \ntldr", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /displayorder {ntldr} /addlast", $TargetDrive & "\", @SW_HIDE)
			; MsgBox(0, "BOOTMGR - XP NTLDR  ENTRY in BCD OK ", "XP NTLDR  Boot Entry was made in Store " & $TargetDrive & "\Boot\BCD ", 3)
		EndIf
	Else
		If GUICtrlRead($g4d_bcd) = $GUI_CHECKED Or GUICtrlRead($xp_bcd) = $GUI_CHECKED Then
			MsgBox(48, "CONFIG ERROR Or Missing File", "Unable to Add to Boot Manager Menu" & @CRLF & @CRLF _
				& " Missing bcdedit.exe Or Boot\BCD file ", 5)
		EndIf
	EndIf
	Sleep(1000)
	; SystemFileRedirect("Off")

EndFunc   ;==> _bcd_menu
;===================================================================================================
Func _bcd_grub2()
	Local $file, $line, $guid, $pos1, $pos2

	SystemFileRedirect("On")

	If FileExists(@WindowsDir & "\system32\bcdedit.exe") Then
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
	Else
		$bcdedit = ""
	EndIf

	If FileExists($TargetDrive & "\Boot\BCD") And $bcdedit <> "" Then
		$store = $TargetDrive & "\Boot\BCD"

		_GUICtrlStatusBar_SetText($hStatus," Making Grub2 - AIO grub2win Entry in Boot Manager Menu - wait ....", 0)

		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /create /d " & '"' & "Grub 2 Win - AIO grub2win" & '"' & " /application bootsector > makebt\bs_temp\bcd_grub2.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\bcd_grub2.txt", 0)
		$line = FileReadLine($file)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 Then
			$guid = StringMid($line, $pos1, $pos2-$pos1+1)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " device boot", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " path \AIO\grub\grub2win", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /displayorder " & $guid & " /addlast", $TargetDrive & "\", @SW_HIDE)
;~ 			If $DriveType="Removable" Or $usbfix Then
;~ 				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
;~ 				& $store & " /default " & $guid, $TargetDrive & "\", @SW_HIDE)
;~ 			EndIf
		EndIf
	Else
		MsgBox(48, "CONFIG ERROR Or Missing File", "Unable to Add Grub2 to Boot Manager Menu" & @CRLF & @CRLF _
			& " Missing bcdedit.exe Or Boot\BCD file ", 5)
	EndIf

	SystemFileRedirect("Off")

EndFunc   ;==> _bcd_grub2
;===================================================================================================
Func _bcd_grub2win()
	Local $file, $line, $guid, $pos1, $pos2

	SystemFileRedirect("On")

	If FileExists(@WindowsDir & "\system32\bcdedit.exe") Then
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
	Else
		$bcdedit = ""
	EndIf

	If FileExists($TargetDrive & "\Boot\BCD") And $bcdedit <> "" Then
		$store = $TargetDrive & "\Boot\BCD"

		_GUICtrlStatusBar_SetText($hStatus," Making  Grub2Win Entry in Boot Manager Menu - wait ....", 0)

		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /create /d " & '"' & "Grub 2 Win - Linux ISO" & '"' & " /application bootsector > makebt\bs_temp\bcd_grub2win.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\bcd_grub2win.txt", 0)
		$line = FileReadLine($file)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 Then
			$guid = StringMid($line, $pos1, $pos2-$pos1+1)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " device boot", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " path \grub2\g2bootmgr\gnugrub.kernel.bios", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /displayorder " & $guid & " /addlast", $TargetDrive & "\", @SW_HIDE)
;~ 			If $DriveType="Removable" Or $usbfix Then
;~ 				RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
;~ 				& $store & " /default " & $guid, $TargetDrive & "\", @SW_HIDE)
;~ 			EndIf
		EndIf
	Else
		MsgBox(48, "CONFIG ERROR Or Missing File", "Unable to Add Grub2Win to Boot Manager Menu" & @CRLF & @CRLF _
			& " Missing bcdedit.exe Or Boot\BCD file ", 5)
	EndIf

	SystemFileRedirect("Off")

EndFunc   ;==> _bcd_grub2win
;===================================================================================================
Func GetContentSource()
	Local $pos, $TempLinuxSource
	Local $pos1, $pos2, $len

	DisableMenus(1)
	$ContentSource = ""
	$content_folder = ""
	GUICtrlSetData($AddContentSource, "")
	$ContentSize=0
	GUICtrlSetData($GUI_ContentSize, "")

	$TempLinuxSource = FileSelectFolder("Select Source Folder for Copy to Target Drive Or Folder","")

	If @error Then
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($TempLinuxSource, "\", 0, -1)
	If $pos = 0 Then
		MsgBox(48,"ERROR - Return", " Path Invalid - No Backslash Found" & @CRLF & @CRLF & "Selected Source = " & $TempLinuxSource)
		$ContentSource = ""
		GUICtrlSetData($AddContentSource, "")
		CheckSize()
		DisableMenus(0)
		GUICtrlSetState($TargetSel, $GUI_FOCUS)
		Return
	EndIf
	If StringLen($TempLinuxSource) = 3 Then $TempLinuxSource = StringLeft($TempLinuxSource, 2)
	If StringLeft($TempLinuxSource, 2) = $TargetDrive Then
		MsgBox(48,"ERROR - Return", " Target and Content Source are Equal Drives " & @CRLF & @CRLF & " Selected Source = " & $TempLinuxSource)
		$ContentSource = ""
		GUICtrlSetData($AddContentSource, "")
		CheckSize()
		DisableMenus(0)
		Return
	EndIf
	If StringLeft($TempLinuxSource, 2) = $WinDrvDrive Then
		MsgBox(48,"ERROR - Return", " System Drive and Content Source are Equal Drives " & @CRLF & @CRLF & " Selected Source = " & $TempLinuxSource)
		$ContentSource = ""
		GUICtrlSetData($AddContentSource, "")
		CheckSize()
		DisableMenus(0)
		Return
	EndIf

	$ContentSource = $TempLinuxSource
	GUICtrlSetData($AddContentSource, $ContentSource)
	$len = StringLen($ContentSource)
	$pos1 = StringInStr($ContentSource, "\", 0, -1)

	If $pos1 Then
		$content_folder = StringRight($ContentSource, $len-$pos1)
	Else
		$content_folder = ""
	EndIf
	; MsgBox(48, "Content Folder", " Content Folder = " & $content_folder)

	$ContentSize = DirGetSize($ContentSource)
	$ContentSize = Round(($ContentSize / 1024 / 1024) + 0.4999999)
	GUICtrlSetData($GUI_ContentSize, $ContentSize & " MB")

	If $ContentSize = 0 Then
		MsgBox(48,"ERROR - Return", " Content Source is Empty " & @CRLF & @CRLF & " Selected Source = " & $TempLinuxSource)
		$ContentSource = ""
		GUICtrlSetData($AddContentSource, "")
		$ContentSize=0
		GUICtrlSetData($GUI_ContentSize, "")
		CheckSize()
		DisableMenus(0)
		Return
	EndIf

	If Not CheckSize() Then
		MsgBox(48, "ERROR - OverFlow", " NOT Enough FreeSpace to Add Source ")
		$ContentSource = ""
		GUICtrlSetData($AddContentSource, "")
		$ContentSize=0
		GUICtrlSetData($GUI_ContentSize, "")
		CheckSize()
	EndIf
	DisableMenus(0)
EndFunc ;==>_GetContentSource()
;===================================================================================================
Func CheckSize()
	; _GUICtrlStatusBar_SetText($hStatus," Measuring Total Source Size - Wait... ", 0)

	If $TargetDrive <> "" Then
		$TargetSpaceAvail = Round(DriveSpaceFree($TargetDrive))
	Else
		$TargetSpaceAvail = 0
	EndIf
	If $WinDrvDrive <> "" Then
		$WinDrvSpaceAvail = Round(DriveSpaceFree($WinDrvDrive))
	Else
		$WinDrvSpaceAvail = 0
	EndIf

	If $ContentSource <> "" Then
		$ContentSize = DirGetSize($ContentSource)
		$ContentSize = Round($ContentSize / 1024 / 1024,1)
	Else
		$ContentSize = 0
	EndIf

	If $btimgfile <> "" Then
		$BTIMGSize = FileGetSize($btimgfile)
		$BTIMGSize = Round($BTIMGSize / 1024 / 1024)
	Else
		$BTIMGSize = 0
	EndIf

	; No copy of image file
	$TotalSourceSize = $ContentSize

	If GUICtrlRead($Combo_Folder) = "Folder on S" Or GUICtrlRead($Combo_Folder) = "System Drive" Then
		If $WinDrvSpaceAvail < $TotalSourceSize * 1.05 Then Return 0
	Else
		If $TargetSpaceAvail < $TotalSourceSize * 1.05 Then Return 0
	EndIf

	Return 1
EndFunc ;==>_CheckSize()
;===================================================================================================
Func _CopyDirWithProgress($aFileList, $sDestDir, $sl, $NrAllFiles, $CopyFlag)
;original author: ezzetabi
Local $fProgressAll, $c, $FileName, $iOutPut = 0, $sLost = '', $ddfn, $msg
;$sOriginalDir and $sDestDir are quite selfexplanatory...
  ;This func returns:
  ; -1 in case of critical error, bad original or destination dir
  ;  0 if everything went all right
  ; >0 is the number of file not copied
	If StringRight($sDestDir, 1) <> '\' Then $sDestDir = $sDestDir & '\'
	_GUICtrlStatusBar_SetText($hStatus,$NrAllFiles, 2)
	If $aFileList[0] = 0 Then
		SetError(1)
		Return -1
	EndIf
	If FileExists($sDestDir) Then
		If Not StringInStr(FileGetAttrib($sDestDir), 'd') Then
			SetError(2)
			Return -1
		EndIf
	Else
		DirCreate($sDestDir)
		If Not FileExists($sDestDir) Then
			SetError(2)
			Return -1
		EndIf
	EndIf
	Opt("GUIOnEventMode", 0)
	For $c = 1 To $aFileList[0]
		$NrCpdFiles += 1
		$msg = GUIGetMsg()
		If $msg = $EXIT  Then
			Opt("GUIOnEventMode", 1)
			_Quit()
			Opt("GUIOnEventMode", 0)
		Else
			$FileName = StringTrimLeft($aFileList[$c], $sl)
			$fProgressAll = Int($NrCpdFiles * 100/ $NrAllFiles)
			GUICtrlSetData($ProgressAll, $fProgressAll)
			_GUICtrlStatusBar_SetText($hStatus, StringRight($aFileList[$c], 40), 0)
			_GUICtrlStatusBar_SetText($hStatus,$NrCpdFiles, 1)
			$ddfn = StringReplace($sDestDir & $FileName, "\\", "\")
			If StringInStr(FileGetAttrib($aFileList[$c]), 'd') Then
				DirCreate($ddfn)
			Else
				If Not FileCopy($aFileList[$c], $ddfn, $CopyFlag + 8) Then
					;modified Tries a second time After Setting Attribute to -RSH
					FileSetAttrib($ddfn, "-RSH", 1)
					If Not FileCopy($aFileList[$c], $ddfn, $CopyFlag + 8) Then
						$iOutPut = $iOutPut + 1
						If $iOutPut < 6 Then $sLost = $sLost & $aFileList[$c] & @CRLF
					EndIf
				EndIf
			EndIf
		EndIf
	Next
	Opt("GUIOnEventMode", 1)
	If $iOutPut Then MsgBox(48, "ERROR - No FileCopy", $iOutPut & " FileCopy ERRORS" & @CRLF & @CRLF & $sLost)
	Return $iOutPut
EndFunc  ;==>_CopyDirWithProgress
;===================================================================================================
Func _FileSearch($sPath, $sFilter = '*.*', $iFlag = 0, $ExcludeFile = '', $iRecurse = True)
;===============================================================================
;
; Description:      lists all or preferred files and or folders in a specified path (Similar to using Dir with the /B Switch)
; Syntax:           _FileListToArrayEx($sPath, $sFilter = '*.*', $iFlag = 0, $ExcludeFile = '')
; Parameter(s):        $sPath = Path to generate filelist for
;                    $sFilter = The filter to use. Search the Autoit3 manual for the word "WildCards" For details, support now for multiple searches
;                            Example *.exe; *.txt will find all .exe and .txt files
;                   $iFlag = determines weather to return file or folders or both.
;                    $ExcludeFile = CustomFile.txt with list of Folders and files to exclude
;                     Example: Entry I386\LANG\ will exclude all files from folder LANG
;                        $iFlag=0(Default) Return both files and folders
;                       $iFlag=1 Return files Only
;                        $iFlag=2 Return Folders Only
;
; Requirement(s):   None
; Return Value(s):  On Success - Returns an array containing the list of files and folders in the specified path
;                        On Failure - Returns the an empty string "" if no files are found and sets @Error on errors
;                        @Error or @extended = 1 Path not found or invalid
;                        @Error or @extended = 2 Invalid $sFilter
;                       @Error or @extended = 3 Invalid $iFlag
;                         @Error or @extended = 4 No File(s) Found
;
; Author(s):        SmOke_N
; Note(s):            The array returned is one-dimensional and is made up as follows:
;                    $array[0] = Number of Files\Folders returned
;                    $array[1] = 1st File\Folder
;                    $array[2] = 2nd File\Folder
;                    $array[3] = 3rd File\Folder
;                    $array[n] = nth File\Folder
;
;                    All files are written to a "reserved" .tmp file (Thanks to gafrost) for the example
;                    The Reserved file is then read into an array, then deleted
;===============================================================================
; Modified by wimb for EXCLUDE filelist
; $ExcludeFile = CustomFile.txt with list of Folders and files to exclude
	Local $exfile, $line, $count, $exlist[3000]
    If $ExcludeFile = -1 Or $ExcludeFile = Default Then $ExcludeFile = ""
	If $ExcludeFile And FileExists($ExcludeFile) Then
		$exfile = FileOpen($ExcludeFile, 0)
		$count = 0
		While $count < 2999
			$line = FileReadLine($exfile)
			If @error = -1 Then ExitLoop
			If $line <> "" Then
				$count = $count + 1
				$line = StringStripWS($line, 3)
				$exlist[0] = $count
				$exlist[$count]=$line
			EndIf
		Wend
		FileClose($exfile)
;		_ArrayDisplay($exlist)
	EndIf

    If Not FileExists($sPath) Then Return SetError(1, 1, '')
    If $sFilter = -1 Or $sFilter = Default Then $sFilter = '*.*'
    If $iFlag = -1 Or $iFlag = Default Then $iFlag = 0
    Local $aBadChar[6] = ['\', '/', ':', '>', '<', '|']
    $sFilter = StringRegExpReplace($sFilter, '\s*;\s*', ';')
    If StringRight($sPath, 1) <> '\' Then $sPath &= '\'
    For $iCC = 0 To 5
        If StringInStr($sFilter, $aBadChar[$iCC]) Then Return SetError(2, 2, '')
    Next
    If StringStripWS($sFilter, 8) = '' Then Return SetError(2, 2, '')
    If Not ($iFlag = 0 Or $iFlag = 1 Or $iFlag = 2) Then Return SetError(3, 3, '')
    Local $oFSO = ObjCreate("Scripting.FileSystemObject"), $sTFolder
    $sTFolder = $oFSO.GetSpecialFolder(2)
    Local $hOutFile = @TempDir & $oFSO.GetTempName
    If Not StringInStr($sFilter, ';') Then $sFilter &= ';'
    Local $aSplit = StringSplit(StringStripWS($sFilter, 8), ';'), $sRead, $sHoldSplit
    For $iCC = 1 To $aSplit[0]
        If StringStripWS($aSplit[$iCC],8) = '' Then ContinueLoop
        If StringLeft($aSplit[$iCC], 1) = '.' And _
            UBound(StringSplit($aSplit[$iCC], '.')) - 2 = 1 Then $aSplit[$iCC] = '*' & $aSplit[$iCC]
        $sHoldSplit &= '"' & $sPath & $aSplit[$iCC] & '" '
    Next
    $sHoldSplit = StringTrimRight($sHoldSplit, 1)

    If $iRecurse Then
        RunWait(@Comspec & ' /c dir /b /s /a ' & $sHoldSplit & ' > "' & $hOutFile & '"', '', @SW_HIDE)
    Else
        RunWait(@ComSpec & ' /c dir /b /a ' & $sHoldSplit & ' /o-e /od > "' & $hOutFile & '"', '', @SW_HIDE)
    EndIf
    $sRead &= FileRead($hOutFile)
    If Not FileExists($hOutFile) Then Return SetError(4, 4, '')
    FileDelete($hOutFile)
    If StringStripWS($sRead, 8) = '' Then SetError(4, 4, '')
    Local $aFSplit = StringSplit(StringTrimRight(StringStripCR($sRead), 1), @LF)
    Local $sHold, $a_AnsiFName
    For $iCC = 1 To $aFSplit[0]
        ; translate DOS filenames from OEM to ANSI
        $a_AnsiFName = DllCall('user32.dll','Int','OemToChar','str',$aFSplit[$iCC],'str','')
        If @error=0 Then $aFSplit[$iCC] = $a_AnsiFName[2]
		; Exclude Folders and Files from File $ExcludeFile
		For $iEx = 1 To $exlist[0]
			; If StringInStr($aFSplit[$iCC], "\" & $exlist[$iEx]) Then ContinueLoop 2
			If StringInStr($aFSplit[$iCC], $exlist[$iEx]) Then ContinueLoop 2
		Next

        Switch $iFlag
			Case 0
				; modified by wimb to allow Network Share as XP Source, the double backslash gives problem with the commented code below
				; If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
                ;    $sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
				; Else
				$sHold &= $aFSplit[$iCC] & Chr(1)
				; EndIf
            Case 1
                If StringInStr(FileGetAttrib($sPath & '\' & $aFSplit[$iCC]), 'd') = 0 And _
                    StringInStr(FileGetAttrib($aFSplit[$iCC]), 'd') = 0 Then
                    ; If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
					; 	$sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
					; Else
					$sHold &= $aFSplit[$iCC] & Chr(1)
                    ; EndIf
                EndIf
            Case 2
                If StringInStr(FileGetAttrib($sPath & '\' & $aFSplit[$iCC]), 'd') Or _
                    StringInStr(FileGetAttrib($aFSplit[$iCC]), 'd') Then
					; If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
					;	$sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
                    ; Else
					$sHold &= $aFSplit[$iCC] & Chr(1)
                    ; EndIf
                EndIf
        EndSwitch
    Next
    If StringTrimRight($sHold, 1) Then Return StringSplit(StringTrimRight($sHold, 1), Chr(1))
    Return SetError(4, 4, '')
EndFunc
;===================================================================================================
Func _BCD_Create()

	$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

	If Not FileExists($TargetDrive & "\Boot\BCD") Then
		DirCopy(@WindowsDir & "\Boot\PCAT", $TargetDrive & "\Boot", 1)
		DirCopy(@WindowsDir & "\Boot\Fonts", $TargetDrive & "\Boot\Fonts", 1)
		DirCopy(@WindowsDir & "\Boot\Resources", $TargetDrive & "\Boot\Resources", 1)
		If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi") Then
			FileCopy(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi", $TargetDrive & "\Boot\", 1)
		EndIf
		FileMove($TargetDrive & "\Boot\bootmgr", $TargetDrive & "\bootmgr", 1)
		FileMove($TargetDrive & "\Boot\bootnxt", $TargetDrive & "\BOOTNXT", 1)

		$store = $TargetDrive & "\Boot\BCD"
		RunWait(@ComSpec & " /c " & $bcdedit & " /createstore " & $store, $TargetDrive & "\", @SW_HIDE)
		sleep(1000)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {bootmgr}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} description " & '"' & "Windows Boot Manager" & '"', $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} inherit {globalsettings}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 20", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} toolsdisplayorder {memdiag}", $TargetDrive & "\", @SW_HIDE)
		; sleep(1000)

		$winload = "winload.exe"
		$bcd_guid_outfile = "makebt\bs_temp\crea_win_guid.txt"
		_win_boot_menu()

		$sdi_guid_outfile = "makebt\bs_temp\crea_sdi_guid.txt"
		$bcd_guid_outfile = "makebt\bs_temp\crea_pe_guid.txt"
		_pe_boot_menu()

		_mem_boot_menu()

	EndIf

	If Not FileExists($TargetDrive & "\EFI\Microsoft\Boot\BCD") Then
		_GUICtrlStatusBar_SetText($hStatus," PE x64 - Make EFI Manager Menu on USB " & $TargetDrive & " - wait .... ", 0)
		DirCopy(@WindowsDir & "\Boot\EFI", $TargetDrive & "\EFI\Microsoft\Boot", 1)
		DirCopy(@WindowsDir & "\Boot\Fonts", $TargetDrive & "\EFI\Microsoft\Boot\Fonts", 1)
		DirCopy(@WindowsDir & "\Boot\Resources", $TargetDrive & "\EFI\Microsoft\Boot\Resources", 1)
		If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi") Then
			FileCopy(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi", $TargetDrive & "\Boot\", 1)
		EndIf
		If FileExists(@WindowsDir & "\Boot\EFI\bootmgfw.efi") Then
			FileCopy(@WindowsDir & "\Boot\EFI\bootmgfw.efi", $TargetDrive & "\EFI\Boot\", 9)
			If @OSArch <> "X86" Then
				FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootx64.efi", 1)
			Else
				FileMove($TargetDrive & "\EFI\Boot\bootmgfw.efi", $TargetDrive & "\EFI\Boot\bootia32.efi", 1)
			EndIf
		EndIf

		$store = $TargetDrive & "\EFI\Microsoft\Boot\BCD"
		RunWait(@ComSpec & " /c " & $bcdedit & " /createstore " & $store, $TargetDrive & "\", @SW_HIDE)
		sleep(1000)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {bootmgr}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} description " & '"' & "Windows Boot Manager" & '"', $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} inherit {globalsettings}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 20", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} toolsdisplayorder {memdiag}", $TargetDrive & "\", @SW_HIDE)
		; sleep(1000)

		$winload = "winload.efi"
		$bcd_guid_outfile = "makebt\bs_temp\crea_efi_win_guid.txt"
		_win_boot_menu()

		$sdi_guid_outfile = "makebt\bs_temp\crea_efi_sdi_guid.txt"
		$bcd_guid_outfile = "makebt\bs_temp\crea_efi_pe_guid.txt"
		_pe_boot_menu()

		_mem_boot_menu()

	EndIf

EndFunc ;==>  _BCD_Create
;===================================================================================================
Func _pe_boot_menu()

	Local $val=0, $len, $pos, $sdi_file = "boot.sdi"
	Local $guid, $pos1, $pos2, $ramdisk_guid = "", $pe_guid = ""
	Local $file, $line

	$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create /device > " & $sdi_guid_outfile, @ScriptDir, @SW_HIDE)
	$file = FileOpen(@ScriptDir & "\" & $sdi_guid_outfile, 0)
	$line = FileReadLine($file)
	FileClose($file)
	$pos1 = StringInStr($line, "{")
	$pos2 = StringInStr($line, "}")
	If $pos2-$pos1=37 Then
		$ramdisk_guid = StringMid($line, $pos1, $pos2-$pos1+1)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $ramdisk_guid & " ramdisksdidevice boot", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $ramdisk_guid & " ramdisksdipath \Boot\" & $sdi_file, $TargetDrive & "\", @SW_HIDE)
	EndIf
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create /application osloader > " & $bcd_guid_outfile, @ScriptDir, @SW_HIDE)
	$file = FileOpen(@ScriptDir & "\" & $bcd_guid_outfile, 0)
	$line = FileReadLine($file)
	FileClose($file)
	$pos1 = StringInStr($line, "{")
	$pos2 = StringInStr($line, "}")
	If $pos2-$pos1=37 And $ramdisk_guid <> "" Then
		$pe_guid = StringMid($line, $pos1, $pos2-$pos1+1)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " DESCRIPTION " & "PE-Boot-WIM", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " device ramdisk=[boot]\boot.wim," & $ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " osdevice ramdisk=[boot]\boot.wim," & $ramdisk_guid, $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " systemroot \Windows", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " inherit {bootloadersettings}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " nx OptIn", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " detecthal on", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " winpe Yes", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /displayorder " & $pe_guid & " /addfirst", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " NoIntegrityChecks 1", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " loadoptions DISABLE_INTEGRITY_CHECKS", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $pe_guid & " testsigning on", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /default " & $pe_guid, $TargetDrive & "\", @SW_HIDE)
	EndIf
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} nointegritychecks on", $TargetDrive & "\", @SW_HIDE)
	; to get PE ProgressBar and Win Boot Manager Menu displayed and waiting for User Selection
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /bootems {emssettings} ON", $TargetDrive & "\", @SW_HIDE)

EndFunc   ;==> _pe_boot_menu
;===================================================================================================
Func _win_boot_menu()

	Local $val=0, $len, $pos
	Local $guid, $pos1, $pos2, $win_guid = ""
	Local $file, $line

	$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create /application osloader > " & $bcd_guid_outfile, @ScriptDir, @SW_HIDE)
	$file = FileOpen(@ScriptDir & "\" & $bcd_guid_outfile, 0)
	$line = FileReadLine($file)
	FileClose($file)
	$pos1 = StringInStr($line, "{")
	$pos2 = StringInStr($line, "}")
	If $pos2-$pos1=37 Then
		$win_guid = StringMid($line, $pos1, $pos2-$pos1+1)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " DESCRIPTION " & "Windows-C-Drive", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " device partition=C:", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " osdevice partition=C:", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " systemroot \Windows", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " path \Windows\system32\" & $winload, $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " inherit {bootloadersettings}", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " nx OptIn", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /displayorder " & $win_guid & " /addfirst", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $win_guid & " bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
	EndIf

EndFunc   ;==> _win_boot_menu
;===================================================================================================
Func _mem_boot_menu()

	$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {memdiag}", @ScriptDir, @SW_HIDE)
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} DESCRIPTION " & '"' & "Windows Memory Diagnostic" & '"', $TargetDrive & "\", @SW_HIDE)
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} device boot", $TargetDrive & "\", @SW_HIDE)
	If $store = $TargetDrive & "\Boot\BCD" Then
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set {memdiag} path \Boot\memtest.exe", $TargetDrive & "\", @SW_HIDE)
	Else
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set {memdiag} path \EFI\Microsoft\Boot\memtest.efi", $TargetDrive & "\", @SW_HIDE)
	EndIf
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} inherit {globalsettings}", $TargetDrive & "\", @SW_HIDE)
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} badmemoryaccess Yes", $TargetDrive & "\", @SW_HIDE)

EndFunc   ;==> _win_boot_menu
;===================================================================================================
Func _BCD_Inside_Entry()

	Local $file, $line, $pos1, $pos2, $guid

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /create /d " & '"' & $vhdfile_name_only & '"' & " /application osloader > " & $bcd_guid_outfile, @ScriptDir, @SW_HIDE)
	$file = FileOpen(@ScriptDir & "\" & $bcd_guid_outfile, 0)
	$line = FileReadLine($file)
	FileClose($file)
	$pos1 = StringInStr($line, "{")
	$pos2 = StringInStr($line, "}")
	If $pos2-$pos1=37 Then
		$guid = StringMid($line, $pos1, $pos2-$pos1+1)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " device boot", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " path \Windows\system32\" & $winload, $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " osdevice boot", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " systemroot \Windows", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " locale " & $DistLang, $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " nx OptIn", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /displayorder " & $guid & " /addfirst", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /default " & $guid, $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " detecthal on", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " bootmenupolicy legacy", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " loadoptions DISABLE_INTEGRITY_CHECKS", $tmpdrive & "\", @SW_HIDE)
		; If $SysWOW64=1 And StringRight($vhdfile_name_only, 4) = ".vhd" And $PartStyle = "MBR" Or $driver_flag = 3 Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " testsigning on", $tmpdrive & "\", @SW_HIDE)
		; EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} nointegritychecks on", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 1", $tmpdrive & "\", @SW_HIDE)
		; to get PE ProgressBar and Win 8 Boot Manager Menu displayed and waiting for User Selection
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /bootems {emssettings} ON", $tmpdrive & "\", @SW_HIDE)
	EndIf
EndFunc ;==>  _BCD_Inside_Entry
;===================================================================================================
Func _BCD_Inside_VHD()

	Local $val=0

	If FileExists(@WindowsDir & "\system32\bcdboot.exe") And Not FileExists($tmpdrive & "\Boot\BCD") Then
		; in win8 x64 OS then Win8x64 bcdboot with option /f ALL must be used, otherwise entry is not made
		If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
			_GUICtrlStatusBar_SetText($hStatus," UEFI x64 - Make Boot Manager Inside VHD - wait .... ", 0)
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $tmpdrive & " /f ALL", @ScriptDir, @SW_HIDE)
		Else
			_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager Inside VHD - wait .... ", 0)
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $tmpdrive, @ScriptDir, @SW_HIDE)
		EndIf
		Sleep(2000)
	EndIf
	If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($tmpdrive & "\Boot\BCD") Then
		_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager entry Inside VHD", 0)
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
		$store = $tmpdrive & "\Boot\BCD"
		$winload = "winload.exe"
		$bcd_guid_outfile = "makebt\bs_temp\bcd_boot_vhd.txt"

		_BCD_Inside_Entry()

		Sleep(2000)
		FileSetAttrib($tmpdrive & "\Boot", "-RSH", 1)
		FileSetAttrib($tmpdrive & "\bootmgr", "-RSH")
	EndIf
	If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($tmpdrive & "\EFI\Microsoft\Boot\BCD") Then
		_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager entry Inside VHD", 0)
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
		$store = $tmpdrive & "\EFI\Microsoft\Boot\BCD"
		$winload = "winload.efi"
		$bcd_guid_outfile = "makebt\bs_temp\bcd_efi_vhd.txt"

		_BCD_Inside_Entry()

	EndIf

EndFunc ;==>  _BCD_Inside_VHD
;===================================================================================================
Func _BCD_BootDrive_VHD_Entry()
	Local $file, $line, $pos1, $pos2, $guid

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /create /d " & '"' & $vhdfile_name & '"' & " /application osloader > " & $bcd_guid_outfile, @ScriptDir, @SW_HIDE)
	$file = FileOpen(@ScriptDir & "\" & $bcd_guid_outfile, 0)
	$line = FileReadLine($file)
	FileClose($file)
	$pos1 = StringInStr($line, "{")
	$pos2 = StringInStr($line, "}")
	If $pos2-$pos1=37 Then
		$guid = StringMid($line, $pos1, $pos2-$pos1+1)
		If $PartStyle = "GPT" Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " device vhd=[" & $WinDrvDrive & "]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " osdevice vhd=[" & $WinDrvDrive & "]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
		Else
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " device vhd=[locate]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " osdevice vhd=[locate]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
		EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " path \Windows\system32\" & $winload, $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " systemroot \Windows", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " locale " & $DistLang, $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " nx OptIn", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /displayorder " & $guid & " /addfirst", $TargetDrive & "\", @SW_HIDE)
		If $bcdboot_flag = 1 Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /default " & $guid, $TargetDrive & "\", @SW_HIDE)
		EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " detecthal on", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " loadoptions DISABLE_INTEGRITY_CHECKS", $TargetDrive & "\", @SW_HIDE)
		; If $SysWOW64=1 And StringRight($vhdfile_name, 4) = ".vhd" And $PartStyle = "MBR" Or $driver_flag = 3 Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " testsigning on", $TargetDrive & "\", @SW_HIDE)
		; EndIf
		If $OS_drive <> $TargetDrive Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set {bootmgr} nointegritychecks on", $TargetDrive & "\", @SW_HIDE)
		EndIf
		; to get PE ProgressBar and Win 8 Boot Manager Menu displayed and waiting for User Selection
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /bootems {emssettings} ON", $TargetDrive & "\", @SW_HIDE)
	EndIf

EndFunc ;==>  _BCD_BootDrive_VHD_Entry
;===================================================================================================
Func _DetectLang()
	If FileExists($tmpdrive & "\Windows\System32\en-US\ieframe.dll.mui") Then $DistLang = "en-US"
	If FileExists($tmpdrive & "\Windows\System32\ar-SA\ieframe.dll.mui") Then $DistLang = "ar-SA"
	If FileExists($tmpdrive & "\Windows\System32\bg-BG\ieframe.dll.mui") Then $DistLang = "bg-BG"
	If FileExists($tmpdrive & "\Windows\System32\cs-CZ\ieframe.dll.mui") Then $DistLang = "cs-CZ"
	If FileExists($tmpdrive & "\Windows\System32\da-DK\ieframe.dll.mui") Then $DistLang = "da-DK"
	If FileExists($tmpdrive & "\Windows\System32\de-DE\ieframe.dll.mui") Then $DistLang = "de-DE"
	If FileExists($tmpdrive & "\Windows\System32\el-GR\ieframe.dll.mui") Then $DistLang = "el-GR"
	If FileExists($tmpdrive & "\Windows\System32\es-ES\ieframe.dll.mui") Then $DistLang = "es-ES"
	If FileExists($tmpdrive & "\Windows\System32\es-MX\ieframe.dll.mui") Then $DistLang = "es-MX"
	If FileExists($tmpdrive & "\Windows\System32\et-EE\ieframe.dll.mui") Then $DistLang = "et-EE"
	If FileExists($tmpdrive & "\Windows\System32\fi-FI\ieframe.dll.mui") Then $DistLang = "fi-FI"
	If FileExists($tmpdrive & "\Windows\System32\fr-FR\ieframe.dll.mui") Then $DistLang = "fr-FR"
	If FileExists($tmpdrive & "\Windows\System32\he-IL\ieframe.dll.mui") Then $DistLang = "he-IL"
	If FileExists($tmpdrive & "\Windows\System32\hr-HR\ieframe.dll.mui") Then $DistLang = "hr-HR"
	If FileExists($tmpdrive & "\Windows\System32\hu-HU\ieframe.dll.mui") Then $DistLang = "hu-HU"
	If FileExists($tmpdrive & "\Windows\System32\it-IT\ieframe.dll.mui") Then $DistLang = "it-IT"
	If FileExists($tmpdrive & "\Windows\System32\ja-JP\ieframe.dll.mui") Then $DistLang = "ja-JP"
	If FileExists($tmpdrive & "\Windows\System32\ko-KR\ieframe.dll.mui") Then $DistLang = "ko-KR"
	If FileExists($tmpdrive & "\Windows\System32\lt-LT\ieframe.dll.mui") Then $DistLang = "lt-LT"
	If FileExists($tmpdrive & "\Windows\System32\lv-LV\ieframe.dll.mui") Then $DistLang = "lv-LV"
	If FileExists($tmpdrive & "\Windows\System32\nb-NO\ieframe.dll.mui") Then $DistLang = "nb-NO"
	If FileExists($tmpdrive & "\Windows\System32\nl-NL\ieframe.dll.mui") Then $DistLang = "nl-NL"
	If FileExists($tmpdrive & "\Windows\System32\pl-PL\ieframe.dll.mui") Then $DistLang = "pl-PL"
	If FileExists($tmpdrive & "\Windows\System32\pt-BR\ieframe.dll.mui") Then $DistLang = "pt-BR"
	If FileExists($tmpdrive & "\Windows\System32\pt-PT\ieframe.dll.mui") Then $DistLang = "pt-PT"
	If FileExists($tmpdrive & "\Windows\System32\ro-RO\ieframe.dll.mui") Then $DistLang = "ro-RO"
	If FileExists($tmpdrive & "\Windows\System32\ru-RU\ieframe.dll.mui") Then $DistLang = "ru-RU"
	If FileExists($tmpdrive & "\Windows\System32\sk-SK\ieframe.dll.mui") Then $DistLang = "sk-SK"
	If FileExists($tmpdrive & "\Windows\System32\sl-SI\ieframe.dll.mui") Then $DistLang = "sl-SI"
	If FileExists($tmpdrive & "\Windows\System32\sr-Latn-CS\ieframe.dll.mui") Then $DistLang = "sr-Latn-CS"
	If FileExists($tmpdrive & "\Windows\System32\sv-SE\ieframe.dll.mui") Then $DistLang = "sv-SE"
	If FileExists($tmpdrive & "\Windows\System32\th-TH\ieframe.dll.mui") Then $DistLang = "th-TH"
	If FileExists($tmpdrive & "\Windows\System32\tr-TR\ieframe.dll.mui") Then $DistLang = "tr-TR"
	If FileExists($tmpdrive & "\Windows\System32\uk-UA\ieframe.dll.mui") Then $DistLang = "uk-UA"
	If FileExists($tmpdrive & "\Windows\System32\zh-CN\ieframe.dll.mui") Then $DistLang = "zh-CN"
	If FileExists($tmpdrive & "\Windows\System32\zh-HK\ieframe.dll.mui") Then $DistLang = "zh-HK"
	If FileExists($tmpdrive & "\Windows\System32\zh-TW\ieframe.dll.mui") Then $DistLang = "zh-TW"
EndFunc   ;==> _DetectLang
;===================================================================================================
Func _WinLang()
	If FileExists(@WindowsDir & "\System32\en-US\ieframe.dll.mui") Then $WinLang = "en-US"
	If FileExists(@WindowsDir & "\System32\ar-SA\ieframe.dll.mui") Then $WinLang = "ar-SA"
	If FileExists(@WindowsDir & "\System32\bg-BG\ieframe.dll.mui") Then $WinLang = "bg-BG"
	If FileExists(@WindowsDir & "\System32\cs-CZ\ieframe.dll.mui") Then $WinLang = "cs-CZ"
	If FileExists(@WindowsDir & "\System32\da-DK\ieframe.dll.mui") Then $WinLang = "da-DK"
	If FileExists(@WindowsDir & "\System32\de-DE\ieframe.dll.mui") Then $WinLang = "de-DE"
	If FileExists(@WindowsDir & "\System32\el-GR\ieframe.dll.mui") Then $WinLang = "el-GR"
	If FileExists(@WindowsDir & "\System32\es-ES\ieframe.dll.mui") Then $WinLang = "es-ES"
	If FileExists(@WindowsDir & "\System32\es-MX\ieframe.dll.mui") Then $WinLang = "es-MX"
	If FileExists(@WindowsDir & "\System32\et-EE\ieframe.dll.mui") Then $WinLang = "et-EE"
	If FileExists(@WindowsDir & "\System32\fi-FI\ieframe.dll.mui") Then $WinLang = "fi-FI"
	If FileExists(@WindowsDir & "\System32\fr-FR\ieframe.dll.mui") Then $WinLang = "fr-FR"
	If FileExists(@WindowsDir & "\System32\he-IL\ieframe.dll.mui") Then $WinLang = "he-IL"
	If FileExists(@WindowsDir & "\System32\hr-HR\ieframe.dll.mui") Then $WinLang = "hr-HR"
	If FileExists(@WindowsDir & "\System32\hu-HU\ieframe.dll.mui") Then $WinLang = "hu-HU"
	If FileExists(@WindowsDir & "\System32\it-IT\ieframe.dll.mui") Then $WinLang = "it-IT"
	If FileExists(@WindowsDir & "\System32\ja-JP\ieframe.dll.mui") Then $WinLang = "ja-JP"
	If FileExists(@WindowsDir & "\System32\ko-KR\ieframe.dll.mui") Then $WinLang = "ko-KR"
	If FileExists(@WindowsDir & "\System32\lt-LT\ieframe.dll.mui") Then $WinLang = "lt-LT"
	If FileExists(@WindowsDir & "\System32\lv-LV\ieframe.dll.mui") Then $WinLang = "lv-LV"
	If FileExists(@WindowsDir & "\System32\nb-NO\ieframe.dll.mui") Then $WinLang = "nb-NO"
	If FileExists(@WindowsDir & "\System32\nl-NL\ieframe.dll.mui") Then $WinLang = "nl-NL"
	If FileExists(@WindowsDir & "\System32\pl-PL\ieframe.dll.mui") Then $WinLang = "pl-PL"
	If FileExists(@WindowsDir & "\System32\pt-BR\ieframe.dll.mui") Then $WinLang = "pt-BR"
	If FileExists(@WindowsDir & "\System32\pt-PT\ieframe.dll.mui") Then $WinLang = "pt-PT"
	If FileExists(@WindowsDir & "\System32\ro-RO\ieframe.dll.mui") Then $WinLang = "ro-RO"
	If FileExists(@WindowsDir & "\System32\ru-RU\ieframe.dll.mui") Then $WinLang = "ru-RU"
	If FileExists(@WindowsDir & "\System32\sk-SK\ieframe.dll.mui") Then $WinLang = "sk-SK"
	If FileExists(@WindowsDir & "\System32\sl-SI\ieframe.dll.mui") Then $WinLang = "sl-SI"
	If FileExists(@WindowsDir & "\System32\sr-Latn-CS\ieframe.dll.mui") Then $WinLang = "sr-Latn-CS"
	If FileExists(@WindowsDir & "\System32\sv-SE\ieframe.dll.mui") Then $WinLang = "sv-SE"
	If FileExists(@WindowsDir & "\System32\th-TH\ieframe.dll.mui") Then $WinLang = "th-TH"
	If FileExists(@WindowsDir & "\System32\tr-TR\ieframe.dll.mui") Then $WinLang = "tr-TR"
	If FileExists(@WindowsDir & "\System32\uk-UA\ieframe.dll.mui") Then $WinLang = "uk-UA"
	If FileExists(@WindowsDir & "\System32\zh-CN\ieframe.dll.mui") Then $WinLang = "zh-CN"
	If FileExists(@WindowsDir & "\System32\zh-HK\ieframe.dll.mui") Then $WinLang = "zh-HK"
	If FileExists(@WindowsDir & "\System32\zh-TW\ieframe.dll.mui") Then $WinLang = "zh-TW"
EndFunc   ;==> _WinLang
;===================================================================================================
