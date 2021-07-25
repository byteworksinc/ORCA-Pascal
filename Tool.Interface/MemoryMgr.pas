{$keep 'MemoryMgr'}
unit MemoryMgr;
interface

{********************************************************
*
*  Memory Manager Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   attrNoPurge     =   $0000;      (* not purgeable                      *)
   attrBank        =   $0001;      (* fixed bank                         *)
   attrAddr        =   $0002;      (* fixed address                      *)
   attrPage        =   $0004;      (* page aligned                       *)
   attrNoSpec      =   $0008;      (* may not use special memory         *)
   attrNoCross     =   $0010;      (* may not cross bank boundary        *)
   attrPurge1      =   $0100;      (* purge level 1                      *)
   attrPurge2      =   $0200;      (* purge level 2                      *)
   attrPurge3      =   $0300;      (* purge level 3                      *)
   attrPurge       =   $0300;      (* test or set both purge bits        *)
   attrHandle      =   $1000;      (* block of handles - reserved for MM *)
   attrSystem      =   $2000;      (* system handle - reserved for MM    *)
   attrFixed       =   $4000;      (* fixed block                        *)
   attrLocked      =   $8000;      (* locked block                       *)

type
   OOMHeader = record
       reserved:   longint;
       version:    integer;        (* must be zero *)
       signature:  integer;        (* set to $A55A *)
       end;


procedure MMBootInit; tool ($02, $01);     (* WARNING: an application should
                                                       NEVER make this call *)

function MMStartUp: integer; tool ($02, $02);

procedure MMShutDown (userID: integer); tool ($02, $03);

function MMVersion: integer; tool ($02, $04);

procedure MMReset; tool ($02, $05);        (* WARNING: an application should
                                                       NEVER make this call *)

function MMStatus: boolean; tool ($02, $06);

procedure AddToOOMQueue (var headerPtr: OOMHeader); tool ($02, $0C);

procedure BlockMove (sourcPtr, destPtr: ptr; count: longint); tool ($02, $2B);

procedure CheckHandle (theHandle: handle); tool ($02, $1E);

procedure CompactMem; tool ($02, $1F);

procedure DisposeAll (userID: integer); tool ($02, $11);

procedure DisposeHandle (theHandle: handle); tool ($02, $10);

function FindHandle (memLocation: ptr): handle; tool ($02, $1A);

function FreeMem: longint; tool ($02, $1B);

function GetHandleSize (theHandle: handle): longint; tool ($02, $18);

procedure HandToHand (sourceHandle, destHandle: handle; count: longint);
tool ($02, $2A);

procedure HandToPtr (sourceHandle: handle; destPtr: ptr; count: longint);
tool ($02, $29);

procedure HLock (theHandle: handle); tool ($02, $20);

procedure HLockAll (userID: integer); tool ($02, $21);

procedure HUnLock (theHandle: handle); tool ($02, $22);

procedure HUnLockAll (userID: integer); tool ($02, $23);

function MaxBlock: longint; tool ($02, $1C);

function NewHandle (blockSize: longint; userID, memAttributes: integer;
                    memLocation: univ ptr): handle; tool ($02, $09);

procedure PtrToHand (srcPtr: ptr; theHandle: handle; count: longint);
tool ($02, $28);

procedure PurgeAll (userID: integer); tool ($02, $13);

procedure PurgeHandle (theHandle: handle); tool ($02, $12);

function RealFreeMem: longint; tool ($02, $2F);

procedure ReAllocHandle (blockSize: longint; userID, memAttributes: integer;
                         memLocation: ptr; theHandle: handle); tool ($02, $0A);

procedure RemoveFromOOMQueue (var headerPtr: OOMHeader); tool ($02, $0D);

procedure RestoreHandle (theHandle: handle); tool ($02, $0B);

function SetHandleID (newID: integer; theHandle: handle): integer;
tool ($02, $30);

procedure SetHandleSize (newSize: longint; theHandle: handle); tool ($02, $19);

procedure SetPurge (purgeLevel: integer; theHandle: handle); tool ($02, $24);

procedure SetPurgeAll (purgeLevel, userID: integer); tool ($02, $25);

function TotalMem: longint; tool ($02, $1D);

implementation
end.
