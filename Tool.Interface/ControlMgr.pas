{$keep 'ControlMgr'}
unit ControlMgr;
interface

{********************************************************
*
*  Control Manager Interface File
*
*  Other USES files needed:  Common
*
*  Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                           Miscellaneous Tool Set, Quick Draw II,
*                           Event Manager, Window Manager,
*                           LineEdit Tool Set (if using StatTextControl
*                           or LineEditControl), QDAuxilliary Tool Set
*                           (if using PictureControl or IconButtonControl),
*                           TextEdit Tool Set (if using TextEditControl),
*                           Menu Manager (if using PopUpControl), List
*                           Manager (if using ListControl).
*
*
*  Copyright 1987-1992, 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
  ctlInVis         =   $0080;          (* invisible mask for any type ctl *)

  (* Simple button control flag values *)
  simpRound        =   $0000;          (* single outlined, round cornered  *)
  simpBRound       =   $0001;          (* bold outlined, round cornered    *)
  simpSquare       =   $0002;          (* single outlined, square cornered *)
  simpDropSquare   =   $0003;          (* single outlined, square cornered,*)
                                       (* drop shadowed                    *)

  family           =   $007F;          (* radio button family number *)

  (* Scroll bar control flag values *)
  upFlag           =   $0001;          (* up arrow on scroll bar    *)
  downFlag         =   $0002;          (* down arrow on scroll bar  *)
  leftFlag         =   $0004;          (* left arrow on scroll bar  *)
  rightFlag        =   $0008;          (* right arrow on scroll bar *)
  horScroll        =   $0010;          (* horizontal scroll bar     *)

  (* Standard Control procedures *)
  SimpleProc       =   $00000000;      (* simple button standard control *)
  CheckProc        =   $02000000;      (* simple check-box std control   *)
  RadioProc        =   $04000000;      (* radio button standard control  *)
  ScrollProc       =   $06000000;      (* scroll bar standard control    *)
  GrowProc         =   $08000000;      (* size box standard control      *)

  (* NewControl2 procRef values for standard control types *)
  cSimpleButtonControl =  $80000000;
  cCheckControl        =  $82000000;
  cRadioControl        =  $84000000;
  cScrollBarControl    =  $86000000;
  cGrowControl         =  $88000000;
  cStatTextControl     =  $81000000;
  cEditLineControl     =  $83000000;
  cEditTextControl     =  $85000000;
  cPopUpControl        =  $87000000;
  cListControl         =  $89000000;
  cIconButtonControl   =  $07FF0001;
  cPictureControl      =  $8D000000;

