{$keep 'PrintMgr'}
unit PrintMgr;
interface

{********************************************************
*
*  Print Manager Interface File
*
*  Other USES Files Needed:  Common
*
*  Other Tool Sets Needed:   Tool Locator, Memory Manager, Miscellaneous
*                            Tool Set, QuickDraw II, Desk Manager,
*                            Window Manager, Menu Manager, Control Manager,
*                            QuickDraw II Auxilliary, LineEdit Tool Set,
*                            Dialog Manager, Font Manager, List Manager
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Printer error codes *)
   prAbort     =   $80;

type
   (* Printer information subrecord *)
   prInfoRec = record
       iDev:  integer;
       iVRes: integer;
       iHRes: integer;
       rPage: rect;
       end;

   (* Printer style subrecord *)
   prStyleRec = record
       wDev:      integer;
       internA:   array [0..2] of integer;
       feed:      integer;
       paperType: integer;
       case boolean of
           true:  (crWidth:   integer;);
           false: (vSizing:   integer;
                  reduction: integer;
                  internB:   integer;);
           end;

   (* Job information subrecord *)
   prJobRec = record
       iFstPage:  integer;
       iLstPage:  integer;
       iCopies:   integer;
       bJDocLoop: byte;
       fFromUser: byte;
       pIdleProc: procPtr;
       pFileName: pathPtr;
       iFileVol:  integer;
       bFileVers: byte;
       bJobX:     byte;
       end;

   (* Print record *)
   PrRec = record
       prVersion: integer;
       prInfo:    prInfoRec;
       rPaper:    rect;
       prStl:     prStyleRec;
       prInfoPT:  array [0..13] of byte;
       prXInfo:   array [0..23] of byte;
       prJob:     PrJobRec;
       printX:    array [0..37] of byte;
       iReserved: integer;
       end;
   PrRecPtr = ^PrRec;
   PrHandle = ^PrRecPtr;

   (* Printer status subrecord *)
   PrStatusRec = record
       iTotPages:  integer;
       iCurPage:   integer;
       iTotCopies: integer;
       iCurCopy:   integer;
       iTotBands:  integer;
       iCurBand:   integer;
       fPgDirty:   boolean;
       fImaging:   integer;
       hPrint:     prHandle;
       pPrPort:    grafPortPtr;
       hPic:       longint;
       end;
   PrStatusPtr = ^PrStatusRec;


procedure PMBootInit; tool ($13, $01);     (* WARNING: an application should
                                                       NEVER make this call *)

procedure PMStartup (userID, dPageAddr: integer); tool ($13, $02);

procedure PMShutDown; tool ($13, $03);

function PMVersion: integer; tool ($13, $04);

procedure PMReset; tool ($13, $05);        (* WARNING: an application should
                                                       NEVER make this call *)

function PMStatus: boolean; tool ($13, $06);

procedure PMLoadDriver (driver: integer); tool ($13, $35);

procedure PMUnloadDriver (driver: integer); tool ($13, $34);

function PrChoosePrinter: boolean; tool ($13, $16);

procedure PrCloseDoc (printerPort: grafPortPtr); tool ($13, $0F);

procedure PrClosePage (printerPort: grafPortPtr); tool ($13, $11);

procedure PrDefault (thePrintRecord: prHandle); tool ($13, $09);

function PrDriverVer: integer; tool ($13, $23);

function PrError: integer; tool ($13, $14);

function PrGetDocName: pStringPtr; tool ($13, $36);

function PrGetNetworkName: pStringPtr; tool ($13, $2B);

function PrGetPgOrientation (prRecordHdl: prHandle): integer; tool ($13, $38);

function PrGetPortDvrName: pStringPtr; tool ($13, $29);

function PrGetPrinterDvrName: pStringPtr; tool ($13, $28);

(* PrGetPrinterSpecs returns 2 words:  low word = type of printer         *)
(*                                    high word = printer characteristics *)
function PrGetPrinterSpecs: longint; tool ($13, $18);

function PrGetUserName: pStringPtr; tool ($13, $2A);

function PrGetZoneName: pStringPtr; tool ($13, $25);

function PrJobDialog (thePrintRecord: prHandle): boolean; tool ($13, $0C);

function PrOpenDoc (thePrintRecord: prHandle; printerPort: grafPortPtr):
                    grafPortPtr; tool ($13, $0E);

procedure PrOpenPage (printerPort: grafPortPtr; pageFrame: rectPtr);
tool ($13, $10);

procedure PrPicFile (thePrintRecord: prHandle; printerPort: grafPortPtr;
                     statusRecPtr: PrStatusPtr); tool ($13, $12);

procedure PrPixelMap (srcLoc: locInfoPtr; var srcRect: rect; colorFlag: boolean);
tool($13, $0D);

function PrPortVer: integer; tool ($13, $24);

procedure PrSetDocName (docName: pStringPtr); tool ($13, $37);

procedure PrSetError (errorNumber: integer); tool ($13, $15);

function PrStlDialog (thePrintRecord: prHandle): boolean; tool ($13, $0B);

function PrValidate (thePrintRecord: prHandle): boolean; tool ($13, $0A);

implementation
end.
