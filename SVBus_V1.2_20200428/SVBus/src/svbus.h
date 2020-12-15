
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

#ifndef _SVBUS_
#define _SVBUS_

#include <ntddk.h>
#include <ntddscsi.h>
// DISK_GEOMETRY
#include <ntdddisk.h>
// GUID_DEVINTERFACE_DISK
// GUID_BUS_TYPE_INTERNAL
#include <initguid.h>
// CDROM_TOC
#include <ntddcdrm.h>
#include <scsi.h>
// GUID_BUS_TYPE_INTERNAL
#include <wdmguid.h>
// swprintf
#include <stdio.h>

#pragma warning(push)
#pragma warning(disable:4201) // nonstandard extension used : nameless struct/union
#pragma warning(disable:4214) // nonstandard extension used : bit field types other than int

#pragma pack(push,_svbus_)

// this structure is used for floppy images, without this structure the floppy is not
// recognized correctly and will display a removable drive symbol instead of a floppy
// symbol in Windows Explorer
#pragma pack(push,mode_page_flexible_disk,1)
typedef struct _MODE_PAGE_FLEXIBLE_DISK
{
	MODE_PARAMETER_HEADER ModeParameterHeader;
	UCHAR PageCode : 6;
	UCHAR Reserved1 : 1;
	UCHAR PageSavable : 1;
	UCHAR PageLength;
	UCHAR TransferRateMsb;
	UCHAR TransferRateLsb;
	UCHAR NumberOfHeads;
	UCHAR SectorsPerTrack;
	UCHAR DataBytesPerSectorMsb;
	UCHAR DataBytesPerSectorLsb;
	UCHAR NumberOfCylindersMsb;
	UCHAR NumberOfCylindersLsb;
	UCHAR StartingCylinderWritePrecompensationMsb;
	UCHAR StartingCylinderWritePrecompensationLsb;
	UCHAR StartingCylinderReducedWriteCurrentMsb;
	UCHAR StartingCylinderReducedWriteCurrentLsb;
	UCHAR DeviceStepRateMsb;
	UCHAR DeviceStepRateLsb;
	UCHAR DeviceStepPulseWidth;
	UCHAR HeadSettleDelayMsb;
	UCHAR HeadSettleDelayLsb;
	UCHAR MotorOnDelay;
	UCHAR MotorOffDelay;
	UCHAR Reserved2 : 5;
	UCHAR MotorOn : 1;
	UCHAR StartSectorNumber : 1;
	UCHAR TrueReady : 1;
	UCHAR StepPulsePerCylinder : 4;
	UCHAR Reserved : 4;
	UCHAR WriteCompensation;
	UCHAR HeadLoadDelay;
	UCHAR HeadUnloadDelay;
	UCHAR Pin2 : 4;
	UCHAR Pin34 : 4;
	UCHAR Pin1 : 4;
	UCHAR Pin4 : 4;
	UCHAR MediumRotationRateMsb;
	UCHAR MediumRotationRateLsb;
	UCHAR Reserved3;
	UCHAR Reserved4;
}MODE_PAGE_FLEXIBLE_DISK,*PMODE_PAGE_FLEXIBLE_DISK;
#pragma pack(pop,mode_page_flexible_disk)

