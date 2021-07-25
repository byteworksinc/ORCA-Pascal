{$keep 'IntegerMath'}
unit IntegerMath;
interface

{********************************************************
*
*  Integer Math Tool Interface File
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
   (* Limits *)
   minLongint  =   $80000000;      (* min negative signed longint             *)
   minFrac     =   $80000000;      (* pinned value for neg Frac overflow      *)
   minFixed    =   $80000000;      (* pinned value for neg Fixed overflow     *)
   minInt      =   $8000;          (* min negative signed integer             *)
   maxUInt     =   $FFFF;          (* max positive unsigned integer           *)
   maxLongint  =   $7FFFFFFF;      (* max positive signed longint             *)
   maxFrac     =   $7FFFFFFF;      (* pinned value for positive Frac overflow *)
   maxFixed    =   $7FFFFFFF;      (* pinned value, positive Fixed overflow   *)
   maxULong    =   $FFFFFFFF;      (* max unsigned longint                    *)

   (* Signed Flag *)
   unsignedFlag =  $0000;          (* value is not signed *)
   signedFlag  =   $0001;          (* value is signed     *)

type
   extendedValue = array [0..9] of byte;
   extendedValuePtr = ^extendedValue;


procedure IMBootInit; tool ($0B, $01);     (* WARNING: an application should
                                                       NEVER make this call *)

procedure IMStartUp; tool ($0B, $02);

procedure IMShutDown; tool ($0B, $03);

function IMVersion: integer; tool ($0B, $04);

procedure IMReset; tool ($0B, $05);    (* WARNING: an application should
                                                   NEVER make this call *)

function IMStatus: boolean; tool ($0B, $06);

function Dec2Int (inputStr: univ cStringPtr; strLength, signedFlag: integer):
                  integer; tool ($0B, $28);

function Dec2Long (inputStr: univ cStringPtr; strLength, signedFlag: integer):
                   longint; tool ($0B, $29);

function Fix2Frac (fixedValue: longint): longint; tool ($0B, $1C);

function Fix2Long (fixedValue: longint): longint; tool ($0B, $1B);

procedure Fix2X (fixedValue: longint; var extendedVal: extendedValue);
tool ($0B, $1E);

function FixATan2 (input1, input2: longint): longint; tool ($0B, $17);

function FixDiv (dividend, divisor: longint): longint; tool ($0B, $11);

function FixMul (multiplicand, multiplier: longint): longint; tool ($0B, $0F);

function FixRatio (numerator, denominator: integer): longint; tool ($0B, $0E);

function FixRound (fixedValue: longint): integer; tool ($0B, $13);

function Frac2Fix (fracValue: longint): longint; tool ($0B, $1D);

procedure Frac2X (fracValue: longint; var extendedVal: extendedValue);
tool ($0B, $1F);

function FracCos (angle: longint): longint; tool ($0B, $15);

function FracDiv (dividend, divisor: longint): longint; tool ($0B, $12);

function FracMul (multiplicand, multiplier: longint): longint; tool ($0B, $10);

function FracSin (angle: longint): longint; tool ($0B, $16);

function FracSqrt (fracValue: longint): longint; tool ($0B, $14);

function Hex2Int (inputStr: univ cStringPtr; strLength: integer): integer;
tool ($0B, $24);

function Hex2Long (inputStr: univ cStringPtr; strLength: integer): longint;
tool ($0B, $25);

function HexIt (value: integer): longint; tool ($0B, $2A);

function HiWord (longValue: longint): integer; tool ($0B, $18);

procedure Int2Dec (value: integer; outputStr: univ cStringPtr;
                   strLength: integer; signedFlag: boolean); tool ($0B, $26);

procedure Int2Hex (value: integer; outputStr: univ cStringPtr;
                   strLength: integer); tool ($0B, $22);

procedure Long2Dec (value: longint; outputStr: univ cStringPtr;
                    strLength: integer; signedFlag: boolean); tool ($0B, $27);

function Long2Fix (longValue: longint): longint; tool ($0B, $1A);

procedure Long2Hex (value: longint; outputStr: univ cStringPtr;
                    strLength: integer); tool ($0B, $23);

(*          ACTUALLY RETURNS 2 LONG WORDS: REMAINDER AND QUOTIENT
function LongDivide (dividend, divisor: longint): 2 longints; tool ($0B, $0D);
*)

(*          ACTUALLY RETURNS 2 LONG WORDS: MSB AND LSB
function LongMul (multiplicand, multiplier: longint): 2 longints;
tool ($0B, $0C);
*)

function LoWord (longValue: longint): integer; tool ($0B, $19);

function Multiply (multiplicand, multiplier: integer): longint; tool ($0B, $09);

(* SDivide returns 2 words: the lo word = quotient; hi word = remainder *)
function SDivide (dividend, divisor: integer): longint; tool ($0B, $0A);

(* UDivide returns 2 words: the lo word = quotient; hi word = remainder *)
function UDivide (dividend, divisor: integer): longint; tool ($0B, $0B);

function X2Fix (var extendedVal: extendedValue): longint; tool ($0B, $20);

function X2Frac (var extendedVal: extendedValue): longint; tool ($0B, $21);

implementation
end.
