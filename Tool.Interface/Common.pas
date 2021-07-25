{$keep 'Common'}
unit Common;
interface

{********************************************************
*
*  Common Types Interface File
*
*  Other USES Files Needed: - None -
*
*  Copyright 1987-1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

const
   {Reference verbs describing parameter type.}
   pointerVerb     =   $0000;           {parm is pointer to block of data}
   handleVerb      =   $0001;           {parm is handle of block of data}
   resourceVerb    =   $0002;           {parm is resource ID}
   newHandleVerb   =   $0003;           {tool is to create new handle}

   {TaskMaster/Event Manager result codes}
   nullEvt         =   $0000;
   inNull          =   $0000;
   wNoHit          =   $0000;
   mouseDownEvt    =   $0001;
   inButtDwn       =   $0001;
   mouseUpEvt      =   $0002;
   keyDownEvt      =   $0003;
   inKey           =   $0003;
   autoKeyEvt      =   $0005;
   updateEvt       =   $0006;
   inUpdate        =   $0006;
   activateEvt     =   $0008;
   switchEvt       =   $0009;
   deskAccEvt      =   $000A;
   driverEvt       =   $000B;
   app1Evt         =   $000C;
   app2Evt         =   $000D;
   app3Evt         =   $000E;
   app4Evt         =   $000F;
   wInDesk         =   $0010;      {in desktop}
   wInMenuBar      =   $0011;      {in system menu bar}
   wClickCalled    =   $0012;      {system click called}
   wInContent      =   $0013;      {in content region of window}
   wInDrag         =   $0014;      {in drag region of window}
   wInGrow         =   $0015;      {in grow box of active window}
   wInGoAway       =   $0016;      {in close box of active window}
   wInZoom         =   $0017;      {in zoom box of active window}
   wInInfo         =   $0018;      {in information bar of window}
   wInSpecial      =   $0019;      {item ID selected was 250-255}
   wInDeskItem     =   $001A;      {item ID selected was 1-249}
   wInFrame        =   $001B;      {in frame, but not on anything else}
   wInactMenu      =   $001C;      {inactive menu item selected}
   wClosedNDA      =   $001D;      {desk accessory closed}
   wCalledSysEdit  =   $001E;      {inactive menu item selected}
   wTrackZoom      =   $001F;      {zoom box clicked, but not selected}
   wHitFrame       =   $0020;      {button down on frame, made active}
   wInControl      =   $0021;      {button or keystroke in control}
   wInSysWindow    =   $8000;      {high-order bit set for system windows}

type
   {GS/OS class 1 input string}
   gsosInString = record
       size:  integer;
      {Change the array size as needed for your application}
       theString:  packed array [1..254] of char;
       end;
   gsosInStringPtr = ^gsosInString;

   {GS/OS class 1 output string}
   gsosOutString = record
       maxSize:    integer;
       theString:  gsosInString;
       end;
   gsosOutStringPtr = ^gsosOutString;

   {GS/OS option list}
   optionListRecord = record
      totalSize: integer;
      requiredSize: integer;
      fileSysID: integer;
     {Change size of theData as needed}
      theData: packed array [1..100] of char;
      end;
   optionListPtr = ^optionListRecord;

   {GS/OS time field}
   timeField = array[1..8] of byte;

   {ProDOS 16 pathname}
   pathName = packed array [0..128] of char;
   pathPtr = ^pathName;

   {String with a length byte}
   pString = packed array [0..255] of char;
   pStringPtr = ^pString;

   {Null-terminated string}
   cString = packed array [1..256] of char;
   cStringPtr = ^cString;

   {Unterminated text; length specified separately. Array size can be}
   {adjusted by user.}
   textBlock = packed array [1..300] of char;
   textPtr = ^textBlock;

   {"General" types to circumvent type checking by the compiler}
   ptr        = ^byte;
   handle     = ^ptr;
   rgnHandle  = handle;
   procPtr    = ptr;
   integerPtr = ^integer;
   longintPtr = ^longint;
   fixed      = longint;

