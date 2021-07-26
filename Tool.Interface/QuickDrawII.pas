{$keep 'QuickDrawII'}
unit QuickDrawII;
interface

{********************************************************
*
*  Quick Draw II Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                           Miscellaneous Tool Set
*
*  Note: The calls for the QuickDraw Auxiliary Tool Set
*       are at the end of this interface file.
*
*  Copyright 1987-1992, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   {Font Flags}
   widMaxSize      =   $0001;      {nonproportional spacing}
   zeroSize        =   $0002;      {numeric spacing}

   {Color data}
   table320        =   $32;        {320 color table}
   table640        =   $32;        {640 color table}

   {GrafPort sizes}
   maskSize        =   $08;        {mask size}
   locSize         =   $10;        {loc size}
   patSize         =   $20;        {pattern size}
   pnStateSize     =   $32;        {pen state size}
   portSize        =   $AA;        {size of grafPort}

   {Color masks}
   blueMask        =   $000F;      {mask for blue nibble}
   greenMask       =   $00F0;      {mask for green nibble}
   redMask         =   $0F00;      {mask for red nibble}

   {Master colors - mode indicated next to name}
   black           =   $0000;      {works in 320 & 640 modes}
   blue            =   $000F;      {works in 320 & 640 modes}
   darkGreen320    =   $0080;
   green320        =   $00E0;
   green640        =   $00F0;
   lightBlue320    =   $04DF;
   purple320       =   $072C;
   darkGray320     =   $0777;
   periwinkleBlue320 = $078F;
   brown320        =   $0841;
   lightGray320    =   $0CCC;
   red320          =   $0D00;
   lilac320        =   $0DAF;
   red640          =   $0F00;
   orange320       =   $0F70;
   flesh320        =   $0FA9;
   yellow          =   $0FF0;      {works in 320 & 640 modes}
   white           =   $0FFF;      {works in 320 & 640 modes}

   {Pen modes}
   modeCopy        =   $0000;      {copy source to destination}
   modeOR          =   $0001;      {overlay source & destination}
   modeXOR         =   $0002;      {XOR pen with destination}
   modeBIC         =   $0003;      {bit clear pen with destination}
   notCopy         =   $8000;      {copy (not source) to destination}
   notOR           =   $8001;      {overlay (not source) & destination}
   notXOR          =   $8002;      {XOR (not pen) with destination}
   notBIC          =   $8003;      {bit clear (not pen) with destination}

   {Pen and text modes}
   modeForeCopy    =   $0004;      {copy foreground pixels to destination}
   modeForeOR      =   $0005;      {OR foreground pixels into destination}
   modeForeXOR     =   $0006;      {XOR foreground pixels into destination}
   modeForeBIC     =   $0007;      {BIC foreground pixels into destination}
   notForeCopy     =   $8004;      {turn background to foreground, then copy}
                                   {foreground pixels into destination}
   notForeOR       =   $8005;      {turn background to foreground, then OR}
                                   {foreground pixels into destination}
   notForeXOR      =   $8006;      {turn background to foreground, then XOR}
                                   {foreground pixels into destination}
   notForeBIC      =   $8007;      {turn background to foreground, then BIC}
                                   {foreground pixels into destination}

   {QD Start-up modes}
   mode320         =   $00;        {320 graphics mode}
   mode640         =   $80;        {640 graphics mode}

   {SCB Byte Masks}
   colorTableNo    =   $0F;        {color table number}
   scbReserved     =   $10;        {reserved for future use}
   scbFill         =   $20;        {fill mode on}
   scbInterrupt    =   $40;        {interrupt generated when line refreshed}
   scbColorMode    =   $80;        {640 mode on}

   {Text styles}
   boldMask        =   $0001;      {mask for bold bit}
   italicMask      =   $0002;      {mask for italics bit}
   underlineMask   =   $0004;      {mask for underline bit}
   outlineMask     =   $0008;      {mask for outline bit}
   shadowMask      =   $0010;      {mask for shadow bit}

