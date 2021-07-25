{$keep 'ProDOS'}
unit ProDOS;
interface

{********************************************************
*
*  ProDOS 16 Interface File
*
*  Other Uses Files Needed:  Common
*
*  Notes:  Each call refers to a data control block (DCB),
*          defined as a record.  Calls which return values
*          store the output into the DCB.
*          All calls return an error number.
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

type
   createDCB = record
       pathName:    pathPtr;
       access:      integer;
       fileType:    integer;
       auxType:     longint;
       storageType: integer;
       createDate:  integer;
       createTime:  integer;
       end;

   destroyDCB = record
       pathName: pathPtr;
       end;

   changePathDCB = record
       pathName:    pathPtr;
       newPathName: pathPtr;
       end;

   setFileInfoDCB = record
       pathName:   pathPtr;
       access:     integer;
       fileType:   integer;
       auxType:    longint;
       nullField:  integer;
       createDate: integer;
       createTime: integer;
       modDate:    integer;
       modTime:    integer;
       end;

   getFileInfoDCB = record
       pathName:             pathPtr;
       access:               integer;
       fileType:             integer;
       auxTypeOrTotalBlocks: longint;
       storageType:          integer;
       createDate:           integer;
       createTime:           integer;
       modDate:              integer;
       modTime:              integer;
       blocksUsed:           longint;
       end;

   volumeDCB = record
       devName:     pathPtr;
       volName:     pathPtr;
       totalBlocks: longint;
       freeBlocks:  longint;
       fileSysID:   integer;
       end;

   prefixDCB = record
       prefixNum: integer;
       prefix:    pathPtr;
       end;

   clrBkupBitDCB = record
       pathName: pathPtr;
       end;

   openDCB = record
       refNum:   integer;
       pathName: pathPtr;
       reserved: longint;      (* set this value to $00000000 *)
       end;

   newlineDCB = record
       refNum:      integer;
       enableMask:  integer;
       newlineChar: integer;
       end;

   readWriteDCB = record
       refNum:        integer;
       dataBuffer:    ptr;
       requestCount:  longint;
       transferCount: longint;
       end;

   closeDCB = record
       refNum: integer;
       end;

   flushDCB = record
       refNum: integer;
       end;

   markDCB = record
       refNum:   integer;
       position: longint;
       end;

   eofDCB = record
       refNum:   integer;
       fileSize: longint;
       end;

   levelDCB = record
       level: integer;
       end;

   dirEntryDCB = record
       refNum:        integer;
       flags:         integer;
       base:          integer;
       displacement:  integer;
       name:          ptr;
       entryNum:      integer;
       fileType:      integer;
       eofValue:      longint;
       blockCount:    longint;
       createDate:    longint;
       createTime:    longint;
       modDate:       longint;
       modTime:       longint;
       access:        integer;
       auxType:       longint;
       fileSystemID:  integer;
       end;

   getDevNumDCB = record
       devName: pathPtr;
       devNum:  integer;
       end;

   deviceDCB = record
       devNum: integer;
       end;

   blockDCB = record
       devNum:     integer;
       dataBuffer: ptr;
       blockNum:   longint;
       end;

   formatDCB = record
       devName:   pathPtr;
       volName:   pathPtr;
       fileSysID: integer;
       end;

   getNameDCB = record
       theName: pathPtr;
       end;

   quitDCB = record
       pathName: pathPtr;
       flags:    integer;
       end;

   P16versionDCB = record
       version: integer;
       end;

   dInfoDCB = record
       devNum:   integer;
       devName:  pathPtr;
       end;

   allocInterruptDCB = record
       intNum:  integer;
       intCode: ptr;
       end;

   deallocInterruptDCB = record
       intNum: integer;
       end;


procedure P16Create (var parms: createDCB); prodos ($01);

procedure P16Destroy (var parms: destroyDCB); prodos ($02);

procedure P16Change_Path (var parms: changePathDCB); prodos ($04);

procedure P16Set_File_Info (var parms: setFileInfoDCB); prodos ($05);

procedure P16Get_File_Info (var parms: getFileInfoDCB); prodos ($06);

procedure P16Volume (var parms: volumeDCB); prodos ($08);

procedure P16Set_Prefix (var parms: prefixDCB); prodos ($09);

procedure P16Get_Prefix (var parms: prefixDCB); prodos ($0A);

procedure P16Clear_Backup (var parms: clrBkupBitDCB); prodos ($0B);

procedure P16Open (var parms: openDCB); prodos ($10);

procedure P16Newline (var parms: newlineDCB); prodos ($11);

procedure P16Read (var parms: readWriteDCB); prodos ($12);

procedure P16Write (var parms: readWriteDCB); prodos ($13);

procedure P16Close (var parms: closeDCB); prodos ($14);

procedure P16Flush (var parms: flushDCB); prodos ($15);

procedure P16Set_Mark (var parms: markDCB); prodos ($16);

procedure P16Get_Mark (var parms: markDCB); prodos ($17);

procedure P16Set_EOF (var parms: eofDCB); prodos ($18);

procedure P16Get_EOF (var parms: eofDCB); prodos ($19);

procedure P16Set_Level (var parms: levelDCB); prodos ($1A);

procedure P16Get_Level (var parms: levelDCB); prodos ($1B);

procedure P16Get_Dir_Entry (var parms: dirEntryDCB); prodos ($1C);

procedure P16Get_Dev_Number (var parms: getDevNumDCB); prodos ($20);

procedure P16Get_Last_Dev (var parms: deviceDCB); prodos ($21);

procedure P16Read_Block (var parms: blockDCB); prodos ($22);

procedure P16Write_Block (var parms: blockDCB); prodos ($23);

procedure P16Format (var parms: formatDCB); prodos ($24);

procedure P16Erase_Disk (var parms: formatDCB); prodos ($25);

procedure P16Get_Name (var parms: getNameDCB); prodos ($27);

procedure P16Get_Boot_Vol (var parms: getNameDCB); prodos ($28);

procedure P16Quit (var parms: quitDCB); prodos ($29);

procedure P16Get_Version (var parms: P16versionDCB); prodos ($2A);

procedure P16D_Info (var parms: dInfoDCB); prodos ($2C);

procedure P16Alloc_Interrupt (var parms: allocInterruptDCB); prodos ($31);

procedure P16Dealloc_Interrupt (var parms: deallocInterruptDCB); prodos ($32);

implementation
end.
