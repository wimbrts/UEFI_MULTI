

License and copyright information
-----------------------------------

	SVBus - Virtual SCSI Host Adapter
	Copyright (C) 2020 Kai Schtrom

	This file is part of SVBus.

	SVBus is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	SVBus is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with SVBus.  If not, see <http://www.gnu.org/licenses/>.


How to compile SVBus driver
-----------------------------

- install Windows Driver Kit version 7600.16385.1
- unpack SVBus.rar and copy SVBus folder to C:\SVBus
- run "make_chk.cmd" to create the checked build or run "make_fre.cmd" to create
  the free build from the directory "C:\SVBus\src"
- the final driver files can be found in "C:\SVBus\src\bin"


How to compile SVBus Installer
--------------------------------

- install Windows Driver Kit version 7600.16385.1
- unpack SVBus.rar and copy Installer folder to C:\Installer
- run "make_fre.cmd" to create the free build from the directory "C:\Installer\src"
- the final Installer can be found in "C:\Installer\src\bin"
- to support Windows 2000 we have to patch the subsystem version in the PE header
  from 5.02 to 5.00 and correct the PE checksum with LordPE


Install Windows 10 x64 Build 1709 to VHD
------------------------------------------

Things you'll need for installation before starting:
- Computer with a blank HDD or SSD
- Windows 10 x64 Boot-CD
- USB drive with the following files:
  - GRUB4DOS loader named "grldr" version 0.4.5c
  - SVBus binary driver file package

How to install the OS:
- boot Windows 10 x64 Setup from DVD > choose your language and keyboard layout
  > press Next > choose "Install now"
  You should always first choose your language before continuing with the next
  steps, because otherwise your keyboard layout does not match.
- in the dialog with the title "Windows Setup" press Shift + F10 to open a
  command prompt and type the following commands to create a new primary active
  partition on the HDD/SSD:
  - diskpart
  - list disk
  - select disk=0
    You should select the correct disk number. If you only have one HDD/SSD
    connected, which is recommended, choose disk 0.
  - create partition primary
  - active
  - format fs=NTFS quick
  - assign letter=C
  - exit
- in the open command prompt type the following commands to create a new blank
  fixed VHD file:
  - diskpart
  - create vdisk file=C:\win10.vhd maximum=15000 type=fixed
    You could choose a greater size if you want, but it is recommended that you
    do not choose a size bigger than your RAM, otherwise we can not load the VHD
    to RAM later on. The value should be 2 to 3 GB less than your installed RAM,
    otherwise the OS has no more available RAM at runtime.
  - select vdisk file=C:\win10.vhd
  - attach vdisk
  - create partition primary
  - active
  - format fs=NTFS quick
  - exit
  - exit
- enter product key or choose "I don't have a product key"
- select Windows 10 Pro > Next > check "I accept the license terms" > Next
- choose "Custom: Install Windows only (advanced)"
- we should now see two drives, choose Drive 1 Partition 1 with a size of 14.6
  GB > Next > Windows 10 x64 installation is running > choose your region and
  other stuff as usual
- after the installation is finished do the following steps in the running
  Windows 10 OS
- rename "D:\bootmgr" to "D:\bootmgr10"
  To see the bootmgr file you have to disable the hiding of protected OS files
  in Windows Explorer. After the rename you have to choose "Yes" 3 times.
- copy the file grldr from the USB drive to "D:\grldr" and rename it to "D:\bootmgr"
  This will activate GRUB4DOS boot without altering the MBR.
- open notepad and create a file named "D:\menu.lst" with the following content:
  # run Windows 10

  title Windows 10 native VHD
  chainloader /bootmgr10

  title Windows 10 - RAMDISK
  find --set-root --ignore-floppies /win10.vhd
  map --mem /win10.vhd (hd0)
  map --hook
  root (hd0,0)
  chainloader /bootmgr

  title Windows 10 - FILEDISK
  find --set-root --ignore-floppies /win10.vhd
  map /win10.vhd (hd0)
  map --hook
  rootnoverify (hd0,0)
  chainloader /bootmgr
- open a command prompt as Administrator and type the following to disable
  driver signature enforcement:
  bcdedit -set loadoptions DISABLE_INTEGRITY_CHECKS
  bcdedit -set TESTSIGNING ON
- reboot and choose the GRUB4DOS menu entry with the title "Win10 native VHD"
- open a command prompt as Administrator and type the following to copy the
  BCD boot store to the VHD file:
  bcdboot c:\windows /s c: /f ALL