   {DrawStringWidth flag values}
   dswNoCondense    = $8000;
   dswCondense      = $0000;
   dswNoTruncate    = $0000;
   dswTruncLeft     = $2000;
   dswTruncCenter   = $4000;
   dswTruncRight    = $6000;
   dswPString       = $0000;
   dswCString       = $0004;
   dswWString       = $0008;
   dswStrIsPtr      = $0000;
   dswStrIsHandle   = $0001;
   dswStrIsResource = $0002;
  
   {ColorTable flag values}
   ctUse640Colors   = $8000;
   ctNoCtlNewRes    = $4000;
   ctIncludeMenuBar = $2000;

type
   {QDProcsPointer}
   QDProcsPtr = ptr;

   {Buffer sizing record}
   bufDimRec = record
       maxWidth:        integer;
       textBufHeight:   integer;
       textBufferWords: integer;
       fontWidth:       integer;
       end;

   {Font globals record}
   fontGlobalsRecord = record
       fgFontID:    integer;
       fgStyle:     integer;
       fgSize:      integer;
       fgVersion:   integer;
       fgWidMax:    integer;
       fgFBRExtent: integer;
       end;

   {FontInfo record}
   fontInfoRecord = record
       ascent:  integer;
       descent: integer;
       widMax:  integer;
       leading: integer;
       end;

   {Paint parameter block}
   paintParamBlock = record
       ptrToSourceLocInfo:  locInfoPtr;
       ptrToDestLocInfo:    locInfoPtr;
       ptrToSourceRect:     rectPtr;
       ptrToDestPoint:      pointPtr;
       mode:                integer;
       maskHandle:          handle;
       end;
   paintParamPtr = ^paintParamBlock;

   {Pen state record}
   penState = record
       psPnLoc : point;
       psPnSize:  point;
       psPnMode:  integer;
       psPnPat:   pattern;
       psPnMask:  mask;
       end;
   penStatePtr = ^penState;

   {ROM font record}
   ROMFontRec = record
       rfFamNum:     integer;
       rfFamStyle:   integer;
       rfSize:       integer;
       rfFontHandle: fontHndl;
       rfNamePtr:    pStringPtr;
       rfFBRExtent:  integer;
       end;
   ROMFontPtr = ^ROMFontRec;

   {Polygon, defined by user}
   polygon = record
       polySize:   integer;
       polyBBox:   rect;
       polyPoints: array [0..30] of point;  {may be modified by user}
       end;
   polyPtr = ^polygon;
   polyHandle = ^polyPtr;

   {Cursor record.  Array dimensions can be modified for your cursor.}
   {WARNING:  hotSpotX, hotSpotY may not be in the location expected, since}
   {cursorImage and cursorMask can change size.  Use pointer math to}
   {compute their positions for any cursor you did not define using this}
   {record.}
   cursor = record
       cursorHeight: integer;
       cursorWidth:  integer;
       cursorImage:  array [1..44] of integer;
       cursorMask:   array [1..44] of integer;
       hotSpotY:     integer;
       hotSpotX:     integer;
       end;
   cursorPtr = ^cursor;

