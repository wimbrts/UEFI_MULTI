From a1ive post: http://bbs.wuyou.net/forum.php?mod=redirect&goto=findpost&ptid=422652&pid=4195636

Add load command to load EFI driver. (Same function as GRUB2's efiload command and EFI Shell's load command)
Download: BOOTX64.zip (144.17 KB, download times: 54)
usage:
           load [-n] /path/to/driver.efi
Example:
           load /boot/ntfs_x64.efi
           Load NTFS driver, and then enter EFI Shell or refind to read files on NTFS.

           load -n /boot/CrScreenshotDxe.efi
           Load the screenshot driver, after loading, you can press Left Ctrl + Left Alt + F12 to take a screenshot. The picture format is png and saved in the root directory of the first FAT partition found.

           load /boot/EfiGuardDxe.efi
           Load the driver that cracks the Windows driver signature verification. (May not support newer Windows versions, such as 20H1)

NOTE from alacran: IMHO I prefer to use /EFI/grub folder (where menu.lst resides):

Example:

load /EFI/grub/ntfs_x64.efi

ntfs_x64.efi (NTFS driver): From refind-cd-0.11.4.zip: https://sourceforge.net/projects/refind/files/0.11.4/
CrscreenshotDxe.efi (to make screenshots): https://github.com/LongSoft/CrScreenshotDxe
EfiGuardDxe.efi [to disable PatchGuard and Driver Signature Enforcement (DSE)]: https://github.com/Mattiwatti/EfiGuard
unifont.hex.gz (Colection of fonts): Taken from Easy to Boot (E2B) by steve6375