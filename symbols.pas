{$optimize -1}
{------------------------------------------------------------}
{							     }
{  SymbolTables						     }
{							     }
{  This unit implements the symbol table for ORCA/Pascal.    }
{  Also included are many of the declarations that tie the   }
{  various units together.  The specialized memory manager   }
{  used to make symbol table disposal more efficient is also }
{  included in this module.				     }
{							     }
{  The interfaces for the scanner and object module output   }
{  units are in this unit.  This eliminates the need for a   }
{  common module that would have most of the pertinant	     }
{  symbol table type information.			     }
{							     }
{  By Mike Westerfield					     }
{							     }
{  Copyright August 1987 				     }
{  By the Byte Works, Inc.				     }
{							     }
{------------------------------------------------------------}

unit SymbolTables;

{$segment 'Pascal2'}

interface

{$libprefix '0/obj/'}

uses PCommon, CGI, CGC, ObjOut, Native, Scanner;

{---------------------------------------------------------------}

var
					{pointers:}
					{---------}
   intptr,realptr,charptr,
   byteptr,longptr,compptr,
   doubleptr,extendedptr,stringptr,
   boolptr,nilptr,textptr: stp;		{pointers to entries of standard ids}
   externIdentifier: ctp; 		{extern ID entry}
   forwardIdentifier: ctp;		{forward ID entry}
   utypptr,ucstptr,uvarptr,
   ufldptr,uprcptr,ufctptr,		{pointers to entries for undeclared ids}
   fwptr: ctp;				{head of chain for forw decl type ids}
   inptr,outptr,erroroutputptr: ctp;	{standard I/O}
   dummyString: stp;			{index entry for string constants}

{---------------------------------------------------------------}

function CompObjects (fsp1, fsp2: stp): boolean;

{ See if two objects are assignment compatible			}
{								}
{ parameters:							}
{    fsp1 - object to assign to					}
{    fsp2 - object to assign					}
{								}
{ Returns: True if the structures are compatible, else false	}


function CompTypes (fsp1, fsp2: stp): boolean;

{ determine if two structures are type compatible		}
{								}
{ parameters:							}
{    fsp1, fsp2 - structures to check				}
{								}
{ Returns: True if the structures are compatible, else false	}


procedure EnterStdTypes;

{ enter the base types						}


procedure EntStdNames;

{ enter standard names in the program symbol table		}


procedure EnterId (fcp: ctp); extern;

{ Enter an identifier at the current stack frame level		}
{								}
{ parameters:							}
{    fcp - identifier to enter					}


procedure EnterUndecl;

{ enter fake identifiers for use when identifiers are		}
{ undeclared							}


procedure GenSymbols (sym: ctp; doGlobals: integer);

{ generate the symbol table                                     }
{								}
{ Notes: Defined as extern in Native.pas			}


procedure GetBounds (fsp: stp; var fmin,fmax: longint);

{ get internal bounds of subrange or scalar type		}
{ (assume fsp<>longptr and fsp<>realptr)			}
{								}
{ parameters:							}
{    fsp - type to get the bounds for				}
{    fmin, fmax - (output) bounds				}


function GetType (tp: stp; isPacked: boolean): baseTypeEnum;

{ find the base type for a variable type			}
{								}
{ parameters:							}
{    tp - variable type						}
{    isPacked - is the variable packed?				}
{								}
{ returns: Variable base type					}


function IsReal (fsp: stp): boolean;

{ determine if fsp is one of the real types			}
{								}
{ parameters:							}
{    fsp - structure to check					}
{								}
{ Returns: True if fsp is a real, else false			}


function IsString (fsp: stp): boolean;

{ determine if fsp is a string					}
{								}
{ parameters:							}
{    fsp - structure to check					}
{								}
{ Returns: True if fsp is a string, else false			}


procedure SearchSection (fcp: ctp; var fcpl: ctp); extern;