   {QD Auxilliary icon record}
   iconRec = record
       iconType:   integer;
       iconSize:   integer;
       iconHeight: integer;
       iconWidth:  integer;
       iconImage:  array [1..44] of byte;  {Array dimensions can be}
       iconMask:   array [1..44] of byte;  {modified for your icon}
       end;
   iconRecPtr = ^iconRec;


procedure QDBootInit; tool ($04, $01);    {WARNING: an application should
                                                      NEVER make this call}

procedure QDStartup (dPageAddr, masterSCB, maxWidth, userID: integer);
tool ($04, $02);

procedure QDShutDown; tool ($04, $03);

function QDVersion: integer; tool ($04, $04);

procedure QDReset; tool ($04, $05);       {WARNING: an application should
                                                    NEVER make this call}

function QDStatus: boolean; tool ($04, $06);

procedure AddPt (var srcPtPtr, destPtPtr: point); tool ($04, $80);

procedure CharBounds (theChar: char; var result: rect); tool ($04, $AC);

function CharWidth (theChar: char): integer; tool ($04, $A8);

procedure ClearScreen (colorWord: integer); tool ($04, $15);

procedure ClipRect (var theRect: rect); tool ($04, $26);

procedure ClosePicture; tool ($04, $B9);

procedure ClosePoly; tool ($04, $C2);

procedure ClosePort (thePort: grafportPtr); tool ($04, $1A);

procedure CloseRgn (theRgnHandle: rgnHandle); tool ($04, $6E);

procedure CopyRgn (srcRgnHandle, destRgnHandle: rgnHandle); tool ($04, $69);

procedure CStringBounds (theCString: univ CStringPtr; var result: rect);
tool ($04, $AE);

function CStringWidth (theCString: univ CStringPtr): integer; tool ($04, $AA);

procedure DiffRgn (rgn1Handle, rgn2Handle, diffRgnHandle: rgnHandle);
tool ($04, $73);

procedure DisposeRgn (theRgnHandle: rgnHandle); tool ($04, $68);

procedure DrawChar (theChar: char); tool ($04, $A4);

procedure DrawCString (theString: univ CStringPtr); tool ($04, $A6);

procedure DrawString (theString: univ pStringPtr); tool ($04, $A5);

procedure DrawText (theText: univ textPtr; textLen: integer); tool ($04, $A7);

function EmptyRgn (theRgnHandle: rgnHandle): boolean; tool ($04, $78);

function EqualPt (var point1, point2: point): boolean; tool ($04, $83);

function EqualRect (var rect1, rect2: rect): boolean; tool ($04, $51);

function EqualRgn (rgnHandle1, rgnHandle2: rgnHandle): boolean; tool ($04, $77);

procedure EraseArc (var theRect: rect; startAngle, arcAngle: integer);
tool ($04, $64);

procedure EraseOval (var theRect: rect); tool ($04, $5A);

procedure ErasePoly (thePolyHandle: polyHandle); tool ($04, $BE);

procedure EraseRect (var theRect: rect); tool ($04, $55);

procedure EraseRgn (theRgnHandle: rgnHandle); tool ($04, $7B);

procedure EraseRRect (var theRect: rect; ovalWidth, ovalHeight: integer);
tool ($04, $5F);

procedure FillArc (var theRect: rect; startAngle, arcAngle: integer;
                   var thePattern: pattern); tool ($04, $66);

procedure FillOval (var theRect: rectPtr; var thePattern: pattern);
tool ($04, $5C);

procedure FillPoly (thePolyHandle: polyHandle; var thePattern: pattern);
tool ($04, $C0);

procedure FillRect (var theRect: rect; var thePattern: pattern);
tool ($04, $57);

procedure FillRgn (theRgnHandle: rgnHandle; var thePattern: pattern);
tool ($04, $7D);

procedure FillRRect (var theRect: rect; ovalWidth, ovalHeight: integer;
                     var thePattern: pattern); tool ($04, $61);

procedure ForceBufDims (maxWidth, maxFontHeight, maxFBRExtent: integer);
tool ($04, $CC);

procedure FrameArc (var theRect: rect; startAngle, arcAngle: integer);
tool ($04, $62);

procedure FrameOval (var theRect: rect); tool ($04, $58);

procedure FramePoly (thePolyHandle: polyHandle); tool ($04, $BC);

procedure FrameRect (var theRect: rect); tool ($04, $53);

procedure FrameRgn (theRgnHandle: rgnHandle); tool ($04, $79);

procedure FrameRRect (var theRect: rect; ovalWidth, ovalHeight: integer);
tool ($04, $5D);

function Get640Colors: patternPtr; tool ($04, $DA);

function GetAddress (tableID: integer): ptr; tool ($04, $09);

function GetArcRot: integer; tool ($04, $B1);

function GetBackColor: integer; tool ($04, $A3);

procedure GetBackPat (var thePattern: pattern); tool ($04, $35);

function GetCharExtra: fixed; tool ($04, $D5);

procedure GetClip (theRgnHandle: rgnHandle); tool ($04, $25);

function GetClipHandle: rgnHandle; tool ($04, $C7);

function GetColorEntry (tableNumber, entryNumber: integer): integer;
tool ($04, $11);

procedure GetColorTable (tableNumber: integer; var saveTable: colorTable);
tool ($04, $0F);

function GetCursorAdr: cursorPtr; tool ($04, $8F);

function GetFGSize: integer; tool ($04, $CF);

function GetFont: fontHndl; tool ($04, $95);

function GetFontFlags: integer; tool ($04, $99);

procedure GetFontGlobals (var theFGRec: fontGlobalsRecord); tool ($04, $97);

function GetFontID: longint; tool ($04, $D1);

procedure GetFontInfo (var theFIRec: fontInfoRecord); tool ($04, $96);

function GetFontLore (recordPtr: ptr; recordSize: integer): integer;
tool ($04, $D9);

function GetForeColor: integer; tool ($04, $A1);

function GetGrafProcs: QDProcsPtr; tool ($04, $45);

function GetMasterSCB: integer; tool ($04, $17);

procedure GetPen (var thePoint: point); tool ($04, $29);

procedure GetPenMask (var theMask: mask); tool ($04, $33);

function GetPenMode: integer; tool ($04, $2F);

procedure GetPenPat (var thePattern: pattern); tool ($04, $31);

procedure GetPenSize (var thePoint: point); tool ($04, $2D);

procedure GetPenState (var oldPenState: penState); tool ($04, $2B);

function GetPicSave: handle; tool ($04, $3F);

function GetPixel (h, v: integer): integer; tool ($04, $88);

function GetPolySave: handle; tool ($04, $43);

function GetPort: grafPortPtr; tool ($04, $1C);

procedure GetPortLoc (var theLocInfo: locInfo); tool ($04, $1E);

procedure GetPortRect (var theRect: rect); tool ($04, $20);

function GetRgnSave: handle; tool ($04, $41);

procedure GetROMFont (var recordPtr: ROMFontRec); tool ($04, $D8);

function GetSCB (scanLine: integer): integer; tool ($04, $13);

function GetSpaceExtra: fixed; tool ($04, $9F);

function GetStandardSCB: integer; tool ($04, $0C);

function GetSysField: longint; tool ($04, $49);

function GetSysFont: fontHndl; tool ($04, $B3);

function GetTextFace: integer; tool ($04, $9B);

function GetTextMode: integer; tool ($04, $9D);

function GetTextSize: integer; tool ($04, $D3);

function GetUserField: longint; tool ($04, $47);

function GetVisHandle: rgnHandle; tool ($04, $C9);

procedure GetVisRgn (theRgnHandle: rgnHandle); tool ($04, $B5);

procedure GlobalToLocal (var thePoint: point); tool ($04, $85);

procedure GrafOff; tool ($04, $0B);

procedure GrafOn; tool ($04, $0A);

procedure HideCursor; tool ($04, $90);

procedure HidePen; tool ($04, $27);

procedure InflateTextBuffer (newWidth, newHeight: integer); tool ($04, $D7);

procedure InitColorTable (var theTable: colorTable); tool ($04, $0D);

procedure InitCursor; tool ($04, $CA);

procedure InitPort (thePort: grafportPtr); tool ($04, $19);

procedure InsetRect (var theRect: rect; dH, dV: integer); tool ($04, $4C);

procedure InsetRgn (theRgnHandle: rgnHandle; dH, dV: integer); tool ($04, $70);

procedure InvertArc (var theRect: rect; startAngle, arcAngle: integer);
tool ($04, $65);

procedure InvertOval (var theRect: rect); tool ($04, $5B);

procedure InvertPoly (thePolyHandle: polyHandle); tool ($04, $BF);

procedure InvertRect (var theRect: rect); tool ($04, $56);

procedure InvertRgn (theRgnHandle: rgnHandle); tool ($04, $7C);

procedure InvertRRect (var theRect: rect; ovalWidth, ovalHeight: integer);
tool ($04, $60);

procedure KillPoly (thePolyHandle: polyHandle); tool ($04, $C3);

procedure Line (dH, dV: integer); tool ($04, $3D);

procedure LineTo (h, v: integer); tool ($04, $3C);

procedure LocalToGlobal (var thePoint: point); tool ($04, $84);

procedure MapPoly (thePoly: polyHandle; var srcRect, destRect: rect);
tool ($04, $C5);

procedure MapPt (var thePoint: point; var srcRect, destRect: rect);
tool ($04, $8A);

procedure MapRect (var theRect, srcRect, destRect: rect); tool ($04, $8B);

procedure MapRgn (mapRgnHandle: rgnHandle; var srcRect, destRect: rect);
tool ($04, $8C);

procedure Move (dH, dV: integer); tool ($04, $3B);

procedure MovePortTo (h, v: integer); tool ($04, $22);

procedure MoveTo (h, v: integer); tool ($04, $3A);

function NewRgn: rgnHandle; tool ($04, $67);

function NotEmptyRect (var theRect: rect): boolean; tool ($04, $52);

procedure ObscureCursor; tool ($04, $92);

procedure OffsetPoly (thePolyHandle: polyHandle; dH, dV: integer); tool ($04, $C4);

procedure OffsetRect (var theRect: rect; dH, dV: integer); tool ($04, $4B);

procedure OffsetRgn (theRgnHandle: rgnHandle; dH, dV: integer); tool ($04, $6F);

function OpenPoly: polyHandle; tool ($04, $C1);

procedure OpenPort (newPort: grafportPtr); tool ($04, $18);

procedure OpenRgn; tool ($04, $6D);

procedure PaintArc (var theRect: rect; startAngle, arcAngle: integer);
tool ($04, $63);

procedure PaintOval (var theRect: rect); tool ($04, $59);

procedure PaintPixels (var thePaintParam: paintParamBlock); tool ($04, $7F);

procedure PaintPoly (thePolyHandle: polyHandle); tool ($04, $BD);

procedure PaintRect (var theRect: rect); tool ($04, $54);

procedure PaintRgn (theRgnHandle: rgnHandle); tool ($04, $7A);

procedure PaintRRect (var theRect: rect; ovalWidth, ovalHeight: integer);
tool ($04, $5E);

procedure PenNormal; tool ($04, $36);

procedure PPToPort (srcLoc: locInfoPtr; var srcRect: rect; destX,
                    destY, transferMode: integer); tool ($04, $D6);

procedure Pt2Rect (var point1, point2: point; var destRect: rect);
tool ($04, $50);

function PtInRect (var thePoint: point; var theRect: rect): boolean;
tool ($04, $4F);

function PtInRgn (var thePoint: point; theRgnHandle: rgnHandle): boolean;
tool ($04, $75);

function QDRandom: integer; tool ($04, $86);

function RectInRgn (var theRect: rect; theRgnHandle: rgnHandle): boolean;
tool ($04, $76);

procedure RectRgn (theRgnHandle: rgnHandle; var theRect: rect); tool ($04, $6C);

procedure RestoreBufDims (var saveSizeInfo: bufDimRec); tool ($04, $CE);

procedure SaveBufDims (var saveSizeInfo: bufDimRec); tool ($04, $CD);

procedure ScalePt (var thePoint: point; var srcRect, destRect: rect);
tool ($04, $89);

procedure ScrollRect (var theRect: rect; dH, dV: integer; updateRgnHandle:
                      rgnHandle); tool ($04, $7E);

function SectRect (var rect1, rect2, destRect: rect): boolean;
tool ($04, $4D);

procedure SectRgn (rgn1Handle, rgn2Handle, destRgnHandle: rgnHandle);
tool ($04, $71);

procedure Set640Colors (colorNum: integer); tool ($04, $DB);
{Set640Color is correct; Set640Colors is retained for backwards compatibility}
procedure Set640Color (colorNum: integer); tool ($04, $DB);

procedure SetAllSCBs (newSCB: integer); tool ($04, $14);

procedure SetArcRot (arcRotValue: integer); tool ($04, $B0);

procedure SetBackColor (backColor: integer); tool ($04, $A2);

procedure SetBackPat (var thePattern: pattern); tool ($04, $34);

procedure SetBufDims (maxWidth, maxFontHeight, maxFBRExtent: integer);
tool ($04, $CB);

procedure SetCharExtra (charExtra: fixed); tool ($04, $D4);

procedure SetClip (rgnHandle: handle); tool ($04, $24);

procedure SetClipHandle (clipRgnHandle: rgnHandle); tool ($04, $C6);

procedure SetColorEntry (tableNumber, entryNumber, newColor: integer);
tool ($04, $10);

procedure SetColorTable (tableNumber: integer; var newTable: colorTable);
tool ($04, $0E);

procedure SetCursor (var theCursor: cursor); tool ($04, $8E);

procedure SetEmptyRgn (theRgnHandle: rgnHandle); tool ($04, $6A);

procedure SetFont (newFontHandle: fontHndl); tool ($04, $94);

procedure SetFontFlags (fontFlags: integer); tool ($04, $98);

procedure SetFontID (newFontID: fontID); tool ($04, $D0);

procedure SetForeColor (foreColor: integer); tool ($04, $A0);

procedure SetGrafProcs (grafProcsPtr: ptr); tool ($04, $44);

procedure SetIntUse (useInt: boolean); tool ($04, $B6);

procedure SetMasterSCB (masterSCB: integer); tool ($04, $16);

procedure SetOrigin (h, v: integer); tool ($04, $23);

procedure SetPenMask (var theMask: mask); tool ($04, $32);

procedure SetPenMode (penMode: integer); tool ($04, $2E);

procedure SetPenPat (var thePattern: pattern); tool ($04, $30);

procedure SetPenSize (width, height: integer); tool ($04, $2C);
 
procedure SetPenState (var newPenState: penState); tool ($04, $2A);

procedure SetPicSave (picSaveValue: handle); tool ($04, $3E);
{WARNING: an application should
            NEVER make this call}

procedure SetPolySave (polySaveValue: handle); tool ($04, $42);
{WARNING: an application should
            NEVER make this call}

procedure SetPort (thePort: grafportPtr); tool ($04, $1B);

procedure SetPortLoc (var theLocInfo: locInfo); tool ($04, $1D);

procedure SetPortRect (var theRect: rect); tool ($04, $1F);

procedure SetPortSize (portWidth, portHeight: integer); tool ($04, $21);

procedure SetPt (var srcPoint: point; h, v: integer); tool ($04, $82);

procedure SetRandSeed (randomSeed: longint); tool ($04, $87);

procedure SetRect (var theRect: rect; left, top, right, bottom: integer);
tool ($04, $4A);

procedure SetRectRgn (theRgnHandle: rgnHandle; left, top, right, bottom:
                      integer); tool ($04, $6B);

procedure SetRgnSave (rgnSaveValue: handle); tool ($04, $40);
{WARNING: an application should
            NEVER make this call}

procedure SetSCB (scanLine, newSCB: integer); tool ($04, $12);

procedure SetSolidBackPat (colorNum: integer); tool ($04, $38);

procedure SetSolidPenPat (colorNum: integer); tool ($04, $37);

procedure SetSpaceExtra (spaceExtra: fixed); tool ($04, $9E);

procedure SetStdProcs (stdProcRecPtr: QDProcsPtr); tool ($04, $8D);

procedure SetSysField (sysFieldValue: longint); tool ($04, $48);
{WARNING: an application should
            NEVER make this call}

procedure SetSysFont (theFontHandle: fontHndl); tool ($04, $B2);

procedure SetTextFace (textFace: integer); tool ($04, $9A);

procedure SetTextMode (textMode: integer); tool ($04, $9C);

procedure SetTextSize (textSize: integer); tool ($04, $D2);

procedure SetUserField (userFieldValue: longint); tool ($04, $46);

procedure SetVisHandle (theRgnHandle: rgnHandle); tool ($04, $C8);

procedure SetVisRgn (theRgnHandle: rgnHandle); tool ($04, $B4);

procedure ShowCursor; tool ($04, $91);

procedure ShowPen; tool ($04, $28);

procedure SolidPattern (colorNum: integer; var thePattern: pattern);
tool ($04, $39);

procedure StringBounds (theString: univ pStringPtr; var theRect: rect);
tool ($04, $AD);

function StringWidth (theString: univ pStringPtr): integer; tool ($04, $A9);

procedure SubPt (var srcPoint, destPoint: point); tool ($04, $81);

procedure TextBounds (theText: univ textPtr; textLen: integer;
                      var theRect: rect); tool ($04, $AF);

function TextWidth (theText: univ textPtr; textLen: integer): integer;
tool ($04, $AB);

procedure UnionRect (var rect1, rect2, destRect: rect); tool ($04, $4E);

procedure UnionRgn (rgn1Handle, rgn2Handle, destRgnHandle: rgnHandle);
tool ($04, $72);

procedure XorRgn (rgn1Handle, rgn2Handle, destRgnHandle: rgnHandle);
tool ($04, $74);

{------------------------ QuickDraw Auxiliary Tool Set --------------------}

procedure QDAuxBootInit; tool ($12, $01);   {WARNING: an application should
                                                        NEVER make this call}
procedure QDAuxStartup; tool ($12, $02);

procedure QDAuxShutDown; tool ($12, $03);

function QDAuxVersion: integer; tool ($12, $04);

procedure QDAuxReset; tool ($12, $05);      {WARNING: an application should
                                                        NEVER make this call}

function QDAuxStatus: boolean; tool ($12, $06);

procedure CalcMask (var srcLocInfo: locInfo; var srcRect: rect;
                    var destLocInfo: locInfo; var destRect: rect;
                    resMode: integer; thePattern: patternPtr;
                    leakTblPtr: univ ptr); tool ($12, $0E);
      
procedure CopyPixels (var srcLocPtr, destLocPtr: locInfo;
                      var srcRect, destRect: rect;
                      xFerMode: integer; maskRgn: rgnHandle); tool ($12, $09);

procedure DrawIcon (var iconPtr: iconRec; displayMode, xPos, yPos: integer);
tool ($12, $0B);

procedure DrawPicture (picHandle: handle; var destRect: rect); tool ($04, $BA);

function GetSysIcon (flags, value: integer; auxValue: longint): ptr;
tool ($12, $0F);

procedure IBeamCursor; tool ($12, $13);

procedure KillPicture (picHandle: handle); tool ($04, $BB);

function OpenPicture (var picFrame: rect): handle; tool ($04, $B7);

procedure PicComment (commentKind, dataSize: integer; dataHandle: handle);
tool ($04, $B8);

function PixelMap2Rgn (srcLocInfo: locInfo; flags, colorsToInclude: integer):
   rgnHandle; tool ($12, $10);

procedure SeedFill (var srcLocInfoPtr: locInfo; var srcRect: rect;
                    var destLocInfoPtr: locInfo; var destRec: rect;
                    seedH, seedV, resMode: integer; thePattern: patternPtr;
                    leakTblPtr: univ ptr); tool ($12, $0D);

procedure SpecialRect (var theRect: rect; frameColor, fillColor: integer);
tool ($12, $0C);

procedure WaitCursor; tool ($12, $0A);

procedure WhooshRect (flags: longint; smallRect, bigRect: rect);
tool ($12, $14);

{new in 6.0.1}

procedure DrawStringWidth (flags: integer; stringRef: univ longint;
                           width: integer); tool ($12, $15);

function UseColorTable (tableNum: integer; table: colorTablePtr;
                        flags:integer): handle; tool ($12, $16);

procedure RestoreColorTable (colorInfoHandle: handle; flags: integer);
tool ($12, $17);

implementation
end.
