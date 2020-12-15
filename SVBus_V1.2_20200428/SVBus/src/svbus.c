
/*
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
*/

#include "svbus.h"
#pragma warning(disable:28719) // Banned API Usage: swprintf is a Banned API as listed in dontuse.h for security purposes.


//------------------------------------------------------------------------------
// read / write physical disk
//------------------------------------------------------------------------------
NTSTATUS ReadWritePhysicalDisk(PDEVICE_OBJECT DeviceObject,PFILE_OBJECT FileObject,ULONG MajorFunction,PVOID buffer,ULONG length,PLARGE_INTEGER offset)
{
	KEVENT Event;
	PIRP Irp;
	IO_STATUS_BLOCK IoStatusBlock;
	PIO_STACK_LOCATION Stack;
	NTSTATUS Status;

	// initialize notification event object
	KeInitializeEvent(&Event,NotificationEvent,FALSE);

	// allocate and set up an IRP for a synchronously processed I/O request
	Irp = IoBuildSynchronousFsdRequest(MajorFunction,DeviceObject,buffer,length,offset,&Event,&IoStatusBlock);
	if(Irp == NULL)
	{
		return STATUS_INSUFFICIENT_RESOURCES;
	}

	// get higher level driver access to the next lower driver's I/O stack location
	Stack = IoGetNextIrpStackLocation(Irp);

	// set the flag SL_OVERRIDE_VERIFY_VOLUME
	Stack->Flags |= SL_OVERRIDE_VERIFY_VOLUME;

	// since Windows Vista direct write operations to volumes and disks are blocked, therefore we use the flag SL_FORCE_DIRECT_WRITE
	// which bypasses the check in file system and storage drivers
	if(MajorFunction == IRP_MJ_WRITE)
	{
		// set the flag SL_FORCE_DIRECT_WRITE
		Stack->Flags |= SL_FORCE_DIRECT_WRITE;
	}

	// reference file object, we take an extra reference here to prevent early unload problems
	ObReferenceObject(FileObject);

	// set the FileObject pointer in the first stack location
	Stack->FileObject = FileObject;

	// send IRP to the device object
	Status = IoCallDriver(DeviceObject,Irp);
	if(Status == STATUS_PENDING)
	{
		// wait for disk read / write to finish
		KeWaitForSingleObject(&Event,Executive,KernelMode,FALSE,NULL);
		// get returned NTSTATUS value
		Status = IoStatusBlock.Status;
	}

	// dereference file object
	ObDereferenceObject(FileObject);

	return Status;
}


//------------------------------------------------------------------------------
// open disk file
//------------------------------------------------------------------------------
NTSTATUS DiskOpenFile(IN PVOID StartContext)
{
	PDEVICE_OBJECT DeviceObject;
	PDEVICE_EXTENSION DeviceExtension;
	NTSTATUS Status;
	PWSTR SymbolicLinkList;
	PWCHAR p;
	UNICODE_STRING deviceNameUnicodeString;
	PFILE_OBJECT FileObject;
	PDEVICE_OBJECT FileDeviceObject;
	LARGE_INTEGER ByteOffset;
	PUCHAR buf;
	SIZE_T size;
	size_t len = 0;

	// get device object and device extension from start context of thread
	DeviceObject = (PDEVICE_OBJECT)StartContext;
	DeviceExtension = (PDEVICE_EXTENSION)DeviceObject->DeviceExtension;

	// get list of disk class devices
	Status = IoGetDeviceInterfaces(&GUID_DEVINTERFACE_DISK,NULL,0,&SymbolicLinkList);
	if(!NT_SUCCESS(Status))
	{
		return Status;
	}

	// allocate memory for read buffer
	// the minimum buffer size should be 2048 bytes for one CD/DVD-ROM sector
	size = 0x800;
	buf = (PUCHAR)ExAllocatePoolWithTag(PagedPool,size,SVBUS_POOL_TAG);
	if(buf == NULL)
	{
		return STATUS_INSUFFICIENT_RESOURCES;
	}

	// do this for every disk in the Unicode string list
	for(p = SymbolicLinkList; *p != UNICODE_NULL; p += len)
	{
		// do not check our own SVBus, this can BSOD with the error "System Thread Exception not handled" if we send IRP_MJ_READ in IoCallDriver of ReadWritePhysicalDisk
		/*lint -save -e585 Warning 585: The sequence (??\) is not a valid Trigraph sequence */
		if(RtlCompareMemory(p,L"\\??\\SVBus",(SIZE_T)0x12) != 0x12)
		/*lint -restore */
		{
			// initialize device name unicode string
			RtlInitUnicodeString(&deviceNameUnicodeString,p);

			// get a pointer to the top object in the named device object's stack and a pointer to the corresponding file object
			Status = IoGetDeviceObjectPointer(&deviceNameUnicodeString,FILE_ALL_ACCESS,&FileObject,&FileDeviceObject);
			if(NT_SUCCESS(Status))
			{
				// CDROM
				if(DeviceExtension->Disk.VirtualDeviceType == CDROM)
				{
					// read possible CD001 location of virtual ISO file on physical disk
					ByteOffset.QuadPart = (LONGLONG)DeviceExtension->Disk.ImageStartOffsetInBytes + 0x8000;
				}
				// HDD and FLOPPY
				else
				{
					// read possible MBR location of virtual hard disk file on physical disk
					ByteOffset.QuadPart = (LONGLONG)DeviceExtension->Disk.ImageStartOffsetInBytes;
				}

				// zero read buffer memory
				RtlZeroMemory(buf,size);

				// read / write physical disk
				Status = ReadWritePhysicalDisk(FileDeviceObject,FileObject,IRP_MJ_READ,buf,(ULONG)size,&ByteOffset);
				if(NT_SUCCESS(Status))
				{
					// CDROM
					if(DeviceExtension->Disk.VirtualDeviceType == CDROM)
					{
						// check for string "CD001"
						if(buf[1] == 'C' && buf[2] == 'D' && buf[3] == '0' && buf[4] == '0' && buf[5] == '1')
						{
							// we have found a valid CDROM ISO, save file object and file device object
							DeviceExtension->Disk.FileObject = FileObject;
							DeviceExtension->Disk.FileDeviceObject = FileDeviceObject;
							// free read buffer memory
							ExFreePoolWithTag(buf,SVBUS_POOL_TAG);
							// free list of disks
							ExFreePool(SymbolicLinkList);
							return STATUS_SUCCESS;
						}
					}
					// HDD and FLOPPY
					else if(DeviceExtension->Disk.VirtualDeviceType == HDD || DeviceExtension->Disk.VirtualDeviceType == FLOPPY)
					{
						// check for last 2 bytes of a valid MBR
						if(buf[510] == 0x55 && buf[511] == 0xAA)
						{
							// we have found a valid MBR, save file object and file device object
							DeviceExtension->Disk.FileObject = FileObject;
							DeviceExtension->Disk.FileDeviceObject = FileDeviceObject;
							// free read buffer memory
							ExFreePoolWithTag(buf,SVBUS_POOL_TAG);
							// free list of disks
							ExFreePool(SymbolicLinkList);
							return STATUS_SUCCESS;
						}
					}
				}

				// we have not found a CDROM ISO or an MBR
				// dereference the file object, this will also indirectly dereference the device object
				ObDereferenceObject(FileObject);
			}
		}

		// get Unicode string length of physical disk
		// add 2 bytes for Unicode terminating null and continue with the next physical disk in the list
		len = wcslen(p) + 1;
	}

	// free read buffer memory
	ExFreePoolWithTag(buf,SVBUS_POOL_TAG);
	// free list of disks
	ExFreePool(SymbolicLinkList);

	return STATUS_DEVICE_NOT_READY;
}


//------------------------------------------------------------------------------
// disk read / write file thread
//------------------------------------------------------------------------------
VOID DiskReadWriteThread(IN PVOID StartContext)
{
	PDEVICE_OBJECT DeviceObject;
	PDEVICE_EXTENSION DeviceExtension;
	PLIST_ENTRY Request;
	PIRP Irp;
	PIO_STACK_LOCATION Stack;
	PSCSI_REQUEST_BLOCK Srb;
	PCDB Cdb;
	ULONGLONG StartSector;
	ULONG SectorCount;
	ULONG Length;
	PVOID sysAddr;
	PVOID buffer;
	PVOID tmpBuffer;
	NTSTATUS Status;
	LARGE_INTEGER offset;

	// get device object and device extension from start context of thread
	DeviceObject = (PDEVICE_OBJECT)StartContext;
	DeviceExtension = (PDEVICE_EXTENSION)DeviceObject->DeviceExtension;

	// zero file object and file device object
	DeviceExtension->Disk.FileObject = NULL;
	DeviceExtension->Disk.FileDeviceObject = NULL;

	// set run time priority of our thread
	KeSetPriorityThread(KeGetCurrentThread(),LOW_REALTIME_PRIORITY);

	// do this until the thread is terminated
	for(;;)
	{
		// wait for the disk read / write event to be triggered
		KeWaitForSingleObject(&DeviceExtension->Disk.Event,Executive,KernelMode,FALSE,NULL);

		// check if we should terminate the disk read / write thread
		if(DeviceExtension->Disk.bTerminateThread)
		{
			// check for a valid file object
			if(DeviceExtension->Disk.FileObject != NULL)
			{
				// dereference the file object, this will also indirectly dereference the device object
				ObDereferenceObject(DeviceExtension->Disk.FileObject);
				// zero file object
				DeviceExtension->Disk.FileObject = NULL;
				// zero file device object
				DeviceExtension->Disk.FileDeviceObject = NULL;
			}

			// terminate thread
			PsTerminateSystemThread(STATUS_SUCCESS);
		}

		// remove entry from the beginning of the doubly linked list of read / write requests
		while((Request = ExInterlockedRemoveHeadList(&DeviceExtension->Disk.ListHead,&DeviceExtension->Disk.ListLock)) != NULL)
		{
			// get the IRP and stack location of the request
			Irp = CONTAINING_RECORD(Request,IRP,Tail.Overlay.ListEntry);
			Stack = IoGetCurrentIrpStackLocation(Irp);

			// get the SCSI request block and command descriptor block
			Srb = Stack->Parameters.Scsi.Srb;
			Cdb = (PCDB)Srb->Cdb;

			// set all values to status success
			Irp->IoStatus.Information = 0;
			Srb->SrbStatus = SRB_STATUS_SUCCESS;
			Srb->ScsiStatus = SCSISTAT_GOOD;
			Status = STATUS_SUCCESS;

			// check the first command descriptor block byte
			switch(Cdb->AsByte[0])
			{
				// 0x28 READ (10)
				case SCSIOP_READ:
				// 0x2A WRITE (10)
				case SCSIOP_WRITE:
				// 0x2F VERIFY (10)
				case SCSIOP_VERIFY:
				// 0x88 READ (16)
				case SCSIOP_READ16:
				// 0x8A WRITE (16)
				case SCSIOP_WRITE16:
				// 0x8F VERIFY (16)
				case SCSIOP_VERIFY16:
				{
					// zero start sector and sector count
					StartSector = 0;
					SectorCount = 0;

					// check for read / write / verify 16 command
					if(Cdb->AsByte[0] == SCSIOP_READ16 || Cdb->AsByte[0] == SCSIOP_WRITE16 || Cdb->AsByte[0] == SCSIOP_VERIFY16)
					{
						// convert start LBA and transfer length to start sector and sector count
						REVERSE_BYTES_QUAD(&StartSector,&Cdb->CDB16.LogicalBlock[0]);
						REVERSE_BYTES(&SectorCount,&Cdb->CDB16.TransferLength[0]);
					}
					// check for read / write / verify command
					else if(Cdb->AsByte[0] == SCSIOP_READ || Cdb->AsByte[0] == SCSIOP_WRITE || Cdb->AsByte[0] == SCSIOP_VERIFY)
					{
						// convert start LBA and transfer length to start sector and sector count
						StartSector = ((ULONG)Cdb->CDB10.LogicalBlockByte0 << 24) | ((ULONG)Cdb->CDB10.LogicalBlockByte1 << 16) | ((ULONG)Cdb->CDB10.LogicalBlockByte2 << 8) | Cdb->CDB10.LogicalBlockByte3;
						SectorCount = ((ULONG)Cdb->CDB10.TransferBlocksMsb << 8) | Cdb->CDB10.TransferBlocksLsb;
					}

					// check for a disk access beyond the limit of the image size
					if(StartSector + SectorCount > DeviceExtension->Disk.ImageSizeInLBAs)
					{
						// return SCSI_SENSE_ILLEGAL_REQUEST
						Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
						Srb->DataTransferLength = 0;
						Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
						Status = STATUS_INVALID_PARAMETER;
						break;
					}

					// calculate length of transfer
					Length = SectorCount * DeviceExtension->Disk.SectorSize;

					// SRB data buffer is valid and transfer length did not match the SRB data transfer length
					if(Srb->DataBuffer != NULL && Length != Srb->DataTransferLength)
					{
						// return SCSI_SENSE_ILLEGAL_REQUEST
						Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
						Srb->DataTransferLength = 0;
						Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
						Status = STATUS_INVALID_PARAMETER;
						break;
					}

					// transfer length is not a multiple of sector size
					if(Length % DeviceExtension->Disk.SectorSize != 0)
					{
						// return SCSI_SENSE_ILLEGAL_REQUEST
						Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
						Srb->DataTransferLength = 0;
						Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
						Status = STATUS_INVALID_PARAMETER;
						break;						
					}

					// return success on zero sectors to transfer or verify only command
					if(SectorCount == 0 || Cdb->AsByte[0] == SCSIOP_VERIFY16 || Cdb->AsByte[0] == SCSIOP_VERIFY)
					{
						Srb->DataTransferLength = 0;
						break;
					}

					// get nonpaged system space virtual address for the buffer
					sysAddr = MmGetSystemAddressForMdlSafe(Irp->MdlAddress,HighPagePriority);
					if(sysAddr == NULL)
					{
						// return SCSI_SENSE_ILLEGAL_REQUEST
						Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
						Srb->DataTransferLength = 0;
						Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
						Status = STATUS_INSUFFICIENT_RESOURCES;
						break;
					}

					// calculate buffer address from base virtual address and nonpaged system space virtual address
					buffer = (PVOID)(((SIZE_T)Srb->DataBuffer - (SIZE_T)MmGetMdlVirtualAddress(Irp->MdlAddress)) + (SIZE_T)sysAddr);

					// calculate start offset on the physical disk
					offset.QuadPart = (LONGLONG)(DeviceExtension->Disk.ImageStartOffsetInBytes + StartSector * DeviceExtension->Disk.SectorSize);

					// check if file object is valid
					if(DeviceExtension->Disk.FileObject == NULL)
					{
						// open disk file
						Status = DiskOpenFile(StartContext);
						if(!NT_SUCCESS(Status))
						{
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_BUSY;
							Status = STATUS_DEVICE_NOT_READY;
							break;
						}
					}

					// 0x28 READ (10) or 0x88 READ (16)
					if(Cdb->AsByte[0] == SCSIOP_READ || Cdb->AsByte[0] == SCSIOP_READ16)
					{
						// allocate memory for temporary read buffer
						// We can not use the buffer address here like in the write code below. We have to
						// use double buffering, otherwise we get a MEMORY MANAGEMENT BSOD on Windows 10.
						// Reason is the MmProbeAndLockPages call in IoBuildSynchronousFsdRequest function,
						// which probes the pages for IoReadAccess.
						tmpBuffer = ExAllocatePoolWithTag(PagedPool,(SIZE_T)Length,SVBUS_POOL_TAG);
						if(tmpBuffer == NULL)
						{
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_ERROR;
							Status = STATUS_INSUFFICIENT_RESOURCES;
							break;
						}

						// read from the physical disk
						Status = ReadWritePhysicalDisk(DeviceExtension->Disk.FileDeviceObject,DeviceExtension->Disk.FileObject,IRP_MJ_READ,tmpBuffer,Length,&offset);
						if(!NT_SUCCESS(Status))
						{
							ExFreePoolWithTag(tmpBuffer,SVBUS_POOL_TAG);
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_ERROR;
							break;
						}

						// copy data from temporary buffer to buffer
						RtlCopyMemory(buffer,tmpBuffer,(SIZE_T)Length);
						// free temporary buffer memory
						ExFreePoolWithTag(tmpBuffer,SVBUS_POOL_TAG);

						// set returned read length
						Irp->IoStatus.Information = Length;
						Srb->DataTransferLength = Length;
					}
					// 0x2A WRITE (10) or 0x8A WRITE (16)
					else if(Cdb->AsByte[0] == SCSIOP_WRITE || Cdb->AsByte[0] == SCSIOP_WRITE16)
					{
						// write to the physical disk
						Status = ReadWritePhysicalDisk(DeviceExtension->Disk.FileDeviceObject,DeviceExtension->Disk.FileObject,IRP_MJ_WRITE,buffer,Length,&offset);
						if(!NT_SUCCESS(Status))
						{
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_ERROR;
							break;
						}

						// set returned write length
						Irp->IoStatus.Information = Length;
						Srb->DataTransferLength = Length;
					}

					break;
				}
				// we should not receive any other commands as read / write / verify
				default:
				{
					Srb->DataTransferLength = 0;
					Srb->SrbStatus = SRB_STATUS_INVALID_REQUEST;
					Status = STATUS_NOT_IMPLEMENTED;
					break;
				}
			}

			// complete request
			Irp->IoStatus.Status = Status;
			if(NT_SUCCESS(Status))
			{
				// give the IRP a priority boost on STATUS_SUCCESS
				IoCompleteRequest(Irp,IO_DISK_INCREMENT);
			}
			else
			{
				IoCompleteRequest(Irp,IO_NO_INCREMENT);
			}
		}
	}
}