- install SVBus driver:
  - right click on Start > choose Run > type "hdwwiz.exe" > OK > Yes > Next
  - select "Install the hardware that I manually select from a list (Advanced)"
    > Next
  - select "Storage controllers" > Next > Have Disk... > Browse... > choose
    svbus.inf on the USB drive > Open > OK > Next > Next > select "Install
    this driver software anyway" > Finish
- reboot and choose the GRUB4DOS entry with the title "Windows 10 - FILEDISK"
- we will see a svbusx64.sys driver signature error > press F8 > press F7 to
  disable driver signature enforcement
- open a command prompt as Administrator and type the following to disable
  driver signature enforcement on the new BCD store inside the VHD:
  bcdedit -set loadoptions DISABLE_INTEGRITY_CHECKS
  bcdedit -set TESTSIGNING ON
- open a command prompt as Administrator and type the following to disable
  hibernation mode:
  powercfg -h off
  Hibernation mode is not supported by SVBus and could give problems if the
  machine is shut down.  
- reboot once more and test the GRUB4DOS menu entries for FILEDISK and RAMDISK
  If both GRUB4DOS menu entries are running without any problems we can delete
  the Boot directory and the file bootmgr10 on drive D: (the real HDD/SSD). Pay
  attention that the GRUB4DOS menu entry "Windows 10 native VHD" does not work
  after that anymore and can also be deleted from "D:\menu.lst".


Install Windows 8.1 Enterprise x64 to VHD
-------------------------------------------

Things you'll need for installation before starting:
- Computer with a blank HDD or SSD
- Windows 10 x64 Boot-CD
- USB drive with the following files:
  - GRUB4DOS loader named "grldr" version 0.4.5c
  - SVBus binary driver file package
  - Windows DSE overrider version 1.2.2.1712 (dsefix.exe, download from GitHub)
    This executable is only needed on the x64 version of Windows.
  - Windows 8.1 Enterprise x64 Boot-CD ISO file named "win81.iso"

How to install the OS:
- boot Windows 10 x64 Setup from DVD > choose your language and keyboard layout
  > press Next > choose "Install now"
  You should always first choose your language before continuing with the next
  steps, because otherwise your keyboard layout does not match.
- in the dialog with the title "Windows Setup" press Shift + F10 to open a
  command prompt and type the following commands to create a new primary active
  partition on the HDD/SSD:
  - diskpart
  - list disk
  - select disk=0
    You should select the correct disk number. If you only have one HDD/SSD
    connected, which is recommended, choose disk 0.
  - create partition primary
  - active
  - format fs=NTFS quick
  - assign letter=C
  - exit
- in the open command prompt type the following commands to create a new blank
  fixed VHD file:
  - diskpart
  - create vdisk file=C:\win81.vhd maximum=15000 type=fixed
    You could choose a greater size if you want, but it is recommended that you
    do not choose a size bigger than your RAM, otherwise we can not load the VHD
    to RAM later on. The value should be 2 to 3 GB less than your installed RAM,
    otherwise the OS has no more available RAM at runtime.
  - select vdisk file=C:\win81.vhd
  - attach vdisk
  - create partition primary
  - active
  - format fs=NTFS quick
  - exit
- copy the following files from the command line or start notepad.exe and use the
  open dialog with the filter "All Files"
- copy the file grldr from the USB drive to "C:\grldr" and rename it to "C:\bootmgr"
  This will activate GRUB4DOS boot without altering the MBR.
- copy the SVBus binary driver file package from the USB drive to "C:\SVBus"
- copy dsefix.exe file from the USB drive to "C:\dsefix.exe"
- copy the file "win81.iso" from the USB drive to "C:\win81.iso"
- open notepad by typing "notepad.exe" in the command line and create a file named
  "C:\menu.lst" with the following content:
  # run Windows 8.1
  
  title Windows 8.1 - RAMDISK
  find --set-root --ignore-floppies /win81.vhd
  map --mem /win81.vhd (hd0)
  map --hook
  root (hd0,0)
  chainloader /bootmgr
  
  title Windows 8.1 - FILEDISK
  find --set-root --ignore-floppies /win81.vhd
  map /win81.vhd (hd0)
  map --hook
  root (hd0,0)
  chainloader /bootmgr
  
  # Install Windows 8.1 from ISO Image
  
  title Windows 8.1 Setup Step 1 load ISO Image
  map /win81.vhd (hd0)
  map --mem /win81.iso (0xff)
  map --hook
  chainloader (0xff)
  
  title Windows 8.1 Setup Step 2 load ISO Image
  map /win81.vhd (hd0)
  map --mem /win81.iso (0xff)
  map --hook
  root (hd0,0)
  chainloader /bootmgr
