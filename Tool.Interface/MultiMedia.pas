{$keep 'MultiMedia'}
unit MultiMedia;
interface

{********************************************************
*
*  MultiMedia Sequence Editor, Scheduler
*
*  Other USES Files Needed:  Common
*
*  Other Tool Sets Needed:   Tool Locator
*
*  Copyright 1992, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   inChapters = 1;
   inFrames = 2;
   inTimes = 3;

   mcCInit = 1;                         {control values for MCControl}
   mcCEject = 2;
   mcCVideoOn = 3;
   mcCVideoOff = 4;
   mcCDisplayOn = 5;
   mcCDisplayOff = 6;
   mcCBlankVideo = 7;
   mcCDefaultCom = 8;
   mcCLockDev = 9;
   mcCUnLockDev = 10;

   mcC8Data1Stop = 40;
   mcC7Data1Stop = 41;
   mcC6Data1Stop = 42;
   mcC5Data1Stop = 43;
   mcC8Data2Stop = 44;
   mcC7Data2Stop = 45;
   mcC6Data2Stop = 46;
   mcC5Data2Stop = 47;
   
   mcCBaudDflt = 50;

   mcCBaud50 = 51;
   mcCBaud75 = 52;
   mcCBaud110 = 53;
   mcCBaud134 = 54;
   mcCBaud150 = 55;
   mcCBaud300 = 56;
   mcCBaud600 = 57;
   mcCBaud1200 = 58;
   mcCBaud1800 = 59;
   mcCBaud2400 = 60;
   mcCBaud3600 = 61;
   mcCBaud4800 = 62;
   mcCBaud7200 = 63;
   mcCBaud9600 = 64;
   mcCBaud19200 = 65;

   mcCModem = 100;
   mcCPrinter = 101;

   mcCIgnoreDS = 200;
   mcCReportDS = 201;

   mcFTypes = 0;                        {status values for MCGetFeatures}
   mcFStep = 1;
   mcFRecord = 2;
   mcFVideo = 3;
   mcFEject = 4;
   mcFLock = 5;
   mcFVDisplay = 6;
   mcFVOverlay = 7;
   mcFVOChars = 8;
   mcFVolume = 9;

   mcSUnknown = 0;                      {status values for MCGetStatus}
   mcSDeviceType = $0000;
   mcSLaserDisc = 1;
   mcSCDAudio = 2;
   mcSCDLaserCD = 3;
   mcSVCR = 4;
   mcSCamCorder = 5;
   mcSPlayStatus = $0001;
   mcSPlaying = 1;
   mcSStill = 2;
   mcSParked = 3;
   mcSDoorStatus = $0002;
   mcSDoorOpen = 1;
   mcSDoorClosed = 2;
   mcSDiscType = $0003;
   mcS_CLV = 1;
   mcS_CAV = 2;
   mcS_CDV = 3;
   mcS_CD = 4;
   mcSDiscSize = $0004;
   mcSDisc3inch = 3;
   mcSDisk5inch = 5;
   mcSDisk8inch = 8;
   mcSDisk12inch = 12;
   mcSDiskSide = $0005;
   mcSSideOne = 1;
   mcSSideTwo = 2;
   mcSVolumeL = $0006;
   mcSVolumeR = $0007;

   mcElapsedTrack = 0;                  {MCGetTimes selector values}
   mcRemainTrack = 1;
   mcElapsedDisc = 2;
   mcRemainDisc = 3;
   mcTotalDisc = 4;

   mcTotalFrames = 5;
   mcTracks = 6;
   mcDiscID = 7;
   