//------------------------------------------------------------------------------
// add child device to bus
//------------------------------------------------------------------------------
NTSTATUS BusAddChild(IN PDEVICE_OBJECT BusDeviceObject,IN ULONG i)
{
	PDEVICE_EXTENSION BusDeviceExtension;
	PMY_DRIVER_EXTENSION DriverExtension;
	DEVICE_TYPE DeviceType;
	ULONG DeviceCharacteristics;
	NTSTATUS Status;
	PDEVICE_OBJECT DeviceObject = NULL;
	PDEVICE_EXTENSION DeviceExtension;
	ULONGLONG LogicalBlockAddress;
	HANDLE ThreadHandle;
	PDEVICE_EXTENSION Walker;

	// get bus device extension
	BusDeviceExtension = (PDEVICE_EXTENSION)BusDeviceObject->DeviceExtension;

	// retrieve our previously allocated per driver context area
	/*lint -save -e611 Warning 611: Suspicious cast */
	#pragma warning(suppress:4054) // okay to type cast function pointer as data pointer for this use case
	DriverExtension = (PMY_DRIVER_EXTENSION)IoGetDriverObjectExtension(BusDeviceExtension->DriverObject,(PVOID)DriverEntry);
	/*lint -restore */
	if(DriverExtension == NULL)
	{
		// driver context area not found
		return STATUS_INSUFFICIENT_RESOURCES;
	}

	// CDROM
	// from_cdrom == 1 checks for a virtual CDROM drive
	if(DriverExtension->slot[i].from_cdrom == 1)
	{
		// set device type and characteristics to CDROM
		DeviceType = FILE_DEVICE_CD_ROM;
		DeviceCharacteristics = FILE_REMOVABLE_MEDIA | FILE_READ_ONLY_DEVICE | FILE_AUTOGENERATED_DEVICE_NAME | FILE_DEVICE_SECURE_OPEN;
	}
	// HDD and FLOPPY
	// from_cdrom == 0
	else
	{
		// FLOPPY
		if(DriverExtension->slot[i].from_drive < 0x80)
		{
			// set device type and characteristics to FLOPPY
			DeviceType = FILE_DEVICE_DISK;
			DeviceCharacteristics = FILE_REMOVABLE_MEDIA | FILE_FLOPPY_DISKETTE | FILE_AUTOGENERATED_DEVICE_NAME | FILE_DEVICE_SECURE_OPEN;
		}
		// HDD
		else
		{
			// set device type and characteristics to HDD
			DeviceType = FILE_DEVICE_DISK;
			DeviceCharacteristics = FILE_AUTOGENERATED_DEVICE_NAME | FILE_DEVICE_SECURE_OPEN;
		}
	}

	// create child disk device object
	Status = IoCreateDevice(BusDeviceExtension->DriverObject,(ULONG)sizeof(DEVICE_EXTENSION),NULL,DeviceType,DeviceCharacteristics,FALSE,&DeviceObject);
	if(!NT_SUCCESS(Status))
	{
		return Status;
	}

	// zero device extension memory
	DeviceExtension = (PDEVICE_EXTENSION)DeviceObject->DeviceExtension;
	RtlZeroMemory(DeviceExtension,sizeof(DEVICE_EXTENSION));

	// set child device extension parameters
	DeviceExtension->IsBus = FALSE;
	DeviceExtension->Self = DeviceObject;
	DeviceExtension->DriverObject = BusDeviceExtension->DriverObject;
	DeviceExtension->State = NotStarted;
	DeviceExtension->OldState = NotStarted;
	DeviceExtension->Disk.Parent = BusDeviceObject;
	DeviceExtension->Disk.Next = NULL;
	DeviceObject->Flags |= DO_DIRECT_IO;
	DeviceObject->Flags |= DO_POWER_INRUSH;

	// RAM image
	if(DriverExtension->slot[i].to_drive == 0xFF)
	{
		// set image type to RAM and copy image type string
		DeviceExtension->Disk.ImageType = RAM;
		swprintf(DeviceExtension->Disk.wszImageType,L"RAM");
	}
	// DISK image
	else
	{
		// set image type to DISK and copy image type string
		DeviceExtension->Disk.ImageType = DISK;
		swprintf(DeviceExtension->Disk.wszImageType,L"Disk");
	}

	// CDROM
	if(DeviceType == FILE_DEVICE_CD_ROM)
	{
		// set virtual device type to CDROM
		DeviceExtension->Disk.VirtualDeviceType = CDROM;

		// set virtual device type string 1
		swprintf(DeviceExtension->Disk.wszVirtualDeviceType1,L"CdRom");
		// set virtual device type string 2
		swprintf(DeviceExtension->Disk.wszVirtualDeviceType2,L"CD/DVD-ROM");
		// set compatible ID string
		swprintf(DeviceExtension->Disk.wszCompatibleId,L"GenCdRom");

		// sector size for CDROMs is 2048 bytes
		DeviceExtension->Disk.SectorSize = 2048;
		// do not subtract one sector for the VHD image footer, because we have an ISO image
		DeviceExtension->Disk.ImageSizeInLBAs = DriverExtension->slot[i].sector_count / 4;

		// PERIPHERAL DEVICE TYPE 0x05 CD/DVD device MMC-5
		DeviceExtension->Disk.InquiryData.DeviceType = READ_ONLY_DIRECT_ACCESS_DEVICE;
		// RMB (removable media bit)
		DeviceExtension->Disk.InquiryData.RemovableMedia = TRUE;
		// the device complies to SCSI-2
		DeviceExtension->Disk.InquiryData.Versions = 0x02;
		// a RESPONSE DATA FORMAT field value of two indicates that the data shall be in the format defined in the SPC-4 standard
		DeviceExtension->Disk.InquiryData.ResponseDataFormat = 0x02;
		// ADDITIONAL LENGTH (n-4)
		DeviceExtension->Disk.InquiryData.AdditionalLength = 0x1F;
		// SYNC bit should be set
		DeviceExtension->Disk.InquiryData.Synchronous = TRUE;

		// inquiry data PRODUCT IDENTIFICATION
		if(DeviceExtension->Disk.ImageType == RAM)
		{
			RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.ProductId[0],"CD/DVD-ROM RAM  ",(SIZE_T)0x10);
		}
		else if(DeviceExtension->Disk.ImageType == DISK)
		{
			RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.ProductId[0],"CD/DVD-ROM Disk ",(SIZE_T)0x10);
		}

		// CDROM TOC
		*(PUSHORT)(&DeviceExtension->Disk.CdromToc.Length[0]) = RtlUshortByteSwap(sizeof(CDROM_TOC) - 2);
		DeviceExtension->Disk.CdromToc.FirstTrack = 1;
		DeviceExtension->Disk.CdromToc.LastTrack = 1;
		// data track recorded uninterrupted and digital copy prohibited
		DeviceExtension->Disk.CdromToc.TrackData[0].Control = 4;
		// Q Sub-channel mode information not supplied
		DeviceExtension->Disk.CdromToc.TrackData[0].Adr = 0;
		// current track number
		DeviceExtension->Disk.CdromToc.TrackData[0].TrackNumber = 1;
	}
	else
	{
		// FLOPPYDISK
		// from_drive < 0x80 checks for a FLOPPYDISK drive
		if(DriverExtension->slot[i].from_drive < 0x80)
		{
			// set virtual device type to FLOPPY
			DeviceExtension->Disk.VirtualDeviceType = FLOPPY;

			// set virtual device type string 1
			swprintf(DeviceExtension->Disk.wszVirtualDeviceType1,L"SFloppy");
			// set virtual device type string 2
			swprintf(DeviceExtension->Disk.wszVirtualDeviceType2,L"Floppy Disk");
			// set compatible ID string
			swprintf(DeviceExtension->Disk.wszCompatibleId,L"GenSFloppy");

			// values taken from a Mitsumi USB floppy drive
			// PERIPHERAL DEVICE TYPE 0x00 Direct access block device (e.g., magnetic disk) SBC-3
			DeviceExtension->Disk.InquiryData.DeviceType = DIRECT_ACCESS_DEVICE;
			// RMB (removable media bit)
			DeviceExtension->Disk.InquiryData.RemovableMedia = TRUE;
			// the device does not claim conformance to any standard
			DeviceExtension->Disk.InquiryData.Versions = 0x00;
			// response data format values less than two are obsolete
			DeviceExtension->Disk.InquiryData.ResponseDataFormat = 0x01;
			// ADDITIONAL LENGTH (n-4)
			DeviceExtension->Disk.InquiryData.AdditionalLength = 0x1F;

			// inquiry data PRODUCT IDENTIFICATION
			if(DeviceExtension->Disk.ImageType == RAM)
			{
				RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.ProductId[0],"Floppy Disk RAM ",(SIZE_T)0x10);
			}
			else if(DeviceExtension->Disk.ImageType == DISK)
			{
				RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.ProductId[0],"Floppy Disk Disk",(SIZE_T)0x10);
			}

			// do not subtract one sector for the VHD image footer, because we have a floppy image
			DeviceExtension->Disk.ImageSizeInLBAs = DriverExtension->slot[i].sector_count;
		}
		// HARDDISK
		// from_drive >= 0x80 checks for a HARDDISK drive
		else
		{
			// set virtual device type to HDD
			DeviceExtension->Disk.VirtualDeviceType = HDD;

			// set virtual device type string 1
			swprintf(DeviceExtension->Disk.wszVirtualDeviceType1,L"Disk");
			// set virtual device type string 2
			swprintf(DeviceExtension->Disk.wszVirtualDeviceType2,L"Hard Disk");
			// set compatible ID string
			swprintf(DeviceExtension->Disk.wszCompatibleId,L"GenDisk");

			// VMware virtual disk drive in ESXi sets the following values
			// PERIPHERAL DEVICE TYPE 0x00 Direct access block device (e.g., magnetic disk) SBC-3
			DeviceExtension->Disk.InquiryData.DeviceType = DIRECT_ACCESS_DEVICE;
			// RMB (removable media bit)
			DeviceExtension->Disk.InquiryData.RemovableMedia = FALSE;
			// the device complies to SCSI-2
			DeviceExtension->Disk.InquiryData.Versions = 0x02;
			// a RESPONSE DATA FORMAT field value of two indicates that the data shall be in the format defined in the SPC-4 standard
			DeviceExtension->Disk.InquiryData.ResponseDataFormat = 0x02;
			// ADDITIONAL LENGTH (n-4)
			DeviceExtension->Disk.InquiryData.AdditionalLength = 0x1F;
			// A SftRe bit of one indicates that the device responds to the RESET condition with the soft RESET alternative (see 6.2.2.2).
			DeviceExtension->Disk.InquiryData.SoftReset = TRUE;
			// A command queuing (CmdQue) bit of one indicates that the device supports tagged command queuing for this logical unit.
			DeviceExtension->Disk.InquiryData.CommandQueue = TRUE;
			// A synchronous transfer (Sync) bit of one indicates that the device supports synchronous data transfer.
			DeviceExtension->Disk.InquiryData.Synchronous = TRUE;
			// A wide bus 16 (Wbus16) bit of one indicates that the device supports 16-bit wide data transfers.
			DeviceExtension->Disk.InquiryData.Wide16Bit = TRUE;
			// A wide bus 32 (Wbus32) bit of one indicates that the device supports 32-bit wide data transfers.
			DeviceExtension->Disk.InquiryData.Wide32Bit = TRUE;

			// inquiry data PRODUCT IDENTIFICATION
			if(DeviceExtension->Disk.ImageType == RAM)
			{
				RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.ProductId[0],"Hard Disk RAM   ",(SIZE_T)0x10);
			}
			else if(DeviceExtension->Disk.ImageType == DISK)
			{
				RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.ProductId[0],"Hard Disk Disk  ",(SIZE_T)0x10);
			}

			// subtract one sector for the VHD image footer, because we have a hard disk image
			DeviceExtension->Disk.ImageSizeInLBAs = DriverExtension->slot[i].sector_count - 1;
		}

		// sector size for FLOPPYs and HDDs is 512 bytes
		DeviceExtension->Disk.SectorSize = 512;
	}

	// generate product id string
	swprintf(DeviceExtension->Disk.wszProductId,L"%ws %ws",DeviceExtension->Disk.wszVirtualDeviceType2,DeviceExtension->Disk.wszImageType);

	// calculate image start offset in bytes
	// start sector is always based on 512 byte sectors of the HDD
	DeviceExtension->Disk.ImageStartOffsetInBytes = DriverExtension->slot[i].start_sector * 512;

	// READ CAPACITY data
	LogicalBlockAddress = DeviceExtension->Disk.ImageSizeInLBAs - 1;
	REVERSE_BYTES(&DeviceExtension->Disk.ReadCapacityData.BytesPerBlock,&DeviceExtension->Disk.SectorSize);
	if(LogicalBlockAddress > 0xFFFFFFFF)
	{
		DeviceExtension->Disk.ReadCapacityData.LogicalBlockAddress = 0xFFFFFFFF;
	}
	else
	{
		REVERSE_BYTES(&DeviceExtension->Disk.ReadCapacityData.LogicalBlockAddress,&LogicalBlockAddress);
	}

	// READ CAPACITY EX data
	REVERSE_BYTES_QUAD(&DeviceExtension->Disk.ReadCapacityDataEx.LogicalBlockAddress.QuadPart,&LogicalBlockAddress);
	REVERSE_BYTES(&DeviceExtension->Disk.ReadCapacityDataEx.BytesPerBlock,&DeviceExtension->Disk.SectorSize);

	// T10 VENDOR IDENTIFICATION
	RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.VendorId[0],"Schtrom ",(SIZE_T)0x08);
	// PRODUCT REVISION LEVEL
	RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.InquiryData.ProductRevisionLevel[0],"1.00",(SIZE_T)0x04);

	// set SVBus string
	swprintf(DeviceExtension->Disk.wszSVBus,L"SVBus");
	// set revision string
	swprintf(DeviceExtension->Disk.wszRevision,L"1.00");

	// for floppies we have to return the MODE PAGE FLEXIBLE DISK
	// the virtual floppy needs MODE PAGE FLEXIBLE DISK to display the correct floppy disk icon in Windows Explorer,
	// if we do not support this command we see only the removable device icon in Windows Explorer
	if(DeviceExtension->Disk.VirtualDeviceType == FLOPPY)
	{
		// MODE PAGE FLEXIBLE
		// MODE DATA LENGTH -> size of the following data not included the mode data length field
		DeviceExtension->Disk.ModePageFlexibleDisk.ModeParameterHeader.ModeDataLength = 0x23;
		// MEDIUM TYPE -> Mitsumi USB floppy drive uses medium type 0x02 (Flexible disk, double-sided; unspecified medium)
		DeviceExtension->Disk.ModePageFlexibleDisk.ModeParameterHeader.MediumType = 0x02;
		// DEVICE-SPECIFIC PARAMETER
		DeviceExtension->Disk.ModePageFlexibleDisk.ModeParameterHeader.DeviceSpecificParameter = 0x00;
		// BLOCK DESCRIPTOR LENGTH
		DeviceExtension->Disk.ModePageFlexibleDisk.ModeParameterHeader.BlockDescriptorLength = 0x00;
		// PS | Reserved | PAGE CODE (05h)
		DeviceExtension->Disk.ModePageFlexibleDisk.PageCode = 0x05;
		DeviceExtension->Disk.ModePageFlexibleDisk.Reserved1 = 0x00;
		DeviceExtension->Disk.ModePageFlexibleDisk.PageSavable = 0x00;
		// PAGE LENGTH in bytes (1Eh)
		DeviceExtension->Disk.ModePageFlexibleDisk.PageLength = 0x1E;
		// TRANSFER RATE MSB -> 01F4h 500 kbit/s transfer rate
		DeviceExtension->Disk.ModePageFlexibleDisk.TransferRateMsb = 0x01;
		// TRANSFER RATE LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.TransferRateLsb = 0xF4;
		// NUMBER OF HEADS
		DeviceExtension->Disk.ModePageFlexibleDisk.NumberOfHeads = 0x02;
		// SECTORS PER TRACK
		DeviceExtension->Disk.ModePageFlexibleDisk.SectorsPerTrack = 0x12;
		// DATA BYTES PER SECTOR MSB
		DeviceExtension->Disk.ModePageFlexibleDisk.DataBytesPerSectorMsb = 0x02;
		// DATA BYTES PER SECTOR LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.DataBytesPerSectorLsb = 0x00;
		// NUMBER OF CYLINDERS MSB
		DeviceExtension->Disk.ModePageFlexibleDisk.NumberOfCylindersMsb = 0x00;
		// NUMBER OF CYLINDERS LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.NumberOfCylindersLsb = 0x50;
		// STARTING CYLINDER-WRITE PRECOMPENSATION MSB
		DeviceExtension->Disk.ModePageFlexibleDisk.StartingCylinderWritePrecompensationMsb = 0x00;
		// STARTING CYLINDER-WRITE PRECOMPENSATION LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.StartingCylinderWritePrecompensationLsb = 0x00;
		// STARTING CYLINDER-REDUCED WRITE CURRENT MSB
		DeviceExtension->Disk.ModePageFlexibleDisk.StartingCylinderReducedWriteCurrentMsb = 0x00;
		// STARTING CYLINDER-REDUCED WRITE CURRENT LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.StartingCylinderReducedWriteCurrentLsb = 0x00;
		// DEVICE STEP RATE MSB
		DeviceExtension->Disk.ModePageFlexibleDisk.DeviceStepRateMsb = 0x00;
		// DEVICE STEP RATE LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.DeviceStepRateLsb = 0x00;
		// DEVICE STEP PULSE WIDTH
		DeviceExtension->Disk.ModePageFlexibleDisk.DeviceStepPulseWidth = 0x00;
		// HEAD SETTLE DELAY MSB
		DeviceExtension->Disk.ModePageFlexibleDisk.HeadSettleDelayMsb = 0x00;
		// HEAD SETTLE DELAY LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.HeadSettleDelayLsb = 0x00;
		// MOTOR ON DELAY -> we used some real world values from a Mitsumi USB floppy drive
		DeviceExtension->Disk.ModePageFlexibleDisk.MotorOnDelay = 0x05;
		// MOTOR OFF DELAY -> we used some real world values from a Mitsumi USB floppy drive
		DeviceExtension->Disk.ModePageFlexibleDisk.MotorOffDelay = 0x28;
		// TRDY | SSN | MO | Reserved
		DeviceExtension->Disk.ModePageFlexibleDisk.Reserved2 = 0x00;
		DeviceExtension->Disk.ModePageFlexibleDisk.MotorOn = 0x00;
		DeviceExtension->Disk.ModePageFlexibleDisk.StartSectorNumber = 0x00;
		DeviceExtension->Disk.ModePageFlexibleDisk.TrueReady = 0x00;
		// Reserved | SPC
		DeviceExtension->Disk.ModePageFlexibleDisk.StepPulsePerCylinder = 0x00;
		DeviceExtension->Disk.ModePageFlexibleDisk.Reserved = 0x00;
		// WRITE COMPENSATION
		DeviceExtension->Disk.ModePageFlexibleDisk.WriteCompensation = 0x00;
		// HEAD LOAD DELAY
		DeviceExtension->Disk.ModePageFlexibleDisk.HeadLoadDelay = 0x00;
		// HEAD UNLOAD DELAY
		DeviceExtension->Disk.ModePageFlexibleDisk.HeadUnloadDelay = 0x00;
		// PIN 34 | PIN 2
		DeviceExtension->Disk.ModePageFlexibleDisk.Pin2 = 0x00;
		DeviceExtension->Disk.ModePageFlexibleDisk.Pin34 = 0x00;
		// PIN 4 | PIN 1
		DeviceExtension->Disk.ModePageFlexibleDisk.Pin1 = 0x00;
		DeviceExtension->Disk.ModePageFlexibleDisk.Pin4 = 0x00;
		// MEDIUM ROTATION RATE MSB
		DeviceExtension->Disk.ModePageFlexibleDisk.MediumRotationRateMsb = 0x01;
		// MEDIUM ROTATION RATE LSB
		DeviceExtension->Disk.ModePageFlexibleDisk.MediumRotationRateLsb = 0x2C;
		// Reserved
		DeviceExtension->Disk.ModePageFlexibleDisk.Reserved3 = 0x00;
		// Reserved
		DeviceExtension->Disk.ModePageFlexibleDisk.Reserved4 = 0x00;
	}
	// for CDROM we return only a mode page header, no other mode pages are necessary
	else if(DeviceExtension->Disk.VirtualDeviceType == CDROM)
	{
		// Mode parameter header(6)
		// MODE DATA LENGTH field indicates the length in bytes of the following data
		DeviceExtension->Disk.ModeParameterHeader.ModeDataLength = 0x03;
		// CDROM: Optical memory medium-type codes -> 00h Default (only one medium type supported)
		DeviceExtension->Disk.ModeParameterHeader.MediumType = 0x00;
		DeviceExtension->Disk.ModeParameterHeader.DeviceSpecificParameter = 0x00;
		// BLOCK DESCRIPTOR LENGTH field contains the length in bytes of all the block descriptors
		DeviceExtension->Disk.ModeParameterHeader.BlockDescriptorLength = 0x00;
	}
	// for HDD we return the MODE PAGE CACHING
	// the virtual HDD needs MODE PAGE CACHING to display the tab Policies in the Properties of
	// the HDD in device manager
	else if(DeviceExtension->Disk.VirtualDeviceType == HDD)
	{
		// Mode parameter header(6)
		// Microsoft's vhdmp.sys virtual disk driver for VHDs sets the following values
		// MODE DATA LENGTH field indicates the length in bytes of the following data
		DeviceExtension->Disk.ModePageCaching.ModeParameterHeader.ModeDataLength = 0x0F;
		// HDD: Direct-access medium-type codes -> 00h Default medium type (currently mounted medium type)
		DeviceExtension->Disk.ModePageCaching.ModeParameterHeader.MediumType = 0x00;
		DeviceExtension->Disk.ModePageCaching.ModeParameterHeader.DeviceSpecificParameter = 0x00;
		// BLOCK DESCRIPTOR LENGTH field contains the length in bytes of all the block descriptors
		DeviceExtension->Disk.ModePageCaching.ModeParameterHeader.BlockDescriptorLength = 0x00;
		DeviceExtension->Disk.ModePageCaching.PageCode = 0x08;
		DeviceExtension->Disk.ModePageCaching.PageLength = 0x0A;
		DeviceExtension->Disk.ModePageCaching.WriteCacheEnable = 0x01;
	}

	// SENSE DATA
	RtlZeroMemory(&DeviceExtension->Disk.SenseData,sizeof(SENSE_DATA));
	// RESPONSE CODE 0x70 fixed format sense data
	DeviceExtension->Disk.SenseData.ErrorCode = 0x70;
	// SENSE KEY
	DeviceExtension->Disk.SenseData.SenseKey = SCSI_SENSE_ILLEGAL_REQUEST;
	// ADDITIONAL SENSE LENGTH (n-7)
	DeviceExtension->Disk.SenseData.AdditionalSenseLength = 0x0B;

	// DISK_GEOMETRY
	if(DeviceExtension->Disk.VirtualDeviceType == HDD)
	{
		DeviceExtension->Disk.DiskGeometry.MediaType = FixedMedia;
	}
	else if(DeviceExtension->Disk.VirtualDeviceType == CDROM || DeviceExtension->Disk.VirtualDeviceType == FLOPPY)
	{
		DeviceExtension->Disk.DiskGeometry.MediaType = RemovableMedia;
	}

	DeviceExtension->Disk.DiskGeometry.TracksPerCylinder = DriverExtension->slot[i].max_head + 1;
	DeviceExtension->Disk.DiskGeometry.SectorsPerTrack = DriverExtension->slot[i].to_sector;
	DeviceExtension->Disk.DiskGeometry.BytesPerSector = DeviceExtension->Disk.SectorSize;
	DeviceExtension->Disk.DiskGeometry.Cylinders.QuadPart = (LONGLONG)((DeviceExtension->Disk.ImageSizeInLBAs / DeviceExtension->Disk.DiskGeometry.TracksPerCylinder) / DeviceExtension->Disk.DiskGeometry.SectorsPerTrack);

	// initialize SCSI_ADDRESS structure
	DeviceExtension->Disk.ScsiAddress.Length = sizeof(SCSI_ADDRESS);
	DeviceExtension->Disk.ScsiAddress.PortNumber = 0;
	DeviceExtension->Disk.ScsiAddress.PathId = 0;
	// use the child disk's index number as SCSI target ID
	DeviceExtension->Disk.ScsiAddress.TargetId = (UCHAR)i;
	DeviceExtension->Disk.ScsiAddress.Lun = 0;

	// initialize STORAGE_ADAPTER_DESCRIPTOR structure
	DeviceExtension->Disk.StorageAdapterDescriptor.Version = sizeof(STORAGE_ADAPTER_DESCRIPTOR);
	DeviceExtension->Disk.StorageAdapterDescriptor.Size = sizeof(STORAGE_ADAPTER_DESCRIPTOR);
	// we use 4 MB as transfer length, this is the optimum value, 64K would result in slow ram disk speeds,
	// 8 MB would only outperform a few Disk Mark tests in comparison to 4 MB
	DeviceExtension->Disk.StorageAdapterDescriptor.MaximumTransferLength = 0x400000;
	// one page is 4K (4096) bytes in size
	DeviceExtension->Disk.StorageAdapterDescriptor.MaximumPhysicalPages = DeviceExtension->Disk.StorageAdapterDescriptor.MaximumTransferLength / 4096;
	// byte aligned
	DeviceExtension->Disk.StorageAdapterDescriptor.AlignmentMask = 0;
	DeviceExtension->Disk.StorageAdapterDescriptor.AdapterUsesPio = TRUE;
	DeviceExtension->Disk.StorageAdapterDescriptor.AdapterScansDown = FALSE;
	DeviceExtension->Disk.StorageAdapterDescriptor.CommandQueueing = FALSE;
	DeviceExtension->Disk.StorageAdapterDescriptor.AcceleratedTransfer = FALSE;
	DeviceExtension->Disk.StorageAdapterDescriptor.BusType = BusTypeScsi;
	DeviceExtension->Disk.StorageAdapterDescriptor.BusMajorVersion = 1;
	DeviceExtension->Disk.StorageAdapterDescriptor.BusMinorVersion = 0;

	// initialize MY_STORAGE_DEVICE_DESCRIPTOR structure
	// this is always 0x28
	DeviceExtension->Disk.StorageDeviceDescriptor.Version = sizeof(STORAGE_DEVICE_DESCRIPTOR);
	// should be 0x81 calculated above -> sizeof(STORAGE_DEVICE_DESCRIPTOR) + 0x24 + 9 + 17 + 5 + 21 + 1;
	DeviceExtension->Disk.StorageDeviceDescriptor.Size = sizeof(MY_STORAGE_DEVICE_DESCRIPTOR);
	DeviceExtension->Disk.StorageDeviceDescriptor.DeviceType = DeviceExtension->Disk.InquiryData.DeviceType;
	DeviceExtension->Disk.StorageDeviceDescriptor.DeviceTypeModifier = DeviceExtension->Disk.InquiryData.DeviceTypeModifier;
	DeviceExtension->Disk.StorageDeviceDescriptor.RemovableMedia = DeviceExtension->Disk.InquiryData.RemovableMedia;
	DeviceExtension->Disk.StorageDeviceDescriptor.CommandQueueing = DeviceExtension->Disk.InquiryData.CommandQueue;
	// STORAGE_DEVICE_DESCRIPTOR + INQUIRY_DATA (0x24)
	DeviceExtension->Disk.StorageDeviceDescriptor.VendorIdOffset = sizeof(STORAGE_DEVICE_DESCRIPTOR) + sizeof(MY_INQUIRY_DATA);
	// VendorIdOffset + VENDOR ID and null byte
	DeviceExtension->Disk.StorageDeviceDescriptor.ProductIdOffset = DeviceExtension->Disk.StorageDeviceDescriptor.VendorIdOffset + 9;
	// ProductIdOffset + PRODUCT ID and null byte
	DeviceExtension->Disk.StorageDeviceDescriptor.ProductRevisionOffset = DeviceExtension->Disk.StorageDeviceDescriptor.ProductIdOffset + 17;
	// Attention: We have a Microsoft bug in esent.dll starting with Windows 10 x64
	// Build 1803 if the serial number offset is set to 0xFFFFFFFF (-1). Details are
	// listed in the ReadMe.txt topic named "Application and Service Crashes on
	// Windows 10 x64 Build 1909 with SVBus version 1.1".
	// If the device has no serial number, this member is -1.
	//DeviceExtension->Disk.StorageDeviceDescriptor.SerialNumberOffset = 0xFFFFFFFF;
	DeviceExtension->Disk.StorageDeviceDescriptor.SerialNumberOffset = DeviceExtension->Disk.StorageDeviceDescriptor.ProductRevisionOffset + 5;
	DeviceExtension->Disk.StorageDeviceDescriptor.BusType = BusTypeScsi;
	// INQUIRY_DATA length 0x24
	DeviceExtension->Disk.StorageDeviceDescriptor.RawPropertiesLength = sizeof(MY_INQUIRY_DATA);
	// copy complete INQUIRY_DATA
	RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.StorageDeviceDescriptor.InquiryData,(PUCHAR)&DeviceExtension->Disk.InquiryData,sizeof(MY_INQUIRY_DATA));
	// copy vendor ID
	RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.StorageDeviceDescriptor.VendorId[0],(PUCHAR)&DeviceExtension->Disk.InquiryData.VendorId[0],(SIZE_T)0x08);
	// null terminate vendor ID
	DeviceExtension->Disk.StorageDeviceDescriptor.VendorId[0x08] = 0;
	// copy product ID
	RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.StorageDeviceDescriptor.ProductId[0],(PUCHAR)&DeviceExtension->Disk.InquiryData.ProductId[0],(SIZE_T)0x10);
	// null terminate product ID
	DeviceExtension->Disk.StorageDeviceDescriptor.ProductId[0x10] = 0;
	// copy product revision
	RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.StorageDeviceDescriptor.ProductRevisionLevel[0],(PUCHAR)&DeviceExtension->Disk.InquiryData.ProductRevisionLevel[0],(SIZE_T)0x04);
	// null terminate product revision
	DeviceExtension->Disk.StorageDeviceDescriptor.ProductRevisionLevel[0x04] = 0;
	// copy serial number "KaiSchtrom"
	RtlCopyMemory((PUCHAR)&DeviceExtension->Disk.StorageDeviceDescriptor.SerialNumber[0],"4B616953636874726F6D",(SIZE_T)0x14);
	// null terminate serial number
	DeviceExtension->Disk.StorageDeviceDescriptor.SerialNumber[0x14] = 0;
	// add last terminating null
	DeviceExtension->Disk.StorageDeviceDescriptor.Reserved = 0;

	// we have to handle image type disk with a read / write thread
	if(DeviceExtension->Disk.ImageType == DISK)
	{
		// initialize list head
		InitializeListHead(&DeviceExtension->Disk.ListHead);
		// initialize spin lock variable
		KeInitializeSpinLock(&DeviceExtension->Disk.ListLock);
		// initialize synchronization event object
		KeInitializeEvent(&DeviceExtension->Disk.Event,SynchronizationEvent,FALSE);
		// set thread termination to false
		DeviceExtension->Disk.bTerminateThread = FALSE;

		// create disk read / write file thread
		Status = PsCreateSystemThread(&ThreadHandle,THREAD_ALL_ACCESS,NULL,NULL,NULL,DiskReadWriteThread,DeviceObject);
		if(!NT_SUCCESS(Status))
		{
			IoDeleteDevice(DeviceObject);
			return Status;
		}

		// get pointer to object body from object table entry
		Status = ObReferenceObjectByHandle(ThreadHandle,THREAD_ALL_ACCESS,NULL,KernelMode,&DeviceExtension->Disk.ThreadObject,NULL);
		if(!NT_SUCCESS(Status))
		{
			IoDeleteDevice(DeviceObject);
			return Status;
		}

		// close disk read / write file thread handle
		ZwClose(ThreadHandle);
	}

	// insert the new child disk into the bus child list
	if(BusDeviceExtension->Bus.ChildList == NULL)
	{
		// this is the first child disk, so let the bus child list point to it
		BusDeviceExtension->Bus.ChildList = DeviceExtension;
	}
	else
	{
		// this is not the first child disk, so add it to the bus child list's end
		// get start of bus child list
		Walker = BusDeviceExtension->Bus.ChildList;
		// as long as we have another child disk following the actual list
		while(Walker->Disk.Next != NULL)
		{
			// set Walker to the next child disk
			Walker = Walker->Disk.Next;
		}

		// we get here if the next child disk pointer is zero
		// we now add our new child disk to the end of the bus child list
		Walker->Disk.Next = DeviceExtension;
	}

	// increment the number of children connected to the bus
	BusDeviceExtension->Bus.Children++;

	// device initialization finished
	DeviceObject->Flags &= ~DO_DEVICE_INITIALIZING;

	return STATUS_SUCCESS;
}


