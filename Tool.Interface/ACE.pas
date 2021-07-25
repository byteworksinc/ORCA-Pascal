{$keep 'ACE'}
unit ACE;
interface

{********************************************************
*
*  ACE Tool Set Interface File (Apple IIGS Audio
*                               Compression and Expansion)
*
*  Other USES Files Needed:  Common
*
*  Other Tool Sets Needed:   Tool Locator
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;


procedure ACEBootInit; tool ($1D, $01);    (* WARNING: an application should
                                                       NEVER make this call *)

procedure ACEStartup (zeroPageLoc: integer); tool ($1D, $02);

procedure ACEShutdown; tool ($1D, $03);

function ACEVersion: integer; tool ($1D, $04);

procedure ACEReset; tool ($1D, $05);       (* WARNING: an application should
                                                       NEVER make this call *)

function ACEStatus: boolean; tool ($1D, $06);

function ACEInfo (infoItemCode: integer): longint; tool ($1D, $07);

procedure ACECompBegin; tool ($1D, $0B);

procedure ACECompress (src: handle; srcOffset: longint; dest: handle;
                       destOffset: longint; nBlks, method: integer);
tool ($1D, $09);

procedure ACEExpand (src: handle; srcOffset: longint; dest: handle;
                     destOffset: longint; nBlks, method: integer);
tool ($1D, $0A);

procedure ACEExpBegin; tool ($1D, $0C);

function GetACEExpState: ptr; tool ($1D, $0D);

procedure SetACEExpState (buffer: ptr); tool ($1D, $0E);

implementation
end.
