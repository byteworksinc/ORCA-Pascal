{$keep 'GSOS'}
unit GSOS;
interface

{********************************************************
*
*  GS/OS Interface File
*
*  Other Uses Files Needed: Common
*
*  Notes:  Each call refers to a data control block (DCB),
*          defined as a record.  Calls which return values
*          store the output into the DCB.
*          All calls return an error number.
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* File System IDs *)
   (* reserved = 0 *)
   ProDOS_SOS      =   1;
   DOS_3_3         =   2;
   DOS_3_2         =   3;
   ApplePascal     =   4;
   Macintosh_MFS   =   5;
   Macintosh_HFS   =   6;
   LISA            =   7;
   AppleCPM        =   8;
   CharacterFST    =   9;
   MS_DOS          =   10;
   HighSierra      =   11;
   ISO_9660        =   12;
   AppleShare      =   13;

   (* Standard I/O prefixes *)
   stdIn       =   10;
   stdOut      =   11;
   stdError    =   12;

type
   bindIntOSDCB = record
      pcount: integer;
      intNum: integer;
      vrn: integer;
      intCode: ptr;
      end;

   changePathOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      newPathName: gsosInStringPtr;
      flags: integer;
      end;

   closeOSDCB = record
      pcount: integer;
      refNum: integer;
      end;

   clrBkupBitOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      end;

   createOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      access: integer;
      fileType: integer;
      auxType: longint;
      storageType: integer;
      dataEOF: longint;
      resourceEOF: longint;
      end;

   destroyOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      end;

   devReadWriteOSDCB = record
      pcount: integer;
      devNum: integer;
      buffer: ptr;
      requestCount: longint;
      startingBlock: longint;
      blockSize: integer;
      transferCount: longint;
      end;

   dInfoOSDCB = record
      pcount: integer;
      devNum: integer;
      devName: gsosOutStringPtr;
      characteristics: integer;
      totalBlocks: longint;
      slotNum: integer;
      unitNum: integer;
      version: integer;
      deviceID: integer;
      headLink: integer;
      forwardLink: integer;
      extendedDIBptr: ptr;
      end;

   dirEntryOSDCB = record
      pcount: integer;
      refNum: integer;
      flags: integer;
      base: integer;
      displacement: integer;
      name: gsosOutStringPtr;
      entryNum: integer;
      fileType: integer;
      eofValue: longint;
      blockCount: longint;
      createDateTime: timeField;
      modDateTime: timeField;
      access: integer;
      auxType: longint;
      fileSysID: integer;
      optionList: optionListPtr;
      resourceEOF: longint;
      resourceBlocks: longint;
      end;

   dRenameOSDCB = record
      pcount: integer;
      devNum: integer;
      replaceString: gsosInStringPtr;
      end;

   dStatusOSDCB = record
      pcount: integer;
      devNum: integer;
      statusCode: integer;
      statusList: ptr;
      requestCount: longint;
      transferCount: longint;
      end;

   eofOSDCB = record
      pcount: integer;
      refNum: integer;
      eofEOF: longint;
      end;

   expandPathOSDCB = record
      pcount: integer;
      inputPath: gsosInStringPtr;
      outputPath: gsosOutStringPtr;
      flags: integer;
      end;

   flushOSDCB = record
      pcount: integer;
      refNum: integer;
      end;

   formatOSDCB = record
      pcount: integer;
      devName: gsosInStringPtr;
      volName: gsosInStringPtr;
      fileSysID: integer;
      reqFileSysID: integer;
      flags: integer;
      reaVolName: gsosOutStringPtr;
      end;

   fstInfoOSDCB = record
      pcount: integer;
      fstNum: integer;
      fileSysID: integer;
      fstName: gsosOutStringPtr;
      version: integer;
      attributes: integer;
      blockSize: integer;
      maxVolSize: longint;
      maxFileSize: longint;
      end;

   getDevNumOSDCB = record
      pcount: integer;
      devName: gsosInStringPtr;
      devNum: integer;
      end;

   getFileInfoOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      access: integer;
      fileType: integer;
      auxType: longint;
      storageType: integer;
      createDateTime: timeField;
      modDateTime: timeField;
      optionList: optionListPtr;
      dataEOF: longint;
      blocksUsed: longint;
      resourceEOF: longint;
      resourceBlocks: longint;
      end;

   getMarkOSDCB = record
      pcount: integer;
      refNum: integer;
      position: longint;
      end;

   getNameOSDCB = record
      pcount: integer;
      dataBuffer: gsosOutStringPtr;
      userID: integer;
      end;

   getPrefixOSDCB = record
      pcount: integer;
      prefixNum: integer;
      prefix: gsosOutStringPtr;
      end;

   getRefInfoOSDCB = record
      pcount: integer;
      referenceNumber: integer;
      access: integer;
      thePath: gsosOutStringPtr;
      resourceNumber: integer;
      level: integer;
      end;

   getRefNumOSDCB = record
      pcount: integer;
      thePath: gsosInStringPtr;
      referenceNumber: integer;
      access: integer;
      resourceNum: integer;
      caseSense: integer;
      displacement: integer;
      end;

   getStdRefNumOSDCB = record
      pcount: integer;
      prefixNumber: integer;
      referenceNumber: integer;
      end;

   judgeNameOSDCB = record
      pcount: integer;
      fileSysID: integer;
      nameType: integer;
      syntax: pStringPtr;
      maxLen: integer;
      name: gsosOutStringPtr;
      nameFlags: integer;
      end;

   levelOSDCB = record
      pcount: integer;
      level: integer;
      levelMode: integer;
      end;

   newlineOSDCB = record
      pcount: integer;
      refNum: integer;
      enableMask: integer;
      numChars: integer;
      newlineTable: ptr;
      end;

   notifyOSDCB = record
      pcount: integer;
      theProc: procPtr;
      end;

   nullOSDCB = record
      pcount: integer;
      end;

   openOSDCB = record
      pcount: integer;
      refNum: integer;
      pathName: gsosInStringPtr;
      requestAccess: integer;
      resourceNumber: integer;
      access: integer;
      fileType: integer;
      auxType: longint;
      storageType: integer;
      createDateTime: timeField;
      modDateTime: timeField;
      optionList: optionListPtr;
      dataEOF: longint;
      blocksUsed: longint;
      resourceEOF: longint;
      resourceBlocks: longint;
      end;

   osVersionOSDCB = record
      pcount: integer;
      version: integer;
      end;

   prefsOSDCB = record
      pcount: integer;
      preferences: integer;
      end;

   quitOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      flags: integer;
      end;

   readWriteOSDCB = record
      pcount: integer;
      refNum: integer;
      dataBuffer: ptr;
      requestCount: longint;
      transferCount: longint;
      cachePriority: integer;
      end;

   setFileInfoOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      access: integer;
      fileType: integer;
      auxType: longint;
      nullField1: integer;       {set this field to zero}
      createDateTime: timeField;
      modDateTime: timeField;
      optionList: optionListPtr;
      nullField2: longint;       {set this field to zero}
      nullField3: longint;       {set this field to zero}
      nullField4: longint;       {set this field to zero}
      nullField5: longint;       {set this field to zero}
      end;

   setMarkOSDCB = record
      pcount: integer;
      refNum: integer;
      base: integer;
      displacement: longint;
      end;

   setStdRefNumOSDCB = record
      pcount: integer;
      prefixNum: integer;
      refNum: integer;
      end;

   shutdownOSDCB = record
      pcount: integer;
      shutdownFlag: integer;
      end;

   statusOSDCB = record
      pcount: integer;
      status: integer;
      end;

   unbindIntOSDCB = record
      pcount: integer;
      intNum: integer;
      end;

   volumeOSDCB = record
      pcount: integer;
      devName: gsosInStringPtr;
      volName: gsosOutStringPtr;
      totalBlocks: longint;
      freeBlocks: longint;
      fileSysID: integer;
      blockSize: integer;
      characteristics: integer;
      deviceID: integer;
      end;