//------------------------------------------------------------------------------
// add bus device
//------------------------------------------------------------------------------
NTSTATUS BusAddDevice(IN PDRIVER_OBJECT DriverObject,IN PDEVICE_OBJECT PhysicalDeviceObject)
{
	PMY_DRIVER_EXTENSION DriverExtension;
	NTSTATUS Status;
	UNICODE_STRING DeviceName;
	UNICODE_STRING DosDeviceName;
	PDEVICE_OBJECT DeviceObject = NULL;
	PDEVICE_EXTENSION DeviceExtension;
	PHYSICAL_ADDRESS physAddr;
	PUCHAR virtAddr;
	SIZE_T mapSize;
	INTERRUPT_VECTOR intVector;
	LONG i;
	LONG k;

	// allocate a driver context area
	/*lint -save -e611 Warning 611: Suspicious cast */
	#pragma warning(suppress:4054) // okay to type cast function pointer as data pointer for this use case
	Status = IoAllocateDriverObjectExtension(DriverObject,(PVOID)DriverEntry,(ULONG)sizeof(MY_DRIVER_EXTENSION),(PVOID*)&DriverExtension);
	/*lint -restore */
	if(!NT_SUCCESS(Status))
	{
		return Status;
	}

	// set device name and DOS device name
	RtlInitUnicodeString(&DeviceName,L"\\Device\\SVBus");
	RtlInitUnicodeString(&DosDeviceName,L"\\DosDevices\\SVBus");

	// create bus device object
	Status = IoCreateDevice(DriverObject,(ULONG)sizeof(DEVICE_EXTENSION),&DeviceName,FILE_DEVICE_CONTROLLER,FILE_DEVICE_SECURE_OPEN,FALSE,&DeviceObject);
	if(!NT_SUCCESS(Status))
	{
		return Status;
	}

	// save bus device object in driver extension
	DriverExtension->BusDeviceObject = DeviceObject;

	// create symbolic link between the bus device object name and the user visible name
	Status = IoCreateSymbolicLink(&DosDeviceName,&DeviceName);
	if(!NT_SUCCESS(Status))
	{
		IoDeleteDevice(DeviceObject);
		return Status;
	}

	// zero device extension memory
	DeviceExtension = (PDEVICE_EXTENSION)DeviceObject->DeviceExtension;
	RtlZeroMemory(DeviceExtension,sizeof(DEVICE_EXTENSION));

	// set bus device extension parameters
	DeviceExtension->IsBus = TRUE;
	DeviceExtension->DriverObject = DriverObject;
	DeviceExtension->Self = DeviceObject;
	DeviceExtension->State = NotStarted;
	DeviceExtension->OldState = NotStarted;
	DeviceExtension->Bus.PhysicalDeviceObject = PhysicalDeviceObject;
	DeviceExtension->Bus.Children = 0;
	DeviceExtension->Bus.ChildList = NULL;
	DeviceObject->Flags |= DO_DIRECT_IO;
	DeviceObject->Flags |= DO_POWER_INRUSH;

	// check if the physical device object is valid
	if(PhysicalDeviceObject != NULL)
	{
		// attach device object to the highest device object in the chain
		DeviceExtension->Bus.LowerDeviceObject = IoAttachDeviceToDeviceStack(DeviceObject,PhysicalDeviceObject);
		if(DeviceExtension->Bus.LowerDeviceObject == NULL)
		{
			IoDeleteSymbolicLink(&DosDeviceName);
			IoDeleteDevice(DeviceObject);
			return STATUS_NO_SUCH_DEVICE;
		}
	}

	// device initialization finished
	DeviceObject->Flags &= ~DO_DEVICE_INITIALIZING;

	// we do two RAM mappings, because if we would map the first MB of physical memory we get the following problems:
	// - on Windows 10 x64 Build 1709 we get the bug check 0x1A MEMORY_MANAGEMENT if WinDbg is attached and the driver runs on an ESXi machine
	// - on Windows 10 x64 Build 1803 MmMapIoSpace returns NULL for the virtual address even without an attached debugger on an ESXi machine
	// map real mode RAM range 0 - 1024 bytes
	physAddr.QuadPart = 0;
	mapSize = 0x400;
	// map physical address range to nonpaged system space
	// we should map this non cached, otherwise Driver Verifier shows the following error in WinDbg: Iospace mapping overlap
	// the reason is because the OS has already mapped the same address range with another cache type
	virtAddr = (PUCHAR)MmMapIoSpace(physAddr,mapSize,MmNonCached);
	if(virtAddr == NULL)
	{
		IoDeleteSymbolicLink(&DosDeviceName);
		IoDetachDevice(DeviceExtension->Bus.LowerDeviceObject);
		IoDeleteDevice(DeviceObject);
		return STATUS_INSUFFICIENT_RESOURCES;			
	}

	// get interrupt vector for int13h
	intVector = ((INTERRUPT_VECTOR*)(VOID*)(virtAddr))[0x13];
	
	// unmap real mode RAM range 0 - 1024 bytes
	MmUnmapIoSpace(virtAddr,mapSize);

	// map real mode RAM INT13 segment for a size of interrupt vector offset + 1024 bytes
	physAddr.QuadPart = (LONGLONG)intVector.Segment << 4;
	mapSize = intVector.Offset + 0x400;
	// map physical address range to nonpaged system space
	// we should map this non cached, otherwise Driver Verifier shows the following error in WinDbg: Iospace mapping overlap
	// the reason is because the OS has already mapped the same address range with another cache type
	virtAddr = (PUCHAR)MmMapIoSpace(physAddr,mapSize,MmNonCached);
	if(virtAddr == NULL)
	{
		IoDeleteSymbolicLink(&DosDeviceName);
		IoDetachDevice(DeviceExtension->Bus.LowerDeviceObject);
		IoDeleteDevice(DeviceObject);
		return STATUS_INSUFFICIENT_RESOURCES;			
	}

	// check for the GRUB4DOS identify string "$INT13SFGRUB4DOS" at int13h offset + 0x03
	if(RtlCompareMemory(&virtAddr[intVector.Offset + 0x03],"$INT13SFGRUB4DOS",(SIZE_T)0x10) == 0x10)
	{
		// GRUB4DOS identify string "$INT13SFGRUB4DOS" found
		
		// copy all GRUB4DOS drive map slots to our driver context area slot structure
		RtlCopyMemory(&DriverExtension->slot[0],&virtAddr[0x20],sizeof(GRUB4DOS_DRIVE_MAP_SLOT) * MAXIMUM_GRUB4DOS_DRIVE_MAP_SLOTS);

		// unmap real mode RAM INT13 segment for a size of interrupt vector offset + 1024 bytes
		MmUnmapIoSpace(virtAddr,mapSize);

		return STATUS_SUCCESS;
	}

	// unmap real mode RAM INT13 segment for a size of interrupt vector offset + 1024 bytes
	MmUnmapIoSpace(virtAddr,mapSize);

	// GRUB4DOS identify string "$INT13SFGRUB4DOS" not found
	// we now try to search for the GRUB4DOS INT13 handler in the first 640 KB

	// check the first 640 KB for the GRUB4DOS identify string "$INT13SFGRUB4DOS"
	// we search in reverse order from top to down, because this is faster
	for(i = 0x9F000; i >= 0; i -= 0x1000)
	{
		// map real mode RAM address for a size of 4096 bytes
		physAddr.QuadPart = (LONGLONG)i;
		mapSize = 0x1000;
		// map physical address range to nonpaged system space
		// we should map this non cached, otherwise Driver Verifier shows the following error in WinDbg: Iospace mapping overlap
		// the reason is because the OS has already mapped the same address range with another cache type
		virtAddr = (PUCHAR)MmMapIoSpace(physAddr,mapSize,MmNonCached);
		if(virtAddr == NULL)
		{
			IoDeleteSymbolicLink(&DosDeviceName);
			IoDetachDevice(DeviceExtension->Bus.LowerDeviceObject);
			IoDeleteDevice(DeviceObject);
			return STATUS_INSUFFICIENT_RESOURCES;			
		}

		// do this for 4096 bytes - 16 bytes for the GRUB4DOS identify string "$INT13SFGRUB4DOS"
		for(k = 0; k < 0xFF0; k++)
		{
			// check for the GRUB4DOS identify string "$INT13SFGRUB4DOS"
			if(RtlCompareMemory(&virtAddr[k],"$INT13SFGRUB4DOS",(SIZE_T)0x10) == 0x10)
			{
				// GRUB4DOS identify string "$INT13SFGRUB4DOS" found
		
				// copy all GRUB4DOS drive map slots to our driver context area slot structure
				// k - 0xE3 is the start offset of our drive map table, this negative memory range is included in our memory map
				RtlCopyMemory(&DriverExtension->slot[0],&virtAddr[k - 0xE3],sizeof(GRUB4DOS_DRIVE_MAP_SLOT) * MAXIMUM_GRUB4DOS_DRIVE_MAP_SLOTS);

				// unmap real mode RAM address for a size of 4096 bytes
				MmUnmapIoSpace(virtAddr,mapSize);

				return STATUS_SUCCESS;
			}
		}

		// unmap real mode RAM address for a size of 4096 bytes
		MmUnmapIoSpace(virtAddr,mapSize);		
	}

	// GRUB4DOS identify string "$INT13SFGRUB4DOS" not found, this does not indicate an error, because GRUB4DOS is simply not installed
	return STATUS_SUCCESS;
}


