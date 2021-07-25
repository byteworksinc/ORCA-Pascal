{$keep 'ResourceMgr'}
unit ResourceMgr;
interface

{********************************************************
*
*  Resource Manager Interface File
*
*  Other USES files needed:  Common
*
*  Other Tool Sets Needed:  - None -
*
*  Copyright 1987-1992, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Resource Manager Error Codes *)
   resForkUsed     =   $1E01;  (* resource fork not empty                     *)
   resBadFormat    =   $1E02;  (* format of resource fork is unknown          *)
   resNoConverter  =   $1E03;  (* no converter logged in for resource         *)
   resNoCurFile    =   $1E04;  (* there are no current open resource files    *)
   resDupID        =   $1E05;  (* ID is already used                          *)
   resNotFound     =   $1E06;  (* resource was not found                      *)
   resFileNotFound =   $1E07;  (* resource file not found                     *)
   resBadAppID     =   $1E08;  (* user ID not found, call ResourceStartup     *)
   resNoUniqueID   =   $1E09;  (* a unique ID was not found                   *)
   resIndexRange   =   $1E0A;  (* index is out of range                       *)
   resSysIsOpen    =   $1E0B;  (* system file is already open                 *)
   resHasChanged   =   $1E0C;  (* resource changed - operation can't be done  *)
   resDifConverter =   $1E0D;  (* different converter logged for resrc type   *)

   (* Resource flag values *)
   resChanged      =   $0020;  (* true if resource has changed                *)
   resPreLoad      =   $0040;  (* true if should load with OpenResourceFile   *)
   resProtected    =   $0080;  (* true if should never write to disk          *)
   resAbsLoad      =   $0400;  (* true if should load at absolute address     *)
   resConverter    =   $0800;  (* true if requires converter for loads/writes *)
   resMemAttr      =   $C31C;  (* mask for NewHandle for resource memory      *)

   (* System file ID *)
   sysFileID       =   $0001;  (* file ID of system resource file *)

   (* Map flag values *)
   systemMap       =   $0001;
   mapChanged      =   $0002;  (* true if map has changed         *)
   romMap          =   $0004;  (* true if resource file is in ROM *)

type
   resID   = longint;
   resType = integer;
   resAttr = integer;

   resHeaderRec = record
       rFileVersion:  longint;
       rFileToMap:    longint;
       rFileMapSize:  longint;
       rFileMemo:     packed array [1..128] of byte;
       end;

   freeBlockRec = record
       blkOffset:  longint;
       blkSize:    longint;
       end;

   resRefRec = record
       rResType:    resType;
       rResID:      resID;
       rResOffset:  longint;
       rResAttr:    resAttr;
       rResSize:    longint;
       rResHandle:  handle;
       end;

   resMapHandle = ^resMapPtr;
   resMapPtr    = ^resMapRec;
   resMapRec = record
       mapNext:          resMapHandle;
       mapFlag:          integer;
       mapOffset:        longint;
       mapSize:          longint;
       mapToIndex:       integer;
       mapFileNum:       integer;
       mapID:            integer;
       mapIndexSize:     longint;
       mapIndexUsed:     longint;
       mapFreeListSize:  integer;
       mapFreeListUsed:  integer;
   (* Set the array size for your application. *)
       mapFreeList:      array [1..1] of freeBlockRec;
       end;

   resourceSpec = record
       resourceType:  resType;
       resourceID:    resID;
       end;

   resNameEntryPtr = ^resNameEntry;
   resNameEntry = record
       namedResID:  resID;
       resName:     pString
       end;

   resNameRecordHandle = ^ResNameRecordPtr;
   resNameRecordPtr    = ^ResNameRecord;
   resNameRecord = record
       version:         integer;
       nameCount:       longint;
       resNameEntries:  array [1..1] of resNameEntry;
       end;


procedure ResourceBootInit; tool ($1E, $01); (* WARNING: an application should
                                                         NEVER make this call *)

procedure ResourceStartup (myID: integer); tool ($1E, $02);

procedure ResourceShutdown; tool ($1E, $03);

function ResourceVersion: integer; tool ($1E, $04);

procedure ResourceReset; tool ($1E, $05);    (* WARNING: an application should
                                                         NEVER make this call *)

function ResourceStatus: boolean; tool ($1E, $06);

procedure AddResource (resourceHandle: handle; resourceAttr: integer;
                       resourceType: integer; resourceID: longint);
tool ($1E, $0C);

procedure CloseResourceFile (fileID: integer); tool ($1E, $0B);

function CountResources (resourceType: integer): longint; tool ($1E, $22);

function CountTypes: integer; tool ($1E, $20);

procedure CreateResourceFile (auxType: longint; fileType: integer; 
                              fileAccess: integer; var fileName: gsosInString);
tool ($1E, $09);

procedure DetachResource (resourceType: integer; resourceID: longint); 
tool ($1E, $18);

function GetCurResourceApp: integer; tool ($1E, $14);

function GetCurResourceFile: integer; tool ($1E, $12);

function GetIndResource (resourceType: resType; resourceIndex: longint): resID;
tool ($1E, $23);

function GetIndType (typeIndex: integer): resType; tool ($1E, $21);

function GetMapHandle (fileID: integer): resMapHandle; tool ($1E, $26);

function GetOpenFileRefNum (fileID: integer): integer; tool ($1E, $1F);

function GetResourceAttr (resourceType: resType; resourceID: resID): resAttr;
tool ($1E, $1B);

function GetResourceSize (resourceType: resType; resourceID: resID): longint;
tool ($1E, $1D);

function HomeResourceFile (resourceType: resType; resourceID: resID): integer;
tool ($1E, $15);

function LoadAbsResource (loadAddress: longint; maxSize: longint;
                          resourceType: resType; resourceID: resID): longint;
tool ($1E, $27);

function LoadResource (resourceType: resType; resourceID: resID): handle;
tool ($1E, $0E);

function LoadResource2 (flags: integer; buffer: ptr; resourceType: resType;
   resourceID: resID): handle; tool ($1E, $29);

procedure MarkResourceChange (changeFlag: boolean; resourceType: resType;
                              resourceID: resID); tool ($1E, $10);

procedure MatchResourceHandle (var foundRec: resourceSpec;
                               resourceHandle: handle); tool ($1E, $1E);

function OpenResourceFile (openAccess: integer; mapAddress: resMapPtr;
                           var fileName: gsosInString): integer; tool ($1E, $0A);

procedure ReleaseResource (purgeLevel: integer; resourceType: resType;
                           resourceID: resID); tool ($1E, $17);

procedure RemoveResource (resourceType: resType; resourceID: resID);
tool ($1E, $0F);

procedure ResourceConverter (converterProc: procPtr; resourceType: resType;
                             logFlags: integer); tool ($1E, $28);

function RMFindNamedResource (resourceType: resType; name: pString;
   var fileNum: integer): longint; tool ($1E, $2A);

procedure RMGetResourceName (resourceType: resType; rID: longint;
   var name: pString); tool ($1E, $2B);

procedure RMSetResourceName (resourceType: resType; rID: longint;
   name: pString); tool ($1E, $2D);

function RMLoadNamedResource (resourceType: resType; name: pString):
   handle; tool ($1E, $2C);

procedure SetCurResourceApp (myID: integer); tool ($1E, $13);

procedure SetCurResourceFile (fileID: integer); tool ($1E, $11);

procedure SetResourceAttr (resourceAttr: resAttr; resourceType: resType;
                           resourceID: resID); tool ($1E, $1C);

function SetResourceFileDepth (searchDepth: integer): integer; tool ($1E, $25);

procedure SetResourceID (newID: resID; resourceType: resType; 
                         currentID: resID); tool ($1E, $1A);

function SetResourceLoad (readFlag: integer): integer; tool ($1E, $24);

function UniqueResourceID (IDrange: integer; resourceType: resType): resID;
tool ($1E, $19);

procedure UpdateResourceFile (fileID: integer); tool ($1E, $0D);

procedure WriteResource (resourceType: resType; resourceID: resID);
tool ($1E, $16);

{new in 6.0.1}

function OpenResourceFileByID (openAccess, userID: integer): integer;
tool ($1E, $2E);

procedure CompactResourceFile (flags, fileID: integer); tool ($1E, $2F);

implementation
end.