procedure AddNotifyProcGS (var parms: notifyOSDCB); prodos ($2034);

procedure BeginSessionGS (var parms: nullOSDCB); prodos ($201D);

procedure BindIntGS (var parms: bindIntOSDCB); prodos ($2031);

procedure ChangePathGS (var parms: changePathOSDCB); prodos ($2004);

procedure ClearBackupGS (var parms: clrBkupBitOSDCB); prodos ($200B);

procedure CloseGS (var parms: closeOSDCB); prodos ($2014);

procedure CreateGS (var parms: createOSDCB); prodos ($2001);

procedure DControlGS (var parms: dStatusOSDCB); prodos ($202E);

procedure DelNotifyProcGS (var parms: notifyOSDCB); prodos ($2035);

procedure DestroyGS (var parms: destroyOSDCB); prodos ($2002);

procedure DInfoGS (var parms: dInfoOSDCB); prodos ($202C);

procedure DReadGS (var parms: devReadWriteOSDCB); prodos ($202F);

procedure DRenameGS (var parms: dRenameOSDCB); prodos ($2036);

procedure DStatusGS (var parms: dStatusOSDCB); prodos ($202D);

procedure DWriteGS (var parms: devReadWriteOSDCB); prodos ($2030);

procedure EndSessionGS (var parms: nullOSDCB); prodos ($201E);