//------------------------------------------------------------------------------
// unload driver
//------------------------------------------------------------------------------
VOID Unload(IN PDRIVER_OBJECT DriverObject)
{
	UNREFERENCED_PARAMETER(DriverObject);

	return;
}


//------------------------------------------------------------------------------
// disk dispatch power
//------------------------------------------------------------------------------
NTSTATUS DiskDispatchPower(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension)
{
	NTSTATUS Status;

	UNREFERENCED_PARAMETER(DeviceObject);
	UNREFERENCED_PARAMETER(DeviceExtension);

	// check minor function code
	switch(Stack->MinorFunction)
	{
		// change to system or device power state
		case IRP_MN_SET_POWER:
		// query device if system or device power state can be changed
		case IRP_MN_QUERY_POWER:
		{
			// return success, otherwise the system can not enter standby
			Status = STATUS_SUCCESS;
			break;
		}
		// awaken sleeping system or device
		case IRP_MN_WAIT_WAKE:
		// return power sequence values for device
		case IRP_MN_POWER_SEQUENCE:
		default:
		{
			Status = STATUS_NOT_SUPPORTED;
			break;
		}
	}

	// signal the power manager that we are ready to handle the next power IRP
	PoStartNextPowerIrp(Irp);
	// complete request
	Irp->IoStatus.Status = Status;
	Irp->IoStatus.Information = 0;
	IoCompleteRequest(Irp,IO_NO_INCREMENT);
	return Status;
}


