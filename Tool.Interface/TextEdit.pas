{$keep 'TextEdit'}
unit TextEdit;
interface

{********************************************************
*
*   Text Edit Tool Set Interface File
*
*   Other USES Files Needed: Common
*
*   Other Tool Sets Needed:  Tool Locator, Miscellaneous Tool Set,
*                            QuickDraw II, Event Manager,
*                            Window Manager, Control Manager,
*                            Menu Manager, QuickDraw Auxiliary,
*                            Scrap Manager, Font Manager, Resource Manager
*
*  Copyright 1987-1990
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common, ControlMgr;

const
   (* Text Edit error codes *)
   teAlreadyStarted    =   $2201;
   teNotStarted        =   $2202;
   teInvalidHandle     =   $2203;
   teInvalidVerb       =   $2204;
   teInvalidFlag       =   $2205;
   teInvalidPCount     =   $2206;
   teInvalidRect       =   $2207;
   teBufferOverflow    =   $2208;
   teInvalidLine       =   $2209;
   teInvalidCall       =   $220A;
   teInvalidParameter  =   $220B;
   teInvalidTextBox2   =   $220C;

   (* Text descriptors:  Bits 0-2 of descriptor word *)
   dataIsPString       =   $000;
   dataIsCString       =   $001;
   dataIsC1Input       =   $002;
   dataIsC1Output      =   $003;
   dataIsTextBox2      =   $004;
   dataIsTextBlock     =   $005;

   (* Text Edit reference descriptors *)
   teRefIsPtr          =   $0000;
   teRefIsHandle       =   $0001;
   teRefIsResource     =   $0002;
   teRefIsNewHandle    =   $0003;

type
   teColorTablePtr = ^TEColorTable;
   teColorTable = record
       contentColor:         integer;
       outlineColor:         integer;
       hiliteForeColor:      integer;
       hiliteBackColor:      integer;
       vertColorDescriptor:  integer;
       vertColorRef:         longint;
       horzColorDescriptor:  integer;
       horzColorRef:         longint;
       growColorDescriptor:  integer;
       growColorRef:         longint;
       end;

   teTextBlock = record
       nextHandle: longint;
       prevHandle: longint;
       textLength: longint;
       flags:      integer;
       reserved:   integer;
   (* Change size of array to suit your needs. *)
       theText:    packed array [1..512] of text;
       end;

   superItem = record
       theLength:  longint;
       theData:    longint;
       end;

   superBlock = record
       nextHandle:  longint;
       prevHandle:  longint;
       textLength:  longint;
       reserved:    longint;
   (* Change the array size to suit your needs. *)
       theItems:    array [1..10] of superItem;
       end;

   (* Definitions of textList, superHandle, teStyle, and keyRecord can be *)
   (* found in the Common.Intf interface file.                            *)

   teHandle = ctlRecHndl;
   teRecPtr = ctlPtr;
   teTabItem = record
       tabKind: integer;
       tabData: integer;
       end;

   teRuler = record
       leftMargin:     integer;
       leftIndent:     integer;
       rightMargin:    integer;
       just:           integer;
       extraLS:        integer;
       flags:          integer;
       userData:       longint;
       tabType:        integer;
   (* Change size of array for application. *)
       tabs:           array [1..1] of teTabItem;
       tabTerminator:  integer;
       end;

   teStyleGroupHndl = ^teStyleGroupPtr;
   teStyleGroupPtr  = ^teStyleGroup;
   teStyleGroup = record
       count:   integer;
   (* Change array size for application. *)
       styles:  array [1..1] of teStyle;
       end;

   teStyleItem = record
       length:  longint;
       offset:  longint;
       end;

   teFormatHndl = ^teFormatPtr;
   teFormatPtr  = ^teFormat;
   teFormat = record
       version:          integer;
       rulerListLength:  longint;
   (* Change array size for application. *)
       theRulerList:     array [1..1] of teRuler;
       styleListLength:  longint;
   (* Change array size for application. *)
       theStyleList:     array [1..1] of teStyle;
       numberOfStyles:   longint;
   (* Change array size for application. *)
       theStyles:        array [1..1] of teStyleItem;
       end;

   teTextRef  = longint;
   teStyleRef = longint;

   (* The TEParamBlock record appears in the Resource Manager interface file *)
   (* as editTextControl.                                                    *)

