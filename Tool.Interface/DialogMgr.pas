{$keep 'DialogMgr'}
unit DialogMgr;
interface

{********************************************************
*
*   Dialog Manager Interface File
*
*   Other USES Files Needed: Common
*
*   Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                            Miscellaneous Tool Set, Quick Draw II,
*                            Desk Manager, Event Manager, Window Manager,
*                            Control Manager, LineEdit Tool Set
*
*   Notes:  Any templates, because of their varying format,
*           must be supplied by the user.
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* dialog scroll bar commands *)
   getInitView     =   $0001;          (* view size at creation    *)
   getInitTotal    =   $0002;          (* total size at creation   *)
   getInitValue    =   $0003;          (* value at creation        *)
   scrollLineUp    =   $0004;          (* scroll one line up       *)
   scrollLineDown  =   $0005;          (* scroll one line down     *)
   scrollPageUp    =   $0006;          (* scroll one page up       *)
   scrollPageDown  =   $0007;          (* scroll one page down     *)
   scrollThumb     =   $0008;          (* scroll to thumb position *)

   (* item types *)
   buttonItem      =   $000A;          (* standard button control             *)
   checkItem       =   $000B;          (* standard check box control          *)
   radioItem       =   $000C;          (* standard radio button control       *)
   scrollBarItem   =   $000D;          (* special dialog scroll bar           *)
   userCtlItem     =   $000E;          (* application-defined control         *)
   statText        =   $000F;          (* static text - cannot be edited      *)
   longStatText    =   $0010;          (* static text                         *)
   editLine        =   $0011;          (* text that can be edited             *)
   iconItem        =   $0012;          (* an icon                             *)
   picItem         =   $0013;          (* a QuickDrawII picture               *)
   userItem        =   $0014;          (* application-defined item            *)
   userCtlItem2    =   $0015;          (* application-defined control         *)
   longStatText2   =   $0016;          (* static text - text cannot be edited *)
                                       (* and can contain embedded commands   *)
   itemDisable     =   $8000;          (* added to any item to disable item   *)

   (* item type range *)
   minItemType     =   $000A;          (* minimum valid item type *)
   maxItemType     =   $0016;          (* maximum valid item type *)

   (* item IDs *)
   OK              =   $0001;
   Cancel          =   $0002;

   (* part codes *)
   inButton        =   $0002;          (* user clicked simple button       *)
   inCheckBox      =   $0003;          (* user clicked check box           *)
   inRadioButton   =   $0004;          (* user clicked radio button        *)
   inUpArrow       =   $0005;          (* user clicked up arrow            *)
   inDownArrow     =   $0006;          (* user clicked down arrow          *)
   inPageUP        =   $0007;          (* user clicked page-up area        *)
   inPageDown      =   $0008;          (* user clicked page-down area      *)
   inStatText      =   $0009;          (* user clicked static text item    *)
   inGrow          =   $000A;          (* user clicked size box            *)
   inEditLine      =   $000B;          (* user clicked in text to edit     *)
   inUserItem      =   $000C;          (* user clicked application item    *)
   inLongStatText  =   $000D;          (* user clicked longStatText item   *)
   inIconItem      =   $000E;          (* user clicked an icon             *)
   inLongStatText2 =   $000F;          (* user clicked longStatText2 item  *)
   inThumb         =   $0081;          (* user clicked thumb of scroll item *)

   (* stage bit flags *)
   OKDefault       =   $0000;          (* OK is default for alert     *)
   CancelDefault   =   $0040;          (* Cancel is default for alert *)
   AlertDrawn      =   $0080;          (* draw alert                  *)

type
   itemTemplate = record
       itemID:    integer;
       itemRect:  rect;
       itemType:  integer;
       itemDescr: ptr;
       itemValue: integer;
       itemFlag:  integer;
       itemColor: colorTblPtr;
       end;
   itemTempPtr = ^itemTemplate;

   alertTemplate = record
       atBoundsRect: rect;
       atAlertID:    integer;
       atStage1:     byte;
       atStage2:     byte;
       atStage3:     byte;
       atStage4:     byte;
  (* This array should be set to reflect the number of items in the alert.   *)
  (* The last pointer in the array should be NIL to mark the end of the list *)
       atItemList:   array[1..10] of itemTempPtr;
       end;

   dialogTemplate = record
       dtBoundsRect: rect;
       dtVisible:    boolean;
       dtRefCon:     longint;
  (* This array should be set to reflect the number of items in the dialog.  *)
  (* The last pointer in the array should be NIL to mark the end of the list *)
       dtItemList:   array[1..10] of itemTempPtr;
       end;
   dialogTempPtr = ^dialogTemplate;

   iconRecord = record
       iconRect:  rect;
       iconImage: array [1..64] of integer;  (* user can change size of array *)
       end;

   userCtlItemPB = record
       defProcParm: procPtr;
       titleParm:   ptr;
       param2:      integer;
       param1:      integer;
       end;


procedure DialogBootInit; tool ($15, $01); (* WARNING: an application should
                                                       NEVER make this call *)

procedure DialogStartup (UserID: integer); tool ($15, $02);

procedure DialogShutDown; tool ($15, $03);

function DialogVersion: integer; tool ($15, $04);

procedure DialogReset; tool ($15, $05);    (* WARNING: an application should
                                                       NEVER make this call *)

function DialogStatus: boolean; tool ($15, $06);