//------------------------------------------------------------------------------
// I/O completion
//------------------------------------------------------------------------------
NTSTATUS IoCompletionRoutine(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PVOID Event)
{
	UNREFERENCED_PARAMETER(DeviceObject);
	UNREFERENCED_PARAMETER(Irp);

	// check if we have a valid event
	if(Event != NULL)
	{
		// set event object to signaled state
		KeSetEvent((PKEVENT)Event,0,FALSE);
	}

	return STATUS_MORE_PROCESSING_REQUIRED;
}


//------------------------------------------------------------------------------
// bus dispatch PnP
//------------------------------------------------------------------------------
NTSTATUS BusDispatchPnP(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension)
{
	KEVENT Event;
	NTSTATUS Status;
	PDEVICE_EXTENSION Walker;
	PDEVICE_EXTENSION Next;
	ULONG Count;
	PDEVICE_RELATIONS DeviceRelations;

	UNREFERENCED_PARAMETER(DeviceObject);

	// check minor function code
	switch(Stack->MinorFunction)
	{
		// device is started for the first time or the device is restarted after being stopped
		case IRP_MN_START_DEVICE:
		{
			// initialize notification event object
			KeInitializeEvent(&Event,NotificationEvent,FALSE);
			// copy IRP stack parameters from the current I/O stack location to the stack location of the next lower driver
			IoCopyCurrentIrpStackLocationToNext(Irp);
			// register an IoCompletion routine, which will be called when the next lower level driver has completed the requested operation
			IoSetCompletionRoutine(Irp,(PIO_COMPLETION_ROUTINE)IoCompletionRoutine,(PVOID)&Event,TRUE,TRUE,TRUE);
			// send IRP to the next lower driver
			Status = IoCallDriver(DeviceExtension->Bus.LowerDeviceObject,Irp);

			// check if returned status is pending
			if(Status == STATUS_PENDING)
			{
				// wait for notification event
				KeWaitForSingleObject(&Event,Executive,KernelMode,FALSE,NULL);
			}

			// if we get here the IRP has been processed by the next lower driver
			Status = Irp->IoStatus.Status;

			// on status success
			if(NT_SUCCESS(Status))
			{
				// set device state to started
				DeviceExtension->OldState = DeviceExtension->State;
				DeviceExtension->State = Started;
			}

			// complete request
			Irp->IoStatus.Status = Status;
			IoCompleteRequest(Irp,IO_NO_INCREMENT);
			return Status;
		}
		// device has been ejected or unplugged
		// device has been surprise removed by pulling it from its slot
		// the device driver is updated
		case IRP_MN_REMOVE_DEVICE:
		{
			// set device state to deleted
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = Deleted;
			Irp->IoStatus.Information = 0;
			Irp->IoStatus.Status = STATUS_SUCCESS;
			// modify the system's IO_STACK_LOCATION array pointer, so that the next lower driver receives the same IO_STACK_LOCATION structure
			IoSkipCurrentIrpStackLocation(Irp);
			// send IRP to the next lower driver
			Status = IoCallDriver(DeviceExtension->Bus.LowerDeviceObject,Irp);

			// get start of bus child list
			Walker = DeviceExtension->Bus.ChildList;
			// do this as long as the bus child list is not empty
			while(Walker != NULL)
			{
				// check if we have a disk image type and the thread object is valid
				if(Walker->Disk.ImageType == DISK && Walker->Disk.ThreadObject != NULL)
				{
					// set terminate thread to true
					Walker->Disk.bTerminateThread = TRUE;
					// set event object to signaled state
					KeSetEvent(&Walker->Disk.Event,(KPRIORITY)0,FALSE);
					// wait for disk read / write thread to finish
					KeWaitForSingleObject(Walker->Disk.ThreadObject,Executive,KernelMode,FALSE,NULL);
					// decrement reference count
					ObDereferenceObject(Walker->Disk.ThreadObject);
				}

				// get pointer to next child disk on the bus
				Next = Walker->Disk.Next;
				// delete the actual child disk from the bus
				IoDeleteDevice(Walker->Self);
				// get next child disk
				Walker = Next;
			}

			// zero bus children
			DeviceExtension->Bus.Children = 0;
			// zero bus child list
			DeviceExtension->Bus.ChildList = NULL;
			// detach from lower device object
			IoDetachDevice(DeviceExtension->Bus.LowerDeviceObject);
			// remove bus device object from the system
			IoDeleteDevice(DeviceExtension->Self);
			return Status;
		}
		// determine device relationships
		case IRP_MN_QUERY_DEVICE_RELATIONS:
		{
			// we only support bus relation requests
			if(Stack->Parameters.QueryDeviceRelations.Type != BusRelations || Irp->IoStatus.Information)
			{
				Status = Irp->IoStatus.Status;
				break;
			}

			// zero child disk count
			Count = 0;
			// set Walker to bus child list start
			Walker = DeviceExtension->Bus.ChildList;
			// do this as long as Walker is a valid pointer
			while(Walker != NULL)
			{
				// increment number of child disks
				Count++;
				// set Walker to next child disk
				Walker = Walker->Disk.Next;
			}

			// allocate memory for device relations
			DeviceRelations = (PDEVICE_RELATIONS)ExAllocatePoolWithTag(NonPagedPool,sizeof(DEVICE_RELATIONS) + (sizeof(PDEVICE_OBJECT) * Count),SVBUS_POOL_TAG);
			if(DeviceRelations == NULL)
			{
				Irp->IoStatus.Information = 0;
				Status = STATUS_INSUFFICIENT_RESOURCES;
				break;
			}

			// zero device relations memory
			RtlZeroMemory(DeviceRelations,sizeof(DEVICE_RELATIONS) + (sizeof(PDEVICE_OBJECT) * Count));

			// set device relations count to number of child disks
			DeviceRelations->Count = Count;

			// zero count
			Count = 0;
			// set Walker to bus child list start
			Walker = DeviceExtension->Bus.ChildList;
			// do this as long as Walker is a valid pointer
			while(Walker != NULL)
			{
				// set device relations object pointer to device object
				DeviceRelations->Objects[Count] = Walker->Self;
				// increment reference count
				ObReferenceObject(Walker->Self);
				// increment number of child disks
				Count++;
				// set Walker to next child disk
				Walker = Walker->Disk.Next;
			}

			// return device relations
			Irp->IoStatus.Information = (ULONG_PTR)DeviceRelations;
			Status = STATUS_SUCCESS;
			break;
		}
		// send after IRP_MN_START_DEVICE first device start and if the request was successful
		case IRP_MN_QUERY_PNP_DEVICE_STATE:
		{
			Irp->IoStatus.Information = 0;
			Status = STATUS_SUCCESS;
			break;
		}
		// query whether a device can be stopped
		case IRP_MN_QUERY_STOP_DEVICE:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = StopPending;
			Status = STATUS_SUCCESS;
			break;
		}
		// send after IRP_MN_QUERY_STOP_DEVICE to inform that the device will not be disabled
		case IRP_MN_CANCEL_STOP_DEVICE:
		{
			DeviceExtension->State = DeviceExtension->OldState;
			Status = STATUS_SUCCESS;
			break;
		}
		// send to stop a device
		case IRP_MN_STOP_DEVICE:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = Stopped;
			Status = STATUS_SUCCESS;
			break;
		}
		// device is about to be removed
		case IRP_MN_QUERY_REMOVE_DEVICE:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = RemovePending;
			Status = STATUS_SUCCESS;
			break;
		}
		// device will not be removed
		case IRP_MN_CANCEL_REMOVE_DEVICE:
		{
			DeviceExtension->State = DeviceExtension->OldState;
			Status = STATUS_SUCCESS;
			break;
		}
		// device is no longer available for I/O operations
		case IRP_MN_SURPRISE_REMOVAL:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = SurpriseRemovePending;
			Status = STATUS_SUCCESS;
			break;
		}
		// unsupported minor function code
		default:
		{
			Status = Irp->IoStatus.Status;
			break;
		}
	}

	Irp->IoStatus.Status = Status;
	// modify the system's IO_STACK_LOCATION array pointer, so that the next lower driver receives the same IO_STACK_LOCATION structure
	IoSkipCurrentIrpStackLocation(Irp);
	// send IRP to the next lower driver
	Status = IoCallDriver(DeviceExtension->Bus.LowerDeviceObject,Irp);
	return Status;
}


//------------------------------------------------------------------------------
// bus get device capabilities
//------------------------------------------------------------------------------
NTSTATUS BusGetDeviceCapabilities(IN PDEVICE_OBJECT DeviceObject,IN PDEVICE_CAPABILITIES DeviceCapabilities)
{
	KEVENT pnpEvent;
	PDEVICE_OBJECT targetObject;
	PIRP pnpIrp;
	IO_STATUS_BLOCK ioStatus;
	NTSTATUS Status;
	PIO_STACK_LOCATION irpStack;

	// zero device capabilities structure memory
	RtlZeroMemory(DeviceCapabilities,sizeof(DEVICE_CAPABILITIES));
	// initialize DEVICE_CAPABILITIES structure
	DeviceCapabilities->Size = sizeof(DEVICE_CAPABILITIES);
	DeviceCapabilities->Version = 1;
	// our bus driver does not support an address
	DeviceCapabilities->Address = 0xFFFFFFFF;
	// UINumber is unknown
	DeviceCapabilities->UINumber = 0xFFFFFFFF;

	// initialize notification event object
	KeInitializeEvent(&pnpEvent,NotificationEvent,FALSE);
	// get pointer to the highest level device object in driver stack
	targetObject = IoGetAttachedDeviceReference(DeviceObject);
	// allocate and set up IRP for synchronously processed I/O request
	pnpIrp = IoBuildSynchronousFsdRequest(IRP_MJ_PNP,targetObject,NULL,0,NULL,&pnpEvent,&ioStatus);
	if(pnpIrp == NULL)
	{
		Status = STATUS_INSUFFICIENT_RESOURCES;
	}
	else
	{
		// set status to not supported
		pnpIrp->IoStatus.Status = STATUS_NOT_SUPPORTED;
		// get higher level driver access to the next lower driver's I/O stack location
		irpStack = IoGetNextIrpStackLocation(pnpIrp);
		// zero I/O stack location memory
		RtlZeroMemory(irpStack,sizeof(IO_STACK_LOCATION));
		// set major function code
		irpStack->MajorFunction = IRP_MJ_PNP;
		// set minor function code
		irpStack->MinorFunction = IRP_MN_QUERY_CAPABILITIES;
		// set device capabilities
		irpStack->Parameters.DeviceCapabilities.Capabilities = DeviceCapabilities;
		// send IRP to the next lower driver
		Status = IoCallDriver(targetObject,pnpIrp);
		// check if returned status is pending
		if(Status == STATUS_PENDING)
		{
			// wait for notification event
			KeWaitForSingleObject(&pnpEvent,Executive,KernelMode,FALSE,NULL);
			Status = ioStatus.Status;
		}
	}

	// decrement reference count
	ObDereferenceObject(targetObject);
	return Status;
}


//------------------------------------------------------------------------------
// replace wide character
//------------------------------------------------------------------------------
VOID ReplaceWCHAR(WCHAR *src,WCHAR search,WCHAR replace)
{
	WCHAR *p;

	// do this as long as no terminating Unicode null is found
	for(p = src; *p != UNICODE_NULL; p++)
	{
		// if we found the Unicode search character
		if(*p == search)
		{
			// replace it
			*p = replace;
		}
	}
}