// for HDD we return the MODE PAGE CACHING
// the virtual HDD needs MODE PAGE CACHING to display the tab Policies in the Properties of
// the HDD in device manager
/*lint -esym(768,_MY_MODE_PAGE_CACHING::Reserved) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::PageSavable) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::ReadDisableCache) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::MultiplicationFactor) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::Reserved2) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::WriteRetensionPriority) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::ReadRetensionPriority) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::DisablePrefetchTransfer) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::MinimumPrefetch) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::MaximumPrefetch) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_MODE_PAGE_CACHING::MaximumPrefetchCeiling) Info 768: global struct member not referenced */
#pragma pack(push,my_mode_page_caching,1)
typedef struct _MY_MODE_PAGE_CACHING
{
	MODE_PARAMETER_HEADER ModeParameterHeader;
	UCHAR PageCode : 6;
	UCHAR Reserved : 1;
	UCHAR PageSavable : 1;
	UCHAR PageLength;
	UCHAR ReadDisableCache : 1;
	UCHAR MultiplicationFactor : 1;
	UCHAR WriteCacheEnable : 1;
	UCHAR Reserved2 : 5;
	UCHAR WriteRetensionPriority : 4;
	UCHAR ReadRetensionPriority : 4;
	UCHAR DisablePrefetchTransfer[2];
	UCHAR MinimumPrefetch[2];
	UCHAR MaximumPrefetch[2];
	UCHAR MaximumPrefetchCeiling[2];
}MY_MODE_PAGE_CACHING,*PMY_MODE_PAGE_CACHING;
#pragma pack(pop,my_mode_page_caching)

// custom inquiry data structure without vendor specific and reserved data
/*lint -esym(768,_MY_INQUIRY_DATA::DeviceTypeQualifier) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::HiSupport) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::NormACA) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::ReservedBit) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::AERC) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::Reserved) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::Reserved2) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::LinkedCommands) Info 768: global struct member not referenced */
/*lint -esym(768,_MY_INQUIRY_DATA::RelativeAddressing) Info 768: global struct member not referenced */
#pragma pack(push,my_inquiry_data,1)
typedef struct _MY_INQUIRY_DATA
{
	UCHAR DeviceType : 5;
	UCHAR DeviceTypeQualifier : 3;
	UCHAR DeviceTypeModifier : 7;
	UCHAR RemovableMedia : 1;
	UCHAR Versions;
	UCHAR ResponseDataFormat : 4;
	UCHAR HiSupport : 1;
	UCHAR NormACA : 1;
	UCHAR ReservedBit : 1;
	UCHAR AERC : 1;
	UCHAR AdditionalLength;
	UCHAR Reserved[2];
	UCHAR SoftReset : 1;
	UCHAR CommandQueue : 1;
	UCHAR Reserved2 : 1;
	UCHAR LinkedCommands : 1;
	UCHAR Synchronous : 1;
	UCHAR Wide16Bit : 1;
	UCHAR Wide32Bit : 1;
	UCHAR RelativeAddressing : 1;
	UCHAR VendorId[8];
	UCHAR ProductId[16];
	UCHAR ProductRevisionLevel[4];
}MY_INQUIRY_DATA,*PMY_INQUIRY_DATA;
#pragma pack(pop,my_inquiry_data)

// custom storage device descriptor structure with embedded and zero terminated strings for
// vendor ID, product ID and product revision level
/*lint -esym(768,_MY_STORAGE_DEVICE_DESCRIPTOR::RawDeviceProperties) Info 768: global struct member not referenced */
#pragma pack(push,my_storage_device_descriptor,1)
typedef struct _MY_STORAGE_DEVICE_DESCRIPTOR
{
	ULONG Version;
	ULONG Size;
	UCHAR DeviceType;
	UCHAR DeviceTypeModifier;
	BOOLEAN RemovableMedia;
	BOOLEAN CommandQueueing;
	ULONG VendorIdOffset;
	ULONG ProductIdOffset;
	ULONG ProductRevisionOffset;
	ULONG SerialNumberOffset;
	STORAGE_BUS_TYPE BusType;
	ULONG RawPropertiesLength;
	UCHAR RawDeviceProperties[4];
	MY_INQUIRY_DATA InquiryData;
	UCHAR VendorId[9];
	UCHAR ProductId[17];
	UCHAR ProductRevisionLevel[5];
	UCHAR SerialNumber[21];
	UCHAR Reserved;
}MY_STORAGE_DEVICE_DESCRIPTOR,*PMY_STORAGE_DEVICE_DESCRIPTOR;
#pragma pack(pop,my_storage_device_descriptor)