{ find record fields and forward declared procedure id's	}
{								}
{ parameters:							}
{    fcp - top of identifier tree				}
{    fcpl - (outout) identifier					}


procedure SearchId (fidcls: setofids; var fcp: ctp); extern;

{ find an identifier						}
{								}
{ parameters:							}
{    fidcls - kinds of identifiers to look for			}
{    fcp - (output) identifier found				}


function StrLen (tp: stp): integer;

{ Find the length of a string variable (for library calls)	}
{								}
{ parameters:							}
{    tp - string variable					}
{								}
{ Returns: length of the string					}

{---------------------------------------------------------------}

implementation

{---------------------------------------------------------------}

function CompObjects {fsp1, fsp2: stp): boolean};

{ See if two objects are assignment compatible			}
{								}
{ parameters:							}
{    fsp1 - object to assign to					}
{    fsp2 - object to assign					}
{								}
{ Returns: True if the structures are compatible, else false	}

begin {CompObjects}
CompObjects := false;
if fsp1^.form = objects then begin
  if fsp2^.form = objects then begin
    while fsp2 <> nil do begin
      if fsp1 = fsp2 then begin
	fsp2 := nil;
	CompObjects := true;
	end {if}
      else
	fsp2 := fsp2^.objparent;
      end; {while}
    end {if}
  else if fsp2 = nilptr then
    CompObjects := true;
  end; {if}
end; {CompObjects}


function CompTypes {fsp1,fsp2: stp): boolean};

{ determine if two structures are type compatible		}
{								}
{ parameters:							}
{    fsp1, fsp2 - structures to check				}
{								}
{ Returns: True if the structures are compatible, else false	}

var
   lmin1,lmin2: integer;
   comp: boolean;

begin {CompTypes}
if fsp1 = fsp2 then
   CompTypes := true
else if (fsp1 <> nil) and (fsp2 <> nil) then begin
   if fsp1^.form = subrange then begin
      if fsp2^.form = subrange then
	 CompTypes := CompTypes(fsp1^.rangetype,fsp2^.rangetype)
      else
	 CompTypes := CompTypes(fsp1^.rangetype,fsp2);
      end {if}
   else if fsp2^.form = subrange then
      CompTypes := CompTypes(fsp1,fsp2^.rangetype)
   else if fsp1 = byteptr then
      CompTypes := CompTypes(fsp2,intptr)
   else if fsp2 = byteptr then
      CompTypes := CompTypes(fsp1,intptr)
   else if fsp1^.form = fsp2^.form then begin
      if fsp1^.form = power then
	 CompTypes := CompTypes(fsp1^.elset,fsp2^.elset) and
	    ((fsp1^.ispacked = pkeither) or (fsp2^.ispacked = pkeither) or
	    (fsp1^.ispacked = fsp2^.ispacked))
      else if fsp1^.form = arrays then begin
	 comp := IsString(fsp1) and IsString(fsp2);
	 if iso then
	    comp := comp and (fsp1^.size = fsp2^.size);
	 CompTypes := comp;
	 end {else if}
      else if fsp1^.form = pointerStruct then
	 CompTypes := (fsp1 = nilptr) or (fsp2 = nilptr)
      else
	 CompTypes := IsReal(fsp1) and IsReal(fsp2);
      end {else if}
   else if fsp1^.form = objects then
      CompTypes := fsp2 = nilptr
   else if fsp2^.form = objects then
      CompTypes := fsp1 = nilptr
   else
      CompTypes := false
   end
else
   CompTypes := true
end; {CompTypes}
 

procedure EnterStdTypes;

{ enter the base types						}

begin {EnterStdTypes}
byteptr := pointer(Malloc(sizeof(structure)));	{byte}
with byteptr^ do begin
   size := bytesize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
intptr := pointer(Malloc(sizeof(structure)));	{integer}
with intptr^ do begin
   size := intsize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
longptr := pointer(Malloc(sizeof(structure)));	{long}
with longptr^ do begin
   size := longsize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
realptr := pointer(Malloc(sizeof(structure)));	{real}
with realptr^ do begin
   size := realsize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
doubleptr := pointer(Malloc(sizeof(structure))); {double}
with doubleptr^ do begin
   size := doublesize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
compptr := pointer(Malloc(sizeof(structure))); {comp}
with compptr^ do begin
   size := compsize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
extendedptr := pointer(Malloc(sizeof(structure))); {extended}
with extendedptr^ do begin
   size := extendedsize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