//------------------------------------------------------------------------------
// disk dispatch PnP
//------------------------------------------------------------------------------
NTSTATUS DiskDispatchPnP(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension)
{
	SIZE_T size;
	PWCHAR String;
	NTSTATUS Status;
	ULONG StringLength;
	PWCHAR buffer;
	PDEVICE_RELATIONS DeviceRelations;
	PPNP_BUS_INFORMATION PnPBusInformation;
	PDEVICE_CAPABILITIES DeviceCapabilities;
	DEVICE_CAPABILITIES ParentDeviceCapabilities;

	UNREFERENCED_PARAMETER(DeviceObject);

	// check minor function code
	switch(Stack->MinorFunction)
	{
		// retrieve ID
		case IRP_MN_QUERY_ID:
		{
			// allocate 1024 bytes of memory
			size = 512 * sizeof(WCHAR);
			String = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,size,SVBUS_POOL_TAG);
			if(String == NULL)
			{
				Status = STATUS_INSUFFICIENT_RESOURCES;
				break;
			}

			// zero String buffer memory
			RtlZeroMemory(String,size);

			// check query ID type
			switch(Stack->Parameters.QueryId.IdType)
			{
				// get device ID
				// shown in Device Manager > SCSI Adapter > Properties > Details > Property: Bus Relations
				case BusQueryDeviceID:
				{
					// build device ID string
					StringLength = (ULONG)swprintf(String,L"%ws\\%ws&Ven_%ws&Prod_%ws_%ws&Rev_%ws",
					DeviceExtension->Disk.wszSVBus,
					DeviceExtension->Disk.wszVirtualDeviceType1,
					DeviceExtension->Disk.wszSVBus,
					DeviceExtension->Disk.wszVirtualDeviceType2,
					DeviceExtension->Disk.wszImageType,
					DeviceExtension->Disk.wszRevision) + 1;

					// allocate exact amount of memory for device ID string
					buffer = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,StringLength * sizeof(WCHAR),SVBUS_POOL_TAG);
					if(buffer == NULL)
					{
						Irp->IoStatus.Information = 0;
						Status = STATUS_INSUFFICIENT_RESOURCES;
						break;
					}

					// zero buffer memory
					RtlZeroMemory(buffer,StringLength * sizeof(WCHAR));
					// copy String to buffer
					RtlCopyMemory(buffer,String,StringLength * sizeof(WCHAR));
					// return pointer to buffer
					Irp->IoStatus.Information = (ULONG_PTR)buffer;

					Status = STATUS_SUCCESS;
					break;
				}
				// get instance ID
				// shown in Device Manager > SCSI Adapter > Properties > Details > Property: Bus Relations (6 characters minimum)
				case BusQueryInstanceID:
				{
					// build instance ID string
					StringLength = (ULONG)swprintf(String,L"%.2X%.2X%.2X",
					DeviceExtension->Disk.ScsiAddress.PathId,
					DeviceExtension->Disk.ScsiAddress.TargetId,
					DeviceExtension->Disk.ScsiAddress.Lun) + 1;

					// allocate exact amount of memory for instance ID string
					buffer = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,StringLength * sizeof(WCHAR),SVBUS_POOL_TAG);
					if(buffer == NULL)
					{
						Irp->IoStatus.Information = 0;
						Status = STATUS_INSUFFICIENT_RESOURCES;
						break;
					}

					// zero buffer memory
					RtlZeroMemory(buffer,StringLength * sizeof(WCHAR));
					// copy String to buffer
					RtlCopyMemory(buffer,String,StringLength * sizeof(WCHAR));
					// return pointer to buffer
					Irp->IoStatus.Information = (ULONG_PTR)buffer;

					Status = STATUS_SUCCESS;
					break;
				}
				// get hardware IDs
				// shown in Device Manager > SCSI Device > Properties > Details > Property: Hardware Ids
				case BusQueryHardwareIDs:
				{
					// build 1st hardware IDs string
					StringLength = (ULONG)swprintf(String,L"%ws\\%ws%-8ws%-16ws%-4ws",
					DeviceExtension->Disk.wszSVBus,
					DeviceExtension->Disk.wszVirtualDeviceType1,
					DeviceExtension->Disk.wszSVBus,
					DeviceExtension->Disk.wszProductId,
					DeviceExtension->Disk.wszRevision) + 1;

					// replace space by underscore character
					ReplaceWCHAR(String,' ','_');

					// build 2nd hardware IDs string (compatible ID)
					/*lint -save -e592 Warning 592: Non-literal format specifier used without arguments */
					StringLength += (ULONG)swprintf(&String[StringLength],L"%ws",DeviceExtension->Disk.wszCompatibleId) + 4;
					/*lint -restore */

					// allocate exact amount of memory for hardware IDs string
					buffer = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,StringLength * sizeof(WCHAR),SVBUS_POOL_TAG);
					if(buffer == NULL)
					{
						Irp->IoStatus.Information = 0;
						Status = STATUS_INSUFFICIENT_RESOURCES;
						break;
					}

					// zero buffer memory
					RtlZeroMemory(buffer,StringLength * sizeof(WCHAR));
					// copy String to buffer
					RtlCopyMemory(buffer,String,StringLength * sizeof(WCHAR));
					// return pointer to buffer
					Irp->IoStatus.Information = (ULONG_PTR)buffer;

					Status = STATUS_SUCCESS;
					break;
				}
				// get compatible IDs
				// shown in Device Manager > SCSI Device > Properties > Details > Property: Compatible Ids
				case BusQueryCompatibleIDs:
				{
					// build compatible IDs string
					/*lint -save -e592 Warning 592: Non-literal format specifier used without arguments */
					StringLength = (ULONG)swprintf(String,L"%ws",DeviceExtension->Disk.wszCompatibleId) + 4;
					/*lint -restore */

					// allocate exact amount of memory for compatible IDs string
					buffer = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,StringLength * sizeof(WCHAR),SVBUS_POOL_TAG);
					if(buffer == NULL)
					{
						Irp->IoStatus.Information = 0;
						Status = STATUS_INSUFFICIENT_RESOURCES;
						break;
					}

					// zero buffer memory
					RtlZeroMemory(buffer,StringLength * sizeof(WCHAR));
					// copy String to buffer
					RtlCopyMemory(buffer,String,StringLength * sizeof(WCHAR));
					// return pointer to buffer
					Irp->IoStatus.Information = (ULONG_PTR)buffer;

					Status = STATUS_SUCCESS;
					break;
				}
				// unsupported query ID type
				default:
				{
					Irp->IoStatus.Information = 0;
					Status = STATUS_NOT_SUPPORTED;
					break;
				}
			}

			// free String buffer
			ExFreePoolWithTag(String,SVBUS_POOL_TAG);
			break;
		}
		// retrieve device text
		case IRP_MN_QUERY_DEVICE_TEXT:
		{
			// allocate 1024 bytes of memory
			size = 512 * sizeof(WCHAR);
			String = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,size,SVBUS_POOL_TAG);
			if(String == NULL)
			{
				Status = STATUS_INSUFFICIENT_RESOURCES;
				break;
			}

			// zero String buffer memory
			RtlZeroMemory(String,size);

			// check device text type
			switch(Stack->Parameters.QueryDeviceText.DeviceTextType)
			{
				// get text description
				// shown in Device Manager > SCSI Device > Properties > General > text at the top, right of the drive icon
				case DeviceTextDescription:
				{
					// build text description string
					StringLength = (ULONG)swprintf(String,L"%ws Virtual %ws SCSI %ws Device",
					DeviceExtension->Disk.wszSVBus,
					DeviceExtension->Disk.wszVirtualDeviceType2,
					DeviceExtension->Disk.wszImageType) + 1;

					// allocate exact amount of memory for text description string
					buffer = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,StringLength * sizeof(WCHAR),SVBUS_POOL_TAG);
					if(buffer == NULL)
					{
						Irp->IoStatus.Information = 0;
						Status = STATUS_INSUFFICIENT_RESOURCES;
						break;
					}

					// zero buffer memory
					RtlZeroMemory(buffer,StringLength * sizeof(WCHAR));
					// copy String to buffer
					RtlCopyMemory(buffer,String,StringLength * sizeof(WCHAR));
					// return pointer to buffer
					Irp->IoStatus.Information = (ULONG_PTR)buffer;

					Status = STATUS_SUCCESS;
					break;
				}
				// get text location information
				// shown in Device Manager > SCSI Device > Properties > General > Location
				case DeviceTextLocationInformation:
				{
					// build text location information string
					StringLength = (ULONG)swprintf(String,L"Bus Number %d, Target ID %d, LUN %d",
					DeviceExtension->Disk.ScsiAddress.PathId,
					DeviceExtension->Disk.ScsiAddress.TargetId,
					DeviceExtension->Disk.ScsiAddress.Lun) + 1;

					// allocate exact amount of memory for text location information string
					buffer = (PWCHAR)ExAllocatePoolWithTag(NonPagedPool,StringLength * sizeof(WCHAR),SVBUS_POOL_TAG);
					if(buffer == NULL)
					{
						Irp->IoStatus.Information = 0;
						Status = STATUS_INSUFFICIENT_RESOURCES;
						break;
					}

					// zero buffer memory
					RtlZeroMemory(buffer,StringLength * sizeof(WCHAR));
					// copy String to buffer
					RtlCopyMemory(buffer,String,StringLength * sizeof(WCHAR));
					// return pointer to buffer
					Irp->IoStatus.Information = (ULONG_PTR)buffer;

					Status = STATUS_SUCCESS;
					break;
				}
				// unsupported device text type
				default:
				{
					Irp->IoStatus.Information = 0;
					Status = STATUS_NOT_SUPPORTED;
					break;
				}
			}

			// free String buffer
			ExFreePoolWithTag(String,SVBUS_POOL_TAG);
			break;
		}
		// determine device relationships
		case IRP_MN_QUERY_DEVICE_RELATIONS:
		{
			// we only support target device relation requests
			if(Stack->Parameters.QueryDeviceRelations.Type != TargetDeviceRelation)
			{
				Status = Irp->IoStatus.Status;
				break;
			}

			// allocate memory for device relations
			DeviceRelations = (PDEVICE_RELATIONS)ExAllocatePoolWithTag(PagedPool,sizeof(DEVICE_RELATIONS) + sizeof(PDEVICE_OBJECT),SVBUS_POOL_TAG);
			if(DeviceRelations == NULL)
			{
				Status = STATUS_INSUFFICIENT_RESOURCES;
				break;
			}

			// zero device relations memory
			RtlZeroMemory(DeviceRelations,sizeof(DEVICE_RELATIONS) + sizeof(PDEVICE_OBJECT));

			// set device relations object pointer to device object
			DeviceRelations->Objects[0] = DeviceExtension->Self;
			// set device relations count to 1
			DeviceRelations->Count = 1;
			// increment reference count
			ObReferenceObject(DeviceExtension->Self);
			// return device relations
			Irp->IoStatus.Information = (ULONG_PTR)DeviceRelations;

			Status = STATUS_SUCCESS;
			break;
		}
		// get type and instance number
		case IRP_MN_QUERY_BUS_INFORMATION:
		{
			// allocate memory for PnP bus information
			PnPBusInformation = (PPNP_BUS_INFORMATION)ExAllocatePoolWithTag(PagedPool,sizeof(PNP_BUS_INFORMATION),SVBUS_POOL_TAG);
			if(PnPBusInformation == NULL)
			{
				Status = STATUS_INSUFFICIENT_RESOURCES;
				break;
			}

			// zero PnP bus information memory
			RtlZeroMemory(PnPBusInformation,sizeof(PNP_BUS_INFORMATION));

			// type of bus
			PnPBusInformation->BusTypeGuid = GUID_BUS_TYPE_INTERNAL;
			// interface type of parent bus
			PnPBusInformation->LegacyBusType = PNPBus;
			// bus number distinguishing the bus from other buses of the same type
			PnPBusInformation->BusNumber = 0;
			// return PnP bus information
			Irp->IoStatus.Information = (ULONG_PTR)PnPBusInformation;

			Status = STATUS_SUCCESS;
			break;
		}
		// get capabilities
		case IRP_MN_QUERY_CAPABILITIES:
		{
			// get device capabilities
			DeviceCapabilities = Stack->Parameters.DeviceCapabilities.Capabilities;
			// check version and size
			if(DeviceCapabilities->Version != 1 || DeviceCapabilities->Size < sizeof(DEVICE_CAPABILITIES))
			{
				Status = STATUS_UNSUCCESSFUL;
				break;
			}

			// get bus parent device capabilities
			Status = BusGetDeviceCapabilities(((PDEVICE_EXTENSION)DeviceExtension->Disk.Parent->DeviceExtension)->Bus.LowerDeviceObject,&ParentDeviceCapabilities);
			if(!NT_SUCCESS(Status))
			{
				break;
			}

			// copy parent device capabilities
			RtlCopyMemory(DeviceCapabilities->DeviceState,ParentDeviceCapabilities.DeviceState,(PowerSystemShutdown + 1) * sizeof(DEVICE_POWER_STATE));

			// set device capability values
			DeviceCapabilities->DeviceD1 = TRUE;
			DeviceCapabilities->DeviceD2 = FALSE;
			DeviceCapabilities->EjectSupported = FALSE;
			DeviceCapabilities->UniqueID = FALSE;
			DeviceCapabilities->SilentInstall = FALSE;
			DeviceCapabilities->SurpriseRemovalOK = FALSE;
			DeviceCapabilities->WakeFromD0 = FALSE;
			DeviceCapabilities->WakeFromD1 = FALSE;
			DeviceCapabilities->WakeFromD2 = FALSE;
			DeviceCapabilities->WakeFromD3 = FALSE;
			DeviceCapabilities->HardwareDisabled = FALSE;
			DeviceCapabilities->DeviceWake = PowerDeviceD1;
			DeviceCapabilities->D1Latency = 0;
			DeviceCapabilities->D2Latency = 0;
			DeviceCapabilities->D3Latency = 0;

			// set device power states
			DeviceCapabilities->DeviceState[PowerSystemWorking] = PowerDeviceD0;

			if(DeviceCapabilities->DeviceState[PowerSystemSleeping1] != PowerDeviceD0)
			{
				DeviceCapabilities->DeviceState[PowerSystemSleeping1] = PowerDeviceD1;
			}

			if(DeviceCapabilities->DeviceState[PowerSystemSleeping2] != PowerDeviceD0)
			{
				DeviceCapabilities->DeviceState[PowerSystemSleeping2] = PowerDeviceD3;
			}

			// set removable capability for CDROM and FLOPPY images
			if(DeviceExtension->Disk.VirtualDeviceType == HDD)
			{
				DeviceCapabilities->Removable = FALSE;
			}
			else if(DeviceExtension->Disk.VirtualDeviceType == CDROM || DeviceExtension->Disk.VirtualDeviceType == FLOPPY)
			{
				DeviceCapabilities->Removable = TRUE;
			}

			Status = STATUS_SUCCESS;
			break;
		}
		// we do not support special files like paging file, dump file or hibernation file
		case IRP_MN_DEVICE_USAGE_NOTIFICATION:
		{
			Status = STATUS_UNSUCCESSFUL;
			break;
		}
		// send after IRP_MN_START_DEVICE first device start and if the request was successful
		case IRP_MN_QUERY_PNP_DEVICE_STATE:
		{
			Irp->IoStatus.Information = 0;
			Status = STATUS_SUCCESS;
			break;
		}
		// device is started for the first time or the device is restarted after being stopped
		case IRP_MN_START_DEVICE:
		{
			// set device state to started
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = Started;
			Status = STATUS_SUCCESS;
			break;
		}
		// query whether a device can be stopped
		case IRP_MN_QUERY_STOP_DEVICE:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = StopPending;
			Status = STATUS_SUCCESS;
			break;
		}
		// send after IRP_MN_QUERY_STOP_DEVICE to inform that the device will not be disabled
		case IRP_MN_CANCEL_STOP_DEVICE:
		{
			DeviceExtension->State = DeviceExtension->OldState;
			Status = STATUS_SUCCESS;
			break;
		}
		// send to stop a device
		case IRP_MN_STOP_DEVICE:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = Stopped;
			Status = STATUS_SUCCESS;
			break;
		}
		// device is about to be removed
		case IRP_MN_QUERY_REMOVE_DEVICE:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = RemovePending;
			Status = STATUS_SUCCESS;
			break;
		}
		// device has been ejected or unplugged
		// device has been surprise removed by pulling it from its slot
		// the device driver is updated
		case IRP_MN_REMOVE_DEVICE:
		{
			// set device state to not started
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = NotStarted;
			Status = STATUS_SUCCESS;
			break;
		}
		// device will not be removed
		case IRP_MN_CANCEL_REMOVE_DEVICE:
		{
			DeviceExtension->State = DeviceExtension->OldState;
			Status = STATUS_SUCCESS;
			break;
		}
		// device is no longer available for I/O operations
		case IRP_MN_SURPRISE_REMOVAL:
		{
			DeviceExtension->OldState = DeviceExtension->State;
			DeviceExtension->State = SurpriseRemovePending;
			Status = STATUS_SUCCESS;
			break;
		}
		// unsupported minor function code
		default:
		{
			Status = Irp->IoStatus.Status;
			break;
		}
	}

	// complete request
	Irp->IoStatus.Status = Status;
	IoCompleteRequest(Irp,IO_NO_INCREMENT);
	return Status;
}


//------------------------------------------------------------------------------
// copy memory safely with the smaller specified buffer size
//------------------------------------------------------------------------------
FORCEINLINE ULONG MemCopy(PVOID dstBuf,ULONG dstBufLen,PVOID srcBuf,ULONG srcBufLen)
{
	ULONG Length;

	// return zero buffer length if destination or source buffer is NULL
	if(dstBuf == NULL || srcBuf == NULL)
	{
		return 0;	
	}

	// check if destination buffer length is less than source buffer length
	if(dstBufLen < srcBufLen)
	{
		// use destination buffer length
		Length = dstBufLen;
	}
	else
	{
		// use source buffer length
		Length = srcBufLen;
	}

	// copy source to destination buffer
	RtlCopyMemory(dstBuf,srcBuf,(SIZE_T)Length);

	// return copied buffer length
	return Length;
}


