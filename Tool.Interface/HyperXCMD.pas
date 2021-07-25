(*********************************************************
*
* Definition file for HyperCard XCMDs and XFCNs in Pascal
* For use with HyperCard IIGS Version 1.1
*
* Other USES Files Needed: Common
*
* Copyright Apple Computer, Inc. 1990-91
* All Rights Reserved
*
* Copyright 1993, Byte Works, Inc.
*
*********************************************************)

{$keep 'HyperXCMD'}

unit HyperXCMD;

interface

uses Common;

const
   _CallBackVector = $E10220;		{HyperCard call entry point}

					{XCMDBlock constants for event.what...}
   xOpenEvt = 1000;                     {the first event after you are created}
   xCloseEvt = 1001;                    {your window is being forced close}
   xHidePalettesEvt = 1004;             {someone called HideHCPalettes}
   xShowPalettesEvt = 1005;             {someone called ShowHCPalettes}
   xCursorWithin = 1300;                {cursor is within the window}

					{XWindow styles}
   xWindoidStyle = 0;
   xRectStyle = 1;
   xShadowStyle = 2;
   xDialogStyle = 3;

type
   str19 = string[19];
   string19Ptr = ^str19;
   string19Handle = ^string19Ptr;
   str31 = string[31];
   string31Ptr = ^str31;
   string31Handle = ^string31Ptr;

   XWEventInfo = record
      eventWindow: grafPortPtr;
      event: eventRecord;
      eventParams: array[1..9] of longint;
      eventResult: handle;
      end;
   XWEventInfoPtr = ^XWEventInfo;

   XCMDBlock = record
      paramCount: integer;
      params: array[1..16] of handle;
      returnValue: handle;
      passFlag: boolean;
      userID: integer;
      returnStat: integer;              {0 if normal, 1 if error}
      end;
   XCMDPtr = ^XCMDBlock;

   gsosInStringHandle = ^gsosInStringPtr;

(****  HyperTalk Utilities  ****)
function EvalExpr (expr: pString): handle; vector(_CallBackVector, $0002);

procedure SendCardMessage (msg: pString); vector(_CallBackVector, $0001);

procedure SendHCMessage (msg: pString); vector(_CallBackVector, $0005);


(****  Memory Utilities  ****)
function GetGlobal (globName: pString): handle; vector(_CallBackVector, $0012);

procedure SetGlobal (globName: pString; globValue: handle);
                     vector(_CallBackVector, $0013);

procedure ZeroBytes (dstPtr: ptr; longCount: Longint);
                     vector(_CallBackVector, $0006);


(****  String Utilities  ****)
function GSStringEqual (src1: gsosInStringHandle; src2: gsosInStringHandle): boolean;
                        vector(_CallBackVector, $0022);

procedure ScanToReturn (var scanPtr: ptr); vector(_CallBackVector, $001C);

procedure ScanToZero (var scanPtr: ptr); vector(_CallBackVector, $001D);

function StringEqual (str1: pString; str2: pString): boolean;
                      vector(_CallBackVector, $001A);

function StringLength (strPtr: ptr): longint; vector(_CallBackVector, $0003);

function StringMatch (stringPattern: pString; target: ptr): ptr;
                      vector(_CallBackVector, $0004);


(****  String Conversions  ****)
{ Standard Pascal does not allow returning strings.
function BoolToStr (bool: boolean): str31; vector(_CallBackVector, $0010);
}

function CopyGSString (src: gsosInStringHandle): gsosInStringHandle;
                       vector(_CallBackVector, $0020);

function GSConcat (src1: gsosInStringHandle; src2: gsosInStringHandle):
                   gsosInStringHandle;
                   vector(_CallBackVector, $0021);

{ Standard Pascal does not allow returning strings.
function ExtToStr (extendedNumber: Extended): str31;
                   vector(_CallBackVector, $0011);
}

{ Standard Pascal does not allow returning strings.
function GSToPString (src: gsosInStringHandle): pString;
                      vector(_CallBackVector, $001E);
}
 
function GSToZero (src: gsosInStringHandle): handle;
                   vector(_CallBackVector, $0023);

{ Standard Pascal does not allow returning strings.
function LongToStr (posNum: longint): str31; vector(_CallBackVector, $000D);
}

{ Standard Pascal does not allow returning strings.
function NumToHex (longNumber: longint; nDigits: integer): Str19;
                   vector(_CallBackVector, $000F);
}

