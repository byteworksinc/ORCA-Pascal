{$keep 'MenuMgr'}
unit MenuMgr;
interface

{********************************************************
*
*   Menu Manager Interface File
*
*   Other USES Files Needed:  Common
*
*   Other Tool Sets Needed:   Tool Locator, Memory Manager,
*                             QuickDraw II, Event Manager,
*                             Window Manager, Control Manager
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Masks for MenuFlag *)
   mInvis          =   $0004;      (* set if menu is not visible       *)
   mCustom         =   $0010;      (* set if menu is a custom menu     *)
   mXor            =   $0020;      (* set if menu is hilited using XOR *)
   mSelected       =   $0040;      (* set if menu is highlighted       *)
   mDisabled       =   $0080;      (* set if menu is disabled          *)

   (* Messages to menu definition procedures *)
   mDrawMsg        =   $0000;      (* draw menu             *)
   mChooseMsg      =   $0001;      (* hit test item         *)
   mSizeMsg        =   $0002;      (* compute menu size     *)
   mDrawTitle      =   $0003;      (* draw menu's title     *)
   mDrawMItem      =   $0004;      (* draw item             *)
   mGetMItemID     =   $0005;      (* return item ID number *)

   (* Inputs to SetMenuFlag routine *)
   customMenu      =   $0010;      (* menu is a custom menu                  *)
   disableMenu     =   $0080;      (* menu will be dimmed and not selectable *)
   enableMenu      =   $FF7F;      (* menu will not be dimmed; is selectable *)
   colorReplace    =   $FFDF;      (* menu title and background will be      *)
                                   (*   redrawn and hilighted                *)
   standardMenu    =   $FFEF;      (* menu considered a standard menu        *)

   (* Inputs to SetMItemFlag routine *)
   xorMItemHilite  =   $0020;      (* menu title area XORed to highlight    *)
   underMItem      =   $0040;      (* underline item                        *)
   noUnderMItem    =   $FFBF;      (* don't underline item                  *)
   colorMItemHilite =  $FFDF;      (* menu title and background highlighted *)
   enableItem      =   $FF7F;      (* enable menu item                      *)
   disableItem     =   $0080;      (* disable menu item                     *)

   (* Reference values for new 5.0 Menu Manager calls *)
   refIsPointer    =   0;
   refIsHandle     =   1;
   refIsResource   =   2;

type
   menuItemTemplate = record
       version:       integer;     (* must be zero *)
       itemID:        integer;
       itemChar:      byte;
       itemAltChar:   byte;
       itemCheck:     integer;
       itemFlag:      integer;
       itemTitleRef:  longint;
       end;
         
   menuTemplate = record
       version:       integer;     (* must be zero *)
       menuID:        integer;
       menuFlag:      integer;
       menuTitleRef:  longint;
   (* Array of pointers/handles/resource IDs of menu items.  Set array size  *)
   (* for application.                                                       *)
       itemRefs:      array [1..10] of longint;
       terminator:    longint;     (* must be zero *)
       end;
         
   menuBarTemplate = record
       version:       integer;     (* must be zero *)
       menuBarFlag:   integer;
   (* Array of pointers/handles/resource IDs for menus.  Set array size for  *)
   (* application.                                                           *)
       menuRefs:      array [1..10] of longint;
       terminator:    longint;     (* must be zero *)
       end;

   menuResult = record
      menuID: integer;
      firstHandle, secondHandle: handle;
      end;

   (* The MenuBar record and MenuRecord are defined in the Common.intf  *)
   (* interface file.                                                   *)


procedure MenuBootInit; tool ($0F, $01);   (* WARNING: an application should
                                                       NEVER make this call *)

procedure MenuStartUp (userID, dPageAddr: integer); tool ($0F, $02);

procedure MenuShutDown; tool ($0F, $03);

function MenuVersion: integer; tool ($0F, $04);

procedure MenuReset; tool ($0F, $05);      (* WARNING: an application should
                                                       NEVER make this call *)

function MenuStatus: boolean; tool ($0F, $06);

procedure CalcMenuSize (newWidth, newHeight, menuNum: integer); tool ($0F, $1C);

procedure CheckMItem (checkedFlag: boolean; itemNum: integer); tool ($0F, $32);

function CountMItems (menuNum: integer): integer; tool ($0F, $14);

procedure DeleteMenu (menuNum: integer); tool ($0F, $0E);

procedure DeleteMItem (itemNum: integer); tool ($0F, $10);

procedure DisableMItem (itemNum: integer); tool ($0F, $31);

procedure DisposeMenu (theMenuHandle: menuHandle); tool ($0F, $2E);

procedure DrawMenuBar; tool ($0F, $2A);

procedure EnableMItem (itemNum: integer); tool ($0F, $30);

function FixMenuBar: integer; tool ($0F, $13);

procedure FlashMenuBar; tool ($0F, $0C);

function GetBarColors: longint; tool ($0F, $18);

function GetMenuBar: ctlRecHndl; tool ($0F, $0A);

function GetMenuFlag (menuNum: integer): integer; tool ($0F, $20);

function GetMenuMgrPort: grafPortPtr; tool ($0F, $1B);

function GetMenuTitle (menuNum: integer): cStringPtr; tool ($0F, $22);

function GetMHandle (menuNum: integer): menuHandle; tool ($0F, $16);

function GetMItem (itemNum: integer): cStringPtr; tool ($0F, $25);

function GetMItemBlink: integer; tool ($0F, $4F);

function GetMItemFlag (itemNum: integer): integer; tool ($0F, $27);

function GetMItemFlag2 (itemNum: integer): integer; tool ($0F, $4C);

function GetMItemIcon (itemNum: integer): longint; tool ($0F, $48);

function GetMItemMark (itemNum: integer): integer; tool ($0F, $34);

function GetMItemStruct (itemNum: integer): longint; tool ($0F, $4A);

function GetMItemStyle (itemNum: integer): integer; tool ($0F, $36);

function GetMTitleStart: integer; tool ($0F, $1A);

function GetMTitleWidth (menuNum: integer): integer; tool ($0F, $1E);

function GetPopUpDefProc: procPtr; tool ($0F, $3B);

function GetSysBar: ctlRecHndl; tool ($0F, $11);

procedure HideMenuBar; tool ($0F, $45);

procedure HiliteMenu (hiliteFlag: boolean; menuNum: integer); tool ($0F, $2C);

procedure InitPalette; tool ($0F, $2F);

procedure InsertMenu (addMenu: menuHandle; insertAfter: integer);
tool ($0F, $0D);

procedure InsertMItem (addItem: cStringPtr; insertAfter, menuNum: integer);
tool ($0F, $0F);

procedure InsertMItem2 (refDescriptor: integer; menuItemTRef: longint;
                        insertAfter, menuNum : integer); tool ($0F, $3F);

procedure InsertPathMItems (flags: integer; pathPtr: gsosInString;
   deviceNum, menuID, afterID, startingID: integer; result: menuResult);
   tool ($0F, $50);

function MenuGlobal (menuGlobalMask: integer): integer; tool ($0F, $23);

procedure MenuKey (var theTask: eventRecord; theMenuBar: ctlRecHndl); tool ($0F, $09);

procedure MenuNewRes; tool ($0F, $29);

procedure MenuRefresh (redrawPtr: procPtr); tool ($0F, $0B);

procedure MenuSelect (var theTask: eventRecord; theMenuBar: ctlRecHndl);
tool ($0F, $2B);

function NewMenu (newMenuString: textPtr): menuHandle; tool ($0F, $2D);

function NewMenu2 (refDescriptor: integer; menuTRef: longint):
                   menuHandle; tool ($0F, $3E);
                  
function NewMenuBar (theWindow: grafPortPtr): ctlRecHndl; tool ($0F, $15);

function NewMenuBar2 (refDescriptor: integer; menuBarTRef: univ longint;
                      theWindow: grafPortPtr): menuBarHandle; tool ($0F, $43);
                     
function PopUpMenuSelect (selection, currentLeft, currentTop, flag: integer;
                          theMenu: menuHandle): integer; tool ($0F, $3C);
                  
procedure RemoveMItemStruct (itemID: integer); tool ($0F, $4B);

procedure SetBarColors (newBarColor, newInvertColor, newOutColor: integer);
tool ($0F, $17);

procedure SetMenuBar (theBarHandle: ctlRecHndl); tool ($0F, $39);

procedure SetMenuFlag (newvalue, menuNum: integer); tool ($0F, $1F);

procedure SetMenuID (newMenuNum, curMenuNum: integer); tool ($0F, $37);

procedure SetMenuTitle (newTitle: cStringPtr; menuNum: integer);
tool ($0F, $21);

procedure SetMenuTitle2 (refDescriptor: integer; titleRef: longint;
                         menuNum: integer); tool ($0F, $40);
               
procedure SetMItem (newItem: cStringPtr; itemNum: integer); tool ($0F, $24);

procedure SetMItem2 (refDescriptor: integer; menuItemTRef: longint;
                     menuItem: integer); tool ($0F, $41);

procedure SetMItemBlink (count: integer); tool ($0F, $28);

procedure SetMItemFlag (newValue, itemNum: integer); tool ($0F, $26);

procedure SetMItemFlag2 (newValue, itemNum: integer); tool ($0F, $4D);

procedure SetMItemIcon (iconDesc: integer; iconRef: univ longint;
   itemID: integer); tool ($0F, $47);

procedure SetMItemID (newItemNum, curItemNum: integer); tool ($0F, $38);

procedure SetMItemMark (mark, itemNum: integer); tool ($0F, $33);

procedure SetMItemName (newName: pStringPtr; itemNum: integer); tool ($0F, $3A);

procedure SetMItemName2 (refDescriptor: integer; titleRef: longint;
                         menuItem: integer); tool ($0F, $42);
            
procedure SetMItemStruct (itemStructDesc: integer; itemStructRef: univ longint;
   itemNum: integer); tool ($0F, $49);

procedure SetMItemStyle (textStyle, itemNum: integer); tool ($0F, $35);

procedure SetMTitleStart (xStart: integer); tool ($0F, $19);

procedure SetMTitleWidth (newWidth, menuNum: integer); tool ($0F, $1D);

procedure SetSysBar (theBarHandle: ctlRecHndl); tool ($0F, $12);

procedure ShowMenuBar; tool ($0F, $46);

implementation
end.