//------------------------------------------------------------------------------
// disk dispatch device control
//------------------------------------------------------------------------------
NTSTATUS DiskDispatchDeviceControl(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension)
{
	PSTORAGE_PROPERTY_QUERY StoragePropertyQuery;
	NTSTATUS Status;

	UNREFERENCED_PARAMETER(DeviceObject);

	// check device I/O control code
	switch(Stack->Parameters.DeviceIoControl.IoControlCode)
	{
		// get properties of storage device
		case IOCTL_STORAGE_QUERY_PROPERTY:
		{
			// get pointer to system buffer
			StoragePropertyQuery = (PSTORAGE_PROPERTY_QUERY)Irp->AssociatedIrp.SystemBuffer;
			Status = STATUS_NOT_SUPPORTED;

			// STORAGE_ADAPTER_DESCRIPTOR
			if(StoragePropertyQuery->PropertyId == StorageAdapterProperty && StoragePropertyQuery->QueryType == PropertyStandardQuery)
			{
				// return storage adapter descriptor
				Irp->IoStatus.Information = MemCopy(Irp->AssociatedIrp.SystemBuffer,Stack->Parameters.DeviceIoControl.OutputBufferLength,&DeviceExtension->Disk.StorageAdapterDescriptor,(ULONG)sizeof(STORAGE_ADAPTER_DESCRIPTOR));
				Status = STATUS_SUCCESS;
				break;
			}
			// STORAGE_DEVICE_DESCRIPTOR
			else if(StoragePropertyQuery->PropertyId == StorageDeviceProperty && StoragePropertyQuery->QueryType == PropertyStandardQuery)
			{
				// return storage device descriptor
				Irp->IoStatus.Information = MemCopy(Irp->AssociatedIrp.SystemBuffer,Stack->Parameters.DeviceIoControl.OutputBufferLength,&DeviceExtension->Disk.StorageDeviceDescriptor,(ULONG)sizeof(MY_STORAGE_DEVICE_DESCRIPTOR));
				Status = STATUS_SUCCESS;
				break;
			}

			break;
		}
		// get information about physical disk geometry 
		case IOCTL_DISK_GET_DRIVE_GEOMETRY:
		{
			// return disk geometry
			Irp->IoStatus.Information = MemCopy(Irp->AssociatedIrp.SystemBuffer,Stack->Parameters.DeviceIoControl.OutputBufferLength,&DeviceExtension->Disk.DiskGeometry,(ULONG)sizeof(DISK_GEOMETRY));
			Status = STATUS_SUCCESS;
			break;
		}
		// get address information
		case IOCTL_SCSI_GET_ADDRESS:
		{
			// return SCSI address
			Irp->IoStatus.Information = MemCopy(Irp->AssociatedIrp.SystemBuffer,Stack->Parameters.DeviceIoControl.OutputBufferLength,&DeviceExtension->Disk.ScsiAddress,(ULONG)sizeof(SCSI_ADDRESS));
			Status = STATUS_SUCCESS;
			break;
		}
		// unsupported device I/O control code
		default:
		{
			Irp->IoStatus.Information = 0;
			Status = STATUS_NOT_SUPPORTED;
			break;
		}
	}

	// complete request
	Irp->IoStatus.Status = Status;
	IoCompleteRequest(Irp,IO_NO_INCREMENT);
	return Status;
}


//------------------------------------------------------------------------------
// disk dispatch SCSI
//------------------------------------------------------------------------------
NTSTATUS DiskDispatchSCSI(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension)
{
	PSCSI_REQUEST_BLOCK Srb;
	PCDB Cdb;
	NTSTATUS Status;
	ULONGLONG StartSector;
	ULONG SectorCount;
	ULONG Length;
	PHYSICAL_ADDRESS physAddr;
	PVOID virtAddr;
	PVOID sysAddr;
	PVOID buffer;

	// get the SCSI request block and command descriptor block
	Srb = Stack->Parameters.Scsi.Srb;
	Cdb = (PCDB)Srb->Cdb;

	// set all values to status success
	Irp->IoStatus.Information = 0;
	Srb->SrbStatus = SRB_STATUS_SUCCESS;
	Srb->ScsiStatus = SCSISTAT_GOOD;
	Status = STATUS_SUCCESS;

	// check SRB function
	switch(Srb->Function)
	{
		// SCSI device I/O request
		case SRB_FUNCTION_EXECUTE_SCSI:
		{
			// check the first command descriptor block byte
			switch(Cdb->AsByte[0])
			{
				// 0x00 TEST UNIT READY
				case SCSIOP_TEST_UNIT_READY:
				{
					break;
				}
				// 0x04 FORMAT UNIT
				case SCSIOP_FORMAT_UNIT:
				{
					break;
				}
				// 0x12 INQUIRY
				case SCSIOP_INQUIRY:
				{
					// we only transfer 0x24 bytes of data, because we have no more inquiry data fields filled
					Srb->DataTransferLength = MemCopy(Srb->DataBuffer,Srb->DataTransferLength,&DeviceExtension->Disk.InquiryData,0x24);
					Irp->IoStatus.Information = Srb->DataTransferLength;
					break;
				}
				// 0x1A MODE SENSE (6)
				case SCSIOP_MODE_SENSE:
				{
					// the virtual floppy needs MODE PAGE FLEXIBLE DISK to display the correct floppy disk icon in Windows Explorer 
					if(DeviceExtension->Disk.VirtualDeviceType == FLOPPY)
					{
						// 0x3F (Return all subpage 00h mode pages in page_0 format) or 0x05 MODE PAGE FLEXIBLE DISK (used by floppy)
						if(Cdb->MODE_SENSE.PageCode == MODE_SENSE_RETURN_ALL || Cdb->MODE_SENSE.PageCode == MODE_PAGE_FLEXIBILE)
						{
							// we only have to return the MODE PAGE FLEXIBLE DISK for 0x3F, because we do not support any other mode pages
							Srb->DataTransferLength = MemCopy(Srb->DataBuffer,Srb->DataTransferLength,&DeviceExtension->Disk.ModePageFlexibleDisk,(ULONG)sizeof(MODE_PAGE_FLEXIBLE_DISK));
							Irp->IoStatus.Information = Srb->DataTransferLength;
							break;
						}
					}
					// return mode parameter header for CDROM
					else if(DeviceExtension->Disk.VirtualDeviceType == CDROM)
					{
						// 0x3F (Return all subpage 00h mode pages in page_0 format)
						if(Cdb->MODE_SENSE.PageCode == MODE_SENSE_RETURN_ALL)
						{
							// we only have to return the mode parameter header for 0x3F, because we do not support any mode pages
							Srb->DataTransferLength = MemCopy(Srb->DataBuffer,Srb->DataTransferLength,&DeviceExtension->Disk.ModeParameterHeader,(ULONG)sizeof(MODE_PARAMETER_HEADER));
							Irp->IoStatus.Information = Srb->DataTransferLength;
							break;
						}
					}
					// for HDD we return the MODE PAGE CACHING
					// the virtual HDD needs MODE PAGE CACHING to display the tab Policies in the Properties of
					// the HDD in device manager
					else if(DeviceExtension->Disk.VirtualDeviceType == HDD)
					{
						// 0x3F (Return all subpage 00h mode pages in page_0 format) or 0x08 MODE PAGE CACHING
						if(Cdb->MODE_SENSE.PageCode == MODE_SENSE_RETURN_ALL || Cdb->MODE_SENSE.PageCode == MODE_PAGE_CACHING)
						{
							// we only have to return the MODE PAGE CACHING for 0x3F, because we do not support any other mode pages
							Srb->DataTransferLength = MemCopy(Srb->DataBuffer,Srb->DataTransferLength,&DeviceExtension->Disk.ModePageCaching,(ULONG)sizeof(MY_MODE_PAGE_CACHING));
							Irp->IoStatus.Information = Srb->DataTransferLength;
							break;
						}					
					}

					// return SCSI_SENSE_ILLEGAL_REQUEST
					Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
					Srb->DataTransferLength = 0;
					Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
					Status = STATUS_NOT_IMPLEMENTED;
					break;
				}
				// 0x1B START STOP UNIT
				case SCSIOP_START_STOP_UNIT:
				{
					break;
				}
				// 0x1E PREVENT ALLOW MEDIUM REMOVAL
				case SCSIOP_MEDIUM_REMOVAL:
				{
					break;
				}
				// 0x25 READ CAPACITY (10)
				case SCSIOP_READ_CAPACITY:
				{
					// return read capacity data
					Srb->DataTransferLength = MemCopy(Srb->DataBuffer,Srb->DataTransferLength,&DeviceExtension->Disk.ReadCapacityData,(ULONG)sizeof(READ_CAPACITY_DATA));
					Irp->IoStatus.Information = Srb->DataTransferLength;
					break;
				}
				// 0x28 READ (10)
				case SCSIOP_READ:
				// 0x2A WRITE (10)
				case SCSIOP_WRITE:
				// 0x2F VERIFY (10)
				case SCSIOP_VERIFY:
				// 0x88 READ (16)
				case SCSIOP_READ16:
				// 0x8A WRITE (16)
				case SCSIOP_WRITE16:
				// 0x8F VERIFY (16)
				case SCSIOP_VERIFY16:
				{
					// we can handle image type RAM directly without a read / write thread
					if(DeviceExtension->Disk.ImageType == RAM)
					{
						// zero start sector and sector count
						StartSector = 0;
						SectorCount = 0;

						// check for read / write / verify 16 command
						if(Cdb->AsByte[0] == SCSIOP_READ16 || Cdb->AsByte[0] == SCSIOP_WRITE16 || Cdb->AsByte[0] == SCSIOP_VERIFY16)
						{
							// convert start LBA and transfer length to start sector and sector count
							REVERSE_BYTES_QUAD(&StartSector,&Cdb->CDB16.LogicalBlock[0]);
							REVERSE_BYTES(&SectorCount,&Cdb->CDB16.TransferLength[0]);
						}
						// check for read / write / verify command
						else if(Cdb->AsByte[0] == SCSIOP_READ || Cdb->AsByte[0] == SCSIOP_WRITE || Cdb->AsByte[0] == SCSIOP_VERIFY)
						{
							// convert start LBA and transfer length to start sector and sector count
							StartSector = ((ULONG)Cdb->CDB10.LogicalBlockByte0 << 24) | ((ULONG)Cdb->CDB10.LogicalBlockByte1 << 16) | ((ULONG)Cdb->CDB10.LogicalBlockByte2 << 8) | Cdb->CDB10.LogicalBlockByte3;
							SectorCount = ((ULONG)Cdb->CDB10.TransferBlocksMsb << 8) | Cdb->CDB10.TransferBlocksLsb;
						}

						// check for a disk access beyond the limit of the image size
						if(StartSector + SectorCount > DeviceExtension->Disk.ImageSizeInLBAs)
						{
							// return SCSI_SENSE_ILLEGAL_REQUEST
							Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
							Status = STATUS_INVALID_PARAMETER;
							break;
						}

						// calculate length of transfer
						Length = SectorCount * DeviceExtension->Disk.SectorSize;

						// SRB data buffer is valid and transfer length did not match the SRB data transfer length
						if(Srb->DataBuffer != NULL && Length != Srb->DataTransferLength)
						{
							// return SCSI_SENSE_ILLEGAL_REQUEST
							Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
							Status = STATUS_INVALID_PARAMETER;
							break;
						}

						// transfer length is not a multiple of sector size
						if(Length % DeviceExtension->Disk.SectorSize != 0)
						{
							// return SCSI_SENSE_ILLEGAL_REQUEST
							Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
							Status = STATUS_INVALID_PARAMETER;
							break;						
						}

						// return success on zero sectors to transfer or verify only command
						if(SectorCount == 0 || Cdb->AsByte[0] == SCSIOP_VERIFY16 || Cdb->AsByte[0] == SCSIOP_VERIFY)
						{
							Srb->DataTransferLength = 0;
							break;
						}

						// get nonpaged system space virtual address for the buffer
						sysAddr = MmGetSystemAddressForMdlSafe(Irp->MdlAddress,HighPagePriority);
						if(sysAddr == NULL)
						{
							// return SCSI_SENSE_ILLEGAL_REQUEST
							Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
							Status = STATUS_INSUFFICIENT_RESOURCES;
							break;
						}

						// calculate buffer address from base virtual address and nonpaged system space virtual address
						buffer = (PVOID)(((SIZE_T)Srb->DataBuffer - (SIZE_T)MmGetMdlVirtualAddress(Irp->MdlAddress)) + (SIZE_T)sysAddr);

						// map physical address range to nonpaged system space
						physAddr.QuadPart = (LONGLONG)(DeviceExtension->Disk.ImageStartOffsetInBytes + StartSector * DeviceExtension->Disk.SectorSize);
						// if we use MmNonCached we have a huge performance drop here in RAM read/write speeds
						virtAddr = MmMapIoSpace(physAddr,(SIZE_T)Length,MmCached);
						if(virtAddr == NULL)
						{
							// return SCSI_SENSE_ILLEGAL_REQUEST
							Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
							Srb->DataTransferLength = 0;
							Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
							Status = STATUS_INSUFFICIENT_RESOURCES;
							break;
						}

						// 0x28 READ (10) or 0x88 READ (16)
						if(Cdb->AsByte[0] == SCSIOP_READ || Cdb->AsByte[0] == SCSIOP_READ16)
						{
							// read from RAM
							RtlCopyMemory(buffer,virtAddr,(SIZE_T)Length);
							Srb->DataTransferLength = Length;
							Irp->IoStatus.Information = Length;
						}
						// 0x2A WRITE (10) or 0x8A WRITE (16)
						else if(Cdb->AsByte[0] == SCSIOP_WRITE || Cdb->AsByte[0] == SCSIOP_WRITE16)
						{
							// write to RAM
							RtlCopyMemory(virtAddr,buffer,(SIZE_T)Length);
							Srb->DataTransferLength = Length;
							Irp->IoStatus.Information = Length;
						}

						// unmap physical address range 
						MmUnmapIoSpace(virtAddr,(SIZE_T)Length);
					}
					// we have to handle image type disk with a read / write thread
					else if(DeviceExtension->Disk.ImageType == DISK)
					{
						// further processing is required
						IoMarkIrpPending(Irp);
						// insert read / write request at the end of the doubly linked list
						ExInterlockedInsertTailList(&DeviceExtension->Disk.ListHead,&Irp->Tail.Overlay.ListEntry,&DeviceExtension->Disk.ListLock);
						// set event object to signaled state
						KeSetEvent(&DeviceExtension->Disk.Event,(KPRIORITY)0,FALSE);
						return STATUS_PENDING;
					}

					break;
				}
				// 0x35 SYNCHRONIZE CACHE (10)
				case SCSIOP_SYNCHRONIZE_CACHE:
				{
					break;
				}
				// 0x3B WRITE BUFFER
				case SCSIOP_WRITE_DATA_BUFF:
				{
					break;
				}
				// 0x43 READ TOC (table of contents)
				case SCSIOP_READ_TOC:
				{
					// return table of contents
					Srb->DataTransferLength = MemCopy(Srb->DataBuffer,Srb->DataTransferLength,&DeviceExtension->Disk.CdromToc,(ULONG)sizeof(CDROM_TOC));
					Irp->IoStatus.Information = Srb->DataTransferLength;
					break;
				}
				// 0x91 SYNCHRONIZE CACHE (16)
				case SCSIOP_SYNCHRONIZE_CACHE16:
				{
					break;
				}
				// 0x9E READ CAPACITY (16)
				case SCSIOP_READ_CAPACITY16:
				{
					// return read capacity data ex
					Srb->DataTransferLength = MemCopy(Srb->DataBuffer,Srb->DataTransferLength,&DeviceExtension->Disk.ReadCapacityDataEx,(ULONG)sizeof(READ_CAPACITY_DATA_EX));
					Irp->IoStatus.Information = Srb->DataTransferLength;
					break;
				}
				// unsupported SCSI command
				default:
				{
					// return SCSI_SENSE_ILLEGAL_REQUEST
					Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
					Srb->DataTransferLength = 0;
					Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
					Status = STATUS_NOT_IMPLEMENTED;
					break;
				}
			}

			break;
		}
		// device I/O control request
		case SRB_FUNCTION_IO_CONTROL:
		{
			// return SCSI_SENSE_ILLEGAL_REQUEST
			Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
			Srb->DataTransferLength = 0;
			Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
			Status = STATUS_NOT_IMPLEMENTED;
			break;
		}
		// claim device
		case SRB_FUNCTION_CLAIM_DEVICE:
		{
			ObReferenceObject(DeviceObject);
			Srb->DataBuffer = DeviceObject;
			break;
		}
		// release device
		case SRB_FUNCTION_RELEASE_DEVICE:
		{
			ObDereferenceObject(DeviceObject);
			break;
		}
		// complete transferring data to disk
		case SRB_FUNCTION_SHUTDOWN:
		// transfer cached data to disk
		case SRB_FUNCTION_FLUSH:
		{
			break;
		}
		// unsupported SRB function
		default:
		{
			// return SCSI_SENSE_ILLEGAL_REQUEST
			Srb->SenseInfoBufferLength = (UCHAR)MemCopy(Srb->SenseInfoBuffer,Srb->SenseInfoBufferLength,&DeviceExtension->Disk.SenseData,(ULONG)sizeof(SENSE_DATA));
			Srb->DataTransferLength = 0;
			Srb->SrbStatus = SRB_STATUS_AUTOSENSE_VALID | SRB_STATUS_ERROR;
			Status = STATUS_NOT_IMPLEMENTED;
			break;
		}
	}

	// complete request
	Irp->IoStatus.Status = Status;
	IoCompleteRequest(Irp,IO_NO_INCREMENT);
	return Status;
}


