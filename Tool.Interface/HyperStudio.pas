(****************************************************************
*
*  Interface for HyperStudio
*
*  Other USES Files Needed: - None -
*
*  February 1993
*  Mike Westerfield
*
*  Thanks to Ken Kashmarek, who supplied the original files from
*  wich I shamelessly swiped the names used here.  (Of course,
*  that made it easier for him to convert his software!)
*
*  Copyright 1993
*  Byte Works, Inc.
*
****************************************************************)

{$keep 'HyperStudio'}

unit HyperStudio;

interface

uses Common;

const
					{Callback numbers}
   cMoveToFirst = 1;
   cMoveToLast = 2;
   cMovePrev = 3;
   cMoveNext = 4;
   cMoveToID = 5;
   cRedrawCard = 6;
   cGetStackName = 7;
   cFindText = 8;
   cPokeyFlag = 9;
   cDoMenu = 10;
   cGetHSMode = 11;
   cGetHSVersion = 12;
   cGetStackPathName = 13;
   cGetNumCards = 14;
   cGetNumButtons = 15;
   cGetNumFields = 16;
   cGetNumGraphics = 17;
   cPoint2StackHead = 18;
   cPoint2FirstCard = 19;
   cPoint2CurrCard = 20;
   cPoint2NextCard = 21;
   cPoint2CardItems = 22;
   cPoint2NextCdItem = 23;
   cPoint2StackItem = 24;
   cGetCallerAddr = 25;
   cHideStackItem = 26;
   cShowStackItem = 27;
   cLockItem = 28;
   cUnLockItem = 29;
   cDeleteStackItem = 30;
   cGetItemRect = 31;
   cSetItemRect = 32;
   cGetButtonIcon = 33;
   cSetButtonIcon = 34;
   cGetItemStats = 35;
   cLaunchApplication = 36;
   cGetItemLoc = 37;
   cRedrawItem = 38;
   cMouseClick = 39;
   cGetHSCursorAdr = 40;
   cPassText = 41;
   cGetClickLoc = 42;
   cExecuteButton = 43;
   cScrollField = 44;
   cSetHSFont = 45;
   cSetBrushNum = 46;
   cSetLineWidth = 47;
   cGetOffScreen = 48;
   cGetCurrentScore = 49;
   cSetNextTransition = 50;
   cIsMenuThere = 51;
   cGetUndoBuffer = 52;
   cGetCardPalette = 53;
   cPlayDiskSound = 54;
   cPlayResSound = 55;
   cGetSelectedInfo = 56;
   cGetPatterns = 57;
   cGetFieldText = 58;
   cSetFieldText = 59;
   cGetHSFont = 60;
   cLoadPaintFile = 61;
   cSwapCardPos = 62;
   cSortCards = 63;
   cSetDirtyFlag = 64;
   cAddScript2Button = 65;
   cCreatePaletteWindow = 66;
   cCallNBA = 67;
   cCallHS_XCMD = 68;
   cGetResRefNums = 69;
   cSetBkgdDirty = 70;
   cPlaySound = 71;
   cGetAdvancedUser = 72;
   cVideoOn = 73;
   cVideoOff = 74;
   cMakeTransMask = 75;
   cInitTrans = 76;
   cIncTrans = 77;
   cHorizStrip = 78;
   cVertStrip = 79;
   cBrushDialog = 80;
   cLineDialog = 81;
   cPatternDialog = 82;
   cColorDialog = 83;
   cStartDrawing = 84;
   cDrawToScreen = 85;
   cDrawToOffScreen = 86;
   cEndDrawing = 87;
   cSetDrawColor = 88;
   cGetNewBtnName = 89;
   cGetSndStatus = 90;
   cSetMarkedCard = 91;
   cGetNewExtrasMenu = 92;
   cGetOtherCursors = 93;
   cDoButtonAnimation = 94;
   cPlayAnimation = 95;
   cFlush2Undo = 96;
   cLoadStackField = 97;
   cSaveStackField = 98;
   cPrintStackField = 99;
   cLoadText = 100;
   cSaveText = 101;
   cPrintText = 102;
   cGetPaintVars = 103;
   cGetItemHandle = 104;
   cBeginXSound = 105;
   cEndXSound = 106;
   cGetColorCtlDefProc = 107;

   mAboutHyperStudio = 0;
   mPreferences = 1;
   mNewStack = 2;
   mOpenStack = 3;
   mSaveStack = 4;
   mSaveStackAs = 5;
   mLoadBackground = 6;
   mSaveBackground = 7;
   mAddClipArt = 8;
   mPageSetup = 9;
   mPrint = 10;
   mQuit = 11;
   mUndo = 12;
   mCut = 13;
   mCopy = 14;
   mPaste = 15;
   mClear = 16;
   mNewCard = 17;
   mDeleteCard = 18;
   mCutCard = 19;
   mCopyCard = 20;
   mFlipHorizontal = 21;
   mFlipVertical = 22;
   mEraseBackground = 23;
   mBack = 24;
   mHome = 25;
   mFirstCard = 26;
   mPreviousCard = 27;
   mNextCard = 28;
   mLastCard = 29;
   mMoveToCard = 30;
   mFindText = 31;
   mSetCurrentTool = 32;
   mItemInfo = 33;
   mCardInfo = 34;
   mBackgroundInfo = 35;
   mStackInfo = 36;
   mBringCloser = 37;
   mSendFarther = 38;
   mAddButton = 39;
   mAddGraphic = 40;
   mAddField = 41;
   mAddVideo = 42;
   mSetCurrentColor = 43;
   mLineSizedialog = 44;
   mBrushShapedialog = 45;
   mToggleDrawFilled = 46;
   mToggleDrawMultiple = 47;
   mToggleDrawCentered = 48;
   mTextStyledialog = 49;
   mTextColordialog = 50;
   mBackgroundColordialog = 51;
   mReplaceColorsdialog = 52;
   mEditPattern = 53;
   mStandardPaletteRestore = 54;
   mHideItems = 55;
   mToggleMenubarVisibility = 56;
      
type
   wString = record			{word string}
      length: integer;
      str: packed array[1..256] of char;
      end;
   wStringPtr = ^wString;

   HSParams = record			{HyperStudio Parameters}
      ButtonID: integer;
      CardID: integer;
      ScriptHand: handle;
      ScriptLength: longint;
      TextPassedPtr: wStringPtr;
      CallBack: ptr;
      Version: integer;
      MemoryID: integer;
      Command: integer;
      SubCommand: integer;
      CP1: longint;
      CP2: longint;
      CP3: longint;
      CP4: longint;
      CP5: longint;
      end;
   HSParamPtr = ^HSParams;

procedure __NBACallBack (call: integer; parm: HSParamPtr); extern;

implementation

end.
