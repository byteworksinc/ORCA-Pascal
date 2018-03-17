{$optimize 15}
{------------------------------------------------------------}
{							     }
{  ORCA/Pascal Call Procedure				     }
{							     }
{  The call procedure handles parsing, semantic analysis     }
{  and code generation for all procedure and function calls. }
{  This includes both user-defined and predeclared	     }
{  routines.						     }
{							     }
{  By Mike Westerfield					     }
{							     }
{  Copyright March 1988					     }
{  By the Byte Works, Inc.				     }
{							     }
{------------------------------------------------------------}

unit Call;

interface

{$segment 'Pascal2'}
{$LibPrefix '0/obj/'}

uses pcommon, scanner, cgi, symbols;

{-- Externally available variables --------------------------------------------}

type
					{subroutine calls}
                                        {----------------}
  callKinds = (cStandard, cMethod, cInherited);

					{temporary variable allocation}
					{-----------------------------}
  tempPtr = ^tempRecord;
  tempRecord = record
    last,next: tempPtr;			{doubly linked list}
    labelNum: integer; 			{label number}
    size: integer;			{size of the variable}
    end;

var
  psize: integer;			{size of the parameter space for the current stack frame}
  lc: addrrange; 			{current stack frame size}

					{temporary variable allocation}
					{-----------------------------}
  tempList: tempPtr;			{list of temp work variables}

{-- Externally available subroutines ------------------------------------------}

procedure Call (fsys: setofsys; fcp,fprocp: ctp);

{ generate a call to a procedure or function			}
{								}
{ parameters:							}
{    fsys -							}
{    fcp -							}
{    fprocp -							}


procedure CallNonStandard (fsys: setofsys; fcp,fprocp: ctp; odisp: longint;
  callKind: callKinds);

{ Handle a call to a user defined procedure/function		}
{								}
{ parameters:							}
{    fsys -							}
{    fcp -							}
{    fprocp -							}
{    odisp - disp in object for method calls; else 0		}
{    callKind - type of this call				}


procedure CheckBool;
{load a value, insuring that it is boolean}

procedure CheckBnds(fsp: stp);
{generate range checking code (if needed)}

procedure FreeTemp (labelNum, size: integer);

{ place a temporary label in the available label list		}
{								}
{ parameters:							}
{    labelNum - number of the label to free			}
{    size - size of the variable 				}
{								}
{ variables:							}
{    tempList - list of free labels				}


function GetTemp (size: integer): integer;

{ find a temporary work variable 				}
{								}
{ parameters:							}
{    size - size of the variable 				}
{								}
{ variables:							}
{    tempList - list of free labels				}
{								}
{ Returns the label number.					}


procedure Load;
{load a value onto the evaluation stack}

procedure LoadAddress;
{load the address of a variable onto the top of the stack}

procedure LoadStringAddress;
{load the address and length of a string}

procedure LoadString(kind: stringKind);
{load the address of a string constant}

function ParmSize(lsp: stp; vkind: idkind): integer;
{find the length of a parameter}

procedure ResetTemp;

{ forget all of the temporary work variables			}


procedure Store(var fattr: attr);
{store the value on top of stack}

{-- Private declarations ------------------------------------------------------}

implementation

const
  realfw      =	    16;			{field width for reals & doubles}
  longfw      =	    16;			{field width for long integers}
  intfw	      =	     8;			{field width for integers}
  boolfw      =	     8;			{field width for booleans}

var
  lkey: keyrange;			{proc/func key for std proc compilation}
{-- Imported subroutines ------------------------------------------------------}

procedure DoConstant(fsys: setofsys; var fsp: stp; var fvalu: valu); extern;
{compile a constant term}

procedure Expression(fsys: setofsys; fprocp: ctp); extern;
{compile an expression}

  procedure Selector (fsys: setofsys; fcp,fprocp: ctp; var isMethod: boolean);
  extern;

  { handle indexing arrays, field selection, dereferencing of	}
  { pointers, windowing files					}
  {								}
  { parameters:							}
  {    fsys -							}
  {    fcp -							}
  {    fprocp -							}
  {    isMethod - (returned) Did the selection resolve to a	}
  {       method call?  If so, take no further action.		}

{-- Private subroutines -------------------------------------------------------}

procedure Variable(fsys: setofsys; fprocp: ctp);
{compile a variable for the parm list of a standard proc/func}

var
  isMethod: boolean;			{dummy variable for Selector call}
  lcp: ctp;

begin {Variable}
if sy = ident then begin
  SearchId([varsm,field],lcp);
  InSymbol;
  end
else begin
  Error(2);
  lcp := uvarptr;
  end;
Selector(fsys, lcp, fprocp, isMethod);
glcp := lcp;
end; {Variable}

procedure GetPutClose(fsys: setofsys; fprocp: ctp);
{Compile one of the named standard procs}

begin {GetPutClose}
{compile the file variable}
Variable(fsys + [rparent],fprocp);
{load the file variable}
Load;
Gen0t(pc_stk, cgULong);
{do type checking on file variable}
if gattr.typtr <> nil then
  if gattr.typtr^.form <> files then
    Error(44);
{generate the standard proc call}
Gen1(pc_csp,lkey{get,put,opn,cls})
end; {GetPutClose}

procedure resetrewriteopen(fsys: setofsys; fprocp: ctp);

var
  key: integer;			   {open kind key; 1->read; 2->write; 3->both}
  size: longint; 		      {for remembering file size}
  lsp: stp;			      {file type}
  fkind: (stin,stout,errout,fileout); {kind of file}

begin {resetrewriteopen}
{process the file variable}
Variable(fsys+[comma,rparent],fprocp);
fkind := fileout;
if gattr.typtr = nil then
  Error(44)
else if gattr.typtr^.form = files then begin
  size := gattr.typtr^.filtype^.size;
  if glcp = outptr then begin
    fkind := stout;
    if nooutput then Error(92);
    end
  else if glcp = inptr then begin
    fkind := stin;
    if noinput then Error(91);
    end
  else if glcp = erroroutputptr then
    fkind := errout;
  end
else Error(44);
{determine the type of the open}
if lkey = 3 then
  key := 3
else
  key := lkey-4;
case key of
  1: if fkind in [stout,errout] then Error(44);
  2: if fkind = stin then Error(44);
  3: if fkind <> fileout then Error(44);
  end;
if gattr.typtr <> nil then
  if fkind = fileout then begin
    {load the file variable}
    LoadAddress;
    Gen0t(pc_stk, cgULong);
    {push the open type onto the stack}
    lsp := glcp^.idtype;
    if lsp^.form = pointerStruct then lsp := lsp^.eltype;
    Gen1t(pc_ldc, key+4*ord(lsp=textptr), cgWord);
    Gen0t(pc_stk, cgWord);
    Gen0t(pc_bno, cgWord);
    {load the length of the file}
    Gen1t(pc_ldc, ord(size), cgWord);
    Gen0t(pc_stk, cgWord);
    Gen0t(pc_bno, cgWord);
    end {if}
  else begin
    Gen1t(pc_ldc, ord(fkind), cgWord);
    Gen0t(pc_stk, cgWord);
    Gen0t(pc_bno, cgWord);
    end; {else}
{if there is another parameter, use it for the file name}
if sy = comma then begin
  if iso then Error(112);
  InSymbol;
  Expression(fsys+[rparent],fprocp);
  if gattr.typtr <> nil then
    if IsString(gattr.typtr) then begin
      LoadStringAddress;
      Gen0t(pc_bno, cgULong);
      end {if}
    else Error(44)
  else Error(44);
  end
else begin
  GenLdcLong(0);
  Gen0t(pc_stk, cgULong);
  Gen0t(pc_bno, cgULong);
  Gen1t(pc_ldc, 0, cgWord);
  Gen0t(pc_stk, cgWord);
  Gen0t(pc_bno, cgWord);
  end; {else}
{open the file}
if fkind = fileout then
  Gen1(pc_csp,3{opn})
else
  Gen1(pc_csp,115{rdr});
end; {resetrewriteopen}

procedure seek(fsys: setofsys; fprocp: ctp);
{Compile the seek statement}

begin {seek}
Variable(fsys+[comma,rparent],fprocp);
if gattr.typtr = nil then
  Error(44)
else if gattr.typtr^.form <> files then
  Error(44);
Load;
Gen0t(pc_stk, cgULong);
Match(comma,20);
Expression(fsys+[rparent],fprocp);
Load;
if gattr.typtr <> nil then begin
  if (gattr.typtr=intptr) or (gattr.typtr=byteptr) then begin
    Gen2(pc_cnv,ord(cgWord),ord(cgLong));
    gattr.typtr := longptr;
    end;
  if gattr.typtr <> longptr then Error(44);
  end
else Error(44);
Gen0t(pc_stk, cgULong);
Gen0t(pc_bno, cgULong);
Gen1(pc_csp,44{sek});
end; {seek}

procedure page(fsys: setofsys; fprocp: ctp);
{compile a page procedure call}

var
  lsp: stp;

begin {page}
if sy = lparent then begin
  InSymbol;
  Variable(fsys+[rparent],fprocp);
  lsp := gattr.typtr;
  if lsp <> nil then
    if lsp = textptr then
      if sy <> rparent then begin
	Error(4);
	Skip(fsys+[rparent]);
	end
      else InSymbol
    else Error(44)
  else Error(44);
  if glcp = outptr then begin
    Gen0(pc_nop);
    Gen1(pc_csp,32{pag});
    end {if}
  else if glcp = erroroutputptr then begin
    Gen0(pc_nop);
    Gen1(pc_csp,33{pag});
    end {else if}
  else begin
    Load;
    Gen0t(pc_stk, cgULong);
    Gen1(pc_csp,15{pag});
    end;
  end
else begin
  if nooutput then Error(92);
  Gen0(pc_nop);
  Gen1(pc_csp,32{pag});
  end;
end; {page}

procedure HaltSeed(fsys: setofsys; fprocp: ctp);
{compile a call to halt or seed}

begin {HaltSeed}
Expression(fsys+[rparent],fprocp);
Load;
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(44);
  end
else Error(44);
Gen0t(pc_stk, cgWord);
Gen1(pc_csp,46+lkey);
end; {HaltSeed}

procedure Delete(fsys: setofsys; fprocp: ctp);
{compile a call to the delete string procedure}