   {Point}
   point = record
       v: integer;
       h: integer;
       end;
   pointPtr = ^point;

   {Rectangle}
   rectKinds = (normal, mac, points);

   rect = record
     case rectKinds of
       normal:  (v1: integer;
                 h1: integer;
                 v2: integer;
                 h2: integer);

       mac:     (top:    integer;
                 left:   integer;
                 bottom: integer;
                 right:  integer);

       points:  (topLeft:  point;
                 botRight: point);
       end;
   rectPtr = ^rect;

   {Color table}
   colorTable     = array [0..15] of integer;
   colorTblPtr    = ^colorTable;
   colorTablePtr  = ^colorTable;
   colorTableHndl = ^ColorTablePtr;
   
   {Event record}
   eventRecord = record
       eventWhat:      integer;
       eventMessage:   longint;
       eventWhen:      longint;
       eventWhere:     point;
       eventModifiers: integer;

  {The following fields are required by TaskMaster.  They can be removed }
  {(but do not have to be) if you are not using TaskMaster.              }

       taskData:       longint;
       taskMask:       longint;
       lastClickTick:  longint;
       ClickCount:     integer;
       TaskData2:      longint;
       TaskData3:      longint;
       TaskData4:      longint;
       lastClickPt:    point;
       end;
   eventRecPtr = ^eventRecord;
   wmTaskRec   = eventRecord;

   {Pattern}
   pattern = array [0..31] of byte;
   patternPtr = ^pattern;

   {Font record}
   font = record
       offsetToMF:  integer;
       family:      integer;
       style:       integer;
       size:        integer;
       version:     integer;
       fbrExtent:   integer;
       highowTLoc:  integer;
   {                                                                    }
   {The rest of the font record cannot be easily accessed from Pascal,  }
   {as it is intended to change dynamically at run-time.  The record is }
   {included here for completeness.                                     }
   {                                                                    }
   {Array of bytes, as defined by the user:                             }
   {                                                                    }
   { additionalFields: array [0..n] of byte;                            }
   {                                                                    }
   { fontType: integer;               - ignored on the AppleIIgs -      }
   {                                                                    }
   { firstChar:   integer;                                              }
   { lastChar:    integer;                                              }
   { widMax:      integer;                                              }
   { kernMax:     integer;                                              }
   { nDescent:    integer;                                              }
   { fRectWidth:  integer;                                              }
   { fRectHeight: integer;                                              }
   { owTLoc:      integer;                                              }
   { ascent:      integer;                                              }
   { descent:     integer;                                              }
   { leading:     integer;                                              }
   { rowWords:    integer;                                              }
   {                                                                    }
   {Three arrays, as defined by the user:                               }
   {                                                                    }
   { bitImage: array [1..rowWords, 1..fRectHeight] of integer;          }
   { locTable: array [firstChar..lastChar+2] of integer;                }
   { owTable:  array [firstChar..lastChar+2] of integer;                }

       end;
   fontRec = ^font;
   fontHndl = ^fontRec;

   {Location information record}
   locInfo = record
       portSCB:          integer;
       ptrToPixelImage:  ptr;
       width:            integer;
       boundsRect:       rect;
       end;
   locInfoPtr = ^locInfo;

   {Mask}
   mask = array [0..7] of byte;
   maskPtr = ^mask;

   {Font ID}
   fontID = record
       famNum: integer;
       fontStyle, fontSize: byte;
       end;

   {Font stats record}
   fontStatRec = record
       resultID:    fontID;
       resultStats: integer;
       end;
   fontStatRecPtr = ^fontStatRec;

   ctlPtr = ^ctlRec;
   ctlRecHndl = ^ctlPtr;

