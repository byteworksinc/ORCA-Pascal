{$keep 'SoundMgr'}
unit SoundMgr;
interface

{********************************************************
*
*  Sound Manager Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Channel-generator-type word *)
   ffSynthMode     =   $0001;      (* free-form synthesizer mode *)
   noteSynthMode   =   $0002;      (* note synthesizer mode      *)

   (* Stop-sound mask *)
   gen0off         =   $0001;
   gen1off         =   $0002;
   gen2off         =   $0004;
   gen3off         =   $0008;
   gen4off         =   $0010;
   gen5off         =   $0020;
   gen6off         =   $0040;
   gen7off         =   $0080;
   gen8off         =   $0100;
   gen9off         =   $0200;
   gen10off        =   $0400;
   gen11off        =   $0800;
   gen12off        =   $1000;
   gen13off        =   $2000;
   gen14off        =   $4000;

(* Generator status word *)
   genAvail        =   $0000;
   ffSynth         =   $0100;
   noteSynth       =   $0200;
   lastBlock       =   $8000;


type
   soundPBPtr = ^soundParamBlock;
   soundParamBlock = record
       waveStart:     ptr;                 (* starting address of wave    *)
       waveSize:      integer;             (* waveform size in pages      *)
       freqOffset:    integer;             (* waveform playback frequency *)
       DOCBuffer:     integer;             (* DOC buffer starting address *)
       DOCBufferSize: integer;             (* DOC buffer size code        *)
       nextWAddr:     soundPBPtr;          (* ptr to next waveform block  *)
       volSetting:    integer;             (* DOC volume setting          *)
       end;

   DOCRegParamBlk = record
       oscGenType:  integer;
       freqLow1:    byte;                  (* 1st oscillator's parameters *)
       freqHigh1:   byte;
       vol1:        byte;
       tablePtr1:   byte;
       control1:    byte;
       tableSize1:  byte;
       freqLow2:    byte;                  (* 2nd oscillator's parameters *)
       freqHigh2:   byte;
       vol2:        byte;
       tablePtr2:   byte;
       control2:    byte;
       tableSize2:  byte;
       end;


procedure SoundBootInit; tool ($08, $01);  (* WARNING: an application should
                                                       NEVER make this call *)

procedure SoundStartUp (WAP: integer); tool ($08, $02);

procedure SoundShutDown; tool ($08, $03);

function SoundVersion: integer; tool ($08, $04);

procedure SoundReset; tool ($08, $05);     (* WARNING: an application should
                                                       NEVER make this call *)

function SoundToolStatus: boolean; tool ($08, $06);

procedure FFSetUpSound (channelGen: integer;
                        var paramBlockPtr: soundParamBlock); tool ($08, $15);

function FFGeneratorStatus (genNumber: integer): integer;
tool ($08, $11);

function FFSoundDoneStatus (genNumber: integer): boolean; tool ($08, $14);

function FFSoundStatus: integer; tool ($08, $10);

procedure FFStartPlaying (genWord: integer); tool ($08, $16);

procedure FFStartSound (genNumFFSynth: integer; var PBlockPtr: soundParamBlock);
tool ($08, $0E);

procedure FFStopSound (genMask: integer); tool ($08, $0F);

function GetSoundVolume (genNumber: integer): integer; tool ($08, $0C);

function GetTableAddress: longint; tool ($08, $0B);

procedure ReadDOCReg (var DOCregParamBlkPtr: DOCregParamBlk); tool ($08, $18);

procedure ReadRamBlock (destPtr: ptr; DOCStart, byteCount: integer);
tool ($08, $0A);

procedure SetDOCReg (var DOCRegParamBlock: DOCRegParamBlk); tool ($08, $17);

procedure SetSoundMIRQV (sMasterIRQ: longint); tool ($08, $12);

procedure SetSoundVolume (volume, genNumber: integer); tool ($08, $0D);

function SetUserSoundIRQV (userIRQVector: longint): longint; tool ($08, $13);

procedure WriteRamBlock (srcPtr: ptr; DOCStart, byteCount: integer);
tool ($08, $09);

implementation
end.
