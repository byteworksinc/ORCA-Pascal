{$keep 'Sequencer'}
unit Sequencer;
interface

{********************************************************
*
*  Note Sequencer Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

procedure SeqBootInit; tool ($1A, $01);   (* WARNING: an application should
                                                      NEVER make this call *)

procedure SeqStartup (dPageAddr, mode, updateRate, increment: integer);
tool ($1A, $02);

procedure SeqShutdown; tool ($1A, $03);

function SeqVersion: integer; tool ($1A, $04);

procedure SeqReset; tool ($1A, $05);      (* WARNING: an application should
                                                      NEVER make this call *)

function SeqStatus: boolean; tool ($1A, $06);

function ClearIncr: integer; tool ($1A, $0A);

(* The function GetLoc returns 3 words:            *)
(*     curPhraseItem, curPattItem, and curLevel    *)
(* function GetLoc: 3 words; tool ($1A, $0C);      *)

function GetTimer: integer; tool ($1A, $0B);

procedure SeqAllNotesOff; tool ($1A, $0D);

procedure SetIncr (increment: integer); tool ($1A, $09);

procedure SetInstTable (instTable: handle); tool ($1A, $12);

procedure SetTrkInfo (priority, instIndex, trackNum: integer); tool ($1A, $0E);

procedure StartInts; tool ($1A, $13);

procedure StartSeq (errHndlrRoutine, compRoutine: procPtr; sequence: univ handle);
tool ($1A, $0F);

procedure StartSeqRel (errHndlrRtn, compRtn: procPtr; sequence: univ handle);
tool ($1A, $15);

procedure StepSeq; tool ($1A, $10);

procedure StopInts; tool ($1A, $14);

procedure StopSeq (next: boolean); tool ($1A, $11);

implementation
end.