{ Standard Pascal does not allow returning strings.
function NumToStr (longNumber: longint): str31; vector(_CallBackVector, $000E);
}

function PasToZero (str: pString): handle; vector(_CallBackVector, $0007);

procedure PointToStr (pt: Point; var str: pString);
                      vector(_CallBackVector, $002D);

function PToGSString (src: pString): gsosInStringHandle;
                      vector(_CallBackVector, $001F);

procedure RectToStr (rct: Rect; var str: pString);
                     vector(_CallBackVector, $002E);

procedure ReturnToPas (zeroStr: ptr; var pasStr: pString);
                       vector(_CallBackVector, $001B);

function StrToBool (str: str31): boolean; vector(_CallBackVector, $000B);

function StrToExt (str: str31): Extended; vector(_CallBackVector, $000C);

function StrToLong (str: str31): longint; vector(_CallBackVector, $0009);

function StrToNum (str: str31): longint; vector(_CallBackVector, $000A);

procedure StrToPoint (str: pString; var pt: Point);
                      vector(_CallBackVector, $002F);

procedure StrToRect (str: pString; var rct: Rect);
                     vector(_CallBackVector, $0030);

function ZeroToGS (src: handle): gsosInStringHandle;
                   vector(_CallBackVector, $0024);

procedure ZeroToPas (zeroStr: ptr; var pasStr: pString);
                     vector(_CallBackVector, $0008);


(****  Field Utilities  ****)
function GetFieldByID (cardFieldFlag: boolean; fieldID: integer): handle;
                       vector(_CallBackVector, $0016);

function GetFieldByName (cardFieldFlag: boolean; fieldName: pString): handle;
                         vector(_CallBackVector, $0014);

function GetFieldByNum (cardFieldFlag: boolean; fieldNum: integer): handle;
                        vector(_CallBackVector, $0015);

procedure SetFieldByID (cardFieldFlag: boolean; fieldID: integer;
                        fieldVal: handle);
                        vector(_CallBackVector, $0019);

procedure SetFieldByName (cardFieldFlag: boolean; fieldNName: pString;
                          fieldVal: handle);
                          vector(_CallBackVector, $0017);

procedure SetFieldByNum (cardFieldFlag: boolean; fieldNum: integer;
                         fieldVal: handle);
                         vector(_CallBackVector, $0018);

(****  Graphic Utilities  ****)
procedure ChangedMaskAndData (whatChanged: integer);
                              vector(_CallBackVector, $002C);

procedure GetMaskAndData (var mask: LocInfo; var data: LocInfo);
                          vector(_CallBackVector, $002B);


(****  Miscellaneous Utilities  ****)
procedure BeginXSound; vector(_CallBackVector, $0029);

procedure EndXSound; vector(_CallBackVector, $002A);


(****  Resource Names Utilities  ****)
function FindNamedResource (resourceType: integer; resourceName: pString;
                            var theFile: integer; var resourceID: longint):
                            boolean;
                            vector(_CallBackVector, $0026);

{ Standard Pascal does not allow returning strings.
function GetResourceName (resourceType: integer; resourceID: longint): pString;
                          vector(_CallBackVector, $0028);
}

function LoadNamedResource (resourceType: integer; resourceName: pString):
                            handle;
                            vector(_CallBackVector, $0025);

procedure SetResourceName (resourceType: integer; resourceID: longint;
                           resourceName: pString);
                           vector(_CallBackVector, $0027);


(****  Creating and Disposing XWindoids  ****)
function NewXWindow (boundsRect: Rect; title: str31; visible: boolean;
                     windowStyle: integer): grafPortPtr;
                     vector(_CallBackVector, $0031);

procedure CloseXWindow (window: grafPortPtr); vector(_CallBackVector, $0033);


(****  XWindoid Utilities  ****)
function GetXWindowValue (window: grafPortPtr): longint;
                          vector(_CallBackVector, $0037);

procedure HideHCPalettes; vector(_CallBackVector, $0034);

procedure ShowHCPalettes; vector(_CallBackVector, $0035);

procedure SetXWIdleTime (window: grafPortPtr; interval: longint);
                         vector(_CallBackVector, $0032);

procedure SetXWindowValue (window: grafPortPtr; customValue: longint);
                           vector(_CallBackVector, $0036);

procedure XWAllowReEntrancy (window: grafPortPtr; allowSysEvts: boolean;
                             allowHCEvts: boolean);
                             vector(_CallBackVector, $0038);

implementation

end.
