{$keep 'ListMgr'}
unit ListMgr;
interface

{********************************************************
*
*   List Manager Interface File
*
*   Other USES Files Needed:  Common
*
*   Other Tool Sets Needed:   Tool Locator, Memory Manager,
*                             Miscellaneous Tool Set, QuickDraw II,
*                             Event Manager, Window Manager, Control Manager
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Bit mask for listType *)
   cStringFlag     =   $0001;      (* null-terminated string type *)
   selectOnlyOne   =   $0002;      (* only 1 selection allowed    *)

   (* memFlag *)
   memDisabled     =   $40;        (* sets member flag to disabled *)
   memSelected     =   $80;        (* sets member flag to selected *)

type
   (* Member record is defined in the Common.intf inteface file. *)

   memberList = array [1..100] of memRec;   (* user may modify size *)

   listRec = record
       listRect:        rect;
       listSize:        integer;
       listView:        integer;
       listType:        integer;
       listStart:       integer;
       listCtl:         ctlRecHndl;
       listDraw:        procPtr;
       listMemHeight:   integer;
       listMemSize:     integer;
       listPointer:     memRecPtr;
       listRefCon:      longint;
       listScrollClr:   barColorsPtr;
       end;
   listRecPtr = ^listRec;

   (* List control record:  included as part of Control Record. *)
   (* See the Common interface file for this record.            *)

   (* List color table *)
   lColorTable = record
       listFrameClr:   integer;
       listNorTextClr: integer;
       listSelTextClr: integer;
       listNorBackClr: integer;
       listSelBackClr: integer;
       end;


procedure ListBootInit; tool ($1C, $01);   (* WARNING: an application should
                                                       NEVER make this call *)

procedure ListStartUp; tool ($1C, $02);

procedure ListShutDown; tool ($1C, $03);

function ListVersion: integer; tool ($1C, $04);

procedure ListReset; tool ($1C, $05);      (* WARNING: an application should
                                                       NEVER make this call *)

function ListStatus: boolean; tool ($1C, $06);

function CompareStrings (flags: integer; string1, string2: pString): integer;
tool ($1C, $18);

function CreateList (theWindow: grafPortPtr; var theList: listRec): ctlRecHndl;
tool ($1C, $09);

procedure DrawMember (theMember: memRecPtr; var theList: listRec);
tool ($1C, $0C);

procedure DrawMember2 (itemnum: integer; theListCtl: ctlRecHndl);
tool ($1C, $11);
               
function GetListDefProc: procPtr; tool ($1C, $0E);

procedure ListKey (flags: integer; event: eventRecord; listCtl: ctlRecHndl);
tool ($1C, $17);

procedure NewList (theMember: memRecPtr; var theList: listRec);
tool ($1C, $10);

procedure NewList2 (drawRtn: procPtr; listStart: integer; listRef: longint;
                    listRefDesc, listSize: integer; theListCtl: ctlRecHndl);
tool ($1C, $16);
         
function NextMember (firstMember: memRecPtr; var theList: listRec):
                     memRecPtr; tool ($1C, $0B);
 
function NextMember2 (itemNum: integer; theListCtl: ctlRecHndl): integer;
tool ($1C, $12);

function ResetMember (var theList: listRec): memRecPtr; tool ($1C, $0F);

function ResetMember2 (theListCtl: ctlRecHndl): integer; tool ($1C, $13);

procedure SelectMember (theMember: memRecPtr; var theList: listRec);
tool ($1C, $0D);

procedure SelectMember2 (itemNum: integer; theListCtl: ctlRecHndl);
tool ($1C, $14);

procedure SortList (compareRtn: procPtr; var theList: listRec); tool ($1C, $0A);

procedure SortList2 (compareRtn: procPtr; theListCtl: ctlRecHndl);
tool ($1C, $15);

implementation
end.
