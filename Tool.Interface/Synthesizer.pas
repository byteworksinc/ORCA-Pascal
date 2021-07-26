{$keep 'Synthesizer'}
unit Synthesizer;
interface

(********************************************************
*
*   Note Synthesizer Tool Set Interface File
*
*   Other USES Files Needed:  Common
*
*   Other tool sets needed:  Sound Tool Set
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************)

uses
   Common;

 type
   waveForm = record
     topKey:      byte;
     waveAddress: byte;
     waveSize:    byte;
     DOCMode:     byte;
     relPitch:    integer;
     end;

   instrument = record
     envelope:          array [1..24] of byte;
     releaseSegment:    byte;
     priorityIncrement: byte;
     pitchBendRange:    byte;
     vibratoDepth:      byte;
     vibratoSpeed:      byte;
     spare:             byte;
     aWaveCount:        byte;
     bWaveCount:        byte;
     aWaveList:         array [1..1] of waveForm; (* aWaveCount * 6 bytes *)
     bWaveList:         array [1..1] of waveForm; (* bWaveCount * 6 bytes *)
     end;

   generatorControlBlock = record
       synthID:       byte;
       genNum:        byte;
       semitone:      byte;
       volume:        byte;
       pitchBend:     byte;
       vibratoDepth:  byte;
       reserved:      array [1..10] of byte;
       end;

procedure NSBootInit; tool ($19, $01);     (* WARNING: an application should
                                                       NEVER make this call *)

procedure NSStartUp (updateRate: integer; updateRtn: procPtr) ; tool ($19, $02);

procedure NSShutDown; tool ($19, $03);

function NSVersion: integer; tool ($19, $04);

procedure NSReset; tool ($19, $05);        (* WARNING: an application should
                                                       NEVER make this call *)

function NSStatus: boolean; tool ($19, $06);

procedure AllNotesOff; tool ($19, $0D);

function AllocGen (requestPriority: integer): integer; tool ($19, $09);

procedure DeallocGen (genNum: integer); tool ($19, $0A);

procedure NoteOff (genNum, semitone: integer); tool ($19, $0C);

procedure NoteOn (genNum, semitone, volume: integer;
                  var theInstrument: instrument); tool ($19, $0B);

function NSSetUpdateRate (newRate: integer): integer; tool ($19, $0E);

function NSSetUserUpdateRtn (newUpdateRtn: procPtr): procPtr; tool ($19, $0F);

implementation
end.
