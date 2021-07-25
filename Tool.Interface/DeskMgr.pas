{$keep 'DeskMgr'}
unit DeskMgr;
interface

{********************************************************
*
*   Desk Manager Interface File
*
*   Other USES Files Needed:  Common
*
*   Other Tool Sets Needed:   Tool Locator, Memory Manager,
*                             Miscellaneous Tool Set, Quick Draw II,
*                             Event Manager, Window Manager, Menu Manager,
*                             Control Manager, LineEdit Tool Set,
*                             Dialog Manager, Scrap Manager
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* NDA action codes *)
   eventAction     =   $0001;      (* code for event to be handled by NDA  *)
   runAction       =   $0002;      (* code passed when time period elapsed *)
   cursorAction    =   $0003;      (* code if NDA is frontmost window      *)
   undoAction      =   $0005;      (* code when user selects Undo          *)
   cutAction       =   $0006;      (* code when user selects Cut           *)
   copyAction      =   $0007;      (* code when user selects Copy          *)
   pasteAction     =   $0008;      (* code when user selects Paste         *)
   clearAction     =   $0009;      (* code when user selects Clear         *)

   (* edit types *)
   undoEdit        =   $0001;      (* Undo edit type  *)
   cutEdit         =   $0002;      (* Cut edit type   *)
   copyEdit        =   $0003;      (* Copy edit type  *)
   pasteEdit       =   $0004;      (* Paste edit type *)
   clearEdit       =   $0005;      (* Clear edit type *)


type
   CDA_ID = record
       DAName:     pString;
       DAstart:    procPtr;
       DAShutDown: procPtr;
       end;
   CDA_IDPtr = ^CDA_ID;
   CDA_IDHandle = ^CDA_IDPtr;

   NDA_ID = record
       openRtn:   procPtr;
       closeRtn:  procPtr;
       actionRtn: procPtr;
       initRtn:   procPtr;
       period:    integer;
       eventMask: integer;
       menuText:  cString;
       end;
   NDA_IDPtr = ^NDA_ID;
   NDA_IDHandle = ^NDA_IDPtr;

   stringTable = record
       titleStr:   cStringPtr;
       controlStr: cStringPtr;
       quitStr:    cStringPtr;
       selectStr:  cStringPtr;
       end;
   stringTblPtr = ^stringTable;

   runItem = record
       reserved:  longint;
       period:    integer;
       signature: integer;
       reserved2: longint;
       end;
   runItemPtr = ^runItem;
         
        
procedure DeskBootInit; tool ($05, $01);   (* WARNING: an application should
                                                       NEVER make this call *)

procedure DeskStartUp; tool ($05, $02);

procedure DeskShutDown; tool ($05, $03);

function DeskVersion: integer; tool ($05, $04);

procedure DeskReset; tool ($05, $05);  (* WARNING: an application should NEVER
                                                   make this call *)

function DeskStatus: boolean; tool ($05, $06);

procedure AddToRunQ (header: runItemPtr); tool ($05, $1F);

procedure CallDeskAcc (flags: integer; daReference: univ longint;
   action: integer; bufferPtr: longint); tool ($05, $24);

procedure ChooseCDA; tool ($05, $11);  (* WARNING: an application should NEVER
                                                   make this call *)

procedure CloseAllNDAs; tool ($05, $1D);

procedure CloseNDA (refNum: integer); tool ($05, $16);

procedure CloseNDAbyWinPtr (theWindow: grafPortPtr); tool ($05, $1C);

procedure FixAppleMenu (menuID: integer); tool ($05, $1E);

procedure GetDeskAccInfo (flags: integer; daReference: univ longint;
   buffSize: integer; bufferPtr: ptr); tool ($05, $23);

function GetDeskGlobal (selector: integer): longint; tool ($05, $25);

function GetDAStrPtr: stringTblPtr; tool ($05, $14);

function GetNumNDAs: integer; tool ($05, $1B);

procedure InstallCDA (IDHandle: handle); tool ($05, $0F);

procedure InstallNDA (IDHandle: NDA_IDHandle); tool ($05, $0E);

function OpenNDA (DAIDNumber: integer): integer; tool ($05, $15);

procedure RemoveFromRunQ (header: runItemPtr); tool ($05, $20);

procedure RemoveCDA (IDHandle: CDA_IDHandle); tool ($05, $21);

procedure RemoveNDA (IDHandle: NDA_IDHandle); tool ($05, $22);

procedure RestAll; tool ($05, $0C);    (* WARNING: an application should NEVER
                                                   make this call *)

procedure RestScrn; tool ($05, $0A);   (* WARNING: an application should NEVER
                                                   make this call *)

procedure SaveAll; tool ($05, $0B);    (* WARNING: an application should
                                                   NEVER make this call *)

procedure SaveScrn; tool ($05, $09);   (* WARNING: an application should
                                                   NEVER make this call *)

procedure SetDAStrPtr (altDispHandle: handle; newStrings: stringTblPtr);
tool ($05, $13);

procedure SystemClick (var theEvent: eventRecord; theWindow: grafPortPtr;
                       findWindowResult: integer); tool ($05, $17);

function SystemEdit (editType: integer): boolean; tool ($05, $18);

function SystemEvent (eventWhat: integer; eventMessage, eventWhen, eventWhere:
                      longint; eventMods: integer): boolean; tool ($05, $1A);

procedure SystemTask; tool ($05, $19);

implementation
end.
