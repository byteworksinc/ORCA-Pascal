{$keep 'Scheduler'}
unit Scheduler;
interface

{********************************************************
*
*  Scheduler Tool Set Interface File
*
*  Other USES Files Needed:  Common
*
*  Other Tool Sets Needed:   Tool Locator
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;


procedure SchBootInit; tool ($07, $01);    (* WARNING: an application should
                                                       NEVER make this call *)

procedure SchStartup; tool ($07, $02);

procedure SchShutDown; tool ($07, $03);

function SchVersion: integer; tool ($07, $04);

procedure SchReset; tool ($07, $05);       (* WARNING: an application should
                                                       NEVER make this call *)

function SchStatus: boolean; tool ($07, $06);

function SchAddTask (theTask: procPtr): integer; tool ($07, $09);

procedure SchFlush; tool ($07, $0A);       (* WARNING: an application should
                                                       NEVER make this call *)


implementation

end.