charptr := pointer(Malloc(sizeof(structure)));	{char}
with charptr^ do begin
   size := charsize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := standard;
   hasSFile := false;
   end; {with}
stringptr := pointer(Malloc(sizeof(structure))); {string}
with stringptr^ do begin
   size := packedcharsize*2;
   ispacked := pkpacked;
   form := arrays;
   hasSFile := false;
   aeltype := charptr;
   inxtype := pointer(Malloc(sizeof(structure)));
   with inxtype^ do begin
      size := intsize;
      form := subrange;
      rangetype := intptr;
      min := 1;
      max := 2;
      end; {with}
   end; {with}
boolptr := pointer(Malloc(sizeof(structure)));	{bool}
with boolptr^ do begin
   size := boolsize;
   ispacked := pkunpacked;
   form := scalar;
   scalkind := declared;
   hasSFile := false;
   end; {with}
nilptr := pointer(Malloc(sizeof(structure)));	{nil}
with nilptr^ do begin
   eltype := nil;
   size := ptrsize;
   ispacked := pkunpacked;
   form := pointerStruct;
   hasSFile := false;
   end; {with}
textptr := pointer(Malloc(sizeof(structure)));	{text}
with textptr^ do begin
   filtype := charptr;
   filsize := packedcharsize*2;
   size := ptrsize;
   ispacked := pkunpacked;
   form := files;
   hasSFile := true;
   end; {with}
end; {EnterStdTypes}


procedure EntStdNames;

{ enter standard names in the program symbol table		}

var
   cp,cp1: ctp;
   i: integer;

begin {EntStdNames}
cp := pointer(Malloc(sizeof(identifier)));	{integer}
with cp^ do begin
   name := @'INTEGER';
   idtype := intptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{byte}
with cp^ do begin
   name := @'BYTE';
   idtype := byteptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{longint}
with cp^ do begin
   name := @'LONGINT';
   idtype := longptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{real}
with cp^ do begin
   name := @'REAL';
   idtype := realptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{double}
with cp^ do begin
   name := @'DOUBLE';
   idtype := doubleptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{comp}
with cp^ do begin
   name := @'COMP';
   idtype := compptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{extended}
with cp^ do begin
   name := @'EXTENDED';
   idtype := extendedptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{char}
with cp^ do begin
   name := @'CHAR';
   idtype := charptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{boolean}
with cp^ do begin
   name := @'BOOLEAN';
   idtype := boolptr;
   klass := types;
   hasIFile := false;
   end; {with}
EnterId(cp);  
cp := pointer(Malloc(sizeof(identifier)));	{text}
with cp^ do begin
   name := @'TEXT';
   idtype := textptr;
   klass := types;
   hasIFile := true;
   end; {with}
EnterId(cp);  
cp1 := nil;
for i := 1 to 2 do begin
   cp := pointer(Malloc(sizeof(identifier)));	{false,true}
   with cp^ do begin
      name := na[i];
      idtype := boolptr;
      next := cp1;
      values.ival := i-1;
      klass := konst;
      hasIFile := false;
      end; {with}
   EnterId(cp);
   cp1 := cp
   end; {with}
boolptr^.fconst := cp;
cp := pointer(Malloc(sizeof(identifier)));	{forward}
with cp^ do begin
   name := @'FORWARD';
   next := nil;
   klass := directive;
   drkind := drforw;
   hasIFile := false;
   end; {with}
EnterId(cp);
forwardIdentifier := cp;
cp := pointer(Malloc(sizeof(identifier)));	{extern}
with cp^ do begin
   name := @'EXTERN';
   next := nil;
   klass := directive;
   drkind := drextern;
   hasIFile := false;
   end; {with}
EnterId(cp);
externIdentifier := cp;
cp := pointer(Malloc(sizeof(identifier)));	{external}
with cp^ do begin
   name := @'EXTERNAL';
   next := nil;
   klass := directive;
   drkind := drextern;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{override}
with cp^ do begin
   name := @'OVERRIDE';
   next := nil;
   klass := directive;
   drkind := droverride;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{prodos}
