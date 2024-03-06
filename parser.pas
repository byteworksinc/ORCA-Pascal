{$optimize 7}
{------------------------------------------------------------}
{							     }
{  ORCA/Pascal 2					     }
{							     }
{  A native code compiler for the Apple IIGS.		     }
{							     }
{  By Mike Westerfield					     }
{							     }
{  Copyright March 1988					     }
{  By the Byte Works, Inc.				     }
{							     }
{------------------------------------------------------------}
 
unit parser;

interface

{$segment 'pascal'}

{$LibPrefix '0/obj/'}

uses PCommon, Scanner, CGI, Symbols, Call;

var
					{structured constants:}
					{---------------------}
  blockbegsys: setofsys;		{symbols that can start a block}
  statbegsys: setofsys;

{------------------------------------------------------------}

procedure DoConstant (fsys: setofsys; var fsp: stp; var fvalu: valu);

{ compile a constant term					}
{								}
{ parameters:							}
{    fsys - following symbols					}
{    fsp - (output) constant type				}
{    fvalu - (output) constant value				}

procedure Expression(fsys: setofsys; fprocp: ctp);
{compile an expression}

procedure InitScalars;                  
{Initialize global scalars}

procedure InitSets;
{initialize structured set constants}

  procedure Selector (fsys: setofsys; fcp,fprocp: ctp; var isMethod: boolean);

  { handle indexing arrays, field selection, dereferencing of	}
  { pointers, windowing files					}
  {								}
  { parameters:							}
  {    fsys -							}
  {    fcp -							}
  {    fprocp - identifier for program or program-level		}
  {       subroutine contining this statement			}
  {    isMethod - (returned) Did the selection resolve to a	}
  {       method call?  If so, take no further action.		}

procedure Programme(fsys:setofsys);
{Compile a program}

{------------------------------------------------------------}

implementation

