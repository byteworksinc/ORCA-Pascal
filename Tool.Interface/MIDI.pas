{$keep 'MIDI'}
unit MIDI;
interface

{********************************************************
*
*  MIDI Tool Set Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager;
*                           Sound Manager, Note Synthesizer,
*                           Note Sequencer (if using Synthesizer
*                           or Sequencer)
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

procedure MidiBootInit; tool ($20, $01);   (* WARNING: an application should
                                                       NEVER make this call *)

procedure MidiStartup (theUserID, directPageAddr: integer); tool ($20, $02);

procedure MidiShutdown; tool ($20, $03);

function MidiVersion: integer; tool ($20, $04);

procedure MidiReset; tool ($20, $05);      (* WARNING: an application should
                                                       NEVER make this call *)

function MidiStatus: boolean; tool ($20, $06);

procedure MidiClock (funcNum: integer; arg: longint); tool ($20, $0B);

procedure MidiControl (funcNum: integer; arg: longint); tool ($20, $09);

procedure MidiDevice (funcNum: integer; driverInfo: ptr); tool ($20, $0A);

function MidiInfo (funcNum: integer): longint; tool ($20, $0C);

function MidiReadPacket (bufPtr: ptr; bufSize: integer): integer;
tool ($20, $0D);

function MidiWritePacket (bufPtr: ptr): integer; tool ($20, $0E);

implementation
end.