with cp^ do begin
   name := @'PRODOS';
   next := nil;
   klass := directive;
   drkind := drprodos;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{tool}
with cp^ do begin
   name := @'TOOL';
   next := nil;
   klass := directive;
   drkind := drtool1;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{usertool}
with cp^ do begin
   name := @'USERTOOL';
   next := nil;
   klass := directive;
   drkind := drtool2;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{vector}
with cp^ do begin
   name := @'VECTOR';
   next := nil;
   klass := directive;
   drkind := drvector;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{maxint}
with cp^ do begin
   name := @'MAXINT';
   idtype := intptr;
   next := nil;
   values.ival := maxint;
   klass := konst;
   hasIFile := false;
   end; {with}
EnterId(cp);
cp := pointer(Malloc(sizeof(identifier)));	{maxint4}
with cp^ do begin
   name := @'MAXINT4';
   idtype := longptr;
   next := nil;
   values.valp := pointer(Malloc(constantRec_longC));
   values.valp^.lval := 2147483647;
   values.valp^.cclass := longC;
   klass := konst;
   hasIFile := false;
   end; {with}
EnterId(cp);
for i := 3 to 4 do begin 			{input,output}
   cp := pointer(Malloc(sizeof(identifier)));
   with cp^ do begin
      name := na[i];
      idtype := textptr;
      klass := varsm;
      vkind := actual;
      next := nil;
      vlev := 1;
      vcontvar := false;
      vrestrict := false;
      fromUses := false;
      hasIFile := true;
      end; {with}
   EnterId(cp);
   if i = 3 then inptr := cp else outptr := cp;
   end; {with}
cp := pointer(Malloc(sizeof(identifier)));	{erroroutput}
with cp^ do begin
   name := @'ERROROUTPUT';
   idtype := textptr;
   klass := varsm;
   vkind := actual;
   next := nil;
   vlev := 1;
   vcontvar := false;
   vrestrict := false;
   fromUses := false;
   hasIFile := true;
   end; {with}
EnterId(cp);
erroroutputptr := cp;
for i := 5 to 23 do begin
   cp := pointer(Malloc(sizeof(identifier)));	{std procs}
   with cp^ do begin
      name := na[i];
      idtype := nil;
      next := nil;
      key := i-4;
      klass := proc;
      pfdeckind := standard;
      hasIFile := false;
      end; {with}
   EnterId(cp)
   end; {with}
for i := 24 to 40 do begin
   cp := pointer(Malloc(sizeof(identifier)));	{std funcs}
   with cp^ do begin
      name := na[i];
      idtype := nil;
      next := nil;
      key := i-23;
      klass := func;
      pfdeckind := standard;
      hasIFile := false;
      end; {with}
   EnterId(cp);
   end; {with}
for i := 41 to 50 do begin
   cp := pointer(Malloc(sizeof(identifier)));	{more std procs}
   with cp^ do begin
      name := na[i];
      idtype := nil;
      next := nil;
      key := i-21;
      klass := proc;
      pfdeckind := standard;
      hasIFile := false;
      end; {with}
   EnterId(cp)
   end; {with}
for i := 51 to 77 do begin
   cp := pointer(Malloc(sizeof(identifier)));	{more std funcs}
   with cp^ do begin
      name := na[i];
      idtype := nil;
      next := nil;
      key := i-33;
      klass := func;
      pfdeckind := standard;
      hasIFile := false;
      end; {with}
   EnterId(cp);
   end; {with}
end; {EntStdNames}


procedure EnterUndecl;

{ enter fake identifiers for use when identifiers are		}
{ undeclared							}

begin {EnterUndecl}
utypptr := pointer(Malloc(sizeof(identifier)));	
with utypptr^ do begin
   name := @'  ';
   idtype := nil;
   klass := types;
   hasIFile := false;
   end; {with}
ucstptr := pointer(Malloc(sizeof(identifier)));	
with ucstptr^ do begin
   name := @'  ';
   idtype := nil;
   next := nil;
   values.ival := 0;
   klass := konst;
   hasIFile := false;
   end; {with}