- remove the Windows 10 Setup DVD and the USB drive
- reboot and choose "Windows 8.1 Setup Step 1 load ISO Image" from GRUB4DOS
  menu
- press Enter to boot from the RAM CD ISO image
- in the dialog with the title "Windows Setup" press Shift + F10 to open a
  command prompt and type the following command to install the SVBus driver:
  - C:\dsefix.exe
  - C:\SVBus\instx64.exe
  - C:\dsefix.exe -e
  - exit
  DSEFix will deactivate driver signature enforcement in memory without changing
  the BCD store on the DVD ISO image. After that we can install the test signed
  64 bit SVBus driver without any problems. On x86 versions of Windows this
  command is not needed at all. Pay attention that you use the reenable parameter
  "-e" and not something like "/e", because dsefix only recognizes "-e". If you
  do not reenable the driver signature enforcement Windows setup will show errors
  or a BSOD. Most times we will see a CRITICAL_STRUCTURE_CORRUPTION BSOD in the
  file CI.DLL. If this error is shown simply restart the setup another time.
- choose your language and keyboard layout > press Next > choose "Install now"
- check "I accept the license terms" > Next
- choose "Custom: Install Windows only (advanced)"
- we should now see two drives, choose Drive 1 Partition 1 with a size of 14.6
  GB > Next > Windows 8.1 x64 installation is running
- after the 1st reboot choose "Windows 8.1 Setup Step 2 load ISO Image" from
  GRUB4DOS menu
- on the "Your PC needs to be repaired" screen press F8 for startup settings >
  press F7 to disable Driver Signature Enforcement
- after the 2nd reboot choose "Windows 8.1 Setup Step 2 load ISO Image" from
  GRUB4DOS menu again
- now we see the text "Preparing Automatic Repair", this is related to the
  driver signature enforcement which is active
- in the repair screen choose your keyboard layout > Troubleshoot > Advanced
  options > Command Prompt > enter the following commands:
  - diskpart
  - DISKPART> select vdisk file=C:\win81.vhd
  - DISKPART> attach vdisk
  - DISKPART> list volume
    Remember the volume drive letter of our VHD file. We will be using D: for
    the next commands.
  - DISKPART> exit
  - bcdedit /store D:\boot\bcd /set {default} loadoptions DISABLE_INTEGRITY_CHECKS
  - bcdedit /store D:\boot\bcd /set {default} TESTSIGNING ON
  - exit
  > choose Continue > the machine will reboot again
- choose "Windows 8.1 Setup Step 2 load ISO Image" from GRUB4DOS menu
- the GUI mode setup will continue and ask you about the computer and user name
- reboot once more and test the GRUB4DOS menu entries for FILEDISK and RAMDISK


Install Windows 7 Ultimate x64 to VHD
---------------------------------------

Things you'll need for installation before starting:
- Computer with a blank HDD or SSD
- Windows 10 x64 Boot-CD
- USB drive with the following files:
  - GRUB4DOS loader named "grldr" version 0.4.5c
  - SVBus binary driver file package
  - Windows 7 Ultimate x64 Boot-CD ISO file named "win7.iso"

How to install the OS:
- boot Windows 10 x64 Setup from DVD > choose your language and keyboard layout
  > press Next > choose "Install now"
  You should always first choose your language before continuing with the next
  steps, because otherwise your keyboard layout does not match.
- in the dialog with the title "Windows Setup" press Shift + F10 to open a
  command prompt and type the following commands to create a new primary active
  partition on the HDD/SSD:
  - diskpart
  - list disk
  - select disk=0
    You should select the correct disk number. If you only have one HDD/SSD
    connected, which is recommended, choose disk 0.
  - create partition primary
  - active
  - format fs=NTFS quick
  - assign letter=C
  - exit
- in the open command prompt type the following commands to create a new blank
  fixed VHD file:
  - diskpart
  - create vdisk file=C:\win7.vhd maximum=15000 type=fixed
    You could choose a greater size if you want, but it is recommended that you
    do not choose a size bigger than your RAM, otherwise we can not load the VHD
    to RAM later on. The value should be 2 to 3 GB less than your installed RAM,
    otherwise the OS has no more available RAM at runtime.
  - select vdisk file=C:\win7.vhd
  - attach vdisk
  - create partition primary
  - active
  - format fs=NTFS quick
  - exit
