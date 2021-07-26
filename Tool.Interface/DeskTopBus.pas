{$keep 'DeskTopBus'}
unit DeskTopBus;
interface

{********************************************************
*
*  Desktop Bus Tool Set Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed: Tool Locator, Memory Manager
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   readModes       =   $000A;      (* read modes of ADB command          *)
   readConfig      =   $000B;      (* read configuration of ADB command  *)
   readADBError    =   $000C;      (* read ADB error byte of ADB command *)
   readVersionNum  =   $000D;      (* read version number of ADB command *)
   readAvailCharSet =  $000E;      (* read available character sets      *)
   readAvailLayout =   $000F;      (* read available keyboard layouts    *)

   readMicroMem    =   $0009;      (* read data byte from kybd controller *)

   abort           =   $0001;      (* abort; no operation            *)
   resetKbd        =   $0002;      (* reset keyboard microcontroller *)
   flushKbd        =   $0003;      (* flush keyboard                 *)
   setModes        =   $0004;      (* set modes                      *)
   clearModes      =   $0005;      (* clear modes                    *)
   setConfig       =   $0006;      (* set configuration              *)
   synch           =   $0007;      (* synch                          *)
   writeMicroMem   =   $0008;      (* write microcontroller memory   *)
   resetSys        =   $0010;      (* reset system                   *)
   keyCode         =   $0011;      (* send ADB key code              *)
   resetADB        =   $0040;      (* reset ADB                      *)
   transmitADBBytes =  $0047;      (* transmit ADB bytes             *)
   enableSRQ       =   $0050;      (* enable SRQ                     *)
   flushADBDevBuf  =   $0060;      (* flush buffer on ADB device     *)
   disableSRQ      =   $0070;      (* disable SRQ                    *)
   transmit2ADBBytes = $0080;      (* transmit 2 ADB bytes           *)
   listen          =   $0080;      (* ADB listen command             *)
   talk            =   $00C0;      (* ADB talk command               *)

type
   readConfigRec = record
       rcADBAddr:      byte;
       rcLayoutOrLang: byte;
       rcRepeatDelay:  byte;
       end;

   setConfigRec = record
       scADBAddr:      byte;
       scLayoutOrLang: byte;
       scRepeatDelay:  byte;
       end;

   synchRec = record
       synchMode:          byte;
       synchKybdMouseAddr: byte;
       synchLayoutOrLang:  byte;
       synchRepeatDelay:   byte;
       end;

   scaleRec = record
       xDivide:   integer;
       yDivide:   integer;
       xOffset:   integer;
       yOffset:   integer;
       xMultiply: integer;
       yMultiply: integer;
       end;


procedure ADBBootInit; tool ($09, $01);    (* WARNING:  an application should
                                                        NEVER make this call *)

procedure ADBStartUp; tool ($09, $02);

procedure ADBShutDown; tool ($09, $03);

function ADBVersion: integer; tool ($09, $04);

procedure ADBReset; tool ($09, $05);    (* WARNING: an application should NEVER
                                                    NEVER make this call *)

function ADBStatus: boolean; tool ($09, $06);

procedure AbsON; tool ($09, $0F);

procedure AbsOFF; tool ($09, $10);

procedure AsyncADBReceive (compPtr: procPtr; adbCommand: integer);
tool ($09, $0D);

procedure ClearSRQTable; tool ($09, $16);

procedure GetAbsScale (var dataInPtr: scaleRec); tool ($09, $13);

function ReadAbs: boolean; tool ($09, $11);

procedure ReadKeyMicroData (dataLength: integer; dataPtr: ptr;
                            adbCommand: integer); tool ($09, $0A);

procedure ReadKeyMicroMemory (dataOutPtr, dataInPtr: ptr;
                              adbCommand: integer); tool ($09, $0B);

procedure SendInfo (dataLength: integer; dataPtr: ptr; adbCommand: integer);
tool ($09, $09);

procedure SetAbsScale (var dataOutPtr: scaleRec); tool ($09, $12);

procedure SRQPoll (compPtr: procPtr; adbRegAddr: integer); tool ($09, $14);

procedure SRQRemove (adbRegAddr: integer); tool ($09, $15);

procedure SyncADBReceive (inputWord: integer; compPtr: procPtr;
                          adbCommand: integer); tool ($09, $0E);

implementation

end.