begin {Delete}
{load the string to delete characters from}
Expression(fsys+[comma,rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then begin
    if gattr.kind <> varbl then Error(44);
    LoadStringAddress;
    end
  else Error(44)
else Error(44);
{load the index}
Match(comma,20);
Expression(fsys+[comma,rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then
    Error(44);
  end
else Error(44);
{load the number of chars to delete}
Match(comma,20);
Expression(fsys+[rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(44);
  end
else Error(44);
{call the delete procedure}
Gen1(pc_csp,68{dlt});
end; {Delete}

procedure Insert(fsys: setofsys; fprocp: ctp);
{compile a call to insert one string an another}

begin {Insert}
{load the string to insert characters into}
Expression(fsys+[comma,rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else if gattr.typtr = charptr then begin
    Load;
    Gen0t(pc_stk, cgWord);
    GenLdcLong(-1);
    Gen0t(pc_stk, cgULong);
    Gen0t(pc_bno, cgWord);
    end
  else Error(44)
else Error(44);
{load the string to insert}
Match(comma,20);
Expression(fsys+[comma,rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then begin
    if gattr.kind <> varbl then
      Error(44);
    LoadStringAddress;
    Gen0t(pc_bno, cgWord);
    end
  else Error(44)
else Error(44);
{load the index}
Match(comma,20);
Expression(fsys+[comma,rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(44);
  end
else Error(44);
{call the insert procedure}
Gen1(pc_csp,69{ins});
end; {Insert}

procedure CommandLineShellID(fsys: setofsys; fprocp: ctp);
{compile a call to CommandLine or ShellID}

begin {CommandLineShellID}
{load the string to place characters in}
Expression(fsys+[rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then begin
    if gattr.kind <> varbl then Error(44);
    LoadStringAddress;
    end
  else Error(44)
else Error(44);
{call the procedure}
Gen1(pc_csp,46+lkey);
end; {CommandLineShellID}

procedure StartGraphDesk(fsys: setofsys; fprocp: ctp);
{compile a call to StartGraph or StartDesk}

begin {StartGraphDesk}
Expression(fsys+[rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then
    Error(44);
  end
else Error(44);
Gen1(pc_csp,46+lkey);
end; {StartGraphDesk}

procedure EndGraphDesk;
{compile a call to EndGraph or EndDesk}

begin {EndGraphDesk}
Gen0(pc_nop);
Gen1(pc_csp,46+lkey);
end; {EndGraphDesk}

procedure DoRead (fsys: setofsys; fprocp: ctp);

{ compile a read procedure call					}
{								}
{ Parameters:							}
{    fsys -							}
{    fprocp -							}

var
   lattr,tattr: attr;
   lsp : stp;
   needBno: boolean;			{do we need a pc_bno?}
   test: boolean;
   standardIn: boolean;		        {is the read from standard input?}
   llb: unsigned; 		        {for allocating temporary space}
   inLocalPtr: boolean;		        {is file ptr in local area?}

begin {DoRead}
inLocalPtr := false;
standardIn := true;
lattr.typtr := textptr;
if sy = lparent then begin
   InSymbol;
   Variable(fsys + [comma, rparent], fprocp);
   if glcp <> nil then
      with glcp^ do
         if klass = varsm then begin
	    if vcontvar then
               Error(97);
	    if vlev <> level then
               vrestrict := true;
	    end; {if}
   lsp := gattr.typtr;
   test := false;
   if lsp <> nil then
      if lsp^.form = files then

         {handle reads from files}
         with gattr, lsp^ do begin
	    if (lkey = 13{readln}) and (typtr <> textptr) then
               Error(44);
	    if access = indrct then begin
	       Load;
	       llb := GetTemp(ptrsize);
	       Gen3t(pc_str, llb, 0, 0, cgULong);
	       inLocalPtr := true;
	       dplab := llb;
               gattr.isPacked := false;
	       kind := varbl;
	       access := drct;
	       vlevel := level;
	       FreeTemp(llb, ptrsize);
	       end; {if}
	    lattr := gattr;
	    standardIn := glcp = inptr;
	    if sy = rparent then begin
	       if lkey = 7{read} then
                  Error(44);
	       test := true;
	       end {if}
	    else if sy <> comma then begin
	       Error(44);
	       Skip(fsys + [comma, rparent]);
	       end; {else if}
	    if sy = comma then begin
	       InSymbol;
	       Variable(fsys + [comma, rparent], fprocp);
	       end {if}
	    else
               test := true;
	    end {with}
         else if noinput then
            Error(91);
   if lattr.typtr = textptr then begin

      {read from a text file}
      if not test then
         repeat
	    if glcp <> nil then
	       with glcp^ do
	          if klass = varsm then begin
	             if vcontvar then
                        Error(97);
	             if vlev <> level then
                        vrestrict := true;
	             end; {if}
            needBno := false;
	    if IsString(gattr.typtr) then begin
	       if gattr.kind <> expr then begin
	          LoadAddress;
	          Gen0t(pc_stk, cgULong);
	          Gen1t(pc_ldc, StrLen(gattr.typtr), cgWord);
	          Gen0t(pc_stk, cgWord);
	          Gen0t(pc_bno, cgWord);
                  needBno := true;
	          end;         {if}
	       end {if}
	    else begin
	       if gattr.typtr <> nil then
	          if (gattr.access<>drct) or
	             (gattr.typtr^.form in [arrays,records,objects,files]) then
	             LoadAddress;
	       end; {else}
	    tattr := gattr;
	    if not standardIn then begin
	       gattr := lattr;
	       if inLocalPtr then
	          Gen3t(pc_lod, gattr.dplab, 0, 0, cgULong)
	       else
	          Load;
	       Gen0t(pc_stk, cgULong);
               if needBno then
	          Gen0t(pc_bno, cgULong);
	       end; {if}
	    if tattr.typtr <> nil then
	       if (tattr.typtr^.form <= subrange) or IsString(tattr.typtr) then
                  begin
	          if standardIn then
                     Gen0(pc_nop);
	          if CompTypes(intptr, tattr.typtr) then begin
	             if standardIn then
		        Gen1(pc_csp, 59{rii})
	             else
		        Gen1(pc_csp, 5{rdi});
	             CheckBnds(tattr.typtr);
	             Store(tattr);
	             end {if}
	          else if CompTypes(longptr, tattr.typtr) then begin
	             if standardIn then
		        Gen1(pc_csp, 98{ril})
	             else
		        Gen1(pc_csp, 99{rdl});
	             CheckBnds(tattr.typtr);
	             Store(tattr);
	             end {else if}
	          else if CompTypes(charptr, tattr.typtr) then begin
	             if standardIn then
		        Gen1(pc_csp, 58{ric})
	             else
		        Gen1(pc_csp, 7{rdc});
	             CheckBnds(tattr.typtr);
	             Store(tattr);
	             end {else if}
	          else if CompTypes(realptr, tattr.typtr) then begin
	             if standardIn then
		        Gen1(pc_csp, 61{rir})
	             else
		        Gen1(pc_csp, 6{rdr});
	             CheckBnds(tattr.typtr);
	             Store(tattr);
	             end {else if}
	          else if CompTypes(stringptr, tattr.typtr) then begin
	             if standardIn then
		        Gen1(pc_csp, 84{ris})
	             else
		        Gen1(pc_csp, 50{rds});
	             end {esle if}
	          else
                     Error(44);
                  end {if}
	       else
                  Error(44);
	    test := sy <> comma;
	    if not test then begin
	       InSymbol;
	       Variable(fsys + [comma, rparent], fprocp);
	       end; {if}
         until test;
      end {if}
   else if not test then begin

      {do non-text reads}
      repeat
         if glcp <> nil then
	    with glcp^ do
	       if klass = varsm then begin
	          if vcontvar then
                     Error(97);
	          if vlev <> level then
                     vrestrict := true;
	          end; {if}
         if gattr.typtr <> nil then
	    if (gattr.access<>drct) or
	       (gattr.typtr^.form in [arrays,records,files]) then
	       LoadAddress;
         tattr := gattr;
         if not CompTypes(gattr.typtr, lattr.typtr^.filtype) then
            if not CompObjects(gattr.typtr, lattr.typtr^.filtype) then
               Error(44);
         gattr := lattr;
         if inLocalPtr then
	    Gen3t(pc_lod, gattr.dplab, 0, 0, cgULong)
         else
	    Load;
         with gattr do begin
	    typtr := lattr.typtr^.filtype;
	    kind := varbl;
            isPacked := false;
	    access := indrct;
	    idplmt := 0;
	    end; {with}
         if gattr.typtr^.form in [scalar,subrange,pointerStruct,power,objects]
            then
	    Load
         else
	    LoadAddress;
         case tattr.typtr^.form of
	    scalar,subrange: begin
	       CheckBnds(tattr.typtr);
	       Store(tattr);
	       end;
	    pointerStruct,power,objects:
	       Store(tattr);
	    arrays,records:
	       Gen2(pc_mov, long(tattr.typtr^.size).msw,
                  long(tattr.typtr^.size).lsw);
	    files: Error(71);
	    end; {case}

         {get the next file variable}
         gattr := lattr;
         if inLocalPtr then
	    Gen3t(pc_lod, gattr.dplab, 0, 0, cgULong)
         else
	    Load;
         Gen0t(pc_stk, cgULong);
         Gen1(pc_csp, 1{get});
         test := sy <> comma;
         if not test then begin
	    InSymbol;
	    Variable(fsys+[comma,rparent], fprocp);
	    end; {if}
      until test;
      end; {else if not test}
   Match(rparent, 4);
   end {if}
else if lkey = 7{read} then
   Error(44);
if lkey = 13{readln} then begin
   if standardIn then begin
      Gen0(pc_nop);
      Gen1(pc_csp, 60{rin});
      end {if}
   else begin
      gattr := lattr;
      if inLocalPtr then
         Gen3t(pc_lod, gattr.dplab, 0, 0, cgULong)
      else
         Load;
      Gen0t(pc_stk, cgULong);
      Gen1(pc_csp, 13{rln})
      end; {else}
   end; {if}
end; {DoRead}

procedure DoWrite(fsys: setofsys; fprocp: ctp);
{compile a call to write, writeln}

var
  lsp: stp;
  default,defaultr : boolean;
  llkey: keyrange;
  lcp: ctp;
  len: addrrange;
  lattr,tattr: attr;
  test: boolean;
  standardOut,errorOut: boolean;      {is the write to the console?}
  llb: unsigned; 		      {for allocating temporary space}
  inLocalPtr: boolean;		      {is file ptr in local area?}

  procedure LoadFile;
  {load the file variable}

  begin {LoadFile}
  gattr := lattr;
  if inLocalPtr then
    Gen3t(pc_lod, gattr.dplab, 0, 0, cgULong)
  else
    Load;
  end; {LoadFile}

begin {DoWrite}
inLocalPtr := false;
llkey := lkey;
standardOut := true;
errorOut := false;
lattr.typtr := textptr;
if sy = lparent then begin
  InSymbol;
  Expression(fsys + [comma,colon,rparent],fprocp);
  lsp := gattr.typtr;
  test := false;
  if lsp <> nil then
    if lsp^.form = files then
      with gattr, lsp^ do begin
	if access = indrct then begin
	  Load;
	  llb := GetTemp(ptrsize);
	  Gen3t(pc_str, llb, 0, 0, cgULong);
          gattr.isPacked := false;
	  kind := varbl;
	  access := drct;
	  vlevel := level;
	  dplab := llb;
	  inLocalPtr := true;
	  FreeTemp(llb, ptrsize);
	  end;
	lattr := gattr;
	standardOut := glcp = outptr;
	errorOut := glcp = erroroutputptr;
	if (lkey = 14{writeln}) and (typtr <> textptr) then Error(44);
	if sy = rparent then begin
	  if llkey = 8{write} then Error(44);
	  test := true;
	  end
	else if sy <> comma then begin
	  Error(44);
	  Skip(fsys+[comma,rparent]);
	  end;
	if sy = comma then begin
	  InSymbol;
	  if lattr.typtr = textptr then
	    Expression(fsys+[comma,colon,rparent],fprocp);
	  end
	else test := true
	end
    else if nooutput then Error(92);
  if lattr.typtr = textptr then begin

    {text file reads}
    if not test then
      repeat
	lsp := gattr.typtr;
	if lsp^.form = subrange then
          lsp := lsp^.rangetype;
	if lsp <> nil then
	  if lsp^.form <= subrange then begin
	    Load;
	    if (lsp = intptr) or (lsp = byteptr) or (lsp = charptr)
	      or (lsp = boolptr) then
	      Gen0t(pc_stk, cgWord)
	    else if lsp = longptr then
	      Gen0t(pc_stk, cgLong)
	    else if IsReal(lsp) then
	      Gen0t(pc_stk, cgExtended)
	    else if lsp <> nil then
	      Gen0t(pc_stk, cgULong);
	    end {if}
	  else begin
	    if IsString(gattr.typtr) then
	      LoadStringAddress
	    else begin
	      LoadAddress;
	      Gen0t(pc_stk, cgULong);
	      end; {else}
	    end;
	if sy = colon then begin
	  InSymbol;
	  Expression(fsys + [comma,colon,rparent],fprocp);
	  Load;
	  Gen0t(pc_stk, cgWord);
	  Gen0t(pc_bno, cgWord);
	  if gattr.typtr <> nil then
	    if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then
	      Error(44);
	  if debug then
            Gen2t(pc_chk, 0, maxint, cgUWord);
	  default := false;
	  end
	else default := true;
	if sy = colon then begin
	  InSymbol;
	  Expression(fsys + [comma,rparent],fprocp);
	  Load;
	  Gen0t(pc_stk, cgWord);
	  Gen0t(pc_bno, cgWord);
	  if gattr.typtr <> nil then
	    if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then
	      Error(44);
	  if not IsReal(lsp) then
            Error(50);
	  defaultr := false;
	  end
	else defaultr := true;
	if (lsp = intptr) or (lsp = byteptr) then begin
	  if default then begin
	    Gen1t(pc_ldc, intfw, cgWord);
	    Gen0t(pc_stk, cgWord);
	    Gen0t(pc_bno, cgWord);
	    end; {if}
	  if standardOut then
	    Gen1(pc_csp,16{woi})
	  else if errorOut then
	    Gen1(pc_csp,42{wei})
	  else begin
	    LoadFile;
	    Gen0t(pc_stk, cgULong);
	    Gen0t(pc_bno, cgULong);
	    Gen1(pc_csp,9{wri});
	    end;
	  end
	else if lsp = longptr then begin
	  if default then begin
	    Gen1t(pc_ldc, longfw, cgWord);
	    Gen0t(pc_stk, cgWord);
	    Gen0t(pc_bno, cgWord);
	    end; {if}
	  if standardOut then
	    Gen1(pc_csp,100{wol})
	  else if errorOut then
	    Gen1(pc_csp,101{wel})
	  else begin
	    LoadFile;
	    Gen0t(pc_stk, cgULong);
	    Gen0t(pc_bno, cgULong);
	    Gen1(pc_csp,102{wrl});
	    end;
	  end
	else if IsReal(lsp) then begin
	  if default then begin
	    Gen1t(pc_ldc, realfw, cgWord);
	    Gen0t(pc_stk, cgWord);
	    Gen0t(pc_bno, cgWord);
	    end; {if}
	  if defaultr then begin
	    Gen1t(pc_ldc, 0, cgWord);
	    Gen0t(pc_stk, cgWord);
	    Gen0t(pc_bno, cgWord);
	    end; {if}
	  if standardOut then
	    Gen1(pc_csp,62{wor})
	  else if errorOut then
	    Gen1(pc_csp,53{wer})
	  else begin
	    LoadFile;
	    Gen0t(pc_stk, cgULong);
	    Gen0t(pc_bno, cgULong);
	    Gen1(pc_csp,10{wrr});
	    end; {else}
	  end {else if}
	else if lsp = charptr then begin
	  if standardOut then
	    if default then
	      Gen1(pc_csp,40{wol})
	    else
	      Gen1(pc_csp,37{woc})
	  else if errorOut then
	    if default then
	      Gen1(pc_csp,41{wel})
	    else
	      Gen1(pc_csp,39{wec})
	  else begin
	    if default then begin
	      Gen1t(pc_ldc, 1, cgWord);
	      Gen0t(pc_stk, cgWord);
	      Gen0t(pc_bno, cgWord);
	      end; {if}
	    LoadFile;
	    Gen0t(pc_stk, cgULong);
	    Gen0t(pc_bno, cgULong);
	    Gen1(pc_csp,8{wrc});
	    end;
	  end
	else if lsp = boolptr then begin
	  if default then begin
	    Gen1t(pc_ldc, boolfw, cgWord);
	    Gen0t(pc_stk, cgWord);
	    Gen0t(pc_bno, cgWord);
	    end; {if}
	  if standardOut then
	    Gen1(pc_csp,29{wob})
	  else if errorOut then
	    Gen1(pc_csp,31{web})
	  else begin
	    LoadFile;
	    Gen0t(pc_stk, cgULong);
	    Gen0t(pc_bno, cgULong);
	    Gen1(pc_csp,46{wrb});
	    end;
	  end
	else if lsp <> nil then begin
	  if IsString(lsp) then begin
	    if default then begin
	      Gen1t(pc_ldc, $8000, cgWord);
	      Gen0t(pc_stk, cgWord);
	      Gen0t(pc_bno, cgWord);
	      end; {if}
	    if standardOut then
	      Gen1(pc_csp,21{wos})
	    else if errorOut then
	      Gen1(pc_csp,25{wes})
	    else begin
	      LoadFile;
	      Gen0t(pc_stk, cgULong);
	      Gen0t(pc_bno, cgULong);
	      Gen1(pc_csp,45{wrs});
	      end;
	    end
	  else Error(44);
	  end;
	test := sy <> comma;
	if not test then begin
	  InSymbol;
	  Expression(fsys + [comma,colon,rparent],fprocp)
	  end
      until test;
    end
  else if not test then begin

    {handle non-text files}
    repeat
      {assign the Expression to the file variable}
      LoadFile;
      tattr := gattr;
      with tattr do begin
	typtr := gattr.typtr^.filtype;
        isPacked := false;
	kind := varbl;
	access := indrct;
	idplmt := 0;
	end;
      if debug then
        GenL2t(pc_chk, 1, maxaddr, cgULong);
      Expression(fsys+[comma,colon,rparent],fprocp);
      lsp := gattr.typtr;
      if (lsp^.form <= subrange) or (lsp^.form = objects) then
        Load
      else
        LoadAddress;
      if not CompTypes(lsp,lattr.typtr^.filtype) then
        if not CompObjects(lsp,lattr.typtr^.filtype) then
          Error(44);
      case tattr.typtr^.form of
	scalar,subrange: begin
	  CheckBnds(tattr.typtr);
	  Store(tattr);
	  end;
	pointerStruct,power,objects:
	  Store(tattr);
	arrays,records:
	  Gen2(pc_mov, long(tattr.typtr^.size).msw, long(tattr.typtr^.size).lsw);
	files: Error(71);
	end; {case}
      {write the file variable to the file}
      LoadFile;
      Gen0t(pc_stk, cgULong);
      Gen1(pc_csp,2{put});
      test := sy<>comma;
      if not test then InSymbol;
    until test;
    end; {else if not test}
  Match(rparent,4);
  end
else if lkey = 8{write} then Error(44);
if lkey = 14{writeln} then begin
  if standardOut then begin
    Gen0(pc_nop);
    Gen1(pc_csp,26{wol});
    end {if}
  else if errorOut then begin
    Gen0(pc_nop);
    Gen1(pc_csp,27{wel});
    end {else if}
  else begin
    LoadFile;
    Gen0t(pc_stk, cgULong);
    Gen1(pc_csp,14{wln});
    end;
  end;
end; {DoWrite}

procedure DoPack(fsys: setofsys; fprocp: ctp);
{compile a call to pack}

var
  lsp,lsp1: stp;
  elSize: longint;		      {element size}
  lmin,lmax: longint;		      {subrange of unpacked array}

begin {DoPack}
{get the unpacked array}
Variable(fsys + [comma,rparent],fprocp);
LoadAddress;
Gen0t(pc_stk, cgULong);
if gattr.typtr <> nil then
  with gattr.typtr^ do
    if (form = arrays) and (ispacked = pkunpacked) then begin
      Gen1t(pc_ldc, long(aeltype^.size).lsw, cgUWord);
      Gen0t(pc_stk, cgUWord);
      Gen0t(pc_bno, cgUWord);
      GenLdcLong(size div aeltype^.size);
      Gen0t(pc_stk, cgULong);
      Gen0t(pc_bno, cgULong);
      lsp := inxtype;
      lsp1 := aeltype;
      GetBounds(lsp,lmin,lmax);
      end
    else Error(44);
Match(comma,20);
{get the staring index}
Expression(fsys + [comma,rparent],fprocp);
Load;
if CompTypes(longptr, lsp) then
  if (gattr.typtr = intptr) or (gattr.typtr = bytePtr) then begin
    Gen2(pc_cnv,ord(cgWord),ord(cgLong));
    gattr.typtr := longptr;
    end; {end}
if gattr.typtr <> nil then
  if gattr.typtr^.form <> scalar then
    Error(44)
  else if not CompTypes(lsp,gattr.typtr) then
    Error(44);
if not CompTypes(longptr, gattr.typtr) then begin
  Gen2(pc_cnv, ord(GetType(gattr.typtr, false)), ord(cgLong));
  gattr.typtr := longptr;
  end; {end}
Match(comma,20);
if lmin <> 0 then begin
  GenLdcLong(lmin);
  Gen0(pc_sbl);
  end; {if}
Gen0t(pc_stk, cgULong);
Gen0t(pc_bno, cgULong);
{get the packed array}
Variable(fsys + [rparent],fprocp);
LoadAddress;
Gen0t(pc_stk, cgULong);
Gen0t(pc_bno, cgULong);
if gattr.typtr <> nil then
  with gattr.typtr^ do
    if (form = arrays) and (ispacked = pkpacked) then begin
      if not CompTypes(aeltype,lsp1) then Error(44);
      elSize := aelType^.size;
      if (aelType = charptr) or (aelType = boolptr) then
	elSize := packedCharSize;
      Gen1t(pc_ldc, long(elSize).lsw, cgUWord);
      Gen0t(pc_stk, cgUWord);
      Gen0t(pc_bno, cgUWord);
      GenLdcLong(size div elSize);
      Gen0t(pc_stk, cgULong);
      Gen0t(pc_bno, cgULong);
      end {if}
    else Error(44);
{move the elements}
Gen1(pc_csp, 51{pak});
end; {DoPack}

procedure DoUnpack(fsys: setofsys; fprocp: ctp);
{compile a call to unpack}

var
  lsp,lsp1: stp;
  elSize: longint;		      {element size}
  lmin,lmax: longint;		      {subrange of unpacked array}

begin {DoUnpack}
Variable(fsys + [comma,rparent],fprocp);
LoadAddress;
Gen0t(pc_stk, cgULong);
if gattr.typtr <> nil then
  with gattr.typtr^ do
    if (form = arrays) and (ispacked = pkpacked) then begin
      elSize := aelType^.size;
      if (aelType = charptr) or (aelType = boolptr) then
	elSize := packedCharSize;
      lsp1 := aeltype;
      Gen1t(pc_ldc, long(elSize).lsw, cgWord);
      Gen0t(pc_stk, cgUWord);
      Gen0t(pc_bno, cgUWord);
      GenLdcLong(size div elSize);
      Gen0t(pc_stk, cgULong);
      Gen0t(pc_bno, cgULong);
      end
    else Error(44);
Match(comma,20);
Variable(fsys + [comma,rparent],fprocp);
LoadAddress;
Gen0t(pc_stk, cgULong);
Gen0t(pc_bno, cgULong);
if gattr.typtr <> nil then
  with gattr.typtr^ do
    if (form = arrays) and (ispacked = pkunpacked) then begin
      if not CompTypes(aeltype,lsp1) then Error(44);
      Gen1t(pc_ldc, long(aeltype^.size).lsw, cgWord);
      Gen0t(pc_stk, cgUWord);
      Gen0t(pc_bno, cgUWord);
      GenLdcLong(size div aeltype^.size);
      Gen0t(pc_stk, cgULong);
      Gen0t(pc_bno, cgULong);
      lsp := inxtype;
      GetBounds(lsp,lmin,lmax);
      end
    else Error(44);
Match(comma,20);
Expression(fsys + [rparent],fprocp);
Load;
if CompTypes(longptr, lsp) then
  if (gattr.typtr = intptr) or (gattr.typtr = bytePtr) then begin
    Gen2(pc_cnv, ord(cgWord), ord(cgLong));
    gattr.typtr := longptr;
    end; {end}
if gattr.typtr <> nil then
  if gattr.typtr^.form <> scalar then
    Error(44)
  else if not CompTypes(lsp,gattr.typtr) then
    Error(44);
if not CompTypes(longptr, gattr.typtr) then begin
  Gen2(pc_cnv, ord(GetType(gattr.typtr, false)), ord(cgLong));
  gattr.typtr := longptr;
  end; {end}
if lmin <> 0 then begin
  GenLdcLong(lmin);
  Gen0(pc_sbl);
  end; {if}
Gen0t(pc_stk, cgULong);
Gen0t(pc_bno, cgULong);
Gen1(pc_csp, 52{upk});
end; {DoUnpack}


procedure DoNew (fsys: setofsys; fprocp: ctp);

{ compile a call to new						}
{								}
{ parameters:							}
{    fsys -							}
{    fprocp -							}

label 1;

var
  lattr: attr;				{pointer/object variable's gattr}
  lsize: addrrange;			{amount of memory to allocate}
  lsp,lsp1: stp;
  lval: valu;
  ofld: ctp;				{object field list}
  varts: integer;


  function InitMethods (lcp: ctp): unsigned;

  { Set the address for all methods in a new object		}
  {								}
  { parameters:							}
  {    lsp - head of object field tree				}
  {								}
  { returns: Number of methods					}

  var
     count: unsigned;

  begin {InitMethods}
  count := 0;
  if lcp^.llink <> nil then
    count := InitMethods(lcp^.llink);
  if lcp^.rlink <> nil then
    count := count + InitMethods(lcp^.rlink);
  if lcp^.klass in [proc,func] then begin
    count := count + 1;
    Gen0Name(pc_lad, lcp^.pfoname);
    Gen0t(pc_stk, cgULong);
    GenLdcLong(lcp^.pfaddr);
    Gen0t(pc_stk, cgULong);
    Gen0t(pc_bno, cgULong);
    Gen0t(pc_bno, cgULong);
    end; {if}
  InitMethods := count;
  end; {InitMethods}


begin {DoNew}
{get the pointer to allocate}
Variable(fsys + [comma,rparent],fprocp);
lattr := gattr;
LoadAddress;
Gen0t(pc_stk, cgULong);

{examine the variable to see how much memory to allocate}
lsp := nil;
varts := 0;
lsize := 0;
ofld := nil;
if gattr.typtr <> nil then
  with gattr.typtr^ do
    if form = pointerStruct then begin
      if eltype <> nil then begin
	lsize := eltype^.size;
	if eltype^.form = records then
          lsp := eltype^.recvar;
	end; {if}
      end {if}
    else if (form = objects) and (objdef) then begin
      lsize := objsize;
      ofld := objfld;
      end {else if}
    else
      Error(44);

{handle the variant parts}
while sy = comma do begin
  InSymbol;
  DoConstant(fsys + [comma,rparent],lsp1,lval);
  varts := varts+1;
  if lsp = nil then
    Error(82)
  else if lsp^.form <> tagfld then
    Error(86)
  else if lsp^.tagfieldp <> nil then
    if CompTypes(lsp^.tagfieldp^.idtype,lsp1) then begin
      lsp1 := lsp^.fstvar;
      while lsp1 <> nil do
	with lsp1^ do
	  if varval = lval.ival then begin
	    lsize := size;
	    lsp := subvar;
	    goto 1;
	    end {if}
	  else
	    lsp1 := nxtvar;
      end {if}
    else
      Error(44);
1:  end {while} ;

{for objects, set up size, generation, and method addresses}
if ofld <> nil then begin
  if lattr.typtr <> nil then begin
    Gen1t(pc_ldc, lattr.typtr^.objlevel, cgUWord);
    Gen0t(pc_stk, cgUWord);
    Gen0t(pc_bno, cgUWord);
    end; {if}
  GenLdcLong(lsize);
  Gen0t(pc_stk, cgULong);
  Gen0t(pc_bno, cgULong);
  Gen1t(pc_ldc, InitMethods(ofld), cgUWord);
  Gen0t(pc_stk, cgUWord);
  Gen0t(pc_bno, cgUWord);

{generate the call to allocate memory}
  Gen1(pc_csp,118{newobj});
  end {if}
else if lsize < maxint then begin
  Gen1t(pc_ldc, long(lsize).lsw, cgWord);
  Gen0t(pc_stk, cgWord);
  Gen0t(pc_bno, cgWord);
  Gen1(pc_csp,11{new});
  end {if}
else begin
  if lsize > $010000 then
    if smallMemoryModel then
      Error(122);
  GenLdcLong(lsize);
  Gen0t(pc_stk, cgULong);
  Gen0t(pc_bno, cgULong);
  Gen1(pc_csp,116{new4});
  end; {else}

{if this points to a file, zero the area}
gattr := lattr;
if gattr.typtr <> nil then
  if gattr.typtr^.form <> objects then
    if gattr.typtr^.hasSFile then begin
      Gen1t(pc_ldc, ord(gattr.typtr^.size), cgWord);
      Gen0t(pc_stk, cgWord);
      Load;
      Gen0t(pc_stk, cgULong);
      Gen0t(pc_bno, cgULong);
      Gen1(pc_csp,35{clr});
      end; {if}
end; {DoNew}


procedure DoSizeof;
{compile a call to sizeof}

var
  lcp: ctp;

begin {DoSizeof}
Match(lparent,9);
SearchId([types,varsm], lcp);
if lcp^.idtype^.size < maxint then begin
  Gen1t(pc_ldc, ord(lcp^.idtype^.size), cgWord);
  gattr.typtr := intptr;
  end {if}
else begin
  GenLdcLong(lcp^.idtype^.size);
  gattr.typtr := longptr;
  end; {else}
InSymbol;
end; {DoSizeof}


procedure DoDispose (fsys: setofsys; fprocp: ctp);

{ Compile a call to dispose					}
{								}
{ parameters:							}
{    fsys -							}
{    fprocp -							}

label 1;

var
  lsp,lsp1: stp;
  lval: valu;

begin {DoDispose}
{get the pointer to dispose}
Expression(fsys+[rparent,comma],fprocp);

if gattr.typtr <> nil then
  if gattr.typtr^.form = pointerStruct then begin
    {dispose of a pointer}
    Load;
    Gen0t(pc_stk, cgULong);
    Gen1(pc_csp,17{dsp});
    lsp := nil;
    with gattr.typtr^ do
      if eltype <> nil then
	if eltype^.form = records then
          lsp := eltype^.recvar;
    while sy = comma do begin
      InSymbol;
      DoConstant(fsys+[comma,rparent],lsp1,lval);
      if lsp = nil then Error(82)
      else if lsp^.form <> tagfld then
        Error(86)
      else if lsp^.tagfieldp <> nil then
	if CompTypes(lsp^.tagfieldp^.idtype,lsp1) then begin
	  lsp1 := lsp^.fstvar;
	  while lsp1 <> nil do
	    with lsp1^ do
	      if varval = lval.ival then begin
		lsp := subvar;
                goto 1;
		end {if}
	      else
                lsp1 := nxtvar;
	  lsp := nil;
	  end {if}
	else
          Error(44);
1:	end; {while}
    end {if}
  else if gattr.typtr^.form = objects then begin
    {dispose of an object}
    Load;
    if debug then
      GenL2t(pc_chk, 1, maxaddr, cgULong);
    Gen0t(pc_stk, cgULong);
    Gen1(pc_csp,17{dsp});
    end {else if}
  else
    Error(44);
end; {DoDispose}

procedure Abs;
{compile an absolute value function call}

begin {Abs}
if gattr.typtr <> nil then
  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
    Gen0(pc_abi)
  else if IsReal(gattr.typtr) then
    Gen0(pc_abr)
  else if gattr.typtr = longptr then
    Gen0(pc_abl)
  else begin
    Error(51);
    gattr.typtr := intptr;
    end;
end; {Abs}

procedure Sqr;
{compile a call to the square function}

begin {Sqr}
if gattr.typtr <> nil then
  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
    Gen0(pc_sqi)
  else if IsReal(gattr.typtr) then
    Gen0(pc_sqr)
  else if gattr.typtr = longptr then
    Gen0(pc_sql)
  else begin
    Error(51);
    gattr.typtr := intptr;
    end;
end; {Sqr}

procedure TruncRound;
{compile trunc and round calls}

begin {TruncRound}
if gattr.typtr <> nil then
  if not IsReal(gattr.typtr) then
    Error(51);
if lkey = 3{trunc} then begin
  Gen2(pc_cnv,ord(cgReal),ord(cgWord));
  gattr.typtr := intptr;
  end {if}
else if lkey = 42{trunc4} then begin
  Gen2(pc_cnv,ord(cgReal),ord(cgLong));
  gattr.typtr := longptr;
  end {else if}
else if lkey = 43{round4} then begin
  Gen0(pc_rn4);
  gattr.typtr := longptr;
  end {else if}
else begin
  Gen0(pc_rnd);
  gattr.typtr := intptr;
  end; {else}
end; {TruncRound}

procedure DoOdd;
{compile a call to the odd function}

begin {DoOdd}
if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
  Gen0(pc_odd)
else if gattr.typtr = longptr then
  Gen0(pc_odl)
else
  Error(51);
gattr.typtr := boolptr;
end; {DoOdd}

procedure DoOrd;
{compile the ord function}

begin {DoOrd}
if gattr.typtr <> nil then
  if gattr.typtr^.form > pointerStruct then
    Error(51)
  else if (gattr.typtr^.form = pointerStruct) or (gattr.typtr = longptr) then
    begin
    if iso then Error(112);
    Gen2(pc_cnv,ord(cgLong),ord(cgWord));
    end
  else if not (GetType(gattr.typtr, gattr.isPacked)
    in [cgByte,cgUByte,cgWord,cgUWord]) then
    Error(51);
gattr.typtr := intptr;
end; {DoOrd}

procedure DoOrd4;

{ compile the ord4 function					}

begin {DoOrd4}
if gattr.typtr <> nil then
   if gattr.typtr^.form > pointerStruct then
      Error(51)
   else if GetType(gattr.typtr, gattr.isPacked)
      in [cgByte,cgUByte,cgWord,cgUWord] then
      Gen2(pc_cnv,ord(cgWord),ord(cgLong))
   else if not (GetType(gattr.typtr, gattr.isPacked) in [cgLong,cgULong]) then
      Error(51);
gattr.typtr := longptr;
end; {DoOrd4}

procedure DoPointer;
{compile the Pointer function}

begin {DoPointer}
if gattr.typtr <> nil then
  if gattr.typtr^.form > pointerStruct then
    Error(51)
  else if (gattr.typtr^.form <> pointerStruct) and (gattr.typtr <> longptr)
    then
    Gen2(pc_cnv,ord(cgWord),ord(cgLong));
  {else the value is already 4 bytes}
gattr.typtr := nilptr;
end; {DoPointer}

procedure DoChr;
{compile a call to the chr function}

begin {DoChr}
if gattr.typtr <> nil then
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(51);
{gen0(59( chr ));}
gattr.typtr := charptr;
end; {DoChr}

procedure PredSucc;
{compile a call to pred or succ}

begin {PredSucc}
if gattr.typtr <> nil then
  if (gattr.typtr^.form <> scalar) or IsReal(gattr.typtr) then
    Error(51);
if lkey = 8{pred} then
  Gen1t(pc_dec, 1, GetType(gattr.typtr, gattr.isPacked))
else
  Gen1t(pc_inc, 1, GetType(gattr.typtr, gattr.isPacked));
CheckBnds(gattr.typtr);
end; {PredSucc}

procedure DoEOF (fsys: setofsys; fprocp: ctp);

{ compile a call to eof or eoln					}
{								}
{ Parameters:							}
{    fsys -							}
{    fprocp -							}

begin {DoEOF}
if sy = lparent then begin

   {handle a call for a given file}
   InSymbol;
   Variable(fsys + [rparent],fprocp);
   Match(rparent,4);
   if lkey = 11{eoln} then
      if gattr.typtr <> textptr then
         Error(44);
   if gattr.typtr <> nil then
      if gattr.typtr^.form <> files then
         Error(51);
   if glcp = inptr then
      if lkey=10{eof} then
	 Gen1tName(pc_ldo, 0, cgUWord, @'~EOFINPUT')
      else
	 Gen1tName(pc_ldo, 0, cgUWord, @'~EOLNINPUT')
   else begin
      Load;
      Gen0t(pc_stk, cgULong);
      Gen1t(pc_csp, 38+lkey{eof,eol}, cgUByte);
      end; {else}
   end {if}
else begin

   {handle a call for standard in}
   if noinput then
      Error(91);
   Gen0(pc_nop);
   Gen1t(pc_csp, 175+lkey{eof,eol}, cgUByte);
   end; {else}
gattr.typtr := boolptr;
end; {DoEOF}


procedure trans;
{compile transendental functions}

var
  tkey: keyrange;		      {so we can change the number}

begin {trans}
tkey := lkey;
if gattr.typtr <> nil then
  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then begin
    gen2(pc_cnv,ord(cgWord),ord(cgReal));
    gattr.typtr := realptr;
    end
  else if gattr.typtr = longptr then begin
    Gen2(pc_cnv,ord(cgLong),ord(cgReal));
    gattr.typtr := realptr;
    end;
if not IsReal(gattr.typtr) then
  Error(59);
case tkey of
   12: Gen0(pc_sin);
   13: Gen0(pc_cos);
   14: Gen0(pc_exp);
   15: Gen0(pc_sqt);
   16: Gen0(pc_log);
   17: Gen0(pc_atn);
   36: Gen0(pc_tan);
   37: Gen0(pc_acs);
   38: Gen0(pc_asn);
   otherwise:
     Error(113);
   end; {case}
end; {trans}

procedure DoArctan2(fsys: setofsys; fprocp: ctp);
{compile a call to Arctan2}

begin {DoArctan2}
Match(lparent,9);
Expression(fsys+[comma,rparent],fprocp);
Load;
if gattr.typtr <> nil then
  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then begin
    gen2(pc_cnv,ord(cgWord),ord(cgReal));
    gattr.typtr := realptr;
    end
  else if gattr.typtr = longptr then begin
    Gen2(pc_cnv,ord(cgLong),ord(cgReal));
    gattr.typtr := realptr;
    end;
if not IsReal(gattr.typtr) then
  Error(59);
Match(comma,20);
Expression(fsys+[rparent],fprocp);
Load;
if gattr.typtr <> nil then
  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then begin
    gen2(pc_cnv,ord(cgWord),ord(cgReal));
    gattr.typtr := realptr;
    end
  else if gattr.typtr = longptr then begin
    Gen2(pc_cnv,ord(cgLong),ord(cgReal));
    gattr.typtr := realptr;
    end;
if not IsReal(gattr.typtr) then
  Error(59);
Gen0(pc_at2);
end; {DoArctan2}

procedure DoUserID;
{compile a call to UserID}

begin {DoUserID}
Gen1tName(pc_ldo, 0, cgUWord, @'~USER_ID');
gattr.typtr := intptr;
end; {DoUserID}

procedure ToolError;
{compile a call to tollerror}

begin {ToolError}
Gen1tName(pc_ldo, 0, cgUWord, @'~TOOLERROR');
gattr.typtr := intptr;
end; {ToolError}

procedure Cnvfs(fsys: setofsys; fprocp: ctp);
{compile a call to Cnvrs or Cnvds}

begin {Cnvfs}
{load the value to convert}
Match(lparent,9);
Expression(fsys+[comma,rparent],fprocp);
Load;
if gattr.typtr <> nil then
  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then begin
    Gen2(pc_cnv,ord(cgWord),ord(cgReal));
    gattr.typtr := realptr;
    end
  else if (gattr.typtr = longptr) then begin
    Gen2(pc_cnv,ord(cgLong),ord(cgReal));
    gattr.typtr := realptr;
    end;
if not IsReal(gattr.typtr) then
  Error(59);
Gen0t(pc_stk, cgExtended);
{load the two required field widths}
Match(comma,20);
Expression(fsys+[comma,rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(44);
  end
else Error(44);
Match(comma,20);
Expression(fsys+[rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(44);
  end
else Error(44);
Gen1t(pc_csp,77{cfs},cgString);
gattr.typtr := stringptr;
gattr.kind := expr;
stringHeap := true;
end; {Cnvfs}

procedure Cnvis;
{compile a call to Cnvis}

begin {Cnvis}
if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
  Gen2(pc_cnv,ord(cgWord),ord(cgLong))
else if gattr.typtr <> longptr then Error(44);
Gen0t(pc_stk, cgULong);
Gen1t(pc_csp,78{cis},cgString);
gattr.typtr := stringptr;
gattr.kind := expr;
stringHeap := true;
end; {Cnvis}

procedure CnvSF(fsys: setofsys; fprocp: ctp);
{compile a call to CnvSR or CnvSD}

begin {Cnvsf}
Match(lparent,9);
Expression(fsys+[rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else Error(44)
else Error(44);
gattr.typtr := realptr;
Gen1t(pc_csp,79{csf},cgReal);
end; {Cnvsf}

procedure CnvSI(fsys: setofsys; fprocp: ctp);
{compile a call to CnvSI}

begin {Cnvsi}
Match(lparent,9);
Expression(fsys+[rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else Error(44)
else Error(44);
gattr.typtr := intptr;
Gen1t(pc_csp,80{csi},cgWord);
end; {Cnvsi}

procedure CnvSL(fsys: setofsys; fprocp: ctp);
{compile a call to CnvSL}

begin {Cnvsl}
Match(lparent,9);
Expression(fsys+[rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else Error(44)
else Error(44);
gattr.typtr := longptr;
Gen1t(pc_csp,81{csl},cgLong);
end; {Cnvsl}

procedure Randomf;
{generate a random real or double}

begin {Randomf}
Gen0(pc_nop);
gattr.typtr := realptr;
Gen1t(pc_csp,82{rnf},cgReal);
end; {Randomf}

procedure RandomInteger;
{generate a random integer}

begin {RandomInteger}
Gen0(pc_nop);
gattr.typtr := intptr;
Gen1t(pc_csp,83{rni},cgWord);
end; {RandomInteger}

procedure RandomLongInt;
{generate a random longint}

begin {RandomLongInt}
Gen0(pc_nop);
gattr.typtr := longptr;
Gen1t(pc_csp,83{rni},cgLong);
end; {RandomLongint}

procedure Concat(fsys: setofsys; fprocp: ctp);
{concatonate a series of strings}

var
  numStrings: integer;		      {# of strings to concatonate}
  stop: boolean; 		      {loop termination var}

begin {Concat}
stringHeap := true;
numStrings := 0;
{mark stack so parameters are tagged}
{load the strings}
Match(lparent,9);
repeat
  Expression(fsys+[comma,rparent],fprocp);
  if gattr.typtr <> nil then
    if IsString(gattr.typtr) then
      LoadStringAddress
    else if gattr.typtr = charptr then begin
      Load;
      Gen0t(pc_stk, cgUWord);
      GenLdcLong(-1);
      Gen0t(pc_stk, cgULong);
      Gen0t(pc_bno, cgULong);
      end
    else Error(44)
  else Error(44);
  stop := sy <> comma;
  if not stop then InSymbol;
  numStrings := numStrings+1;
  if numStrings <> 1 then
    Gen0t(pc_bno, cgULong);
until stop or eofl;
Match(rparent,4);
Gen1t(pc_ldc, numStrings, cgWord);
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
{call the concat function}
Gen1t(pc_csp,85{cat},cgString);
gattr.typtr := stringptr;
gattr.kind := expr;
end; {Concat}

procedure Copy(fsys: setofsys; fprocp: ctp);
{compile a call to copy characters from a string}

begin {Copy}
stringHeap := true;
{load the string to copy characters from}
Match(lparent,9);
Expression(fsys+[comma,rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else Error(44)
else Error(44);
{load the index}
Match(comma,20);
Expression(fsys+[comma,rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(44);
  end
else Error(44);
{load the number of chars to copy}
Match(comma,20);
Expression(fsys+[rparent],fprocp);
Load;
Gen0t(pc_stk, cgWord);
Gen0t(pc_bno, cgWord);
if gattr.typtr <> nil then begin
  if (gattr.typtr <> intptr) and (gattr.typtr <> byteptr) then Error(44);
  end
else Error(44);
{call the copy function}
Gen1t(pc_csp,86{cpy},cgString);
gattr.typtr := stringptr;
gattr.kind := expr;
end; {Copy}

procedure DoLength(fsys: setofsys; fprocp: ctp);
{compile a call to Length}

begin {DoLength}
{load the string}
Match(lparent,9);
Expression(fsys+[comma,rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else if gattr.typtr = charptr then begin
    Load;
    Gen0t(pc_stk, cgUWord);
    GenLdcLong(-1);
    Gen0t(pc_stk, cgULong);
    Gen0t(pc_bno, cgULong);
    end
  else Error(44)
else Error(44);
gattr.typtr := intptr;
Gen1t(pc_csp,87{lgt},cgWord);
end; {DoLength}

procedure Pos(fsys: setofsys; fprocp: ctp);
{compile a call to find the position of one string in another}

begin {Pos}
{load the strings}
Match(lparent,9);
Expression(fsys+[comma,rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else if gattr.typtr = charptr then begin
    Load;
    Gen0t(pc_stk, cgUWord);
    GenLdcLong(-1);
    Gen0t(pc_stk, cgULong);
    Gen0t(pc_bno, cgULong);
    end
  else Error(44)
else Error(44);
Match(comma,20);
Expression(fsys+[rparent],fprocp);
if gattr.typtr <> nil then
  if IsString(gattr.typtr) then
    LoadStringAddress
  else if gattr.typtr = charptr then begin
    Load;
    Gen0t(pc_stk, cgUWord);
    GenLdcLong(-1);
    Gen0t(pc_stk, cgULong);
    Gen0t(pc_bno, cgULong);
    end
  else Error(44)
else Error(44);
Gen0t(pc_bno, cgWord);
{call the pos function}
Gen1t(pc_csp,88{pos},cgWord);
gattr.typtr := intptr;
end; {Pos}


procedure DoMember (fsys: setofsys; fprocp: ctp);

{ Compile a call to the member function				}
{								}
{ paremeters:							}
{    fsys - follow symbols					}
{    fprocp - identifier for program or program-level		}
{       subroutine contining this statement			}

var
  lcp: ctp;				{work identifier}

begin {DoMember}
Match(lparent, 9);
Expression(fsys+[comma], fprocp);
Load;
Match(comma,20);
if sy = ident then begin
  SearchId([types], lcp);
  InSymbol;
  if lcp <> nil then
    if lcp^.idtype <> nil then
      if gattr.typtr <> nil then begin
	Gen0t(pc_stk, cgULong);
	if CompObjects(lcp^.idtype, gattr.typtr) then
	  Gen1t(pc_ldc, lcp^.idtype^.objlevel, cgUWord)
        else               
	  Gen1t(pc_ldc, 0, cgUWord);
	Gen0t(pc_stk, cgUWord);
	Gen0t(pc_bno, cgUWord);
        Gen1t(pc_csp, 117{mbr}, cgUWord);
        end; {if}
  end {if}
else
  Error(2);
gattr.typtr := boolptr;
end; {DoMember}

{-- Externally available subroutines ------------------------------------------}

procedure Call {fsys: setofsys; fcp,fprocp: ctp};

{ generate a call to a procedure or function			}
{								}
{ parameters:							}
{    fsys - follow symbols					}
{    fcp -							}
{    fprocp -							}

var
  tkey: keyrange;		      {for saving lkey on recursive fn calls}

begin {Call}
tkey := lkey;
if fcp^.pfdeckind = standard then begin
  lkey := fcp^.key;
  if fcp^.klass = proc then begin

    {compile standard procedure calls}
    if iso then
      if lkey in [3,4,12,16,18..29] then
        Error(112);
    if not(lkey in [7,8,13..15,28,29]) then
      Match(lparent,9);
    case lkey of
      1,2,4: getputclose(fsys,fprocp);
      3,5,6: resetrewriteopen(fsys,fprocp);
      7,13: DoRead(fsys,fprocp);
      8,14: DoWrite(fsys,fprocp);
      9:    DoPack(fsys,fprocp);
      10:   DoUnpack(fsys,fprocp);
      11:   DoNew(fsys,fprocp);
      17:   DoDispose(fsys,fprocp);
      15:   page(fsys,fprocp);
      19:   seek(fsys,fprocp);
      20,21: HaltSeed(fsys,fprocp);
      22:   Delete(fsys,fprocp);
      23:   Insert(fsys,fprocp);
      24,25: CommandLineShellID(fsys,fprocp);
      26,27: StartGraphDesk(fsys,fprocp);
      28,29: EndGraphDesk;
      end; {case}
    if not(lkey in [7,8,13..15,28,29]) then
      Match(rparent,4);
    end
  else begin

    {compile standard function calls}
    if iso then
      if lkey in [18..44] then
        Error(112);
    if not(lkey in [10,11,19,21..34,39..41,44]) then begin
      Match(lparent, 9);
      Expression(fsys+[rparent], fprocp);
      Load;
      end; {if}
    case lkey of
      1:     abs;
      2:     sqr;
      3,4,42,43: truncround;
      5:     DoOdd;
      6:     DoOrd;
      7:     DoChr;
      8,9:   predsucc;
      10,11: DoEOF(fsys,fprocp);
      12,13,14,15,16,17,36,37,38: trans;
      18:    DoOrd4;
      19,32: Cnvfs(fsys,fprocp);
      20:    Cnvis;
      21,33: Cnvsf(fsys,fprocp);
      22:    Cnvsi(fsys,fprocp);
      23:    Cnvsl(fsys,fprocp);
      24,31: Randomf;
      25:    RandomInteger;
      26:    RandomLongInt;
      27:    Concat(fsys,fprocp);
      28:    Copy(fsys,fprocp);
      29:    DoLength(fsys,fprocp);
      30:    Pos(fsys,fprocp);
      34:    DoUserID;
      35:    DoPointer;
      39:    DoArctan2(fsys,fprocp);
      40:    ToolError;
      41:    DoSizeof;
      44:    DoMember(fsys, fprocp);
      end;
    if not (lkey in [10,11,24..27,31,34,40]) then
      Match(rparent,4);
    end;
  end {else}
else
  CallNonStandard(fsys, fcp, fprocp, 0, cStandard);
lkey := tkey;
end; {Call}


procedure CallNonStandard {fsys: setofsys; fcp,fprocp: ctp; odisp: longint;
  callKind: callKinds};

{ Handle a call to a user defined procedure/function		}
{								}
{ parameters:							}
{    fsys -							}
{    fcp -							}
{    fprocp -							}
{    odisp - disp in object for method calls; else 0		}
{    callKind - type of this call				}

label 1,2,3;

var
  nxt,lcp: ctp;
  lattr: attr;				{for forming fake parm types}
  lsp: stp;
  i: integer;
  typeNum: baseTypeEnum;
  pcount: unsigned;			{number of parameters processed}


  procedure CheckParm (lcp1,lcp2: ctp);

  { insure that the parm list matches the definition		}
  {								}
  { parameters:							}
  {    lcp1, lcp2 - parameter lists to check			}

  label 1;

  begin {CheckParm}
  if lcp1 = nil then begin
    if lcp2 <> nil then Error(52);
    end
  else begin
    while lcp1 <> nil do begin
      if lcp2 = nil then begin Error(52); goto 1; end;
      if (lcp1^.idtype <> lcp2^.idtype) or (lcp1^.klass<>lcp2^.klass)
	then begin Error(59); goto 1; end
      else begin
	if lcp1^.klass = varsm then begin
	  if (lcp1^.vkind <> lcp2^.vkind) or
	    (lcp1^.vitem <> lcp2^.vitem) then
	    begin Error(59); goto 1; end
	  end
	else {lcp1^.klass = proc or func} begin
	  CheckParm(lcp1^.pfnext,lcp2^.pfnext);
	  if lcp1^.klass = func then
	    if lcp1^.idtype <> lcp2^.idtype then Error(53);
	  end;
	end;
      lcp1 := lcp1^.next;
      lcp2 := lcp2^.next;
      end;
    if lcp2 <> nil then begin Error(52); goto 1; end;
    end;
1:  end; {CheckParm}


begin {CallNonStandard}
{get the head of the parameter list; preload indirect call addresses}
with fcp^ do
  if pfkind = formal then begin
    nxt := pfnext;
    if callKind = cStandard then begin
      Gen3t(pc_lod, pflabel, 0, level-pflev, cgULong);
      Gen3t(pc_lod, pflabel, 4, level-pflev, cgUWord);
      Gen0t(pc_bno, cgUWord);
      end; {if}
    end {if}
  else begin
    nxt := pfparms;
    if callKind <> cStandard then
      nxt := nxt^.next; {skip SELF}
    end; {else}                       

{for methods, the 'SELF' parameter has already been pushed}
if callKind in [cMethod,cInherited] then
  pcount := 1
else
  pcount := 0;

{compile the call's parameter list}
if sy = lparent then begin
  repeat
    InSymbol;
    {check for too many parms}
    if nxt = nil then begin
      Error(52);
      goto 1;
      end;
    {handle procs and funcs in parm list}
    if nxt^.klass in [proc,func] then begin
      if sy <> ident then begin
	Error(2);
	Skip(fsys + [comma,rparent]);
	end
      else begin
	if nxt^.klass = proc then
          SearchId([proc],lcp)
	else begin
	  SearchId([func],lcp);
	  if lcp^.idtype <> nxt^.idtype then
            Error(53);
	  end; {else}
	if lcp <> nil then with lcp^ do begin
	  if pfkind = formal then begin
	    CheckParm(pfnext,nxt^.pfnext);
            Gen3t(pc_lod, pflabel, 4, level-pflev, cgUWord);
	    Gen0t(pc_stk, cgUWord);
	    if pcount <> 0 then
	      Gen0t(pc_bno, cgUWord);
	    pcount := pcount+1;
	    Gen3t(pc_lod, pflabel, 0, level-pflev, cgULong);
	    end {if}
	  else begin
	    CheckParm(pfparms, nxt^.pfnext);
            Gen1(pc_lsl, level-pflev);
	    Gen0t(pc_stk, cgUWord);
	    if pcount <> 0 then
	      Gen0t(pc_bno, cgUWord);
	    pcount := pcount+1;
	    if pflev = 1 then
	      Gen0Name(pc_lad,lcp^.name)
	    else
	      Gen1(pc_lla, pfname);
	    end;
	  Gen0t(pc_stk, cgULong);
	  end;
	InSymbol;
	if not (sy in fsys + [comma,rparent]) then begin
	  Error(6);
	  Skip(fsys + [comma,rparent]);
	  end;
	end;
      goto 2;
      end;
    {handle expressions in parm list}
    if sy = stringConst then
      if nxt <> nil then
	if nxt^.vkind = actual then
	  if IsString(nxt^.idtype) then begin
	    if StrLen(nxt^.idtype) < 0 then
	      LoadString(lengthString)
	    else
	      LoadString(nullString);
	    InSymbol;
	    goto 3;
	    end; {if}
1:  Expression(fsys + [comma,rparent],fprocp);
3:  if gattr.typtr <> nil then
      if nxt <> nil then begin
	lsp := nxt^.idtype;
	if lsp <> nil then begin
	  if (nxt^.vkind = actual) then begin
	    if lsp^.form <= power then begin
	      if gattr.typtr^.form <= power then
		Load
	      else
		LoadAddress;
	      CheckBnds(lsp);
	      if IsReal(lsp) then begin
		if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
		  begin
		  Gen2(pc_cnv,ord(cgWord),ord(cgExtended));
		  gattr.typtr := realptr;
		  end
		else if gattr.typtr = longptr then begin
		  Gen2(pc_cnv,ord(cgLong),ord(cgExtended));
		  gattr.typtr := realptr;
		  end;
		end
	      else if lsp = longptr then begin
		if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
		  begin
		  Gen2(pc_cnv, ord(cgWord), ord(cgLong));
		  gattr.typtr := longptr;
		  end;
                end {else if}
              else if nxt^.vuniv then
                if ParmSize(lsp, actual) = 4 then
                  if ParmSize(gattr.typtr, actual) = 2 then begin
		    Gen2(pc_cnv, ord(cgWord), ord(cgLong));
		    gattr.typtr := longptr;
                    end; {if}
              case GetType(gattr.typtr, gattr.isPacked) of
		cgByte,cgUByte,cgWord,cgUWord:
		  Gen0t(pc_stk, cgWord);
                cgLong,cgULong,cgString:
		  Gen0t(pc_stk, cgLong);
		cgReal,cgDouble,cgComp,cgExtended:
		  Gen0t(pc_stk, cgExtended);
                cgSet:
		  Gen1(pc_siz, ord(lsp^.size));
		otherwise: ;
		end; {case}
	      end
	    else if gattr.typtr^.form = objects then begin
	      Load;
	      if debug then
		GenL2t(pc_chk, 1, maxaddr, cgULong);
	      Gen0t(pc_stk, cgULong);
              end {else if}
	    else if gattr.typtr^.form = records then begin
	      {value records <= 4 bytes passed by value; otherwise    }
	      { pass an address					      }
	      if gattr.typtr^.size <= 4 then
		if gattr.typtr^.size <= 2 then begin
		  lattr := gattr;
		  gattr.typtr := intptr;
		  Load;
		  Gen0t(pc_stk, cgWord);
		  gattr := lattr;
		  end {if}
		else begin
		  lattr := gattr;
		  gattr.typtr := longptr;
		  Load;
		  Gen0t(pc_stk, cgLong);
		  gattr := lattr;
		  end {else}
	      else begin
		LoadAddress;
		Gen0t(pc_stk, cgULong);
		end;
	      end {else if}
            else if IsString(lsp) then begin
              if gattr.kind = expr then begin
	        LoadAddress;
	        Gen0t(pc_stk, cgULong);
                if StrLen(lsp) < 0 then
                  Gen1t(pc_csp, 119{fxp}, cgULong)
                else
                  Gen1t(pc_csp, 120{fxc}, cgULong);
                end {if}
              else
	        LoadAddress;
	      Gen0t(pc_stk, cgULong);
	      end {else if}
	    else begin
	      LoadAddress;
	      Gen0t(pc_stk, cgULong);
	      end; {else}
	    if not CompTypes(lsp,gattr.typtr) then
	      if (ParmSize(lsp,actual) <> ParmSize(gattr.typtr,actual)) then
		Error(67);
	    end
	  else begin
	    if lsp <> gattr.typtr then
	      if not nxt^.vuniv then
		Error(67);
	    if gattr.kind = varbl then begin
	      LoadAddress;
	      Gen0t(pc_stk, cgULong);
	      end {if}
	    else
	      Error(78);
	    if glcp <> nil then with glcp^ do begin
	      if klass = varsm then begin
		if vcontvar then Error(97);
		if vlev <> level then vrestrict := true;
		end
	      else if klass = field then
		if fldvar then Error(95);
	      end;
	    if gispacked then Error(95);
	    end;
	  end
	end;
2:  {next parm in definition}
    if nxt <> nil then
      nxt := nxt^.next;
    if pcount <> 0 then
      Gen0t(pc_bno, cgWord);
    pcount := pcount+1;
  until sy <> comma;
  Match(rparent,4);
  end; {if}
if pcount = 0 then
  Gen0(pc_nop);

{check for not enough parameters}
if nxt <> nil then
  Error(52);

{generate the call}
with fcp^ do begin
  if klass <> func then
    typeNum := cgVoid
  else begin
    if idtype = realptr then
      typeNum := cgReal
    else if idtype = doubleptr then
      typeNum := cgDouble
    else if idtype = compptr then
      typeNum := cgComp
    else if idtype = extendedptr then
      typeNum := cgExtended
    else if idtype = longptr then
      typeNum := cgLong
    else if idtype^.form = pointerStruct then
      typeNum := cgULong
    else
      typeNum := cgWord;
    end; {else}
  if callKind = cMethod then
    GenL1t(pc_cum, odisp, typeNum)
  else if pfkind = formal then
    Gen0t(pc_cui, typeNum)
  else {if pfkind = actual then}
    case pfdirective of
      drnone,drforw,drextern: {standard calls}
	if pflev = 1 then
	  Gen1tName(pc_cup, level-pflev, typeNum, fcp^.pfoname)
	else
	  Gen2t(pc_cup, pfname, level-pflev, typeNum);
      drprodos: {in line prodos call}
	Gen1(pc_pds, pfcallnum);
      drtool1,drtool2,drvector: begin {in line tool call with passed parms}
	if pfdirective = drtool1 then
	   Gen2t(pc_tl1, pftoolnum, pfcallnum, typeNum)
	else if pfdirective = drtool2 then
	   Gen2t(pc_tl2, pftoolnum, pfcallnum, typeNum)
	else
           Gen1L1t(pc_vct, pfcallnum, pfaddr, typeNum);
	if klass = func then
	  if idtype = boolptr then begin
	    Gen1t(pc_ldc, 0, cgWord);
	    Gen0t(pc_neq, cgWord);
	    end; {if}
	end;
      end; {case}
  end;
{for functions, set the return type}
gattr.typtr := fcp^.idtype
end; {CallNonStandard}


procedure CheckBool;
{load a value, insuring that it is boolean}

begin {CheckBool}
load;
if gattr.typtr <> nil then
  if gattr.typtr <> boolptr then Error(60);
end; {CheckBool}

procedure CheckBnds{fsp: stp};
{generate range checking code (if needed)}

var
  lmin,lmax: integer;

begin {CheckBnds}
if debug then
  if fsp <> nil then
    if fsp = charptr then
      Gen2t(pc_chk, ordminchar, ordmaxchar, cgUWord)
    else if fsp^.form = subrange then
      if fsp^.rangetype = longptr then
        GenL2t(pc_chk, fsp^.min, fsp^.max, cgULong)
      else
        Gen2t(pc_chk, long(fsp^.min).lsw, long(fsp^.max).lsw, cgUWord);
end; {CheckBnds}


procedure FreeTemp{labelNum, size: integer};

{ place a temporary label in the available label list		}
{								}
{ parameters:							}
{    labelNum - number of the label to free			}
{    size - size of the variable 				}
{								}
{ variables:							}
{    tempList - list of free labels				}

var
   tl: tempPtr;				{work pointer}

begin {FreeTemp}
new(tl);
tl^.next := tempList;
tl^.last := nil;
tl^.labelNum := labelNum;
tl^.size := size;
if tempList <> nil then
   tempList^.last := tl;
tempList := tl;
end; {FreeTemp}


function GetTemp{size: integer): integer};

{ find a temporary work variable 				}
{								}
{ parameters:							}
{    size - size of the variable 				}
{								}
{ variables:							}
{    tempList - list of free labels				}
{								}
{ Returns the label number.					}

label 1;

var
   ln: integer;				{label number}
   tl: tempPtr;				{work pointer}

begin {GetTemp}
{try to find a temp from the existing list}
tl := tempList;
while tl <> nil do begin
   if tl^.size = size then begin

      {found an old one - use it}
      if tl^.last = nil then
	 tempList := tl^.next
      else
	 tl^.last^.next := tl^.next;
      if tl^.next <> nil then
	 tl^.next^.last := tl^.last;
      GetTemp := tl^.labelNum;
      goto 1;
      end; {if}
   tl := tl^.next;
   end; {while}

{none found - get a new one}
ln := GetLocalLabel;
GetTemp := ln;
Gen2(dc_loc, ln, size);
1:
end; {GetTemp}


procedure Load;
{load a value onto the evaluation stack}

var
  lmt: addrrange;			{temp disp}
  ltype: stp;				{base type}

begin {Load}
with gattr do
  if typtr <> nil then begin
    ltype := typtr;
    if ltype^.form = subrange then
      ltype := ltype^.rangetype;
    case kind of
      cst:   if (ltype^.form = scalar) and (not IsReal(ltype)) then
	       if ltype = boolptr then
		 Gen1t(pc_ldc, cval.ival, cgUWord)
	       else if ltype=charptr then
		 Gen1t(pc_ldc, cval.ival, cgUWord)
	       else if ltype = longptr then
		 GenLdcLong(cval.valp^.lval)
	       else if cval.ival >= 0 then
		 Gen1t(pc_ldc, cval.ival, cgUWord)
               else
		 Gen1t(pc_ldc, cval.ival, cgWord)
	     else if ltype = nilptr then
	       GenLdcLong(0)
	     else if IsReal(ltype) then
	       GenLdcReal(cval.valp^.rval)
	     else
	       GenLdcSet(cval.valp^);
      varbl: begin
	     if access = drct then
	       if dpdisp > maxint then begin
		 lmt := dpdisp;
		 if vlevel <= 1 then
		   Gen1Name(pc_lao, 0, aname)
		 else
		   Gen3(pc_lda, gattr.dplab, 0, 0);
		 access := indrct;
		 idplmt := lmt;
		 end; {if}
	     case access of
	       drct:   if ltype^.form = power then begin
			 if vlevel<=1 then
			   Gen2tName(pc_ldo, long(dpdisp).lsw, ord(typtr^.size),
			     cgSet, aname)
			 else
			   Gen4t(pc_lod, gattr.dplab, long(dpdisp).lsw,
                             level-vlevel, ord(typtr^.size), cgSet);
			 end {if}
		       else begin
			 if vlevel<=1 then
			   Gen1tName(pc_ldo, long(dpdisp).lsw,
                             GetType(typtr, isPacked), aname)
			 else
			   Gen3t(pc_lod, gattr.dplab, long(dpdisp).lsw,
                             level-vlevel, GetType(typtr, isPacked));
			 end; {else}
	       indrct: begin
		       if idplmt >= maxint then begin
			 GenLdcLong(idplmt);
			 Gen0(pc_adl);
			 idplmt := 0;
			 end; {if}
		       if ltype^.form = power then
			 Gen2t(pc_ind, ord(idplmt), ord(typtr^.size), cgSet)
		       else
			 Gen1t(pc_ind, ord(idplmt), GetType(typtr, isPacked));
		       end;
	       inxd:   Error(113)
	       end; {case}
             end;
      otherwise:
      end;
    typtr := ltype;
    kind := expr;
    end;
end; {Load}

procedure LoadAddress;
{load the address of a variable onto the top of the stack}

var
  lmt: addrrange;			{temp disp}

begin {LoadAddress}
with gattr do
  if typtr <> nil then begin
    if typtr^.form = subrange then
      typtr := typtr^.rangetype;
    case kind of
      cst:   if IsString(typtr) then
	       GenPS(pc_lca, @cval.valp^.sval)
	     else
	       Error(113);
      varbl: begin
	     if access = drct then
	       if dpdisp > maxint then begin
		 lmt := dpdisp;
		 if vlevel <= 1 then
		   Gen1Name(pc_lao, 0, aname)
		 else
		   Gen3(pc_lda, gattr.dplab, 0, 0);
		 access := indrct;
		 idplmt := lmt;
		 end; {if}
	     case access of
	       drct:   if vlevel <= 1 then
			 Gen1Name(pc_lao, long(dpdisp).lsw, aname)
		       else
			 Gen3(pc_lda, dplab, level-vlevel, long(dpdisp).lsw);
	       indrct: begin
		       if idplmt >= maxint then begin
			 GenLdcLong(idplmt);
			 Gen0(pc_adl);
			 end {if}
		       else
			 Gen1t(pc_inc,ord(idplmt),cgULong);
		       end;
	       inxd:   Error(113)
	       end; {case}
	     end;
      expr:  if typtr <> stringPtr then Error(113);
      end;
    kind := varbl;
    access := indrct;
    idplmt := 0;
    end
end; {LoadAddress}

procedure LoadStringAddress;
{load the address and length of a string}

var
  lattr: attr;

begin {LoadStringAddress}
lattr := gattr;
LoadAddress;
Gen0t(pc_stk, cgULong);
if lattr.kind <> expr then begin
  Gen1t(pc_ldc, StrLen(gattr.typtr), cgUWord);
  Gen0t(pc_stk, cgUWord);
  Gen0t(pc_bno, cgUWord);
  end; {if}
end; {LoadStringAddress}

procedure LoadString {kind: stringKind};

{ load the address of a string constant				}
{								}
{ parameters:							}
{    kind - string kind						}

var
   i: unsigned;				{loop variable}
   len: unsigned;			{length of the string}
   tch: char;				{temp for building string from char}

begin {LoadString}
if lgth = 1 then begin			{if the length is 1, make a string   }
   tch := chr(val.ival); 		{ from a character		     }
   val.valp := pointer(Malloc(sizeof(constantRec)));
   with val.valp^ do begin
      cclass := strg;
      sval[0] := chr(1);
      sval[1] := tch;
      end; {with}
   end; {if}
with val.valp^ do begin
   if lgth = 0 then begin		{for a nul string, use two zeros}
      sval[0] := chr(2);
      sval[1] := chr(0);
      sval[2] := chr(0);
      end {if}
   else if kind = lengthString then begin {add the length byte}
      len := length(sval);
      for i := len downto 1 do
	 sval[i+1] := sval[i];
      sval[1] := sval[0];
      sval[0] := chr(len+2);
      end {else}
   else					{bump the length for the null terminator}
      sval[0] := succ(sval[0]);
   sval[ord(sval[0])] := chr(0);	{place a trailing nul on the string}
   gattr.cval := val;			{set up for the load}
   gattr.typtr := stringptr;
   gattr.kind := cst;
   gattr.isPacked := false;
   end; {with}
end; {LoadString}


function ParmSize {lsp: stp; vkind: idkind): integer};

{ find the length of a parameter				}
{								}
{ parameters:							}
{    lsp -							}
{    vkind -							}
{								}
{ Returns: stack size of parameter, in bytes			}

begin {ParmSize}
ParmSize := ptrsize;
if lsp <> nil then
  with lsp^ do
    if vkind = actual then
      if form <= power then begin
	ParmSize := ord(size);
	if IsReal(lsp) then
	  ParmSize := extSize
	else if lsp = byteptr then
	  ParmSize := intSize;
	end {if}
      else if form = records then
	if size <= 2 then
	  ParmSize := 2;
end; {ParmSize}


procedure ResetTemp;

{ forget all of the temporary work variables			}

var
   tl: tempPtr;				{work pointer}

begin {ResetTemp}
while tempList <> nil do begin
  tl := tempList;
  tempList := tl^.next;
  dispose(tl);
  end; {while}
end; {ResetTemp}


procedure Store{var fattr: attr};
{store the value on top of stack}

var
  lmt: addrrange;			{temp disp}

begin {Store}
with fattr do
  if typtr <> nil then begin
    case access of
      drct:   if typtr^.form = power then begin
		if vlevel <= 1 then
		  Gen2tName(pc_sro, long(dpdisp).lsw, ord(typtr^.size), cgSet,
		    aname)
		else
		  Gen4t(pc_str, dplab, long(dpdisp).lsw, level-vlevel,
		    ord(typtr^.size), cgSet);
		end
	      else begin
		if vlevel <= 1 then
		  Gen1tName(pc_sro, long(dpdisp).lsw, GetType(typtr, isPacked),
                    aname)
		else
		  Gen3t(pc_str, dplab, long(dpdisp).lsw, level-vlevel,
		    GetType(typtr, isPacked));
		end;
      indrct: begin
	      if typtr^.form = power then
		Gen1t(pc_sto, ord(typtr^.size), cgSet)
	      else
		Gen0t(pc_sto, GetType(typtr, isPacked));
	      end;
      inxd:   Error(113)
      end; {case}
    end; {if}
end; {Store}

end.