uvarptr := pointer(Malloc(sizeof(identifier)));	
with uvarptr^ do begin
   name := @'  ';
   idtype := nil;
   vkind := actual;
   next := nil;
   vlev := 0;
   vlabel := 1;
   vcontvar := false;
   vrestrict := false;
   klass := varsm;
   fromUses := false;
   hasIFile := false;
   end; {with}
ufldptr := pointer(Malloc(sizeof(identifier)));	
with ufldptr^ do begin
   name := @'  ';
   idtype := nil;
   next := nil;
   fldaddr := 0;
   klass := field;
   hasIFile := false;
   end; {with}
uprcptr := pointer(Malloc(sizeof(identifier)));	
with uprcptr^ do begin
   name := @'  ';
   idtype := nil;
   pfdirective := drnone;
   next := nil;
   pflev := 0;
   pfname := GenLabel;
   fldvar := false;
   klass := proc;
   pfdeckind := declared;
   pfkind := actual;
   hasIFile := false;
   end; {with}
ufctptr := pointer(Malloc(sizeof(identifier)));	
with ufctptr^ do begin
   name := @'  ';
   idtype := nil;
   next := nil;
   pfdirective := drnone;
   pflev := 0;
   pfname := GenLabel;
   klass := func;
   pfdeckind := declared;
   pfkind := actual;
   hasIFile := false;
   end; {with}
dummyString := pointer(Malloc(sizeof(structure)));	
with dummyString^ do begin
   size := 2;
   ispacked := pkpacked;
   form := subrange;
   hasSFile := false;
   rangetype := intptr;
   min := 1;
   max := 2;
   end; {with}
end; {EnterUndecl}
 

procedure GenSymbols {sym: ctp; doGlobals: integer};

{ generate the symbol table                                     }
{								}
{ Notes: Defined as extern in Native.pas			}

const
   noDisp = -1;                         {disp returned by GetTypeDisp if the type was not found}

type
   tpPtr = ^tpRecord;			{type list displacements}
   tpRecord = record
      next: tpPtr;
      tp: stp;
      disp: integer;
      end;