//------------------------------------------------------------------------------
// dispatch
//------------------------------------------------------------------------------
NTSTATUS Dispatch(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp)
{
	PIO_STACK_LOCATION Stack;
	PDEVICE_EXTENSION DeviceExtension;
	NTSTATUS Status;

	// get stack location
	Stack = IoGetCurrentIrpStackLocation(Irp);
	// get device extension
	DeviceExtension = (PDEVICE_EXTENSION)DeviceObject->DeviceExtension;

	// check deleted state
	if(DeviceExtension->State == Deleted)
	{
		// check major function code
		if(Stack->MajorFunction == IRP_MJ_POWER)
		{
			// signal the power manager that we are ready to handle the next power IRP
			PoStartNextPowerIrp(Irp);
		}

		// complete request
		Status = STATUS_NO_SUCH_DEVICE;
		Irp->IoStatus.Status = Status;
		Irp->IoStatus.Information = 0;
		IoCompleteRequest(Irp,IO_NO_INCREMENT);

		return Status;
	}

	// check major function code
	switch(Stack->MajorFunction)
	{
		// power IRP request received
		case IRP_MJ_POWER:
		{
			// bus device
			if(DeviceExtension->IsBus)
			{
				// signal the power manager that we are ready to handle the next power IRP
				PoStartNextPowerIrp(Irp);
				// modify the system's IO_STACK_LOCATION array pointer, so that the next lower driver receives the same IO_STACK_LOCATION structure
				IoSkipCurrentIrpStackLocation(Irp);
				// pass power IRP to next lower driver in device stack
				Status = PoCallDriver(DeviceExtension->Bus.LowerDeviceObject,Irp);
			}
			// disk device
			else
			{
				// call disk dispatch power
				Status = DiskDispatchPower(DeviceObject,Irp,Stack,DeviceExtension);
			}

			break;
		}
		// PnP IRP request received
		case IRP_MJ_PNP:
		{
			// bus device
			if(DeviceExtension->IsBus)
			{
				// call bus dispatch PnP
				Status = BusDispatchPnP(DeviceObject,Irp,Stack,DeviceExtension);
			}
			// disk device
			else
			{
				// call disk dispatch PnP
				Status = DiskDispatchPnP(DeviceObject,Irp,Stack,DeviceExtension);
			}

			break;
		}
		// system control IRP request received
		case IRP_MJ_SYSTEM_CONTROL:
		{
			// bus device
			if(DeviceExtension->IsBus)
			{
				// modify the system's IO_STACK_LOCATION array pointer, so that the next lower driver receives the same IO_STACK_LOCATION structure
				IoSkipCurrentIrpStackLocation(Irp);
				// send IRP to the next lower driver
				Status = IoCallDriver(DeviceExtension->Bus.LowerDeviceObject,Irp);
			}
			// disk device
			else
			{
				// complete request
				Status = Irp->IoStatus.Status;
				IoCompleteRequest(Irp,IO_NO_INCREMENT);
			}

			break;
		}
		// device control IRP request received
		case IRP_MJ_DEVICE_CONTROL:
		{
			// bus device
			if(DeviceExtension->IsBus)
			{
				// complete request
				Status = STATUS_INVALID_DEVICE_REQUEST;
				Irp->IoStatus.Status = Status;
				Irp->IoStatus.Information = 0;
				IoCompleteRequest(Irp,IO_NO_INCREMENT);
			}
			// disk device
			else
			{
				// call disk dispatch device control
				Status = DiskDispatchDeviceControl(DeviceObject,Irp,Stack,DeviceExtension);
			}

			break;
		}
		// create IRP request received
		case IRP_MJ_CREATE:
		// close IRP request received
		case IRP_MJ_CLOSE:
		{
			// complete request
			Status = STATUS_SUCCESS;
			Irp->IoStatus.Status = Status;
			Irp->IoStatus.Information = 0;
			IoCompleteRequest(Irp,IO_NO_INCREMENT);
			break;
		}
		// SCSI IRP request received
		case IRP_MJ_SCSI:
		{
			// bus device
			if(DeviceExtension->IsBus)
			{
				// complete request
				Status = STATUS_NOT_SUPPORTED;
				Irp->IoStatus.Status = Status;
				Irp->IoStatus.Information = 0;
				IoCompleteRequest(Irp,IO_NO_INCREMENT);
			}
			// disk device
			else
			{
				// call disk dispatch SCSI
				Status = DiskDispatchSCSI(DeviceObject,Irp,Stack,DeviceExtension);
			}

			break;
		}
		// unsupported major function code
		default:
		{
			// complete request
			Status = STATUS_NOT_SUPPORTED;
			Irp->IoStatus.Status = Status;
			Irp->IoStatus.Information = 0;
			IoCompleteRequest(Irp,IO_NO_INCREMENT);
			break;
		}
	}

	return Status;
}


//------------------------------------------------------------------------------
// check if system setup is in progress
//------------------------------------------------------------------------------
NTSTATUS IsSystemSetupInProgress(BOOLEAN *bSystemSetupInProgress)
{
	UNICODE_STRING RegistrySystemSetup;
	OBJECT_ATTRIBUTES objectAttributes;
	NTSTATUS Status;
	HANDLE hKey;
	SIZE_T Length;
	PKEY_VALUE_FULL_INFORMATION keyValueInformation;
	UNICODE_STRING ValueName;
	ULONG resultLength;
	ULONG ValueData;

	// set system setup in progress to false
	*bSystemSetupInProgress = FALSE;

	// initialize system setup registry key
	RtlInitUnicodeString(&RegistrySystemSetup,L"\\Registry\\Machine\\System\\Setup");

	// open system setup registry key
	InitializeObjectAttributes(&objectAttributes,&RegistrySystemSetup,(OBJ_KERNEL_HANDLE | OBJ_CASE_INSENSITIVE),NULL,NULL);
	Status = ZwOpenKey(&hKey,KEY_READ,&objectAttributes);
	if(!NT_SUCCESS(Status))
	{
		// set system setup in progress to true if no registry key is found,
		// because on Windows 2000 this key is not present in text mode setup
		if(Status == STATUS_OBJECT_NAME_NOT_FOUND)
		{
			*bSystemSetupInProgress = TRUE;
			// return success
			return STATUS_SUCCESS;
		}

		return Status;
	}

	// allocate memory for key value information
	Length = 256;
	keyValueInformation = (PKEY_VALUE_FULL_INFORMATION)ExAllocatePoolWithTag(NonPagedPool,Length,SVBUS_POOL_TAG);
	if(keyValueInformation == NULL)
	{
		ZwClose(hKey);
		return STATUS_INSUFFICIENT_RESOURCES;
	}

	// zero key value information memory
	RtlZeroMemory(keyValueInformation,Length);

	// initialize registry value name
	RtlInitUnicodeString(&ValueName,L"SystemSetupInProgress");

	// query registry value
	Status = ZwQueryValueKey(hKey,&ValueName,KeyValueFullInformation,keyValueInformation,(ULONG)Length,&resultLength);
	if((!NT_SUCCESS(Status)) || (!keyValueInformation->DataLength))
	{
		// value is not present
		ZwClose(hKey);
		// free key value information memory
		ExFreePoolWithTag(keyValueInformation,SVBUS_POOL_TAG);

		// set system setup in progress to true if no registry value is found,
		// because on Windows Server 2003 this value is not present in text mode setup
		if(Status == STATUS_OBJECT_NAME_NOT_FOUND)
		{
			*bSystemSetupInProgress = TRUE;
			// return success
			return STATUS_SUCCESS;
		}

		return Status;
	}

	// close registry key handle
	ZwClose(hKey);

	// get registry value data
	ValueData = *(PULONG)((PUCHAR)keyValueInformation + keyValueInformation->DataOffset);
	if(ValueData > 0)
	{
		// system setup is in progress
		*bSystemSetupInProgress = TRUE;
	}
	else
	{
		// system setup is not in progress
		*bSystemSetupInProgress = FALSE;
	}

	// free key value information memory
	ExFreePoolWithTag(keyValueInformation,SVBUS_POOL_TAG);

	return STATUS_SUCCESS;
}


//------------------------------------------------------------------------------
// boot driver reinitialization routine
// DriverEntry and BusAddDevice are called before the reinitialization routine
//------------------------------------------------------------------------------
VOID Reinitialize(IN PDRIVER_OBJECT DriverObject,IN PVOID Context,IN ULONG Count)
{
	PMY_DRIVER_EXTENSION DriverExtension;
	PDEVICE_OBJECT BusDeviceObject;
	PDEVICE_EXTENSION BusDeviceExtension;
	ULONG i;
	NTSTATUS Status;

	UNREFERENCED_PARAMETER(Context);
	UNREFERENCED_PARAMETER(Count);

	// retrieve our previously allocated per driver context area
	/*lint -save -e611 Warning 611: Suspicious cast */
	#pragma warning(suppress:4054) // okay to type cast function pointer as data pointer for this use case
	DriverExtension = (PMY_DRIVER_EXTENSION)IoGetDriverObjectExtension(DriverObject,(PVOID)DriverEntry);
	/*lint -restore */
	if(DriverExtension == NULL)
	{
		// driver context area not found
		return;
	}

	// get bus device object
	BusDeviceObject = DriverExtension->BusDeviceObject;
	// get bus device extension
	BusDeviceExtension = (PDEVICE_EXTENSION)BusDeviceObject->DeviceExtension;

	// count the number of drives we have in the GRUB4DOS drive map
	for(i = 0; i < MAXIMUM_GRUB4DOS_DRIVE_MAP_SLOTS; i++)
	{
		// if the sector count is zero we stop with device counting
		if(DriverExtension->slot[i].sector_count == 0)
		{
			// end of device slot list found
			break;
		}

		// add child device to bus
		Status = BusAddChild(BusDeviceObject,i);
		if(NT_SUCCESS(Status))
		{
			// check if we have a valid physical device object
			if(BusDeviceExtension->Bus.PhysicalDeviceObject != NULL)
			{
				// notify the PnP manager that the relations for a device have changed
				IoInvalidateDeviceRelations(BusDeviceExtension->Bus.PhysicalDeviceObject,BusRelations);
			}
		}
	}

	return;
}


//------------------------------------------------------------------------------
// driver entry
//------------------------------------------------------------------------------
NTSTATUS DriverEntry(IN PDRIVER_OBJECT DriverObject,IN PUNICODE_STRING RegistryPath)
{
	NTSTATUS Status;
	BOOLEAN bSystemSetupInProgress;
	PDEVICE_OBJECT PhysicalDeviceObject = NULL;

	UNREFERENCED_PARAMETER(RegistryPath);

	// set up driver specific entry points
	DriverObject->DriverExtension->AddDevice           = BusAddDevice;
	DriverObject->MajorFunction[IRP_MJ_PNP]            = Dispatch;
	DriverObject->MajorFunction[IRP_MJ_POWER]          = Dispatch;
	DriverObject->MajorFunction[IRP_MJ_CREATE]         = Dispatch;
	DriverObject->MajorFunction[IRP_MJ_CLOSE]          = Dispatch;
	DriverObject->MajorFunction[IRP_MJ_SYSTEM_CONTROL] = Dispatch;
	DriverObject->MajorFunction[IRP_MJ_DEVICE_CONTROL] = Dispatch;
	DriverObject->MajorFunction[IRP_MJ_SCSI]           = Dispatch;
	DriverObject->DriverUnload                         = Unload;

	// check if system setup is in progress
	Status = IsSystemSetupInProgress(&bSystemSetupInProgress);
	if(!NT_SUCCESS(Status))
	{
		return Status;
	}

	// if system setup is in progress we are in legacy mode and have to report the device to the PnP manager
	if(bSystemSetupInProgress == TRUE)
	{
		// report non-PnP device to the PnP manager
		/*lint -save -e418 Warning 418: Passing null pointer to function */
		Status = IoReportDetectedDevice(DriverObject,InterfaceTypeUndefined,0xFFFFFFFF,0xFFFFFFFF,NULL,NULL,FALSE,&PhysicalDeviceObject);
		/*lint -restore */
		if(!NT_SUCCESS(Status) || PhysicalDeviceObject == NULL)
		{
			return Status;
		}

		// add bus device
		Status = BusAddDevice(DriverObject,PhysicalDeviceObject);
		if(!NT_SUCCESS(Status))
		{
			return Status;
		}

		// call boot driver reinitialization routine
		Reinitialize(DriverObject,NULL,1);
	}
	else
	{
		// register boot driver reinitialization routine
		IoRegisterBootDriverReinitialization(DriverObject,Reinitialize,NULL);
	}

	return STATUS_SUCCESS;
}

