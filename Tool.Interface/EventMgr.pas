{$keep 'EventMgr'}
unit EventMgr;
interface

{********************************************************
*
*   Event Manager Interface File
*
*   Other USES Files Needed: Common
*
*   Other Tool Sets Needed:  Tool Locator, Memory Manager,
*                            Miscellaneous Tool Set, Quick Draw II,
*                            Desk Manager, ADB Tool Set
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;

const
   (* Event codes are in the Common.Intf interface file *)

   (* event masks *)
   mDownMask       =   $0002;      (* call applies to mouse-down events     *)
   mUpMask         =   $0004;      (* call applies to mouse-up events       *)
   keyDownMask     =   $0008;      (* call applies to key-down events       *)
   autoKeyMask     =   $0020;      (* call applies to auto-key events       *)
   updateMask      =   $0040;      (* call applies to update events         *)
   activeMask      =   $0100;      (* call applies to activate events       *)
   switchMask      =   $0200;      (* call applies to switch events         *)
   deskAccMask     =   $0400;      (* call applies to desk accessory events *)
   driverMask      =   $0800;      (* call applies to device driver events  *)
   app1Mask        =   $1000;      (* call applies to application-1 events  *)
   app2Mask        =   $2000;      (* call applies to application-2 events  *)
   app3Mask        =   $4000;      (* call applies to application-3 events  *)
   app4Mask        =   $8000;      (* call applies to application-4 events  *)
   everyEvent      =   $FFFF;      (* call applies to all events            *)

   (* journal codes *)
   jcTickCount     =   $00;        (* TickCount call                    *)
   jcGetMouse      =   $01;        (* GetMouse call                     *)
   jcButton        =   $02;        (* Button call                       *)
   jcEvent         =   $04;        (* GetNextEvent and EventAvail calls *)

   (* Modifier flags *)
   activeFlag    = $0001;          (* set if window was activated        *)
   changeFlag    = $0002;          (* set if active window changed state *)
   btn1State     = $0040;          (* set if button 1 was up             *)
   btn0State     = $0080;          (* set if button 0 was up             *)
   appleKey      = $0100;          (* set if Apple key was down          *)
   shiftKey      = $0200;          (* set if Shift key was down          *)
   capsLock      = $0400;          (* set if Caps Lock key was down      *)
   optionKey     = $0800;          (* set if Option key was down         *)
   controlKey    = $1000;          (* set if Control key was down        *)
   keyPad        = $2000;          (* set if keypress was from key pad   *)



procedure EMBootInit; tool ($06, $01); (* WARNING: an application should
                                                   NEVER make this call *)

procedure EMStartUp (dPageAddr, queueSize, xMinClamp, xMaxClamp, yMinClamp,
                     yMaxClamp, userID: integer); tool ($06, $02);

procedure EMShutDown; tool ($06, $03);

function EMVersion: integer; tool ($06, $04);

procedure EMReset; tool ($06, $05);    (* WARNING: an application should
                                                   NEVER make this call *)

function EMStatus: boolean; tool ($06, $06);

function Button (buttonNumber: integer): boolean; tool ($06, $0D);

function DoWindows: integer; tool ($06, $09);  (* WARNING: an application should
                                                   NEVER make this call *)

function EventAvail (eventMask: integer; var theEvent: eventRecord): boolean;
tool ($06, $0B);

(* FakeMouse's modLatch_padding are 2 separate parameters, each 1 byte in  *)
(* length.  Use (modLatch  <<  8 | padding)  to create the parameter.      *)

procedure FakeMouse (changedFlag: integer; modLatch_padding: integer;
                     xPosition, yPosition, buttonStatus: integer);
tool ($06, $19);

function FlushEvents (eventMask, stopMask: integer): integer; tool ($06, $15);

function GetCaretTime: longint; tool ($06, $12);

function GetDblTime: longint; tool ($06, $11);

function GetKeyTranslation: integer; tool ($06, $1B);

procedure GetMouse (var mouseLocPtr: point); tool ($06, $0C);

function GetNextEvent (eventMask: integer; var theEvent: eventRecord): boolean;
tool ($06, $0A);

function GetOSEvent (eventMask: integer; var theEvent: eventRecord): boolean;
tool ($06, $16);

function OSEventAvail (eventMask: integer; var theEvent: eventRecord): boolean;
tool ($06, $17);

function PostEvent (eventCode: integer; eventMsg: longint): integer;
tool ($06, $14);

procedure SetAutoKeyLimit (newLimit: integer); tool ($06, $1A);

procedure SetEventMask (systemEventMask: integer); tool ($06, $18);

procedure SetKeyTranslation (kTransID: integer); tool ($06, $1C);

procedure SetSwitch; tool ($06, $13);  (* WARNING: only switcher-type
                                          applications should make this call *)

function StillDown (buttonNumber: integer): boolean; tool ($06, $0E);

function TickCount: longint; tool ($06, $10);

function WaitMouseUp (buttonNumber: integer): boolean; tool ($06, $0F);

implementation
end.