var
   tpList,tp2: tpPtr;			{type displacement list}


   function GetTypeDisp (tp: stp): integer;

   { Look for an existing entry for this type			}
   {								}
   { Parameters:						}
   {    tp - type to look for					}
   {								}
   { Returns: Disp to a variable of the same type, or 0 if	}
   {    there is no such entry.					}
   {								}
   { Notes: If the type is not in the type list, it is entered	}
   {   in the list by this call.				}

   var
      tp1, tp2: tpPtr;			{used to manipulate type list}

   begin {GetTypeDisp}
   tp1 := tpList;			{look for the type}
   tp2 := nil;
   while tp1 <> nil do
      if tp1^.tp = tp then begin
         tp2 := tp1;
         tp1 := nil;
         end {if}
      else
         tp1 := tp1^.next;
   if tp2 <> nil then            
      GetTypeDisp := tp2^.disp		{return disp to entry}
   else begin
      GetTypeDisp := noDisp;			{no entry}
      new(tp1);				{create a new entry}
      tp1^.next := tpList;
      tpList := tp1;
      tp1^.tp := tp;
      tp1^.disp := symLength;
      end; {else}
   end; {GetTypeDisp}


   procedure GenSymbol (sym: ctp; maybeLast: boolean);

   { generate one symbol entry					}
   {								}
   { parameters:						}
   {    sym - identifier to generate				}
   {    maybelast - true if this may be the last node in a	}
   {       record or object tree, false if not; unused for	}
   {       variables						}

   var
      disp: integer;			{disp to symbol of same type}


      procedure WriteAddress (sym: ctp);

      { Write the address and DP flag				}
      {								}
      { parameters:						}
      {    sym - identifier					}
      {    maybeLast - true if this might be the last entry,	}
      {       else false					}

      var
         size: longint;			{used to break apart longints}

      begin {WriteAddress}
      if sym^.klass = field then begin
         size := sym^.fldaddr;
         CnOut2(long(size).lsw);
         CnOut2(long(size).msw);
         CnOut(ord(not(maybeLast and (sym^.rlink = nil))));
         end {if}
      else if sym^.vlev = 1 then begin
         RefName(sym^.name, 0, 4, 0);
         CnOut(1);
         end {else if}
      else begin
         CnOut2(localLabel[sym^.vlabel]);
         CnOut2(0);
         CnOut(0);
         end; {else}
      end; {WriteAddress}


      procedure WriteName (sym: ctp);

      { Write the name field for an identifier			}
      {								}
      { parameters:						}
      {    sym - identifier					}

      var
         len: 0..maxint;		{string length}
         j: 0..maxint;			{loop/index variable}

      begin {WriteName}
      Purge;				{generate the address of the variable  }
      Out(235); Out(4);			{ name                                 }
      LabelSearch(maxLabel, 4, 0, 0);
      if stringsize <> 0 then begin
         Out(129);
         Out2(stringsize); Out2(0);
         Out(1);
         end; {if}
      Out(0);
      len := length(sym^.name^);	{place the name in the string buffer}
      if maxstring-stringsize >= len+1 then begin
         stringspace[stringsize+1] := chr(len);
         for j := 1 to len do
            stringspace[j+stringsize+1] := sym^.name^[j];
         stringsize := stringsize+len+1;
         end {if}
      else
         Error(132);
      end; {WriteName}


      procedure WriteScalarType (tp: stp; modifiers, subscripts: integer);

      { Write a scalar type and subscipt field			}
      {								}
      { parameters:						}
      {    tp - type pointer					}
      {    modifiers - value to or with the type code		}
      {    subscripts - number of subscripts			}

      var
         val: integer;			{type value}

      begin {WriteScalarType}
      case GetType(tp, tp^.isPacked) of
	 cgByte:	val := $40;
         cgUByte:	val := $00;
         cgWord:	val := $01;
         cgUWord:	val := $41;
         cgLong:	val := $02;
         cgULong:	val := $42;
         cgReal:	val := $03;
         cgDouble:	val := $04;
         cgComp:	val := $0A;
         cgExtended:	val := $05;
         otherwise:	val := $01;
         end; {case}
      CnOut(val | modifiers);		{write the format byte}
      CnOut2(subscripts);		{write the # of subscripts}
      end; {WriteScalarType}


      procedure WritePointerType (tp: stp; subscripts: integer);

      { write a pointer type field				}
      {								}
      { parameters:						}
      {    tp - pointer type					}
      {    subscripts - number of subscript fields		}

      begin {WritePointerType}
      case tp^.eltype^.form of
         scalar:	WriteScalarType(tp^.eltype, $80, subscripts);
         subrange:	WriteScalarType(tp^.eltype^.rangetype, $80, subscripts);
         otherwise:	begin
        		CnOut(11);
        		CnOut2(subscripts);
                        end;
         end; {case}
      end; {WritePointerType}


      procedure ExpandPointerType (tp: stp); forward;
      

      procedure ExpandRecordType (tp: stp);

      { write the type entries for a record or object		}
      {								}
      { parameters:						}
      {    tp - record/object type				}

      var
         ip: ctp;			{used to trace the field list}

      begin {ExpandRecordType}
      if tp^.form = records then
         ip := tp^.fstfld
      else
         ip := tp^.objfld;
      GenSymbol(ip, true);
      end; {ExpandRecordType}


      procedure WriteArrays (tp: stp);

      { handle an array type					}
      {								}
      { parameters:						}
      {    tp - array type					}

      var
         count: unsigned;		{# of subscripts}
         lmin, lmax: addrrange;		{index range}
         tp2: stp;			{used to trace array type list}

      begin {WriteArrays}
      count := 0;			{count the subscripts}
      tp2 := tp;
      while tp2^.form = arrays do begin
         count := count+1;
         tp2 := tp2^.aeltype;
         end; {while}
      if tp2^.form = scalar then	{write the type code}
         if GetType(tp2, tp^.isPacked) in [cgByte,cgUByte] then begin
            count := count-1;
            CnOut(6);
            CnOut2(count);
            end {if}
         else
            WriteScalarType(tp2, 0, count)
      else if tp2^.form = subrange then
         WriteScalarType(tp2^.rangetype, 0, count)
      else if tp2^.form = pointerStruct then
         WritePointerType(tp2, count)
      else begin
         CnOut(12);
         CnOut2(count);
         end; {else if}
      while count <> 0 do begin		{write the subscript entries}
         CnOut2(0); CnOut2(0);
         GetBounds(tp, lmin, lmax);
         CnOut2(long(lmin).lsw); CnOut2(long(lmin).msw);
         CnOut2(long(lmax).lsw); CnOut2(long(lmax).msw);
         symLength := symLength+12;
         tp := tp^.aeltype;
         count := count-1;
         end; {while}
      if tp2^.form = pointerStruct then	{expand complex types}
         ExpandPointerType(tp2)
      else if tp2^.form in [records,objects] then
         ExpandRecordType(tp2);
      end; {WriteArrays}


      procedure ExpandPointerType {tp: stp};

      { write the type entries for complex pointer types	}
      {								}
      { parameters:						}
      {    tp - pointer type					}

      var
	 disp: integer;			{disp to symbol of same type}

      begin {ExpandPointerType}
      if tp^.eltype <> nil then
	 if tp^.eltype^.form in [pointerStruct,arrays,records,objects] then
            begin
            symLength := symLength+12;
            CnOut2(0); CnOut2(0);
            CnOut2(0); CnOut2(0);
            CnOut(0);
	    case tp^.eltype^.form of
               pointerStruct:	begin
         		   	WritePointerType(tp^.eltype, 0);
                           	ExpandPointerType(tp^.eltype);
                           	end;
               arrays:		WriteArrays(tp^.aeltype);
               records,
               objects:		begin
				disp := GetTypeDisp(tp^.eltype);
                                if disp = noDisp then begin
                                   if tp^.eltype^.form = records then
        		   	      CnOut(12)
                                   else
        		   	      CnOut(14);
        		   	   CnOut2(0);
                           	   ExpandRecordType(tp^.eltype);
                                   end {if}
                                else begin
        		   	   CnOut(13);
        		   	   CnOut2(disp);
                                   end; {else}
                           	end;
               end; {case}
            end; {if}
      end; {ExpandPointerType}


   begin {GenSymbol}
   if sym^.llink <> nil then
      GenSymbol(sym^.llink, false);

   if sym^.klass in [varsm,field] then
      if sym^.idtype <> nil then
         if sym^.idtype^.form in
            [scalar,subrange,pointerStruct,arrays,records,objects] then begin
	    WriteName(sym);		{write the name field}
	    WriteAddress(sym);		{write the address field}
	    case sym^.idtype^.form of
               scalar:		WriteScalarType(sym^.idtype, 0, 0);
               subrange:	WriteScalarType(sym^.idtype^.rangetype, 0, 0);
               pointerStruct:	begin
         			WritePointerType(sym^.idtype, 0);
                        	ExpandPointerType(sym^.idtype);
                        	end;
               arrays:		WriteArrays(sym^.idtype);
               records,
               objects:		begin
				disp := GetTypeDisp(sym^.idtype);
                        	if disp = noDisp then begin
                                   if sym^.idtype^.form = records then
        			      CnOut(12)
                                   else
        			      CnOut(14);
        			   CnOut2(0);
                        	   ExpandRecordType(sym^.idtype);
                        	   end {if}
                        	else begin
        			   CnOut(13);
        			   CnOut2(disp);
                        	   end; {else}
                        	end;
               end; {case}
	    symLength := symLength+12;	{update length of symbol table}
            end; {if}

   if sym^.rlink <> nil then
      GenSymbol(sym^.rlink, maybeLast);
   end; {GenSymbol}


begin {GenSymbols}
tpList := nil;				{no types so far}
if sym <> nil then			{generate the symbols}
   GenSymbol(sym, false);
while tpList <> nil do begin		{dispose of type list}
   tp2 := tpList;
   tpList := tp2^.next;
   dispose(tp2);
   end; {while}
end; {GenSymbols}


procedure GetBounds {fsp: stp; var fmin,fmax: longint};

{ get internal bounds of subrange or scalar type		}
{ (assume fsp<>longptr and fsp<>realptr)			}
{								}
{ parameters:							}
{    fsp - type to get the bounds for				}
{    fmin, fmax - (output) bounds				}

begin {GetBounds}
fmin := 0;
fmax := 0;
if fsp <> nil then
with fsp^ do
   if form = subrange then begin
      fmin := min;
      fmax := max;
      end {if}
   else if fsp = charptr then begin
      fmin := ordminchar;
      fmax := ordmaxchar;
      end {else if}
   else if fsp = intptr then begin
      fmin := -maxint;
      fmax := maxint;
      end {else if}
   else if fsp = byteptr then
      fmax := 255
   else if fconst <> nil then
      fmax := fconst^.values.ival
end; {GetBounds}
 

function GetType {tp: stp; isPacked: boolean): baseTypeEnum};

{ find the base type for a variable type			}
{								}
{ parameters:							}
{    tp - variable type						}
{    isPacked - is the variable packed?				}
{								}
{ returns: Variable base type					}

begin {GetType}
case tp^.form of
   scalar:
      if tp=intptr then GetType := cgWord
      else if (tp=boolptr) or (tp=charptr) then
	 if isPacked then
            GetType := cgUByte
	 else
            GetType := cgUWord
      else if tp^.scalkind = declared then GetType := cgUWord
      else if tp=realptr then GetType := cgReal
      else if tp=byteptr then GetType := cgUByte
      else if tp=longptr then GetType := cgLong
      else if tp=doubleptr then GetType := cgDouble
      else if tp=extendedptr then GetType := cgExtended
      else if tp=compptr then GetType := cgComp
      else begin
	 GetType := cgWord;
	 Error(113);
	 end; {else}
   subrange: begin
      if tp^.rangetype = intptr then
	 if tp^.min >= 0 then
            GetType := cgUWord
	 else
            GetType := cgWord
      else if tp^.rangetype = longptr then
	 if tp^.min >= 0 then
            GetType := cgULong
	 else
            GetType := cgLong
      else
	 GetType := GetType(tp^.rangetype, isPacked);
      end;
   pointerStruct,
   files,
   objects:
      GetType := cgULong;
   power:
      GetType := cgSet;
   arrays,
   records:
      GetType := cgString;
   otherwise: begin
      GetType := cgWord;
      Error(113);
      end;
   end; {case}
end; {GetType}


function IsReal {fsp: stp): boolean};

