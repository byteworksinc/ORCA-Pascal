{$keep 'MIDISynth'}
unit MIDISynth;
interface

{********************************************************
*
*  MIDISynth Tool Set Interface File
*
*  Other USES Files Needed:  Common
*
*  Copyright 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
					{Error Codes}
   msAlreadyStarted = $2301;		{MidiSynth already started.}
   msNotStarted = $2302;		{MidiSynth never started.}
   msNoDPMem = $2303;			{Can't get direct page memory.}
   msNoMemBlock = $2304;		{Can't get memory block.}
   msNoMiscTool = $2305;		{Misc Tools not started.}
   msNoSoundTool = $2306;		{Sound Tools not started.}
   msGenInUse = $2307;			{Ensoniq generator in use.}
   msBadPortNum = $2308;		{Illegal port number.}
   msPortBusy = $2309;			{Port is busy.}
   msParamRangeErr = $230a;		{Parameter range error.}
   msMsgQueueFull = $230b;		{Message queue full.}
   msRecBufFull = $230c;		{Rec buffer is full.}
   msOutputDisabled = $230d;		{MIDI output disabled.}
   msMessageError = $230e;		{Message error.}
   msOutputBufFull = $230f;		{MIDI output buffer is full.}
   msDriverNotStarted = $2310;		{Driver not started.}
   msDriverAlreadySet = $2311;		{Driver already set.}
   msDevNotAvail = $2380;		{the requested device is not available}
   msDevSlotBusy = $2381;		{requested slot is already in use}
   msDevBusy = $2382;			{the requested device is already in use}
   msDevOverrun = $2383;		{device overrun by incoming MIDI data}
   msDevNoConnect = $2384;		{no connection to MIDI}
   msDevReadErr = $2385;		{framing error in received MIDI data}
   msDevVersion = $2386;		{ROM version is incompatible with device driver}
   msDevIntHndlr = $2387;		{conflicting interrupt handler is installed}

type
   msDirectPageHndl = ^msDirectPagePtr;
   msDirectPagePtr = ^msDirectPage;
   msDirectPage = record
      reserved1: array [0..11] of byte;
      mpacketStat: integer;
      mpacketData1: integer;
      mpacketData2: integer;
      seqClockFrac: byte;
      seqClockInt: longint;
      reserved2: array [$17..$30] of byte;
      seqItemStat: byte;
      seqItemData1: byte;
      seqItemData2: byte;
      reserved3: array [$34..$3E] of byte;
      metroVol: byte;
      reserved4: array [$40..$E3] of byte;
      metroFreq: byte;
      reserved5: array [$E6..$E9] of byte;
      seqItemTrack: byte;
      reserved6: byte;
      packetBytes: byte;
      reserved7: array [$ED..$100] of byte;
      end;

   getMSDataOutputRecHndl = ^getMSDataOutputRecPtr;
   getMSDataOutputRecPtr = ^getMSDataOutputRec;
   getMSDataOutputRec = record
      directPage: msDirectPagePtr;
      reserved: longint;
      end;

   measureRecHndl = ^measureRecPtr;
   measureRecPtr = ^measureRec;
   measureRec = record
      measureNumber: integer;
      beatNumber: integer;
      msRemainder: integer;
      end;

   callBackRecHndl = ^callBackRecPtr;
   callBackRecPtr = ^callBackRec;
   callBackRec = record
      endSeq: procPtr;
      userMeter: procPtr;
      mstart: procPtr;
      mstop: procPtr;
      packetIn: procPtr;
      seqEvent: procPtr;
      sysEx: procPtr;
      packetOut: procPtr;
      pgmChange: procPtr;
      mContinue: procPtr;
      sMarker: procPtr;
      recBufFull: procPtr;
      reserved1: procPtr;
      reserved2: procPtr;
      end;

   seqPlayRecHndl = ^seqPlayRecPtr;
   seqPlayRecPtr = ^seqPlayRec;
   seqPlayRec = record
      pBufStart: ptr;
      reserved: longint;
      rBufStart: ptr;
      rBufEnd: ptr;
      seqFlags: integer;
      theClock: longint;
      end;

   envelopeRecHndl = ^envelopeRecPtr;
   envelopeRecPtr = ^envelopeRec;
   envelopeRec = record
      attackLevel: byte;
      attackRate: byte;
      decay1Level: byte;
      decay1Rate: byte;
      decay2Level: byte;
      decay2Rate: byte;
      sustainLevel: byte;
      decay3Rate: byte;
      release1Level: byte;
      release1Rate: byte;
      release2Level: byte;
      release2Rate: byte;
      release3Rate: byte;
      decayGain: byte;
      velocityGain: byte;
      pitchBendRange: byte;
      end;

   wavelistRecHndl = ^wavelistRecPtr;
   wavelistRecPtr = ^wavelistRec;
   wavelistRec = record
      topKey: byte;
      oscConfig: byte;
      stereo: byte;
      detune: byte;
      waveAddrA: byte;
      waveSizeA: byte;
      volumeA: byte;
      octaveA: byte;
      semitoneA: byte;
      findTuneA: byte;
      wavAddrB: byte;
      waveSizeB: byte;
      volumeB: byte;
      octaveB: byte;
      semitoneB: byte;
      fineTuneB: byte;
      end;

   instrumentRecHndl = ^instrumentRecPtr;
   instrumentRecPtr = ^instrumentRec;
   instrumentRec = record
      gen1EnvRec: envelopeRec;
      gen1WaveRecs: array[1..8] of wavelistRec;
      gen2EnvRec: envelopeRec;
      gen2WaveRecs: array [1..8] of wavelistRec;
      end;

   seqItemRecHndl = ^seqItemRecPtr;
   seqItemRecPtr = ^seqItemRec;
   seqItemRec = record
      trackNum: byte;
      timeStampHigh: byte;
      timeStampLow: byte;
      timeStampMid: byte;
      dataByteCount: byte;
      MIDIStat: byte;
      dataByte1: byte;
      dataByte2: byte;
      end;

procedure MSBootInit; tool ($23, $01);
procedure MSStartUp; tool ($23, $02);
procedure MSShutDown; tool ($23, $03);
function MSVersion: integer; tool ($23, $04);
procedure MSReset; tool ($23, $05);
function MSStatus: Boolean; tool ($23, $06);

{ This call cannot be made from ORCA/Pascal
function ConvertToMeasure (ticksPerBeat, beats: integer; seqClockTics: longint):
   MeasureRec; tool ($23, $21);
}

function ConvertToTime (ticksPerBeat, beats, beatNum, measure: integer): longint;
   tool ($23, $20);
procedure DeleteTrack (trackNum: integer; sequence: ptr); tool ($23, $1D);

{ This call cannot be made from ORCA/Pascal
function GetMSData: getMSDataOutputRec; tool ($23, $1F);
}

procedure GetTuningTable (table: ptr); tool ($23, $25);
procedure InitMIDIDriver (slot, internal, userID: integer; driver: procPtr);
   tool ($23, $27);
procedure KillAllNotes; tool ($23, $0D);
function Locate (timeStamp: longint; seqBuffer: ptr): seqItemRecPtr;
   tool ($23, $11);
function LocateEnd (seqBuffer: ptr): ptr; tool ($23, $1B);
procedure Merge (buffer1, buffer2: ptr); tool ($23, $1C);
procedure MIDIMessage (destination, numBytes, message, dataByte1,
   dataByte2: integer); tool ($23, $1A);
procedure MSResume; tool ($23, $23);
procedure MSSuspend; tool ($23, $22);
procedure PlayNote (channel, noteNum, volume: integer); tool ($23, $0B);
procedure RemoveMIDIDriver; tool ($23, $28);
procedure SeqPlayer (var sequence: seqPlayRec); tool ($23, $15);
procedure SetBasicChannel (channel: integer); tool ($23, $09);
procedure SetBeat (duration: integer); tool ($23, $19);
procedure SetCallBack (var buffer: callBackRec); tool ($23, $17);
procedure SetInstrument (inst: instrumentRecPtr; number: integer);
   tool ($23, $14);
procedure SetMetro (volume, frequency: integer; wave: ptr); tool ($23, $1E);
procedure SetMIDIMode (mode: integer); tool ($23, $0A);
procedure SetMIDIPort (inputDisable, outputDisable: integer); tool ($23, $13);
procedure SetPlayTrack (trackNum, playState: integer); tool ($23, $0F);
procedure SetRecTrack (trackNum: integer); tool ($23, $0E);
procedure SetTempo (tempo: integer); tool ($23, $16);
procedure SetTrackOut (trackNum, path: integer); tool ($23, $26);
procedure SetTuningTable (table: ptr); tool ($23, $24);
procedure SetVelComp (velocity: integer); tool ($23, $24);
procedure StopNote (channel, noteNum: integer); tool ($23, $0C);
procedure SysExOut (message: ptr; delay: integer; monitor: procPtr);
   tool ($23, $18);
procedure TrackToChannel (trackNum, channel: integer); tool ($23, $10);

implementation

end.
