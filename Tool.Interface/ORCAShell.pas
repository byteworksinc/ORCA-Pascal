{$keep 'ORCAShell'}
unit ORCAShell;
interface

{********************************************************
*
*  ORCA Shell Interface File
*
*  Notes:  Each call refers to a data control block (DCB),
*          defined as a record.  Calls which return values
*          store the output into the DCB.
*          Each call returns an error number.
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses Common;

type
   changeVectorDCB = record
      reserved: integer;
      vector: integer;
      proc: procPtr;
      oldProc: procPtr;
      end;

   changeVectorDCBGS = record
      pcount: integer;
      reserved: integer;
      vector: integer;
      proc: procPtr;
      oldProc: procPtr;
      end;

   consoleOutDCB = record
      ch: char;
      end;

   consoleOutDCBGS = record
      pcount: integer;
      ch: char; 
      end;

   directionDCB = record
      device: integer;
      result: integer;
      end;

   directionDCBGS = record
      pcount: integer;
      device: integer;
      direct: integer;
      end;

   errorDCB = record
      errorNumber: integer;
      end;

   errorDCBGS = record
      pcount: integer;
      error: integer;
      end;

   executeDCB = record
      flag: integer;
      commandString: textPtr;
      end;

   executeDCBGS = record
      pcount: integer;
      flag: integer;
      comm: textPtr;
      end;

   expandDevicesDCB = record
      name: pathPtr;
      end;

   expandDevicesDCBGS = record
      pcount: integer;
      inName: gsosInStringPtr;
      outName: gsosOutStringPtr;
      end;

   exportDCB = record
      name: pStringPtr;
      flags: integer;
      end;

   exportDCBGS = record
      pcount: integer;
      name: gsosInStringPtr;
      flags: integer;
      end;

   fastFileDCB = record
      action: integer;
      index: integer;
      flags: integer;
      file_handle: handle;
      file_length: longint;
      name: pathPtr;
      access: integer;
      file_type: integer;
      auxType: longint;
      storage_type: integer;
      create_date: integer;
      create_time: integer;
      mod_date: integer;
      mod_time: integer;
      blocks_used: longint;
      end;

   fastFileDCBGS = record
      pcount: integer;
      action: integer;
      index: integer;
      flags: integer;
      fileHandle: handle;
      pathName: gsosInStringPtr;
      access: integer;
      fileType: integer;
      auxType: longint;
      storageType: integer;
      createDate: timeField;
      modDate: timeField;
      option: optionListPtr;
      fileLength: longint;
      blocksUsed: longint;
      end;

   getCommandDCB = record
      index: integer;
      restart: integer;
      reserved: integer;
      command: integer;
      name: packed array [0..15] of char;
      end;

   getCommandDCBGS = record
      pcount: integer;
      index: integer;
      restart: integer;
      reserved: integer;
      command: integer;
      name: packed array [0..15] of char;
      end;

   IODevicesDCB = record
      output_type: integer;
      output_addr: procPtr;
      error_type: integer;
      error_addr: procPtr;
      input_type: integer;
      input_addr: procPtr;
      end;

   IODevicesDCBGS = record
      pcount: integer;
      outputType: integer;
      outputAddr: procPtr;
      errorType: integer;
      errorAddr: procPtr;
      inputType: integer;
      inputAddr: procPtr;
      end;

   initWildcardDCB = record
      wFile: pathPtr;
      flags: integer;
      end;

   initWildcardDCBGS = record
      pcount: integer;
      wFile: gsosInStringPtr;
      flags: integer;
      end;

   keyPressDCBGS = record
      pcount: integer;
      key: char;
      modifiers: integer;
      available: boolean;
      end;
      
   langDCB = record
      languageNum: integer;
      end;

   langDCBGS = record
      pcount: integer;
      lang: integer;
      end;

   lInfoDCB = record
      sFile: pathPtr;
      dFile: pathPtr;
      namesList: cStringPtr;
      iString: cStringPtr;
      merr: byte;
      merrf: byte;
      opFlags: byte;
      keepFlag: byte;
      mFlags: longint;
      pFlags: longint;
      origin: longint;
      end;

   getLInfoDCBGS = record
      pcount: integer;
      sFile: gsosOutStringPtr;
      dFile: gsosOutStringPtr;
      namesList: gsosOutStringPtr;
      iString: gsosOutStringPtr;
      merr: byte;
      merrf: byte;
      lops: byte;
      kFlag: byte;
      mFlags: longint;
      pFlags: longint;
      org: longint;
      end;

   nextWildcardDCB = record
      nextFile: pathPtr;
      end;

   nextWildcardDCBGS = record
      pcount: integer;
      pathName: gsosOutStringPtr;
      access: integer;
      fileType: integer;
      auxType: longint;
      storageType: integer;
      createDate: timeField;
      modDate: timeField;
      option: optionListPtr;
      EOF: longint;
      blocksUsed: longint;
      resourceEOF: longint;
      resourceBlocks: longint;
      end;

   popVariablesDCBGS = record
      pcount: integer;
      end;

   pushVariablesDCBGS = record
      pcount: integer;
      end;

   readIndexedDCB = record
      varName: pStringPtr;
      value: pStringPtr;
      index: integer;
      end;

   readIndexedDCBGS = record
      pcount: integer;
      name: gsosOutStringPtr;
      value: gsosOutStringPtr;
      index: integer;
      export: integer;
      end;

   readKeyDCBGS = record
      pcount: integer;
      key: char;
      modifiers: integer;
      end;

   readVariableDCB = record
      varName: pStringPtr;
      value: pStringPtr;
      end;

   readVariableDCBGS = record
      pcount: integer;
      name: gsosInStringPtr;
      value: gsosOutStringPtr;
      export: integer;
      end;

