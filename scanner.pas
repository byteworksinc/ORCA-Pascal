{$optimize 15}
{---------------------------------------------------------------}
{								}
{  Scanner							}
{								}
{---------------------------------------------------------------}

unit Scanner;

{$segment 'Pascal2'}

interface

{$libprefix '0/obj/'}

uses PCommon, CGI;

{---------------------------------------------------------------}

var
					{misc}
                                        {----}
   debugType: (stop,breakPoint,autoGo);	{kind of debugging for this line}
   doingInterface: boolean;		{compiling an interface?}
   partiallist: partialptr;		{list of partial compile names}
   partial: boolean;			{is this a partial compile?}

					{returned by InSymbol}
					{--------------------}
   sy: symbol;				{last symbol}
   op: operator;			{classification of last symbol}
   val: valu;				{value of last constant}
   lgth: integer; 			{length of last string constant}
   id: pString;				{last identifier}
   ch: char;				{last character}
   eofl: boolean; 			{end of file flag}

{---------------------------------------------------------------}

procedure InSymbol; extern;

{ read the next token from the source stream			}


procedure Match (sym: symbol; ern: integer); extern;

{ insure that the next symbol is the one requested		}
{								}
{ parameters:							}
{    sym - symbol expected					}
{    ern - error number; used if the symbol is not correct	}


procedure OpenUses;

{ copies the contents of a uses file				}


procedure Scanner_Init; extern;

{ initialize the scanner					}


procedure Scanner_Fini;

{ shut down the scanner						}


procedure Skip (fsys: setofsys);

{ skip input string until relavent symbol found			}
{								}
{ parameters:							}
{    fsys - symbol kind to skip to				}

{---------------------------------------------------------------}

implementation

type
   copyFilePtr = ^copyFileRecord;	{copied file chain}
   copyFileRecord = record
      fnext: copyFilePtr;		{next copied file record}
      fname: gsosOutString;		{file name}
      fpos: longint;			{disp in file}
      fuses: boolean;			{doing uses?}
      flineCount: integer;		{line count}
      end;

