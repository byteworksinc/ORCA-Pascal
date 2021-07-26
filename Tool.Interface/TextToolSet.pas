{$keep 'TextToolSet'}
unit TextToolSet;
interface

{********************************************************
*
*  Text Tool Set Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager
*
*  Copyright 1987-1989
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Echo flag values *)
   noEcho      =   $0000;      (* don't echo chars to output device *)
   echo        =   $0001;      (* echo chars to output device *)

   (* Device numbers *)
   inputDev    =   $0000;
   outputDev   =   $0001;
   errorOutputDev = $0002;

   (* Device types *)
   basicType   =   $0000;
   pascalType  =   $0001;
   ramBased    =   $0002;


procedure TextBootInit; tool ($0C, $01);   (* WARNING: an application should
                                                       NEVER make this call *)

procedure TextStartup; tool ($0C, $02);

procedure TextShutDown; tool ($0C, $03);

function TextVersion: integer; tool ($0C, $04);

procedure TextReset; tool ($0C, $05);      (* WARNING: an application should
                                                       NEVER make this call *)

function TextStatus: boolean; tool ($0C, $06);

procedure CtlTextDev (deviceNumber, controlCode: integer); tool ($0C, $16);

procedure ErrWriteBlock (theText: textBlock; offset, count: integer);
tool ($0C, $1F);

procedure ErrWriteChar (theChar: char); tool ($0C, $19);

procedure ErrWriteCString (theCString: univ cStringPtr); tool ($0C, $21);

procedure ErrWriteLine (theString: univ pStringPtr); tool ($0C, $1B);

procedure ErrWriteString (theString: univ pStringPtr); tool ($0C, $1D);

(* GetErrGlobals returns 2 words:  loWord = OR mask, hiWord = AND mask *)
function GetErrGlobals: longint; tool ($0C, $0E);

(* GetErrorDevice returns 1 integer and 1 longint.                     *)
(* function GetErrorDevice: (deviceType: integer; ptrOrSlot: longint); *)
(* tool ($0C, $14);                                                    *)

(* GetInGlobals returns 2 words: loWord = OR mask, hiWord = AND mask *)
function GetInGlobals: longint; tool ($0C, $0C);

(* GetInputDevice returns 1 integer and 1 longint.                      *)
(* function GetInputDevice: (deviceType: integer; ptrOrSlot: longint);  *)
(* tool ($0C, $12);                                                     *)

(* GetOutGlobals returns 2 words:  loWord = OR mask, hiWord = AND mask *)
function GetOutGlobals: longint; tool ($0C, $0D);

(* GetOutputDevice returns 1 integer and 1 longint.                     *)
(* function GetOutputDevice: (deviceType: integer; ptrOrSlot: longint); *)
(* tool ($0C, $13);                                                     *)

procedure InitTextDev (deviceNum: integer); tool ($0C, $15);

function ReadChar (echoFlag: boolean): char; tool ($0C, $22);

function ReadLine (bufferPtr: ptr; maxCount: integer; endOfLine: char;
                   echoFlag: boolean): integer; tool ($0C, $24);

procedure SetErrGlobals (ANDMask, ORMask: integer); tool ($0C, $0B);

procedure SetErrorDevice (deviceType: integer; slotOrPointer: longint);
tool ($0C, $11);

procedure SetInGlobals (ANDMask, ORMask: integer); tool ($0C, $09);

procedure SetInputDevice (deviceType: integer; slotOrPointer: longint);
tool ($0C, $0F);

procedure SetOutGlobals (ANDMask, ORMask: integer); tool ($0C, $0A);

procedure SetOutputDevice (deviceType: integer; slotOrPointer: longint);
tool ($0C, $10);

procedure StatusTextDev (deviceNum, requestCode: integer); tool ($0C, $17);

procedure TextReadBlock (bufferPtr: ptr; offset, blockSize: integer;
                         echoFlag: boolean); tool ($0C, $23);

procedure TextWriteBlock (theText: univ textPtr; offset, count: integer);
tool ($0C, $1E);

procedure WriteChar (theChar: char); tool ($0C, $18);

procedure WriteCString (theCString: univ cStringPtr); tool ($0C, $20);

procedure WriteLine (theString: univ pStringPtr); tool ($0C, $1A);

procedure WriteString (theString: univ pStringPtr); tool ($0C, $1C);

implementation
end.