   redirectDCB = record
      device: integer;
      appendFlag: integer;
      fileName: pStringPtr;
      end;

   redirectDCBGS = record
      pcount: integer;
      device: integer;
      append: integer;
      fileName: gsosInStringPtr;
      end;

   setDCB = record
      varName: pStringPtr;
      value: pStringPtr;
      end;

   setDCBGS = record
      pcount: integer;
      name: gsosInStringPtr;
      value: gsosInStringPtr;
      export: integer;
      end;

   setLInfoDCBGS = record
      pcount: integer;
      sFile: gsosInStringPtr;
      dFile: gsosInStringPtr;
      namesList: gsosInStringPtr;
      iString: gsosInStringPtr;
      merr: byte;
      merrf: byte;
      lops: byte;
      kFlag: byte;
      mFlags: longint;
      pFlags: longint;
      org: longint;
      end;

   stopDCB = record
      stopFlag: boolean;
      end;

   stopDCBGS = record
      pcount: integer;
      flag: boolean;
      end;

   unsetVariableDCB = record
      name: pStringPtr;
      end;

   unsetVariableDCBGS = record
      pcount: integer;
      name: gsosInString;
      end;

   versionDCB = record
      version: packed array[1..4] of char;
      end;

   versionDCBGS = record
      pcount: integer;
      version: packed array[1..4] of char;
      end;

      
procedure ChangeVector (var parms: changeVectorDCB); prodos ($010C);
procedure ChangeVectorGS (var parms: changeVectorDCBGS); prodos ($014C);

procedure ConsoleOut (var parms: consoleOutDCB); prodos ($011A);
procedure ConsoleOutGS (var parms: consoleOutDCBGS); prodos ($015A);

procedure Direction (var parms: directionDCB); prodos ($010F);
procedure DirectionGS (var parms: directionDCBGS); prodos ($014F);

procedure Error (var parms: errorDCB); prodos ($0105);
procedure ErrorGS (var parms: errorDCBGS); prodos ($0145);

procedure Execute (var parms: executeDCB); prodos ($010D);
procedure ExecuteGS (var parms: executeDCBGS); prodos ($014D);

procedure ExpandDevices (var parms: expandDevicesDCB); prodos ($0114);
procedure ExpandDevicesGS (var parms: expandDevicesDCBGS); prodos ($0154);

procedure Export (var parms: exportDCB); prodos ($0116);
procedure ExportGS (var parms: exportDCBGS); prodos ($0156);

procedure FastFile (var parms: fastFileDCB); prodos ($010E);
procedure FastFileGS (var parms: fastFileDCBGS); prodos ($014E);

procedure GetCommand (var parms: getCommandDCB); prodos ($011D);
procedure GetCommandGS (var parms: getCommandDCBGS); prodos ($015D);

procedure GetIODevices (var parms: IODevicesDCB); prodos ($011C);

procedure Get_Lang (var parms: langDCB); prodos ($0103);
procedure GetLangGS (var parms: langDCBGS); prodos ($0143);

procedure GetLInfo (var parms: lInfoDCB); prodos ($0101);
procedure GetLInfoGS (var parms: getLInfoDCBGS); prodos ($0141);

procedure Init_Wildcard (var parms: initWildcardDCB); prodos ($0109);
procedure InitWildcardGS (var parms: initWildcardDCBGS); prodos ($0149);

procedure KeyPressGS (var parms: keyPressDCBGS); prodos ($015E);

procedure Next_Wildcard (var parms: nextWildcardDCB); prodos ($010A);
procedure NextWildcardGS (var parms: nextWildcardDCBGS); prodos ($014A);

procedure PopVariables (parms: ptr {pass nil}); prodos ($0117);
procedure PopVariablesGS (var parms: popVariablesDCBGS); prodos ($0157);

procedure PushVariables (parms: ptr {pass nil}); prodos ($0118);
procedure PushVariablesGS (var parms: pushVariablesDCBGS); prodos ($0158);

procedure Read_Indexed (var parms: readIndexedDCB); prodos ($0108);
procedure ReadIndexedGS (var parms: readIndexedDCBGS); prodos ($0148);

procedure ReadKeyGS (var parms: readKeyDCBGS); prodos ($015F);

procedure Read_Variable (var parms: readVariableDCB); prodos ($010B);
procedure ReadVariableGS (var parms: readVariableDCBGS); prodos ($014B);

procedure Redirect (var parms: directionDCB); prodos ($0110);
procedure RedirectGS (var parms: directionDCBGS); prodos ($0150);

procedure Set_Variable (var parms: setDCB); prodos ($0106);
procedure SetGS (var parms: setDCBGS); prodos ($0146);

procedure SetIODevices (var parms: IODevicesDCB); prodos ($011B);
procedure SetIODevicesGS (var parms: IODevicesDCBGS); prodos ($015B);

procedure Set_Lang (var parms: langDCB); prodos ($0104);
procedure SetLangGS (var parms: langDCBGS); prodos ($0144);

procedure Set_LInfo (var parms: lInfoDCB); prodos ($0102);
procedure SetLInfoGS (var parms: setLInfoDCBGS); prodos ($0142);

procedure SetStopFlag (var parms: stopDCB); prodos ($0119);
procedure SetStopFlagGS (var parms: stopDCBGS); prodos ($0159);

procedure Stop (var parms: stopDCB); prodos ($0113);
procedure StopGS (var parms: stopDCBGS); prodos ($0153);

procedure UnsetVariable (var parms: unsetVariableDCB); prodos ($0115);
procedure UnsetVariableGS (var parms: unsetVariableDCBGS); prodos ($0155);

procedure Version (var parms: versionDCB); prodos ($0107);
procedure VersionGS (var parms: versionDCBGS); prodos ($0147);

implementation
end.