var
					{misc}
                                        {----}
   didKeep: boolean;			{have we found a $keep directive?}
   doingOption: boolean;		{compiling an option?}
   eofDisable: boolean;			{disable end of file error check?}
   eol: boolean;			{end of line flag}
   fHeadGS: copyFilePtr;		{copied file chain}
   langNum: integer;			{language number}
   listFixed: boolean;			{was the list option specified on the cl?}
   lString: pString;			{last string}
   usesLength: longint;			{# bytes in current uses buffer}
   usesPtr: ptr;			{ptr to next byte in uses buffer}
   
{- Private subroutines -----------------------------------------}

procedure EndOfLine; extern;

{ Read in the next source line					}


procedure FakeInsymbol; extern;

{ install the uses file InSymbol patch				}


procedure GetPartialNames;

{ Form a linked list of partial compile names			}


   function GetName: boolean;

   { Read a name from subsGS					}
   {								}
   { Returns: false if there are no more names, else true	}

   var
      i: unsigned;			{loop/index variable}
      pn: partialptr;			{new partial compile entry}
      pname: pStringPtr;		{work string}


      function GetCh: char;

      { Get a character						}
      {								}
      { returns: next character from subsGS			}

      var
         ch: char;			{work character}

      begin {GetCh}
      if subsGS.theString.size = 0 then
         GetCh := chr(0)
      else begin
         ch := subsGS.theString.theString[1];
         if ch in ['a'..'z'] then
            ch := chr(ord(ch)-ord('a')+ord('A'));
         GetCh := ch;
         end; {else}
      end; {GetCh}


      procedure NextCh;

      { Remove the next character from subsGS			}

      var
         i: unsigned;			{loop/index variable}

      begin {NextCh}
      with subsGS.theString do
         if size <> 0 then begin
            for i := 2 to size do
               theString[i-1] := theString[i];
            size := size-1;
            end; {with}
      end; {NextCh}


   begin {GetName}
   while GetCh = ' ' do
      NextCh;
   if subsGS.theString.size = 0 then
      GetName := false
   else begin
      GetName := true;
      i := 0;
      new(pn);
      new(pname);
      pn^.pname := pname;
      while not (GetCh in [' ', chr(0)]) do begin
         i := i+1;
         pname^[i] := GetCh;
         NextCh;
         end; {while}
      pname^[0] := chr(i);
      pn^.next := partialList;
      partialList := pn;
      end; {else}
   end; {GetName}


begin {GetPartialNames}
partialList := nil;		{assume no list}
partial := false;
if subsGS.theString.size <> 0 then begin
   repeat until not GetName;
   partial := true;
   end; {if}
end; {GetPartialNames}


procedure InitFile;

{ get the command line and GetLInfo information			}

const
                                        {bit masks for GetLInfo flags}
                                        {----------------------------}
   flag_d       = $10000000;            {generate debug code?}
   flag_e       = $08000000;            {abort to editor on terminal error?}
   flag_l       = $00100000;            {list source lines?}
   flag_m       = $00080000;            {memory based compile?}
   flag_o       = $00020000;            {optimize?}
   flag_p       = $00010000;            {print progress info?}
   flag_s       = $00002000;            {list symbol tables?}
   flag_t       = $00001000;            {treat all errors as terminal?}
   flag_w       = $00000200;            {wait when an error is found?}

var
   i: unsigned;				{loop/index variable}

begin {InitFile}
fNameGS.maxSize := maxPath+4;
fNameGS.theString.size := 0;
for i := 1 to maxPath do
   fNameGS.theString.theString[i] := chr(0);
kNameGS := fNameGS;
subsGS := fNameGS;
ldInfoGS := fNameGS;
with liDCBGS do begin
   pCount := 11;
   sFile := @fNameGS;
   dFile := @kNameGS;
   namesList := @subsGS;
   iString := @ldInfoGS;
   end; {with}
GetLInfoGS(liDCBGS);
with liDCBGS do begin
   if pFlags & flag_l <> 0 then begin	{set up source listing flags}
      list := true;
      listFixed := true;
      end
   else if mFlags & flag_l <> 0 then
      listFixed := true
   else
      listFixed := false;
   wait := pFlags & flag_w <> 0;          {wait when an error is found?}
   allTerm := pFlags & flag_t <> 0;	  {all errors terminal?}
   gotoEditor := pFlags & flag_e <> 0;    {enter editor on terminal errors?}
   debugFlag := pFlags & flag_d <> 0;     {generate debug code?}
   profileFlag := debugFlag;		  {generate profile code?}
   memoryFlag := pflags & flag_m <> 0;    {memory based compile?}
   progress := mflags & flag_p = 0;       {write progress info?}
   printSymbols := pflags & flag_s <> 0;  {print the symbol table?}
   cLineOptimize := pFlags & flag_o <> 0; {turn optimizations on?}
   end; {liDCB}
if list then                              {we don't need both...}
   progress := false;
keepFlag := liDCBGS.kFlag;		{set up the code generator}
codeGeneration := keepFlag <> 0;
end; {InitFile}


procedure ListLine; extern;

{ List the current line and any errors found			}


procedure NextCh; extern;

{ Fetch the next source character				}


procedure OpenGS;

{ Open a source file						}

var
   ffDCBGS: fastFileDCBGS;		{for FastFile load}
   erRec: errorDCBGS;			{for reporting shell error}

begin {OpenGS}    
with ffDCBGS do begin			{read the source file}
   pCount := 14;
   action := 0;
   flags := $C000;
   pathName := @fNameGS.theString;
   end; {with}
FastFileGS(ffDCBGS);
if ToolError <> 0 then begin
   erRec.pcount := 1;
   erRec.error := ToolError;
   ErrorGS(erRec);
   TermError(4, nil);
   end; {if}
if langNum <> 0 then begin		{check the language number}
   if ffDCBGS.auxType <> langNum then
      TermError(2, nil);
   end {if}
else
   langNum := long(ffDCBGS.auxType).lsw;
filePtr := ffDCBGS.fileHandle^;		{set beginning of file pointer}
chEndPtr := pointer(ord4(filePtr)+ffDCBGS.fileLength);;
chPtr := pointer(ord4(chEndPtr)-1);	{make sure the file ends with a CR}
if chPtr^ <> 13 then
   TermError(11, nil);
chPtr := filePtr;			{set the character pointer}
end; {OpenGS}


procedure OpenUses;

{ Open a file for the uses statement				}

var
   exRec: ExpandDevicesDCBGS;		{ExpandDevices record}
   ffRec: FastFileDCBGS;		{FastFile record}
   i: unsigned;				{loop/index variable}
   lNameGS: gsosOutString;		{work string for forming path name}
   separator: char;			{separator character}

begin {OpenUses}
if intPrefixGS.theString.size = 0 then begin
   lNameGS.theString.theString := concat('13:ORCAPascalDefs:', id, '.int');
   lNameGS.theString.size := length(lNameGS.theString.theString);
   if GetFileType(lNameGS) = -1 then 
      lNameGS.theString.theString := concat('8:', id, '.int');
   end {if}
else begin
   i := 0;
   separator := ' ';
   while (i < intPrefixGS.theString.size) and (separator = ' ') do begin
      if intPrefixGS.theString.theString[i] in [':', '/'] then
         separator := intPrefixGS.theString.theString[i];
      i := i+1;
      end; {while}
   if separator = ' ' then
      separator := ':';
   lNameGS.theString := intPrefixGS.theString;
   if intPrefixGS.theString.size < maxPath then
      lNameGS.theString.theString[intPrefixGS.theString.size] := chr(0);
   if intPrefixGS.theString.theString[intPrefixGS.theString.size-1] <> separator
      then
      lNameGS.theString.theString :=
         concat(lNameGS.theString.theString, separator);
   lNameGS.theString.theString := concat(lNameGS.theString.theString, id);
   lNameGS.theString.theString := concat(lNameGS.theString.theString, '.int');
   end; {else}
lNameGS.theString.size := length(lNameGS.theString.theString);
exRec.pcount := 2;			{expand devices}
exRec.inName := @lNameGS.theString;
exRec.outName := @usesFileNameGS;
usesFileNameGS.maxSize := maxPath+4;
ExpandDevicesGS(exRec);
if ToolError <> 0 then
   usesFileNameGS := lNameGS;
ffRec.pcount := 14;			{read the file}
ffRec.action := 0;
ffRec.flags := $C000;
ffRec.pathName := @usesFileNameGS.theString;
FastFileGS(ffRec);
if ToolError <> 0 then
   TermError(6, nil);
usesPtr := ffRec.fileHandle^;		{save the file pointer}
usesLength := ffRec.fileLength;		{save the file length}
if ffRec.fileType = DVU then begin	{skip the version number}
   usesPtr := pointer(ord4(usesPtr)+1);
   usesLength := usesLength-1;
   end; {if}
FakeInsymbol;				{set up the InSymbol patch}
end; {OpenUses}


procedure SkipComment;

{ Skip to the end of a comment					}

begin {SkipComment}
repeat
   while not ((ch = '*') or (ch = '}')) and not eofl do
      NextCh;
   if ch = '*' then
      NextCh;
until (ch = ')') or (ch = '}') or eofl;
NextCh;
end; {SkipComment}


function Options: boolean;

{ Compile compiler directives					}
{								}
{ Returns: True if the parser should continue to scan for an	}
{    end of comment, else false					}

const
   nameLen = 12;			{max length of a directive name}

var
   dName: string[nameLen];		{directive name}


   function IsAlpha (ch: char): boolean;

   { See if a character is alphabetic				}
   {								}
   { parameters:						}
   {    ch - character to check					}
   {								}
   { Returns: True for an alphabetic character, else false	}

   begin {IsAlpha}
   IsAlpha := ch in ['a'..'z', 'A'..'Z'];
   end; {IsAlpha}


   procedure SkipBlanks;

   { skip to the next non-blank character			}

   const
      tab = 9;				{tab key code}

   begin {SkipBlanks}
   while (ch in [' ', chr(tab), chr($CA)]) and (not eofl) do
      NextCh;
   end; {SkipBlanks}


   function ToUpper (ch: char): char;

   { Return an uppercase character				}
   {								}
   { parameters:						}
   {    ch - character to check					}
   {								}
   { Returns: Uppercase equivalent of ch			}

   begin {ToUpper}
   if ch in ['a'..'z'] then
      ch := chr(ord(ch)-ord('a')+ord('A'));
   ToUpper := ch;
   end; {ToUpper}


   procedure Expand (var name: pString);

   { Expands a name to a full pathname				}
   {								}
   { parameters:						}
   {    name - file name to expand				}

   var
      exRec: expandDevicesDCBGS;	{expand devices}

   begin {Expand}
   exRec.pcount := 2;
   new(exRec.inName);
   exRec.inName^.theString := name;
   exRec.inName^.size := length(name);
   new(exRec.outName);
   exRec.outName^.maxSize := maxPath+4;
   ExpandDevicesGS(exRec);
   if toolerror = 0 then
      with exRec.outName^.theString do begin
         if size < maxPath then
            theString[size+1] := chr(0);
         name := theString;
         end; {with}
   dispose(exRec.inName);
   dispose(exRec.outName);
   end; {Expand}


   function GetIdent: pStringPtr;

   { Read an identifier						}
   {								}
   { Returns: pointer to the identifier, or nil			}

   var
      disp: integer;			{characters in the string}
      sPtr: pStringPtr;			{dynamic string pointer}
      str: pString;			{work buffer}

   begin {GetIdent}
   SkipBlanks;
   sPtr := nil;
   disp := 0;
   if IsAlpha(ch) then begin
      while ch in ['a'..'z', 'A'..'Z', '0'..'9', '_'] do begin
         if disp < maxLine then
            disp := disp+1;
	 str[disp] := ch;
	 NextCh;
	 end; {while}
      str[0] := chr(disp);
      sPtr := pStringPtr(Malloc(length(str)+1));
      sPtr^ := str;
      end; {if}
   GetIdent := sPtr;
   end; {GetIdent}


   function GetInteger: integer;

   { Read an (possibly signed) integer value			}
   {								}
   { Returns: Value read					}

   var
      sign: boolean;			{is the value negative?}
      temp: integer;			{temp val.ival}

   begin {GetInteger}
   temp := val.ival;
   SkipBlanks;
   sign := false;
   if ch = '-' then begin
      NextCh;
      sign := true;
      end; {if}
   InSymbol;
   if sy = longintconst then
   if val.valp^.lval >> 16 = 0 then begin
      val.ival := ord(val.valp^.lval);
      sy := intconst;
      end; {if}
   if sy <> intconst then
      Error(15);
   if sign then
      val.ival := -val.ival;
   GetInteger := val.ival;
   val.ival := temp;
   end; {GetInteger}


   function GetString: boolean;

   { read a string						}
   {								}
   { Returns: True if a string was found, else false		}
   {								}
   { Notes:							}
   {    1. If a string is found, it is placed in lString	}
   {    2. If a string is not found, no error is reported	}

   begin {GetString}
   SkipBlanks;
   GetString := ch = '''';
   if ch = '''' then
      InSymbol
   else
      Error(6);
   end; {GetString}


   function SetOption: boolean;

   { Check for a +/- options flag				}
   {								}
   { Returns: True for +, false for -				}

   begin {SetOption}
   SetOption := true;
   if ch in ['+','-'] then begin
      SetOption := ch = '+';
      NextCh;
      end {if}
   else
      Error(6);
   end; {SetOption}  


   procedure DoAppend;

   { Append							}

   var
      ffRec: FastFileDCBGS;		{FastFile record}

   begin {DoAppend}
   if GetString then begin		{get the source name}
      EndOfLine;			{read the next source line}
      PurgeSource;			{purge the current source file}
      eol := false;			{don't reprint the line}
      Expand(lString);			{set the new path name}
      fNameGS.theString.theString := lString;
      fNameGS.theString.size := length(lString);
      if not eofDisable then begin
	 OpenGS;			{open the file}
	 lineCount := 1;
         end; {if}
      end {if}
   else begin
      eofl := true;
      Error(37);
      end; {else}
   Options := false;			{we won't scan for end of comment}
   doingOption := false;
   end; {DoAppend}


   procedure DoCDev;

   { CDev							}

   begin {DoCDev}
   if progFound or isNewDeskAcc or isClassicDeskAcc or isCDev or rtl or isXCMD
      or isNBA then
      Error(100);
   isCDev := true;
   openName := GetIdent;
   end; {DoCDev}


   procedure DoClassicDesk;

   { ClassicDesk						}

   begin {DoClassicDesk}
   if progFound or isNewDeskAcc or isClassicDeskAcc or isCDev or rtl or isXCMD
      or isNBA then
      Error(100);
   isClassicDeskAcc := true;
   if GetString then
      menuLine := lString
   else
      Error(131);
   openName := GetIdent;
   closeName := GetIdent;
   end; {DoClassicDesk}


   procedure DoCopy;

   { Copy							}

   var
      ffRec: FastFileDCBGS;		{FastFile record}
      fRec: copyFilePtr;		{copy file record}

   begin {DoCopy}
   new(fRec);				{create a copy record}
   fRec^.fnext := fHeadGS;
   fHeadGS := fRec;
   fRec^.fName := fNameGS;		{fill in the current file name}
   if GetString then begin		{get the source name}
      SkipComment;			{skip to the end of the directive}
					{save the file position}
      fRec^.fpos := ord4(chPtr) + chCnt - ord4(filePtr);
      fRec^.fuses := false;		{not doing a uses}
      fRec^.flineCount := lineCount+1;	{save the new line count}
      EndOfLine;			{read the next source line}
      PurgeSource;			{purge the current source file}
      eol := false;			{don't reprint the line}
      Expand(lString);			{set the new path name}
      fNameGS.theString.theString := lString;
      fNameGS.theString.size := length(lString);
      OpenGS;				{open the file}
      lineCount := 1;
      end {if}
   else begin
      eofl := true;
      Error(37);
      end; {else}
   Options := false;			{we won't scan for end of comment}
   doingOption := false;
   end; {DoCopy}                                       


   procedure DoDataBank;

   { DataBank							}

   begin {DoDataBank}
   dataBank := SetOption;
   end; {DoDataBank}


   procedure DoDebug;

   { Debug							}

   var
      val: unsigned;			{debug flag word}

   begin {DoDebug}
   val := GetInteger;
   debugFlag := odd(val);
   profileFlag := (val & $0002) <> 0;
   profileFlag := profileFlag or debugFlag;
   end; {DoDebug}


   procedure DoEject;

   { Eject							}

   begin {DoEject}
   if printer then
      if list then begin
         write(chr(12));
         lCnt := 0;
         if length(title) <> 0 then begin
            write(title);
            LineFeed;
            LineFeed;
            end; {if}
         end; {if}
   end; {DoEject}


   procedure DoFloat;

   { Float							}

   begin {DoFloat}
   floatCard := GetInteger;
   end; {DoFloat}


   procedure DoISO;

   { ISO							}

   begin {DoISO}
   iso := SetOption;
   if iso then
      debug := true;
   end; {DoISO}


   procedure DoKeep;

   { Keep							}

   begin {DoKeep}
   if progFound or didKeep then
      Error(100)
   else if GetString then begin
      codeGeneration := true;
      Expand(lString);
      kNameGS.theString.theString := lString;
      kNameGS.theString.size := length(lString);
      keepFlag := 1;
      didKeep := true;
      end; {else if}
   end; {DoKeep}


   procedure DoLibPrefix;

   { LibPrefix							}

   var
      i: unsigned;			{loop/index variable}
      len: unsigned;			{length(lString)}
      separator: char;			{path separaotr character}

   begin {DoLibPrefix}
   if GetString then begin
      len := length(lString);
      if len = 0 then
         intPrefixGS.theString.size := 0
      else begin
	 separator := ' ';
	 i := 1;
	 while i < len do
            if lString[i] in [':','/'] then begin
               separator := lString[i];
               i := maxint;
               end {if}
            else
               i := i+1;
	 if separator = ' ' then
            separator := ':';
	 if lString[len] <> separator then
            lString := concat(lString, separator);
	 intPrefixGS.theString.theString := lString;
	 intPrefixGS.theString.size := length(lString);
         end; {else}
      end {if}
   else
      Error(37);
   end; {DoLibPrefix}


   procedure DoList;

   { List							}

   var
      llist: boolean;			{local list}

   begin {DoList}
   llist := SetOption;
   if not listFixed then
      list := llist;
   end; {DoList}


   procedure DoMemoryModel;

   { MemoryModel						}

   begin {DoMemoryModel}
   if progFound then
      Error(100);
   smallMemoryModel := GetInteger = 0;
   end; {DoMemoryModel}


   procedure DoNames;

   { Names							}

   begin {DoNames}
   traceBack := SetOption;
   end; {DoNames}


   procedure DoNBA;

   { NBA							}

   begin {DoNBA}
   if progFound or isNewDeskAcc or isClassicDeskAcc or isCDev or rtl or isXCMD
      or isNBA then
      Error(100);
   isNBA := true;
   openName := GetIdent;
   end; {DoNBA}


   procedure DoNewDeskAcc;

   { NewDeskAcc							}

   begin {DoNewDeskAcc}
   if progFound or isNewDeskAcc or isClassicDeskAcc or isCDev or rtl or isXCMD
      or isNBA then
      Error(100);
   isNewDeskAcc := true;
   openName := GetIdent;
   closeName := GetIdent;
   actionName := GetIdent;
   initName := GetIdent;
   refreshPeriod := GetInteger;
   eventMask := GetInteger;
   if GetString then
      menuLine := lString
   else
      Error(131);
   end; {DoNewDeskAcc}


   procedure DoOptimize;

   { Optimize							}

   var
      val: unsigned;			{optimize flag word}

   begin {DoOptimize}
   val := GetInteger;
   peepHole := odd(val);
   nPeepHole := (val & $0002) <> 0;
   registers := (val & $0004) <> 0;
   commonSubexpression := (val & $0008) <> 0;
   loopOptimizations := (val & $0010) <> 0;
   jslOptimizations := (val & $0020) <> 0;
   end; {DoOptimize}


   procedure DoRangeCheck;

   { RangeCheck							}

   begin {DoRangeCheck}
   debug := SetOption;
   rangeCheck := debug;
   end; {DoRangeCheck}


   procedure DoRTL;

   { RTL							}

   begin {DoRTL}
   if isNewDeskAcc or isClassicDeskAcc or isCDev or rtl then
      Error(100);
   rtl := true;
   end; {DoRTL}


   procedure DoSegment;

   { Segment							}

   var
      i: unsigned;			{loop/index variable}
      seg: segNameType;			{segment name}

   begin {DoSegment}
   if GetString then begin
      seg := lString;
      for i := length(seg)+1 to 10 do
         seg[i] := ' ';
      DefaultSegName(seg);
      isDynamic := false;
      end {if}
   else
      Error(6);
   end; {DoSegment}


   procedure DoDynamic;

   { Dynamic							}

   begin {DoDynamic}
   DoSegment;
   isDynamic := true;
   end; {DoDynamic}


   procedure DoStackSize;

   { StackSize							}

   begin {DoStackSize}
   if progFound then
      Error(100);
   stackSize := GetInteger;
   end; {DoStackSize}


   procedure DoToolParms;

   { ToolParms							}

   begin {DoToolParms}
   toolParms := SetOption;
   end; {DoToolParms}


   procedure DoTitle;

   { Title							}

   begin {DoTitle}
   if GetString then
      title := lString
   else
      title := '';
   end; {DoTitle}


   procedure DoXCMD;

   { XCMD							}

   begin {DoXCMD}
   if progFound or isNewDeskAcc or isClassicDeskAcc or isCDev or rtl or isXCMD
      or isNBA then
      Error(100);
   isXCMD := true;
   openName := GetIdent;
   end; {DoXCMD}


begin {Options} 
Options := true;			{assume we will scan for end of comment}
doingOption := true;			{processing an option}
repeat
   NextCh;
   if (ch <> '*') and (ch <> '}') then begin
      dName[0] := chr(0);		{get a directive name}
      SkipBlanks;
      while IsAlpha(ch) and (ord(dName[0]) < nameLen) do begin
         dName[0] := succ(dName[0]);
         dName[ord(dName[0])] := ToUpper(ch);
         NextCh;
         end; {while}
					{call the correct handler}
      if dName = 'MEMORYMODEL' then DoMemoryModel
      else if dName = 'APPEND' then DoAppend
      else if dName = 'COPY' then DoCopy
      else if dName = 'DEBUG' then DoDebug
      else if dName = 'EJECT' then DoEject
      else if dName = 'FLOAT' then DoFloat
      else if dName = 'ISO' then DoISO
      else if dName = 'KEEP' then DoKeep
      else if dName = 'LIST' then DoList
      else if dName = 'NAMES' then DoNames
      else if dName = 'RANGECHECK' then DoRangeCheck
      else if dName = 'STACKSIZE' then DoStackSize
      else if dName = 'TITLE' then DoTitle
      else if dName = 'RTL' then DoRTL
      else if dName = 'NEWDESKACC' then DoNewDeskAcc
      else if dName = 'OPTIMIZE' then DoOptimize
      else if dName = 'SEGMENT' then DoSegment
      else if dName = 'DYNAMIC' then DoDynamic
      else if dName = 'TOOLPARMS' then DoToolParms
      else if dName = 'DATABANK' then DoDataBank
      else if dName = 'LIBPREFIX' then DoLibPrefix
      else if dName = 'CLASSICDESK' then DoClassicDesk
      else if dName = 'CDEV' then DoCDev
      else if dName = 'XCMD' then DoXCMD
      else if dName = 'NBA' then DoNBA
      else doingOption := false;  
      end {if}
   else
      doingOption := false;
   if doingOption then begin		{check for another one}
      SkipBlanks;
      doingOption := ch = ',';
      end; {if}
until not doingOption;
end; {Options}

{- Public subroutines ------------------------------------------}

procedure Scanner_Fini;

{ Shut down the scanner						}

var
   i: unsigned;				{loop/index variable}
   tp: partialPtr;			{work pointer}

begin {Scanner_Fini}
PurgeSource;				{purge the last source file}
fNameGS.theString.size := 0;		{handle a trailing append}
eofDisable := true;
InSymbol;
if fNameGS.theString.size <> 0 then begin
   liDCBGS.sFile := @fNameGS;
   liDCBGS.namesList := @subsGS;
   subsGS.theString.size := 0;
   while partialList <> nil do begin
      tp := partialList;
      partialList := tp^.next;
      for i := 1 to length(tp^.pname^) do begin
         subsGS.theString.size := subsGS.theString.size+1;
         subsGS.theString.theString[subsGS.theString.size] := tp^.pname^[i];
         end; {for}
      dispose(tp);
      if partialList <> nil then begin
         subsGS.theString.size := subsGS.theString.size+1;
         subsGS.theString.theString[subsGS.theString.size] := ' ';
         end; {if}
      end; {while}
   if keepFlag <> 0 then
      liDCBGS.kFlag := 3;
   end {if}
else begin				{no append; the compile is over}
   liDCBGS.lOps := liDCBGS.lOps & $FFFE;
   if keepFlag <> 0 then
      liDCBGS.kFlag := 3
   else
      liDCBGS.lOps := 0;
   liDCBGS.sFile := @kNameGS;
   end; {else}
with liDCBGS do begin			{pass info back to the shell}
   sFile := pointer(ord4(sFile)+2);
   dFile := pointer(ord4(dFile)+2);
   namesList := pointer(ord4(namesList)+2);
   iString := pointer(ord4(iString)+2);
   end; {with}
SetLInfoGS(liDCBGS);
StopSpin;				{stop the spinner}
ListLine;				{finish the listing}
if list or progress then begin
   LineFeed;
   writeln(errorOutput, numErr:1, ' errors found');
   end; {if}
end; {Scanner_Fini}


procedure Skip {fsys: setofsys};

{ skip input string until relavent symbol found			}
{								}
{ parameters:							}
{    fsys - symbol kind to skip to				}

begin {Skip}
if not eofl then begin
   while not (sy in fsys) and (not eofl) do
      InSymbol;
   if not (sy in fsys) then
      InSymbol;
   end; {if}
end; {Skip}

end.

{$append 'scanner.asm'}
