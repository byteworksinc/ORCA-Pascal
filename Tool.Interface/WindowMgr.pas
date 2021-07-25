{$keep 'WindowMgr'}
unit WindowMgr;
interface

{********************************************************
*
*  Window Manager Interface File
*
*  Other USES Files Needed: Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                           Miscellaneous Tool Set, QuickDraw II,
*                           Event Manager
*
*  Copyright 1987-1992, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Axis parameters *)
   wNoConstraint   =   $0000;      (* no constraint on movement *)
   wHAxisOnly      =   $0001;      (* horizontal axis only      *)
   wVAxisOnly      =   $0002;      (* vertical axis only        *)

   (* Desktop commands *)
   fromDesk        =   $00;        (* subtract region from desktop           *)
   toDesk          =   $01;        (* add region to desktop                  *)
   getDesktop      =   $02;        (* get handle to desktop region           *)
   setDesktop      =   $03;        (* set handle to desktop region           *)
   getDeskPat      =   $04;        (* address of pattern or drawing rtn      *)
   setDeskPat      =   $05;        (* change addr of pattern or drawing rtn  *)
   getVisDesktop   =   $06;        (* get desktop rgn, minus visible windows *)
   backgroundRgn   =   $07;        (* for drawing directly on desktop        *)

   (* SendBehind values *)
   toBottom        =   -2;         (* send window to bottom *)
   topMost         =   -1;         (* make window frontmost *)
   bottomMost      =   $0000;      (* make window bottom    *)

   (* Task mask values *)
   tmMenuKey           =   $00000001;  (* handle menu key events              *)
   tmUpdate            =   $00000002;  (* handle update events                *)
   tmFindW             =   $00000004;  (* FindWindow called                   *)
   tmMenuSel           =   $00000008;  (* MenuSelect called                   *)
   tmOpenNDA           =   $00000010;  (* OpenNDA called                      *)
   tmSysClick          =   $00000020;  (* SystemClick called                  *)
   tmDragW             =   $00000040;  (* DragWindow called                   *)
   tmContent           =   $00000080;  (* activate window if click in content *)
                                       (*  region                             *)
   tmClose             =   $00000100;  (* TrackGoAway called                  *)
   tmZoom              =   $00000200;  (* TrackZoom called                    *)
   tmGrow              =   $00000400;  (* GrowWindow called                   *)
   tmScroll            =   $00000800;  (* enable scrolling; activate window   *)
                                       (*   on click in scroll bar            *)
   tmSpecial           =   $00001000;  (* handle special menu events          *)
   tmCRedraw           =   $00002000;  (* redraw controls                     *)
   tmInactive          =   $00004000;  (* allow select of inactive menu items *)
   tmInfo              =   $00008000;  (* don't activate inactive window on   *)
                                       (*   click in information bar          *)
   tmContentControls   =   $00010000;  (* track controls in content region    *)
   tmControlKey        =   $00020000;  (* send keystrokes to controls in      *)
                                       (*   active window                     *)
   tmControlMenu       =   $00040000;  (* send menu selections to controls in *)
                                       (*   active window                     *)
   tmMultiClick        =   $00080000;  (* track double and triple clicks      *)
   tmIdleEvents        =   $00100000;  (* send null events to active control  *)
                                       (*   in active window                  *)
   tmNoGetNextEvent    =   $00200000;  (* don't call GetNextEvent             *)

   (* varCode values when defining custom windows *)
   wDraw           =   $00;        (* draw window frame command *)
   wHit            =   $01;        (* hit test command          *)
   wCalcRgns       =   $02;        (* compute regions command   *)
   wNew            =   $03;        (* initialization command    *)
   wDispose        =   $04;        (* dispose command           *)

   (* wFrame values *)
   fHilited        =   $0001;      (* window is highlighted                 *)
   fZoomed         =   $0002;      (* window is zoomed                      *)
   fAllocated      =   $0004;      (* window record was allocated           *)
   fCtlTie         =   $0008;      (* state of ctls tied to window's state  *)
   fInfo           =   $0010;      (* window has information bar            *)
   fVis            =   $0020;      (* window is visible                     *)
   fQContent       =   $0040;      (* select window if mousedown in content *)
   fMove           =   $0080;      (* window can be dragged                 *)
   fZoom           =   $0100;      (* window has a zoom box                 *)
   fFlex           =   $0200;      (* data height and width are flexible    *)
   fGrow           =   $0400;      (* window has a size box                 *)
   fBScroll        =   $0800;      (* window has horizontal scroll bar      *)
   fRScroll        =   $1000;      (* window has vertical scroll bar        *)
   fAlert          =   $2000;      (* alert-type window frame               *)
   fClose          =   $4000;      (* window has close box                  *)
   fTitle          =   $8000;      (* window has title bar                  *)

   (* Record sizes *)
   windSize        =   $145;       (* size of window record *)
   wmTaskRecSize   =   $16;        (* size of task record   *)

   (* UpdateWindow flag values *)
   uwBackground    =   $8000;
   uwGSOSnotAvail  =   $4000;
   
type
   (* Document and alert window color table *)
   wColorTbl = record
       frameColor: integer;
       titleColor: integer;
       tBarColor:  integer;
       growColor:  integer;
       infoColor:  integer;
       end;
   wColorPtr = ^wColorTbl;

   (* Window record *)
   windRecPtr = ^windRec;
   windRec = record
       wNext:       windRecPtr;
       wPort:       array [1..170] of byte;
       wDefProc:    longint;
       wRefCon:     longint;
       wContDraw:   procPtr;
       wReserved:   longint;
       wStructRgn:  handle;
       wContRgn:    handle;
       wUpdateRgn:  handle;
       wCtls:       handle;
       wFrameCtls:  handle;
       wFrame:      integer;
   (* Other fields may be added here, as defined by window's defProc. *)
       end;

   paramTableRef = record
       p1Length:       integer;
       p1Frame:        integer;
       p1Title:        longint;
       p1RefCon:       longint;
       p1Zoom:         rect;
       p1Color:        longint;
       p1YOrigin:      integer;
       p1XOrigin:      integer;
       p1DataH:        integer;
       p1DataW:        integer;
       p1MaxH:         integer;
       p1MaxW:         integer;
       p1VerScroll:    integer;
       p1HorScroll:    integer;
       p1VerPage:      integer;
       p1HorPage:      integer;
       p1InfoText:     longint;
       p1InfoHeight:   integer;
       p1DefProc:      procPtr;
       p1InfoDraw:     procPtr;
       p1ContentDraw:  procPtr;
       p1Position:     rect;
       p1Plane:        longint;
       p1ControlList:  longint;
       p1InVerb:       integer;
       end;

   (* original Window parameter list *)
   paramList = record
       paramLength:   integer;
       wFrameBits:    integer;
       wTitle:        pStringPtr;
       wRefCon:       longint;
       wZoom:         rect;
       wColor:        wColorPtr;
       wYOrigin:      integer;
       wXOrigin:      integer;
       wDataH:        integer;
       wDataW:        integer;
       wMaxH:         integer;
       wMaxW:         integer;
       wScrollVer:    integer;
       wScrollHor:    integer;
       wPageVer:      integer;
       wPageHor:      integer;
       wInfoRefCon:   longint;
       wInfoHeight:   integer;
       wFrameDefProc: procPtr;
       wInfoDefProc:  procPtr;
       wContDefProc:  procPtr;
       wPosition:     rect;
       wPlane:        grafPortPtr;
       wStorage :     windRecPtr;    (* address of memory for window record *)
       end;
   paramListPtr = ^paramList;

   deskMessage = record
       reserved:  longint;
       messType:  integer;         (* must be 2 *)
       drawType:  integer;         (* 0 = pattern; 1 = picture *)
   (* drawData = 32 bytes of pattern or 32,000 bytes of picture data *)
       drawData:  array [1..32] of byte;
       end;


(* wmTaskRec is an Event Record, defined in the Common.intf interface file.  *)


procedure WindBootInit; tool ($0E, $01);   (* WARNING: an application should
                                                       NEVER make this call *)

procedure WindStartup (userID: integer); tool ($0E, $02);

procedure WindShutDown; tool ($0E, $03);

function WindVersion: integer; tool ($0E, $04);

procedure WindReset; tool ($0E, $05);      (* WARNING: an application should
                                                       NEVER make this call *)

function WindStatus: boolean; tool ($0E, $06);

function AlertWindow (alertFlags: integer; subStrPtr: ptr;
                      alertStrPtr: univ longint): integer; tool ($0E, $59);

procedure BeginUpdate (theWindow: grafPortPtr); tool ($0E, $1E);

procedure BringToFront (theWindow: grafPortPtr); tool ($0E, $24);

function CheckUpdate (var theEvent: eventRecord): boolean; tool ($0E, $0A);

procedure CloseWindow (theWindow: grafPortPtr); tool ($0E, $0B);

function CompileText (subType: integer; subStringsPtr, srcStringsPtr: univ ptr;
                      srcSize: integer): handle; tool ($0E, $60);
      
function Desktop (deskTopOp: integer; dtParam: longint): longint;
tool ($0E, $0C);

function DoModalWindow (event: eventRecord;
   updateProc, eventHook, beepProc: procPtr; flags: integer): longint;
   tool ($0E, $64);

procedure DragWindow (grid, startX, startY, grace: integer;
                      var boundsRect: rect; theWindow: grafPortPtr);
tool ($0E, $1A);

procedure DrawInfoBar (theWindow: grafPortPtr); tool ($0E, $55);

procedure EndFrameDrawing; tool ($0E, $5B);

procedure EndInfoDrawing; tool ($0E, $51);

procedure EndUpdate (theWindow: grafPortPtr); tool ($0E, $1F);

function ErrorWindow (subType: integer; subStringPtr: univ ptr;
                      errNum: integer): integer; tool ($0E, $62);

function FindCursorCtl (var ctl: ctlRecHndl; xLoc, yLoc: integer;
   theWindow: grafPortPtr): integer; tool ($0E, $69);

function FindWindow (var whichWindow: grafPortPtr; pointX, pointY: integer):
                     integer; tool ($0E, $17);

function FrontWindow: grafPortPtr; tool ($0E, $15);

function GetAuxWindInfo (theWindow: grafPortPtr): longint; tool ($0E, $63);

function GetContentDraw (theWindow: grafPortPtr): procPtr; tool ($0E, $48);

(* GetContentOrigin returns 2 words: loWord = Y origin, hiWord = X origin *)
(* Apple has consistently switched between two spellings for this call.   *)
(* Since it has become impossible to tell what they will do next, both    *)
(* spellings are included here.                                           *)
function GetContentOrigin (theWindow: grafPortPtr): longint; tool ($0E, $3E);
function GetContentOrgin (theWindow: grafPortPtr): longint; tool ($0E, $3E);

function GetContentRgn (theWindow: grafPortPtr): longint; tool ($0E, $2F);

(* GetDataSize returns 2 words: loWord = height, hiWord = width *)
function GetDataSize (theWindow: grafPortPtr): longint; tool ($0E, $40);

function GetDefProc (theWindow: grafPortPtr): procPtr; tool ($0E, $31);

function GetFirstWindow: grafPortPtr; tool ($0E, $52);

procedure GetFrameColor (var newColor: wColorTbl; theWindow: grafPortPtr);
tool ($0E, $10);

function GetInfoDraw (theWindow: grafPortPtr): procPtr; tool ($0E, $4A);

function GetInfoRefCon (theWindow: grafPortPtr): longint; tool ($0E, $35);

(* GetMaxGrow returns 2 words: loWord = maxHeight, hiWord = maxWidth *)
function GetMaxGrow (theWindow: grafPortPtr): longint; tool ($0E, $42);

function GetNextWindow (theWindow: grafPortPtr): grafPortPtr; tool ($0E, $2A);

(* GetPage returns 2 words: loWord = vertical amt, hiWord = horizontal amt *)
function GetPage (theWindow: grafPortPtr): longint; tool ($0E, $46);

procedure GetRectInfo (var infoRect: rect; theWindow: grafPortPtr);
tool ($0E, $4F);

(* GetScroll returns 2 words: loWord = vertical amt, hiWord = horizontal amt *)
function GetScroll (theWindow: grafPortPtr): longint; tool ($0E, $44);

function GetStructRgn (theWindow: grafPortPtr): rgnHandle; tool ($0E, $2E);

function GetSysWFlag (theWindow: grafPortPtr): boolean; tool ($0E, $4C);

function GetUpdateRgn (theWindow: grafPortPtr): rgnHandle; tool ($0E, $30);

function GetWControls (theWindow: grafPortPtr): ctlRecHndl; tool ($0E, $33);

function GetWFrame (theWindow: grafPortPtr): integer; tool ($0E, $2C);

function GetWindowMgrGlobals: ptr; tool ($0E, $58);

function GetWKind (theWindow: grafPortPtr): integer; tool ($0E, $2B);

function GetWMgrPort: grafPortPtr; tool ($0E, $20);

function GetWRefCon (theWindow: grafPortPtr): longint; tool ($0E, $29);

function GetWTitle (theWindow: grafPortPtr): pStringPtr; tool ($0E, $0E);

function GetZoomRect (theWindow: grafPortPtr): rectPtr; tool ($0E, $37);

(* GrowWindow returns 2 words: loWord = new height, hiWord = new width *)
function GrowWindow (minWidth, minHeight, startX, startY: integer;
                     theWindow: grafPortPtr): longint; tool ($0E, $1B);

(* HandleDiskInsertreturns 2 words: loWord = dev num, hiWord = flags *)
function HandleDiskInsert (flags, devNum: integer): longint; tool ($0E, $6B);

procedure HideWindow (theWindow: grafPortPtr); tool ($0E, $12);

procedure HiliteWindow (fHiliteFlag: boolean; theWindow: grafPortPtr);
tool ($0E, $22);

procedure InvalRect (var badRect: rect); tool ($0E, $3A);

procedure InvalRgn (badRgn: rgnHandle); tool ($0E, $3B);

procedure MoveWindow (newX, newY: integer; theWindow: grafPortPtr);
tool ($0E, $19);

function MWGetCtlPart: integer; tool ($0E, $65);

function MWSetMenuProc (newMenuProc: procPtr): procPtr; tool ($0E, $66);

procedure MWSetUpEditMenu; tool ($0E, $68);

procedure MWStdDrawProc; tool ($0E, $67);

function NewWindow (paramListPtr: paramList): grafPortPtr; tool ($0E, $09);

function NewWindow2 (titlePtr: pStringPtr; refCon: univ longint;
                     contentDrawPtr, defProcPtr: procPtr;
                     paramTableDescriptor: integer;
                     paramTableRef:  univ longint;
                     resourceType: integer): grafPortPtr; tool ($0E, $61);

(* PinRect returns a point: loWord = Y coordinate, hiWord = X coordinate *)
function PinRect (xPoint, yPoint: integer; var theRect: rect): longint;
tool ($0E, $21);

procedure RefreshDesktop (redrawRect: rectPtr); tool ($0E, $39);

procedure ResizeInfoBar (flags, newSize: integer; theWindow: grafPortPtr);
tool ($0E, $6A);

procedure ResizeWindow (hiddenFlag: boolean; var theRect: rect;
                        theWindow: grafPortPtr); tool ($0E, $5C);

procedure SelectWindow (theWindow: grafPortPtr); tool ($0E, $11);

procedure SendBehind (behindWindow, theWindow: grafPortPtr); tool ($0E, $14);

procedure SetContentDraw (contDraw: procPtr; theWindow: grafPortPtr);
tool ($0E, $49);

procedure SetContentOrigin (xOrigin, yOrigin: integer; theWindow: grafPortPtr);
tool ($0E, $3F);

procedure SetContentOrigin2 (scrollFlag, xOrigin, yOrigin: integer;
                             theWindow: grafPortPtr); tool ($0E, $57);

procedure SetDataSize (dataWidth, dataHeight: integer; theWindow: grafPortPtr);
tool ($0E, $41);

procedure SetDefProc (wDefProc: procPtr; theWindow: grafPortPtr);
tool ($0E, $32);

procedure SetFrameColor (newColor: wColorPtr; theWindow: grafPortPtr);
tool ($0E, $0F);

procedure SetInfoDraw (infoDraw: procPtr; theWindow: grafPortPtr);
tool ($0E, $16);

procedure SetInfoRefCon (infoRefCon: longint; theWindow: grafPortPtr);
tool ($0E, $36);

procedure SetMaxGrow (maxWidth, maxHeight: integer; theWindow: grafPortPtr);
tool ($0E, $43);

procedure SetOriginMask (originMask: integer; theWindow: grafPortPtr);
tool ($0E, $34);

procedure SetPage (hPage, vPage: integer; theWindow: grafPortPtr);
tool ($0E, $47);

procedure SetScroll (hScroll, vScroll: integer; theWindow: grafPortPtr);
tool ($0E, $45);

procedure SetSysWindow (theWindow: grafPortPtr); tool ($0E, $4B);

procedure SetWFrame (wFrame: integer; theWindow: grafPortPtr); tool ($0E, $2D);

function SetWindowIcons (newFontHandle: handle): handle; tool ($0E, $4E);

procedure SetWRefCon (wRefCon: longint; theWindow: grafPortPtr); tool ($0E, $28);

procedure SetWTitle (title: univ pStringPtr; theWindow: grafPortPtr); tool ($0E, $0D);

procedure SetZoomRect (var wZoomSize: rect; theWindow: grafPortPtr);
tool ($0E, $38);

procedure ShowHide (showFlag: boolean; theWindow: grafPortPtr); tool ($0E, $23);

procedure ShowWindow (theWindow: grafPortPtr); tool ($0E, $13);

procedure SizeWindow (newWidth, newHeight: integer; theWindow: grafPortPtr);
tool ($0E, $1C);

procedure StartDrawing (theWindow: grafPortPtr); tool ($0E, $4D);

procedure StartFrameDrawing (theWindow: grafPortPtr); tool ($0E, $5A);

procedure StartInfoDrawing (var infoRect: rect; theWindow: grafPortPtr);
tool ($0E, $50);

function TaskMaster (taskMask: integer; var theTaskRec: eventRecord): integer;
tool ($0E, $1D);

function TaskMasterDA (eventMask: integer; var taskRecPtr: eventRecord): integer;
tool ($0E, $5F);

function TrackGoAway (startX, startY: integer; theWindow: grafPortPtr):
                      boolean; tool ($0E, $18);

function TrackZoom (startX, startY: integer; theWindow: grafPortPtr): boolean;
tool ($0E, $26);

procedure ValidRect (var goodRect: rect); tool ($0E, $3C);

procedure ValidRgn (goodRgn: rgnHandle); tool ($0E, $3D);

(* WindDragRect returns 2 words:  loWord = change in Y, hiWord = change in X *)
function WindDragRect (actionProc: procPtr; var dragPatternPtr: pattern;
                       startX, startY: integer;
                       var dragRect, limitRect, slopRect: rect;
                       dragFlag: integer): longint; tool($0E, $53);

procedure WindNewRes; tool ($0E, $25);

function WindowGlobal (windowGlobalMask: integer): integer; tool ($0E, $56);

procedure ZoomWindow (theWindow: grafPortPtr); tool ($0E, $27);

{new in 6.0.1}

procedure UpdateWindow (flags: integer; theWindow: grafPortPtr);
tool ($0E, $6C);

implementation
end.
