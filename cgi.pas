{$optimize -1}
{---------------------------------------------------------------}
{								}
{  ORCA Code Generator Interface 				}
{								}
{  This unit serves as the glue code attaching a compiler	}
{  to the code generator.  It provides subroutines in a		}
{  format that is convinient for the compiler during		}
{  semantic analysis, and produces intermediate code records	}
{  as output.  These intermediate code records are then		}
{  passed on to the code generator for optimization and		}
{  native code generation.					}
{								}
{$copy 'cgi.comments'}
{---------------------------------------------------------------}

unit CodeGeneratorInterface;

interface

{$segment 'cg'}
             
{$LibPrefix '0/obj/'}

uses PCommon;

{---------------------------------------------------------------}

const
					{Code Generation}
					{---------------}
   maxLocalLabel =	300;		{max # local variables}
   maxString	=	8000;		{max # chars in string space}

					{Error interface: these constants map  }
					{code generator error numbers into the }
					{numbers used by the compiler's Error  }
					{subroutine.			       }
					{--------------------------------------}
   cge1			=	113;	{compiler error}
   cge2			=	111;	{implementation restriction: too many local labels}
   cge3			=	132;	{implementation restriction: string space exhausted}

					{size of internal types}
					{----------------------}
   cgByteSize		=	1;
   cgWordSize		=	2;
   cgLongSize		=	4;
   cgPointerSize 	=	4;
   cgRealSize		=	4;
   cgDoubleSize		=	8;
   cgCompSize		=	8;
   cgExtendedSize	=      10;

					{token buffer (.int file)}
                                        {------------------------}
					{NOTE: tokenBuffSize also defined in objout.asm}
   tokenBuffSize = 4095;		{size of the token buffer}

type
					{misc}
					{----}
   segNameType = packed array[1..10] of char; {segment name}

					{p code}
					{------}
   pcodes =				{pcode names}
      (pc_adi,pc_adr,pc_and,pc_dvi,pc_dvr,pc_cnn,pc_cnv,pc_ior,pc_mod,pc_mpi,
       pc_mpr,pc_ngi,pc_ngr,pc_not,pc_sbi,pc_sbr,pc_sto,pc_dec,dc_loc,pc_ent,
       pc_fjp,pc_inc,pc_ind,pc_ixa,pc_lao,pc_lca,pc_ldo,pc_mov,pc_ret,pc_sro,
       pc_xjp,pc_cup,pc_equ,pc_geq,pc_grt,pc_lda,pc_ldc,pc_leq,pc_les,pc_lod,
       pc_neq,pc_str,pc_ujp,pc_add,pc_lnm,pc_nam,pc_cui,pc_cum,pc_tjp,dc_lab,
       pc_usr,pc_umi,pc_udi,pc_lla,pc_lsl,pc_lad,pc_uim,dc_enp,pc_stk,dc_glb,
       dc_dst,dc_str,pc_cop,pc_cpo,pc_tl1,pc_tl2,dc_pin,pc_shl,pc_shr,pc_bnd,
       pc_bor,pc_bxr,pc_bnt,pc_bnl,pc_mpl,pc_dvl,pc_mdl,pc_sll,pc_slr,pc_bal,
       pc_ngl,pc_adl,pc_sbl,pc_blr,pc_blx,pc_siz,dc_sym,pc_lnd,pc_lor,pc_vsr,
       pc_uml,pc_udl,pc_ulm,pc_pds,dc_cns,dc_prm,pc_bno,pc_nop,pc_csp,pc_chk,
       pc_abi,pc_abr,pc_abl,pc_sqi,pc_sql,pc_sqr,pc_rnd,pc_rn4,pc_odd,pc_odl,
       pc_at2,pc_sgs,pc_uni,pc_pwr,pc_int,pc_dif,pc_inn,pc_prs,pc_fix,dc_fun,
       pc_sin,pc_cos,pc_exp,pc_sqt,pc_log,pc_atn,pc_tan,pc_acs,pc_asn,pc_vct);

					{intermediate code}
					{-----------------}
   baseTypeEnum = (cgByte,cgUByte,cgWord,cgUWord,cgLong,cgULong,
		   cgReal,cgDouble,cgComp,cgExtended,cgString,cgVoid,
		   cgSet);

   setPtr = ^setRecord;			{set constant}
   setRecord = record
      smax: integer;
      sval: packed array[1..setsize] of char;
      end;

   icptr = ^intermediate_code;
   intermediate_code = record		{intermediate code record}
      opcode: pcodes;			{operation code}
      p,q,r,s: integer;			{operands}
      lab: pStringPtr;			{named label pointer}
      next: icptr;			{ptr to next statement}
      left, right: icptr;		{leaves for trees}
      parents: integer;			{number of parents}
      case optype: baseTypeEnum of
	 cgByte,
	 cgUByte,
	 cgWord,
	 cgUWord 	: (opnd: longint; llab,slab: integer);
	 cgLong,
	 cgULong 	: (lval,lval2: longint);
	 cgReal,
	 cgDouble,
	 cgComp,
	 cgExtended	: (rval: double);
	 cgString	: (str: pStringPtr);
	 cgSet		: (setp: setPtr);
	 cgVoid		: (pval: longint; pstr: pStringPtr);
      end;

					{basic blocks}
					{------------}
   iclist = ^iclistRecord;		{used to form lists of records}
   iclistRecord = record
      next: iclist;
      op: icptr;
      end;

   blockPtr = ^block;			{basic block edges}
   blockListPtr = ^blockListRecord;	{lists of blocks}
   block = record
      last, next: blockPtr;		{for doubly linked list of blocks}
      dfn: integer;			{depth first order index}
      visited: boolean;			{has this node been visited?}
      code: icptr;			{code in the block}
      c_in: iclist;			{list of reaching definitions}
      c_out: iclist;			{valid definitions on exit}
      c_gen: iclist;			{generated definitions}
      dom: blockListPtr; 		{dominators of this block}
      end;

   blockListRecord = record		{lists of blocks}
      next, last: blockListPtr;
      dfn: integer;
      end;

					{65816 native code generation}
					{----------------------------}
   addressingMode = (implied,immediate, {65816 addressing modes}
      longabs,longrelative,relative,absolute,direct,gnrLabel,gnrSpace,
      gnrConstant,genaddress,special,longabsolute);

var
					{misc}
					{----}
   keepflag: integer;			{keep flag}
   currentSegment,defaultSegment: segNameType; {current & default seg names}
   symLength: integer;                  {length of debug symbol table}


					{DAG construction}
					{----------------}
   DAGhead: icPtr;			{1st ic in DAG list}
   DAGblocks: blockPtr;			{list of basic blocks}


					{variables used to control the }
					{quality or characteristics of }
					{code			       }
					{------------------------------}
   cLineOptimize: boolean;		{+o flag set?}
   code: icptr;				{current intermediate code record}
   codeGeneration: boolean;		{is code generation on?}
   commonSubexpression: boolean; 	{do common subexpression removal?}
   debugFlag: boolean;			{generate debugger calls?}
   debugStrFlag: boolean;               {gsbug/niftylist debug names?}
   floatCard: integer;			{0 -> SANE; 1 -> FPE}
   floatSlot: integer;			{FPE slot}
   isDynamic: boolean;			{are segments dynamic?}
   jslOptimizations: boolean;		{do jsl optimizations?}
   loopOptimizations: boolean;		{do loop optimizations?}
   npeephole: boolean;			{do native code peephole optimizations?}
   peephole: boolean;			{do peephole optimization?}
   profileFlag: boolean; 		{generate profiling code?}
   rangeCheck: boolean;			{generate range checks?}
   registers: boolean;			{do register optimizations?}
   saveStack: boolean;			{save, restore caller's stack reg?}
   segmentKind: integer; 		{kind field of segment (ored with start/data)}
   smallMemoryModel: boolean;		{is the small model in use?}
   stackSize: integer;			{amount of stack space to reserve}
   stringsize: 0..maxstring;		{amount of string space left}
   stringspace: packed array[1..maxstring] of char; {string table}
   toolParms: boolean;			{generate tool format paramaters?}
   traceBack: boolean;			{generate traceback code?}

					{current instruction info}
					{------------------------}
   isJSL: boolean;			{is the current opcode a jsl?}

					{desk accessory variables}
					{------------------------}
   isNewDeskAcc: boolean;		{is this a new desk acc?}
   isClassicDeskAcc: boolean;		{is this a classic desk acc?}
   isCDev: boolean;			{is this a control panel device?}
   isNBA: boolean;			{is this a new button action?}
   isXCMD: boolean;			{is this an XCMD?}
   rtl: boolean; 			{return with an rtl?}

   openName,closeName,actionName,	{names of the required procedures}
      initName: pStringPtr;
   refreshPeriod: integer;		{refresh period}
   eventMask: integer;			{event mask}
   menuLine: pString;			{name in menu bar}

					{token buffer (.int file)}
                                        {------------------------}
   tokenDisp: 0..tokenBuffSize;		{disp in token buffer}
   tokenLen: longint;			{size of token buffer}
   tokenHandle: handle;			{token file handle}
   tokenNameGS: gsosOutStringPtr;	{token file name}
   tokenPtr: ptr;			{pointer to active part of token file}

{---------------------------------------------------------------}

procedure CloseToken;

{ close the token file (.int file)				}


procedure CodeGenFini;

{ terminal processing						}


procedure CodeGenInit (keepName: gsosOutStringPtr; keepFlag: integer;
		       partial: boolean);

{ code generator initialization					}
{								}
{ parameters:							}
{	keepName - name of the output file			}
{	keepFlag - keep status:					}
{		0 - don't keep the output                       }
{		1 - create a new object module			}
{		2 - a .root already exists			}
{		3 - at least on .letter file exists		}
{	partial - is this a partial compile?			}


procedure CodeGenScalarInit;

{ initialize codegen scalars					}


procedure DefaultSegName (s: segNameType);

{ set the default segment name					}
{								}
{ parameters:							}
{    s - segment name						}


procedure Gen0 (fop: pcodes);

{ generate an implied operand instruction			}
{								}
{ parameters:							}
{	fop - operation code					}


procedure Gen1 (fop: pcodes; fp2: integer);

{ generate an instruction with one numeric operand		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp2 - operand						}


procedure Gen2 (fop: pcodes; fp1, fp2: integer);

{ generate an instruction with two numeric operands		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}


procedure Gen3 (fop: pcodes; fp1, fp2, fp3: integer);

{ generate an instruction with three numeric operands		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	fp3 - third operand					}


procedure Gen0t (fop: pcodes; tp: baseTypeEnum);

{ generate a typed implied operand instruction			}
{								}
{ parameters:							}
{	fop - operation code					}
{	tp - base type						}


procedure Gen1t (fop: pcodes; fp1: integer; tp: baseTypeEnum);

{ generate a typed instruction with two numeric operands 	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - operand						}
{	tp - base type						}


procedure Gen2t (fop: pcodes; fp1, fp2: integer; tp: baseTypeEnum);

{ generate a typed instruction with two numeric operands 	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	tp - base type						}


procedure Gen3t (fop: pcodes; fp1, fp2, fp3: integer; tp: baseTypeEnum);

{ generate a typed instruction with three numeric operands	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	fp3 - third operand					}
{	tp - base type						}


procedure Gen4t (fop: pcodes; fp1, fp2, fp3, fp4: integer; tp: baseTypeEnum);

{ generate a typed instruction with four numeric operands	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	fp3 - third operand					}
{	fp4 - fourth operand					}
{	tp - base type						}


procedure Gen0Name (fop: pcodes; name: pStringPtr);

{ generate a p-code with a name					}
{								}
{ parameters:							}
{	fop - operation code					}
{	name - named label					}


procedure Gen1Name (fop: pcodes; fp1: integer; name: pStringPtr);

{ generate a one operand p-code with a name			}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	name - named label					}


procedure Gen2Name (fop: pcodes; fp1, fp2: integer; name: pStringPtr);

{ generate a two operand p-code with a name			}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	name - named label					}


procedure Gen1tName (fop: pcodes; fp1: integer; tp: baseTypeEnum;
		     name: pStringPtr);

{ generate a typed one operand p-code with a name		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	tp - base type						}
{	name - named label					}


procedure Gen2tName (fop: pcodes; fp1, fp2: integer; tp: baseTypeEnum;
		     name: pStringPtr);

{ generate a typed two operand p-code with a name		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	tp - base type						}
{	name - named label					}


procedure Gen1L1t (fop: pcodes; fp1: integer; lval: longint; tp: baseTypeEnum);

{ generate an instruction with one integer and one longint	}
{                                                               }
{ parameters:                                                   }
{	fop - operation code					}
{	fp1 - integer parameter					}
{       lval - longint parameter				}
{	tp - base type						}
                                                                       

procedure GenL1t (fop: pcodes; lval: longint; tp: baseTypeEnum);

{ generate an instruction that uses a longint			}
{                                                               }
{ parameters:                                                   }
{	fop - operation code					}
{       lval - longint parameter				}
{	tp - base type						}
                                                                       

procedure GenL2t (fop: pcodes; lval, lval2: longint; tp: baseTypeEnum);

{ generate an instruction that uses two longints		}
{                                                               }
{ parameters:                                                   }
{	fop - operation code					}
{       lval, lval2 - longint parameters			}
{	tp - base type						}
                                                                       

procedure GenLdcLong (lval: longint);

{ load a long constant						}
{								}
{ parameters:							}
{	lval - value to load					}


procedure GenLdcReal (rval: double);

{ load a real constant						}
{								}
{ parameters:							}
{	rval - value to load					}


procedure GenLdcSet (cval: constantRec);

{ load a set constant						}
{								}
{ parameters:							}
{	cval - value to load					}


procedure GenPS (fop: pcodes; str: pStringPtr);

{ generate an instruction that uses a p-string operand		}
{								}
{ parameters:							}
{	fop - operation code					}
{	str - pointer to string					}


procedure InitLabels; extern;

{ initialize the labels array for a procedure			}


{procedure InitWriteCode; 		    {debug}

{ initialize the intermediate code opcode table			}


procedure NextSegName (s: segNameType);

{ set the segment name for the next segment created		}
{								}
{ parameters:							}
{    s - segment name						}


{procedure PrintBlocks (tag: pStringPtr; bp: blockPtr); {debug}

{ print a series of basic blocks 				}
{								}
{ parameters:							}
{    tag - label for lines					}
{    bp - first block to print					}


{procedure WriteCode (code: icptr);	{debug}

{ print an intermediate code instruction 			}
{								}
{ Parameters:							}
{    code - intermediate code instruction to write		}

{---------------------------------------------------------------}

implementation

{var
   opt: array[pcodes] of packed array[1..3] of char; {debug}

function NewHandle (blockSize: longint; userID, memAttributes: integer;
                    memLocation: univ ptr): handle; tool ($02, $09);

{Imported from ObjOut.pas:}

procedure CloseObj; extern;

{ close the current obj file					}


procedure TokenOut (b: byte); extern;

{ Write a byte to the interface file				}
{								}
{ parameters:							}
{    b - byte to write						}


{Imported from DAG.pas:}

procedure DAG (code: icptr); extern;

{ place an op code in a DAG or tree				}
{								}
{ parameters:							}
{	code - opcode						}


{Imported from Native.pas:}

procedure InitFile (keepName: gsosOutStringPtr; keepFlag: integer; partial: boolean);
extern;

{ Set up the object file 					}
{								}
{ parameters:							}
{    keepName - name of the output file				}
{    keepFlag - keep status:					}
{	0 - don't keep the output				}
{	1 - create a new object module				}
{	2 - a .root already exists				}
{	3 - at least on .letter file exists			}
{    partial - is this a partial compile?			}

{---------------------------------------------------------------}

{ copy 'cgi.debug'}			{debug}

procedure CloseToken;

{ close the token file (.int file)				}

var
   dsRec: destroyOSDCB;			{DestroyGS record}
   ffRec: fastFileDCBGS;		{FastFile record}
   i: 1..8;				{loop/index variable}

begin {CloseToken}
if GetFileType(tokenNameGS^) = BIN then begin
   dsRec.pCount := 1;			{destroy any old file}
   dsRec.pathname := @tokenNameGS^.theString;
   DestroyGS(dsRec);
   end; {if}
if doingUnit and codegeneration then begin
   ffRec.pCount := 13;
   ffRec.action := 3 {save} ;
   ffRec.flags := $C000;
   ffRec.fileHandle := tokenHandle;
   ffRec.pathName := @tokenNameGS^.theString;
   ffRec.access := $00C3;
   ffRec.fileType := DVU;
   ffRec.auxType := AuxUnit;
   ffRec.storageType := 1;
   for i := 1 to 8 do
      ffRec.createDate[i] := 0;
   ffRec.modDate := ffRec.createDate;
   ffRec.option := nil;
   ffRec.fileLength := tokenLen + tokenDisp;
   FastFileGS(ffRec);
   if ToolError <> 0 then
      TermError(12, nil);
   ffRec.action := 7 {purge} ;
   ffRec.fileHandle := tokenHandle;
   FastFileGS(ffRec);
   if ToolError <> 0 then
      TermError(12, nil);
   end; {if}
end; {CloseToken}


procedure CodeGenFini;

{ terminal processing						}

begin {CodeGenFini}
CloseObj;				{close the open object file}
end; {CodeGenFini}


procedure CodeGenInit {keepName: gsosOutStringPtr; keepFlag: integer;
		       partial: boolean};

{ code generator initialization					}
{								}
{ parameters:							}
{	keepName - name of the output file			}
{	keepFlag - keep status:					}
{		0 - don't keep the output                       }
{		1 - create a new object module			}
{		2 - a .root already exists			}
{		3 - at least on .letter file exists		}
{	partial - is this a partial compile?			}

const
   usesVersion = 1;			{current uses file format version}

begin {CodeGenInit}
{initialize the debug tables		{debug}
{InitWriteCode;				{debug}

{initialize the label table}
InitLabels;

codeGeneration := true;			{turn on code generation}

{set up the DAG variables}
DAGhead := nil;				{no ics in DAG list}

InitFile(keepName, keepFlag, partial);	{open the keep file}

if doingUnit then begin
   new(tokenNameGS);			{create the token file name}
   tokenNameGS^ := keepName^;
   if tokenNameGS^.theString.size < maxPath then
      tokenNameGS^.theString.theString[tokenNameGS^.theString.size+1] := chr(0);
   tokenNameGS^.theString.theString := concat(tokenNameGS^.theString.theString, '.int');
   tokenNameGS^.theString.size := length(tokenNameGS^.theString.theString);
   if memoryFlag then			{memory-based compiles are not allowed}
      TermError(10, nil);
   tokenHandle :=			{get a token buffer}
      NewHandle(tokenBuffSize+1, UserID, $8000, nil);
   if ToolError <> 0 then
      TermError(3, nil);
   tokenPtr := tokenHandle^;
   tokenDisp := 0;
   tokenLen := 0;
   TokenOut(usesVersion);
   end; {if}
end; {CodeGenInit}


procedure CodeGenScalarInit;

{ initialize codegen scalars					}

begin {CodeGenScalarInit}
isJSL := false;				{the current opcode is not a jsl}
isNewDeskAcc := false;			{assume a normal program}
isCDev := false;
isClassicDeskAcc := false;
isNBA := false;
isXCMD := false;
codeGeneration := false; 		{code generation is not turned on yet}
currentSegment := '          ';		{start with the blank segment}
defaultSegment := '          ';
smallMemoryModel := true;		{small memory model}
dataBank := false;			{don't save/restore data bank}
stackSize := 0;				{default to the launcher's stack size}
toolParms := false;			{generate tool format parameters?}
rtl := false;				{return with a ~QUIT}
floatCard := 0;				{use SANE}
floatSlot := 0;				{default to slot 0}
stringSize := 0; 			{no strings, yet}

rangeCheck := false;			{don't generate range checks}
profileFlag := false;			{don't generate profiling code}
debugFlag := false;			{don't generate debug code}
debugStrFlag := false;                  {don't generate gsbug debug strings}
traceBack := false;			{don't generate traceback code}

registers := cLineOptimize;		{don't do register optimizations}
peepHole := cLineOptimize;		{not doing peephole optimization (yet)}
npeepHole := cLineOptimize;
commonSubexpression := cLineOptimize;	{not doing common subexpression elimination}
loopOptimizations := cLineOptimize;	{not doing loop optimizations, yet}
jslOptimizations := cLineOptimize;	{not doing jsl optimizations, yet}

{allocate the initial p-code}
code := pointer(Calloc(sizeof(intermediate_code)));
code^.optype := cgWord;
end; {CodeGenScalarInit}


procedure DefaultSegName {s: segNameType};

{ set the default segment name					}
{								}
{ parameters:							}
{    s - segment name						}

begin {DefaultSegName}
currentSegment := s;
defaultSegment := s;
end; {DefaultSegName}


procedure Gen0 {fop: pcodes};

{ generate an implied operand instruction			}
{								}
{ parameters:							}
{	fop - operation code					}

begin {Gen0}
if codeGeneration then begin

   {generate the intermediate code instruction}
   code^.opcode := fop;
{  if printSymbols then			{debug}
{     WriteCode(code);			{debug}
   DAG(code);				{generate the code}

   {initialize volitile variables for next intermediate code}
   code := pointer(Calloc(sizeof(intermediate_code)));
   {code^.lab := nil;}
   code^.optype := cgWord;
   end; {if}
end; {Gen0}


procedure Gen1 {fop: pcodes; fp2: integer};

{ generate an instruction with one numeric operand		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp2 - operand						}

begin {Gen1}
if codeGeneration then begin
   if fop = pc_ret then
      code^.optype := cgVoid;
   code^.q := fp2;
   Gen0(fop);
   end; {if}
end; {Gen1}


procedure Gen2 {fop: pcodes; fp1, fp2: integer};

{ generate an instruction with two numeric operands		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}

label 1;

var
   lcode: icptr; 			{local copy of code}

begin {Gen2}
if codeGeneration then begin
   lcode := code;
   case fop of

      dc_fun,pc_lnm,pc_tl1,pc_tl2,pc_lda,dc_loc,pc_mov: begin
	 lcode^.r := fp1;
	 lcode^.q := fp2;
	 end;

      pc_cnn,pc_cnv:
	 if fp1 = fp2 then
	    goto 1
	 else if (baseTypeEnum(fp1) in [cgReal,cgDouble,cgComp,cgExtended])
	    and (baseTypeEnum(fp2) in [cgReal,cgDouble,cgComp,cgExtended]) then
	    goto 1
	 else if (baseTypeEnum(fp1) in [cgUByte,cgWord,cgUWord])
	    and (baseTypeEnum(fp2) in [cgWord,cgUWord]) then
	    goto 1
	 else if (baseTypeEnum(fp1) in [cgByte,cgUByte])
	    and (baseTypeEnum(fp2) in [cgByte,cgUByte]) then
	    goto 1
	 else
	    lcode^.q := (fp1 << 4) | fp2;

      otherwise:
	 Error(cge1);
      end; {case}

   Gen0(fop);
   end; {if}
1:
end; {Gen2}


procedure Gen3 {fop: pcodes; fp1, fp2, fp3: integer};

{ generate an instruction with three numeric operands		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	fp3 - third operand					}

var
   lcode: icptr; 			{local copy of code}

begin {Gen3}
if codeGeneration then begin
   lcode := code;
   if fop = pc_lda then begin
      lcode^.s := fp1;
      lcode^.p := fp2;
      lcode^.q := fp3;
      end {if}
   else begin
      lcode^.s := fp1;
      lcode^.q := fp2;
      lcode^.r := fp3;
      end; {else}
   Gen0(fop);
   end; {if}
end; {Gen3}


procedure Gen0t {fop: pcodes; tp: baseTypeEnum};

{ generate a typed implied operand instruction			}
{								}
{ parameters:							}
{	fop - operation code					}
{	tp - base type						}

begin {Gen0t}
if codeGeneration then begin
   code^.optype := tp;
   Gen0(fop);
   end; {if}
end; {Gen0t}


procedure Gen1t {fop: pcodes; fp1: integer; tp: baseTypeEnum};

{ generate a typed instruction with two numeric operands 	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - operand						}
{	tp - base type						}

var
   lcode: icptr; 			{local copy of code}

begin {Gen1t}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := tp;
   lcode^.q := fp1;
   Gen0(fop);
   end; {if}
end; {Gen1t}


procedure Gen2t {fop: pcodes; fp1, fp2: integer; tp: baseTypeEnum};

{ generate a typed instruction with two numeric operands 	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	tp - base type						}

var
   lcode: icptr; 			{local copy of code}

begin {Gen2t}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := tp;
   lcode^.r := fp1;
   lcode^.q := fp2;
   Gen0(fop);
   end; {if}
end; {Gen2t}


procedure Gen3t {fop: pcodes; fp1, fp2, fp3: integer; tp: baseTypeEnum};

{ generate a typed instruction with three numeric operands	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	fp3 - third operand					}
{	tp - base type						}

var
   lcode: icptr; 			{local copy of code}

begin {Gen3t}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := tp;
   if fop in [pc_lod, pc_str] then begin
      lcode^.r := fp1;
      lcode^.q := fp2;
      lcode^.p := fp3;
      end {if}
   else begin
      lcode^.s := fp1;
      lcode^.q := fp2;
      lcode^.r := fp3;
      end; {else if}
   Gen0(fop);
   end; {if}
end; {Gen3t}


procedure Gen4t {fop: pcodes; fp1, fp2, fp3, fp4: integer; tp: baseTypeEnum};

{ generate a typed instruction with four numeric operands	}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	fp3 - third operand					}
{	fp4 - fourth operand					}
{	tp - base type						}

var
   lcode: icptr; 			{local copy of code}

begin {Gen4t}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := tp;
   lcode^.r := fp1;
   lcode^.q := fp2;
   lcode^.p := fp3;
   lcode^.s := fp4;
   Gen0(fop);
   end; {if}
end; {Gen4t}


procedure Gen0Name {fop: pcodes; name: pStringPtr};

{ generate a p-code with a name					}
{								}
{ parameters:							}
{	fop - operation code					}
{	name - named label					}

begin {Gen0Name}
if codeGeneration then begin
   code^.lab := name;
   Gen0(fop);
   end; {if}
end; {Gen0Name}


procedure Gen1Name {fop: pcodes; fp1: integer; name: pStringPtr};

{ generate a one operand p-code with a name			}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	name - named label					}

var
   lcode: icptr; 			{local copy of code}

begin {Gen1Name}
if codeGeneration then begin
   lcode := code;
   lcode^.q := fp1;
   lcode^.lab := name;
   Gen0(fop);
   end; {if}
end; {Gen1Name}


procedure Gen2Name {fop: pcodes; fp1, fp2: integer; name: pStringPtr};

{ generate a two operand p-code with a name			}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	name - named label					}

var
   lcode: icptr; 			{local copy of code}

begin {Gen2Name}
if codeGeneration then begin
   lcode := code;
   lcode^.q := fp2;
   lcode^.r := fp1;
   lcode^.lab := name;
   Gen0(fop);
   end; {if}
end; {Gen2Name}


procedure Gen1tName {fop: pcodes; fp1: integer; tp: baseTypeEnum;
		     name: pStringPtr};

{ generate a typed one operand p-code with a name		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	tp - base type						}
{	name - named label					}

var
   lcode: icptr; 			{local copy of code}

begin {Gen1tName}
if codeGeneration then begin
   lcode := code;
   lcode^.q := fp1;
   lcode^.lab := name;
   lcode^.optype := tp;
   Gen0(fop);
   end; {if}
end; {Gen1tName}


procedure Gen2tName {fop: pcodes; fp1, fp2: integer; tp: baseTypeEnum;
		     name: pStringPtr};

{ generate a typed two operand p-code with a name		}
{								}
{ parameters:							}
{	fop - operation code					}
{	fp1 - first operand					}
{	fp2 - second operand					}
{	tp - base type						}
{	name - named label					}

var
   lcode: icptr; 			{local copy of code}

begin {Gen2tName}
if codeGeneration then begin
   lcode := code;
   lcode^.r := fp1;
   lcode^.q := fp2;
   lcode^.lab := name;
   lcode^.optype := tp;
   Gen0(fop);
   end; {if}
end; {Gen2tName}


procedure Gen1L1t {fop: pcodes; fp1: integer; lval: longint; tp: baseTypeEnum};

{ generate an instruction with one integer and one longint	}
{                                                               }
{ parameters:                                                   }
{	fop - operation code					}
{	fp1 - integer parameter					}
{       lval - longint parameter				}
{	tp - base type						}
                                                                       
var
   lcode: icptr; 			{local copy of code}

begin {Gen1L1t}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := tp;
   lcode^.q := fp1;
   lcode^.lval := lval;
   Gen0(fop);
   end; {if}
end; {Gen1L1t}


procedure GenL1t {fop: pcodes; lval: longint; tp: baseTypeEnum};

{ generate an instruction that uses a longint			}
{                                                               }
{ parameters:                                                   }
{	fop - operation code					}
{       lval - longint parameter				}
{	tp - base type						}
                                                                       
var
   lcode: icptr; 			{local copy of code}

begin {GenL1t}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := tp;
   lcode^.lval := lval;
   Gen0(fop);
   end; {if}
end; {GenL1t}


procedure GenL2t {fop: pcodes; lval, lval2: longint; tp: baseTypeEnum};

{ generate an instruction that uses a longint and an int        }
{                                                               }
{ parameters:                                                   }
{	fop - operation code					}
{       lval, lval2 - longint parameters			}
{	tp - base type						}
                                                                       
var
   lcode: icptr; 			{local copy of code}

begin {GenL2t}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := tp;
   lcode^.lval := lval;
   lcode^.lval2 := lval2;
   Gen0(fop);
   end; {if}
end; {GenL2t}


procedure GenLdcLong {lval: longint};

{ load a long constant						}
{								}
{ parameters:							}
{	lval - value to load					}

var
   lcode: icptr; 			{local copy of code}

begin {GenLdcLong}
if codeGeneration then begin
   lcode := code;
   if lval >= 0 then
     lcode^.optype := cgULong
   else
     lcode^.optype := cgLong;
   lcode^.lval := lval;
   Gen0(pc_ldc);
   end; {if}
end; {GenLdcLong}


procedure GenLdcReal {rval: double};

{ load a real constant						}
{								}
{ parameters:							}
{	rval - value to load					}

var
   lcode: icptr; 			{local copy of code}

begin {GenLdcReal}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := cgReal;
   lcode^.rval := rval;
   Gen0(pc_ldc);
   end; {if}
end; {GenLdcReal}


procedure GenLdcSet {cval: constantRec};

{ load a set constant						}
{								}
{ parameters:							}
{	cval - value to load					}

var
   i, k: unsigned;			{loop/index variables}
   lcode: icptr; 			{local copy of code}

begin {GenLdcSet}
if codeGeneration then begin
   lcode := code;
   lcode^.optype := cgSet;
   i := cval.pmax div 8 + 1;
   lcode^.setp := pointer(Calloc(3+i));
   with lcode^.setp^ do begin
      smax := i;
      for k := 1 to i do
         sval[k] := cval.ch[k-1];
      end; {with}
   Gen0(pc_ldc);
   end; {if}
end; {GenLdcSet}


procedure GenPS {fop: pcodes; str: pStringPtr};

{ generate an instruction that uses a p-string operand		}
{								}
{ parameters:							}
{	fop - operation code					}
{	str - pointer to string					}

var
   lcode: icptr; 			{local copy of code}

begin {GenPS}
if codeGeneration then begin
   lcode := code;
   lcode^.q := length(str^);
   lcode^.optype := cgString;
   lcode^.str := str;
   Gen0(fop);
   end; {if}
end; {GenPS}


procedure NextSegName {s: segNameType};

{ set the segment name for the next segment created		}
{								}
{ parameters:							}
{    s - segment name						}

begin {NextSegmentName}
currentSegment := s;
end; {NextSegmentName}

end.

{$append 'cgi.asm'}