function Alert (var theAlertTemplate: alertTemplate;
                filterProc: procPtr): integer; tool ($15, $17);

function CautionAlert (var theAlertTemplate: alertTemplate;
                       filterProc: procPtr): integer; tool ($15, $1A);

procedure CloseDialog (theDialog: grafPortPtr); tool ($15, $0C);

function DefaultFilter (theDialog: grafPortPtr; var theEvent: eventRecord;
                        var itemHitPtr: ptr): boolean; tool ($15, $36);

function DialogSelect (var theEvent: eventRecord; var resultPtr: grafPortPtr;
                       var itemHit: integer): boolean; tool ($15, $11);

procedure DisableDItem (theDialog: grafPortPtr; itemID: integer); tool ($15, $39);

procedure DlgCopy (theDialog: grafPortPtr); tool ($15, $13);

procedure DlgCut (theDialog: grafPortPtr); tool ($15, $12);

procedure DlgDelete (theDialog: grafPortPtr); tool ($15, $15);

procedure DlgPaste (theDialog: grafPortPtr); tool ($15, $14);

procedure DrawDialog (theDialog: grafPortPtr); tool ($15, $16);

procedure EnableDItem (theDialog: grafPortPtr; itemID: integer); tool ($15, $3A);

procedure ErrorSound (soundProcPtr: procPtr); tool ($15, $09);

function FindDItem (theDialog: grafPortPtr; var thePoint: point): integer;
tool ($15, $24);

function GetAlertStage: integer; tool ($15, $34);

function GetControlDItem (theDialog: grafPortPtr; itemID: integer): ctlRecHndl;
tool ($15, $1E);

function GetDefButton (theDialog: grafPortPtr): integer; tool ($15, $37);

procedure GetDItemBox (theDialog: grafPortPtr; itemID: integer;
                       var itemBoxPtr: rect); tool ($15, $28);

function GetDItemType (theDialog: grafPortPtr; itemID: integer): integer;
tool ($15, $26);

function GetDItemValue (theDialog: grafPortPtr; itemID: integer): integer;
tool ($15, $2E);

function GetFirstDItem (theDialog: grafPortPtr): integer; tool ($15, $2A);

procedure GetIText (theDialog: grafPortPtr; itemID: integer; resultPtr:
                    univ pStringPtr); tool ($15, $1F);

procedure GetNewDItem (theDialog: grafPortPtr;
                       var theItemTemplate: itemTemplate); tool ($15, $33);

function GetNewModalDialog (var theDialogTemplate: dialogTemplate): grafPortPtr;
tool ($15, $32);

function GetNextDItem (theDialog: grafPortPtr; itemID: integer): integer;
tool ($15, $2B);

procedure HideDItem (theDialog: grafPortPtr; itemID: integer); tool ($15, $22);

function IsDialogEvent (var theEvent: eventRecord): boolean; tool ($15, $10);

function ModalDialog (filterProc: procPtr): integer; tool ($15, $0F);

(* ModalDialog2 returns 2 integers: the lo word = item; hi word = part code *)

function ModalDialog2 (filterProc: procPtr): longint; tool ($15, $2C);

procedure NewDItem (theDialog: grafPortPtr; itemID: integer; var itemRect: rect;
                    itemType: integer; itemDescr: univ longint;
                    itemValue, itemFlag: integer; itemColor: univ ptr);
tool ($15, $0D);

function NewModalDialog (var dBoundsRect: rect; dVisibleFlag: boolean;
                         dRefCon: longint): grafPortPtr; tool ($15, $0A);

function NewModelessDialog (var dBoundsRect: rect; dTitle: pStringPtr;
                            dBehind: grafPortPtr; dFlag: integer;
                            dRefCon: longint; var dFullSize: rect): grafPortPtr;
tool ($15, $0B);

function NoteAlert (var theAlertTemplate: alertTemplate; filterProc: procPtr):
                    integer; tool ($15, $19);

procedure ParamText (param0, param1, param2, param3: pStringPtr);
tool ($15, $1B);

procedure RemoveDItem (theDialog: grafPortPtr; itemID: integer); tool ($15, $0E);

procedure ResetAlertStage; tool ($15, $35);

procedure SelectIText (theDialog: grafPortPtr; itemID, startSel,
                       endSel: integer); tool ($15, $21);

procedure SetDAFont (theFontHandle: fontHndl); tool ($15, $1C);

procedure SetDefButton (defButtonID: integer; theDialog: grafPortPtr);
tool ($15, $38);

procedure SetDItemBox (theDialog: grafPortPtr; itemID: integer;
                       var itemBox: rect); tool ($15, $29);

procedure SetDItemType (itemType: integer; theDialog: grafPortPtr;
                        itemID: integer); tool ($15, $27);

procedure SetDItemValue (itemValue: integer; theDialog: grafPortPtr;
                         itemID: integer); tool ($15, $2F);

procedure SetIText (theDialog: grafPortPtr; itemID: integer;
                    theString: pStringPtr); tool ($15, $20);

procedure ShowDItem (theDialog: grafPortPtr; itemID: integer); tool ($15, $23);

function StopAlert (var theAlertTemplate: alertTemplate; filterProc: procPtr):
                    integer; tool ($15, $18);

procedure UpdateDialog (theDialog: grafPortPtr; updateRgn: rgnHandle);
tool ($15, $25);

implementation
end.
