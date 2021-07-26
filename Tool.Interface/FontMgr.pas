{$keep 'FontMgr'}
unit FontMgr;
interface

{********************************************************
*
*   Font Manager Interface File
*
*   Other USES Files Needed: Common, QuickDrawII
*
*   Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                            Quick Draw II, Integer Math Tool Set
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common, QuickDrawII;

const
   (* font stat bits *)
   memBit          =   $0001;          (* font is in memory                   *)
   unrealBit       =   $0002;          (* font is scaled from another font    *)
   apFamBit        =   $0004;          (* font family supplied by application *)
   apVarBit        =   $0008;          (* font added by AddFontVar call or    *)
                                       (* scaled from such a font             *)
   purgeBit        =   $0010;          (* font is purgeable                   *)
   notDiskBit      =   $0020;          (* font not in ROM or in FONTS folder  *)
   notFoundBit     =   $8000;          (* specified font not found            *)

   (* font spec bits *)
   memOnlyBit      =   $0001;          (* allow only ROM fonts and fonts     *)
                                       (* currently in memory                *)
   realOnlyBit     =   $0002;          (* allow only unscaled fonts          *)
   anyFamBit       =   $0004;          (* ignore family number in call       *)
   anyStyleBit     =   $0008;          (* allow any partially matching style *)
   anySizeBit      =   $0010;          (* ignore point size in call          *)

   (* family stat bits *)
   notBaseBit      =   $0020;          (* family is not a base family *)

   (* family spec bits *)
   baseOnlyBit     =   $0020;          (* allow only base families *)

   (* Scale word *)
   dontScaleBit    =   $0001;          (* disable font scaling *)

   (* Family Numbers *)
   newYork         =   $0002;
   geneva          =   $0003;
   monaco          =   $0004;
   venice          =   $0005;
   london          =   $0006;
   athens          =   $0007;
   sanFran         =   $0008;
   toronto         =   $0009;
   cairo           =   $000B;
   losAngeles      =   $000C;
   times           =   $0014;
   helvetica       =   $0015;
   courier         =   $0016;
   symbol          =   $0017;
   taliesin        =   $0018;
   shaston         =   $FFFE;

(* Font records are defined in Common and QuickDrawII interface files. *)


procedure FMBootInit; tool ($1B, $01); (* WARNING: an application should
                                                   NEVER make this call *)

procedure FMStartUp (userID, dPageAddr: integer); tool ($1B, $02);

procedure FMShutDown; tool ($1B, $03);

function FMVersion: integer; tool ($1B, $04);

procedure FMReset; tool ($1B, $05);    (* WARNING: an application should
                                                   NEVER make this call *)

function FMStatus: boolean; tool ($1B, $06);

procedure AddFamily (famNum: integer; namePtr: univ pStringPtr); tool ($1B, $0D);

procedure AddFontVar (theFontHandle: fontHndl; newSpecs: integer);
tool ($1B, $14);

function ChooseFont (currentID: fontID; famSpecs: integer): longint;
tool ($1B, $16);

function CountFamilies (famSpecs: integer): integer; tool ($1B, $09);

function CountFonts (desiredID: fontID; specs: integer): integer;
tool ($1B, $10);

function FamNum2ItemID (familyNum: integer): integer; tool ($1B, $1B);

function FindFamily (famSpecs, positionNum: integer; name: univ pStringPtr):
                     integer; tool ($1B, $0A);

procedure FindFontStats (desiredID: fontID;  specs, positionNum: integer;
                         var resultPtr: fontStatRec); tool ($1B, $11);

procedure FixFontMenu (menuID, startingID, famSpecs: integer); tool ($1B, $15);

function FMGetCurFID: longint; tool ($1B, $1A);

function FMGetSysFID: longint; tool ($1B, $19);

procedure FMSetSysFont (theFontID: fontID); tool ($1B, $18);

function GetFamInfo (famNum: integer; name: univ pStringPtr): integer;
tool ($1B, $0B);

function GetFamNum (name: univ pStringPtr): integer; tool ($1B, $0C);

procedure InstallFont (desiredID: fontID; scaleWord: integer); tool ($1B, $0E);

function InstallWithStats (desiredID: fontID; scaleWord: integer):
                           fontStatRecPtr; tool ($1B, $1C);

function ItemID2FamNum (itemID: integer): integer; tool ($1B, $17);

procedure LoadFont (desiredID: fontID; specs, positionNum: integer;
                    var resultPtr: fontStatRec); tool ($1B, $12);

procedure LoadSysFont; tool ($1B, $13);

procedure SetPurgeStat (theFontID: fontID; purgeStat: integer); tool ($1B, $0F);

implementation
end.
