dsfok #4b

Copyright (c)2005 Dariusz Stanislawek
freezip@bigfoot.com



DS File Ops Kit
---------------


1) dsfo

dsfo can save a block of data of any size from any location within a file.

Also:

- backup any disk partition, including "live" and "hidden"
- backup entire disk, including "live"
- create an ISO CD-ROM or DVD-ROM image
- create a floppy disk image
- check MD5 signature of a partial or complete data object
- fast sector-level transfer

Usage: dsfo source offset size destination

Note: null size is interpreted as max possible output
      negative size is calculated on current file size
      negative offset is calculated from end of file
      use "$" as destination to check MD5 signature only

Example: dsfo c:\tmp\my.avi -50000 0 test.bin
         dsfo \\.\d: 0 512 c:\0\partition-sectors.dat
         dsfo \\.\PHYSICALDRIVE0 0 0 \\srv\shr\tmp\first.dsk
         dsfo \\.\a: 0 0 "c:\tmp\floppy disk image.img"
         dsfo \\.\e: 0 0 d:\CDROM_or_DVD_image.iso

To backup a "hidden" partition (no assigned letter), first run vlm to find its
unique volume name, then copy and paste it to dsfo, eg:
dsfo \\.\Volume{ac837e69-551d-11d9-9a3c-806d6172696f} 0 0 c:\tmp\my.dat

Check MD5 signature only: dsfo \\.\g: 0 2048 $

The offset argument has to be "0" with non-file objects.




2) dsfi

dsfi can overwrite a block of data of any size at any location within a file.

Also:

- restore disk partitions (no resizing)
- restore entire disk (no resizing)
- restore a floppy disk image
- join two files
- fast sector-level transfer

Usage: dsfi destination offset size source

Note: null size is interpreted as max possible input
      negative size is calculated on current file size
      negative offset is calculated from end of file
      use "e" as offset to indicate end of file

Example: dsfi c:\tmp\my.avi -50000 0 test.bin
         dsfi \\.\d: 0 512 c:\0\partition-sectors.dat
         dsfi \\.\PHYSICALDRIVE0 0 0 \\srv\shr\tmp\first.dsk
         dsfi \\.\a: 0 0 "c:\tmp\floppy disk image.img"

To join two files type: dsfi file1 e 0 file2

The offset argument has to be "0" with non-file objects.




3) fsz

fsz can be used to create a file or truncate/extend an existing one.
No file size limits (on NTFS).

Usage: fsz file size (in bytes, no limits - be careful)
Example: fsz data.fil 15773




4) rsz

rsz can be used to truncate or extend a file.
No file size limits (on NTFS).

Usage: rsz file resize (in +/- bytes, no limits - be careful)
Example: rsz data.fil -3773




5) ESD

ESD is a file encryption program derived from DSE. Unlike DSE, it overwrites
encrypted or decrypted files. ESD is not directly compatible with DSE because
the initialization vector is attached to the end of encrypted files.

Usage: esd keyfile e|d file

WARNING: files are overwritten without verification!
Create a random-content key file: esd keyfile
Create a key file from a password: esd keyfile p
Key file size is 32 bytes.
Encryption example: esd a:\my.key e d:\x\data.zip
Decryption example: esd my.key d data.enc

To convert an encrypted DSE file1 to ESD file2, do:
dsfo file1 16 0 file2
dsfi file2 e 16 file1




6) vlm

vlm scans the volumes of a computer and reports detailed info.

Found volumes: (sample output)

\\.\Volume{ac837e60-551d-11d9-9a3c-806d6172696f}
Label: (none), File System: FAT32  4995/2000 MB
Symbolic Link: \Device\HarddiskVolume1




7) msk

msk is a file scrambler. It uses the XOR stream conversion to mask a target
file with the contents of another one. If the keyfile's contents is random,
as large as the target and never reused, this operation results in a truly
unbreakable encryption, called One-Time Pad.

Usage: msk target offset size mask mask_offset

Note: null size is interpreted as max possible
      negative size is calculated on current file size
      negative offset is calculated from end of file
      mask's size has to be at least equal to masked target

Example: msk c:\tmp\my.vol 0 512 a:\data.key 1000




8) flip

flip will do a simple bitwise reversion operation on any file.

Usage: flip target
Example: flip c:\tmp\my.zip




9) xdl

xdl is a secure file deleter and partition or disk eraser. It overwrites
targets with random bytes. Everything on a partition or disk, including
file system and boot sectors, is destroyed.

Special features:
- erase file name (random, eg. "LTp30vBTIt049NIkt.3Tz")
- erase file time/date (random 1995 - 2005)
- nullify file size
- erase file cluster slack (xdl will report up to 64kB more erased data)
- bypass file system's caching and buffering for top performance

Usage: xdl target
Warning, target will be irreversibly erased.
Example: xdl c:\tmp\my.zip

erase "D" partition: xdl \\.\d:
erase second hard disk: xdl \\.\PHYSICALDRIVE1
erase floppy disk: xdl \\.\a:

To erase a "hidden" partition (no assigned letter), first run vlm to find its
unique volume name, then copy and paste it to xdl, eg:
xdl \\.\Volume{ac837e69-551d-11d9-9a3c-806d6172696f}

xdl deletes files after one round of overwriting of their contents, but
disks and partitions can be erased as many times as you wish. One round
of overwriting may not be enough if you use a low density disk and are
concerned with magnetic microscopy recovery.

Files can be drag-and-dropped on xdl.exe or its shortcut.

Warning again, there is no undelete or unformat option after running xdl,
no prompt nor confirmation dialog. It is possible to erase a "live" disk
or partition and make it inoperable.




10) EDS

EDS is a file encryption program derived from ESD. It overwrites encrypted
or decrypted files, but does not change their size. The initialization vector
has to be managed manually. EDS encryption method and keys are fully
compatible with DSE and ESD.

Usage: eds keyfile e|d file init

WARNING: files are overwritten without verification!
The init parameter can contain up to 16 characters.
Create a random-content key file: eds keyfile
Create a key file from a password: eds keyfile p
Key file size is 32 bytes.
Encryption example: eds a:\my.key e d:\x\data.zip 20050218
Decryption example: eds my.key d data.enc abc5

Initialization vector does not have to be secret, but it must be UNIQUE
for every encryption with the same key. You can reuse it only to decrypt
the same file.




INFO

A command-line session on Win NT/2k/XP can be conveniently available on a
drive or folder right-click if the included "DOS Prompt Here NT.inf" file
is installed. Right-click on it and select "Install".

Some of the CLI utilities or their functions may not work on Windows 9x/Me.

The old GUI versions work with files up to 4GB.




CHANGE LOG

#4b
xdl v1.02, faster PRNG, processing timer

#4a
xdl v1.01, new feature: erase file time/date




WEBSITE

http://www.ozemail.com.au/~nulifetv/freezip/freeware/

Backup:
http://www.ploty.com/freezip/freeware/
http://edxor.tripod.com/fw.htm
http://www.geocities.com/edxor/fw.htm
http://freezip.cjb.net/freeware/




FREEWARE SOFTWARE

Free for private or business use. Free for distribution and publication,
but in unmodified package. It can be freely bundled with any product or
application. Individual permissions are not required and will not be given.




DISCLAIMER
=========================================================================
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=========================================================================
