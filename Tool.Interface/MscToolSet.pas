{$keep 'MscToolSet'}
unit MscToolSet;
interface

{********************************************************
*
*   Miscellaneous Tool Set Interface File
*
*   Other USES Files Needed: Common
*
*   Other Tool Sets Needed:  Tool Locator, Memory Manager
*
*  Copyright 1987-1992, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

type
   queueHeader = record
       reserved1:  longint;
       reserved2:  integer;
       signature:  integer;    (* set to $A55A *)
       end;
   queueHeaderPtr = ^queueHeader;

   intStateRecord = record
       irq_A:       integer;
       irq_X:       integer;
       irq_Y:       integer;
       irq_S:       integer;
       irq_D:       integer;
       irq_P:       byte;
       irq_DB:      byte;
       irq_e:       byte;
       irq_K:       byte;
       irq_PC:      integer;
       irq_state:   byte;
       irq_shadow:  integer;
       irq_mslot:   byte;
       end;


procedure MTBootInit; tool ($03, $01);     (* WARNING: an application should
                                                       NEVER make this call *)

procedure MTStartUp; tool ($03, $02);

procedure MTShutDown; tool ($03, $03);

function MTVersion: integer; tool ($03, $04);

procedure MTReset; tool ($03, $05);        (* WARNING: an application should
                                                       NEVER make this call *)

function MTStatus: boolean; tool ($03, $06);

procedure AddToQueue (newEntry, headerPtr: queueHeaderPtr); tool ($03, $2E);

function ConvSeconds (convVerb: integer; seconds: longint; datePtr: ptr)
                      : longint; tool ($03, $37);

procedure DeleteFromQueue (newEntry, headerPtr: queueHeaderPtr); tool ($03, $2F);

procedure SetInterruptState (var interruptState: intStateRecord;
                             bytesDesired: integer); tool ($03, $30);

procedure GetInterruptState (var interruptState: intStateRecord;
                             bytesDesired: integer); tool ($03, $31);

function GetIntStateRecSize: integer; tool ($03, $32);

function GetCodeResConverter: procPtr; tool ($03, $34);

procedure WriteBRam (bufferAddress: ptr); tool ($03, $09);

procedure ReadBRam (bufferAddress: ptr); tool ($03, $0A);

procedure WriteBParam (theData, paramRefNum: integer); tool ($03, $0B);

function ReadBParam (paramRefNum: integer): integer; tool ($03, $0C);

(* ReadTimeHex returns 8 bytes - no direct interface is possible *)

(* To set up parameters for WriteTimeHex, you could shift the first value *)
(* and then OR it with the second value:  month_day := month << 8 | day   *)

procedure WriteTimeHex (month_day, year_hour, minute_second: integer);
tool ($03, $0E);

procedure ReadASCIITime (bufferAddress: ptr); tool ($03, $0F);

(* FWEntry returns 4 integers - no direct interface is possible *)

function GetAddr (refNum: integer): ptr; tool ($03, $16);

function GetTick: longint; tool ($03, $25);

function GetIRQEnable: integer; tool ($03, $29);

procedure IntSource (srcRefNum: integer); tool ($03, $23);

procedure ClampMouse (xMinClamp, xMaxClamp, yMinClamp, yMaxClamp: integer);
tool ($03, $1C);

procedure ClearMouse; tool ($03, $1B);

(* GetMouseClamp returns 4 integers - no direct interface is possible *)

procedure HomeMouse; tool ($03, $1A);

procedure InitMouse (mouseSlot: integer); tool ($03, $18);

procedure PosMouse (xPos, yPos: integer); tool ($03, $1E);

(* ReadMouse returns 2 integers and 2 bytes - no direct interface is possible *)
(* ReadMouse2 returns 3 integers - no direct interface is possible            *)

function ServeMouse: integer; tool ($03, $1F);

procedure SetMouse (mouseMode: integer); tool ($03, $19);

procedure SetAbsClamp (xMinClamp, xMaxClamp, yMinClamp, yMaxClamp: integer);
tool ($03, $2A);

(* GetAbsClamp returns 4 integers - no direct interface is possible *)

function PackBytes (startHandle: handle; var size: integer; bufferPtr: ptr;
                    bufferSize: integer): integer; tool ($03, $26);

function UnPackBytes (packBufferPtr: ptr; bufferSize: integer;
                      startHandle: handle; var size: integer): integer;
tool ($03, $27);

function Munger (destPtr: handle; var destLen: integer; targPtr: ptr;
                 targLen: integer; replPtr: ptr; replLen: integer;
                 padPtr: ptr): integer; tool ($03, $28);

procedure SetHeartBeat (taskPtr: ptr); tool ($03, $12);

procedure DelHeartBeat (taskPtr: ptr); tool ($03, $13);

procedure ClrHeartBeat; tool ($03, $14);

procedure SysBeep; tool ($03, $2C);

procedure SysBeep2 (beepType: integer); tool ($03, $38);

procedure SysFailMgr (errorCode: integer; failString: univ pStringPtr);
tool ($03, $15);

function GetNewID (IDTag: integer): integer; tool ($03, $20);

procedure DeleteID (IDTag: integer); tool ($03, $21);

procedure StatusID (IDTag: integer); tool ($03, $22);

procedure SetVector (vectorRefNum: integer; vectorPtr: ptr); tool ($03, $10);

function GetVector (vectorRefNum: integer): ptr; tool ($03, $11);

procedure VersionString (flags: integer; theVersion: longint;
   str: univ cStringPtr); tool ($03, $39);

function WaitUntil (delayFrom, delayAmount: integer): integer; tool ($03, $3A);

function ScanDevices: integer; tool ($03, $3D);

procedure ShowBootInfo (str: cStringPtr; icon: ptr); tool ($03, $3C);

function StringToText (flags: integer; textPtr: cStringPtr; textLen: integer;
   result: gsosOutStringPtr): longint; tool ($03, $3B);

{new in 6.0.1}

function AlertMessage (msgTable: ptr; msgNum: integer; subs: ptr): integer;
tool($03, $3E);

function DoSysPrefs (bitsToClear, bitsToSet: integer): integer; tool ($03, $3F);

implementation
end.
