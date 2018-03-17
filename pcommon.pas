{$optimize -1}
{---------------------------------------------------------------}
{								}
{  PCommon							}
{								}
{  Common variables and low-level utility subroutines used by	}
{  by the compiler.						}
{								}
{---------------------------------------------------------------}

unit PCommon;

interface

const
   displimit   = 20;			{max # proc levels, nested records,}
					{ with statements.}
   maxaddr     = maxint4;		{max legal value for a pointer}
   maxcnt      = 256;			{number of characters in a line+1}
   maxLine     = 255;			{number of characters in a line}
   maxLabel    = 2400;			{max # of compiler generated labels}
   maxlevel    = 10;			{max # proc levels}
   maxgoto     = 10;			{max nesting level for goto check}
					{NOTE: maxPath also defined in scanner.asm}
   maxPath     = 255;			{max length of a path name}
   ordmaxchar  = 127;			{ord of largest char}
   ordminchar  = 0;			{ord of smallest char}
   sethigh     = 2047;			{number of bits in set variable - 1}
   setlow      = 0;			{"ord" of lsb of set variable}
   setsize     = 256;			{set size in bytes; (sethigh+1) div 8}

   intsize     = 2;			{storage in bytes required for base}
   realsize    = 4;			{ types}
   doublesize  = 8;
   compsize    = 8;
   extendedsize  = 10;
   bytesize    = 1;
   longsize    = 4;
   packedcharsize = 1;
   charsize    = 2;
   boolsize    = 2;
   ptrsize     = 4;
   procsize    = 6;
   extSize     = 10;			{size of real when passed as parm}

   constantRec_longC = 6;		{partial sizes for constantRec}
   constantRec_reel  = 10;
   constantRec_pset  = 260;
   constantRec_chset = 258;
   constantRec_strg  = 258;

					{error reporting}
					{---------------}
   maxErr = 10;				{max errors on one line}

					{file types}
                                        {----------}
   BIN = $06;				{binary file}
   DVU = $5E;				{developer utility data file}
   AuxUnit = $008009;			{Pascal unit Aux Type}

type
					{misc}
					{----}
   disprange = 0..displimit;		{nesting level for procs + withs}
   markPtr = ^integer;			{pointer type for mark, release}
   ptr = ^byte;				{general pointer}
   handle = ^ptr;			{general handle}
   stringKind = (lengthString,nullString); {string formats}
   pString = packed array [0..maxLine] of char; {length string}
   pStringPtr = ^pString;
   unsigned = 0..maxint; 		{unsigned integer}
   where = (blck,crec,vrec,rec); 	{origin of a set of symbols}

   long = record 			{for extracting words}
      case boolean of
	 true: (lsw, msw: integer);
	 false: (l: longint);
      end;

					{error reporting}
					{---------------}
					{NOTE: disps defined in Scanner.asm}
   errtype = record
      nmr: unsigned;			{error number}
      pos: unsigned;			{position in line}
      end;
					{basic symbols}
					{-------------}
   packedkinds = (pkpacked,pkunpacked,pkeither);

   symbol = (ident,intconst,realconst,stringconst,notsy,mulop,addop,relop,
	     lparent,rparent,lbrack,rbrack,comma,semicolon,period,arrow,
	     colon,dotdot,becomes,labelsy,constsy,typesy,varsy,funcsy,
	     progsy,procsy,setsy,packedsy,arraysy,recordsy,filesy,nilsy,
	     beginsy,ifsy,casesy,repeatsy,whilesy,forsy,withsy,gotosy,
	     endsy,elsesy,untilsy,ofsy,dosy,tosy,downtosy,thensy,
	     othersy,otherwisesy,powersy,bitnot,usessy,stringsy,atsy,
	     longintconst,unitsy,interfacesy,implementationsy,univsy,
             objectsy,inheritedsy);
   setofsys = set of symbol;

   operator = (noop,mul,rdiv,andop,idiv,imod,plus,minus,orop,ltop,leop,geop,gtop,
	       neop,eqop,inop,band,bor,xor,rshift,lshift);


					{data structures}
					{---------------}
   ctp = ^identifier;

   addrrange = longint;			{valid range for pointers}
   declkind = (standard,declared);
   structform = (scalar,subrange,pointerStruct,power,arrays,records,objects,
		files,tagfld,variant);

   stp = ^structure;
   structure = record
      size: addrrange;
      ispacked: packedkinds;
      hasSFile: boolean;
      case form: structform of
	 scalar: 	(case scalkind: declkind of
			    declared: (fconst: ctp);
			    standard: ());
	 subrange:	(rangetype: stp; min,max: longint);
	 pointerStruct: (eltype: stp);
	 power:		(elset: stp);
	 arrays: 	(aeltype,inxtype: stp);
	 records:	(fstfld: ctp; recvar: stp);
	 objects:	(objfld: ctp;		{object fields}
			 objsize: addrrange;	{object size}
                         objname: pstringptr;	{object name}
                         objlevel: integer;	{generation level}
                         objparent: stp;	{parent or nil}
                         objdef: boolean;       {false if not defined}
                         );
	 files:		(filtype: stp; filsize: addrrange);
	 tagfld: 	(tagfieldp: ctp; fstvar: stp);
	 variant:	(nxtvar,subvar: stp; varval: integer)
      end;

					{constants}
					{---------}
   cstclass = (reel,pset,strg,chset,longC);
   settype = set of setlow..sethigh;

   csp = ^ constantRec;
				{NOTE: Size in scanner.asm}
				{NOTE: Partial sizes here and in scanner.asm}
   constantRec = record
      case cclass: cstclass of
	 longC:(lval: longint);
	 reel: (rval: double);
	 pset: (pval: settype;
		pmax: setlow..sethigh);
	 chset:(ch: packed array[0..255] of char);
	 strg: (sval: pString);
	 end;

   valu = record case boolean of
      true  :(ival: integer);
      false: (valp: csp)
      end;
					{names}
					{-----}

   directive_type = (drnone,drforw,drextern,drprodos,drtool1,drtool2,drvector,
                     droverride);
   idclass = (types,konst,varsm,field,proc,func,directive,prog);
   setofids = set of idclass;
   idkind = (actual,formal);
   levrange = 0..maxlevel;
   keyrange = 1..53;			{range of std proc nums}

					{NOTE: Disps in scanner.asm}
   identifier = record
      name: pStringPtr;			{name of the identifier}
      llink, rlink: ctp; 		{links for symbol tree}
      idtype: stp;			{type of identifier}
      next: ctp;
      hasIFile: boolean;
      case klass: idclass of
	 konst: (values: valu);		{constant value}
	 varsm: (vkind: idkind;
		 vlev: levrange; 	{declaration level}
		 vitem: integer;
		 vlabel: unsigned;	{variable label}
		 vcontvar: boolean;
		 fromUses: boolean;
		 vrestrict: boolean;
		 vuniv: boolean; 	{for parameters, is it universal?}
		 vPrivate: boolean;
		 );
	 field: (fldaddr: addrrange;
		 fldvar: boolean;
		 );
	 prog,
	 proc,
	 func:	(case pfdeckind: declkind of
		  standard: (key: keyrange);
		  declared: (pflev: levrange;		{static level}
			     pfname: integer;		{subroutine name}
                             pfoname: pStringPtr;	{object.method name}
			     pfactualsize: integer;	{size of parameters}
			     pflabel: unsigned;
			     pfset: boolean;		{has func. return value been set?}
			     pfmark: markPtr;		{memory mark}
			     pfPrivate: boolean;
                             pfaddr: addrrange;		{method object disp}
                             pfparms: ctp;		{parameter list}
			     case pfkind: idkind of
			       actual: (pfdirective: directive_type;
					pfcallnum, pftoolnum: integer;
				       );
			       formal: (pflab: unsigned;
			                pfnext: ctp;
				       );
			    );                      
		);
	 directive: (drkind: directive_type);
	 types: ();
      end;

					{NOTE: Disps in scanner.asm}
					{NOTE: Size in scanner.asm}
   lptr = ^ltype;			{linked list of identifiers used from}
   ltype = record			{ other levels}
      next: lptr;			{next record}
      name: pStringPtr;			{identifier that was used}
      disx: disprange;			{level of the identifier}
      end;

   partialptr = ^partialname;		{partial compile ptr}
   partialname = record			{partial name}
      next: partialptr;
      pname: pStringPtr;
      end;

					{labels}
					{------}
  starrtype = array[1..maxgoto] of integer;
  lbp = ^ labl;
  labl = record
	   nextlab: lbp;
	   defined: boolean;
	   lstlevel: integer;
	   lstarray: starrtype;
	   labval, labname: integer;
	 end;

					{expression attributes}
					{---------------------}
   attrkind = (cst,varbl,expr);
   vaccess = (drct,indrct,inxd);

   attrptr = ^attr;
   attr = record
      typtr: stp;			{type of the expression}
      isPacked: boolean;		{is this value packed?}
      case kind: attrkind of		{form of the expression}
	 cst:	 (cval: valu);		{... a constant}
	 expr:	 ();
	 varbl:	 (case access: vaccess of {... a variable}
		  drct: (vlevel: levrange;
			 dplab: unsigned;
			 dpdisp: addrrange;
			 aname: pStringPtr;
			 );
		  indrct: (idplmt: addrrange);	{... a pointer to something}
		  inxd: ()
		  );
      end;

					{files}
					{-----}
   extfilep = ^filerec;
   filerec = record
      filename: pStringPtr;
      nextfile: extfilep
      end;

   gsosInString = record
       size: integer;
       theString: packed array [1..maxPath] of char;
       end;
   gsosInStringPtr = ^gsosInString;

   {GS/OS class 1 output string}
   gsosOutString = record
       maxSize: integer;
       theString: gsosInString;
       end;
   gsosOutStringPtr = ^gsosOutString;

					{ORCA Shell and ProDOS}
					{---------------------}
   consoleOutDCBGS = record
      pcount: integer;
      ch: char;
      end;

   destroyOSDCB = record		{Destroy DCB}
      pcount: integer;
      pathName: gsosInStringPtr;
      end;

   timeField = array[1..8] of byte;

   optionListRecord = record
      totalSize: integer;
      requiredSize: integer;
      fileSysID: integer;
      theData: packed array [1..100] of char;
      end;
   optionListPtr = ^optionListRecord;

   errorDCBGS = record
      pcount: integer;
      error: integer;
      end;

   expandDevicesDCBGS = record
      pcount: integer;
      inName: gsosInStringPtr;
      outName: gsosOutStringPtr;
      end;

   fastFileDCBGS = record
      pcount: integer;
      action: integer;
      index: integer;
      flags: integer;
      fileHandle: handle;
      pathName: gsosInStringPtr;
      access: integer;
      fileType: integer;
      auxType: longint;
      storageType: integer;
      createDate: timeField;
      modDate: timeField;
      option: optionListPtr;
      fileLength: longint;
      blocksUsed: longint;
      end;

   getFileInfoOSDCB = record
      pcount: integer;
      pathName: gsosInStringPtr;
      access: integer;
      fileType: integer;
      auxType: longint;
      storageType: integer;
      createDateTime: timeField;
      modDateTime: timeField;
      optionList: optionListPtr;
      dataEOF: longint;
      blocksUsed: longint;
      resourceEOF: longint;
      resourceBlocks: longint;
      end;

   getLInfoDCBGS = record
      pcount: integer;
      sFile: gsosOutStringPtr;
      dFile: gsosOutStringPtr;
      namesList: gsosOutStringPtr;
      iString: gsosOutStringPtr;
      merr: byte;
      merrf: byte;
      lops: byte;
      kFlag: byte;
      mFlags: longint;
      pFlags: longint;
      org: longint;
      end;

   versionDCBGS = record
      pcount: integer;
      version: packed array[1..4] of char;
      end;

var
					{misc}
					{----}
   chEndPtr: ptr;			{pointer to the end of the current file}
   chPtr: ptr;				{pointer to the next line of the current file}
   filePtr: ptr; 			{pointer to the start of the current file}

					{counters:}
					{---------}
   intLabel: integer;			{last label number used}
   linecount: integer;			{line number for current line}

					{flags & switches}
					{----------------}
   wait: boolean;			{wait for keypress on non-terminal error?}
   allTerm: boolean;			{treat all errors as terminal?}
   dataBank: boolean;			{save, restore data bank?}
   debug: boolean;			{generate range check code?}
   doingUnit: boolean;			{compiling a unit?}
   goToEditor: boolean;			{return to editor on a terminal error?}
   iso: boolean; 			{iso only?}
   liDCBGS: getLInfoDCBGS;		{get/set LInfo DCB}
   list: boolean;			{list source?}
   memoryFlag: boolean;			{+M flag from command line?}
   noGlobalLabels: boolean;		{have any global labels been detected?}
   noinput,nooutput,noerroroutput: boolean; {tells if stan. dev. are declared}
   printer: boolean;			{is the printer on?}
   printSymbols: boolean;		{print the symbol table?}
   progfound: boolean;			{tells if the code has started}
   progress: boolean;			{print progress information?}
   prterr: boolean;			{to allow forward references in pointer
					 type declaration by supressing error
					 messages}
   stringHeap: boolean;			{has the string heap been used?}

					{error reporting}
					{---------------}
   errinx: 0..maxErr;			{number of errors on this line}
   errlist: array[1..maxErr] of errtype; {list of errors}
   numerr: unsigned;			{number of errors in the program}

{---------------------------------------------------------------}

					{scanner}
					{-------}
   chCnt: unsigned;			{character counter}
   lCnt: unsigned;			{# lines written on this page}
   pageSize: unsigned;			{printing lines on a page}
   title: pString;			{title}

					{expression compilation:}
					{-----------------------}
   gattr: attr;				{describes the expr currently compiled}
   gispacked: boolean;			{was last identifier a component of
					 a packed structure?}
   glcp: ctp;				{last identifier in an expression}

					{structured constants:}
					{---------------------}
   na:	array [1..77] of pStringPtr;

					{file names}
					{----------}
   fNameGS: gsosOutString;		{current source file name}
   kNameGS: gsosOutString;		{Keep file name}
   subsGS: gsosOutString;		{List of subroutines for partial compile}
   ldInfoGS: gsosOutString;		{language dependent parameters (not used)}
   intPrefixGS: gsosOutString;		{prefix to search for interface files}
   usesFileNameGS: gsosOutString;	{active uses file name}

					{bookkeeping of declaration levels:}
					{----------------------------------}
   disx: disprange;			{level of last id searched by searchid}
   level: levrange;			{current static level}
   top: disprange;			{top of display}
   nextLocalLabel: unsigned;		{next available local data label number}

					{NOTE: Disps in scanner.asm}
					{NOTE: Size in scanner.asm}
   display:				{where:	  means:}
      array [disprange] of record
	 ispacked: boolean;
	 labsused: lptr; 		{list of labels used from other levels}
	 fname: ctp;
	 flabel: lbp;
	 case occur: where of		{=blck:	  id is variable id}
	    crec: (clev: levrange;	{=crec:	  id is field id in record with}
		  cdspl: addrrange;	{	  constant address}
                  clab: unsigned;
		  cname: pStringPtr);
	    vrec: (vdsplab: unsigned);	{=vrec:	  id is field id in record with}
                                      	{	  variable address}
	    rec,blck:();
	 end;				{ --> procedure withstatement}

{---------------------------------------------------------------}

					{ORCA Shell and ProDOS}
					{---------------------}

procedure DestroyGS (var parms: destroyOSDCB); prodos ($2002);

procedure ErrorGS (var parms: errorDCBGS); prodos ($0145);

procedure GetFileInfoGS (var parms: getFileInfoOSDCB); prodos ($2006);

procedure GetLInfoGS (var parms: getLInfoDCBGS); prodos ($0141);

procedure ExpandDevicesGS (var parms: expandDevicesDCBGS); prodos ($0154);

procedure FastFileGS (var parms: fastFileDCBGS); prodos ($014E);

procedure SetLInfoGS (var parms: getLInfoDCBGS); prodos ($0142);

procedure VersionGS (var parms: versionDCBGS); prodos ($0147);

{---------------------------------------------------------------}

procedure Brk (code: integer); extern;

{ Break into the debugger					}
{								}
{ parameters:							}
{    code - BRK code						}


function Calloc (size: integer): ptr; extern;

{ Allocate and clear memory					}
{								}
{ parameters:							}
{    size - number of bytes to reserve				}
{								}
{ Returns: pointer to the memory 				}


procedure ClearHourGlass;

{ Erase the hourglass from the screen				}


function CompNames (var name1,name2: pString): integer; extern;

{ Compare two identifiers					}
{								}
{ parameters:							}
{    name1, name2 - identifiers to compare			}
{								}
{ Returns:	-1 if name1 < name2				}
{		0 if name1 = name2				}
{		1 if name1 > name2				}


procedure CopyString (var s1,s2: pString; len: integer); extern;

{ copy a string from s2 to s1					}
{								}
{ parameters:							}
{    s1 - string buffer to copy to				}
{    s2 - string buffer to copy from				}
{    len - length of the s1 string buffer			}


procedure DrawHourGlass;

{ Draw the hourglass on the screen				}


procedure Error (err: integer);

{ flag an error in the current line				}
{								}
{ parameters:							}
{    err - error number						}


{procedure Error2 (loc, err: integer); {debug}

{ flag an error in the current line				}
{								}
{ parameters:							}
{    loc - error location					}
{    err - error number						}


procedure FlagError;

{ do all error processing except writing the message		}


function GenLabel: integer;

{ generate the next local label, checking for too many		}


function GetFileType (var name: gsosOutString): integer;

{ Checks to see if a file exists				}
{								}
{ parameters:							}
{    name - file name to check for				}
{								}
{ Returns: File type if the file exists, or -1 if the file does	}
{    not exist (or if GetFileInfo returns an error)		}


function GetLocalLabel: integer;

{ get the next local label number				}


procedure InitPCommon;

{ Initialize this module 					}


function KeyPress: boolean; extern;
 
{ Has a key been presed?                                        }
{                                                               }
{ If a key has not been pressed, this function returns          }
{ false.  If a key has been pressed, it clears the key          }
{ strobe.  If the key was an open-apple ., a terminal exit      }
{ is performed; otherwise, the function returns true.           }
 

procedure LineFeed;

{ generate a line feed						}


function Malloc (size: integer): ptr; extern;

{ Allocate memory						}
{								}
{ parameters:							}
{    size - number of bytes to reserve				}
{								}
{ Returns: pointer to the memory 				}


procedure MMInit; extern;

{ initialize the memory manager					}


procedure Mark (var p: markPtr); extern;

{ mark the heap							}
{								}
{ parameters:							}
{    p - location to save mark pointer				}


procedure PurgeSource;

{ Purge the current source file					}


procedure Release (p: markPtr); extern;

{ release previously marked heap area				}
{								}
{ parameters:							}
{    p - release all memory from this point on			}


procedure StdNames; extern;

{ initialize the na array					}


procedure Spin;

{ Spin the spinner						}
{								}
{ Notes: Starts the spinner if it is not already in use		}


procedure StopSpin;

{ Stop the spinner						}
{								}
{ Notes: The call is safe, and ignored, if the spinner is	}


procedure SystemError (errNo: integer);

{ intercept run time compiler errors				}


procedure TermError (err: unsigned; msg: pStringPtr);

{ Flag a terminal error						}
{								}
{ parameters:							}
{    err - terminal error number 				}
{    msg - error message, or nil for one of the standard errors	}
{								}
{ Notes: err is not used if msg <> nil				}


procedure WaitForKeyPress; extern;

{ If +w has been used, waits for a keypress			}

{---------------------------------------------------------------}

implementation

const
					{spinner}
					{-------}
   spinSpeed = 8;			{calls before one spinner move}

var
					{spinner}
					{-------}

   spinning: boolean;			{are we spinning now?}
   spinDisp: integer;			{disp to the spinner character}
   spinCount: integer;			{spin loop counter}

   spinner: array[0..3] of char; 	{spinner characters}

procedure ConsoleOutGS (var parms: consoleOutDCBGS); prodos ($015A);

procedure SystemQuitFlags (flags: integer); extern;

{---------------------------------------------------------------}

procedure ExitToEditor (msg: pStringPtr; disp: longint);

{  do an error exit to the editor				}
{								}
{  parameters:							}
{	msg - pointer to the error message			}
{	disp - displacement into the error file			}
{								}
{  variables:							}
{	includeFile - source file name				}

var
   msgGS: gsosInString;			{message}

begin {ExitToEditor}
msgGS.size := length(msg^);		{set up the error message}
msgGS.theString := msg^;
liDCBGS.org := disp;			{mark the error}
liDCBGS.namesList := @msgGS;
liDCBGS.lops := 0;			{prevent re-entry}
liDCBGS.merrf := 255;
with liDCBGS do begin
   sFile := pointer(ord4(sFile)+2);
   dFile := pointer(ord4(dFile)+2);
   iString := pointer(ord4(iString)+2);
   end; {with}
SetLInfoGS(liDCBGS);
StopSpin;				{stop the spinner}
halt(-1);				{return to the shell}
end; {ExitToEditor}

{---------------------------------------------------------------}

procedure ClearHourGlass;

{ Erase the hourglass from the screen				}

var
   coRec: consoleOutDCBGS;		{Console out record}

begin {ClearHourGlass}
coRec.pcount := 1;
coRec.ch := ' '; 	ConsoleOutGS(coRec);
coRec.ch := chr(8);	ConsoleOutGS(coRec);
end; {ClearHourGlass}


procedure DrawHourGlass;

{ Draw the hourglass on the screen				}

var
   coRec: consoleOutDCBGS;		{Console out record}

begin {DrawHourGlass}
coRec.pcount := 1;
coRec.ch := chr(27);	ConsoleOutGS(coRec);
coRec.ch := chr(15);	ConsoleOutGS(coRec);
coRec.ch := 'C'; 	ConsoleOutGS(coRec);
coRec.ch := chr(24);	ConsoleOutGS(coRec);
coRec.ch := chr(14);	ConsoleOutGS(coRec);
coRec.ch := chr(8);	ConsoleOutGS(coRec);
end; {DrawHourGlass}


procedure Error {err: integer};

{ flag an error in the current line				}
{								}
{ parameters:							}
{    err - error number						}

begin {Error}
if errinx >= maxErr - 1 then begin
   errlist[maxErr].nmr := 109;
   errinx := maxErr;
   end {if}
else begin
   errinx := errinx + 1;
   errlist[errinx].nmr := err;
   numerr := numerr + 1;
   end; {else}
errlist[errinx].pos := chCnt;
if liDCBGS.merrf < 16 then
   liDCBGS.merrf := 16;
end; {Error}


{procedure Error2 {loc, err: integer); {debug}

{ flag an error in the current line				}
{								}
{ parameters:							}
{    loc - error location					}
{    err - error number						}

{begin {Error2}
{writeln('Error ', err:1, ' flagged at ', loc:1);
Error(err);
end; {Error2}


procedure FlagError;

{ do all error processing except writing the message		}

begin {FlagError}
LineFeed;				{write the carriage return}
numerr := numerr+1;			{increment the number of errors}
WaitForKeyPress; 			{wait for a keypress}
if liDCBGS.merrf < 16 then		{set the error level}
   liDCBGS.merrf := 16;
end; {FlagError}


function GenLabel{: integer};

{ generate the next local label, checking for too many		}

begin {GenLabel}
if intLabel < maxLabel then
   intLabel := intLabel+1
else begin
   intLabel := 0;
   Error(102);
   end;
GenLabel := intLabel;
end; {GenLabel}


function GetFileType {var name: gsosOutString): integer};

{ Checks to see if a file exists				}
{								}
{ parameters:							}
{    name - file name to check for				}
{								}
{ Returns: File type if the file exists, or -1 if the file does	}
{    not exist (or if GetFileInfo returns an error)		}

var
   giRec: getFileInfoOSDCB;		{GetFileInfo record}

begin {GetFileType}
giRec.pcount := 3;
giRec.pathName := @name.theString;
GetFileInfoGS(giRec);
if ToolError = 0 then
   GetFileType := giRec.fileType
else
   GetFileType := -1;
end; {GetFileType}


function GetLocalLabel{: integer};

{ get the next local label number				}

begin {GetLocalLabel}
GetLocalLabel := nextLocalLabel;
nextLocalLabel := nextLocalLabel+1;
end; {GetLocalLabel}


procedure InitPCommon;

{ Initialize this module 					}

var
   vDCBGS: versionDCBGS;		{for checking the version number}

begin {InitPCommon}
SystemQuitFlags($4000);			{make sure we quit with restart set}

vDCBGS.pCount := 1;			{check the version number}
VersionGS(vDCBGS);
if vDCBGS.version[1] < '2' then
   TermError(14, nil);

spinning := false;			{not spinning the spinner}
spinDisp := 0;				{start spinning with the first character}
spinner[0] := '|';			{set up the spinner characters}
spinner[1] := '/';
spinner[2] := '-';
spinner[3] := '\';
end; {InitPCommon}


procedure LineFeed;

{ generate a line feed						}

begin {LineFeed}
writeln;
if printer then begin
   lcnt := lcnt+1;
   if lcnt = pageSize then begin
      if length(title) = 0 then
	 lcnt := 0
      else begin
	 lcnt := 2;
	 writeln(title);
	 writeln;
	 end; {else}
      end; {if}
   end; {if}
end; {LineFeed}


procedure PurgeSource;

{ Purge the current source file					}

var
   ffDCBGS: fastFileDCBGS;		{FastFile record}

begin {PurgeSource}
with ffDCBGS do begin
   pCount := 5;
   action := 7;
   pathName := @fNameGS.theString;
   end; {with}
FastFileGS(ffDCBGS);
end; {PurgeSource}


procedure Spin;

{ Spin the spinner						}
{								}
{ Notes: Starts the spinner if it is not already in use		}

var
   coRec: consoleOutDCBGS;		{Console out record}

begin {Spin}
if not spinning then begin
   spinning := true;
   spinCount := spinSpeed;
   end; {if}
spinCount := spinCount - 1;
if spinCount = 0 then begin
   spinCount := spinSpeed;
   spinDisp := spinDisp - 1;
   if spinDisp < 0 then
      spinDisp := 3;
   coRec.pcount := 1;
   coRec.ch := spinner[spinDisp];
   ConsoleOutGS(coRec);
   coRec.ch := chr(8);
   ConsoleOutGS(coRec);
   end; {if}
end; {Spin}


procedure StopSpin;

{ Stop the spinner						}
{								}
{ Notes: The call is safe, and ignored, if the spinner is	}
{	inactive.						}

var
   coRec: consoleOutDCBGS;		{Console out record}

begin {StopSpin}
if spinning then begin
   spinning := false;
   coRec.pcount := 1;
   coRec.ch := ' ';
   ConsoleOutGS(coRec);
   coRec.ch := chr(8);
   ConsoleOutGS(coRec);
   end; {if}
end; {StopSpin}


procedure SystemError {errNo: integer};

{ intercept run time compiler errors				}

begin {SystemError}
if errNo = 5 then
   TermError(3, nil)
else
   TermError(7, nil);
end; {SystemError}


procedure TermError {err: unsigned; msg: pStringPtr};

{ Flag a terminal error						}
{								}
{ parameters:							}
{    err - terminal error number 				}
{    msg - error message, or nil for one of the standard errors	}
{								}
{ Notes: err is not used if msg <> nil				}

begin {TermError}
PurgeSource;				{purge the source file}
if msg = nil then
   case err of
      0:msg := @'User termination';
      1:msg := @'Not enough bank zero memory';
      2:msg := @'Non-Pascal file opened at an inappropriate time';
      3:msg := @'Out of memory';
      4:msg := @'Tool or ProDOS error - see listing file';
      5:msg := @'Segment buffer overflow';
      6:msg := @'Error reading uses file';
     {7:msg := @'Compiler error';}
      8:msg := @'Could not open the object file';
      9:msg := @'Could not delete interface file';
     10:msg := @'Units cannot be compiled to memory';
     11:msg := @'Source files must end with a return';
     12:msg := @'Error writing uses file';
     13:msg := @'Error writing object file';
     14:msg := @'ORCA/Pascal requires version 2.0 or later of the shell';
     otherwise:
	msg := @'Compiler error';
     end; {case}
writeln('Terminal error: ', msg^);
if gotoEditor then			{error exit to editor}
   ExitToEditor(msg, ord4(chPtr) - ord4(filePtr) + chCnt)
else begin
   liDCBGS.lops := 0;			{prevent re-entry}
   liDCBGS.merrf := 127;
   with liDCBGS do begin
      sFile := pointer(ord4(sFile)+2);
      dFile := pointer(ord4(dFile)+2);
      namesList := pointer(ord4(namesList)+2);
      iString := pointer(ord4(iString)+2);
      end; {with}
   SetLInfoGS(liDCBGS);
   StopSpin;				{stop the spinner}
   halt(-1);				{return to the shell}
   end; {else}
end; {TermError}

end.

{$append 'pcommon.asm'}