// enum for PNP device state
typedef enum
{
	NotStarted,
	Started,
	StopPending,
	Stopped,
	RemovePending,
	SurpriseRemovePending,
	Deleted
}STATE,*PSTATE;

// enum for virtual device type
typedef enum
{
    HDD,
    CDROM,
    FLOPPY
}VIRTUAL_DEVICE_TYPE;

// enum for image type
typedef enum
{
    RAM,
    DISK
}IMAGE_TYPE;

// custom device extension structure
typedef struct _DEVICE_EXTENSION
{
	BOOLEAN IsBus;
	PDEVICE_OBJECT Self;
	PDRIVER_OBJECT DriverObject;
	STATE State;
	STATE OldState;
	union
	{
		struct
		{
			PDEVICE_OBJECT LowerDeviceObject;
			PDEVICE_OBJECT PhysicalDeviceObject;
			ULONG Children;
			struct _DEVICE_EXTENSION *ChildList;
		}Bus;

		struct
		{
			PDEVICE_OBJECT Parent;
			struct _DEVICE_EXTENSION *Next;
			VIRTUAL_DEVICE_TYPE VirtualDeviceType; // virtual device type can be HDD, CDROM or FLOPPY
			IMAGE_TYPE ImageType;				   // image type can be RAM or DISK
			ULONG SectorSize;					   // sector size of the device: 512 bytes for HDD and FLOPPY, 2048 bytes for CDROM
			ULONGLONG ImageStartOffsetInBytes;	   // image start offset in bytes on the file system or memory
			ULONGLONG ImageSizeInLBAs;			   // image size in device specific LBAs
			READ_CAPACITY_DATA ReadCapacityData;
			READ_CAPACITY_DATA_EX ReadCapacityDataEx;
			MY_INQUIRY_DATA InquiryData;
			MODE_PARAMETER_HEADER ModeParameterHeader;
			MODE_PAGE_FLEXIBLE_DISK ModePageFlexibleDisk;
			MY_MODE_PAGE_CACHING ModePageCaching;
			CDROM_TOC CdromToc;
			SENSE_DATA SenseData;
			PFILE_OBJECT FileObject;
			PDEVICE_OBJECT FileDeviceObject;
			LIST_ENTRY ListHead;
			KSPIN_LOCK ListLock;
			KEVENT Event;
			PVOID ThreadObject;
			BOOLEAN bTerminateThread;
			DISK_GEOMETRY DiskGeometry;
			SCSI_ADDRESS ScsiAddress;
			STORAGE_ADAPTER_DESCRIPTOR StorageAdapterDescriptor;
			MY_STORAGE_DEVICE_DESCRIPTOR StorageDeviceDescriptor;
			WCHAR wszVirtualDeviceType1[8];
			WCHAR wszVirtualDeviceType2[16];
			WCHAR wszImageType[8];
			WCHAR wszSVBus[8];
			WCHAR wszRevision[8];
			WCHAR wszProductId[32];
			WCHAR wszCompatibleId[16];
		}Disk;
	};
}DEVICE_EXTENSION,*PDEVICE_EXTENSION;

// structure for interrupt vector with segment and offset values
typedef struct _INTERRUPT_VECTOR
{ 
	USHORT Offset;
	USHORT Segment;
}INTERRUPT_VECTOR,*PINTERRUPT_VECTOR;