const
  digmax      =	   255;			{maxcnt-1}
  workspace   =	    16;			{# bytes of work space on stack frame}

{-------------------------------------------------------------------------}
 
type
					{case statement}
					{--------------}
  cip = ^caseinfo;
  caseinfo = packed record
    next: cip;
    csstart: unsigned;
    cslab: integer;
    end;

var
					{counters:}
					{---------}
 
  lastline: integer;			{last line seen by gen}
  firstlab: integer;			{value for intlabel at start of segment}

 
					{switches:}
					{---------}
 
  inseg: boolean;			{tells if a segment is active}
  inUses: boolean;			{tells if a uses is being compiled}
  doingCast: boolean;			{casting a type?}
 
					{pointers:}
					{---------}
  fextfilep: extfilep;			{head of chain for external files}
  thisType: pStringPtr;			{pointer to name of current type}
 
 
					{msc}
					{---}

  namFound: boolean;			{has nam been found? {i.e., should line
					 #'s be generated?}

                                        {objects}
                                        {-------}
  isMethod: boolean;			{are we compiling a method?}
  objectcp: ctp;			{last procedure or function identifier}
  objectName: pString;			{object name (for methods)}
  objectType: stp;			{type of method's object}
  objptr: ctp;                          {linked list of objects}

					{structured constants:}
					{---------------------}
 
  constbegsys,simptypebegsys,typebegsys,selectsys,facbegsys,
  typedels: setofsys;
  inputid,outputid,erroroutputid: pString; {commonly compared identifiers}

{----Parser and Semantic Analysis-----------------------------------------}

procedure DoConstant {fsys: setofsys; var fsp: stp; var fvalu: valu};

{ compile a constant term					}
{								}
{ parameters:							}
{    fsys - following symbols					}
{    fsp - (output) constant type				}
{    fvalu - (output) constant value				}

var
  lsp: stp;
  lcp: ctp;
  sign: (none,pos,neg);
  lvp: csp;

begin {DoConstant}
lsp := nil;
fvalu.ival := 0;
if not(sy in constbegsys) then begin
  Error(22);
  Skip(fsys+constbegsys)
  end; {if}
if sy in constbegsys then begin
  if sy = stringconst then begin
    if (sy = addop) and (op in [plus,minus]) then begin
      Error(34);
      InSymbol;
      end; {if}
    if lgth = 1 then
      lsp := charptr
    else begin
      lsp := pointer(Malloc(sizeof(structure)));
      with lsp^ do begin
	aeltype := charptr;
	inxtype := nil;
	ispacked := pkpacked;
	hasSFile := false;
	size := lgth*packedcharsize;
	form := arrays;
	end; {with}
      end; {else}
    fvalu := val;
    InSymbol;
    end
  else begin
    sign := none;
    if (sy = addop) and (op in [plus,minus]) then begin
      if op = plus then sign := pos else sign := neg;
      InSymbol;
      end; {if}
    if sy = ident then begin
      searchid([konst],lcp);
      if lcp <> nil then
	with lcp^ do begin
	  lsp := idtype;
	  fvalu := values;
	  end {with}
      else begin
	fvalu.ival := 0;
	lsp := intptr;
	end; {else}
      if sign = neg then
	if (lsp = intptr) or (lsp = byteptr) then
	  fvalu.ival := -fvalu.ival
	else if lsp = longptr then begin
          lvp := pointer(Malloc(constantRec_longC));
          lvp^.cclass := longC;
	  lvp^.lval := -fvalu.valp^.lval;
	  fvalu.valp := lvp;
	  end {else if}
	else if IsReal(lsp) then begin
          lvp := pointer(Malloc(constantRec_reel));
          lvp^.cclass := reel;
	  lvp^.rval := -fvalu.valp^.rval;
	  fvalu.valp := lvp;
	  end; {else if}
      if sign <> none then
	if (lsp <> intptr) and (not IsReal(lsp)) and
	  (lsp <> byteptr) and (lsp <> longptr) then
	  Error(34);
      InSymbol;
      end {if}
    else if sy = intconst then begin
      if sign = neg then
        val.ival := -val.ival;
      lsp := intptr;
      fvalu := val;
      InSymbol;
      end {else if}
    else if sy = realconst then begin
      if sign = neg then
        val.valp^.rval := -val.valp^.rval;
      lsp := realptr;
      fvalu := val;
      InSymbol;
      end {else if}
    else if sy = longintconst then begin
      if sign = neg then
        val.valp^.lval := -val.valp^.lval;
      lsp := longptr;
      fvalu := val;
      InSymbol;
      end {else if}
    else begin
      Error(35);
      Skip(fsys);
      end {else if}
    end; {else}
  if not (sy in fsys) then begin
    Error(6);
    Skip(fsys);
    end; {if}
  end; {if}
fsp := lsp;
end; {DoConstant}


  procedure CheckUses(var id: pString; sym: symbol);
  {make sure this name has not been used from another level}

  label 1;

  var
    p: lptr;				{work pointer for traversing list}
    lcp: ctp;				{work pointer for checking fwd ptrs}

  begin {CheckUses}
  p := display[top].labsused;
  while p <> nil do begin
    if CompNames(p^.name^,id) = 0 then begin
      Error(18);
      goto 1;
      end;
    p := p^.next;
    end;
  if sym <> typesy then begin
    lcp := fwptr;
    while lcp <> nil do begin
      if CompNames(lcp^.name^,id) = 0 then begin
	Error(18);
	goto 1;
	end;
      lcp := lcp^.next;
      end;
    end;
  1:
  end; {CheckUses}

  procedure ExportUses;
  {uses from more than one level back are exported to the previous level}

  label 1;

  var
    p,q,r: lPtr; 			{for moveing used id list up}

  begin {ExportUses}
  p := display[top].labsused;		{check all labels in curent list}
  while p <> nil do begin
    if p^.disx < top-1 then begin	{if they are from more than one level  }
      q := display[top-1].labsused;	{ back, they must be in the last list  }
      while q <> nil do begin		{skip if the label is already in the   }
	if q^.name = p^.name then	{ last list			       }
	  goto 1;
	q := q^.next;
	end; {while}
      new(r);				{insert in the last list}
      r^.next := display[top-1].labsused;
      display[top-1].labsused := r;
      r^.name := p^.name;
      r^.disx := p^.disx;
      end; {if}
    p := p^.next;
    end; {while}
  1:
  end; {ExportUses}


  procedure ProcDeclaration (fsy: symbol; fsys: setofsys;
    isObject, compilebody: boolean; var foundbody: boolean); forward;

  { Procedure/function declaration				}


  procedure Typ (fsys: setofsys; var fsp: stp; var fsize: addrrange;
    isType: boolean);

  { compile a type definition					}
  {								}
  { parameters:							}
  {    fsys - follow symbols					}
  {    fsp -							}
  {    fsize -							}
  {    isType - is this the root level of a type declaration?	}

  var
    lsp,lsp1,lsp2: stp;
    oldtop: disprange;			{display level on entry}
    ttop: disprange;			{temp display level}
    lcp, lcp2: ctp;
    lsize,disp1: addrrange;
    lmin,lmax: longint;
    ispacked: packedkinds;
    test: boolean;
    lvalu: valu;
    len: integer;			{string length}
    l1,l2,l3: longint;			{used to compute array size}
    lval: record 			{used to convert between types}
      case boolean of
	true : (long: longint);
	false: (lsw: integer; msw: integer);
      end;


    procedure Duplicate (var ncp: ctp; ocp: ctp);

    { Duplicate a field list					}
    {								}
    { parameters:						}
    {    ncp - (output) new (copied) identifier			}
    {    ocp - identifier to copy				}

    begin {Duplicate}
    if ocp <> nil then begin
      ncp := pointer(Malloc(sizeof(identifier)));
      ncp^ := ocp^;
      Duplicate(ncp^.llink, ocp^.llink);
      Duplicate(ncp^.rlink, ocp^.rlink);
      end; {if}
    end; {Duplicate}


    procedure SimpleType (fsys:setofsys; var fsp:stp; var fsize:addrrange);

    { Compile a simple type					}
    {								}
    { parameters:						}
    {    fsys -							}
    {    fsp -							}
    {    fsize -						}

    var
      lsp,lsp1: stp;
      lcp,lcp1: ctp;
      ttop: disprange;
      lcnt: integer;
      lvalu: valu;
      len: integer;			{string length}

    begin {SimpleType}
    fsize := 1;
    if not (sy in simptypebegsys) then begin
      Error(1);
      Skip(fsys + simptypebegsys);
      end; {if}
    if sy in simptypebegsys then begin

      {enumerations}
      if sy = lparent then begin
	ttop := top;   {decl. consts local to innermost block}
	while display[top].occur <> blck do
          top := top - 1;
        lsp := pointer(Malloc(sizeof(structure)));
	with lsp^ do begin
	  size := intsize;
	  form := scalar;
	  hasSFile := false;
	  scalkind := declared;
	  end; {with}
	lcp1 := nil;
	lcnt := 0;
	repeat
	  InSymbol;
	  if sy = ident then begin
            lcp := pointer(Malloc(sizeof(identifier)));
	    with lcp^ do begin
	      len := ord(id[0])+2;
              name := pointer(Malloc(len));
	      CopyString(name^,id,len);
	      idtype := lsp;
	      next := lcp1;
	      values.ival := lcnt;
	      klass := konst;
	      hasIFile := idtype^.hasSFile;
	      end;
	    CheckUses(lcp^.name^,constsy);
	    EnterId(lcp);
	    lcnt := lcnt + 1;
	    lcp1 := lcp; InSymbol
	    end
	  else Error(2);
	  if not (sy in fsys + [comma,rparent]) then begin
	    Error(6);
	    Skip(fsys + [comma,rparent]);
	    end;
	until sy <> comma;
	lsp^.fconst := lcp1;
	top := ttop;
	Match(rparent,4);
	end

      {named types, subranges}
      else begin
	if sy = ident then begin
	  SearchID([types,konst],lcp);
	  if lcp^.name = thisType then
            Error(10);
	  InSymbol;
	  if lcp^.klass = konst then begin
            lsp := pointer(Malloc(sizeof(structure)));
	    with lsp^, lcp^ do begin
	      rangetype := idtype;
	      form := subrange;
	      hasSFile := false;
              if rangetype = longptr then begin
	        min := values.valp^.lval;
	        size := longsize;
                end {if}
              else begin
	        min := values.ival;
	        size := intsize;
                end; {else}
	      end;
	    Match(dotdot,83);
	    DoConstant(fsys,lsp1,lvalu);
            if lsp1 = longptr then
	      lsp^.max := lvalu.valp^.lval
            else
	      lsp^.max := lvalu.ival;
	    if lsp^.rangetype <> lsp1 then
              if (lsp^.rangetype = intptr) and (lsp1 = longptr) then begin
        	lsp^.rangetype := longptr;
                lsp^.size := longsize;
                end {if}
              else if (lsp^.rangetype <> longptr) or (lsp1 <> intptr) then
        	Error(36);
	    end
	  else begin
	    lsp := lcp^.idtype;
	    if lsp <> nil then fsize := lsp^.size;
	    if iso then
	      if (lsp = longptr) or (lsp = byteptr) then Error(112);
	    end
	  end {sy = ident}
	else begin
          lsp := pointer(Malloc(sizeof(structure)));
	  DoConstant(fsys + [dotdot],lsp1,lvalu);
	  with lsp^ do begin
	    form := subrange;
	    hasSFile := false;
	    rangetype:=lsp1;
            if rangetype = longptr then begin
	      min := lvalu.valp^.lval;
	      size := longsize;
              end {if}
            else begin
	      min := lvalu.ival;
	      size := intsize;
              end; {else}
	    end;
	  Match(dotdot,83);
	  DoConstant(fsys,lsp1,lvalu);
          if lsp1 = longptr then
	    lsp^.max := lvalu.valp^.lval
          else
	    lsp^.max := lvalu.ival;
	  if lsp^.rangetype <> lsp1 then
            if (lsp^.rangetype = intptr) and (lsp1 = longptr) then begin
              lsp^.rangetype := longptr;
              lsp^.size := longsize;
              end {if}
            else if (lsp^.rangetype <> longptr) or (lsp1 <> intptr) then
              Error(36);
	  end;
	if lsp <> nil then
	  with lsp^ do
	    if form = subrange then
	      if rangetype <> nil then
		if IsReal(rangetype) or IsString(rangetype) then
                  Error(73)
		else if min > max then
                  Error(31)
	end;
      fsp := lsp;
      if not (sy in fsys) then begin
        Error(6);
        Skip(fsys)
        end; {if}
      end
    else fsp := nil
    end; {SimpleType}


    procedure FieldList (fsys: setofsys; var frecvar: stp; var hasFile: boolean;
      isObject: boolean);

    { compile a field list					}
    {								}
    { parameters:						}
    {    fsys - following symbols				}
    {    frecvar -						}
    {    hasFile -						}
    {    isObject - is this an object? (or a record)		}

    label 1;

    var
      lcp,lcp1,nxt,nxt1,inst: ctp;
      lsp,lsp1,lsp2,lsp3,lsp4: stp;
      minsize,maxsize,lsize: addrrange;
      lvalu: valu;
      numcase: longint;
      max,min: longint;
      tHasFile: boolean; 		{tracks files in the field list}
      len: integer;			{length of a string}
      hasId: boolean;			{does the case have an attached id?}

    begin {FieldList}
    lsp := nil;
    hasFile := false;
    if not (sy in fsys+[ident,casesy]) then begin
      Error(19);
      Skip(fsys + [ident,casesy]);
      end;
    while sy = ident do begin
      nxt := nil;
      nxt1 := nil;
      repeat
	if sy = ident then begin
          lcp := pointer(Malloc(sizeof(identifier)));
	  with lcp^ do begin
	    len := ord(id[0])+2;
            name := pointer(Malloc(len));
	    CopyString(name^,id,len);
	    idtype := nil;
	    next := nil;
	    klass := field;
	    fldvar := false;
	    hasIFile := false;
	    end;
	  if nxt1 <> nil then
            nxt1^.next := lcp;
	  nxt1 := lcp;
	  if nxt = nil then
            nxt := lcp;
	  EnterId(lcp);
	  InSymbol;
	  end
	else Error(2);
	if not (sy in [comma,colon]) then begin
          Error(6);
          Skip(fsys + [comma,colon,semicolon,casesy])
	  end; {if}
	test := sy <> comma;
	if not test then InSymbol;
      until test;
      Match(colon,5);
      Typ(fsys + [casesy,semicolon], lsp, lsize, false);
      hasFile := hasFile or lsp^.hasSFile;
      while nxt <> nil do
	with nxt^ do begin
	  idtype := lsp;
	  fldaddr := disp1;
	  nxt := next;
	  disp1 := disp1 + lsize;
	  end;
      while sy = semicolon do begin
	InSymbol;
	if not (sy in fsys + [ident,casesy,semicolon]) then begin
	  Error(19);
	  Skip(fsys + [ident,casesy]);
	  end;
	end;
      end; {while sy = ident}
    if sy = casesy then begin
      if isObject then
        Error(123);
      hasId := false;
      lsp := pointer(Malloc(sizeof(structure)));
      with lsp^ do begin
	tagfieldp := nil;
	fstvar := nil;
	form := tagfld;
	hasSFile := false;
	end;
      frecvar := lsp;
      InSymbol;
      if sy = ident then begin
        lcp := pointer(Malloc(sizeof(identifier)));
	with lcp^ do begin
	  len := ord(id[0])+2;
          name := pointer(Malloc(len));
	  CopyString(name^,id,len);
	  idtype := nil;
	  klass:=field;
	  next := nil;
	  fldaddr := disp1;
	  fldvar := true;
	  hasIFile := false;
	  end;
	InSymbol;
	if sy = colon then begin
	  InSymbol;
	  hasId := true;
	  if sy <> ident then begin
	    Error(2);
	    Skip(fsys + [ofsy,lparent]);
	    goto 1;
	    end; {if sy <> ident}
	  EnterId(lcp);
	  end
	else begin
	  id := lcp^.name^;
	  if sy <> ofsy then Error(8);
	  end;
	SearchID([types], lcp1);
	lsp1 := lcp1^.idtype;
	if lsp1 <> nil then begin
	  lcp^.fldaddr := disp1;
	  if hasId then
	    disp1 := disp1+lsp1^.size;
	  if lsp1^.form <= subrange then begin
	    if IsReal(lsp1) then
              Error(39)
	    else if (lsp1 = intptr) or (lsp1 = longptr) then begin
	      Error(111);
	      numcase := maxint;
	      end
	    else begin
	      GetBounds(lsp1,min,max);
	      if (max >= 0) and (min <= 0) then
		if max < (maxint+min) then
		  numcase := max-min+1
		else begin
		  Error(111);
		  numcase := maxint;
		  end
	      else
		numcase := max-min+1
	      end;
	    lcp^.idtype := lsp1;
	    lsp^.tagfieldp := lcp;
	    end
	  else
            Error(39);
	  end;
	if sy = ident then InSymbol;
	end
      else begin
	Error(2);
	Skip(fsys + [ofsy,lparent]);
	end;
1:    lsp^.size := disp1;
      Match(ofsy,8);
      lsp1 := nil;
      minsize := disp1;
      maxsize := disp1;
      repeat
	lsp2 := nil;
	if not (sy in fsys + [semicolon]) then begin
	  repeat
	    DoConstant(fsys + [comma,colon,lparent],lsp3,lvalu);
	    if lsp^.tagfieldp <> nil then
	      if not CompTypes(lsp^.tagfieldp^.idtype,lsp3) then
		Error(40);
            lsp3 := pointer(Malloc(sizeof(structure)));
	    numcase := numcase-1;
	    with lsp3^ do begin
	      nxtvar := lsp1;
	      subvar := lsp2;
	      varval := lvalu.ival;
	      form := variant;
	      hasSFile := false;
	      end;
	    lsp4 := lsp1;
	    while lsp4 <> nil do
	      with lsp4^ do begin
		if varval = lvalu.ival then Error(94);
		lsp4 := nxtvar;
		end;
	    lsp1 := lsp3;
	    lsp2 := lsp3;
	    test := sy <> comma;
	    if not test then InSymbol;
	  until test;
	  Match(colon,5);
	  Match(lparent,9);
	  FieldList(fsys + [rparent, semicolon], lsp2, tHasFile, false);
	  hasFile := hasFile or tHasFile;
	  if disp1 > maxsize then maxsize := disp1;
	  while lsp3 <> nil do begin
	    lsp4 := lsp3^.subvar;
	    lsp3^.subvar := lsp2;
	    lsp3^.size := disp1;
	    lsp3 := lsp4;
	    end;
	  Match(rparent,4);
	  if not (sy in fsys + [semicolon]) then begin
	    Error(6);
	    Skip(fsys + [semicolon]);
	    end;
	  end;
	test := sy <> semicolon;
	if not test then begin
	  disp1 := minsize;
	  InSymbol;
	  end;
      until test;
      if numcase <> 0 then Error(98);
      disp1 := maxsize;
      lsp^.fstvar := lsp1;
      frecVar^.hasSFile := hasFile;
      end
    else
      frecvar := nil;
    end; {FieldList}


    procedure ProcList (fsys: setofsys);

    { compile a field list					}
    {								}
    { parameters:						}
    {    fsys - following symbols				}

    var
      foundBody: boolean;		{dummy var for ProcDeclaration}
      lsy: symbol; 			{for recording type of subroutine}

    begin {ProcList}
    {make sure the initial symbol is valid}
    if not (sy in fsys+[procsy,funcsy]) then begin
      Error(19);
      Skip(fsys + [procsy,funcsy]);
      end; {if}

    {process all procedures and functions}
    while sy in [procsy,funcsy] do begin
      nextLocalLabel := 1;
      lsy := sy;
      InSymbol;
      nextLocalLabel := 1;
      ProcDeclaration(lsy, fsys+[procsy,funcsy], true, true, foundbody);
      if objectcp^.pfdirective = droverride then
        objectcp^.pfdirective := drforw
      else begin
        objectcp^.pfaddr := disp1;
        disp1 := disp1 + ptrsize;
        end; {else}
      while sy = semicolon do begin
	InSymbol;
	if not (sy in fsys + [procsy,funcsy,semicolon]) then begin
	  Error(19);
	  Skip(fsys + [procsy,funcsy]);
	  end; {if}
	end; {while}
      end; {while}
    end; {ProcList}


  begin {Typ}
  if not (sy in typebegsys) then begin
    Error(10);
    Skip(fsys+typebegsys);
    end;
  if sy in typebegsys then begin
    if sy in simptypebegsys then
      SimpleType(fsys,fsp,fsize)
{^} else if sy = arrow then begin
      lsp := pointer(Malloc(sizeof(structure)));
      fsp := lsp;
      with lsp^ do begin
	eltype := nil;
	size := ptrsize;
	form := pointerStruct;
	hasSFile := false;
	end; {with}
      InSymbol;
      if sy = ident then begin
	SearchSection(display[top].fname,lcp);
	if lcp <> nil then
          if lcp^.klass <> types then
            lcp := nil;
	if lcp = nil then begin
          {forward reference type id}
          lcp := pointer(Malloc(sizeof(identifier)));
	  with lcp^ do begin
	    len := ord(id[0])+2;
            name := pointer(Malloc(len));
	    CopyString(name^,id,len);
	    idtype := lsp;
	    next := fwptr;
	    klass := types;
	    hasIFile := lsp^.hasSFile;
	    end; {with}
	  fwptr := lcp;
	  end {if}
	else
	  with lcp^,lsp^ do begin
	    if {lcp^.}idtype <> nil then begin
	      {lsp^.}eltype := {lcp^.}idtype;
	      {lsp^.}hasSFile := {lcp^.}hasIFile;
	      end; {if}
	    if {lcp^.}name = thisType then
              Error(10);
	    end; {with}
	InSymbol;
	end {if}
      else Error(2);
      end {else if}
    else begin
      if sy = packedsy then begin
	InSymbol;
	ispacked := pkpacked;
	if not (sy in (typedels + [objectsy])) then begin
	  Error(10);
	  Skip(fsys + (typedels + [objectsy]));
	  end {if}
	end {if}
      else ispacked := pkunpacked;
{array}
      if sy = arraysy then begin
	InSymbol;
	Match(lbrack,11);
	lsp1 := nil;
	repeat
          lsp := pointer(Malloc(sizeof(structure)));
	  with lsp^ do begin
	    aeltype := lsp1;
	    inxtype := nil;
	    form := arrays;
	    hasSFile := lsp1^.hasSFile;
	    end;
	  lsp^.ispacked := ispacked;
	  lsp1 := lsp;
	  SimpleType(fsys + [comma,rbrack,ofsy],lsp2,lsize);
	  lsp1^.size := lsize;
	  if lsp2 <> nil then
	    if lsp2^.form <= subrange then begin
	      if IsReal(lsp2) then begin
		Error(38);
		lsp2 := nil;
		end
	      else if lsp2 = longptr then begin
		Error(74);
		lsp2 := nil;
		end; {else if}
	      lsp^.inxtype := lsp2
	      end {if}
	    else begin
	      Error(41);
	      lsp2 := nil;
	      end; {else}
	  test := sy <> comma;
	  if test then Match(rbrack,12) else InSymbol;
	until test;
	Match(ofsy,8);
	Typ(fsys, lsp, lsize, false);
	if lsp1^.ispacked = pkpacked then
	  if CompTypes(lsp,charptr) or CompTypes(lsp,boolptr) then
	    lsize := packedcharsize;
	repeat
	  with lsp1^ do begin
	    lsp2 := aeltype;
	    aeltype := lsp;
	    hasSFile := lsp^.hasSFile;
	    if inxtype <> nil then begin
	      GetBounds(inxtype,lmin,lmax);
              lsize := (lmax-lmin+1)*lsize;
	      size := lsize;
	      end; {if}
	    end; {with}
	  lsp := lsp1; lsp1 := lsp2;
	until lsp1 = nil;
        if lsize > $010000 then
          if SmallMemoryModel then
            Error(122);
	end
{stringsy}
      else if sy = stringsy then begin
	InSymbol;
	lmin := 80; {default string length is 80}
	if sy = lbrack then begin
	  InSymbol;
	  DoConstant(fsys+[rbrack],lsp1,lvalu);
	  if lsp1 = intptr then
	    lmin := lvalu.ival
	  else
	    Error(15);
	  Match(rbrack,12);
	  end;
        lsp1 := pointer(Malloc(sizeof(structure)));
	with lsp1^ do begin
	  size := 2;
	  form := subrange;
	  hasSFile := false;
	  rangetype := intptr;
	  min := 0;
	  if lmin > 255 then
	    min := 1;
	  max := lmin;
	  end;
        lsp := pointer(Malloc(sizeof(structure)));
	with lsp^ do begin
	  aeltype := charptr;
	  inxtype := lsp1;
	  form := arrays;
	  hasSFile := false;
	  size := (lmin-lsp1^.min+1)*packedcharsize;
	  ispacked := pkpacked;
	  end;
	end
{record}
      else if sy = recordsy then begin
	InSymbol;
	oldtop := top;
	if top < displimit then begin
	  top := top+1;
	  with display[top] do begin
	    fname := nil;
	    flabel := nil;
	    labsused := nil;
	    occur := rec;
	    end
	  end
	else
          Error(107);
	disp1 := 0;
        lsp := pointer(Malloc(sizeof(structure)));
	FieldList(fsys-[semicolon]+[endsy], lsp1, lsp^.hasSFile, false);
        if disp1 > $010000 then
          if SmallMemoryModel then
            Error(122);
	with lsp^ do begin
	  fstfld := display[top].fname;
	  recvar := lsp1;
	  size := disp1;
	  form := records;
	  end; {with}
	lsp^.ispacked := ispacked;
	ExportUses;
	top := oldtop;
	Match(endsy,13);
	end
{object}
      else if sy = objectsy then begin
	InSymbol;

        {make sure we are declaring a type}
        if not isType then
          Error(127);

        { check for previous foward declaration }
        lsp := nil;
        lcp := objptr;
        while (lcp <> nil) and (CompNames(objectName, lcp^.name^) <> 0)
	  do lcp := lcp^.next;

        if lcp <> nil then lsp := lcp^.idtype;
        if (sy <> semicolon) and (lsp <> nil) and (lsp^.objdef) then lsp := nil;

        if lsp = nil then begin
          {set up the type}
          lsp := pointer(Malloc(sizeof(structure)));
            with lsp^ do begin
	    form := objects;
            objname := nil;
            objsize := 6;
            objlevel := 1;
            objparent := nil;
            objdef := true;
	    size := ptrsize;
            hasSFile := false;
      	    end; {with}
        end;

	{ handle forward declaration }
        if sy = semicolon then begin
            { if lcp is defined, then we're already inserted, nothing to do}
            if lcp = nil then begin
              lsp^.objdef := false;
              objectcp^.idtype := lsp;
              EnterId(objectcp);
              objectcp^.next := objptr;
   	      objptr := objectcp;
           end;       
        end else begin
          
          {set up a new display}
	  oldtop := top;
	  if top < displimit then begin
	    top := top+1;
	    with display[top] do begin
	      fname := nil;
	      flabel := nil;
	      labsused := nil;
	      occur := rec;
	      end
	    end
	  else
            Error(107);
	  disp1 := 6;
 	

          {handle inheritance}
          if sy = lparent then begin
            InSymbol;
            if sy = ident then begin
              SearchId([types], lcp2);
              if lcp2 <> nil then begin
                if lcp2^.idtype <> nil then
                  if (lcp2^.idtype^.form = objects) and (lcp2^.idtype^.objdef)
                  then begin
                    Duplicate(display[top].fname, lcp2^.idtype^.objfld);
                    disp1 := lcp2^.idtype^.objsize;
                    lsp^.objparent := lcp2^.idtype;
                    lsp^.objlevel := lcp2^.idtype^.objlevel + 1;
                    end {if}
                  else
                    Error(129);
                end {if}
              else
                Error(33);
              InSymbol;
              end {if}
            else
              Error(128);
            Match(rparent,4);
            end; {if}

          {compile the fields and methods}
          if sy in typebegsys then
       	    FieldList(fsys-[semicolon]+[endsy,procsy,funcsy], lsp1,
              lsp^.hasSFile, true);
          objectType := lsp;
          if lsp^.objdef then begin
            ttop := top;
            top := oldtop;
            objectcp^.idtype := lsp;
            EnterId(objectcp);
            objectcp^.next := objptr;
   	    objptr := objectcp;
            top := ttop;
          end;
          lsp^.objdef := true;

          ProcList(fsys-[semicolon]+[endsy]);
          if disp1 > $010000 then
            if SmallMemoryModel then
              Error(122);
   	  lsp^.objfld := display[top].fname;
          lsp^.objsize := disp1;

	  lsp^.ispacked := ispacked;
	  ExportUses;
	  top := oldtop;
  	  Match(endsy,13);
        end; {if not forward declaration}
      end {else if}
{set} else if sy = setsy then begin
	InSymbol;
	Match(ofsy,8);
	SimpleType(fsys,lsp1,lsize);
	if lsp1 <> nil then
	  if lsp1^.form > subrange then begin
	    Error(43);
	    lsp1 := nil;
	    end
	  else if IsReal(lsp1) then begin
	    Error(42);
	    lsp1 := nil;
	    end
	  else if (lsp1 = intptr) or (lsp1 = longptr) then begin
	    Error(90);
	    lsp1 := nil;
	    end
	  else begin
	    GetBounds(lsp1,lmin,lmax);
	    if (lmin < setlow) or (lmax > sethigh) then
              Error(90);
	    lmax := lmax div 8 + 1;
            if lmax = 1 then
               lmax := 2
            else if lmax = 3 then
               lmax := 4;
	    end;
        lsp := pointer(Malloc(sizeof(structure)));
	with lsp^ do begin
	  elset := lsp1;
	  size := lmax;
	  form := power;
	  hasSFile := false;
	  end;
	lsp^.ispacked := ispacked;
	end
{file} else if sy = filesy then begin
	InSymbol;
	Match(ofsy,8);
	Typ(fsys, lsp1, lsize, false);
	if lsp1^.hasSFile then Error(117);
	fsize := lsize;
	if (lsp1 = charptr) or (lsp1 = boolptr) then
	  fsize := packedcharsize;
        lsp := pointer(Malloc(sizeof(structure)));
	with lsp^ do begin
	  size := ptrsize;
	  form := files;
	  hasSFile := true;
	  filtype := lsp1;
	  filsize := lsize;
	  end;
	lsp^.ispacked := ispacked;
	end;
      fsp := lsp
      end;
    if not (sy in fsys) then begin
      Error(6);
      Skip(fsys)
      end; {if}
    end
  else
    fsp := nil;
  if fsp = nil then
    fsize := 1
  else
    fsize := fsp^.size;
  end {Typ} ;

  procedure labeldeclaration(fsys: setofsys);
  {Declare a user-defined label}

  var
    llp: lbp;
    redef: boolean;
    i: integer;
    test: boolean;

  begin {labeldeclaration}
  repeat
    if sy = intconst then
      with display[top] do begin
	llp := flabel; redef := false;
	while (llp <> nil) and not redef do
	  if llp^.labval <> val.ival then llp := llp^.nextlab
	  else begin redef := true; Error(88); end;
	if not redef then begin
          llp := pointer(Malloc(sizeof(labl)));
	  with llp^ do begin
	    labval := val.ival; labname := GenLabel;
	    if top = 1 then firstlab := labname+1;
	    defined := false; nextlab := flabel;
	    lstlevel := 0;
	    end;
	  if (val.ival < 0) or (val.ival > 9999) then Error(105);
	  flabel := llp
	  end;
	InSymbol;
	end
    else Error(15);
    if not ( sy in fsys + [comma, semicolon] ) then begin
      Error(6);
      Skip(fsys+[comma,semicolon])
      end;
    test := sy <> comma;
    if not test then InSymbol
  until test;
  Match(semicolon,14);
  end; {labeldeclaration}

  procedure ConstDeclaration(fsys: setofsys);
  {compile a constant}

  var
    lcp: ctp;
    lsp: stp;
    lvalu: valu;
    len: integer;			{string length}

  begin {ConstDeclaration}
  if sy <> ident then begin
    Error(2);
    Skip(fsys + [ident]);
    end;
  while sy = ident do begin
    lcp := pointer(Malloc(sizeof(identifier)));
    with lcp^ do begin
      len := ord(id[0])+2;
      name := pointer(Malloc(len));
      CopyString(name^,id,len);
      idtype := nil;
      next := nil;
      klass:=konst;
      hasIFile := false;
      end;
    InSymbol;
    if (sy = relop) and (op = eqop) then
      InSymbol
    else
      Error(16);
    DoConstant(fsys + [semicolon],lsp,lvalu);
    EnterId(lcp);
    with lcp^ do begin
      CheckUses({lcp^.}name^,constsy);
      {lcp^.}idtype := lsp;
      {lcp^.}values := lvalu;
      end;
    Match(semicolon,14);
    if not (sy in fsys+[ident,implementationsy]) then begin
      Error(6);
      Skip(fsys + [ident,implementationsy]);
      end;
    end;
  end; {ConstDeclaration}

  procedure FwPtrCheck;
  {Check all forward declared pointers to be sure they are resolved}

  var
    lcp: ctp;

  begin {FwPtrCheck}
  while fwptr <> nil do begin
    id := fwptr^.name^;
    prterr := false;
    SearchId([types],lcp);
    prterr := true;
    if lcp = nil then begin
      write('**** The pointer ',id,' cannot be resolved');
      FlagError;
      end
    else if lcp^.idtype <> nil then
      with fwptr^.idtype^, lcp^ do begin
	eltype := idtype;
	hasSFile := hasIFile;
	end;
    fwptr := fwptr^.next;
    end;
  end; {FwPtrCheck}

  procedure TypeDeclaration (fsys: setofsys);

  { compile a type declaration					}
  {								}
  { parameters:							}
  {   fsys -							}

  var
    lcp: ctp;
    lsp: stp;
    lsize: addrrange;
    len: integer;			{string length}

  begin {TypeDeclaration}
  if sy <> ident then begin		{check for a bogus start}
    Error(2);
    Skip(fsys + [ident]);
    end; {if}
  while sy = ident do begin		{scan all declarations}
					{process the identifier}
    lcp := pointer(Malloc(sizeof(identifier)));
    with lcp^ do begin
      len := ord(id[0])+2;
      name := pointer(Malloc(len));
      CopyString(name^,id,len);
      thisType := name;
      klass := types;
      end; {with}
    InSymbol;
					{check for '='}
    if (sy = relop) and (op = eqop) then
      InSymbol
    else
      Error(16);
    objectName := lcp^.name^;
    objectcp := lcp;
    Typ(fsys+[semicolon], lsp, lsize, true); {get the type}
    if lsp^.form = objects then
      lsp^.objname := lcp^.name;
    thisType := nil;
    if lsp^.form <> objects then	{enter in symbol table}
      EnterId(lcp);
    with lcp^ do begin
      {lcp^.}idtype := lsp;
      {lcp^.}hasIFile := lsp^.hasSFile;
      CheckUses({lcp^.}name^,typesy);
      end; {with}
    Match(semicolon,14);		{get ready for another one}
    if not (sy in fsys + [ident,implementationsy]) then begin
      Error(6);
      Skip(fsys + [ident,implementationsy]);
      end; {if}
    end; {while}
  FwPtrCheck;				{make sure forward declarations were resolved}
  end; {TypeDeclaration}

  procedure VarDeclaration(fsys: setofsys);
  {declare variables}

  var
    isExtern: boolean;			{is this an external variable declaration?}
    lcp,nxt: ctp;
    lsp: stp;
    lsize: addrrange;
    test: boolean;
    len: integer;			{string length}

  begin {VarDeclaration}
  nxt := nil;
  repeat {loops over type part}
    repeat {loops over all variable names}
      if sy = ident then begin
	{declare a new variable}
        lcp := pointer(Malloc(sizeof(identifier)));
	with lcp^ do begin
          len := ord(id[0])+2;
          name := pointer(Malloc(len));
	  CopyString(name^,id,len);
	  next := nxt;
	  klass := varsm;
	  vcontvar := false;
	  vrestrict := false;
	  idtype := nil;
	  vkind := actual;
	  vlev := level;
	  fromUses := inUses;
	  vPrivate := doingUnit and (not doingInterface);
	  end;
	EnterId(lcp);
	nxt := lcp;
	InSymbol;
	end
      else Error(2);
      if not (sy in fsys + [comma,colon] + typedels) then begin
	Error(6); Skip(fsys+[comma,colon,semicolon]+typedels)
	end;
      test := sy <> comma;
      if not test then InSymbol;
    until test;
    Match(colon,5);

    {see if the variable is extern}
    isExtern := false;
    if not iso then
      if sy = ident then
        if (id = 'EXTERN') or (id = 'EXTERNAL') then begin
          InSymbol;
          isExtern := true;
          end; {if}
    {get the type for the variable list}
    Typ(fsys + [semicolon] + typedels, lsp, lsize, false);
    FwPtrCheck;
    {loop over the variable list, filling in type based info}
    while nxt <> nil do
      with nxt^ do begin
	CheckUses(name^,varsy);
	idtype := lsp;
	fromUses := fromUses or isExtern;
	hasIFile := lsp^.hasSFile;
	if level <> 1 then
	  vlabel := GetLocalLabel;
	nxt := next;
	end;
    Match(semicolon,14);
    if not (sy in fsys + [ident,implementationsy]) then begin
      Error(6);
      Skip(fsys + [ident,implementationsy]);
      end;
  until (sy <> ident) and not (sy in typedels);
  end; {VarDeclaration}
 

  procedure DoBlock (fsys: setofsys; fsy: symbol; fprocp: ctp;
     isProgram: boolean); forward;
  {compile a block}


  procedure ProcDeclaration {fsy: symbol; fsys: setofsys;
    isObject, compilebody: boolean; var foundbody: boolean};

  { Procedure/function declaration				}
  {								}
  { parameters:							}
  {   fsy - procedure or function symbol			}
  {   fsys - follow symbols					}
  {   isObject - is this declaration in an object?		}
  {   compilebody - Compile the body? (used for partial compile)}
  {   foundbody - Was the body found (used for partial compile)	}

  var
    forw: boolean;
    i: integer;
    lcp,lcp1,lcp2: ctp;
    len: integer;			{string length}
    lisMethod: boolean;			{copy of isMethod}
    lpsize: integer;			{for saving psize (nested declarations)}
    lsp, lsp1: stp;
    lvalu: valu;			{constant from a directive}
    needSemicolon: boolean;		{for parsing interface files}
    oldlev: 0..maxlevel;
    oldtop: disprange;
    override: boolean;			{true if override is the only legal possibility}


    procedure ParameterList (ssy: setofsys; var fpar: ctp;
      forw,dummy: boolean);

    { Compile the parameter list				}
    {								}
    { parameters:						}
    {    ssy -							}
    {    fpar - list of parameter symbols			}
    {    forw -							}
    {    dummy -						}

    var
      list,lcp,lcp1: ctp;
      lsp: stp; lkind: idkind;
      lsize: unsigned;
      item: integer;
      test: boolean;
      len: integer;			{string length}
      universal: boolean;		{is the parm universal?}


      procedure FunProcParm (forp: idclass; var lcp: ctp; fsys: setofsys);

      { Compile a procedure or function parameter		}
      {								}
      { parameters:						}
      {    forp - function or procedure symbol			}
      {    lcp -						}
      {    fsys -						}

      var
	lpsize: integer;		{for saving psize}
	len: integer;			{string length}

      begin {FunProcParm}
      InSymbol;
      if sy = ident then begin

        {create a symbol table entry}
        lcp := pointer(Malloc(sizeof(identifier)));
	with lcp^ do begin
          len := ord(id[0])+2;
          name := pointer(Malloc(len));
	  CopyString(name^,id,len);
	  hasIFile := false;
	  idtype := nil;
	  pflev := level;
	  klass := forp;
	  pfdeckind := declared;
	  psize := psize+procsize;
	  pflabel := GetLocalLabel;
          pfparms := nil;
	  pfkind := formal;
	  pfnext := nil;
	  next := nil;
	  end; {with}
	if not dummy then
          EnterId(lcp);
	InSymbol;

	item := item+1;
	if list <> nil then
          list^.next := lcp;
	list := lcp;
	if fpar = nil then
          fpar := list;
	lpsize := psize;
	with lcp^ do
	  if forp = proc then begin
	    if not (sy in [semicolon,rparent]) then
	      ParameterList([semicolon,rparent], pfnext, false, true);
	    end
	  else if sy <> colon then
	    ParameterList([colon], pfnext, false, true);
	psize := lpsize;
	end {if}
      else
	Error(2);
      end; {FunProcParm}


    begin {ParameterList}
    list := nil;
    fpar := nil;
    item := 1;
    if isObject or (sy = lparent) then
      psize := 0; {define parameters as offsets from 0}

    {declare the 'self' parameter for methods}
    if isObject then begin
      lcp := pointer(Malloc(sizeof(identifier)));
      with lcp^ do begin
	name := @'SELF';
	idtype := objectType;
	next := nil;
	hasIFile := false;
	klass := varsm;
	vkind := actual;
	vlev := level;
	vitem := item;
	vlabel := GetLocalLabel;
	vcontvar := false;
	fromUses := false;
	vrestrict := false;
	vUniv := false;
	vPrivate := true;
	end; {with}
      EnterId(lcp);
      list := lcp;
      fpar := list;
      psize := {psize +} ptrsize;
      item := 2 {item+1};
      end; {if}

    {handle standard parameters}
    if not (sy in ssy+[lparent]) then begin
      Error(7);
      Skip(fsys+ssy+[lparent])
      end; {if}
    if sy = lparent then begin
      if forw or override then
        Error(45);
      InSymbol;
      if not (sy in [ident,varsy,funcsy,procsy]) then begin
	Error(7);
	Skip(fsys+[ident,rparent]);
	end; {if}
      while sy in [ident,varsy,funcsy,procsy] do begin
	if sy = procsy then begin
	  FunProcParm(proc, lcp, fsys+[comma,semicolon,rparent]);
	  lcp^.idtype := nilptr;
	  end {if}
	else if sy = funcsy then begin
	  FunProcParm(func, lcp, fsys+[comma,semicolon,rparent,colon]);
	  Match(colon,5);
	  if sy = ident then begin
	    SearchId([types],lcp1);
	    lsp := lcp1^.idtype;
	    if lsp <> nil then
	      if not (lsp^.form in [scalar,subrange,pointerStruct,objects])
                then begin
		Error(46);
		lsp := nil;
		end; {if}
	    lcp^.idtype := lsp;
	    InSymbol;
	    end
	  else Error(2);
	  end {else if}

        {'normal' parameter}
	else begin			

          {handle var declarations}
	  if sy = varsy then begin
	    lkind := formal;
	    InSymbol;
	    end
	  else
	    lkind := actual;

	  {process the list of names}
	  lcp1 := nil;
	  repeat
	    if sy = ident then begin
              lcp := pointer(Malloc(sizeof(identifier)));
	      with lcp^ do begin
                len := ord(id[0])+2;
                name := pointer(Malloc(len));
		CopyString(name^,id,len);
		idtype := nil;
		klass := varsm;
		vkind := lkind;
		next := nil;
		vlev := level;
		vcontvar := false;
		vrestrict := false;
		vitem := item;
		fromUses := inUses;
		end; {with}
	      if not dummy then
                EnterId(lcp);
	      if list <> nil then
                list^.next := lcp;
	      list := lcp;
	      if fpar = nil then
                fpar := list;
	      if lcp1 = nil then
                lcp1 := list;
	      InSymbol;
	      end {if}
	    else
              Error(2);
	    if not (sy in [comma,colon]+fsys) then begin
	      Error(7);
	      Skip(fsys+[comma,semicolon,rparent]);
	      end;
	    test := sy <> comma;
	    if not test then InSymbol;
	  until test;
	  Match(colon,5);

	  {see if the symbol is universal}
	  if sy = univsy then begin
	    if iso then
              Error(112);
	    universal := true;
	    InSymbol;
	    end {if}
	  else
	    universal := false;

	  {process the parameter type}
	  if sy = ident then begin

	    {find and check the type}
	    SearchId([types],lcp);
	    lsp := lcp^.idtype;
	    if lsp <> nil then
	      if lkind = actual then
		if lsp^.form = files then
                  Error(47);

	    {record the type size}
	    lsize := ParmSize(lsp,lkind);

	    {scan the variables, adding type info}
	    while lcp1 <> nil do begin
	      with lcp1^ do begin
		idtype := lsp;
                psize := psize+lsize;
		vlabel := GetLocalLabel;
		vuniv := universal;
		hasIFile := false;
		end; {with}

	      {allocate local space for value parms passed as pointers}
	      if lsp <> nil then
		if (lkind = actual) and (lsp^.form > power) then
		  if (lsp^.form <> records) or (lsp^.size > 4) then
		    lcp1^.vlabel := GetLocalLabel;
	      lcp1 := lcp1^.next;
	      end; {while}
	    InSymbol;
	    end {if}
	  else
            Error(2);
	  item := item+1;
	  end; {else}

	if not (sy in fsys+[semicolon,rparent]) then begin
	  Error(7);
	  Skip(fsys+[ident,rparent]);
	  end; {if}
	if sy = semicolon then begin
	  InSymbol;
	  if not (sy in fsys+[ident,varsy,procsy,funcsy]) then begin
	    Error(7);
	    Skip(fsys+[ident,rparent]);
	    end; {if}
	  end; {if}
	end; {while}
      Match(rparent,4);
      if not (sy in ssy+fsys) then begin
	Error(6);
	Skip(ssy+fsys);
	end; {if}
      end; {if}
    display[top].labsused := nil;
    end; {ParameterList}                


  begin {ProcDeclaration}
  lpsize := psize;
  psize := 0;
  forw := false;

  {see if this is the object name for a method}
  override := false;
  isMethod := false;
  if sy = ident then begin
    prterr := false;
    SearchID([types], lcp);
    prterr := true;
    if lcp <> nil then
      if lcp^.idtype <> nil then
	if lcp^.idtype^.form = objects then begin
          isMethod := true;
          lisMethod := true;
          objectName := id;
          InSymbol;
	  Match(period, 21);
          end; {if}
    end; {if}

  if sy = ident then begin
    {check for forward declarations}
    if isMethod then begin
      if level <> 1 then
        Error(126);
      if lcp^.idtype = nil then
        lcp := nil
      else
        SearchSection(lcp^.idtype^.objfld, lcp);
      if lcp = nil then
        Error(124)
      else
        if lcp^.pfdirective = drnone then
          Error(30);
      end {if}
    else
      SearchSection(display[top].fname, lcp);
    if lcp <> nil then
      with lcp^ do begin
        if isObject then
          override := true
	else if klass = proc then
	  forw := ((pfdirective=drforw) or isMethod)
            and (fsy=procsy) and (pfkind=actual)
	else if klass = func then
	  forw:= ((pfdirective=drforw) or isMethod)
            and (fsy=funcsy) and (pfkind=actual)
	else
          forw := false;
	if not (forw or override) then
          Error(84);
	end; {with}

    {if not forward, create a new identifier}
    if override then begin

      {override an ancestor method}
      lcp^.pfoname := pointer(Malloc(length(objectName)+length(lcp^.name^)+2));
      lcp^.pfoname^ := concat(objectName, '~', lcp^.name^);
      objectcp := lcp;

      {change the 'SELF' parameter type}
      lcp2 := pointer(Malloc(sizeof(identifier)));
      lcp2^ := lcp^.pfparms^;
      lcp^.pfparms := lcp2;
      lcp2^.idtype := objectType;
      end {if}
    else if not forw then begin
      lcp := pointer(Malloc(sizeof(identifier)));
      with lcp^ do begin
        len := ord(id[0])+2;
        name := pointer(Malloc(len));
	CopyString(name^,id,len);
	idtype := nilptr;
	pflev := level;
	pfname := GenLabel;
        if isObject then begin
          pfoname := pointer(Malloc(length(objectName)+length(name^)+2));
          pfoname^ := concat(objectName, '~', name^);
          end {if}
        else
          pfoname := name;
	pfparms := nil;
	pfdeckind := declared;
	pfkind := actual;
	pfPrivate := doingUnit and (not doingInterface);
	if fsy = procsy then
          klass := proc
        else
          klass := func;
	hasIFile := false;
	end; {if}
      CheckUses(lcp^.name^, procsy);
      EnterId(lcp);
      objectcp := lcp;
      end {if}
    else begin
      {forward - reset location counter}
      psize := lcp^.pfactualsize;

      {reset label counter}
      lcp1 := lcp^.pfparms;
      while lcp1 <> nil do begin
        if lcp1^.klass = varsm then begin
          if lcp1^.vlabel >= nextLocalLabel then
            nextLocalLabel := lcp1^.vlabel + 1;
          end {if}
        else if lcp1^.klass in [proc,func] then
          if lcp1^.pflabel >= nextLocalLabel then
            nextLocalLabel := lcp1^.pflabel + 1;
        lcp1 := lcp1^.next;
        end; {while}
      end; {else}
    InSymbol;

    {check for unexpected method}
    if sy = period then begin
      Error(125);
      InSymbol;
      if sy = ident then
        InSymbol;
      end; {if}
    end {if}
  else begin

    {missing function identifier}
    Error(2);
    lcp := ufctptr;
    end; {else}

  {create a new stack frame level}
  oldlev := level;
  oldtop := top;
  if level < maxlevel then
    level := level + 1
  else
    Error(108);
  if top < displimit then begin
    top := top+1;
    with display[top] do begin
      if forw then
        fname := lcp^.pfparms
      else
        fname := nil;
      flabel := nil;
      labsused := nil;
      occur := blck;
      ispacked := false;
      end; {with}
    end {if}
  else
    Error(107);

  {assign function labels}
  with lcp^ do
    if klass = func then
      pflabel := GetLocalLabel
    else
      pflabel := 0;

  {compile the parameters}
  if fsy = procsy then begin
    ParameterList([semicolon], lcp1, forw, false);
    if not (forw or override) then
      with lcp^ do begin
	pfparms := lcp1;
	pfactualsize := psize;
	end; {with}
    end {if}
  else begin
    ParameterList([semicolon,colon], lcp1, forw, false);
    if not (forw or override) then
      with lcp^ do begin
	pfparms := lcp1;
	pfactualsize := psize;
	end; {with}
    if sy = colon then begin
      InSymbol;
      if sy = ident then begin
	if forw or override then
          Error(48);
	SearchId([types], lcp1);
	lsp := lcp1^.idtype;
	lcp^.idtype := lsp;
	if lsp <> nil then
	  if not (lsp^.form in [scalar,subrange,pointerStruct,objects]) then
            begin
	    Error(46);
            lcp^.idtype := nil;
	    end; {if}
	InSymbol;
	end {if}
      else begin
        Error(2);
        Skip(fsys + [semicolon])
        end; {else}
      end {if}
    else if not (forw or override) then
      Error(49)
    end; {else}
  Match(semicolon,14);

  {handle directives}
  if (sy = ident) or doingInterface or inUses or isObject then begin
    foundBody := false;
    if sy <> ident then begin		{special assumptions for uses,	}
      if inUses and (not isObject) then	{ interface files, methods	}
	lcp2 := externIdentifier
      else
	lcp2 := forwardIdentifier;
      if override then
        Error(30);
      needSemicolon := false;
      end {if}
    else begin				{normal identifier section}
      SearchId([directive],lcp2);	{find the identifier type}
      InSymbol;
      needSemicolon := true;
      end; {else}
    lcp^.pfdirective := lcp2^.drkind;
    if override then begin
      if lcp2^.drkind <> droverride then
        Error(30);
      end {if}
    else if lcp2^.drkind = droverride then
      Error(124);
    with lcp^ do
      case pfdirective of
	drforw,droverride:
	  if forw then
	    Error(85);
	drextern:
	  if level <> 2 then
	    Error(101);
	drprodos: begin
	  if sy = lparent then
            InSymbol;
	  if (sy = intconst) then begin
	    pfcallnum := val.ival;
	    InSymbol;
	    end {if}
	  else
            Error(15);
	  if sy = rparent then
            InSymbol;
	  end;
	drtool1,drtool2: begin
	  if sy = lparent then
            InSymbol;
	  DoConstant(fsys+[comma], lsp1, lvalu);
          if lsp1 = intptr then
	    pftoolnum := lvalu.ival
	  else
            Error(15);
	  Match(comma,20);
	  DoConstant(fsys+[rparent], lsp1, lvalu);
          if lsp1 = intptr then
	    pfcallnum := lvalu.ival
	  else
            Error(15);
	  if sy = rparent then
	    InSymbol;
	  end;
	drvector: begin
	  if sy = lparent then
            InSymbol;
	  DoConstant(fsys+[comma], lsp1, lvalu);
          if lsp1 = longptr then
            pfaddr := lvalu.valp^.lval
          else if lsp1 = intptr then
	    pftoolnum := lvalu.ival
	  else
            Error(15);
	  Match(comma,20);
	  DoConstant(fsys+[rparent], lsp1, lvalu);
          if lsp1 = intptr then
	    pfcallnum := lvalu.ival
	  else
            Error(15);
	  if sy = rparent then
	    InSymbol;
	  end;
	otherwise: Error(6);
	end; {case}
    if needSemicolon then
      Match(semicolon,14);
    if not (sy in fsys) then begin
      Error(6);
      Skip(fsys);
      end; {if}
    end {if}
  else
    with lcp^ do begin

      {if list is off, write the proc name}
      foundBody := true;
      if (not list) and progress and compilebody then
	writeln(' ':level, {lcp^.}pfoname^);

      {lcp^.}pfdirective := drnone;
      {lcp^.}pfset := false;
      if compilebody then begin
	if level <= 2 then begin
	  mark({lcp^.}pfmark);
	  Gen2Name(dc_str, $4000*ord({lcp^.}pfPrivate)+$8000*ord(isDynamic), 0,
	    {lcp^.}pfoname);
	  inseg := true;
	  end; {if}
	DoBlock(fsys,semicolon,lcp,false);
	Match(semicolon,14);
	if not (sy in [endsy,beginsy,procsy,funcsy]) then begin
	  Error(6);
	  Skip([beginsy,procsy,funcsy]);
	  end; {if}
	if ({lcp^.}klass = func) and (not {lcp^.}pfset) then Error(96);
	end; {if}
      end; {with}
  ExportUses;
  level := oldlev;
  top := oldtop;
  psize := lpsize;
  end; {ProcDeclaration}


  procedure UsesDeclaration(fsys: setofsys);
  {compile a uses statement}

  var
    done: boolean;			{for detecting end of loop}
    foundBody: boolean;			{dummy var for ProcDeclaration}
    lfsys: setofsys;			{temp fsys}
    lsy: symbol; 			{for recording type of subroutine}

  begin {UsesDeclaration}
  if level <> 1 then Error(115); 	{must be at program level}
  repeat
    if sy = ident then begin
      inUses := true;			{mark as in a uses file}
      OpenUses;				{open the uses file}
      InSymbol;				{get the first symbol in the uses file}
      fsys := fsys+[implementationsy];	{allow implementation}
					{compile the file}
      while sy = usessy do begin 	{skip uses - assumes correct syntax,}
	repeat				{ but will not hang if fooled	    }
	  InSymbol;
	until (sy = semicolon) or eofl;
	InSymbol;
	end;
      if sy = constsy then begin InSymbol; ConstDeclaration(fsys); end;
      if sy = typesy then begin InSymbol; TypeDeclaration(fsys); end;
      if sy = varsy then begin InSymbol; VarDeclaration(fsys); end;
      {handle procedure, function declarations}
      while sy in [procsy,funcsy] do begin
	lsy := sy;
	InSymbol;
        nextLocalLabel := 1;
	ProcDeclaration(lsy, fsys, false, true, foundbody);
	if foundBody then Error(81);
	end;
      if sy <> implementationsy then begin
	Error(116);
	Skip([implementationsy]);
	end
      else
	InSymbol;
      inUses := false;			{mark as out of uses file}
      end
    else
      Error(2);
    done := sy <> comma;
    if not done then
      InSymbol;
  until done or eofl;
  Match(semicolon,14);
  end; {UsesDeclaration}


  procedure Selector {fsys: setofsys; fcp,fprocp: ctp; var isMethod: boolean};

  { handle indexing arrays, field selection, dereferencing of	}
  { pointers, windowing files					}
  {								}
  { parameters:							}
  {    fsys -							}
  {    fcp -							}
  {    fprocp - identifier for program or program-level		}
  {       subroutine contining this statement			}
  {    isMethod - (returned) Did the selection resolve to a	}
  {       method call?  If so, take no further action.		}

  var
    isFunction: boolean; 		{are we dereferencing a function?}
    lattr: attr;			{copy of an attribute}
    lcp,lcp1: ctp;
    lmin,lmax: longint;
    lsize: addrrange;
    lispacked: boolean;


    procedure ArrayIndex;

    { Handles subscripting an array				}

    var
      bt: baseTypeEnum;			{index base type}

    begin {ArrayIndex}
    {track array packing}
    gispacked := gispacked or lispacked;
    
    {loop over subscripts, possibly separated by commas}
    repeat

      {get the type, and make sure it's an array}
      lattr := gattr;
      lcp1 := glcp;
      with lattr do 
	if typtr <> nil then
	  if typtr^.form <> arrays then begin
	    Error(63);
            typtr := nil;
	    end; {if}
      LoadAddress;
      InSymbol;

      {get the array subscript value}
      Expression(fsys + [comma,rbrack],fprocp);
      Load;
      glcp := lcp1;
      if gattr.typtr <> nil then
	if gattr.typtr^.form <> scalar then
          Error(41);
      if lattr.typtr <> nil then
	with lattr.typtr^ do begin

          {if needed, promote the index to long}
          if CompTypes(inxtype, longptr) then
            if CompTypes(gattr.typtr, intptr) then begin
              Gen2(pc_cnv, ord(cgWord), ord(cgLong));
              gattr.typtr := longptr;
              end; {if}

          {check the type of the subscript}
	  if CompTypes(inxtype,gattr.typtr) then begin
	    if inxtype <> nil then begin

              {check the range of the subscript}
	      GetBounds(inxtype,lmin,lmax);
	      if debug then
                if GetType(inxtype, false) in [cgLong,cgULong] then
                  GenL2t(pc_chk, lmin, lmax, cgULong)
                else
                  Gen2t(pc_chk, ord(lmin), ord(lmax), cgWord);

              {handle non-zero stating indexes for the array}
              if lmin <> 0 then
                if lmin > maxint then begin
                  GenLdcLong(lmin);
                  Gen0(pc_sbl);
                  end {if}
                else
		  Gen1t(pc_dec, ord(lmin), GetType(inxtype, false));
	      end;
	    end
	  else
            Error(64);

          {set up the result type, after indexing}
          bt := GetType(gattr.typtr, false);
	  with gattr do begin
	    typtr := aeltype;
            isPacked := false;
	    kind := varbl;
	    access := indrct;
	    idplmt := 0;
	    end;

          {index into the array}
	  if gattr.typtr <> nil then begin
	    lsize := gattr.typtr^.size;
	    if ((gattr.typtr = charptr) or (gattr.typtr = boolptr))
	      and (ispacked = pkpacked) then begin
	      lsize := packedcharsize;
              gattr.isPacked := true;
              end; {if}
            if (size < $010000) and (inxtype^.size <= intsize) then begin
	      Gen1t(pc_ldc, long(lsize).lsw, cgUWord);
              Gen0(pc_umi);
	      Gen0t(pc_ixa, cgUWord);
              end {if}
            else begin
              if not (bt in [cgLong,cgULong]) then
                Gen2(pc_cnv,ord(bt),ord(cgULong));
	      GenLdcLong(lsize);
              Gen0(pc_uml);
              Gen0(pc_adl);
              end; {else}
      	    end; {if}
	  end; {with}
    until sy <> comma;

    {make sure there is a matching ']'}
    Match(rbrack,12);
    end; {ArrayIndex}


    procedure FieldSelection;

    { Compile a field selection					}

    var
      form: structform;			{records or objects (kind of variable)}
      disp: addrrange;			{disp in object for method}

    begin {FieldSelection}
    gispacked := gispacked or lispacked;
    with gattr do begin

      {get the variable kind}
      if typtr <> nil then begin
        form := typtr^.form;
	if not (form in [records,objects]) then begin
	  Error(65);
          typtr := nil;
	  end; {if}
        end {if}
      else
        form := records;

      {get the field id}
      if sy = ident then begin
	if typtr <> nil then begin

          {find the field}
          if form = records then
	    SearchSection(typtr^.fstfld, lcp)
          else
	    SearchSection(typtr^.objfld, lcp);
	  if lcp = nil then begin
	    Error(77);
            typtr := nil;
	    end {if}
	  else begin

            {dereference the field}
	    glcp := lcp;
	    with lcp^ do begin
	      typtr := idtype;
	      lispacked := typtr^.ispacked = pkpacked;
	      case access of
		drct:	  begin
                          if form = objects then begin
                            typtr := longptr;
                            Load;
			    if debug then
			      GenL2t(pc_chk, 1, maxaddr, cgULong);
			    typtr := idtype;
                            isPacked := lispacked;
			    kind := varbl;
			    access := indrct;
                            if klass = field then
			      idplmt := fldaddr
                            else
			      idplmt := pfaddr;
                            end {if}
                          else begin
                            dpdisp := dpdisp + fldaddr;
                            if dpdisp > maxint then
                              {use indirect access}
                              LoadAddress;
                            end; {else}
                          end;     
		indrct:   if form = objects then begin
                            typtr := longptr;
                            Load;
			    if debug then
			      GenL2t(pc_chk, 1, maxaddr, cgULong);
                            typtr := idtype;
                            isPacked := lispacked;
			    kind := varbl;                                
			    access := indrct;
                            if klass = field then
			      idplmt := fldaddr
                            else
			      idplmt := pfaddr;
	                    end {if}
                          else
			    idplmt := idplmt + fldaddr;
		inxd:	  Error(113)
		end; {case}
	      end; {with}

            {skip the field name}
	    InSymbol;

            {check for method calls}
            if glcp^.klass = proc then begin
              disp := gattr.idplmt;
              gattr.idplmt := 0;
              LoadAddress;
              Gen0t(pc_stk, cgULong);
	      CallNonStandard(fsys, glcp, fprocp, disp, cMethod);
              isMethod := true;
              end {if}
            else if glcp^.klass = func then begin
              disp := gattr.idplmt;
              gattr.idplmt := 0;
              LoadAddress;
              Gen0t(pc_stk, cgULong);
	      isFunction := true;
	      CallNonStandard(fsys, glcp, fprocp, disp, cMethod);
              isMethod := true;
	      if sy <> arrow then
		gattr.kind := expr;
	      if sy in [period,lbrack] then
        	Error(23);
              end; {else if}
	    end; {else}
	  end {if}
        else

          {skip the field name}
	  InSymbol;
	end {sy = ident}
      else
        Error(2)
      end; {with gattr}
    end; {FieldSelection}


  begin {Selector}
  isFunction := false;
  isMethod := false;
  if not doingCast then begin

    {access the identifier}
    with fcp^, gattr do begin
      typtr := idtype;
      isPacked := false;
      kind := varbl;
      case klass of
	varsm:
	  if vkind = actual then begin
	    {for actual variables, pass back the info}
	    access := drct;
	    vlevel := vlev;
	    dpdisp := 0;
	    if vlevel = 1 then
	      aname := name
	    else
	      dplab := vlabel;
	    end
	  else begin
	    {for formal variables, load their addr and indicate indirection}
	    Gen3t(pc_lod, vlabel, 0, level-vlev, cgULong);
	    access := indrct;
	    idplmt := 0
	    end;
	field:
	  with display[disx] do
	    if occur = crec {field is directly accessable} then begin
	      access := drct;
	      vlevel := clev;
	      if vlevel = 1 then
                aname := cname;
	      dpdisp := cdspl+fldaddr;
              dplab := clab;
	      end {if}
	    else {field must be accessed indirectly} begin
	      {for with only - access temp global variable from stack frame}
	      Gen3t(pc_lod, vdsplab, 0, 0, cgULong);
	      access := indrct;
	      idplmt := fldaddr
	      end;
	func: begin
	  isFunction := true;
	  Call(fsys, fcp, fprocp);
	  if sy <> arrow then
	    gattr.kind := expr;
	  if sy in [period,lbrack] then
            Error(23);
	  end;
	otherwise:;
	end; {case}
      end; {with}
    if not (sy in selectsys + fsys) then begin
      Error(29);
      Skip(selectsys + fsys);
      end;
    lispacked := false;
    if glcp <> nil then
      with glcp^ do
	if {glcp^.}idtype <> nil then
	  lispacked := {glcp^.}idtype^.ispacked = pkpacked;
    {handle selections}
    end; {with}

  {do selections}
  while sy in selectsys do begin
{[} if sy = lbrack then			{indexes}
      ArrayIndex
{.} else if sy = period then begin	{record or object fields}
      InSymbol;
      FieldSelection;
      end {else if}
{^} else begin
      gispacked := false;
      if gattr.typtr <> nil then
	with gattr,typtr^ do
	  if form in [pointerStruct,files] then begin
	    if not isFunction then
	      Load;
	    if form = pointerStruct then
	      typtr := eltype
	    else
	      typtr := filtype;
	    lispacked := typtr^.ispacked = pkpacked;
	    if debug then
	      GenL2t(pc_chk, 1, maxaddr, cgULong);
	    with gattr do begin
              isPacked := false;
	      kind := varbl;
	      access := indrct;
	      idplmt := 0;
	      end;
	    end
	  else
	    Error(66);
      InSymbol;
      end;
    if not (sy in fsys + selectsys) then begin
      Error(6);
      Skip(fsys + selectsys);
      end; {if}
    end {while}
  end; {Selector}

  
  procedure InheritedCall (fsys: setofsys; fprocp: ctp);

  { Compile an inherited call					}
  {								}
  { parameters:							}
  {    fsys - follow symbols					}
  {    fprocp - identifier for program or program-level		}
  {       subroutine contining this statement			}
  
  var
    lcp, lcp2, lcp3: ctp;		{work identifiers}
    loc: unsigned;			{position of '~' in object.method name}
    lsp: stp;				{superclass object type}

  begin {InheritedCall}
  if sy = ident then begin

    {find the current method's object}
    SearchId([proc,func], lcp);
    if lcp <> nil then begin
      id := lcp^.pfoname^;
      loc := Pos('~', id);
      if loc <> 0 then
        id[0] := chr(loc-1);
      SearchId([types], lcp2);
      
      {find the parent object}
      if lcp2 <> nil then
        if lcp2^.idtype <> nil then
          if lcp2^.idtype^.objparent <> nil then begin
            lsp := lcp2^.idtype^.objparent;

            {find the method to be inherited}
            id := lcp^.name^;
	    SearchSection(lsp^.objfld, lcp2);
            if lcp2 = nil then
              Error(130)
            else begin
	      {set up the 'SELF' parameter}
	      id := 'SELF';
	      SearchId([varsm,field], lcp3);
	      if lcp3 <> nil then
		if (lcp3^.idtype <> nil) and (lcp3^.klass = varsm) then begin
		  gattr.typtr := lcp3^.idtype;
        	  gattr.isPacked := false;
        	  gattr.kind := varbl;
        	  gattr.access := drct;
        	  gattr.vlevel := lcp3^.vlev;
        	  gattr.dplab := lcp3^.vlabel;
        	  gattr.dpdisp := 0;
        	  gattr.aname := lcp3^.name;
                  Load;
                  Gen0t(pc_stk, cgULong);
        	  end; {if}

              {call the inherited method}
	      InSymbol;
	      CallNonStandard(fsys, lcp2, fprocp, 0, cInherited);
              end; {else}
            end; {if}
      end; {if}
    end {if}
  else begin
    Error(2);
    Skip(fsys);
    end; {else}
  end; {InheritedCall}


  procedure Expression {fsys: setofsys; fprocp: ctp};

  { compile an expression					}
  {								}
  { parameters:							}
  {    fsys - follow symbols					}
  {    fprocp - identifier for program or program-level		}
  {       subroutine contining this statement			}
  
  var
    lattr: attr;
    lop: operator;
    typind: basetypeenum;
    lsize,rsize: integer;		{size of string operands}
 
    procedure FloatCheck(var first, second: stp);
    {insure that both operands are real}

    begin {FloatCheck}
    if (second = intptr) or (second = byteptr) then begin
      Gen2(pc_cnv,ord(cgWord),ord(cgReal));
      second := realptr;
      end
    else if second = longptr then begin
      Gen2(pc_cnv,ord(cgLong),ord(cgReal));
      second := realptr;
      end
    else if IsReal(second) then
      second := realptr;
    if (first = intptr) or (first = byteptr) then begin
      Gen2(pc_cnn,ord(cgWord),ord(cgReal));
      first := realptr;
      end
    else if first = longptr then begin
      Gen2(pc_cnn,ord(cgLong),ord(cgReal));
      first := realptr;
      end
    else if IsReal(first) then
      first := realptr;
    end; {FloatCheck}

    procedure MatchOpnd(var first, second: stp);
    {insure that the operand types match}

    begin {MatchOpnd}
    {eliminate need for redundant checking}
    if second = byteptr then
      second := intptr
    else if IsReal(second) then
      second := realptr;
    if first = byteptr then
      first := intptr
    else if IsReal(first) then
      first := realptr;
    {match second operand to first if first is of higher type}
    if second = intptr then begin
      if first = longptr then begin
	Gen2(pc_cnv,ord(cgWord),ord(cgLong));
	second := longptr;
	end
      else if first = realptr then begin
	Gen2(pc_cnv,ord(cgWord),ord(cgReal));
	second := realptr;
	end;
      end
    else if second = longptr then
      if first = realptr then begin
	Gen2(pc_cnv,ord(cgLong),ord(cgReal));
	second := realptr;
	end;
    {match first operand to second if second is of higher type}
    if first = intptr then begin
      if second = longptr then begin
	Gen2(pc_cnn,ord(cgWord),ord(cgLong));
	first := longptr;
	end
      else if second = realptr then begin
	Gen2(pc_cnn,ord(cgWord),ord(cgReal));
	first := realptr;
	end;
      end
    else if first = longptr then
      if second = realptr then begin
	Gen2(pc_cnn,ord(cgLong),ord(cgReal));
	first := realptr;
	end;
    end; {MatchOpnd}

    procedure SimpleExpression(fsys: setofsys);
    {compile a simple expression}

    var
      lattr: attr;
      lop: operator;
      signed,foundSign: boolean;
 
      procedure Term (fsys: setofsys);

      { compile a term						}
      {								}
      { parameters:						}
      {    fsys - follow symbols				}

      var
	lattr: attr;
	lop: operator;


	procedure Factor (fsys: setofsys);

	{ compile a factor						}
        {								}
        { parameters:							}
        {    fsys - follow symbols					}

	var
          isMethod: boolean;		{dummy for selector call}
	  lvp: csp;
	  varpart: boolean;
	  cstmax: setlow..sethigh;
	  lsp: stp;
	  lowrange,i: integer;
	  test: boolean;
	  lcp: ctp;			{used to form addresses via atsy}
	  cstpart: ^settype;
	  castType: stp; 		{type to cast to (for type casting)}
	  castSize: addrrange;		{sizes (for type casting)}

	begin {Factor}
	if not (sy in facbegsys) then begin
	  Error(28);
	  Skip(fsys + facbegsys);
	  gattr.typtr := nil;
	  end; {if}
	while sy in facbegsys do begin
	  case sy of
  {id}	    ident: begin
	      SearchId([types,konst,varsm,field,func],glcp);
	      with glcp^ do begin
		InSymbol;
		if klass = types then begin
		  {handle a type cast}
		  if iso then Error(112);
		  castType := {glcp^.}idtype;
		  castSize := castType^.size;
		  Match(lparent,9);
		  Expression(fsys + [rparent],fprocp);
		  if (gattr.typtr^.form in
                    [power,arrays,records,files,tagfld,variant])
                    or (castType^.form in [power,files,tagfld,variant]) then
		    Error(121);
		  if castSize <> gattr.typtr^.size then begin
		    {type conversion}
		    Load;
		    gattr.typtr := castType;
		    if castSize = 2 then
		      Gen2(pc_cnv,ord(cgLong),ord(cgWord))
		    else
		      Gen2(pc_cnv,ord(cgWord),ord(cgLong));
		    Match(rparent,4);
		    end
		  else begin
		    {treat space as another type}
		    gattr.typtr := castType;
		    Match(rparent,4);
		    doingCast := true;
		    Selector(fsys, glcp, fprocp, isMethod);
		    doingCast := false;
		    end;
		  end
		else if klass = konst then
		  with gattr do begin
		    typtr := {glcp^.}idtype;
                    isPacked := false;
		    kind := cst;
		    cval := {glcp^.}values;
		    end
		else
		  Selector(fsys, glcp, fprocp, isMethod);
		end;
	      end;
{inherited} inheritedsy: begin
              InSymbol;
	      InheritedCall(fsys, fprocp);
	      if sy <> arrow then
		gattr.kind := expr;
	      if sy in [period,lbrack] then
        	Error(23);
              end;
  {nil}	    nilsy: begin
	      with gattr do begin
		typtr := nilptr;
                isPacked := false;
		kind := cst;
		cval.ival := 0;
		InSymbol;
		end;
	      end;
  {atsy}    atsy: begin
	      InSymbol;
	      if sy = ident then begin
		SearchId([konst,varsm,field,func,proc],lcp);
		InSymbol;
		if lcp^.klass in [func,proc] then
		  Gen0Name(pc_lad,lcp^.name)
                else if lcp^.klass = konst then begin
                  if IsString(lcp^.idtype) then begin
                    val := lcp^.values;
                    lgth := length(val.valp^.sval);
                    LoadString(lengthString);
		    LoadAddress;
                    end {if}
                  else
                    Error(32);
                  end {else if}
		else begin
		  if lcp^.klass = varsm then begin
		    if lcp^.vcontvar then Error(97);
		    if lcp^.vlev <> level then lcp^.vrestrict := true;
		    end;
		  Selector(fsys, lcp, fprocp, isMethod);
		  LoadAddress;
		  end;
		end
	      else if sy = stringconst then begin
		LoadString(lengthString);
		InSymbol;
		LoadAddress;
		end
	      else Error(2);
	      gattr.kind := expr;
	      gattr.typtr := nilptr;
	      end;
  {cst}	    intconst: begin
	      with gattr do begin
		typtr := intptr;
                isPacked := false;
		kind := cst;
		cval := val;
		end;
	      InSymbol;
	      end;
	    longintconst: begin
	      with gattr do begin
		typtr := longptr;
                isPacked := false;
		kind := cst;
		cval := val;
		end;
	      InSymbol;
	      end;
	    realconst: begin
	      with gattr do begin
		typtr := realptr;
                isPacked := false;
		kind := cst;
		cval := val;
		end;
	      InSymbol;
	      end;
	    stringconst: begin
	      with gattr do begin
		if lgth = 1 then
                  typtr := charptr
		else begin
                  lsp := pointer(Malloc(sizeof(structure)));
		  with lsp^ do begin
		    aeltype := charptr;
		    form := arrays;
		    hasSFile := false;
		    ispacked := pkpacked;
		    inxtype := dummystring;
		    size := lgth*packedcharsize;
		    end; {with}
		  typtr := lsp
		  end; {else}
                isPacked := false;
		kind := cst;
		cval := val;
		end; {with}
	      InSymbol;
	      end;
    {(}	    lparent: begin
	      InSymbol;
	      Expression(fsys + [rparent],fprocp);
	      Load;
	      Match(rparent,4);
	      end;
   {not}    notsy: begin
	      InSymbol;
	      Factor(fsys);
	      Load;
	      Gen0(pc_not);
	      if gattr.typtr <> nil then
		if gattr.typtr <> boolptr then begin
		  Error(60); gattr.typtr := nil;
		  end;
	      end;
   {~}	    bitnot: begin
	      InSymbol;
	      Factor(fsys);
	      Load;
	      if gattr.typtr <> nil then
		if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
		  Gen0(pc_bnt)
		else if gattr.typtr = longptr then
		  Gen0(pc_bnl)
		else begin
		  Error(59);
		  gattr.typtr := nil;
		  end;
	      end;
   {[}	    lbrack: begin
	      new(cstPart);
	      InSymbol;
	      cstpart^ := [ ];
	      varpart := false;
              lsp := pointer(Malloc(sizeof(structure)));
	      cstmax := setlow;
	      with lsp^ do begin
		ispacked := pkeither;
		hasSFile := false;
		form := power;
		elset := nil;
		end;
	      if sy = rbrack then begin
		lsp^.size := cstmax div 8 + 1;
		with gattr do begin
		  typtr := lsp;
                  isPacked := false;
                  kind := cst
                  end;
		InSymbol;
		end
	      else begin
		repeat
		  Expression(fsys + [comma,rbrack,dotdot],fprocp);
		  if gattr.typtr <> nil then
		    if not (gattr.typtr^.form in [scalar,subrange]) then begin
		      Error(61);
                      gattr.typtr := nil;
		      end
		    else if CompTypes(lsp^.elset,gattr.typtr) then begin
		      if gattr.kind = cst then begin
			if (gattr.cval.ival < setlow) or
			  (gattr.cval.ival > sethigh) then Error(110);
			if sy = dotdot then begin
			  InSymbol;
			  lowrange := gattr.cval.ival;
			  Expression(fsys+[comma,rbrack],fprocp);
			  if gattr.typtr <> nil then
			    if not (gattr.typtr^.form in [scalar,subrange]) then
			      begin
			      Error(61);
			      gattr.typtr := nil;
			      end
			    else if CompTypes(lsp^.elset,gattr.typtr) then begin
			      if gattr.kind = cst then begin
				if gattr.cval.ival>sethigh then Error(110);
				for i := lowrange to gattr.cval.ival do
				  cstpart^ := cstpart^+[i];
				if gattr.cval.ival > cstmax then
				  cstmax := gattr.cval.ival;
				end
			      else begin
                                Gen1t(pc_ldc, lowRange, cgWord);
				Load;
				if debug then
				  Gen2t(pc_chk, setlow, sethigh, cgUWord);
				Gen0(pc_sgs);
				if varpart then Gen0(pc_uni)
				else varpart := true
				end;
			      end
			    else Error(62);
			  end
			else begin
			  cstpart^ := cstpart^+[gattr.cval.ival];
			  if gattr.cval.ival > cstmax then
			    cstmax := gattr.cval.ival;
			  end
			end
		      else begin
			Load;
			if debug then
			  Gen2t(pc_chk, setlow, sethigh, cgUWord);
			if sy = dotdot then begin
			  InSymbol;
			  Expression(fsys+[comma,rbrack],fprocp);
			  if gattr.typtr <> nil then
			    if not (gattr.typtr^.form in [scalar,subrange]) then
			      begin
			      Error(61);
			      gattr.typtr := nil;
			      end
			    else if CompTypes(lsp^.elset,gattr.typtr) then begin
			      Load;
			      if debug then
				Gen2t(pc_chk, setlow, sethigh, cgUWord);
			      end
			    else Error(62);
			  end
			else
			  Gen1t(pc_ldc, $8000, cgUWord);
			Gen0(pc_sgs);
			if varpart then Gen0(pc_uni)
			else varpart := true
			end;
		      lsp^.elset := gattr.typtr;
		      gattr.typtr := lsp
		      end
		    else Error(62);
		  test := sy <> comma;
		  if not test then InSymbol
		until test;
		Match(rbrack,12);
		end;
	      if varpart then begin
		if cstpart^ <> [ ] then begin
                  lvp := pointer(Malloc(sizeof(constantRec)));
		  with lvp^ do begin
		    cclass := pset;
		    pval := cstpart^;
		    pmax := cstmax;
		    end;
		  GenLdcSet(lvp^);
		  Gen0(pc_uni);
		  gattr.kind := expr;
		  end
		end
	      else begin
                lvp := pointer(Malloc(sizeof(constantRec)));
		with lvp^ do begin
		  cclass := pset;
		  pval := cstpart^;
		  pmax := cstmax;
		  end;
		gattr.cval.valp := lvp;
                gattr.isPacked := false;
		gattr.kind := cst;
		end;
	      dispose(cstPart);
	      end
	    end; {case}
	  if not (sy in (fsys+[powersy])) then begin
	    Error(6);
            Skip(fsys + facbegsys);
	    end; {if}
	  end; {while}
	if sy = powersy then begin
	  Load;
	  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
	    Gen2(pc_cnv,ord(cgWord),ord(cgReal))
	  else if gattr.typtr = longptr then
	    Gen2(pc_cnv,ord(cgLong),ord(cgReal))
	  else if not IsReal(gattr.typtr) then
	    Error(59);
	  InSymbol;
	  Factor(fsys);
	  Load;
	  if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
	    Gen2(pc_cnv,ord(cgWord),ord(cgReal))
	  else if gattr.typtr = longptr then
	    Gen2(pc_cnv,ord(cgLong),ord(cgReal))
	  else if not IsReal(gattr.typtr) then
	    Error(59);
	  Gen0(pc_pwr);
	  gattr.typtr := realptr;
	  end;
	end; {Factor}

      begin {Term}
      Factor(fsys + [mulop,powersy]);
      while sy = mulop do begin
	Load;
	lattr := gattr;
	lop := op;
	InSymbol;
	Factor(fsys + [mulop]);
	Load;
	if (lattr.typtr <> nil) and (gattr.typtr <> nil) then
	  case lop of
   {*}	    mul: begin
	      MatchOpnd(lattr.typtr,gattr.typtr);
	      if lattr.typtr = intptr then
		Gen0(pc_mpi)
	      else if lattr.typtr = longptr then
		Gen0(pc_mpl)
	      else if lattr.typtr = realptr then
		Gen0(pc_mpr)
	      else if(lattr.typtr^.form=power)
		and CompTypes(lattr.typtr,gattr.typtr)then
		Gen0(pc_int)
	      else begin
		Error(59);
		gattr.typtr:=nil;
		end;
	      end;
   {/}	    rdiv: begin
	      FloatCheck(lattr.typtr,gattr.typtr);
	      if lattr.typtr = realptr then
		Gen0(pc_dvr)
	      else begin
		Error(59);
		gattr.typtr := nil;
		end;
	      end;
   {div}    idiv: begin
	      MatchOpnd(lattr.typtr,gattr.typtr);
	      if lattr.typtr = intptr then
		Gen0(pc_dvi)
	      else if lattr.typtr = longptr then
		Gen0(pc_dvl)
	      else begin
		Error(59);
		gattr.typtr := nil;
		end;
	      end;
   {mod}    imod: begin
	      MatchOpnd(lattr.typtr,gattr.typtr);
	      if lattr.typtr = intptr then
		Gen0(pc_mod)
	      else if lattr.typtr = longptr then
		Gen0(pc_mdl)
	      else begin
		Error(59);
		gattr.typtr := nil;
		end;
	      end;
   {and}    andop:
	      if (lattr.typtr = boolptr) and (gattr.typtr = boolptr) then
		Gen0(pc_and)
	      else begin
		Error(59);
		gattr.typtr := nil;
		end;
   {<<}	    lshift: begin
	      MatchOpnd(lattr.typtr,gattr.typtr);
	      if lattr.typtr=intptr then
		Gen0(pc_shl)
	      else if lattr.typtr = longptr then
		Gen0(pc_sll)
	      else begin
		Error(59);
		gattr.typtr:=nil;
		end;
	      end;
   {>>}	    rshift: begin
	      MatchOpnd(lattr.typtr,gattr.typtr);
	      if lattr.typtr=intptr then
		Gen0(pc_shr)
	      else if lattr.typtr = longptr then
		Gen0(pc_slr)
	      else begin
		Error(59);
		gattr.typtr:=nil;
		end;
	      end;
   {&}	    band: begin
	      MatchOpnd(lattr.typtr,gattr.typtr);
	      if lattr.typtr=intptr then
		Gen0(pc_bnd)
	      else if lattr.typtr = longptr then
		Gen0(pc_bal)
	      else begin
		Error(59);
		gattr.typtr:=nil;
		end;
	      end;
	    end {case}
	else
	  gattr.typtr := nil;
	end; {while}
      end; {Term}

    begin {SimpleExpression}
    signed := false;
    foundSign := false;
    if (sy = addop) and (op in [plus,minus]) then begin
      signed := op = minus;
      InSymbol;
      foundSign := true;
      end;
    Term(fsys + [addop]);
    if signed then begin
      Load;
      if (gattr.typtr = intptr) or (gattr.typtr = byteptr) then
	Gen0(pc_ngi)
      else if gattr.typtr = longptr then
	Gen0(pc_ngl)
      else if IsReal(gattr.typtr) then
	Gen0(pc_ngr)
      else begin
	Error(59);
	gattr.typtr := nil;
	end;
      end
    else if foundSign then
      if (gattr.typtr <> intptr) and (not IsReal(gattr.typtr))
	and (gattr.typtr <> byteptr) and (gattr.typtr <> longptr) then
	Error(34);
    while sy = addop do begin
      Load;
      lattr := gattr;
      lop := op;
      InSymbol;
      Term(fsys + [addop]);
      Load;
      if (lattr.typtr <> nil) and (gattr.typtr <> nil) then
	case lop of
{+}	  plus: begin
	    MatchOpnd(lattr.typtr,gattr.typtr);
	    if lattr.typtr = intptr then
	      Gen0(pc_adi)
	    else if lattr.typtr = longptr then
	      Gen0(pc_adl)
	    else if lattr.typtr = realptr then
	      Gen0(pc_adr)
	    else if (lattr.typtr^.form=power)
	      and CompTypes(lattr.typtr,gattr.typtr) then
	      Gen0(pc_uni)
	    else begin
	      Error(59);
	      gattr.typtr:=nil;
	      end;
	    end;
{-}	  minus: begin
	    MatchOpnd(lattr.typtr,gattr.typtr);
	    if lattr.typtr = intptr then
	      Gen0(pc_sbi)
	    else if lattr.typtr = longptr then
	      Gen0(pc_sbl)
	    else if lattr.typtr = realptr then
	      Gen0(pc_sbr)
	    else if (lattr.typtr^.form = power)
	      and CompTypes(lattr.typtr,gattr.typtr) then
	      Gen0(pc_dif)
	    else begin
	      Error(59);
	      gattr.typtr := nil;
	      end;
	    end;
{or}	  orop:
	    if (lattr.typtr = boolptr) and (gattr.typtr = boolptr) then
	      Gen0(pc_ior)
	    else begin
	      Error(59);
	      gattr.typtr := nil;
	      end;
{|}	  bor: begin
	    MatchOpnd(lattr.typtr,gattr.typtr);
	    if lattr.typtr = intptr then
	      Gen0(pc_bor)
	    else if lattr.typtr = longptr then
	      Gen0(pc_blr)
	    else begin
	      Error(59);
	      gattr.typtr:=nil;
	      end;
	    end;
{!}	  xor: begin
	    MatchOpnd(lattr.typtr,gattr.typtr);
	    if lattr.typtr = intptr then
	      Gen0(pc_bxr)
	    else if lattr.typtr = longptr then
	      Gen0(pc_blx)
	    else begin
	      Error(59);
	      gattr.typtr:=nil;
	      end;
	    end;
	  end {case}
      else gattr.typtr := nil
      end; {while}
    end; {SimpleExpression}

  begin {Expression}
  SimpleExpression(fsys + [relop]);
  if sy = relop then begin
    if gattr.typtr <> nil then
      if gattr.typtr^.form in [scalar..power,objects] then
	Load
      else
	LoadAddress;
    lattr := gattr;
    lop := op;
    InSymbol;
    SimpleExpression(fsys);
    {set the size of the left operand}
    if lattr.typtr <> nil then
      if IsString(lattr.typtr) then
	lsize := StrLen(lattr.typtr);
    if gattr.typtr <> nil then begin
      if IsString(gattr.typtr) then
	if lattr.typtr = charptr then begin
	  lattr.typtr := stringptr;
	  lsize := -1;
	  end;
      if gattr.typtr^.form in [scalar..power,objects] then
	Load
      else
	LoadAddress;
      end;
    {set the size of the right operand}
    if IsString(gattr.typtr) then
      rsize := StrLen(gattr.typtr)
    else begin
      if lattr.typtr <> nil then
	if IsString(lattr.typtr) then
	  if gattr.typtr = charptr then begin
	    gattr.typtr := stringptr;
	    rsize := -1;
	    end; {if}
      end; {else}

    if (lattr.typtr <> nil) and (gattr.typtr <> nil) then
      if lop = inop then
	if lattr.typtr^.form<power then
	  if gattr.typtr^.form = power then
	    if CompTypes(lattr.typtr,gattr.typtr^.elset) then
	      Gen0(pc_inn)
	    else begin Error(54); gattr.typtr := nil; end
	  else begin Error(55); gattr.typtr := nil; end
	else begin Error(54); gattr.typtr := nil; end
      else begin
	MatchOpnd(lattr.typtr,gattr.typtr);
	if CompTypes(lattr.typtr,gattr.typtr) then begin
	  case lattr.typtr^.form of
	    scalar:
	      if lattr.typtr = realptr then typind := cgReal
	      else if lattr.typtr = boolptr then typind := cgUWord
	      else if lattr.typtr = charptr then typind := cgUWord
	      else if lattr.typtr = doubleptr then typind := cgDouble
	      else if lattr.typtr = compptr then typind := cgComp
	      else if lattr.typtr = extendedptr then typind := cgExtended
	      else if lattr.typtr = longptr then typind := cgLong
	      else typind := cgWord;
	    pointerStruct,objects: begin
	      if lop in [ltop,leop,gtop,geop] then Error(56);
	      typind := cgULong;
	      end;
	    power: begin
	      if lop in [ltop,gtop] then Error(57);
	      typind := cgSet;
	      end;
	    arrays: begin
	      if not IsString(lattr.typtr) then Error(59);
	      typind := cgString;
	      end;
	    records: begin
	      Error(59);
	      typind := cgString;
	      end;
	    files: begin
	      Error(58);
	      typind := cgULong;
	      end
	    end;
          if typind = cgString then begin
	    case lop of
	      ltop: Gen2t(pc_les, lsize, rsize, typind);
	      leop: Gen2t(pc_leq, lsize, rsize, typind);
	      gtop: Gen2t(pc_grt, lsize, rsize, typind);
	      geop: Gen2t(pc_geq, lsize, rsize, typind);
	      neop: Gen2t(pc_neq, lsize, rsize, typind);
	      eqop: Gen2t(pc_equ, lsize, rsize, typind);
	      end {case}
            end
          else
	    case lop of
	      ltop: Gen0t(pc_les, typind);
	      leop: Gen0t(pc_leq, typind);
	      gtop: Gen0t(pc_grt, typind);
	      geop: Gen0t(pc_geq, typind);
	      neop: Gen0t(pc_neq, typind);
	      eqop: Gen0t(pc_equ, typind);
	      end; {case}
	  end
	else Error(54);
	end;
    gattr.typtr := boolptr;
    gattr.kind := expr;
    end; {sy = relop}
  end; {Expression}

 
  procedure Statement (fsys: setofsys; fprocp: ctp; var stlevel: integer;
    var starray: starrtype);

  { Compile a statement						}
  {								}
  { parameters:							}
  {    fsys -							}
  {    fprocp - identifier for program or program-level		}
  {       subroutine contining this statement			}
  {    stlevel -						}
  {    starray -						}

  label 1;

  var
    lcp, fcp: ctp;			{work identifier pointers}
    llp: lbp; i: integer;


    procedure MakeLab(var ml: ctp; n: integer);
    {Change a numbered label into a named label}

    var i: integer;

    begin {MakeLab}
    ml := pointer(Malloc(sizeof(identifier)));
    with ml^ do begin
      name := pointer(Malloc(6));
      name^[0] := chr(5);
      name^[1] := '~';
      for i := 5 downto 2 do begin
	name^[i] := chr(ord('0')+n mod 10);
	n := n div 10;
	end;
      end;
    end; {MakeLab}


    procedure Assignment (fcp: ctp);

    { compile an assignment statement				}
    {								}
    { parameters:						}
    {    fcp - leading identifier in assignment statement	}

    label 1;

    var
      isMethod: boolean;		{is this a method call?}
      lattr: attr;			{attr for left hand side}
      tattr: attr;			{for checking string types}
      stringAssignment: boolean; 	{are we assigning a string?}

    begin {Assignment}
    isMethod := false;
    stringAssignment := false;
    if fcp <> nil then
      with fcp^ do begin
	if klass = func then begin

          {function assignment}
	  pfset := true;
	  if pfdeckind = standard then begin
	    Error(75);
	    gattr.typtr := nil;
	    end
	  else begin
	    if pfkind = formal then
	      Error(76)
	    else if pflev+1 > level then
	      Error(93);
	    with gattr do begin
	      typtr := idtype;
              isPacked := false;
	      kind := varbl;
	      access := drct;
	      vlevel := pflev+1;
	      dplab := pflabel;
              dpdisp := 0;
	      end; {with}
	    end;
	  goto 1;
	  end {if}
	else if klass = varsm then begin

          {variable (non-function) assignment}
	  if vcontvar then
            Error(97);
	  if vlev <> level then
            vrestrict := true;
	  end; {else if}
	end; {with}
    Selector(fsys + [becomes], fcp, fprocp, isMethod);

    {handle the right-hand side}
1:  if not isMethod then
      if sy = becomes then begin
	if gattr.typtr <> nil then begin
	  stringAssignment := IsString(gattr.typtr);
	  if (gattr.access<>drct) or 
	    (gattr.typtr^.form in [arrays,records,files]) then begin
	    LoadAddress;
	    if stringAssignment then
              Gen0t(pc_stk, cgULong);
            end; {if}
	  if stringAssignment then begin
	    Gen1t(pc_ldc, StrLen(gattr.typtr), cgWord);
            Gen0t(pc_stk, cgWord);
            Gen0t(pc_bno, cgWord);
            end; {if}
	  end; {if}
	lattr := gattr;
	InSymbol;
	Expression(fsys,fprocp);
	tattr := gattr;
	if gattr.typtr <> nil then
	  if gattr.typtr^.form = objects then begin
	    Load;
	    if debug then
	      GenL2t(pc_chk, 1, maxaddr, cgULong);
            end {if}
	  else if gattr.typtr^.form in [scalar,subrange,pointerStruct,power] then
	    Load
	  else
	    LoadAddress;

	if (lattr.typtr <> nil) and (gattr.typtr <> nil) then begin
	  if CompTypes(realptr, lattr.typtr) then begin

            {convert a non-real rhs to a real before storing}
	    if (gattr.typtr = intptr) or (gattr.typtr = bytePtr) then begin
	      Gen2(pc_cnv, ord(cgWord), ord(cgReal));
	      gattr.typtr := realptr;
	      end
	    else if gattr.typtr = longptr then begin
	      Gen2(pc_cnv, ord(cgLong), ord(cgReal));
	      gattr.typtr := realptr;
	      end;
	    end
	  else if CompTypes(longptr, lattr.typtr) then

            {convert a non-long rhs to a long before storing}
	    if (gattr.typtr = intptr) or (gattr.typtr = bytePtr) then begin
	      Gen2(pc_cnv, ord(cgWord), ord(cgLong));
	      gattr.typtr := longptr;
	      end; {if}

          {convert a char rhs to a string before storing}
	  if gattr.typtr = charptr then begin
	    if IsString(lattr.typtr) then begin
	      stringAssignment := true;
	      gattr.typtr := stringptr;
              Gen0t(pc_stk, cgUWord);
              GenLdcLong(-1);
              Gen0t(pc_stk, cgULong);
              Gen0t(pc_bno, cgULong);
              Gen0t(pc_bno, cgULong);
	      end;
	    end
	  else if IsString(tattr.typtr) then begin
	    if tattr.kind <> expr then begin
              Gen0t(pc_stk, cgULong);
	      Gen1t(pc_ldc, StrLen(tattr.typtr), cgWord);
              Gen0t(pc_stk, cgWord);
              Gen0t(pc_bno, cgWord);
              end; {if}
            Gen0t(pc_bno, cgULong);
            end;

          {do the assignment}
	  if CompTypes(lattr.typtr, gattr.typtr) then begin
	    case lattr.typtr^.form of
	      scalar,subrange: begin
		CheckBnds(lattr.typtr);
		Store(lattr);
		end;
	      pointerStruct, power, objects:
        	Store(lattr);
	      arrays,records:
		if stringAssignment then
		  Gen1(pc_csp,91{mvs})
		else
	          Gen2(pc_mov, long(lattr.typtr^.size).msw,
                    long(lattr.typtr^.size).lsw);
	      files: ;
	      end; {case}
	    if gattr.typtr^.hasSFile then
	      if lattr.typtr^.form <> pointerStruct then
		Error(71);
	    end {if}
	  else if CompObjects(lattr.typtr, gattr.typtr) then
            Store(lattr)
	  else
            Error(54);
	  end {if}
	end {sy = becomes}
      else
	Error(23);
    end; {Assignment}


    procedure GotoStatement;
    {Compile a goto statement}

    label 1;

    var
      llp: lbp;
      ttop: disprange;
      i: integer;
      fcp: ctp;

    begin {GotoStatement}
    if sy = intconst then begin
      ttop := level;
      repeat
	llp := display[ttop].flabel;
	while llp <> nil do
	  with llp^ do
	    if labval = val.ival then begin
	      for i := ttop to level-1 do
                Gen0(pc_prs);
	      if labname >= firstlab then
                Gen1(pc_ujp, labname)
	      else begin
		MakeLab(fcp,labname);
		Gen0Name(pc_ujp, fcp^.name);
		end;
	      if defined then begin
		if lstlevel > stlevel then Error(99)
		else begin
		  for i := 1 to lstlevel-1 do
		    if starray[i] <> lstarray[i] then begin
		      Error(99); goto 1;
		      end;
		  end;
		end
	      else begin
		if ttop<>level then lstlevel := 1
		else if lstlevel = 0 then begin
		  lstlevel := stlevel; lstarray := starray;
		  end
		else begin
		  if lstlevel > stlevel then lstlevel := stlevel;
		  for i := 1 to lstlevel do
		    if lstarray[i] <> starray[i] then begin
		      lstlevel := i; goto 1;
		      end;
		  end;
		end;
	      goto 1;
	      end
	    else llp := nextlab;
	ttop := ttop-1;
      until ttop = 0;
      Error(89);
1:    InSymbol
      end
    else Error(15)
    end; {GotoStatement}
 
    procedure StartStruct;

    begin {StartStruct}
    if stlevel < maxgoto then starray[stlevel] := starray[stlevel]+1;
    stlevel := stlevel+1;
    end; {StartStruct}

    procedure EndStruct;

    begin {EndStruct}
    if stlevel < maxgoto then starray[stlevel] := 0;
    stlevel := stlevel-1;
    end; {EndStruct}

    procedure CompoundStatement;
    {compile a compound statement}

    var
      test: boolean;

    begin {CompoundStatement}
    StartStruct;
    repeat
      repeat
	Statement(fsys + [semicolon,endsy],fprocp,stlevel,starray);
      until not (sy in statbegsys);
      test := sy <> semicolon;
      if not test then InSymbol
    until test;
    Match(endsy,13); EndStruct;
    end; {CompoundStatement}
 
    procedure IfStatement;

    var
      lcix1,lcix2: integer;

    begin {IfStatement}
    Expression(fsys + [thensy],fprocp);
    lcix1 := GenLabel;
    checkbool;
    Gen1(pc_fjp, lcix1);
    Match(thensy,24);
    StartStruct;
    Statement(fsys + [elsesy],fprocp,stlevel,starray);
    EndStruct;
    if sy = elsesy then begin
      lcix2 := GenLabel;
      Gen1(pc_ujp, lcix2);
      Gen1(dc_lab, lcix1);
      InSymbol; StartStruct;
      Statement(fsys,fprocp,stlevel,starray);
      EndStruct;
      Gen1(dc_lab, lcix2)
      end
    else
      Gen1(dc_lab, lcix1)
    end {IfStatement} ;
 
    procedure CaseStatement;
    {compile a case statement}

    label 1;

    const
      sparse = 5;			{label to tableSize ratio for sparse table}

    var
      foundlab: boolean; 		{was a label found?}
      fstptr,lpt1,lpt2,lpt3: cip;
      isotherwise: boolean;		{was the last label 'otherwise'?}
      laddr, lcix, lcix1: integer;
      lcount: unsigned;			{number of case labels}
      lmin, lmax: integer;		{low, high case label}
      llb: unsigned;			{used to allocate temporary space}
      lsp,lsp1: stp;
      lval: valu;
      otherlab: unsigned;		{otherwise label number}
      test: boolean;

    begin {CaseStatement}
    {evaluate the case expression}
    otherlab := 0;
    Expression(fsys + [ofsy,comma,colon],fprocp);
    Load;
    llb := GetTemp(intsize);
    Gen3t(pc_str, llb, 0, 0, cgWord);
    lcix := GenLabel;
    lsp := gattr.typtr;
    if lsp <> nil then
      if (lsp^.form <> scalar) or IsReal(lsp) then begin
	Error(69);
	lsp := nil;
	end; {if}
    Gen1(pc_ujp, lcix);
    Match(ofsy,8);
    fstptr := nil;
    laddr := GenLabel;

    {collect the labeled statements}
    lmax := -maxint;
    lcount := 0;
    repeat
      StartStruct;
      lpt3 := nil;
      lcix1 := GenLabel;
      foundlab := false;
      if not(sy in [semicolon,endsy]) then begin
	repeat
	  if sy = otherwisesy then begin
	    if otherlab <> 0 then
	      Error(80)
	    else begin
	      foundlab := true;
	      otherlab := lcix1;
	      end;
	    InSymbol;
	    isotherwise := true;
	    end {if}
	  else begin
	    isotherwise := false;
	    DoConstant(fsys + [comma,colon],lsp1,lval);
	    if lval.ival > lmax then
              lmax := lval.ival;
	    if lsp <> nil then
	      if CompTypes(lsp,lsp1) then begin
		lpt1 := fstptr;
		lpt2 := nil;
		while lpt1 <> nil do
		  with lpt1^ do begin
		    if cslab >= lval.ival then begin
		      if cslab = lval.ival then
                        Error(80);
		      goto 1;
		      end; {if}
		    lpt2 := lpt1;
		    lpt1 := next;
		    end; {with}
1:		lpt3 := pointer(Malloc(sizeof(caseInfo)));
		foundlab := true;
		with lpt3^ do begin
		  next := lpt1;
		  cslab := lval.ival;
		  csstart := lcix1;
		  end; {with}
                lcount := lcount+1;
		if lpt2 = nil then
                  fstptr := lpt3
		else
                  lpt2^.next := lpt3
		end {if}
	      else
		Error(72);
	    end;
	  test := sy <> comma;
	  if not test then InSymbol;
	until test;
	if sy = colon then
	  InSymbol
	else if not isotherwise then
	  Error(5);
	Gen1(dc_lab, lcix1);
	repeat
	  Statement(fsys + [semicolon],fprocp,stlevel,starray);
	until not (sy in statbegsys);
	if foundlab then
          Gen1(pc_ujp, laddr);
	end;
      test := sy <> semicolon;
      if not test then InSymbol;
      EndStruct;
    until test;

    {generate the branch code}
    Gen1(dc_lab, lcix);
    if fstptr <> nil then begin		{if there are labels...}
      lmin := fstptr^.cslab;
      if (ord4(lmax) - lmin) div lcount > sparse then begin

        {use if-else for sparse case statements}
        while fstptr <> nil do begin
          Gen1t(pc_ldc, fstptr^.cslab, cgWord);
          Gen3t(pc_lod, llb, 0, 0, cgWord);
          Gen0t(pc_equ, cgWord);
          Gen1(pc_tjp, fstptr^.csstart);
          fstptr := fstptr^.next;
          end; {while}
        {handle untrapped values}
        if otherlab <> 0 then
          Gen1(pc_ujp, otherlab)
        else begin
          Gen0(pc_nop);
	  Gen1tName(pc_cup, 0, cgVoid, @'~XJPERROR');
          end; {if}
        end {if}
      else begin

        {use a jump table for compact case statements}
	Gen3t(pc_lod, llb, 0, 0, cgWord); {do the indexed jump}
	Gen1t(pc_dec, lmin, cgWord);
	Gen1(pc_xjp, lmax-lmin+1);
	repeat				{generate the jump table}
	  with fstptr^ do begin
	    while cslab > lmin do begin	{generate default labels for gaps in   }
	      Gen1(pc_add, otherlab);	{ the table			       }
	      lmin := lmin+1;
	      end; {while}
	    Gen1(pc_add, csstart);	{generate an entry for a label that    }
	    fstptr := next;		{was specified			       }
	    lmin := lmin+1;
	    end; {with}
	until fstptr = nil;
	Gen1(pc_add, otherlab);		{generate a label for overflows}
        end; {else}

      Gen1(dc_lab, laddr);		{for branching around the table}
      end; {if}
    Match(endsy,13);
    FreeTemp(llb, intsize);		{free the temp label}
    end; {CaseStatement}
 
    procedure RepeatStatement;

    var
      laddr: integer;

    begin {RepeatStatement}
    laddr := GenLabel;
    Gen1(dc_lab, laddr);
    StartStruct;
    repeat
      Statement(fsys + [semicolon,untilsy],fprocp,stlevel,starray);
      if sy in statbegsys then Error(14)
    until not(sy in statbegsys);
    while sy = semicolon do
      begin InSymbol;
      repeat
	Statement(fsys + [semicolon,untilsy],fprocp,stlevel,starray);
	if sy in statbegsys then Error(14)
      until not (sy in statbegsys);
      end;
    Match(untilsy,25);
    Expression(fsys,fprocp);
    checkbool;
    Gen1(pc_fjp, laddr);
    EndStruct;
    end {RepeatStatement} ;
 
    procedure WhileStatement;

    var
      laddr, lcix: integer;

    begin {WhileStatement}
    laddr := GenLabel;
    Gen1(dc_lab, laddr);
    StartStruct;
    Expression(fsys + [dosy],fprocp);
    lcix := GenLabel;
    checkbool;
    Gen1(pc_fjp, lcix);
    Match(dosy,26);
    Statement(fsys,fprocp,stlevel,starray);
    Gen1(pc_ujp, laddr);
    Gen1(dc_lab, lcix);
    EndStruct;
    end; {WhileStatement}
 
    procedure ForStatement;
    {compile a for loop}

    var
      firstExpr: boolean;		{was the first thing an expression?}
      lattr,lattr2: attr;		{local attributes for start, stop}
      ldattr: attr;			{lattr without subranges removed}
      lsy: symbol;			{preserve symbol past InSymbol call}
      lab1, lab2: integer;		{top, bottom labels}
      llb,llb2: unsigned;		{used to allocate temporary space}
      llb1Used,llb2Used: boolean;	{was work space used?}
      lcp,cvlcp: ctp;			{temp ptr to identifier}
      sattr: attr;			{attr for start expr}
      isunsigned: boolean;		{is the loop variable unsigned?}

      startConst,endConst: boolean;	{are start,stop points constant?}
      startVal,endVal: integer;		{ if so, these are the values}


    begin {ForStatement}
    {no work space reserved yet}
    llb1Used := false;
    llb2Used := false;
    firstExpr := false;

    {set up the top and bottom loop points}
    lab1 := GenLabel;
    lab2 := GenLabel;

    {set up a default control variable}
    with lattr do begin
      typtr := nil;
      isPacked := false;
      kind := varbl;
      aName := pointer(ord4(@'  ')+1);
      access := drct;
      vlevel := level;
      dpdisp := 0;
      end;

    {find and check the control variable}
    isunsigned := false;
    if sy = ident then begin
      SearchId([varsm],lcp);
      if lcp <> nil then
         if lcp^.idtype <> nil then
            if lcp^.idtype^.form = subrange then
               isunsigned := lcp^.idtype^.min >= 0;
      with lattr do begin
        isPacked := false;
	kind := varbl;
	with lcp^ do begin
	  typtr := idtype;
	  if vcontvar or vrestrict then
            Error(97);
	  {prohibit use of this var as a control var}
	  vcontvar := true;
	  if vkind = actual then
	    if vlev = level then begin
	      access := drct;
	      aname := name;
	      vlevel := level;
              dpdisp := 0;
	      if level <> 1 then
                dplab := vlabel;
	      end
	    else begin
	      Error(79);
	      typtr := nil;
	      end
	  else begin
	    Error(95);
	    typtr := nil;
	    end;{else}
	  end; {with}
	end; {with}
      cvlcp := lcp;
      ldattr := lattr;
      if lattr.typtr <> nil then
	if (lattr.typtr^.form > subrange)
	  or CompTypes(realptr,lattr.typtr)
	  or CompTypes(longptr,lattr.typtr) then begin
	  Error(68);
	  lattr.typtr := nil;
	  end;
      InSymbol;
      end
    else begin
      Error(2);
      Skip(fsys + [becomes,tosy,downtosy,dosy]);
      end;
    {evaluate the start value for the loop}
    if sy = becomes then begin
      InSymbol;
      Expression(fsys + [tosy,downtosy,dosy],fprocp);
      if gattr.typtr <> nil then begin
	if gattr.typtr^.form = subrange then
	  gattr.typtr := gattr.typtr^.rangetype;
	if gattr.typtr^.form <> scalar then
          Error(69)
	else if CompTypes(lattr.typtr,gattr.typtr) then begin
	  lattr2 := lattr;
	  if gattr.kind = cst then begin
	    startConst := true;
	    startVal := gattr.cval.ival;
	    end {if}
	  else begin
	    startConst := false;
	    with gattr do
	      if (kind = expr) or ((kind = varbl) and (access <> drct)) then
		begin
		Load;
		llb := GetTemp(intsize);
		llb1Used := true;
		Gen3t(pc_str, llb, 0, 0, cgWord);
                isPacked := false;
		kind := varbl;
		access := drct;
		vlevel := level;
		dplab := llb;
		firstExpr := true;
		end; {with}
	    end; {else}
	  sattr := gattr;
	  end {else if}
	else
          Error(70);
	end; {if}
      {evaluate the loop condition and stop point}
      if sy in [tosy,downtosy] then begin
	lsy := sy;
	InSymbol;
	Expression(fsys + [dosy],fprocp);
	if gattr.typtr <> nil then begin
	  if gattr.typtr^.form = subrange then
	    gattr.typtr := gattr.typtr^.rangetype;
	  if gattr.typtr^.form <> scalar then
            Error(69)
	  else if CompTypes(lattr.typtr,gattr.typtr) then begin
	    if gattr.kind = cst then begin
	      endConst := true;
	      endVal := gattr.cval.ival;
	      end
	    else begin
	      endConst := false;
	      Load;
	      {make room for the end value on the stack frame}
	      llb2 := GetTemp(intsize);
	      llb2Used := true;
	      Gen3t(pc_str, llb2, 0, 0, cgWord);
	      end;
	    {initialize the loop variable}
	    gattr := sattr;
	    if firstExpr then
	      Gen3t(pc_lod, gattr.dplab, 0, 0, cgWord)
	    else
	      Load;
	    Store(lattr);
	    if (not startConst) or (not endConst) then begin
	      {check for a skip of the entire body}
	      gattr := ldattr;
	      Load;
	      if endConst then
		Gen1t(pc_ldc, endVal, cgWord)
	      else
	        Gen3t(pc_lod, llb2, 0, 0, cgWord);
	      if lsy = downtosy then
                if isunsigned then
                   Gen0t(pc_geq, cgUWord)
                else
                   Gen0t(pc_geq, cgWord)
              else
                if isunsigned then
                  Gen0t(pc_leq, cgUWord)
		else
                  Gen0t(pc_leq, cgWord);
	      Gen1(pc_fjp, lab2);
	      end {if}
	    else if lsy = tosy then begin
	      if endVal < startVal then
		Gen1(pc_ujp, lab2);
	      end {else if}
	    else
	      if endVal > startVal then
		Gen1(pc_ujp, lab2);
	    Gen1(dc_lab, lab1);
	    end {else if}
	  else
            Error(70);
	  end {if}
	end
      else begin
	Error(27);
	Skip(fsys + [dosy]);
	end; {else}
      {must find the closing do}
      Match(dosy,26);
      {compile the body of the loop}
      StartStruct;
      Statement(fsys,fprocp,stlevel,starray);
      EndStruct;
      if endConst then begin
	{handle a constant stop condition}
	{update the control var}
	gattr := lattr;
	Load;
	if lsy = tosy then
          Gen1t(pc_inc, 1, cgWord)
	else
          Gen1t(pc_dec, 1, cgWord);
	Store(lattr);
	{branch if not done}
	gattr := lattr;
	Load;
	if lsy = tosy then
	  Gen1t(pc_ldc, endVal+1, cgWord)
	else
	  Gen1t(pc_ldc, endVal-1, cgWord);
	Gen0t(pc_equ, cgWord);
	Gen1(pc_fjp, lab1);
	end
      else begin
	{handle a constant end condition}
	{branch if done}
	gattr := lattr;
	Load;
	Gen3t(pc_lod, llb2, 0, 0, cgWord);
	Gen0t(pc_neq, cgWord);
	Gen1(pc_fjp, lab2);
	{update the control var}
	gattr := lattr;
	Load;
	if lsy = tosy then
          Gen1t(pc_inc, 1, cgWord)
	else
          Gen1t(pc_dec, 1, cgWord);
	Store(lattr);
	{back to the top}
	Gen1(pc_ujp, lab1);
	end;
      Gen1(dc_lab, lab2);
      {remove the end value's space from the used part of the stack frame}
      if llb1Used then
        FreeTemp(llb, intsize);
      if llb2Used then
        FreeTemp(llb2, intsize);
      {allow reuse of this var as a control var}
      cvlcp^.vcontvar := false;
      end
    else begin
      Error(23);
      Skip(fsys + [semicolon]);
      end;
    end; {ForStatement}
 
    procedure WithStatement;
    {compile the with statement}

    var
      form: structform;			{kind of with (records or objects)}
      isMethod: boolean;		{dummy for selector call}
      lcp: ctp;
      llb: unsigned;			{for reserving work space}
      llbUsed: boolean;			{was llc used?}
      name: pStringPtr;			{name of the record being with-ed}
      test: boolean;			{test for loop termination}
      len: integer;			{string length}
      oldtop: integer;			{old top value}

    begin {WithStatement}
    llbUsed := false;
    oldtop := top;
    repeat
      if sy = ident then begin
        len := ord(id[0])+2;
        name := pointer(Malloc(len));
	CopyString(name^,id,len);
	SearchId([varsm,field],lcp);
	InSymbol;
	end
      else begin
	Error(2);
	lcp := uvarptr;
	name := nil;
	end;
      Selector(fsys + [comma,dosy], lcp, fprocp, isMethod);
      if gattr.typtr <> nil then begin
        form := gattr.typtr^.form;
	if form in [records,objects] then
	  if top < displimit then begin
	    top := top+1;
	    with display[top] do begin
	      cname := pointer(ord4(@'  ')+1);
              if form = records then
		fname := gattr.typtr^.fstfld
              else
		fname := gattr.typtr^.objfld;
	      flabel := nil;
	      ispacked := gattr.typtr^.ispacked = pkpacked;
	      end; {with}
	    if (gattr.access = drct) and (form = records) then
	      with display[top] do begin
		occur := crec;
		labsused := nil;
		clev := gattr.vlevel;
		if display[disx].occur = crec then
		  cname := display[disx].cname
		else
		  cname := name;
		name := nil;
		cdspl := gattr.dpdisp;
		clab := gattr.dplab;
		end
	    else begin
              if gattr.access = drct {and (form = objects)} then
                Load
              else
	        LoadAddress;
	      llb := GetTemp(ptrsize);
	      llbUsed := true;
	      if level <= 1 then
		Gen3t(pc_str, llb, 0, level-1, cgULong)
	      else
		Gen3t(pc_str, llb, 0, 0, cgULong);
	      with display[top] do begin
		labsused := nil;
		occur := vrec;
		vdsplab := llb;
		end; {with}
	      end; {else}
	    end {if}
	  else
            Error(107)
	else
          Error(65);
        end; {if}
      test := sy <> comma;
      if not test then
        InSymbol;
    until test;
    Match(dosy,26);
    StartStruct;
    Statement(fsys,fprocp,stlevel,starray);
    EndStruct;
    if llbUsed then
      FreeTemp(llb, ptrsize);
    top := oldtop;
    end; {WithStatement}


  begin {Statement}
  if sy = intconst then begin
    {define a label for gotos}
    llp := display[level].flabel;
    while llp <> nil do
      with llp^ do
	if labval = val.ival then begin
	  if defined then Error(87);
	  if labname > firstlab then
            Gen1(dc_lab, labname)
	  else begin
	    MakeLab(fcp,labname);
	    Gen0name(dc_lab, fcp^.name);
	    end;
	  defined := true;
	  if lstlevel <> 0 then
	    if stlevel > lstlevel then Error(99)
	    else
	      for i := 1 to stlevel-1 do
		if starray[i] <> lstarray[i] then begin
		  Error(99);
		  goto 1;
		  end;
	  lstlevel := stlevel;
	  lstarray := starray;
	  goto 1;
	  end
	else llp := nextlab;
    Error(89);
1:  InSymbol; Match(colon,5);
    end;
  if not (sy in fsys + [ident]) then begin
    Error(6);
    Skip(fsys);
    end;

  {if trace names are enabled and a line # is due, generate it}
  if debugFlag or traceBack then
    if lastline<>linecount then
      if namFound then begin
	lastline := linecount;
	Gen2(pc_lnm, linecount, ord(debugType));
	end;
  if sy in statbegsys + [ident] then begin
    case sy of
      beginsy:	   begin InSymbol; CompoundStatement; end;
      gotosy:	   begin InSymbol; GotoStatement; end;
      ifsy:	   begin InSymbol; IfStatement; end;
      casesy:	   begin InSymbol; CaseStatement; end;
      whilesy:	   begin InSymbol; WhileStatement; end;
      repeatsy:    begin InSymbol; RepeatStatement; end;
      forsy:	   begin InSymbol; ForStatement; end;
      withsy:	   begin InSymbol; WithStatement; end;
      inheritedsy: begin InSymbol; InheritedCall(fsys, fprocp); end;
      ident:	   begin
		   SearchId([varsm,field,func,proc], lcp);
		   InSymbol;
		   if lcp^.klass = proc then
                     Call(fsys, lcp, fprocp)
		   else
                     Assignment(lcp);
		   end;
      end;
    {if the string heap was used, purge it}
    if stringHeap then begin
      stringHeap := false;
      Gen0(pc_nop);
      Gen1(pc_csp,92{dsh});
      end;
    {make sure the next token is legal}
    if not (sy in [semicolon,endsy,elsesy,untilsy]) then begin
      Error(6);
      Skip(fsys);
      end;
    end;        
  end; {Statement}
 
  procedure Body (fsys: setofsys; fprocp: ctp);

  { Compile the body of a procedure, function or program	}
  {								}
  { parameters:							}
  {    fsys - follow symbols					}
  {    fprocp - identifier for program or program-level		}
  {       subroutine contining this statement			}
  
  var
    llcp: ctp;
    saveId: pStringPtr;			{program identifier name}
    i: integer;
    llbl: unsigned;
    lcp: ctp;
    llp: lbp;
    fcp: csp;
    fsp: stp;
    plabel: unsigned;			{largest parameter label number}
    size: unsigned;			{temp size}
    stlevel: integer;
    starray: starrtype;
    test: boolean;
    hasFiles: boolean;			{are there any files in the block?}

    procedure GenLocals (lcp: ctp; pLab: unsigned);

    { define non-array global variables				}
    {								}
    { parameters:						}
    {   lcp - symbol table node					}
    {   pLab - largest parameter label				}

    begin {GenLocals}
    if lcp <> nil then
      with lcp^ do begin
	GenLocals(rlink, pLab);
	GenLocals(llink, pLab);
	if klass = varsm then
          if vlabel > pLab then 
            Gen2(dc_loc, vlabel, long(idtype^.size).lsw);
	end; {with}
    end; {GenLocals}


    procedure OpenFiles (lcp: ctp);

    { open all files in the block				}
    {								}
    { parameters:						}
    {   lcp - symbol table node					}
    
    begin {OpenFiles}
    if lcp <> nil then
      with lcp^ do begin
	OpenFiles(rlink);
	OpenFiles(llink);
	if hasIFile then
	  if klass = varsm then begin
	    hasFiles := true;
	    Gen1t(pc_ldc, ord(idtype^.size), cgUWord);
            Gen0t(pc_stk, cgWord);
	    with gattr do begin
	      typtr := idtype;
	      access := drct;
              isPacked := false;
	      kind := varbl;
	      vlevel := vlev;
              dpdisp := 0;
	      if vlev <> 1 then
                dplab := vlabel;
	      aname := name;
	      end; {with}
	    LoadAddress;
            Gen0t(pc_stk, cgULong);
            Gen0t(pc_bno, cgULong);
	    Gen1(pc_csp,35{clr});
	    end; {if}
      end; {with}
    end; {OpenFiles}


    procedure WithSelf;

    { Fake a "with self do begin" for methods			}

    var
      form: structform;			{kind of with (records or objects)}
      lid: pString;			{copy of id}
      lcp: ctp;				{object type}

    begin {WithSelf}
    lid := id;
    id := 'SELF';
    SearchId([varsm,field],lcp);
    if lcp <> nil then
      if lcp^.idtype <> nil then begin
	form := lcp^.idtype^.form;
	if form in [records,objects] then
	  if top < displimit then begin
	    top := top+1;
	    with display[top] do begin
	      isPacked := lcp^.idtype^.ispacked = pkpacked;
	      labsused := nil;
              if form = records then
		fname := lcp^.idtype^.fstfld
              else
		fname := lcp^.idtype^.objfld;
	      flabel := nil;
              occur := vrec;
              vdsplab := lcp^.vlabel;
	      end; {with}
	    end {if}
	  else
            Error(107)
	else
          Error(65);
	end; {if}
    id := lid;
    end; {WithSelf}


  begin {Body}
  namFound := false;			{turn line #s off}
  for stlevel := 1 to maxgoto do
    starray[stlevel] := 0;
  stlevel := 1;
  if level = 1 {program block} then begin
    Gen2Name(dc_str, $4000+$8000*ord(isDynamic), 0, fprocp^.name);
    inseg := true;
    end
  else if level = 2 {entry of level 1 procedure} then
    Gen0(dc_pin)
  else {imbeded procedure}
    Gen1(dc_lab, fprocp^.pfname);
  Gen1Name(pc_ent, 0, fprocp^.name); {create a stack frame}

  ResetTemp;				{forget old temporary variables}

  lcp := fprocp^.pfparms;		{generate code for passed parameters}
  plabel := 0;
  while lcp <> nil do
    with lcp^ do begin
      if klass = varsm then begin
	if idtype <> nil then
	  if idtype^.form > power then begin
            {handle variables always passed as pointers}
	    if vkind = actual then begin
	      if (idtype^.form = records) and (idtype^.size <= 4) then begin
                {short records are passed by value}
		if idtype^.size <= 2 then
		  size := 2
		else
                  size := 4;
		psize := psize-size;
                Gen3(dc_prm, vlabel, size, psize);
		end {if}
              else if idtype^.form = objects then begin
	        psize := psize-ptrsize;
                Gen3(dc_prm, vlabel, ptrsize, psize);
                end {else if}
              else begin
	        psize := psize-ptrsize;
                size := long(idtype^.size).lsw;
                Gen3(dc_prm, vlabel-1, ptrsize, psize);
                Gen2(dc_loc, vlabel, size);
		Gen3(pc_lda, vlabel, 0, 0);
		Gen3t(pc_lod, vlabel-1, 0, 0, cgULong);
		Gen2(pc_mov, 0, size);
                end; {else}
	      end {if}
            else begin
	      psize := psize-ptrsize;
              Gen3(dc_prm, vlabel, ptrsize, psize);
              end; {else}
	    end {else if}
	  else if vkind = actual then begin
	    if IsReal(idtype) then begin
	      psize := psize-extSize;
              Gen3(dc_prm, vlabel, extSize, psize);
              if GetType(idtype, false) <> cgExtended then
	        Gen1t(pc_fix, vlabel, GetType(idtype, false));
	      end
	    else if idtype = byteptr then begin
	      psize := psize-intSize;
              Gen3(dc_prm, vlabel, intSize, psize);
              end {else if}
	    else begin
              size := long(idtype^.size).lsw;
	      psize := psize-size;
              Gen3(dc_prm, vlabel, size, psize);
              end; {else}
	    end
	  else begin
	    psize := psize-ptrsize;
            Gen3(dc_prm, vlabel, ptrsize, psize);
            end; {else}
	if vlabel > plabel then
          plabel := vlabel;
	end {if}
      else if klass in [proc,func] then begin
	psize := psize-procsize;
        Gen3(dc_prm, pflabel, procsize, psize);
	if pflabel > plabel then
          plabel := pflabel;
        end; {else if}
      lcp := lcp^.next;                      
      end; {with}
  if fprocp^.klass = func then begin	{generate the function label}
    case GetType(fprocp^.idtype, false) of
      cgByte,cgUByte,
      cgWord,cgUWord:   size := cgWordSize;
      cgLong,cgULong:   size := cgLongSize;
      cgReal:           size := cgRealSize;
      cgDouble:         size := cgDoubleSize;
      cgComp:           size := cgCompSize;
      cgExtended:       size := cgExtendedSize;
      otherwise:	size := 0;
      end; {case}     
    Gen2(dc_fun, fprocp^.pflabel, size);
    if fprocp^.pflabel > plabel then
      plabel := fprocp^.pflabel;
    end; {if}
  if level <> 1 then			{generate space for local variables}
     GenLocals(display[top].fname, plabel);

					{record the current procedure name}
  if debugFlag or profileFlag or traceBack then begin
    fcp := pointer(Malloc(sizeof(constantRec)));
    with fcp^ do begin
      cclass := strg;
      sval := fprocp^.name^;
      end; {with}
    GenPS(pc_nam, fprocp^.pfoname);
    namFound := true; {turn line #s on}
    end; {if}
					{give the symbol table to the code }
					{ generator.			   }
  if debugFlag then
    Gen1Name(dc_sym, 0, pointer(display[top].fname));
  if fprocp^.klass = prog then begin
    new(saveId);
    saveId^ := id;
    while fextfilep <> nil do begin
      with fextfilep^ do
	if not ((CompNames(filename^,inputid) = 0) or
	  (CompNames(filename^,outputid) = 0) or
	  (CompNames(filename^,erroroutputid) = 0)) then begin
	  id := filename^;
	  SearchSection(display[1].fname,llcp);
	  if llcp = nil then begin
	    write('**** Undeclared external variable: ', filename^);
	    FlagError;
	    end
	  else if llcp^.klass in [proc,func] then begin
	    write('**** External variable cannot be procedure or function: ',
               filename^);
	    FlagError;
	    end;
	  end;
      fextfilep := fextfilep^.nextfile;
      end;
    id := saveId^;
    dispose(saveId);
    end;
  if isMethod then			{do "with self do begin"}
    WithSelf;
  hasFiles := false;			{initialize all file variables}
  OpenFiles(display[top].fname);
  if hasFiles then begin
    {create a new file record level}
    Gen0(pc_nop);
    Gen1(pc_csp,96{orc});
    end;
  repeat				{compile the statements in the body}
    repeat
      Statement(fsys+[semicolon,endsy],fprocp,stlevel,starray);
    until not (sy in statbegsys);
    test := sy <> semicolon;
    if not test then
      InSymbol;
  until test;
  Match(endsy,13);
  llp := display[top].flabel;		{test for undefined labels}
  while llp <> nil do
    with llp^ do begin
      if not defined then begin
	write('**** undefined label: ',labval:1);
	FlagError;
	end;
      llp := nextlab;
      end;
  if hasFiles then begin		{close all files opened in this block}
    Gen0(pc_nop);
    Gen1(pc_csp,97{crc});
    end;
  if fprocp^.klass <> func then		{return to caller}
    Gen0t(pc_ret, cgVoid)
  else
    Gen0t(pc_ret, GetType(fprocp^.idtype, false));
  if level <= 2 then begin		{finish the segment}
    Gen0(dc_enp);
    intlabel := firstlab;
    inseg := false;
    if fprocp^.klass in [proc,func] then begin
      release(fprocp^.pfmark);
      code := pointer(Calloc(sizeof(intermediate_code)));
      end;
    end;
  if isMethod then			{do "end" for "with self do begin"}
    top := top-1;
  end; {Body}
 
  procedure DoBlock {fsys: setofsys; fsy: symbol; fprocp: ctp;
     isProgram: boolean};
  {compile a block}

  label 1;

  const
    returnSize = 3;			{size of a return address}

  var
    actuallc: addrrange; 		{used when updating actual parm locs}
    lsy: symbol; 			{temp symbol}
    foundBody: boolean;			{dummy var for ProcDeclaration}
    lisMethod: boolean;			{copy of isMethod}
    lcp: ctp;				{work pointer}
    procName: pStringPtr;		{name of proc being compiled}


    procedure CheckForw(lcp: ctp);

    begin {CheckForw}
    if lcp<>nil then with lcp^ do begin
      CheckForw(rlink);
      CheckForw(llink);
      if (klass in [proc,func]) and (pfkind = actual) then
	if pfdirective = drforw then begin
	  write('**** forward ref not resolved: ', name^);
	  FlagError;
	  end;
      end;
    end; {CheckForw}


    function ShouldBeCompiled(fsy: symbol): boolean;
    {check to see if a level 1 proc should be compiled; skip if not}

    var
      foundBody: boolean;		{did the proc have a body}
      llist: boolean;			{local list flag}


      function InPartialList(var name: pString): boolean;

      { see if a name is in the partial compile list		}
      {								}
      { parameters:						}
      {    name - name to check					}
      {								}
      { returns: True if the name is in the list, else false	}
      {								}
      { Note: name is var to save space - it is not changed	}

      label 1;

      var
	ptr,lptr: partialptr;

      begin {InPartialList}
      InPartialList := true;
      ptr := partialList;
      lptr := nil;
      while ptr <> nil do begin
	with ptr^ do
	  if CompNames(name, pname^) = 0 then goto 1;
	lptr := ptr;
	ptr := ptr^.next;
	end; {while}
      InPartialList := false;
      1:
      end; {InPartialList}


      procedure SkipProc;
      {skip a procedure or function}

      var
	cnt: integer;			{# ends needed}
	lcp: ctp;			{work pointer for skipping forwards}

      begin {SkipProc}
      {skip to the first function or procedure, or the body}
      while (not eofl) and (not(sy in [beginsy,procsy,funcsy])) do
	InSymbol;
      {skip all of the procedure and function declarations}
      while sy in [procsy,funcsy] do begin
	{skip to the parameter list or the end of the header}
	while (not eofl) and (not (sy in [lparent,semicolon])) do InSymbol;
	{if there is a header, skip it}
	if sy = lparent then begin
	  InSymbol;
	  cnt := 1;
	  while (cnt > 0) and (not eofl) do begin
	    if sy = lparent then cnt := cnt+1
	    else if sy = rparent then cnt := cnt-1;
	    InSymbol;
	    end;
	  end;
	{skip the function return type, if any}
	while (sy <> semicolon) and (not eofl) do InSymbol;
	InSymbol;
	{if the declaration has no block, skip the identifiers (forward, etc)}
	if sy = ident then begin
	  SearchId([directive],lcp);
	  InSymbol;
	  if sy = lparent then begin
	    while (sy <> rparent) and (not eofl) do InSymbol;
	    InSymbol;
	    end;
	  Match(semicolon,14);
	  end
	{for procedures with a block, skip it here}
	else
	  SkipProc;
	end;
      {skip the body}
      Match(beginsy,17);
      cnt := 1;
      while (cnt > 0) and (not eofl) do begin
	if sy in [beginsy,casesy] then
	  cnt := cnt+1
	else if sy = endsy then
	  cnt := cnt-1;
	InSymbol;
	end;
      Match(semicolon,14);
      end; {SkipProc}

    begin {ShouldBeCompiled}
    if InPartialList(id) then
      ShouldBeCompiled := true
    else begin
      ShouldBeCompiled := false;
      {compile the header}
      ProcDeclaration(fsy, fsys, false, false, foundBody);
      {if there is a body, skip it}
      if foundBody then begin
	llist := list;
	list := false;
	SkipProc;
	list := llist;
	end;
      end;
    end; {ShouldBeCompiled}


    procedure Remove(var name: pString);

    { remove a name from the partial compile list		}
    {								}
    { parameters:						}
    {    name - name to remove					}
    {								}
    { Note: name is var to save space - it is not changed	}

    label 1;

    var
      ptr,lptr: partialptr;

    begin {Remove}
    ptr := partialList;
    lptr := nil;
    while ptr <> nil do begin
      with ptr^ do
	if CompNames(name,pname^) = 0 then begin
	  if lptr = nil then
	    partialList := next
	  else
	    lptr^.next := next;
	  goto 1;
	  end; {if}
      lptr := ptr;
      ptr := ptr^.next;
      end; {while}
    1:
    end; {Remove}


  begin {DoBlock}
  {save the methods object, if any}
  lisMethod := isMethod;

  {handle declarations}
  repeat
    while sy = usessy do begin
      InSymbol;
      UsesDeclaration(fsys);
      end; {while}
    if sy = labelsy then begin
      InSymbol;
      LabelDeclaration(fsys);
      if isProgram then
	noGlobalLabels := false;
      end; {if}
    if sy = constsy then begin
      InSymbol;
      ConstDeclaration(fsys);
      end; {if}
    if sy = typesy then begin
      InSymbol;
      TypeDeclaration(fsys);
      end; {if}
    if sy = varsy then begin
      InSymbol;
      VarDeclaration(fsys);
      end; {if}
    {handle procedure, function declarations}
    while sy in [procsy,funcsy] do begin
      if level = 1 then
	nextLocalLabel := 1;
      lsy := sy;
      InSymbol;
      new(procName);
      procName^ := id;
      if (level > 1) or (not partial) then
	ProcDeclaration(lsy, fsys, false, true, foundBody)
      else if ShouldBeCompiled(lsy) then begin
	{compile the header}
	ProcDeclaration(lsy, fsys, false, true, foundBody);
	{remove the name from the list of names to compile}
	if foundBody and (not isMethod) then
	  Remove(procName^);
	if partialList = nil then begin
	  eofl := true;
	  sy := period;
	  goto 1;
	  end;
	end;
      dispose(procName);
      end;
    CheckForw(display[top].fname);
    if not ((sy = beginsy) or (doingUnit and (sy = endsy))) then begin
      Error(18);
      Skip(fsys);
      end;
  until (sy in statbegsys) or (doingUnit and (sy = endsy)) or eofl;

  {compile the body of the block}
  if (not doingUnit) or (level > 1) then begin
    if level = 1 then
      nextLocalLabel := 1;
    Match(beginsy,17);                            
    repeat
      isMethod := lisMethod;
      Body(fsys + [casesy],fprocp);
      if sy <> fsy then begin
	Error(6);
	Skip(fsys);
	end;
    until (sy = fsy) or (sy in blockbegsys) or eofl;
    end; {if}
1:
  end; {DoBlock}
 
  procedure Programme{fsys:setofsys};
  {Compile a program}

  var
    fp,extfp,nextfp: extfilep;
    lcp: ctp;
    idname: pStringPtr;			{segment name}
    noStart: boolean;			{has a start been generated?}
    len: integer;			{string length}

    procedure DoGlobals;
    {declare the ~globals and ~arrays segments}

    var
      didone: boolean;			{did we generate at least one label?}

      procedure GenArrays(lcp: ctp);

      { define global arrays					}
      {								}
      { parameters:						}
      {   lcp - stack frame to check for arrays			}

      var
        size: addrrange;		{size of the array}

      begin {GenArrays}
      if lcp <> nil then with lcp^ do begin
	GenArrays(rlink);
	GenArrays(llink);
	if klass = varsm then
	  if idtype^.form in [arrays,records] then
	    if not fromUses then begin
	      if noStart then begin
		idName := @'~ARRAYS';
		if smallMemoryModel then
		  NextSegName('          ')
		else
		  NextSegName('~ARRAYS   ');
		Gen2Name(dc_str, $4000, 1, idname);
		noStart := false;
		end;
	      Gen2Name(dc_glb, 0, ord(vPrivate), name);
              size := idtype^.size;
              while size > maxint do begin
                Gen1(dc_dst, $4000);
                size := size-$4000;
                end; {while}
              Gen1(dc_dst, long(size).lsw);
	      end;
	end;
      end; {GenArrays}

      procedure GenGlobals(lcp: ctp);
      {define non-array global variables}

      begin {GenGlobals}
      if lcp <> nil then with lcp^ do begin
	GenGlobals(rlink);
	GenGlobals(llink);
	if klass = varsm then
	  if not (idtype^.form in [arrays,records]) then
	    if not fromUses then begin
	      Gen2Name(dc_glb, long(idtype^.size).lsw, ord(vPrivate), name);
	      didone := true;
	      end; {if}
	end;
      end; {GenGlobals}

    begin {DoGlobals}
    {declare the ~globals segment, which holds non-array data types}
    idName := @'~GLOBALS';
    if smallMemoryModel then
      NextSegName('          ')
    else
      NextSegName('~GLOBALS  ');
    Gen2Name(dc_str, $4000, 0, idname);
    didone := false;
    GenGlobals(display[1].fname);
    if not didone then
      if not smallMemoryModel then
	Gen2Name(dc_glb, 1{byte}, 1{private}, @'~');
    Gen0(dc_enp);
    {declare the ~arrays segment, which holds global arrays}
    noStart := true;
    GenArrays(display[1].fname);
    if not noStart then
      Gen0(dc_enp);
    end; {DoGlobals}

    procedure InterfacePart;
    {compile the interface part of a unit}

    var
      lsy: symbol;			{temp symbol}
      foundBody: boolean;		{dummy var for ProcDeclaration}
 
    begin {InterfacePart}
    repeat
      {handle declarations}
      while sy = usessy do begin InSymbol; UsesDeclaration(fsys); end;
      if sy = constsy then begin InSymbol; ConstDeclaration(fsys); end;
      if sy = typesy then begin InSymbol; TypeDeclaration(fsys); end;
      if sy = varsy then begin InSymbol; VarDeclaration(fsys); end;
      {handle procedure, function declarations}
      while sy in [procsy,funcsy] do begin
	lsy := sy;
	InSymbol;
	{compile the header}
        nextLocalLabel := 1;
	ProcDeclaration(lsy, fsys+[implementationsy], false, true, foundBody);
	if foundBody then
	  Error(120);
	end;
      if sy <> implementationsy then begin
	Skip([period]);
	InSymbol;
	end;
    until (sy = implementationsy) or eofl;
    end; {InterfacePart}

  begin {Programme}
  progfound := true;
					{create the main program name}
  lcp := pointer(Malloc(sizeof(identifier)));
  with lcp^ do begin
    name := @'~_PASMAIN';
    idtype := nil;
    next := nil;
    klass := prog;
    pfname := 0;
    pfoname := name;
    pfactualsize := 0;
    pfparms := nil;
    hasIFile := false;
    end;
  EnterId(lcp);
  if sy = progsy then begin {compilation of a program}
    if kNameGS.theString.size <> 0 then {start output files}
      CodeGenInit(kNameGS, keepflag, partial);
    InSymbol;
    Match(ident,2);
    {compile the program's parameter list}
    if sy = lparent then begin
      nextfp := nil;
      repeat
	InSymbol;
	if sy = ident then begin
          extfp := pointer(Malloc(sizeof(filerec)));
	  with extfp^ do begin
            len := ord(id[0])+2;
            filename := pointer(Malloc(len));
	    CopyString(filename^,id,len);
	    nextfile := nil;
	    end;
	  fp := fextfilep;
	  while fp <> nil do begin
	    if CompNames(fp^.filename^,id) = 0 then
              Error(30);
	    fp := fp^.nextfile;
	    end;
	  if nextfp <> nil then nextfp^.nextfile := extfp;
	  nextfp := extfp;
	  if fextfilep = nil then fextfilep := extfp;
	  if CompNames(id,inputid) = 0 then noinput := false;
	  if CompNames(id,outputid) = 0 then nooutput := false;
	  if CompNames(id,erroroutputid) = 0 then noerroroutput := false;
	  InSymbol;
	  if not (sy in [comma,rparent]) then Error(20);
	  end
	else Error(2);
      until sy <> comma;
      if sy <> rparent then Error(4);
      InSymbol;
      end;
    Match(semicolon,14);
    {compile the block}
    repeat DoBlock(fsys,period,lcp,true);
      if sy <> period then Error(21);
    until (sy = period) or eofl;
    end
  else begin {compilation of a unit}
    noInput := false;			{allow all I/O}
    noOutput := false;
    noErrorOutput := false;
    doingUnit := true;			{note that this is a unit}
    if kNameGS.theString.size <> 0 then {start output files}
      CodeGenInit(kNameGS, keepflag, partial);
    Match(unitsy,3);			{compile the header}
    Match(ident,2);
    Match(semicolon,14);
    doingInterface := true;		{compile the interface part}
    Match(interfacesy,119);
    InterfacePart;
    doingInterface := false;
    CloseToken;
    Match(implementationsy,118); 	{compile the implementation part}
    DoBlock(fsys,period,lcp,true);
    if not ((sy = period) and eofl) then begin
      Match(endsy,13);
      if sy <> period then begin
        Error(21);
        if allTerm then
          while (errinx <> 0) and (not eofl) do
            InSymbol;
        end; {if}
      end;
    end;
  DoGlobals;				{declare the global variables}
  end; {Programme}
 
{----Initialization-------------------------------------------------------}

  procedure InitScalars;
  {Initialize global scalars}

  var
    i: integer;

  begin {InitScalars}
  level := 0; top := 0;			{set up level 0 frame}
  with display[0] do begin
     fname := nil;
     flabel := nil;
     labsused := nil;
     occur := blck;
     ispacked := false;
     end; {with}
  display[1] := display[0];

  code := pointer(Calloc(sizeof(intermediate_code)));
  {code^.lab := nil;}
  fwptr := nil;
  objptr := nil;
  fextfilep := nil;
  thisType := nil;			{not declaring a type}
  tempList := nil; 			{no temp variables}
  nextLocalLabel := 1;			{reset local label count}
  numerr := 0;				{no errors found}
  errinx := 0;
  intlabel := 0;
  linecount := 0;			{no lines processed}
  lastline := 0;
  firstlab := 0;
  eofl := false; 			{not at end of file}
  iso := false;				{don't enforce iso}
  progfound := false;			{program symbol not found}
  inseg := false;
  debug := false;			{don't generate check code}
  inUses := false;
  stringHeap := false;
  namFound := false;
  isDynamic := false;			{segments are not dynamic}
  isMethod := false;			{not doing a method}
  doingInterface := false;		{not doing interface part}
  doingUnit := false;			{not doing a unit}
  doingCast := false;			{not casting an expression}
  noGlobalLabels := true;		{no program level labels found so far}
  prterr := true;
  noinput := true;
  nooutput := true;
  noerroroutput := true;
  psize := 0;				{no parameters at the program level}
  ch := ' ';
  code^.optype := cgWord;
  gattr.aname := pointer(Malloc(maxCnt+1));

  inputid := 'INPUT';
  outputid := 'OUTPUT';
  erroroutputid := 'ERROROUTPUT';
  end; {InitScalars}
 
  procedure InitSets;
  {initialize structured set constants}

  begin {InitSets}
  constbegsys := [addop,intconst,realconst,stringconst,ident,nilsy,
    longintconst];
  simptypebegsys := [lparent] + constbegsys;
  typebegsys:=[stringsy,arrow,packedsy,arraysy,recordsy,setsy,filesy,objectsy]
    +simptypebegsys;
  typedels := [arraysy,recordsy,setsy,filesy];
  blockbegsys := [labelsy,constsy,typesy,varsy,procsy,funcsy,beginsy];
  selectsys := [arrow,period,lbrack];
  facbegsys := [intconst,realconst,stringconst,ident,lparent,bitnot,
    nilsy,lbrack,notsy,atsy,longintconst,inheritedsy];
  statbegsys := [beginsy,gotosy,ifsy,whilesy,repeatsy,forsy,withsy,casesy,
    inheritedsy];
  end {InitSets};
 
end.