procedure EraseDiskGS (var parms: formatOSDCB); prodos ($2025);

procedure ExpandPathGS (var parms: expandPathOSDCB); prodos ($200E);

procedure FlushGS (var parms: flushOSDCB); prodos ($2015);

procedure FormatGS (var parms: formatOSDCB); prodos ($2024);

procedure GetBootVolGS (var parms: getNameOSDCB); prodos ($2028);

procedure GetDevNumberGS (var parms: getDevNumOSDCB); prodos ($2020);

procedure GetDirEntryGS (var parms: dirEntryOSDCB); prodos ($201C);

procedure GetEOFGS (var parms: eofOSDCB); prodos ($2019);

procedure GetFileInfoGS (var parms: getFileInfoOSDCB); prodos ($2006);

procedure GetFSTInfoGS (var parms: fstInfoOSDCB); prodos ($202B);

procedure GetLevelGS (var parms: levelOSDCB); prodos ($201B);

procedure GetMarkGS (var parms: getMarkOSDCB); prodos ($2017);

procedure GetNameGS (var parms: getNameOSDCB); prodos ($2027);

procedure GetPrefixGS (var parms: getPrefixOSDCB); prodos ($200A);

procedure GetRefInfoGS (var parms: getRefInfoOSDCB); prodos ($2039);

procedure GetRefNumGS (var parms: getRefNumOSDCB); prodos ($2038);

procedure GetStdRefNumGS (var parms: getStdRefNumOSDCB); prodos ($2037);

procedure GetSysPrefsGS (var parms: prefsOSDCB); prodos ($200F);

procedure GetVersionGS (var parms: osVersionOSDCB); prodos ($202A);

procedure JudgeNameGS (var parms: judgeNameOSDCB); prodos ($2007);
          
procedure NewlineGS (var parms: newlineOSDCB); prodos ($2011);

procedure NullGS (var parms: nullOSDCB); prodos ($200D);

procedure OpenGS (var parms: openOSDCB); prodos ($2010);

procedure OSShutdownGS (var parms: shutdownOSDCB); prodos ($2003);

procedure QuitGS (var parms: quitOSDCB); prodos ($2029);

procedure ReadGS (var parms: readWriteOSDCB); prodos ($2012);

procedure ResetCacheGS (var parms: nullOSDCB); prodos ($2026);

procedure SessionStatusGS (var parms: statusOSDCB); prodos ($201F);

procedure SetEOFGS (var parms: setMarkOSDCB); prodos ($2018);

procedure SetFileInfoGS (var parms: setFileInfoOSDCB); prodos ($2005);

procedure SetLevelGS (var parms: levelOSDCB); prodos ($201A);

procedure SetMarkGS (var parms: setMarkOSDCB); prodos ($2016);

procedure SetPrefixGS (var parms: getPrefixOSDCB); prodos ($2009);

procedure SetStdRefNum (var parms: setStdRefNumOSDCB); prodos ($203A);

procedure SetSysPrefsGS (var parms: prefsOSDCB); prodos ($200C);

procedure UnbindIntGS (var parms: unbindIntOSDCB); prodos ($2032);

procedure VolumeGS (var parms: volumeOSDCB); prodos ($2008);

procedure WriteGS (var parms: readWriteOSDCB); prodos ($2013);


implementation

end.