   teInfoRec = record
       charCount:     longint;
       lineCount:     longint;
       formatMemory:  longint;
       totalMemory:   longint;
       styleCount:    longint;
       rulerCount:    longint;
       end;

   teHooks = record
       charFilter:  procPtr;
       wordWrap:    procPtr;
       wordBreak:   procPtr;
       drawText:    procPtr;
       eraseText:   procPtr;
       end;


procedure TEBootInit; tool ($22, $01);

procedure TEStartup (myId: integer; directPage: integer); tool ($22, $02);

procedure TEShutDown; tool ($22, $03);

function TEVersion: integer; tool ($22, $04);

procedure TEReset; tool ($22, $05);

function TEStatus: boolean; tool ($22, $06);

procedure TEActivate (theTERecord: teHandle); tool ($22, $0F);

procedure TEClear (theTERecord: teHandle); tool ($22, $19);

procedure TEClick (var theEvent: eventRecord; theTERecord: teHandle);
tool ($22, $11);

procedure TECopy (theTERecord: teHandle); tool ($22, $17);

procedure TECut (theTERecord: teHandle); tool ($22, $16);

procedure TEDeactivate (theTERecord: teHandle); tool ($22, $10);

function TEGetDefProc: procPtr; tool ($22, $22);

procedure TEGetRuler (rulerDescriptor: integer; rulerRef: univ longint;
                      theTERecord: teHandle); tool ($22, $23);

procedure TEGetSelection (selectionStart, selectionEnd: univ ptr;
                          theTERecord: teHandle); tool ($22, $1C);

function TEGetSelectionStyle (var commonStyle: teStyle; 
                              styleHandle: TEStyleGroupHndl;
                              theTERecord: teHandle): integer; tool ($22, $1E);

function TEGetText (bufferDescriptor: integer; bufferRef: univ longint;
                    bufferLength: longint; styleDescriptor: integer;
                    styleRef: univ longint; theTERecord: teHandle): longint;
tool ($22, $0C);

procedure TEGetTextInfo (var infoRec: teInfoRec; parameterCount: integer;
                         theTERecord: teHandle); tool ($22, $0D);

procedure TEIdle (theTERecord: teHandle); tool ($22, $0E);

procedure TEInsert (textDescriptor: integer; textRef: teTextRef; 
                    textLength: longint; styleDescriptor: integer; 
                    styleRef: teStyleRef; theTERecord: teHandle);
tool ($22, $1A);

procedure TEInsertPageBreak; tool ($22, $23);

procedure TEKey (var theEventRecord: eventRecord; theTERecord: teHandle);
tool ($22, $14);

procedure TEKill (theTERecord: teHandle); tool ($22, $0A);

function TENew (var parameterBlock: editTextControl): teHandle; tool ($22, $09);

procedure TEOffsetToPoint (textOffset: longint; vertPosPtr, horzPosPtr: ptr;
                           theTERecord: teHandle); tool ($22, $20);

function TEPaintText (thePort: grafPortPtr; startingLine: longint;
                      var destRect: rect; flags: integer;
                      theTERecord: teHandle): longint; tool ($22, $13);

procedure TEPaste (theTERecord: teHandle); tool ($22, $18);

function TEPointToOffset (vertPos, horzPos: longint; theTERecord: teHandle):
                          longint; tool ($22, $21);

procedure TEReplace (textDescriptor: integer; textRef: teTextRef; 
                     textLength: longint; styleDescriptor: integer; 
                     styleRef: teStyleRef; theTERecord: teHandle);
tool ($22, $1B);

procedure TEScroll (scrollDescriptor: integer; vertAmount, horzAmount: longint;
                    theTERecord: teHandle); tool ($22, $25);

procedure TESetRuler (rulerDescriptor: integer; rulerRef: univ longint;
                      theTERecord: teHandle); tool ($22, $24);

procedure TESetSelection (selectionStart, selectionEnd: longint; 
                          theTEREcord: teHandle); tool ($22, $1D);

procedure TESetText (textDescriptor: integer; textRef: teTextRef;
                     textLength: longint; styleDescriptor: integer;
                     styleRef: teStyleRef; theTERecord: teHandle);
tool ($22, $0B);

procedure TEStyleChange (flags: integer; var newStyle: teStyle;
                         theTERecord: teHandle); tool ($22, $1F);

procedure TEUpdate (theTERecord: TEHandle); tool ($22, $12);

implementation
end.