   {Graphics port}
   grafPort = record
       portInfo:   locInfo;
       portRect:   rect;
       clipRgn:    rgnHandle;
       visRgn:     rgnHandle;
       bkPat:      pattern;
       pnLoc:      point;
       pnSize:     point;
       pnMode:     integer;
       pnPat:      pattern;
       pnMask:     mask;
       pnVis:      integer;
       fontHandle: fontHndl;
       theFontID:  fontID;
       fontFlags:  integer;
       txSize:     integer;
       txFace:     integer;
       txMode:     integer;
       spExtra:    fixed;
       chExtra:    fixed;
       fgColor:    integer;
       bgColor:    integer;
       picSave:    handle;
       rgnSave:    handle;
       polySave:   handle;
       grafProcs:  ptr;
       arcRot:     integer;
       userField:  longint;
       sysField:   longint;
     {These additional fields are used by the Window Manager.}
       wDefProc:    longint;
       wRefCon:     longint;
       wContDraw:   longint;
       wReserved:   longint;
       wStructRgn:     rgnHandle;
       wContRgn:       rgnHandle;
       wUpdateRgn:     rgnHandle;
       wControl:       ctlRecHndl;
       wFrameControl:  ctlRecHndl;
       wFrame:         integer;
       end;
   grafPortPtr = ^grafPort;

   {Member record}
   memRec = record
       memPtr:  pStringPtr;
       memFlag: byte;
   {Rest is defined by user}
       end;
   memRecPtr = ^memRec;

   {Scroll bar color table}
   barColors = record
       barOutline:   integer;
       barNorArrow:  integer;
       barSelArrow:  integer;
       barArrowBack: integer;
       barNorThumb:  integer;
       barSelThumb:  integer;
       barPageRgn:   integer;
       barInactive:  integer;
       end;
   barColorsPtr = ^barColors;

   {Menu record}
   menu = record
       menuID:     integer;
       menuWidth:  integer;
       menuHeight: integer;
       menuProc:   procPtr;
       menuFlag:   byte;
       menuRes:    byte;
       numOfItems: integer;
       titleWidth: integer;
       titleName:  pStringPtr;
       menuCache:  handle;
       end;
   menuPtr = ^menu;
   menuHandle = ^menuPtr;

   textList = record
       cachedHandle: longint;
       cachedOffset: longint;
       end;

   superHandle = record
       cachedHandle:  longint;
       cachedOffset:  longint;
       cachedIndex:   integer;
       end;

   teStyle = record
       teFont:     fontID;
       foreColor:  integer;
       backColor:  integer;
       userData:   longint;
       end;

   keyRecord = record
       theChar:         integer;
       theModifiers:    integer;
       theInputHandle:  longint;
       cursorOffset:    longint;
       theOpCode:       integer;
       end;

   keyEquivRec = record
       key1:          byte;
       key2:          byte;
       keyModifiers:  integer;
       keyCareBits:   integer;
       end;

   ctlType = (generic, btnOrCheck, icon, lnEdPicGrow, list, popUp, scroll,
              staticText, textEdit);

   {Control record}
   ctlRec = record
       ctlNext:   ctlRecHndl;
       ctlOwner:  grafPortPtr;
       ctlRect:   rect;
       ctlFlag:   byte;
       ctlHilite: byte;
       ctlValue:  integer;
       ctlProc:   procPtr;
       ctlAction: procPtr;
       ctlData:   longint;
       ctlRefCon: longint;
       ctlColor:  colorTblPtr;
   {These new fields have been added for GS/OS 5.0 calls.}
       case ctlType of
           generic:      (ctlReserved:      packed array [0..15] of byte;
                          ctlID:            longint;
                          ctlMoreFlags:     integer;
                          ctlVersion:       integer);

           btnOrCheck:   (keyEquiv1:        keyEquivRec;
                          reserved1:        packed array [1..10] of byte;
                          ctlID1:           longint;
                          ctlMoreFlags1:    integer;
                          ctlVersion1:      integer);