// structure for GRUB4DOS drive map slot
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::max_sector) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::disable_lba) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::read_only) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::to_cylinder) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::to_cdrom) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::to_support_lba) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::to_head) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::fake_write) Info 768: global struct member not referenced */
/*lint -esym(768,_GRUB4DOS_DRIVE_MAP_SLOT::in_situ) Info 768: global struct member not referenced */
typedef struct _GRUB4DOS_DRIVE_MAP_SLOT
{
	UCHAR from_drive;
	UCHAR to_drive;			 // 0xFF indicates a memdrive
	UCHAR max_head;
	UCHAR max_sector:6;
	UCHAR disable_lba:1;	 // bit 6: disable lba
	UCHAR read_only:1;		 // bit 7: read only 
	USHORT to_cylinder:13;	 // max cylinder of the TO drive
	USHORT from_cdrom:1;	 // bit 13: FROM drive is CDROM(with big 2048-byte sector)
	USHORT to_cdrom:1;		 // bit 14:  TO  drive is CDROM(with big 2048-byte sector)
	USHORT to_support_lba:1; // bit 15:  TO  drive support LBA
	UCHAR to_head;			 // max head of the TO drive
	UCHAR to_sector:6;		 // max sector of the TO drive
	UCHAR fake_write:1;		 // bit 6: fake-write or safe-boot
	UCHAR in_situ:1;		 // bit 7: in-situ
	ULONGLONG start_sector;
	ULONGLONG sector_count;
}GRUB4DOS_DRIVE_MAP_SLOT,*PGRUB4DOS_DRIVE_MAP_SLOT;

// we can have a maximum of 8 GRUB4DOS drive map slots
#define MAXIMUM_GRUB4DOS_DRIVE_MAP_SLOTS 8
// pool tag for the allocated memory
#define SVBUS_POOL_TAG (ULONG)'SBVS'

// custom driver extension structure
typedef struct _MY_DRIVER_EXTENSION
{
	PDEVICE_OBJECT BusDeviceObject;
	GRUB4DOS_DRIVE_MAP_SLOT slot[MAXIMUM_GRUB4DOS_DRIVE_MAP_SLOTS];
}MY_DRIVER_EXTENSION,*PMY_DRIVER_EXTENSION;

// prototypes of functions defined in svbus.c
NTSTATUS ReadWritePhysicalDisk(PDEVICE_OBJECT DeviceObject,PFILE_OBJECT FileObject,ULONG MajorFunction,PVOID buffer,ULONG length,PLARGE_INTEGER offset);
NTSTATUS DiskOpenFile(IN PVOID StartContext);
KSTART_ROUTINE DiskReadWriteThread;
NTSTATUS BusAddChild(IN PDEVICE_OBJECT BusDeviceObject,IN ULONG i);
DRIVER_ADD_DEVICE BusAddDevice;
DRIVER_UNLOAD Unload;
NTSTATUS DiskDispatchPower(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension);
IO_COMPLETION_ROUTINE IoCompletionRoutine;
NTSTATUS BusDispatchPnP(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension);
NTSTATUS BusGetDeviceCapabilities(IN PDEVICE_OBJECT DeviceObject,IN PDEVICE_CAPABILITIES DeviceCapabilities);
VOID ReplaceWCHAR(WCHAR *src,WCHAR search,WCHAR replace);
NTSTATUS DiskDispatchPnP(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension);
FORCEINLINE ULONG MemCopy(PVOID dstBuf,ULONG dstBufLen,PVOID srcBuf,ULONG srcBufLen);
NTSTATUS DiskDispatchDeviceControl(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension);
NTSTATUS DiskDispatchSCSI(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,IN PIO_STACK_LOCATION Stack,IN PDEVICE_EXTENSION DeviceExtension);
__drv_dispatchType(IRP_MJ_PNP)
__drv_dispatchType(IRP_MJ_POWER)
__drv_dispatchType(IRP_MJ_CREATE)
__drv_dispatchType(IRP_MJ_CLOSE)
__drv_dispatchType(IRP_MJ_SYSTEM_CONTROL)
__drv_dispatchType(IRP_MJ_DEVICE_CONTROL)
__drv_dispatchType(IRP_MJ_SCSI)
DRIVER_DISPATCH Dispatch;
NTSTATUS IsSystemSetupInProgress(BOOLEAN *bSystemSetupInProgress);
DRIVER_REINITIALIZE Reinitialize;
DRIVER_INITIALIZE DriverEntry;

#pragma pack(pop,_svbus_) // restore original packing level

#pragma warning(pop) // un-sets any local warning changes

#endif // !defined _SVBUS_

