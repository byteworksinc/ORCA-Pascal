{$keep 'ToolLocator'}
unit ToolLocator;
interface

{********************************************************
*
*  Tool Locator Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  - None -
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* MessageCenter action codes *)
   addMessage  =   1;          (* add message to msg center data *)
   getMessage  =   2;          (* return message from msg center *)
   deleteMessage = 3;          (* delete message from msg center *)


type
   (* Table of tools to load from the TOOLS directory in the SYSTEM folder *)
   toolSpec = record
       toolNumber: integer;
       minVersion: integer;
       end;

   (* Change array size for your application. *)
   ttArray = array [1..20] of toolSpec;
    
   toolTable = record
       numToolsRequired:  integer;
       tool:              ttArray;
       end;

   startStopRecord = record
       flags:        integer;
       videoMode:    integer;
       resFileID:    integer;
       DPageHandle:  handle;
       numTools:     integer;
       toolArray:    ttArray;
       end;
   startStopRecordPtr = ^startStopRecord;
      
   (* Function pointer table *)
   FPT = record
       count: longint;          (* number of functions plus 1             *)
       addr1: ptr;              (* ptr to BootInit routine minus 1        *)
       addr2: ptr;              (* ptr to StartUp routine minus 1         *)
       addr3: ptr;              (* ptr to ShutDown routine minus 1        *)
       addr4: ptr;              (* ptr to Version routine minus 1         *)
       addr5: ptr;              (* ptr to Reset routine minus 1           *)
       addr6: ptr;              (* ptr to Status routine minus 1          *)
       addr7: ptr;              (* ptr to reserved routine minus 1        *)
       addr8: ptr;              (* ptr to reserved routine minus 1        *)
       addr9: ptr;              (* ptr to 1st nonrequired routine minus 1 *)
   (* Other pointers to additional nonrequired routines, each minus 1     *)
       addr: array [1..50] of ptr;
       end;

   messageRecord = record
       blockLength: integer;
       IDstring:    pString;   (* may be a max of 64 chars long *)
   (* Change length of array to suit application. *)
       dataBlock:   packed array [1..1] of byte;
       end;


procedure TLBootInit; tool ($01, $01);     (* WARNING: an application should
                                                       NEVER make this call *)

procedure TLStartup; tool ($01, $02);

procedure TLShutDown; tool ($01, $03);

function TLVersion: integer; tool ($01, $04);

procedure TLReset; tool ($01, $05);        (* WARNING: an application should
                                                       NEVER make this call *)

function TLStatus: boolean; tool ($01, $06);

procedure AcceptRequests (nameString: pString; userID: integer;
   requestProc: ptr); tool ($01, $1B);

function GetFuncPtr (userOrSystem: integer; funcNum_TSNum: integer): longint;
tool ($01, $0B);

function GetMsgHandle (flags: integer; messageRef: univ longint): longint;
tool ($01, $1A);

function GetTSPtr (userOrSystem, tsNum: integer): longint; tool ($01, $09);

function GetWAP (userOrSystem, tsNum: integer): longint; tool ($01, $0C);

procedure LoadOneTool (toolNumber, minVersion: integer); tool ($01, $0F);

procedure LoadTools (var theToolTable: toolTable); tool ($01, $0E);

(* MessageByName returns two words:  lo word = message number  *)
(*                                   hi word = boolean flag    *)
function MessageByName (createItFlag: boolean; var inputRecord: messageRecord):
                        longint; tool ($01, $17);

procedure MessageCenter (action, msgID: integer; messageHandle: handle);
tool ($01, $15);

procedure RestoreTextState (stateHandle: handle); tool ($01, $14);

function SaveTextState: handle; tool ($01, $13);

procedure SendRequest (reqCode, sendHow: integer; target, dataIn: univ longint;
   dataOut: ptr); tool ($01, $1C);

procedure SetDefaultTPT; tool ($01, $16);  (* WARNING: an application should
                                                       NEVER make this call *)

procedure SetTSPtr (userOrSystem, tsNum: integer; theFPT: FPT);
tool ($01, $0A);

procedure SetWAP (userOrSystem, tsNum: integer; waptPtr: ptr);
tool ($01, $0D);

procedure ShutDownTools (startStopVerb: integer;
                         startStopRecRef: univ longint); tool ($01, $19);

function StartupTools (myID, startStopVerb: integer;
                       startStopRecRef: univ longint): longint;
tool ($01, $18);
 
function TLMountVolume (whereX, whereY: integer; line1Ptr, line2Ptr,
                        but1Ptr, but2Ptr: pStringPtr): integer; tool ($01, $11);

function TLTextMountVolume (line1Ptr, line2Ptr, button1Ptr, button2Ptr:
                            pStringPtr): integer; tool ($01, $12);

procedure UnloadOneTool (toolNumber: integer); tool ($01, $10);

implementation
end.
