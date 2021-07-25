{$keep 'Finder'}
unit Finder;
interface

{********************************************************
*
*  Finder data structures and constants
*
*  Other USES Files Needed:  Common
*
*  Copyright 1992
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

uses
   Common;
   
const

   name_of_finder = 'Apple~Finder~';    {target name for SendRequest to Finder}

                                        {SendRequest codes sent by the Finder}
   finderSaysHello            = $0100;
   finderSaysGoodbye          = $0101;
   finderSaysSelectionChanged = $0102;
   finderSaysMItemSelected    = $0103;
   finderSaysBeforeOpen       = $0104;
   finderSaysOpenFailed       = $0105;
   finderSaysBeforeCopy       = $0106;
   finderSaysBeforeIdle       = $0107;
   finderSaysExtrasChosen     = $0108;
   finderSaysBeforeRename     = $0109;
   finderSaysKeyHit           = $010A;
   
                                        {SendRequest codes sent to the Finder}
   tellFinderGetDebugInfo      = $8000;
   askFinderAreYouThere        = $8001;
   tellFinderAreYouThere       = $8001;
   tellFinderOpenWindow        = $8002;
   tellFinderCloseWindow       = $8003;
   tellFinderGetSelectedIcons  = $8004;
   tellFinderSetSelectedIcons  = $8005;
   tellFinderLaunchThis        = $8006;
   tellFinderShutDown          = $8007;
   tellFinderMItemSelected     = $8008;
   tellFinderMatchFileToIcon   = $800A;
   tellFinderAddBundle         = $800B;
   tellFinderAboutChange       = $800C;
   tellFinderCheckDatabase     = $800D;
   tellFinderColorSelection    = $800E;
   tellFinderAddToExtras       = $800F;
   askFinderIdleHowLong        = $8011;
   tellFinderIdleHowLong       = $8011;
   tellFinderGetWindowIcons    = $8012;
   tellFinderGetWindowInfo     = $8013;
   tellFinderRemoveFromExtras  = $8014;
   tellFinderSpecialPreference = $8015;

type
   finderSaysHelloIn = record
      pCount: integer;
      version: longint;
      finderID: integer;
      iconObjJize: integer;
      end;
   finderSaysHelloInPtr = ^finderSaysHelloIn;

   finderSaysMItemSelectedIn = record
      pCount: integer;
      menuItemID: integer;
      menuID: integer;
      modifiers: integer;
      end;
   finderSaysMItemSelectedInPtr = ^finderSaysMItemSelectedIn;

   finderSaysMItemSelectedOut = record
      recvCount: integer;
      abortIt: integer;
      end;
   finderSaysMItemSelectedOutPtr = ^finderSaysMItemSelectedOut;

   finderSaysBeforeOpenIn = record
      pCount: integer;
      pathname: gsosInStringPtr;
      zoomRect: rectPtr;
      fileType: integer;
      auxType: longint;
      modifiers: integer;
      theIconObj: ptr;
      printFlag: boolean;
      end;
   finderSaysBeforeOpenInPtr = ^finderSaysBeforeOpenIn;
   finderSaysOpenFailedIn = finderSaysBeforeOpenIn;
   finderSaysOpenFailedInPtr = ^finderSaysOpenFailedIn;

   finderSaysBeforeCopyIn = record
      pCount: integer;
      inpath: gsosInStringPtr;
      outpath: gsosOutStringPtr;
      end;
   finderSaysBeforeCopyInPtr = ^finderSaysBeforeCopyIn;

   finderSaysBeforeCopyOut = record
      recvCount: integer;
      abortFlag: integer;
      end;
   finderSaysBeforeCopyOutPtr = ^finderSaysBeforeCopyOut;

   finderSaysBeforeRenameIn = record
      pCount: integer;
      oldpath,
      newpath: gsosInStringPtr;
      fileType: integer;
      auxType: longint;
      end;
   finderSaysBeforeRenameInPtr = ^finderSaysBeforeRenameIn;

   finderSaysBeforeRenameOut = record
      recvCount: integer;
      abortFlag: integer;
      end;
   finderSaysBeforeRenameOutPtr = ^finderSaysBeforeRenameOut;

   finderSaysKeyHitIn = record
      pCount: integer;
      message: integer;
      modifiers: integer;
      end;
   finderSaysKeyHitInPtr = ^finderSaysKeyHitIn;

   tellFinderGetDebugInfoOut = record
      recvCount: integer;
      finderResult: integer;
      reserved: integer;
      directPage: integer;
      deskIcon: handle;
      nameChainH: handle;
      filetypeBlock: ptr;
      deviceBlock: ptr;
      masterChainH: handle;
      finderPathsH: handle;
      finderPathsCount: integer;
      nameChainInsert: longint;
      reserved2: longint;
      masterChainInsert: longint;
      reserved3: longint;
      chainTable: handle;
      iconOffsetArray: handle;
      iconHandleArray: handle;
      iconArrayUsed: integer;
      iconArraySize: integer;
      reserved4: array[0..64] of byte;
      end;
   tellFinderGetDebugInfoOutPtr = ^tellFinderGetDebugInfoOut;

   tellFinderAreYouThereOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderAreYouThereOutPtr = ^tellFinderAreYouThereOut;

