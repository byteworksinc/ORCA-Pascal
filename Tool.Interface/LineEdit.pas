{$keep 'LineEdit'}
unit LineEdit;
interface

{********************************************************
*
*   Line Edit Tool Set Interface File
*
*   Other USES Files Needed: Common
*
*   Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                            Quick Draw II, Event Manager
*
*  Copyright 1987-1990, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Justification *)
   leJustLeft      =   $0000;      (* left justify       *)
   leJustCenter    =   $0001;      (* center             *)
   leJustRight     =   $FFFF;      (* right justify      *)
   leJustFill      =   $0002;      (* fill justification *)

   (* LEClassifyKey result values *)
   leKeyIsSpecial    = $8000;
   leKeyIsNumber     = $4000;
   leKeyIsHex        = $2000;
   leKeyIsAlpha      = $1000;
   leKeyIsNonControl = $0800;

type
   leRec = record
       leLineHandle: ^cStringPtr;
       leLength:     integer;
       leMaxLength:  integer;
       leDestRect:   rect;
       leViewRect:   rect;
       lePort:       grafPortPtr;
       leLineHite:   integer;
       leBaseHite:   integer;
       leSelStart:   integer;
       leSelEnd:     integer;
       leActFlag:    integer;
       leCarAct:     integer;
       leCarOn:      integer;
       leCarTime:    longint;
       leHiliteHook: procPtr;
       leCaretHook:  procPtr;
       leJust:       integer;
       lePWChar:     integer;
       end;
   leRecPtr = ^leRec;
   leRecHndl = ^leRecPtr;


procedure LEBootInit; tool ($14, $01); (* WARNING: an application should
                                                   NEVER make this call *)

procedure LEStartUp (userID, dPageAddr: integer); tool ($14, $02);

procedure LEShutDown; tool ($14, $03);

function LEVersion: integer; tool ($14, $04);

procedure LEReset; tool ($14, $05);    (* WARNING: an application should
                                                   NEVER make this call *)

function LEStatus: boolean; tool ($14, $06);

function GetLeDefProc: procPtr; tool ($14, $24);

procedure LEActivate (LEHandle: leRecHndl); tool ($14, $0F);

procedure LEClick (var theEvent: eventRecord; LEHandle: leRecHndl);
tool ($14, $0D);

procedure LECopy (LEHandle: leRecHndl); tool ($14, $13);

procedure LECut (LEHandle: leRecHndl); tool ($14, $12);

procedure LEDeactivate (LEHandle: leRecHndl); tool ($14, $10);

procedure LEDelete (LEHandle: leRecHndl); tool ($14, $15);

procedure LEDispose (LEHandle: leRecHndl); tool ($14, $0A);

procedure LEFromScrap; tool ($14, $19);

function LEGetScrapLen: integer; tool ($14, $1C);

function LEGetTextHand (LEHandle: leRecHndl): handle; tool ($14, $22);

function LEGetTextLen (LEHandle: leRecHndl): integer; tool ($14, $23);

procedure LEIdle (LEHandle: leRecHndl); tool ($14, $0C);

procedure LEInsert (theText: univ cStringPtr; textLength: integer;
                    LEHandle: leRecHndl); tool ($14, $16);

procedure LEKey (key, modifiers: integer; LEHandle: leRecHndl);
tool ($14, $11);

function LENew (var destRect, viewRect: rect; maxTextLen: integer): leRecHndl;
tool ($14, $09);

procedure LEPaste (LEHandle: leRecHndl); tool ($14, $14);

function LEScrapHandle: handle; tool ($14, $1B);

procedure LESetCaret (caretProc: procPtr; LEHandle: leRecHndl);
tool ($14, $1F);

procedure LESetHilite (hiliteProc: procPtr; LEHandle: leRecHndl);
tool ($14, $1E);

procedure LESetJust (just: integer; LEHandle: leRecHndl); tool ($14, $21);

procedure LESetScrapLen (newLength: integer); tool ($14, $1D);

procedure LESetSelect (selStart, selEnd: integer; LEHandle: leRecHndl);
tool ($14, $0E);

procedure LESetText (theText: univ cStringPtr; textLength: integer;
                     LEHandle: leRecHndl); tool ($14, $0B);

procedure LETextBox (theText: univ cStringPtr; textLength: integer;
                     var box: rect; just: integer); tool ($14, $18);

procedure LETextBox2 (theText: univ cStringPtr; textLength: integer;
                      var box: rect; just: integer); tool ($14, $20);

procedure LEToScrap; tool ($14, $1A);

procedure LEUpdate (LEHandle: leRecHndl); tool ($14, $17);

{new in 6.0.1}

function LEClassifyKey (eventPtr: eventRecord): integer; tool ($14, $25);

implementation
end.
