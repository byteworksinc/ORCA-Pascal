{$keep 'SFToolSet'}
unit SFToolSet;
interface

{********************************************************
*
*   Standard File Operations Tool Set Interface File
*
*   Other USES Files Needed: Common, Dialog Manager
*
*   Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                            Miscellaneous Tool Set, QuickDraw II,
*                            Event Manager, Window Manager, Control Manager,
*                            Menu Manager, LineEdit Tool Set, Dialog Manager
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common, DialogMgr;

const
   (* Filter procedure results. *)
   noDisplay       =   $0000;      (* don't display file                      *)
   noSelect        =   $0001;      (* display file, but don't allow selection *)
   displaySelect   =   $0002;      (* display file and allow selection        *)

type
   typeList = record
       numEntries: byte;
       fileType:   array [1..10] of byte;    (* Array can be expanded *)
       end;
   typeListPtr = ^typeList;

   replyRecord = record
       good:         boolean;
       fileType:     integer;
       auxFileType:  integer;
       fileName:     packed array [0..15] of char;
       fullPathName: pathName;
       end;

   replyRecord5_0 = record
       good:         integer;
       fileType:     integer;
       auxFileType:  longint;
       nameVerb:     integer;
       nameRef:      longint;
       pathVerb:     integer;
       pathRef:      longint;
       end;

   typeRec = record
       flags:     integer;
       fileType:  integer;
       auxType:   longint;
       end;

   typeList5_0 = record
       numEntries:       integer;
       fileAndAuxTypes:  array [1..10] of typeRec;     (* change array size *)
       end;                                            (*   as needed       *)
   typeList5_0Ptr = ^typeList5_0;

   multiReplyRecord = record
      good:         integer;
      namesHandle:  handle;
      end;   


procedure SFBootInit; tool ($17, $01);     (* WARNING: an application should
                                                       NEVER make this call *)

procedure SFStartup (userID, dPageAddr: integer); tool ($17, $02);

procedure SFShutDown; tool ($17, $03);

function SFVersion: integer; tool ($17, $04);

procedure SFReset; tool ($17, $05);        (* WARNING: an application should
                                                       NEVER make this call *)

function SFStatus: boolean; tool ($17, $06);

procedure SFAllCaps (allCapsFlag: boolean); tool ($17, $0D);

procedure SFGetFile (whereX, whereY: integer; prompt: univ pStringPtr;
                     filterProc: procPtr; theTypeList: typeListPtr;
                     var theReply: replyRecord); tool ($17, $09);

procedure SFGetFile2 (whereX, whereY, promptVerb: integer;
                      promptRef: univ longint; filterProcPtr: procPtr;
                      var theTypeList: typeList5_0;
                      var theReply: replyRecord5_0); tool ($17, $0E);

procedure SFMultiGet2 (whereX, whereY, promptVerb: integer;
                       promptRef: univ longint; filterProcPtr: procPtr;
                       var theTypeList: typeList5_0;
                       var theReply: multiReplyRecord); tool ($17, $14);
       
procedure SFPGetFile (whereX, whereY: integer; prompt: univ pStringPtr;
                      filterProc: procPtr; theTypeList: typeListPtr;
                      theDialogTemplate: dialogTempPtr; dialogHookPtr: procPtr;
                      var theReply: replyRecord); tool ($17, $0B);

procedure SFPGetFile2 (whereX, whereY: integer; itemDrawPtr: procPtr;
                       promptVerb: integer; promptRef: univ longint;
                       filterProcPtr: procPtr; var theTypeList: typeList5_0;
                       var dlgTemp: dialogTemplate; dialogHookPtr: procPtr;
                       var theReply: replyRecord5_0); tool ($17, $10);

procedure SFPMultiGet2 (whereX, whereY: integer; itemDrawPtr: procPtr;
                        promptVerb: integer; promptRef: univ longint;
                        filterProcPtr: procPtr;
                        var theTypeList: typeList5_0;
                        var dlgTemp: dialogTemplate; dialogHookPtr: procPtr;
                        var theReply: multiReplyRecord); tool ($17, $15);
       
procedure SFPPutFile (whereX, whereY: integer; prompt, origName: univ pStringPtr;
                      maxLen: integer; theDialogTemplate: dialogTempPtr;
                      dialogHookPtr: procPtr; var theReply: replyRecord);
                      tool ($17, $0C);

procedure SFPPutFile2 (whereX, whereY: integer; itemDrawPtr: procPtr;
                       promptVerb: integer; promptRef: univ longint;
                       origNameVerb: integer; origNameRef:  univ longint;
                       var dlgTemp: dialogTemplate; dialogHookPtr: procPtr;
                       var theReply: replyRecord5_0); tool ($17, $11);
       
procedure SFPutFile (whereX, whereY: integer; prompt, origName: univ pStringPtr;
                     maxLen: integer; var theReply: replyRecord);
                     tool ($17, $0A);

procedure SFPutFile2 (whereX, whereY, promptVerb: integer;
                      promptRef: univ longint; origNameVerb: integer;
                      origNameRef: univ longint;
                      var theReply: replyRecord5_0); tool ($17, $0F);
            
procedure SFReScan (filterProcPtr: procPtr; var theTypeList: typeList);
tool ($17, $13);

function SFShowInvisible (invisibleState: boolean): boolean; tool ($17, $12);

implementation
end.