  (* DefProc message parameters *)
  drawCtl          =   $00;            (* draw the control                   *)
  calcCRect        =   $01;            (* compute the rectangle to drag      *)
  testCtl          =   $02;            (* test where mouse button pressed    *)
  initCtl          =   $03;            (* perform additional control init    *)
  dispCtl          =   $04;            (* take additional disposal actions   *)
  posCtl           =   $05;            (* move control's indicator           *)
  thumbCtl         =   $06;            (* compute parms for dragging indic.  *)
  dragCtl          =   $07;            (* drag either indicator or control   *)
  autoTrack        =   $08;            (* called while dragging if -1 passed *)
                                       (* to TrackControl                    *)
  newValue         =   $09;            (* called when ctl gets new value     *)
  setParams        =   $0A;            (* called when ctl gets add. parms    *)
  moveCtl          =   $0B;            (* called when control moves          *)
  recSize          =   $0C;            (* return ctl record size in bytes    *)

  ctlHandleEvent    =  $0D;            (* handle keystrokes/menu selections  *)
  ctlChangeTarget   =  $0E;            (* make control active/inactive       *)
  ctlChangeBounds   =  $0F;            (* change bounds rectangle of control *)
  ctlWindChangeSize =  $10;            (* window has grown or been zoomed    *)
  ctlHandleTab      =  $11;            (* control was tabbed to              *)
  ctlNotifyMultiPart = $12;            (* multipart control must be hidden,  *)
                                       (*   drawn, or shown                  *)
  ctlWinStateChange =  $13;            (* window state has changed           *)

 
  (* axis parameters *)
  noConstraint     =   $0000;          (* no movement constraint              *)
  hAxisOnly        =   $0001;          (* constrain movement to horiz. axis   *)
  vAxisOnly        =   $0002;          (* constrain movement to vertical axis *)

  (* part codes *)
  NoPart           =   $00;            (* no part                  *)
  SimpleButton     =   $02;            (* simple button            *)
  CheckBox         =   $03;            (* check box                *)
  RadioButton      =   $04;            (* radio button             *)
  UpArrow          =   $05;            (* up arrow on scroll bar   *)
  DownArrow        =   $06;            (* down arrow on scroll bar *)
  PageUp           =   $07;            (* page up                  *)
  PageDown         =   $08;            (* page down                *)
  GrowBox          =   $0A;            (* size box                 *)
  Thumb            =   $81;            (* thumb                    *)

(* Hilite control parameters *)
noHilite           =   $0000;          (* hilight control                *)
inactiveHilite     =   $00FF;          (* remove hilighting from control *)

(* Control Manager constants (upper 8 bits) of ctlMoreFlags field *)
fCtlTarget         =   $8000;      (* ctl is currently active control        *)
fCtlCanBeTarget    =   $4000;      (* ctl can be made active control         *)
fCtlWantEvents     =   $2000;      (* call ctl when SendEventToCtl activated *)
fCtlProcRefNotPtr  =   $1000;      (* if set, ProcRef = ID of def proc rtn,  *)
                                   (*   else ProcRef = ptr to defproc rtn    *)
fCtlTellAboutSize  =   $0800;      (* notify ctl when window size changes    *)
fCtlIsMultiPart    =   $0400;      (* notify ctl needs to be hidden          *)

(* defProc constants (lower 8 bits) of ctlMoreFlags field *)

(* Bits 0 and 1 describe title reference: *)
titleIsPtr         = $0;
titleIsHandle      = $1;
titleIsResource    = $2;

(* Bits 2 and 3 describe the color table reference: *)
colorTableIsPtr      = $0;
colorTableIsHandle   = $4;
colorTableIsResource = $8;


type
   (* Control record is defined in the Common.intf interface file *)

   (* Scroll bar color table is defined in the Common.intf interface file *)

   boxColors = record                  (* check box color table *)
       boxReserved: integer;
       boxNor:      integer;
       boxSel:      integer;
       boxTitle:    integer;
       end;

   bttnColors = record                  (* button color table *)
       bttnOutline: integer;
       bttnNorBack: integer;
       bttnSelBack: integer;
       bttnNorText: integer;
       bttnSelText: integer;
       end;

   limitBlk = record                    (* limit block *)
       boundRect: rect;
       slopRect:  rect;
       axisParam: integer;
       dragPatt:  ptr;
       end;

   radioColors = record                 (* radio button color table *)
       radReserved: integer;
       radNor:      integer;
       radSel:      integer;
       radTitle:    integer;
       end;

   (* Control templates *)
   customControl = record
       pCount:      integer;
       ID:          longint;
       boundsRect:  rect;
       procRef:     longint;
       flag:        integer;
       moreFlags:   integer;
       refCon:      longint;
   (* This block is user-defined:  set your own limit. *)
       data:        packed array [0..255] of byte;
       end;

   simpleButtonControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       titleRef:     longint;
       colorTblRef:  longint;          (* optional *)
       keyEquiv:     keyEquivRec;      (* optional *)
       end;
            
   checkOrRadioControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       titleRef:     longint;
       initialValue: integer;
       colorTblRef:  longint;          (* optional *)
       keyEquiv:     keyEquivRec;      (* optional *)
       end;
            
   scrollControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       maxSize:      integer;
       viewSize:     integer;
       initialValue: integer;
       colorTblRef:  longint;          (* optional *)
       end;
            
   statTextControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       textRef:      longint;
       textSize:     integer;          (* optional *)
       just:         integer;          (* optional *)
       end;
            
   editLineControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       maxSize:      integer;
       defaultRef:   longint;
       end;
            
   editTextControl = record
       pCount:          integer;
       controlID:       longint;
       boundsRect:      rect;
       procRef:         longint;       (* must be $85000000 *)
       flags:           integer;
       moreflags:       integer;
       refCon:          longint;
       textFlags:       longint;
       indentRect:      rect;          (* this, and the rest of the fields, *)
       vertBar:         longint;       (*   are optional                    *)
       vertAmount:      integer;
       horzBar:         longint;       (* reserved - set to nil *)
       horzAmount:      integer;       (* reserved - set to 0   *)
       styleRef:        longint;
       textDescriptor:  integer;
       textRef:         longint;
       textLength:      longint;
       maxChars:        longint;
       maxLines:        longint;
       maxCharsPerLine: integer;
       maxHeight:       integer;
       colorRef:        longint;
       drawMode:        integer;
       filterProcPtr:   procPtr;
       end;

   popUpControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       titleWidth:   integer;
       menuRef:      longint;
       initialValue: integer;
       colorRef:     longint;          (* optional *)
       end;
            
   listControl = record
       pCount:         integer;
       ID:             longint;
       boundsRect:     rect;
       procRef:        longint;
       flag:           integer;
       moreFlags:      integer;
       refCon:         longint;
       listSize:       integer;
       listView:       integer;
       listType:       integer;
       listStart:      integer;
       listDraw:       procPtr;
       listMemHeight:  integer;
       listMemSize:    integer;
       listRef:        longint;
       colorRef:       longint;
       end;
            
   growControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       colorRef:     longint;          (* optional *)
       end;

   pictureControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       pictureRef:   longint;
       end;
            
   iconButtonControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       iconRef:      longint;
       titleRef:     longint;          (* optional *)
       colorTblRef:  longint;          (* optional *)
       displayMode:  integer;          (* optional *)
       keyEquiv:     keyEquivRec;      (* optional *)
       end;

   rectangleControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       penHeight:    integer;
       penWidth:     integer;
       penMask:      mask;
       penPattern:   pattern;
       end;

   thermometerControl = record
       pCount:       integer;
       ID:           longint;
       boundsRect:   rect;
       procRef:      longint;
       flag:         integer;
       moreFlags:    integer;
       refCon:       longint;
       value:        integer;
       data:         integer;
       colorTblRef:  longint;          (* optional *)
       end;



procedure CtlBootInit; tool ($10, $01);    (* WARNING: an application should
                                                       NEVER make this call *)

procedure CtlStartup (userID, dPageAddr: integer); tool ($10, $02);

procedure CtlShutDown; tool ($10, $03);

function CtlVersion: integer; tool ($10, $04);

procedure CtlReset; tool ($10, $05);   (* WARNING: an application should
                                                   NEVER make this call *)

function CtlStatus: boolean; tool ($10, $06);

function CallCtlDefProc (theControl: ctlRecHndl; message: integer;
                         param: univ longint): longint; tool ($10, $2C);

function CMLoadResource (resourceType: integer; resourceID: longint): handle;
tool ($10, $32);                        (* WARNING: an application should
                                                    NEVER make this call *)
                     
procedure CMReleaseResource (resourceType: integer; resourceID: longint);
tool ($10, $33);                        (* WARNING: an application should
                                                    NEVER make this call *)

procedure CtlNewRes; tool ($10, $12);

procedure DisposeControl (theControl: ctlRecHndl); tool ($10, $0A);

procedure DragControl (startX, startY: integer;
                       var limitRectPtr, slopRectPtr: rect; axis: integer;
                       theControl: ctlRecHndl); tool ($10, $17);

(* DragRect returns 2 integers; the hi word = amt X changed; *)
(*                              the lo word = amt Y changed  *)

function DragRect (actionProc: procPtr; var dragPattern: pattern;
                   startX, startY: integer;
                   var dragRect, limitRect, slopRect: rect;
                   dragFlag: integer): longint; tool ($10, $1D);

procedure DrawControls (theWindow: grafPortPtr); tool ($10, $10);

procedure DrawOneCtl (theControl: ctlRecHndl); tool ($10, $25);

procedure EraseControl (theControl: ctlRecHndl); tool ($10, $24);

function FindControl (var foundCtlPtr: ctlRecHndl; pointX, pointY: integer;
                      theWindow: grafPortPtr): integer; tool ($10, $13);

function FindRadioButton (theWindow: grafPortPtr; famNum: integer): integer;
tool ($10, $39);

function FindTargetCtl: ctlRecHndl; tool ($10, $26);

function GetCtlAction (theControl: ctlRecHndl): procPtr; tool ($10, $21);

function GetCtlHandleFromID (theWindow: grafPortPtr; ctlID: univ longint):
                             ctlRecHndl; tool ($10, $30);
                     
function GetCtlID (theControl: ctlRecHndl): longint; tool ($10, $2A);

function GetCtlDPage: integer; tool ($10, $1F);

function GetCtlMoreFlags (theControl: ctlRecHndl): integer; tool ($10, $2E);
                     
function GetCtlParamPtr: longint; tool ($10, $35);

(* GetCtlParams returns 2 integers: both are values of additional ctl parms *)

function GetCtlParams (theControl: ctlRecHndl): longint; tool ($10, $1C);

function GetCtlRefCon (theControl: ctlRecHndl): longint; tool ($10, $23);

function GetCtlTitle (theControl: ctlRecHndl): pStringPtr; tool ($10, $0D);

function GetCtlValue (theControl: ctlRecHndl): integer; tool ($10, $1A);

procedure GetLETextByID (theWindow: grafPortPtr; controlID: longint;
   var text: pString); tool ($10, $3B);

(* GrowSize returns 2 integers: lo word = height; hi word = width *)

function GrowSize: longint; tool ($10, $1E);

procedure HideControl (theControl: ctlRecHndl); tool ($10, $0E);

procedure HiliteControl (hiliteState: integer; theControl: ctlRecHndl);
tool ($10, $11);

procedure InvalCtls (theWindow: grafPortPtr); tool ($10, $37);

procedure KillControls (theWindow: grafPortPtr); tool ($10, $0B);

function MakeNextCtlTarget: ctlRecHndl; tool ($10, $27);

procedure MakeThisCtlTarget (theControl: ctlRecHndl); tool ($10, $28);

procedure MoveControl (newX, newY: integer; theControl: ctlRecHndl);
tool ($10, $16);

function NewControl (theWindow: grafPortPtr; var boundsRect: rect;
                     title: univ pStringPtr;
                     flag, value, param1, param2: integer;
                     defProc: univ longint; refCon: longint;
                     ctlColorTable: colorTblPtr): ctlRecHndl;
tool ($10, $09);

function NewControl2 (theWindow: grafPortPtr; referenceDesc: integer;
                      reference: univ longint): ctlRecHndl; tool ($10, $31);

procedure NotifyCtls (mask, message: integer; param: univ longint;
                      theWindow: grafportptr); tool ($10, $2D);
                     
function SendEventToCtl (targetOnlyFlag: boolean; theWindow: grafPortPtr;
                         var eTaskRecPtr: eventRecord): boolean;
tool ($10, $29);
                             
procedure SetCtlAction (newAction: procPtr; theControl: ctlRecHndl);
tool ($10, $20);

function SetCtlIcons (newFontHandle: fontHndl): fontHndl; tool ($10, $18);

procedure SetCtlID (newID: longint; theControl: ctlRecHndl); tool ($10, $2B);

procedure SetCtlMoreFlags (newMoreFlags: integer; theControl: ctlRecHndl);
tool ($10, $2F);
                     
procedure SetCtlParamPtr (subArrayptr: univ longint); tool ($10, $34);

procedure SetCtlParams (param2, param1: integer; theControl: ctlRecHndl);
tool ($10, $1B);

procedure SetCtlRefCon (newRefCon: longint; theControl: ctlRecHndl);
tool ($10, $22);

procedure SetCtlTitle (titlePtr: univ pStringPtr; theControl: ctlRecHndl);
tool($10, $0C);

procedure SetCtlValue (curValue: integer; theControl: ctlRecHndl);
tool ($10, $19);

procedure SetLETextByID (windPtr: grafPortPtr; leCtlID: longint;
   text: pString); tool ($10, $3A);

procedure ShowControl (theControl: ctlRecHndl); tool ($10, $0F);

function TestControl (pointX, pointY: integer; theControl: ctlRecHndl): integer;
tool ($10, $14);

function TrackControl (startX, startY: integer; actionProc: procPtr;
                       theControl: ctlRecHndl): integer; tool ($10, $15);

{new in 6.0.1}

procedure SetCtlValueByID (curValue: integer; theWindow: grafPortPtr;
                           theID: longint); tool ($10, $3C);

function GetCtlValueByID (theWindow: grafPortPtr; theID: longint): integer;
tool ($10, $3D);

procedure InvalOneCtlByID (theWindow: grafPortPtr; theID: longint);
tool ($10, $3E);

procedure HiliteCtlByID (hiliteState: integer; theWindow: grafPortPtr;
                         theID:longint); tool ($10, $3F);

implementation
end.