   AudioOff = 0;                        {Audio values}
   AudioRight = 1;
   AudioLinR = 2;
   AudioMinR = 3;
   AudioRinL = 4;
   AudioRinLR = 5;
   AudioReverse = 6;
   AudioRinLMR = 7;
   AudioLeft = 8;
   AudioSterio = 9;
   AudioLinLR = 10;
   AudioLinLMR = 11;
   AudioMinL = 12;
   AudioMinLRinR = 13;
   AudioMonLLinR = 14;
   AudioMonaural = 15;
           
procedure MCBootInit; tool ($26, $01);

procedure MCStartUp (userID: integer); tool ($26, $02);

procedure MCShutDown; tool ($26, $03);

function MCVersion: integer; tool ($26, $04);

procedure MCReset; tool ($26, $05);

function MCStatus: boolean; tool ($26, $06);

procedure MCLoadDriver (mcChannelNo: integer); tool ($26, $0A);

procedure MCUnLoadDriver (mcChannelNo: integer); tool ($26, $0B);

procedure MCDStartUp (mcChannelNo: integer; portnameptr: pString;
                       drvrUserID: integer); tool ($26, $14);

procedure MCDShutDown (mcChannelNo: integer); tool ($26, $15);

function MCBinToTime (mcBinVal: longint): longint; tool ($26, $0D);

procedure MCControl (mcChannelNo, ctlcommand: integer); tool ($26, $1B);

function MCGetDiscID (mcChannelNo: integer): longint; tool ($26, $28);

procedure MCGetDicTitle (mcDiscID: longint; var PStrPtr: pString);
   tool ($26, $12);

function MCGetDiscTOC (mcChannelNo, mcTrackNo: integer): longint;
   tool ($26, $27);

procedure MCGetErrorMsg (mcErrorNo: integer; var PStrPtr: pString);
   tool ($26, $09);

function MCGetFeatures (mcChannelNo, mcFeatSel: integer): longint;
   tool ($26, $16);

procedure MCGetName (mcChannelNo: integer; var PStrPtr: pString);
   tool ($26, $2D);

function MCGetNoTracks (mcChannelNo: integer): integer; tool ($26, $29);

function MCGetPosition (mcChannelNo, mcUnitType: integer): longint;
   tool ($26, $24);

procedure MCGetProgram (mcDiscID: longint; var PStrPtr: pString);
   tool ($26, $10);

procedure MCGetSpeeds (mcChannelNo: integer; var PStrPtr: pString);
   tool ($26, $1D);

function MCGetStatus (mcChannelNo, mcStatusSel: integer): integer;
   tool ($26, $1A);

function MCGetTimes (mcChannelNo, mcTimeSel: integer): longint; tool ($26, $26);

procedure MCGetTrackTitle (mcDiscID: longint; mcTrackNo: integer;
   var PStrPtr: pString); tool ($26, $0E);

procedure MCJog (mcChannelNo, mcUnitType: integer; mcNJog: longint;
   mcJogRepeat: integer); tool ($26, $20);

procedure MCPause (mcChannelNo: integer); tool ($26, $18);

procedure MCPlay (mcChannelNo: integer); tool ($26, $17);

procedure MCRecord (mcChannelNo: integer); tool ($26, $2A);

procedure MCSetAudio (mcChannelNo, mcAudioCtl: integer); tool ($26, $25);

procedure MCSetVolume (mcChannelNo, mcLeftVol, mcRightVol: integer);
   tool ($26, $2E);

procedure MCScan (mcChannelNo, mcDirection: integer); tool ($26, $1C);

function MCSearchDone (mcChannelNo: integer): boolean; tool ($26, $22);

procedure MCSearchTo (mcChannelNo, mcUnitType: integer; searchLoc: longint);
   tool ($26, $21);

procedure MCSearchWait (mcChannelNo: integer); tool ($26, $23);

procedure MCSendRawData (mcChannelNo: integer; mcNativePtr: gsosInString);
   tool ($26, $19);

procedure MCSetDiscTitle (mcDiscID: longint; titlePtr: pString);
   tool ($26, $13);

procedure MCSetProgram (mcDiscID: longint; titlePtr: gsosInString);
   tool ($26, $11);

procedure MCSetTrackTitle (mcDiscID: longint; trackNum: integer;
   titlePtr: pString); tool ($26, $0F);

procedure MCSpeed (mcChannelNo, mcFPS: integer); tool ($26, $1E);

procedure MCStop (mcChannelNo: integer); tool ($26, $2B);

procedure MCStopAt (mcChannelNo, mcUnitType: integer; mcStopLoc: longint);
   tool ($26, $1F);

function MCTimeToBin (mcTimeValue: longint): longint; tool ($26, $0C);

procedure MCWaitRawData (mcChannelNo: integer; var result: gsosOutString;
   tickwait, term_mask: integer); tool ($26, $2C);

implementation                       
end.