- copy the following files from the command line or start notepad.exe and use the
  open dialog with the filter "All Files"
- copy the file grldr from the USB drive to "C:\grldr" and rename it to "C:\bootmgr"
  This will activate GRUB4DOS boot without altering the MBR.
- copy the SVBus binary driver file package from the USB drive to "C:\SVBus"
- copy the file "win7.iso" from the USB drive to "C:\win7.iso"
- open notepad by typing "notepad.exe" in the command line and create a file named
  "C:\menu.lst" with the following content:
  # run Windows 7
  
  title Windows 7 - RAMDISK
  find --set-root --ignore-floppies /win7.vhd
  map --mem /win7.vhd (hd0)
  map --hook
  root (hd0,0)
  chainloader /bootmgr
  
  title Windows 7 - FILEDISK
  find --set-root --ignore-floppies /win7.vhd
  map /win7.vhd (hd0)
  map --hook
  root (hd0,0)
  chainloader /bootmgr
  
  # Install Windows 7 from ISO Image
  
  title Windows 7 Setup Step 1 load ISO Image
  map /win7.vhd (hd0)
  map --mem /win7.iso (0xff)
  map --hook
  chainloader (0xff)
  
  title Windows 7 Setup Step 2 load ISO Image
  map /win7.vhd (hd0)
  map --mem /win7.iso (0xff)
  map --hook
  root (hd0,0)
  chainloader /bootmgr
- remove the Windows 10 Setup DVD and the USB drive
- reboot and choose "Windows 7 Setup Step 1 load ISO Image" from GRUB4DOS
  menu
- press Enter to boot from the RAM CD ISO image
- in the dialog with the title "Install Windows" press Shift + F10 to open a
  command prompt and type the following commands to install the SVBus driver:
  - C:\SVBus\instx64.exe
  - exit
- choose your language and keyboard layout > press Next > choose "Install now"
- check "I accept the license terms" > Next > choose "Custom (advanced)"
- we should now see two drives, choose Drive 1 Partition 1 with a size of 14.6
  GB > Next > Windows 7 x64 installation is running
- after the 1st reboot choose "Windows 7 Setup Step 2 load ISO Image" from
  GRUB4DOS menu
- we see a Windows Boot Manager Info screen with the following message:
  Windows cannot verify the digital signature for this file. (svbusx64.sys)
- press Enter to continue > F8 > choose "Disable Driver Signature Enforcement"
- the GUI mode setup will continue
- after the 2nd reboot choose "Windows 7 Setup Step 2 load ISO Image" from
  GRUB4DOS menu
- press Enter to continue > F8 > choose "Disable Driver Signature Enforcement"
- the GUI mode setup will continue and ask you about the computer and user name
- in the running Windows 7 OS open a command prompt as Administrator and type
  the following to disable driver signature enforcement inside the VHD:
  bcdedit -set loadoptions DISABLE_INTEGRITY_CHECKS
  bcdedit -set TESTSIGNING ON
- you can now delete the directory "D:\SVBus"
- reboot once more and test the GRUB4DOS menu entries for FILEDISK and RAMDISK


Install Windows 2000 Professional Build 5.00.2195.6717.sp4 to VHD
-------------------------------------------------------------------

Things you'll need for installation before starting:
- Computer with a blank HDD or SSD
- Windows 10 x64 Boot-CD
- USB drive with the following files:
  - GRUB4DOS loader named "grldr" version 0.4.5c
  - Windows 2000 Professional Boot-CD ISO file named "win2000.iso"
  - floppy disk image svbus.ima

Preparing the floppy disk image file svbus.ima:
- install WinImage or any other floppy disk imaging software
- start WinImage > Menu > File > New... > leave the standard format 1.44 MB > OK
- drag and drop the content of the SVBus binary directory to the WinImage window
  > choose "Yes" to inject the files into the image > Menu > File > Save As... >
  Save as type: Image File (*.ima) > File name: svbus.ima > Save
- copy the svbus.ima file to the USB drive
- pay attention that if you need another AHCI driver for your chipset you may
  have to create a custom TXTSETUP.OEM file on the floppy disk image

