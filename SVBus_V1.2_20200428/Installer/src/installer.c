
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

#define APPNAME "SVBus Installer"
#define VERSION "V1.2"
#define BUILD "Build 20200428"

#include <windows.h>
// printf
#include <stdio.h>
// HDEVINFO
#include <setupapi.h>
// GUID_DEVCLASS_SCSIADAPTER
#include <initguid.h>
#include <devguid.h>
// UpdateDriverForPlugAndPlayDevices
#include <newdev.h>
#pragma warning(disable:28719) // Banned API Usage: lstrcpy is a Banned API as listed in dontuse.h for security purposes.


//------------------------------------------------------------------------------
// main function
//------------------------------------------------------------------------------
int __cdecl main()
{
	SYSTEM_INFO siSysInfo;
	LPCTSTR ServiceKey;
	LPCTSTR DeviceName;
	LPCTSTR hwid;
	HKEY hKey;
	HDEVINFO DeviceInfoSet;
	SP_DEVINFO_DATA DeviceInfoData;
	TCHAR hwIdList[LINE_LEN + 4];
	DWORD dwPropertyBufferSize;
	DWORD dwLen;
	LPCTSTR inf = TEXT("svbus.inf");
	TCHAR InfPath[MAX_PATH];

	// show app name, version and build number
	printf(APPNAME" "VERSION" "BUILD" by Kai Schtrom\n");

	// get system info
	GetSystemInfo(&siSysInfo);

	// running on x86
	if(siSysInfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_INTEL)
	{
		ServiceKey = TEXT("System\\CurrentControlSet\\Services\\svbusx86");
		DeviceName = TEXT("svbusx86");
		hwid = TEXT("ROOT\\svbusx86");
	}
	// running on x64
	else if(siSysInfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64)
	{
		ServiceKey = TEXT("System\\CurrentControlSet\\Services\\svbusx64");
		DeviceName = TEXT("svbusx64");
		hwid = TEXT("ROOT\\svbusx64");
	}
	// unknown architecture
	else
	{
		printf("Error : Unknown processor architecture found\n");
		return 1;
	}

	// open SVBus service registry key to check if the driver is already installed
	if(RegOpenKey(HKEY_LOCAL_MACHINE,ServiceKey,&hKey) == ERROR_SUCCESS)
	{
		printf("Error : SVBus driver is already installed\n");
		RegCloseKey(hKey);
		return 2;
	}

	// create an empty device information set
	DeviceInfoSet = SetupDiCreateDeviceInfoList(&GUID_DEVCLASS_SCSIADAPTER,0);
	if(DeviceInfoSet == INVALID_HANDLE_VALUE)
	{
		printf("Error : SetupDiCreateDeviceInfoList failed rc = %d\n",GetLastError());
		return 3;
	}

	// create a new device information element and add it as a new member to the specified device information set
	DeviceInfoData.cbSize = sizeof(SP_DEVINFO_DATA);
	if(SetupDiCreateDeviceInfo(DeviceInfoSet,DeviceName,&GUID_DEVCLASS_SCSIADAPTER,NULL,0,DICD_GENERATE_ID,&DeviceInfoData) == FALSE)
	{
		printf("Error : SetupDiCreateDeviceInfo failed rc = %d\n",GetLastError());
		SetupDiDestroyDeviceInfoList(DeviceInfoSet);
		return 4;
	}

	// list of hardware ID's must be double zero-terminated
	ZeroMemory(hwIdList,sizeof(hwIdList));
	if(lstrcpy(hwIdList,hwid) == NULL)
	{
		printf("Error : lstrcpy failed\n");
		SetupDiDestroyDeviceInfoList(DeviceInfoSet);
		return 5;		
	}

	// add HardwareID to the Device's HardwareID property
	dwPropertyBufferSize = (DWORD)(lstrlen(hwIdList) + 1 + 1) * sizeof(TCHAR);
	if(SetupDiSetDeviceRegistryProperty(DeviceInfoSet,&DeviceInfoData,SPDRP_HARDWAREID,(LPBYTE)hwIdList,dwPropertyBufferSize) == FALSE)
	{
		printf("Error : SetupDiSetDeviceRegistryProperty failed rc = %d\n",GetLastError());
		SetupDiDestroyDeviceInfoList(DeviceInfoSet);
		return 6;
	}

	// call the appropriate class installer
	// transform the registry element into an actual devnode in the PnP HW tree
	if(SetupDiCallClassInstaller(DIF_REGISTERDEVICE,DeviceInfoSet,&DeviceInfoData) == FALSE)
	{
		printf("Error : SetupDiCallClassInstaller failed rc = %d\n",GetLastError());
		SetupDiDestroyDeviceInfoList(DeviceInfoSet);
		return 7;
	}

	// retrieve full path and file name of the specified INF file
	dwLen = GetFullPathName(inf,MAX_PATH,InfPath,NULL);
	if(dwLen >= MAX_PATH || dwLen == 0)
	{
		// INF path name too long
		printf("Error : INF path name is too long\n");
		SetupDiDestroyDeviceInfoList(DeviceInfoSet);
		return 8;
	}

	// retrieve file system attributes for the specified INF file
	if(GetFileAttributes(InfPath) == INVALID_FILE_ATTRIBUTES)
	{
		// INF doesn't exist
		printf("Error : INF doesn't exist\n");
		SetupDiDestroyDeviceInfoList(DeviceInfoSet);
		return 9;
	}

	// install updated drivers for devices that match the hardware ID
	if(UpdateDriverForPlugAndPlayDevices(NULL,hwid,InfPath,INSTALLFLAG_FORCE,NULL) == FALSE)
	{
		printf("Error : UpdateDriverForPlugAndPlayDevices failed rc = %d\n",GetLastError());
		SetupDiDestroyDeviceInfoList(DeviceInfoSet);
		return 10;
	}

	// delete device information set and free all associated memory
	SetupDiDestroyDeviceInfoList(DeviceInfoSet);

	printf("OK    : SVBus installed successfully\n");

	return 0;
}

