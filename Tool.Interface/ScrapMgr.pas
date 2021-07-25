{$keep 'ScrapMgr'}
unit ScrapMgr;
interface

{********************************************************
*
*  Scrap Manager Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager
*
*  Copyright 1987-1992, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Scrap types *)
   textScrap   =   0;
   picScrap    =   1;

   (* ShowClipboard flag values *)
   cpOpenWindow  = $8000;
   cpCloseWindow = $4000;

type
   scrapBuffer = record
      scrapType: integer;
      scrapSize: longint;
      scrapHandle: handle;
      end;

procedure ScrapBootInit; tool ($16, $01);  (* WARNING: an application should
                                                       NEVER make this call *)

procedure ScrapStartup; tool ($16, $02);

procedure ScrapShutDown; tool ($16, $03);

function ScrapVersion: integer; tool ($16, $04);

procedure ScrapReset; tool ($16, $05);     (* WARNING: an application should
                                                       NEVER make this call *)

function ScrapStatus: boolean; tool ($16, $06);

procedure GetIndScrap (index: integer; buffer: scrapBuffer); tool ($16, $14);

procedure GetScrap (destHandle: handle; scrapType: integer); tool ($16, $0D);

function GetScrapCount: integer; tool ($16, $12);

function GetScrapHandle (scrapType: integer): handle; tool ($16, $0E);

function GetScrapPath: pathPtr; tool ($16, $10);

function GetScrapSize (scrapType: integer): longint; tool ($16, $0F);

function GetScrapState: integer; tool ($16, $13);

procedure LoadScrap; tool ($16, $0A);

procedure PutScrap (numBytes: longint; scrapType: integer; srcPtr: ptr);
tool ($16, $0C);

procedure SetScrapPath (var thePath: pathName); tool ($16, $11);

procedure UnloadScrap; tool ($16, $09);

procedure ZeroScrap; tool ($16, $0B);

{new in 6.0.1}

function ShowClipboard (flags: integer; zoomRect: rectPtr): grafPortPtr;
tool ($16, $15);

implementation
end.