How to install the OS:
- boot Windows 10 x64 Setup from DVD > choose your language and keyboard layout
  > press Next > choose "Install now"
  You should always first choose your language before continuing with the next
  steps, because otherwise your keyboard layout does not match.
- in the dialog with the title "Windows Setup" press Shift + F10 to open a
  command prompt and type the following commands to create a new primary active
  partition on the HDD/SSD:
  - diskpart
  - list disk
  - select disk=0
    You should select the correct disk number. If you only have one HDD/SSD
    connected, which is recommended, choose disk 0.
  - create partition primary
  - active
  - format fs=NTFS quick
  - assign letter=C
  - exit
- in the open command prompt type the following commands to create a new blank
  fixed VHD file:
  - diskpart
  - create vdisk file=C:\win2000.vhd maximum=2500 type=fixed
    You could choose a greater size if you want, but you may need another edition
    of Windows 2000 which does not max out at 4 GB RAM like Professional. It is
    recommended that you do not choose a size bigger than your RAM, otherwise we
    can not load the VHD to RAM later on. The value should be 512 MB to 1 GB less
    than your installed RAM, otherwise the OS has no more available RAM at runtime.
  - select vdisk file=C:\win2000.vhd
  - attach vdisk
  - create partition primary
  - active
  - format fs=NTFS quick
  - exit
- copy the file grldr from the USB drive to "C:\grldr" and rename it to "C:\bootmgr"
  This will activate GRUB4DOS boot without altering the MBR.
- copy the file "svbus.ima" from the USB drive to "C:\svbus.ima"
- copy the file "win2000.iso" from the USB drive to "C:\win2000.iso"
- open notepad by typing "notepad.exe" in the command line and create a file named
  "C:\menu.lst" with the following content:
  # run Windows 2000
  
  title Windows 2000 - RAMDISK
  find --set-root --ignore-floppies /win2000.vhd
  map --mem /win2000.vhd (hd0)
  map --hook
  root (hd0,0)
  chainloader /ntldr
  
  title Windows 2000 - FILEDISK
  find --set-root --ignore-floppies /win2000.vhd
  map /win2000.vhd (hd0)
  map --hook
  root (hd0,0)
  chainloader /ntldr
  
  # Install Windows 2000 from ISO Image
  
  title Windows 2000 Setup Step 1 load ISO Image
  map /win2000.vhd (hd0)
  map --mem /win2000.iso (0xff)
  map --mem /svbus.ima (fd0)
  map --hook
  chainloader (0xff)
  
  title Windows 2000 Setup Step 2 load ISO Image
  map /win2000.vhd (hd0)
  map --mem /win2000.iso (0xff)
  map --hook
  root (hd0,0)
  chainloader /ntldr
- remove the Windows 10 Setup DVD and the USB drive
- reboot and choose "Windows 2000 Setup Step 1 load ISO Image" from GRUB4DOS
  menu
- press Enter to boot from the RAM CD ISO image
- press F6 at the setup screen > press 'S' to specify an additional device >
  press Enter > choose "SVBus Virtual SCSI Host Adapter x86" > 2 x Enter
- pay attention if you need an additional AHCI driver for your chipset this
  should be installed here also, it may be necessary to create a custom floppy
  disk image in this case
- SVBus should be always installed as the first SCSI driver, otherwise drive
  C: will not be mapped to the GRUB4DOS mapped drive in text mode setup and
  the OS may install to drive D:
- choose Enter to set up Windows now > press F8 to accept the licensing agreement
- choose the 2499 MB partition > Enter > choose "Format the partition using
  the NTFS file system" > Enter > press 'F' > Setup will copy files now
- after the 1st reboot choose "Windows 2000 Setup Step 2 load ISO Image" from
  GRUB4DOS menu and follow the GUI mode installation steps
- during GUI mode installation you will get the warning "Digital Signature Not
  Found" two times, choose always "Yes" to continue the installation
- after installation is finished run Windows 2000 from the image file by
  choosing "Windows 2000 - FILEDISK" from GRUB4DOS menu
- reboot once more and test the GRUB4DOS menu entry named "Windows 2000 - RAMDISK"


Use TrueCrypt V7.1a full system disk encryption with GRUB4DOS
---------------------------------------------------------------

To use TrueCrypt V7.1a full system disk encryption with GRUB4DOS you have to install
SVBus version 1.1 or greater. SVBus version 1.0 can not find the GRUB4DOS signature
string inside the INT13 handler. Use the following menu.lst entries to boot the VHD
file with TrueCrypt:

title Windows 10 - RAMDISK
find --set-root --ignore-floppies /win10.vhd
map --mem /win10.vhd (hd0)
map --hook
rootnoverify (hd0,0)
chainloader (hd0)+1

title Windows 10 - FILEDISK
find --set-root --ignore-floppies /win10.vhd
map /win10.vhd (hd0)
map --hook
rootnoverify (hd0,0)
chainloader (hd0)+1


Application and Service Crashes on Windows 10 x64 Build 1909 with SVBus version 1.1
-------------------------------------------------------------------------------------

These application crashes do not occur on the x86 version of Windows 10 Build 1909.
The crashes do also not occur if we use the Microsoft VHD driver vhdmp.sys to boot
the VHD file. Our operating system uses the file "C:\Windows\system32\esent.dll"
with file version 10.0.18362.207 and the SVBus driver version 1.1.

We get numerous error scenarios on the above configuration. Some of the errors are:
1.) Some services fail to start with the following error message:
    Title : Services
    Text  : Windows could not start the "Service Name" service on
            Local Computer.
            Error 1067: The process terminated unexpectedly.

    We can simulate the error by manually starting these services. Affected services
    include the following:
    - Background Intelligent Transfer Service
    - Windows Search
    - Windows Update

2.) Security settings in gpedit.msc can not be set or cause a blue screen of death.
    To simulate this run gpedit.msc > Computer Configuration > Windows Settings >
    Security Settings > Local Policies > Audit Policy. As soon as you click on
    Audit Policy we see the BSOD CRITICAL_PROCESS_DIED. This is related to gpedit.msc
    accessing the file "C:\Windows\security\database\secedit.sdb" by using function
    calls from esent.dll.

3.) We can see the service errors logged in event viewer. For a system service the
    entry looks like this in Event Viewer > Windows Logs > System:
    The Windows Search service terminated unexpectedly. It has done this 60 time(s).
    
    We can also see the application error logged in event viewer. This is shown in
    Event Viewer > Windows Logs > Application like follows:

    Source: Windows Error Reporting
    Fault bucket , type 0
    Event Name: APPCRASH
    Response: Not available
    Cab Id: 0
    Problem signature:
    P1: SearchIndexer.exe
    P2: 7.0.18362.329
    P3: 15ed5303
    P4: ESENT.dll
    P5: 10.0.18362.207
    P6: a3266cf3
    P7: c0000005
    P8: 00000000000cc6e4
    P9: 
    P10:

4.) The application esentutl.exe fails if we use the following command on an
    administrative command line:
    "C:\Windows\System32\esentutl.exe" /g "C:\Windows\security\database\secedit.sdb"

    This command does only show the copyright notice. After that esentutl.exe exits.
    
The reason for the crashes is the file "C:\Windows\system32\esent.dll" with file
version 10.0.18362.207. It sends IOCTL_STORAGE_QUERY_PROPERTY to our driver and
uses the serial number offset of the returned STORAGE_DEVICE_DESCRIPTOR structure
without checking for 0xFFFFFFFF (-1). The older documentation of the WDK version
7600.16385.1 states the following for the structure member SerialNumberOffset:
Specifies the byte offset from the beginning of the structure to a NULL-terminated
ASCII string that contains the device's serial number. If the device has no serial
number, this member is -1.

Newer documentations state the following for the structure member SerialNumberOffset:
Specifies the byte offset from the beginning of the structure to a null-terminated
ASCII string that contains the device's serial number. If the device has no serial
number, this member is zero.

Instead of checking for -1 and 0 in esent.dll, Microsoft decided to only check for
zero. This means an older driver that was programmed with the old documentation in
mind will set this field to -1 if the device has no serial number. After this check
esent.dll adds the serial number offset to the start address of the structure
STORAGE_DEVICE_DESCRIPTOR. Because we have 0xFFFFFFFF as our serial number offset
we are now at an invalid memory address and break with a first chance exception
0xC0000005 EXCEPTION_ACCESS_VIOLATION. This causes all the above service errors,
application crashes and BSODs with CRITICAL_PROCESS_DIED.

We would recommend to Microsoft that they change esent.dll to check for a serial
number offset of 0 and -1 to make older drivers work again without any problems.
The internet is full of different error messages that are all caused by esent.dll
and never got fixed since Windows 10 x64 Build 1803. Some users experience the
problem with Intel's RST drivers and a trial version of Diskeeper 2012 Pro.