   tellFinderOpenWindowOut = record
      recvCount: integer;
      finderResult: integer;
      windowPtr: grafPortPtr;
      end;
   tellFinderOpenWindowOutPtr = ^tellFinderOpenWindowOut;

   tellFinderCloseWindowOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderCloseWindowOutPtr = ^tellFinderCloseWindowOut;

   tellFinderGetSelectedIconsOut = record
      recvCount: integer;
      finderResult: integer;
      windowPtr: grafPortPtr;
      stringListHandle: handle;
      end;
   tellFinderGetSelectedIconsOutPtr = ^tellFinderGetSelectedIconsOut;

   tellFinderSetSelectedIconsOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderSetSelectedIconsOutPtr = ^tellFinderSetSelectedIconsOut;

   tellFinderLaunchThisIn = record
      reserved: integer;
      pathname: gsosInStringPtr;
      end;
   tellFinderLaunchThisInPtr = ^tellFinderLaunchThisIn;

   tellFinderLaunchThisOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderLaunchThisOutPtr = ^tellFinderLaunchThisOut;

   tellFinderShutDownOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderShutDownOutPtr = ^tellFinderShutDownOut;

   tellFinderMItemSelectedIn = record
      menuItemID: integer;
      modifiers: integer;
      flags: integer;
      end;
   tellFinderMItemSelectedInPtr = ^tellFinderMItemSelectedIn;

   tellFinderMItemSelectedOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderMItemSelectedOutPtr = ^tellFinderMItemSelectedOut;

   swapLong = record
      msw,lsw: integer;
      end;

   tellFinderMatchFileToIconIn = record
      pCount: integer;
      vote: integer;
      match: integer;
      fileType: integer;
      auxType: swapLong;
      fileNamePtr: swapLong;
      createDateTimePtr: swapLong;
      modDateTimePtr: swapLong;
      access: integer;
      flags: integer;
      optionPtr: swapLong;
      combinedEOF: swapLong;
      end;
   tellFinderMatchFileToIconInPtr = ^tellFinderMatchFileToIconIn;

   tellFinderMatchFileToIconOut = record
      recvCount: integer;
      finderResult: integer;
      offset: longint;
      matches: handle;
      smallIcon: longint;
      largeIcon: longint;
      finderPath: handle;
      end;
   tellFinderMatchFileToIconOutPtr = ^tellFinderMatchFileToIconOut;

   tellFinderAddBundleIn = record
      reserved: integer;
      path1: gsosInStringPtr;
      path2: gsosInStringPtr;
      rBundleID: longint;
      end;
   tellFinderAddBundleInPtr = ^tellFinderAddBundleIn;

   tellFinderAddBundleOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderAddBundleOutPtr = ^tellFinderAddBundleOut;

   tellFinderAboutChangeOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderAboutChangeOutPtr = ^tellFinderAboutChangeOut;

   ptr68000 = record
      b3,b2,b1,b0: byte;
      end;

   tellFinderCheckDatabaseIn = record
      update: integer;
      pathName: ptr68000;
      rVersion: ptr68000;
      end;
   tellFinderCheckDatabaseInPtr = ^tellFinderCheckDatabaseIn;
      
   tellFinderCheckDatabaseOut = record
      recvCount: integer;
      finderResult: integer;
      found: integer;
      end;
   tellFinderCheckDatabaseOutPtr = ^tellFinderCheckDatabaseOut;

   tellFinderColorSelectionOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderColorSelectionOutPtr = ^tellFinderColorSelectionOut;
   
   tellFinderAddToExtrasOut = record
      recvCount: integer;
      finderResult: integer;
      menuItemID: integer;
      menuID: integer;
      end;
   tellFinderAddToExtrasOutPtr = ^tellFinderAddToExtrasOut;

   askFinderIdleHowLongOut = record
      recvCount: integer;
      finderResult: integer;
      tickCount: longint;
      end;
   askFinderIdleHowLongOutPtr = ^askFinderIdleHowLongOut;
   tellFinderIdleHowLongOut = askFinderIdleHowLongOut;
   tellFinderIdleHowLongOutPtr = ^tellFinderIdleHowLongOut;

   tellFinderGetWindowIconsOut = record
      recvCount: integer;
      finderResult: integer;
      stringListHandle: handle;
      end;
   tellFinderGetWindowIconsOutPtr = ^tellFinderGetWindowIconsOut;

   tellFinderGetWindowInfoOut = record
      recvCount: integer;
      finderResult: integer;
      windType: integer;
      windView: integer;
      windFST: integer;
      windTitle: pStringPtr;
      windPath: gsosInStringPtr;
      reserved1: longint;
      reserved2: longint;
      end;
   tellFinderGetWindowInfoOutPtr = ^tellFinderGetWindowInfoOut;

   tellFinderRemoveFromExtrasOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderRemoveFromExtrasOutPtr = ^tellFinderRemoveFromExtrasOut;

   tellFinderSpecialPreferencesIn = record
      pCount: integer;
      allowDrag: boolean;
      end;
   tellFinderSpecialPreferencesInPtr = ^tellFinderSpecialPreferencesIn;

   tellFinderSpecialPreferencesOut = record
      recvCount: integer;
      finderResult: integer;
      end;
   tellFinderSpecialPreferencesOutPtr = ^tellFinderSpecialPreferencesOut;

implementation
end.