{ determine if fsp is one of the real types			}
{								}
{ parameters:							}
{    fsp - structure to check					}
{								}
{ Returns: True if fsp is a real, else false			}

begin {IsReal}
if fsp = realptr then
   IsReal := true
else if fsp = doubleptr then
   IsReal := true
else if fsp = extendedptr then
   IsReal := true
else if fsp = compptr then
   IsReal := true
else          
   IsReal := false;
end; {IsReal}


function IsString {fsp: stp): boolean};

{ determine if fsp is a string					}
{								}
{ parameters:							}
{    fsp - structure to check					}
{								}
{ Returns: True if fsp is a string, else false			}

var
   low,hi: longint;			{range of index variable}

begin {IsString}
IsString := false;
if fsp <> nil then
   with fsp^ do
      if form = arrays then
         if aeltype = charptr then
	    if CompTypes(inxtype,intptr) then
	       if ispacked = pkpacked then
	          if inxtype = nil then
	             {string constants have nil index types}
	             IsString := true
	          else begin
	             GetBounds(inxtype,low,hi);
	             IsString := ((low = 1) or ((low = 0) and (not iso)))
		        and (hi > 1);
	             end; {else}
end; {IsString}


function StrLen {tp: stp): integer};

{ Find the length of a string variable (for library calls)	}
{								}
{ parameters:							}
{    tp - string variable					}
{								}
{ Returns: length of the string					}

var
   low,hi: longint;			{range of index variable}

begin {StrLen}
if tp <> nil then
   with tp^ do 
      if (inxType = dummyString) or (inxType = nil) then
	 StrLen := long(size).lsw
      else begin
	 GetBounds(inxType,low,hi);
	 if low = 0 then
	    StrLen := -long(hi).lsw
	 else
	    StrLen := long(hi).lsw;
	 end; {else}
end; {StrLen}

end.

{$append 'symbols.asm'}