           icon:         (keyEquiv2:        keyEquivRec;
                          reserved2:        packed array [1..10] of byte;
                          ctlID2:           longint;
                          ctlMoreFlags2:    integer;
                          ctlVersion2:      integer;
                          iconRef:          longint;
                          displayMode:      integer);

           lnEdPicGrow:  (reserved3:        packed array [1..10] of byte;
                          ctlID3:           longint;
                          ctlMoreFlags3:    integer;
                          ctlVersion3:      integer);

           list:         (ctlMemDraw:       procPtr;
                          ctlMemHeight:     integer;
                          ctlMemSize:       integer;
                          ctlListRef:       longint;
                          ctlListBar:       ctlRecHndl;
                          ctlID4:           longint;
                          ctlMoreFlags4:    integer;
                          ctlVersion4:      integer);

           popUp:        (menuRef:          longint;
                          menuEnd:          longint;
                          popUpRect:        rect;
                          ctlID5:           longint;
                          ctlMoreFlags5:    integer;
                          ctlVersion5:      integer;
                          titleWidth:       integer);

           scroll:       (thumbRect:        rect;
                          pageRegion:       rect;
                          ctlID6:           longint;
                          ctlMoreFlags6:    integer;
                          ctlVersion6:      integer);

           staticText:   (ctlJust:          integer;
                          reserved7:        packed array [1..14] of byte;
                          ctlID7:           longint;
                          ctlMoreFlags7:    integer;
                          ctlVersion7:      integer);

           textEdit:     (textFlags:        longint;
                          textLength:       longint;
                          blockList:        textList;
                          ctrlID8:          integer;
                          ctrlMoreFlags8:   integer;
                          ctrlVersion8:     integer;
                          viewRect:         rect;
                          totalHeight:      longint;
                          lineSuper:        superHandle;
                          styleSuper:       superHandle;
                          styleList:        handle;
                          rulerList:        handle;
                          lineAtEndFlag:    integer;
                          selectionStart:   longint;
                          selectionEnd:     longint;
                          selectionActive:  integer;
                          selectionState:   integer;
                          caretTime:        longint;
                          nullStyleActive:  integer;
                          nullStyle:        teStyle;
                          topTextOffset:    longint;
                          topTextVPos:      integer;
                          vertScrollBar:    ctlRecHndl;
                          vertScrollPos:    longint;
                          vertScrollMax:    longint;
                          vertScrollAmount: integer;
                          horzScrollBar:    ctlRecHndl;
                          horzScrollPos:    longint;
                          horzScrollMax:    longint;
                          horzScrollAmount: integer;
                          growBoxHandle:    ctlRecHndl;
                          maximumChars:     longint;
                          maximumLines:     longint;
                          maxCharsPerLine:  integer;
                          maximumHeight:    integer;
                          textDrawMode:     integer;
                          wordBreakHook:    procPtr;
                          wordWrapHook:     procPtr;
                          keyFilter:        procPtr;
                          theFilterRect:    rect;
                          theBufferVPos:    integer;
                          theBufferHPos:    integer;
                          theKeyRecord:     keyRecord;
                          cachedSelcOffset: longint;
                          cachedSelcVPos:   integer;
                          cachedSelcHPos:   integer;
                          mouseRect:        rect;
                          mouseTime:        longint;
                          mouseKind:        integer;
                          lastClick:        longint;
                          savedHPos:        integer;
                          anchorPoint:      longint);
       end;

   {Menu bar record}
   menuBar = record
       ctlNext:   ctlRecHndl;
       ctlOwner:  grafPortPtr;
       ctlRect:   rect;
       ctlFlag:   byte;
       ctlHilite: byte;
       ctlValue:  integer;
       ctlProc:   procPtr;
       ctlAction: procPtr;
       ctlData:   longint;
       ctlRefCon: longint;
       ctlColor:  colorTblPtr;
   {Change size of array for application}
       menuList:  array [1..10] of menuHandle;
       end;
   menuBarPtr = ^menuBar;
   menuBarHandle = ^menuBarPtr;

implementation
end.
