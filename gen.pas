{$optimize -1}
{---------------------------------------------------------------}
{								}
{  Gen								}
{								}
{  Generates native code from intermediate code instructions.	}
{								}
{---------------------------------------------------------------}

unit Gen;

interface

{$segment 'gen'}

{$LibPrefix '0/obj/'}

uses PCommon, CGI, CGC, ObjOut, Native;

{---------------------------------------------------------------}

procedure Gen (blk: blockPtr);

{ Generates native code for a list of blocks			}
{								}
{ parameters:							}
{    blk - first of the list of blocks				}

{---------------------------------------------------------------}

implementation

const
   A_X		=	1;		{longword locations}
   onStack	=	2;
   inPointer	=	4;
   localAddress =	8;
   globalLabel	=      16;
   constant	=      32;

					{stack frame locations}
					{---------------------}
   returnSize		=	3;	{size of return address}

type
					{possible locations for 4 byte values}
   longType = record			{desciption of current four byte value}
      preference: integer;		{where you want the value}
      where: integer;			{where the value is at}
      fixedDisp: boolean;		{is the displacement a fixed value?}
      isLong: boolean;			{is long addr required for named labs?}
      disp: integer;			{fixed displacement/local addr}
      lval: longint;			{value}
      lab: pStringPtr;			 {global label name}
      end;

var
   enpFound: boolean;			{was the dc_enp found?}
   gLong: longType;			{info about last long value}
   namePushed: boolean;			{has a name been pushed in this proc?}
   skipLoad: boolean;			{skip load for a pc_lli, etc?}

					{stack frame locations}
					{---------------------}
   bankLoc: integer;			{disp in dp where bank reg is stored}
   dworkLoc: integer;			{disp in dp of 4 byte work spage for cg}
   funLoc: integer;			{loc of fn ret value in stack frame}
   localSize: integer;			{local space for current proc}
   parameterSize: integer;		{# bytes of parameters for current proc}
   staticLoc: integer;			{loc of static link}
   
{---------------------------------------------------------------}

procedure GenTree (op: icptr); forward;

{---------------------------------------------------------------}

function Complex (op: icptr): boolean;

{ determine if loading the intermediate code involves anything	}
{ but one reg							}
{								}
{ parameters:							}
{    code - intermediate code to check				}
{								}
{ NOTE: for one and two byte values only!!!			}

begin {Complex}
Complex := true;
if op^.opcode in [pc_ldo,pc_ldc] then
   Complex := false
else if op^.opcode = pc_lod then
   if op^.p = 0 then
      if localLabel[op^.r] + op^.q < 256 then
	 Complex := false;
if op^.optype in [cgByte,cgUByte] then
   Complex := true;
end; {Complex}


procedure DoOp(op_imm, op_abs, op_dir: integer; icode: icptr; disp: integer);

{ Do an operation.						}
{								}
{ Parameters:							}
{    op_imm,op_abs,op_dir - op codes for the various		}
{	addressing modes 					}
{    icode - intermediate code record				}
{    disp - disp past the location (1 or 2)			}

var
   val: integer; 		     {value for immediate operations}
   lval: longint;		     {long value for immediate operations}

begin {DoOp}
if icode^.opcode = pc_ldc then begin
   lval := icode^.lval;
   if disp = 0 then
      val := long(lval).lsw
   else
      val := long(lval).msw;
   GenNative(op_imm, immediate, val, nil, 0);
   end {if}
else if icode^.opcode in [pc_lod,pc_str] then
   GenNative(op_dir, direct, localLabel[icode^.r] + icode^.q + disp, nil, 0)
else {if icode^.opcode in [pc_ldo, pc_sro] then}
   GenNative(op_abs, absolute, icode^.q + disp, icode^.lab, 0);
end; {DoOp}


procedure GetPointer (op: icptr);

{ convert a tree into a usable pointer for indirect		}
{ loads/stores							}
{								}
{ parameters:							}
{    op - pointer tree						}

begin {GetPointer}
gLong.preference := A_X+inPointer+localAddress+globalLabel;
GenTree(op);
if gLong.where = onStack then begin
   GenImplied(m_pla);
   GenImplied(m_plx);
   gLong.where := A_X;
   end; {if}
if gLong.where = A_X then begin
   GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
   GenNative(m_stx_dir, direct, dworkLoc+2, nil, 0);
   gLong.where := inPointer;
   gLong.fixedDisp := true;
   gLong.disp := dworkLoc;
   end; {else if}
end; {GetPointer}


procedure IncAddr (size: integer);

{ add a two byte constant to a four byte value - generally an	}
{ address							}
{								}
{ parameters:							}
{    size - integer to add					}

var
   lab1: integer;			{branch point}

begin {IncAddr}
if size <> 0 then
   case gLong.where of

      onStack: begin
	 lab1 := GenLabel;
	 GenImplied(m_pla);
	 if size = 1 then begin
	    GenImplied(m_ina);
	    GenNative(m_bne, relative, lab1, nil, 0);
	    end {if}
	 else begin
	    GenImplied(m_clc);
	    GenNative(m_adc_imm, immediate, size, nil, 0);
	    GenNative(m_bcc, relative, lab1, nil, 0);
	    end; {else}
	 GenImplied(m_plx);
	 GenImplied(m_inx);
	 GenImplied(m_phx);
	 GenLab(lab1);
	 GenImplied(m_pha);
	 end;

      A_X: begin
	 lab1 := GenLabel;
	 if size = 1 then begin
	    GenImplied(m_ina);
	    GenNative(m_bne, relative, lab1, nil, 0);
	    end {if}
	 else begin
	    GenImplied(m_clc);
	    GenNative(m_adc_imm, immediate, size, nil, 0);
	    GenNative(m_bcc, relative, lab1, nil, 0);
	    end; {else}
	 GenImplied(m_inx);
	 GenLab(lab1);
	 end;

      inPointer:
	 if gLong.fixedDisp then begin
	    gLong.fixedDisp := false;
	    GenNative(m_ldy_imm, immediate, size, nil, 0);
	    end {if}
	 else if size <= 4 then begin
	    while size <> 0 do begin
	       GenImplied(m_iny);
	       size := size - 1;
	       end; {while}
	    end {else if}
	 else begin
	    GenImplied(m_tya);
	    GenImplied(m_clc);
	    GenNative(m_adc_imm, immediate, size, nil, 0);
	    GenImplied(m_tay);
	    end; {else}

      localAddress,globalLabel:
	 gLong.disp := gLong.disp+size;

      otherwise:
	 Error(cge1);
      end; {case}
end; {IncAddr}


procedure LoadX (op: icptr);

{ Load X with a two byte value					}
{                                                               }
{ parameters:                                                   }
{    op - value to load						}

var
   q, r: integer;
   lab: pStringPtr;

begin {LoadX}
q := op^.q;
r := op^.r;
lab := op^.lab;
case op^.opcode of
   pc_lao,pc_lda:
      Error(cge1);
   pc_ldc:
      GenNative(m_ldx_imm, immediate, q, nil, 0);
   pc_ldo:
      GenNative(m_ldx_abs, absolute, q, lab, 0);
   pc_lod:
      GenNative(m_ldx_dir, direct, localLabel[r] + q, nil, 0);
   otherwise:
      Error(cge1);
   end; {case}
end; {LoadX}


procedure OperA (mop: integer; op: icptr);

{ Do an operation on op that has addr modes equivalent to STA	}
{								}
{ parameters:							}
{    op - node to generate the leaf for				}
{    mop - operation						}

var
   loc: integer; 			{stack frame position}
   opcode: pcodes;			{temp storage}

begin {OperA}
opcode := op^.opcode;
case opcode of

   pc_ldo: begin
      {this shortcut is valid for cmp, adc, and, ora, sbc, eor}
      mop := mop+4;
      if smallMemoryModel then
         GenNative(mop, absolute, op^.q, op^.lab, 0)
      else
         GenNative(mop+2, longAbs, op^.q, op^.lab, 0);
      end; {case pc_ldo}

   pc_lod: begin
      {this shortcut is valid for cmp, adc, and, ora, sbc, eor}
      mop := mop-4;
      loc := localLabel[op^.r];
      loc := loc + op^.q;
      GenNative(mop, direct, loc, nil, 0);
      end; {case pc_lod}

   pc_ldc:
      GenNative(mop, immediate, op^.q, nil, 0);

   otherwise:
      Error(cge1);
   end; {case}
end; {OperA}


function NeedsCondition (opcode: pcodes): boolean;

{ See if the operation is one that doesn't set the condition	}
{ code reliably							}
{								}
{ Parameters:							}
{    opcodes - operation to check				}
{								}
{ Returns: True if the condition code is not set properly for	}
{    an operand type of cgByte,cgUByte,cgWord,cgUWord, else	}
{    false							}

begin {NeedsCondition}
NeedsCondition := opcode in
   [pc_and,pc_ior,pc_cui,pc_cup,pc_lor,pc_lnd,
    pc_cop,pc_cpo,pc_dvi,pc_mpi,pc_adi,pc_sbi,pc_mod,pc_bno];
end; {NeedsCondition}


function SameLoc (load, save: icptr): boolean;

{ See if load and save represent the same location (which must	}
{ be a direct page value or a global label).			}
{								}
{ parameters:							}
{    load - load operation					}
{    save - save operation					}
{								}
{ Returns: True the the same location is used, else false	}

begin {SameLoc}
SameLoc := false;
if save <> nil then begin
   if load^.opcode = pc_lod then begin
      if localLabel[load^.r] + load^.q < 254 then
	 if save^.opcode = pc_str then
	    if save^.q = load^.q then
	       if save^.r = load^.r then
	          if save^.p = load^.p then
		     SameLoc := true;
      end {if}
   else if smallMemoryModel then
      if load^.opcode = pc_ldo then
	 if save^.opcode = pc_sro then
	    if load^.lab^ = save^.lab^ then
	       if load^.q = save^.q then
		  SameLoc := true;
   end; {if}
end; {SameLoc}


procedure SaveRetValue (optype: baseTypeEnum);

{ save a value returned by a function                           }
{                                                               }
{ parameters:                                                   }
{    optype - function type					}

begin {SaveRetValue}
if optype in [cgLong,cgULong] then begin
   if (A_X & gLong.preference) = 0 then begin
      gLong.where := onStack;
      GenImplied(m_phx);
      GenImplied(m_pha);
      end
   else
      gLong.where := A_X;
   end {if}
else if optype in [cgReal,cgDouble,cgExtended,cgComp] then
   GenCall(85);
end; {SaveRetValue}


procedure StaticLink (levels: integer; guardA: boolean; inA: boolean);

{ Returns the start of the needed stack frame in X.		}
{								}
{ parameters:							}
{    levels - number of static levels to traverse		}
{    guardA - if true, A is preserved				}
{    inA - if true, the result is returned in A, rather than X	}
{								}
{ Note: gardA and inA should not both be true			}

var
   i: integer;				{loop variable}

begin {StaticLink}
if inA and (levels = 1) then
   GenNative(m_lda_dir, direct, staticLoc, nil, 0)
else
   GenNative(m_ldx_dir, direct, staticLoc, nil, 0);
if levels > 1 then begin
   if guardA then
      GenImplied(m_tay);
   for i := 2 to levels do begin
      GenNative(m_lda_longX, longAbsolute, staticLoc, nil, 0);
      if not (inA and (levels = i)) then
	 GenImplied(m_tax);
      end; {for}
   if guardA then
      GenImplied(m_tya);
   end; {if}
end; {StaticLink}

{---------------------------------------------------------------}

procedure GenAdlSbl (op, save: icptr);

{ generate code for pc_adl, pc_sbl				}
{								}
{ parameters:							}
{    op - pc_adl or pc_sbl operation				}
{    save - save location (pc_str or pc_sro) or nil		}

var
   bcc,clc,adc_imm,inc_dir,adc_abs,	{for op-code insensitive code}
      adc_dir,inc_abs,adc_s: integer;
   disp: integer;			{direct page location}
   lab1: integer;			{label number}
   lLong: longType;			{used to reserve gLong}
   nd: icptr;				{for swapping left/right children}
   opcode: pcodes;			{temp storage; for efficiency}
   simpleStore: boolean; 		{is the store absolute or direct?}
   val: longint; 			{long constant value}


   function Simple (icode: icptr): boolean;

   { See if the intermediate code is simple; i.e., can be	}
   { reached by direct page or absolute addressing.		}

   var
      load: icptr;			{left opcode}

   begin {Simple}
   Simple := false;
   if icode^.opcode = pc_ldc then
      Simple := true
   else if icode^.opcode in [pc_lod,pc_str] then begin
      if localLabel[icode^.r] + icode^.q < 254 then
         if icode^.p = 0 then
	    Simple := true;
      end {else if}
   else if icode^.opcode in [pc_ldo,pc_sro] then
      Simple := smallMemoryModel;
   end; {Simple}


begin {GenAdlSbl}
{determine where the result goes}
if save <> nil then
   gLong.preference :=
      A_X+onStack+inPointer+localAddress+globalLabel+constant;
lLong := gLong;

{set up the master instructions}
opcode := op^.opcode;
if opcode = pc_adl then begin
   clc := m_clc;
   bcc := m_bcc;
   adc_imm := m_adc_imm;
   adc_abs := m_adc_abs;
   adc_dir := m_adc_dir;
   adc_s   := m_adc_s;
   inc_dir := m_inc_dir;
   inc_abs := m_inc_abs;
   end {if}
else begin
   clc := m_sec;
   bcc := m_bcs;
   adc_imm := m_sbc_imm;
   adc_abs := m_sbc_abs;
   adc_dir := m_sbc_dir;
   adc_s   := m_sbc_s;
   inc_dir := m_dec_dir;
   inc_abs := m_dec_abs;
   end; {else}

{if the lhs is a constant, swap the nodes}
if ((op^.left^.opcode = pc_ldc) and (opcode = pc_adl)) then begin
   nd := op^.left;
   op^.left := op^.right;
   op^.right := nd;
   end; {if}

{handle a constant rhs}
if op^.right^.opcode = pc_ldc then
   val := op^.right^.lval
else
   val := -1;
if SameLoc(op^.left, save) and (save^.p = 0) and (long(val).msw = 0) then begin
   lab1 := GenLabel;
   if val = 1 then begin
      if opcode = pc_adl then begin
	 DoOp(0, m_inc_abs, m_inc_dir, op^.left, 0);
	 GenNative(m_bne, relative, lab1, nil, 0);
	 DoOp(0, m_inc_abs, m_inc_dir, op^.left, 2);
	 GenLab(lab1);
	 end {if}
      else {if opcode = pc_sbl then} begin
	 DoOp(m_lda_imm, m_lda_abs, m_lda_dir, op^.left, 0);
	 GenNative(m_beq, relative, lab1, nil, 0);
	 DoOp(0, m_dec_abs, m_dec_dir, op^.left, 0);
	 GenLab(lab1);
	 DoOp(0, m_dec_abs, m_dec_dir, op^.left, 2);
	 end; {else}
      end {if}
   else begin {rhs in [2..65535]}
      GenImplied(clc);
      DoOp(m_lda_imm, m_lda_abs, m_lda_dir, op^.left, 0);
      GenNative(adc_imm, immediate, long(val).lsw, nil, 0);
      DoOp(0, m_sta_abs, m_sta_dir, op^.left, 0);
      GenNative(bcc, relative, lab1, nil, 0);
      if opcode = pc_adl then
	 DoOp(0, m_inc_abs, m_inc_dir, op^.left, 2)
      else
	 DoOp(0, m_dec_abs, m_dec_dir, op^.left, 2);
      GenLab(lab1);
      end; {else}
   end {if constant rhs}

else begin
   simpleStore := false;
   if save <> nil then
      simpleStore := Simple(save);
   if (opcode = pc_adl) and Simple(op^.left) then begin
      nd := op^.left;
      op^.left := op^.right;
      op^.right := nd;
      end; {if}
   if simpleStore and Simple(op^.right) then begin
      if Simple(op^.left) then begin
	 GenImplied(clc);
	 DoOp(m_lda_imm, m_lda_abs, m_lda_dir, op^.left, 0);
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 0);
	 DoOp(0, m_sta_abs, m_sta_dir, save, 0);
	 DoOp(m_lda_imm, m_lda_abs, m_lda_dir, op^.left, 2);
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 2);
	 DoOp(0, m_sta_abs, m_sta_dir, save, 2);
	 end {if}
      else begin
	 gLong.preference := A_X;
	 GenTree(op^.left);
	 GenImplied(clc);
	 if gLong.where = onStack then
	    GenImplied(m_pla);
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 0);
	 DoOp(0, m_sta_abs, m_sta_dir, save, 0);
	 if gLong.where = onStack then
	    GenImplied(m_pla)
	 else
	    GenImplied(m_txa);
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 2);
	 DoOp(0, m_sta_abs, m_sta_dir, save, 2);
	 end; {else}
      end {if}
   else if Simple(op^.right) and (save = nil) then begin
      gLong.preference := gLong.preference & A_X;
      GenTree(op^.left);
      GenImplied(clc);
      if gLong.where = onStack then begin
	 GenImplied(m_pla);
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 0);
	 GenImplied(m_pha);
	 GenNative(m_lda_s, direct, 3, nil, 0);
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 2);
	 GenNative(m_sta_s, direct, 3, nil, 0);
	 end {if}
      else begin
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 0);
	 GenImplied(m_tay);
	 GenImplied(m_txa);
	 DoOp(adc_imm, adc_abs, adc_dir, op^.right, 2);
	 GenImplied(m_tax);
	 GenImplied(m_tya);
	 end; {else}
      end {else if}
   else begin {doing it the hard way}
      gLong.preference := onStack;
      GenTree(op^.right);
      gLong.preference := onStack;
      GenTree(op^.left);
      GenImplied(clc);
      GenImplied(m_pla);
      GenNative(adc_s, direct, 3, nil, 0);
      GenNative(m_sta_s, direct, 3, nil, 0);
      GenImplied(m_pla);
      GenNative(adc_s, direct, 3, nil, 0);
      GenNative(m_sta_s, direct, 3, nil, 0);
      if save = nil then
	 gLong.where := onStack
      else if save^.opcode = pc_str then begin
	 disp := localLabel[save^.r] + save^.q;
         if save^.p <> 0 then begin
	    StaticLink(save^.p, false, false);
	    GenImplied(m_pla);
	    GenNative(m_sta_longX, longAbsolute, disp, nil, 0);
	    GenImplied(m_pla);
	    GenNative(m_sta_longX, longAbsolute, disp+2, nil, 0);
            end {if}
	 else if disp < 254 then begin
	    GenImplied(m_pla);
	    GenNative(m_sta_dir, direct, disp, nil, 0);
	    GenImplied(m_pla);
	    GenNative(m_sta_dir, direct, disp+2, nil, 0);
	    end {else if}
	 else begin
	    GenNative(m_ldx_imm, immediate, disp, nil, 0);
	    GenImplied(m_pla);
	    GenNative(m_sta_dirX, direct, 0, nil, 0);
	    GenImplied(m_pla);
	    GenNative(m_sta_dirX, direct, 2, nil, 0);
	    end; {else}
	 end {else if}
      else {if save^.opcode = pc_sro then} begin
	 GenImplied(m_pla);
	 if smallMemoryModel then
	    GenNative(m_sta_abs, absolute, save^.q, save^.lab, 0)
	 else
	    GenNative(m_sta_long, longabsolute, save^.q, save^.lab, 0);
	 GenImplied(m_pla);
	 if smallMemoryModel then
	    GenNative(m_sta_abs, absolute, save^.q+2, save^.lab, 0)
	 else
	    GenNative(m_sta_long, longabsolute, save^.q+2, save^.lab, 0);
	 end; {else}
      end; {else}
   end; {else}
end; {GenAdlSbl}


procedure GenCmp (op: icptr; rOpcode: pcodes; lb: integer);

{ generate code for pc_les, pc_leq, pc_grt or pc_geq		}
{								}
{ parameters:							}
{    op - operation						}
{    rOpcode - Opcode that will use the result of the		}
{	compare.  If the result is used by a tjp or fjp, 	}
{	this procedure generated special code and does the	}
{	branch internally.					}
{    lb - For fjp, tjp, this is the label to branch to if	}
{	     the condition is satisfied. 			}

var
   i: integer;				{loop variable}
   lab1,lab2,lab3,lab4: integer; 	{label numbers}
   num: integer; 			{constant to compare to}
   nop: icptr;				{new opcode}


   procedure Switch;

   { switch the operands 					}

   var
      nd: icptr; 			{used to switch nodes}
      t: integer;			{used to switch string lengths}

   begin {Switch}
   nd := op^.left;
   op^.left := op^.right;
   op^.right := nd;
   if op^.optype = cgString then begin
      t := op^.r;
      op^.r := op^.q;
      op^.q := t;
      end; {if}
   end; {Switch}

begin {GenCmp}
{To reduct the number of possibilities that must be handled, pc_les  }
{and pc_leq compares are reduced to their equivalent pc_grt and	     }
{pc_geq instructions.						     }
if op^.opcode = pc_les then begin
   Switch;
   op^.opcode := pc_grt;
   end {if}
else if op^.opcode = pc_leq then begin
   Switch;
   op^.opcode := pc_geq;
   end; {else if}

{To take advantage of shortcuts, switch operands if generating	  }
{for a tjp or fjp with a constant left operand.			  }
if op^.optype in [cgByte,cgUByte,cgWord,cgUWord] then begin
   if op^.left^.opcode = pc_ldc then begin
      if rOpcode in [pc_tjp,pc_fjp] then begin
	 if op^.opcode = pc_geq then
	    op^.opcode := pc_grt
	 else
	    op^.opcode := pc_geq;
	 if rOpcode = pc_tjp then
	    rOpcode := pc_fjp
	 else
	    rOpcode := pc_tjp;
	 Switch;
	 end; {if}
      end; {if}

   {If constant operands are involved, change > to >=		}
   if op^.opcode = pc_grt then begin
      if op^.left^.opcode = pc_ldc then begin
         if (op^.left^.q > 0) or
            ((op^.optype in [cgWord, cgByte]) and (op^.left^.q > -maxint)) then
            begin
            nop := pointer(malloc(sizeof(intermediate_code)));
            nop^ := op^.left^;
            op^.left := nop;
            nop^.q := nop^.q - 1;
            op^.opcode := pc_geq;
            end; {if}
         end {if}
      else if op^.right^.opcode = pc_ldc then
         if op^.right^.q < maxint then begin
            nop := pointer(malloc(sizeof(intermediate_code)));
            nop^ := op^.right^;                              
            op^.right := nop;
            nop^.q := nop^.q + 1;
            op^.opcode := pc_geq;
            end; {if}
      end; {if}
   end; {if}

{Short cuts are available for single-word operands where the	  }
{right operand is a constant.					  }
if (op^.optype in [cgByte,cgUByte,cgWord,cgUWord]) and
   (op^.right^.opcode = pc_ldc) then begin
   GenTree(op^.left);
   num := op^.right^.q;
   lab1 := GenLabel;
   if rOpcode = pc_fjp then begin
      if op^.optype in [cgByte,cgWord] then begin
         if NeedsCondition(op^.left^.opcode) then
            GenImplied(m_tax);
	 if (num >= 0) and (num < 4) then begin
	    if op^.opcode = pc_geq then begin
	       if num <> 0 then begin
		  lab2 := GenLabel;
		  GenNative(m_bmi, relative, lab2, nil, 0);
		  for i := 1 to num do
		     GenImplied(m_dea);
		  end; {if}
	       GenNative(m_bpl, relative, lab1, nil, 0);
	       if num <> 0 then
		  GenLab(lab2);
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       GenLab(lab1);
	       end {if}
	    else {if opcode = pc_grt then} begin
	       lab2 := GenLabel;
	       GenNative(m_bmi, relative, lab2, nil, 0);
	       for i := 0 to num do
		  GenImplied(m_dea);
	       GenNative(m_bpl, relative, lab1, nil, 0);
	       GenLab(lab2);
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       GenLab(lab1);
	       end; {else if}
	    end {if (num >= 0) and (num < 4)}
	 else begin
	    lab2 := GenLabel;
	    if num > 0 then
	       GenNative(m_bmi, relative, lab1, nil, 0)
	    else
	       GenNative(m_bpl, relative, lab1, nil, 0);
	    GenNative(m_cmp_imm, immediate, num, nil, 0);
	    if op^.opcode = pc_grt then begin
	       lab3 := GenLabel;
	       GenNative(m_beq, relative, lab3, nil, 0);
	       GenNative(m_bcs, relative, lab2, nil, 0);
	       GenLab(lab3);
	       end
	    else
	       GenNative(m_bcs, relative, lab2, nil, 0);
	    if num > 0 then begin
	       GenLab(lab1);
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       end {if}
	    else begin
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       GenLab(lab1);
	       end; {else}
	    GenLab(lab2);
	    end; {else if}
	 end {if}
      else {if optype in [cgUByte,cgUWord] then} begin
	 GenNative(m_cmp_imm, immediate, num, nil, 0);
	 if op^.opcode = pc_grt then begin
	    lab2 := GenLabel;
	    GenNative(m_beq, relative, lab2, nil, 0);
	    end; {if}
	 GenNative(m_bcs, relative, lab1, nil, 0);
	 if op^.opcode = pc_grt then
	    GenLab(lab2);
	 GenNative(m_brl, longrelative, lb, nil, 0);
	 GenLab(lab1);
	 end; {else}
      end {if rOpcode = pc_fjp}
   else if rOpcode = pc_tjp then begin
      if op^.optype in [cgByte,cgWord] then begin
         if NeedsCondition(op^.left^.opcode) then
            GenImplied(m_tax);
	 if (num >= 0) and (num < 4) then begin
	    lab2 := GenLabel;
	    if op^.opcode = pc_geq then begin
	       GenNative(m_bmi, relative, lab1, nil, 0);
	       if num > 0 then begin
		  for i := 1 to num do
		  GenImplied(m_dea);
		  GenNative(m_bmi, relative, lab2, nil, 0);
		  end; {if}
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       end {if}
	    else {if op^.opcode = pc_grt then} begin
	       if num > 0 then begin
		  GenNative(m_bmi, relative, lab1, nil, 0);
		  for i := 0 to num do
		     GenImplied(m_dea);
		  GenNative(m_bmi, relative, lab2, nil, 0);
		  end {if}
	       else begin
		  GenNative(m_beq, relative, lab1, nil, 0);
		  GenNative(m_bmi, relative, lab2, nil, 0);
		  end; {else}
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       end; {else}
	    GenLab(lab2);
	    GenLab(lab1);
	    end {if (num >= 0) and (num < 4)}
	 else begin
	    lab2 := GenLabel;
	    if num > 0 then
	       GenNative(m_bmi, relative, lab1, nil, 0)
	    else
	       GenNative(m_bpl, relative, lab1, nil, 0);
	    GenNative(m_cmp_imm, immediate, num, nil, 0);
	    if op^.opcode = pc_grt then begin
	       lab3 := GenLabel;
	       GenNative(m_beq, relative, lab3, nil, 0);
	       end; {if}
	    GenNative(m_bcc, relative, lab2, nil, 0);
	    if num > 0 then begin
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       GenLab(lab2);
	       GenLab(lab1);
	       end {if}
	    else begin
	       GenLab(lab1);
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       GenLab(lab2);
	       end; {else}
	    if op^.opcode = pc_grt then
	       GenLab(lab3);
	    end; {else}
	 end {if}
      else {if optype in [cgUByte,cgUWord] then} begin
	 GenNative(m_cmp_imm, immediate, num, nil, 0);
	 GenNative(m_bcc, relative, lab1, nil, 0);
	 if op^.opcode = pc_grt then begin
	    lab2 := GenLabel;
	    GenNative(m_beq, relative, lab1, nil, 0);
	    end; {if}
	 GenNative(m_brl, longrelative, lb, nil, 0);
	 if op^.opcode = pc_grt then
	    GenLab(lab2);
	 GenLab(lab1);
	 end; {else}
      end {if rOpcode = pc_tjp}
   else if op^.optype in [cgByte,cgWord] then begin
      lab2 := GenLabel;
      GenNative(m_ldx_imm, immediate, 1, nil, 0);
      GenImplied(m_sec);
      GenNative(m_sbc_imm, immediate, num, nil, 0);
      if op^.opcode = pc_grt then begin
	 lab3 := GenLabel;
	 GenNative(m_beq, relative, lab3, nil, 0);
	 end; {if}
      GenNative(m_bvs, relative, lab1, nil, 0);
      GenNative(m_eor_imm, immediate, $8000, nil, 0);
      GenLab(lab1);
      GenNative(m_bmi, relative, lab2, nil, 0);
      if op^.opcode = pc_grt then
	 GenLab(lab3);
      GenImplied(m_dex);
      GenLab(lab2);
      GenImplied(m_txa);
      end {else if}
   else begin
      GenNative(m_ldx_imm, immediate, 0, nil, 0);
      GenNative(m_cmp_imm, immediate, num, nil, 0);
      GenNative(m_bcc, relative, lab1, nil, 0);
      if op^.opcode = pc_grt then
	 GenNative(m_beq, relative, lab1, nil, 0);
      GenImplied(m_inx);
      GenLab(lab1);
      GenImplied(m_txa);
      end; {else if}
   end {if (op^.optype in [cgByte,cgUByte,cgWord,cgUWord]) and
      (op^.right^.opcode = pc_ldc)}

{This section of code handles the cases where the above short	  }
{cuts cannot be used.						  }
else
   case op^.optype of

      cgByte,cgUByte,cgWord,cgUWord: begin
	 if Complex(op^.right) then begin
	    GenTree(op^.right);
	    if Complex(op^.left) then begin
	       GenImplied(m_pha);
	       GenTree(op^.left);
	       GenImplied(m_ply);
	       GenNative(m_sty_dir, direct, dworkLoc, nil, 0);
	       end {if}
	    else begin
	       GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
	       GenTree(op^.left);
	       end; {else}
	    if not (rOpcode in [pc_fjp,pc_tjp]) then
	       GenNative(m_ldx_imm, immediate, 1, nil, 0);
	    if op^.optype in [cgByte,cgWord] then begin
	       GenImplied(m_sec);
	       GenNative(m_sbc_dir, direct, dworkLoc, nil, 0);
	       end {if}
	    else
	       GenNative(m_cmp_dir, direct, dworkLoc, nil, 0);
	    end {if}
	 else begin
	    GenTree(op^.left);
	    if not (rOpcode in [pc_fjp,pc_tjp]) then
	       GenNative(m_ldx_imm, immediate, 1, nil, 0);
	    if op^.optype in [cgByte,cgWord] then begin
	       GenImplied(m_sec);
	       OperA(m_sbc_imm, op^.right);
	       end {if}
	    else
	       OperA(m_cmp_imm, op^.right);
	    end; {else}
	 if rOpcode = pc_fjp then begin
	    lab2 := GenLabel;
	    if op^.opcode = pc_grt then begin
	       lab3 := GenLabel;
	       GenNative(m_beq, relative, lab3, nil, 0);
	       end; {if}
	    if op^.optype in [cgByte,cgWord] then begin
	       lab1 := GenLabel;
	       GenNative(m_bvs, relative, lab1, nil, 0);
	       GenNative(m_eor_imm, immediate, $8000, nil, 0);
	       GenLab(lab1);
	       GenNative(m_bmi, relative, lab2, nil, 0);
	       end {if}
	    else
	       GenNative(m_bcs, relative, lab2, nil, 0);
	    if op^.opcode = pc_grt then
	       GenLab(lab3);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab2);
	    end {if}
	 else if rOpcode = pc_tjp then begin
	    lab2 := GenLabel;
	    if op^.opcode = pc_grt then begin
	       lab3 := GenLabel;
	       GenNative(m_beq, relative, lab3, nil, 0);
	       end; {if}
	    if op^.optype in [cgByte,cgWord] then begin
	       lab1 := GenLabel;
	       GenNative(m_bvs, relative, lab1, nil, 0);
	       GenNative(m_eor_imm, immediate, $8000, nil, 0);
	       GenLab(lab1);
	       GenNative(m_bpl, relative, lab2, nil, 0);
	       end {if}
	    else
	       GenNative(m_bcc, relative, lab2, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    if op^.opcode = pc_grt then
	       GenLab(lab3);
	    GenLab(lab2);
	    end {else if}
	 else begin
	    lab2 := GenLabel;
	    if op^.opcode = pc_grt then begin
	       lab3 := GenLabel;
	       GenNative(m_beq, relative, lab3, nil, 0);
	       end; {if}
	    if op^.optype in [cgByte,cgWord] then begin
	       lab1 := GenLabel;
	       GenNative(m_bvs, relative, lab1, nil, 0);
	       GenNative(m_eor_imm, immediate, $8000, nil, 0);
	       GenLab(lab1);
	       GenNative(m_bmi, relative, lab2, nil, 0);
	       end {if}
	    else
	       GenNative(m_bcs, relative, lab2, nil, 0);
	    if op^.opcode = pc_grt then
	       GenLab(lab3);
	    GenImplied(m_dex);
	    GenLab(lab2);
	    GenImplied(m_txa);
	    end; {else}
	 end; {case optype of cgByte,cgUByte,cgWord,cgUWord}

      cgULong: begin
	 gLong.preference := onStack;
	 GenTree(op^.right);
	 gLong.preference := A_X;
	 GenTree(op^.left);
	 if gLong.where = onStack then begin
	    GenImplied(m_ply);
	    GenImplied(m_pla);
	    end {if}
	 else begin
	    GenImplied(m_tay);
	    GenImplied(m_txa);
	    end; {else}
	 lab1 := GenLabel;
	 GenNative(m_ldx_imm, immediate, 1, nil, 0);
	 GenNative(m_cmp_s, direct, 3, nil, 0);
	 GenNative(m_bne, relative, lab1, nil, 0);
	 GenImplied(m_tya);
	 GenNative(m_cmp_s, direct, 1, nil, 0);
	 GenLab(lab1);
	 lab2 := GenLabel;
	 if op^.opcode = pc_grt then begin
	    lab3 := GenLabel;
	    GenNative(m_beq, relative, lab3, nil, 0);
	    end; {if}
	 GenNative(m_bcs, relative, lab2, nil, 0);
	 if op^.opcode = pc_grt then
	    GenLab(lab3);
	 GenImplied(m_dex);
	 GenLab(lab2);
	 GenImplied(m_pla);
	 GenImplied(m_pla);
	 GenImplied(m_txa);
	 if rOpcode = pc_fjp then begin
	    lab4 := GenLabel;
	    GenNative(m_bne, relative, lab4, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab4);
	    end {if}
	 else if rOpcode = pc_tjp then begin
	    lab4 := GenLabel;
	    GenNative(m_beq, relative, lab4, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab4);
	    end; {else if}
	 end;

      cgReal,cgDouble,cgComp,cgExtended,cgSet: begin
	 GenTree(op^.left);
	 GenTree(op^.right);
         if op^.opType = cgSet then
            GenCall(74)
	 else {if op^.opType in [cgReal,cgDouble,cgComp,cgExtended] then}
            if op^.opcode = pc_geq then
	       GenCall(71)
	    else
	       GenCall(70);
	 if (rOpcode = pc_fjp) or (rOpcode = pc_tjp) then begin
	    lab1 := GenLabel;
	    if rOpcode = pc_fjp then
	       GenNative(m_bne, relative, lab1, nil, 0)
	    else
	       GenNative(m_beq, relative, lab1, nil, 0);
	    GenNative(m_brl,longrelative,lb,nil,0);
	    GenLab(lab1);
	    end; {if}
	 end; {case optype of cgReal..cgExtended,cgSet}

      cgString: begin
	 gLong.preference := onStack;
	 GenTree(op^.left);
	 if op^.left^.opcode <> pc_csp then begin
	    if op^.r = -1 then begin
	       GenImplied(m_pha);
	       GenImplied(m_pha);
	       end; {if}
	    GenNative(m_pea, immediate, op^.r, nil, 0);
	    end; {if}
	 gLong.preference := onStack;
	 GenTree(op^.right);
	 if op^.right^.opcode <> pc_csp then begin
	    if op^.q = -1 then begin
	       GenImplied(m_pha);
	       GenImplied(m_pha);
	       end; {if}
	    GenNative(m_pea, immediate, op^.q, nil, 0);
	    end; {if}
         if op^.opcode = pc_geq then
	    GenCall(73)
	 else
	    GenCall(72);
	 if (rOpcode = pc_fjp) or (rOpcode = pc_tjp) then begin
	    lab1 := GenLabel;
	    if rOpcode = pc_fjp then
	       GenNative(m_bne, relative, lab1, nil, 0)
	    else
	       GenNative(m_beq, relative, lab1, nil, 0);
	    GenNative(m_brl,longrelative,lb,nil,0);
	    GenLab(lab1);
	    end; {if}
	 end; {case optype of cgString}

      cgLong: begin
	 gLong.preference := onStack;
	 GenTree(op^.left);
	 if op^.opcode = pc_geq then begin
	    gLong.preference := A_X;
	    GenTree(op^.right);
	    if gLong.where = onStack then begin
	       GenImplied(m_pla);
	       GenImplied(m_plx);
	       end; {if}
	    num := 139;
	    end {if}
	 else begin
	    gLong.preference := onStack;
	    GenTree(op^.right);
	    num := 138;
	    end; {else}
	 GenCall(num);
	 if (rOpcode = pc_fjp) or (rOpcode = pc_tjp) then begin
	    lab1 := GenLabel;
	    if rOpcode = pc_fjp then
	       GenNative(m_bne, relative, lab1, nil, 0)
	    else
	       GenNative(m_beq, relative, lab1, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab1);
	    end; {if}
	 end; {case optype of cgLong}

      otherwise:
	 Error(cge1);
      end; {case}
end; {GenCmp}


procedure GenCnv (op: icptr);

{ generate a pc_cnv instruction					}

const                                {note: these constants list all legal }
                                     {      conversions; others are ignored}
   cReal             = $06;
   cDouble           = $07;
   cComp             = $08;
   cExtended         = $09;

   byteToWord        = $02;
   byteToUword       = $03;
   byteToLong        = $04;
   byteToUlong       = $05;
   byteToReal        = $06;
   byteToDouble      = $07;
   ubyteToLong       = $14;
   ubyteToUlong      = $15;
   ubyteToReal       = $16;
   ubyteToDouble     = $17;
   wordToByte        = $20;
   wordToUByte       = $21;
   wordToLong        = $24;
   wordToUlong       = $25;
   wordToReal        = $26;
   wordToDouble      = $27;
   uwordToByte       = $30;
   uwordToUByte      = $31;
   uwordToLong       = $34;
   uwordToUlong      = $35;
   uwordToReal       = $36;
   uwordToDouble     = $37;
   longTobyte        = $40;
   longToUbyte       = $41;
   longToWord        = $42;
   longToUword       = $43;
   longToReal        = $46;
   longToDouble      = $47;
   ulongTobyte       = $50;
   ulongToUbyte      = $51;
   ulongToWord       = $52;
   ulongToUword      = $53;
   ulongToReal       = $56;
   ulongToDouble     = $57;
   realTobyte        = $60;
   realToUbyte       = $61;
   realToWord        = $62;
   realToUword       = $63;
   realToLong        = $64;
   realToUlong       = $65;
   doubleTobyte      = $70;
   doubleToUbyte     = $71;
   doubleToWord      = $72;
   doubleToUword     = $73;
   doubleToLong      = $74;
   doubleToUlong     = $75;

var
   fromReal: boolean;			{are we converting from a real?}
   lab1: integer;			{used for branches}
   lLong: longType;			{used to reserve gLong}

begin {GenCnv}
lLong := gLong;
gLong.preference := onStack+A_X+constant;
gLong.where := onStack;
if ((op^.q & $00F0) >> 4) in [cDouble,cExtended,cComp] then begin
   op^.q := (op^.q & $000F) | (cReal * 16);
   fromReal := true;
   end {if}
else
   fromReal := false;
if (op^.q & $000F) in [cDouble,cExtended,cComp] then
   op^.q := (op^.q & $00F0) | cReal;
GenTree(op^.left);
if op^.q in [wordToLong,wordToUlong] then begin
   lab1 := GenLabel;
   GenNative(m_ldx_imm, immediate, 0, nil, 0);
   GenImplied(m_tay);
   GenNative(m_bpl, relative, lab1, nil, 0);
   GenImplied(m_dex);
   GenLab(lab1);
   if (lLong.preference & A_X) <> 0 then
      gLong.where := A_X
   else begin
      gLong.where := onStack;
      GenImplied(m_phx);
      GenImplied(m_pha);
      end; {else}
   end {if}
else if op^.q in [byteToLong,byteToUlong] then begin
   lab1 := GenLabel;
   GenNative(m_ldx_imm, immediate, 0, nil, 0);
   GenNative(m_bit_imm, immediate, $0080, nil, 0);
   GenNative(m_beq, relative, lab1, nil, 0);
   GenImplied(m_dex);
   GenNative(m_ora_imm, immediate, $FF00, nil, 0);
   GenLab(lab1);
   if (lLong.preference & A_X) <> 0 then
      gLong.where := A_X
   else begin
      gLong.where := onStack;
      GenImplied(m_phx);
      GenImplied(m_pha);
      end; {else}
   end {if}
else if op^.q in [byteToWord,byteToUword] then begin
   lab1 := GenLabel;
   GenNative(m_bit_imm, immediate, $0080, nil, 0);
   GenNative(m_beq, relative, lab1, nil, 0);
   GenNative(m_ora_imm, immediate, $FF00, nil, 0);
   GenLab(lab1);
   end {if}
else if op^.q in [ubyteToLong,ubyteToUlong,uwordToLong,uwordToUlong] then
   begin
   if (lLong.preference & A_X) <> 0 then begin
      gLong.where := A_X;
      GenNative(m_ldx_imm, immediate, 0, nil, 0);
      end {if}
   else begin
      gLong.where := onStack;
      GenNative(m_pea, immediate, 0, nil, 0);
      GenImplied(m_pha);
      end; {else}
   end {else if}
else if op^.q in [wordToByte,wordToUbyte,uwordToByte,uwordToUbyte] then
   GenNative(m_and_imm, immediate, $00FF, nil, 0)
else if op^.q in [byteToReal,uByteToReal,wordToReal,uWordToReal] then
   GenCall(36)
else if op^.q in [longToByte,longToUbyte,ulongToByte,ulongToUbyte] then begin
   if gLong.where = A_X then
      GenNative(m_and_imm, immediate, $00FF, nil, 0)
   else if gLong.where = constant then
      GenNative(m_lda_imm, immediate, long(gLong.lval).lsw & $00FF, nil, 0)
   else {if gLong.where = onStack then} begin
      GenImplied(m_pla);
      GenImplied(m_plx);
      GenNative(m_and_imm, immediate, $00FF, nil, 0);
      end; {else if}
   end {else if}
else if op^.q in [longToWord,longToUword,ulongToWord,ulongToUword] then begin
   {Note: if the result is in A_X, no further action is needed}
   if gLong.where = constant then
      GenNative(m_lda_imm, immediate, long(gLong.lval).lsw, nil, 0)
   else if gLong.where = onStack then begin
      GenImplied(m_pla);
      GenImplied(m_plx);
      end; {else if}
   end {else if}
else if op^.q in [longToReal,uLongToReal] then begin
   if gLong.where = constant then begin
      GenNative(m_lda_imm, immediate, long(gLong.lval).lsw, nil, 0);
      GenNative(m_ldx_imm, immediate, long(gLong.lval).msw, nil, 0);
      end {if}
   else if gLong.where = onStack then begin
      GenImplied(m_pla);
      GenImplied(m_plx);
      end; {else if}
   GenCall(166);
   end {else}
else if op^.q in [realToByte,realToUbyte,realToWord,realToUWord] then begin
   GenCall(37);
   if (op^.q & $00FF) in [0,1] then
      GenNative(m_and_imm, immediate, $00FF, nil, 0);
   end {else if}
else if op^.q in [realToLong,realToUlong] then begin
   GenCall(150);
   if (lLong.preference & A_X) <> 0 then
      gLong.where := A_X
   else begin
      gLong.where := onStack;
      GenImplied(m_phx);
      GenImplied(m_pha);
      end; {else}
   end {else if}
else if (lLong.preference & gLong.where = 0)
   and ((op^.q & $000F) <> ord(cgVoid)) then begin
   if gLong.where = constant then begin
      GenNative(m_pea, immediate, long(gLong.lval).msw, nil, 0);
      GenNative(m_pea, immediate, long(gLong.lval).lsw, nil, 0);
      end {if}
   else if gLong.where = A_X then begin
      GenImplied(m_phx);
      GenImplied(m_pha);
      end; {else if}
   gLong.where := onStack;
   end; {else if}
end; {GenCnv}


procedure GenEquNeq (op: icptr; opcode: pcodes; lb: integer);

{ generate a pc_equ or pc_neq instruction			}
{								}
{ parameters:							}
{    op - node to generate the compare for			}
{    opcode - Opcode that will use the result of the compare.	}
{	If the result is used by a tjp or fjp, this procedure	}
{	 generates special code and does the branch internally.	}
{    lb - For fjp, tjp, this is the label to branch to if	}
{	 the condition is satisfied.				}

var
   nd: icptr;				{work node}
   num: integer; 			{constant to compare to}
   lab1,lab2: integer;			{label numbers}
   bne: integer; 			{instruction for a pc_equ bne branch}
   beq: integer; 			{instruction for a pc_equ beq branch}
   lLong: longType;			{local long value information}
   leftOp,rightOp: pcodes;		{opcode codes to left, right}


   procedure DoOr (op: icptr);

   { or the two halves of a four byte value			}
   {								}
   { parameters: 						}
   {	operand to or						}

   var
      disp: integer;			{disp of value on stack frame}

   begin {DoOr}
   with op^ do begin
      if opcode = pc_ldo then begin
	 GenNative(m_lda_abs, absolute, q, lab, 0);
	 GenNative(m_ora_abs, absolute, q+2, lab, 0);
	 end {if}
      else begin
	 disp := localLabel[r] + q;
	 if disp < 254 then begin
	    GenNative(m_lda_dir, direct, disp, nil, 0);
	    GenNative(m_ora_dir, direct, disp+2, nil, 0);
	    end {else if}
	 else begin
	    GenNative(m_ldx_imm, immediate, disp, nil, 0);
	    GenNative(m_lda_dirX, direct, 0, nil, 0);
	    GenNative(m_ora_dirX, direct, 2, nil, 0);
	    end; {else}
	 end; {else}
      end; {with}
   end; {DoOr}


   procedure DoCmp (op: icPtr);

   { compare a long value in A_X to a local or global scalar	}
   {								}
   { parameters: 						}
   {	op - value to compare to 				}

   var
      disp: integer;			{disp of value on stack frame}
      lab1: integer;			{label numbers}

   begin {DoCmp}
   lab1 := GenLabel;
   with op^ do begin
      if opcode = pc_ldo then begin
	 GenNative(m_cmp_abs, absolute, q, lab, 0);
	 GenNative(m_bne, relative, lab1, nil, 0);
	 GenNative(m_cpx_abs, absolute, q+2, lab, 0);
	 end {if}
      else begin
	 disp := localLabel[r] + q;
	 if disp < 254 then begin
	    GenNative(m_cmp_dir, direct, disp, nil, 0);
	    GenNative(m_bne, relative, lab1, nil, 0);
	    GenNative(m_cpx_dir, direct, disp+2, nil, 0);
	    end {if}
	 else begin
	    GenImplied(m_txy);
	    GenNative(m_ldx_imm, immediate, disp, nil, 0);
	    GenNative(m_cmp_dirX, direct, 0, nil, 0);
	    GenNative(m_bne, relative, lab1, nil, 0);
	    GenImplied(m_tya);
	    GenNative(m_cmp_dirX, direct, 2, nil, 0);
	    end; {else}
	 end; {else}
      GenLab(lab1);
      end; {with}
   end; {DoCmp}


begin {GenEquNeq}
if op^.opcode = pc_equ then begin
   bne := m_bne;
   beq := m_beq;
   end {if}
else begin
   bne := m_beq;
   beq := m_bne;
   end; {else}
if op^.optype <> cgString then begin
   if op^.left^.opcode in [pc_lod,pc_ldo] then begin
      nd := op^.left;
      op^.left := op^.right;
      op^.right := nd;
      end; {if}
   if op^.left^.opcode = pc_ldc then begin
      nd := op^.left;
      op^.left := op^.right;
      op^.right := nd;
      end; {if}
   end; {if}
leftOp := op^.left^.opcode;		{set op codes for fast access}
rightOp := op^.right^.opcode;
if (op^.optype in [cgByte,cgUByte,cgWord,cgUWord]) and
   (rightOp = pc_ldc) then begin
   GenTree(op^.left);
   num := op^.right^.q;
   lab1 := GenLabel;
   if opcode in [pc_fjp,pc_tjp] then begin
      if num <> 0 then
	 GenNative(m_cmp_imm, immediate, num, nil, 0)
      else if NeedsCondition(leftOp) then
	 GenImplied(m_tay);
      if opcode = pc_fjp then
	 GenNative(beq, relative, lab1, nil, 0)
      else
	 GenNative(bne, relative, lab1, nil, 0);
      GenNative(m_brl, longrelative, lb, nil, 0);
      GenLab(lab1);
      end {if}
   else begin
      GenNative(m_ldx_imm, immediate, 0, nil, 0);
      GenNative(m_cmp_imm, immediate, num, nil, 0);
      GenNative(bne, relative, lab1, nil, 0);
      GenImplied(m_inx);
      GenLab(lab1);
      GenImplied(m_txa);
      end; {else}
   end {if}
else if (op^.optype in [cgLong,cgULong])
   and ((leftOp = pc_ldo) or ((leftOp = pc_lod) and (op^.left^.p = 0)))
   and (rightOp = pc_ldc) and (op^.right^.lval = 0) then begin
   if opcode in [pc_fjp,pc_tjp] then begin
      DoOr(op^.left);
      lab1 := GenLabel;
      if opcode = pc_fjp then
	 GenNative(beq, relative, lab1, nil, 0)
      else
	 GenNative(bne, relative, lab1, nil, 0);
      GenNative(m_brl, longrelative, lb, nil, 0);
      GenLab(lab1);
      end {if}
   else if op^.opcode = pc_equ then begin
      lab1 := GenLabel;
      lab2 := GenLabel;
      DoOr(op^.left);
      GenNative(bne, relative, lab1, nil, 0);
      GenNative(m_lda_imm, immediate, 1, nil, 0);
      GenNative(m_bra, relative, lab2, nil, 0);
      GenLab(lab1);
      GenNative(m_lda_imm, immediate, 0, nil, 0);
      GenLab(lab2);
      end {else if}
   else {if op^.opcode = pc_neq then} begin
      lab1 := GenLabel;
      DoOr(op^.left);
      GenNative(m_beq, relative, lab1, nil, 0);
      GenNative(m_lda_imm, immediate, 1, nil, 0);
      GenLab(lab1);
      end; {else if}
   end {else if}
else if (op^.optype in [cgLong,cgULong])
   and ((rightOp = pc_ldo) or ((rightOp = pc_lod) and (op^.right^.p = 0)))
   then begin
   gLong.preference := A_X;
   GenTree(op^.left);
   if gLong.where = onStack then begin
      GenImplied(m_pla);
      GenImplied(m_plx);
      end; {if}
   if opcode in [pc_fjp,pc_tjp] then begin
      DoCmp(op^.right);
      lab1 := GenLabel;
      if opcode = pc_fjp then
	 GenNative(beq, relative, lab1, nil, 0)
      else
	 GenNative(bne, relative, lab1, nil, 0);
      GenNative(m_brl, longrelative, lb, nil, 0);
      GenLab(lab1);
      end {if}
   else begin
      lab1 := GenLabel;
      lab2 := GenLabel;
      DoCmp(op^.right);
      GenNative(bne, relative, lab1, nil, 0);
      GenNative(m_lda_imm, immediate, 1, nil, 0);
      GenNative(m_bra, relative, lab2, nil, 0);
      GenLab(lab1);
      GenNative(m_lda_imm, immediate, 0, nil, 0);
      GenLab(lab2);
      end; {else}
   end {else if}
else
   case op^.optype of

      cgByte,cgUByte,cgWord,cgUWord: begin
	 if not Complex(op^.left) then
	    if Complex(op^.right) then begin
	       nd := op^.left;
	       op^.left := op^.right;
	       op^.right := nd;
	       end; {if}
	 GenTree(op^.left);
	 if Complex(op^.right) or (not (opcode in [pc_fjp,pc_tjp])) then begin
	    GenImplied(m_pha);
	    GenTree(op^.right);
	    GenImplied(m_sec);
	    GenNative(m_sbc_s, direct, 1, nil, 0);
	    GenImplied(m_plx);
	    GenImplied(m_tax);
	    if opcode in [pc_fjp,pc_tjp] then begin
	       lab1 := GenLabel;
	       if opcode = pc_fjp then
		  GenNative(beq, relative, lab1, nil, 0)
	       else
		  GenNative(bne, relative, lab1, nil, 0);
	       GenNative(m_brl, longrelative, lb, nil, 0);
	       GenLab(lab1);
	       end {if}
	    else begin
	       lab1 := GenLabel;
	       GenNative(m_beq, relative, lab1, nil, 0);
	       GenNative(m_lda_imm, immediate, 1, nil, 0);
	       GenLab(lab1);
	       if op^.opcode = pc_equ then
		  GenNative(m_eor_imm, immediate, 1, nil, 0);
	       end; {else}
	    end {if}
	 else begin
	    OperA(m_cmp_imm, op^.right);
	    lab1 := GenLabel;
	    if opcode = pc_fjp then
	       GenNative(beq, relative, lab1, nil, 0)
	    else
	       GenNative(bne, relative, lab1, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab1);
	    end; {else}
	 end; {case optype of cgByte,cgUByte,cgWord,cgUWord}

      cgLong,cgULong: begin
	 gLong.preference := onStack;
	 GenTree(op^.left);
	 lLong := gLong;
	 gLong.preference := A_X;
	 GenTree(op^.right);
	 if gLong.where = onStack then begin
	    GenImplied(m_pla);
	    GenImplied(m_plx);
	    end; {if}
	 GenNative(m_ldy_imm, immediate, 1, nil, 0);
	 GenNative(m_cmp_s, direct, 1, nil, 0);
	 lab1 := GenLabel;
	 GenNative(m_beq, relative, lab1, nil, 0);
	 GenImplied(m_dey);
	 GenLab(lab1);
	 GenImplied(m_txa);
	 GenNative(m_cmp_s, direct, 3, nil, 0);
	 lab1 := GenLabel;
	 GenNative(m_beq, relative, lab1, nil, 0);
	 GenNative(m_ldy_imm, immediate, 0, nil, 0);
	 GenLab(lab1);
	 GenImplied(m_pla);
	 GenImplied(m_pla);
	 GenImplied(m_tya);
	 if opcode in [pc_fjp,pc_tjp] then begin
	    lab1 := GenLabel;
	    if opcode = pc_fjp then
	       GenNative(bne, relative, lab1, nil, 0)
	    else
	       GenNative(beq, relative, lab1, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab1);
	    end {if}
	 else if op^.opcode = pc_neq then
	    GenNative(m_eor_imm, immediate, 1, nil, 0);
	 end; {case optype of cgLong,cgULong}

      cgReal,cgDouble,cgComp,cgExtended,cgSet: begin
         gLong.preference := onStack;
	 GenTree(op^.left);
         gLong.preference := onStack;
	 GenTree(op^.right);         
         if op^.optype = cgSet then
	    GenCall(30)
         else
	    GenCall(31);
	 if opcode in [pc_fjp,pc_tjp] then begin
	    lab1 := GenLabel;
	    if opcode = pc_fjp then
	       GenNative(bne, relative, lab1, nil, 0)
	    else
	       GenNative(beq, relative, lab1, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab1);
	    end {if}
	 else if op^.opcode = pc_neq then
	    GenNative(m_eor_imm, immediate, 1, nil, 0);
	 end; {case optype of cgReal..cgExtended, cgSet}

      cgString: begin
         gLong.preference := onStack;
	 GenTree(op^.left);
         if op^.left^.opcode <> pc_csp then begin
            if op^.r = -1 then begin
               GenImplied(m_pha);
               GenImplied(m_pha);
               end; {if}
            GenNative(m_pea, immediate, op^.r, nil, 0);
            end; {if}
         gLong.preference := onStack;
	 GenTree(op^.right);
         if op^.right^.opcode <> pc_csp then begin
            if op^.q = -1 then begin
               GenImplied(m_pha);
               GenImplied(m_pha);
               end; {if}
            GenNative(m_pea, immediate, op^.q, nil, 0);
            end; {if}
	 GenCall(69);
	 if opcode in [pc_fjp,pc_tjp] then begin
	    lab1 := GenLabel;
	    if opcode = pc_fjp then
	       GenNative(bne, relative, lab1, nil, 0)
	    else
	       GenNative(beq, relative, lab1, nil, 0);
	    GenNative(m_brl, longrelative, lb, nil, 0);
	    GenLab(lab1);
	    end {if}
	 else if op^.opcode = pc_neq then
	    GenNative(m_eor_imm, immediate, 1, nil, 0);
	 end; {case optype of cgString}

      otherwise:
	 Error(cge1);
      end; {case}
end; {GenEquNeq}


procedure GenIncDec (op, save: icptr);

{ generate code for pc_inc, pc_dec				}
{								}
{ parameters:							}
{    op - pc_inc or pc_dec operation				}
{    save - save location (pc_str or pc_sro) or nil		}

var
   disp: integer;			{disp in stack frame}
   lab1: integer;			{branch point}
   opcode: pcodes;			{temp storage for op code}
   short: boolean;			{doing a one-byte save?}
   size: integer;			{number to increment by}
   clc,ina,adc: integer; 		{instructions to generate}

begin {GenIncDec}
{set up local variables}
opcode := op^.opcode;
size := op^.q;

if op^.optype in [cgByte,cgUByte,cgWord,cgUWord] then begin
   if SameLoc(op^.left, save) and (save^.p = 0) and (size = 1) then begin
      if opcode = pc_inc then
	 DoOp(0, m_inc_abs, m_inc_dir, op^.left, 0)
      else {if opcode = pc_dec then}
	 DoOp(0, m_dec_abs, m_dec_dir, op^.left, 0);
      end {if}
   else begin
      GenTree(op^.left);
      if opcode = pc_inc then begin
	 clc := m_clc;
	 ina := m_ina;
	 adc := m_adc_imm;
	 end {if}
      else begin
	 clc := m_sec;
	 ina := m_dea;
	 adc := m_sbc_imm;
	 end; {else}
      if size = 1 then
	 GenImplied(ina)
      else if size = 2 then begin
	 GenImplied(ina);
	 GenImplied(ina);
	 end {else if}
      else if size <> 0 then begin
	 GenImplied(clc);
	 GenNative(adc, immediate, size, nil, 0);
	 if rangeCheck then
	    GenCall(147);
	 end; {else if}
      if save <> nil then begin
         short := save^.optype in [cgByte,cgUByte];
	 if save^.opcode = pc_str then begin
	    disp := localLabel[save^.r] + save^.q;
            if save^.p <> 0 then begin
	       StaticLink(save^.p, true, false);
               if short then
	          GenNative(m_sep, immediate, 32, nil, 0);
	       GenNative(m_sta_longX, longAbsolute, disp, nil, 0);
               end {if}
	    else if disp < 254 then begin
               if short then
	          GenNative(m_sep, immediate, 32, nil, 0);
	       GenNative(m_sta_dir, direct, disp, nil, 0);
               end {else if}
	    else begin
               if short then
	          GenNative(m_sep, immediate, 32, nil, 0);
	       GenNative(m_ldx_imm, immediate, disp, nil, 0);
	       GenNative(m_sta_dirX, direct, 0, nil, 0);
	       end; {else}
	    end {else if}
	 else {if save^.opcode = pc_sro then} begin
            if short then
	       GenNative(m_sep, immediate, 32, nil, 0);
	    if smallMemoryModel then
	       GenNative(m_sta_abs, absolute, save^.q, save^.lab, 0)
	    else
	       GenNative(m_sta_long, longabsolute, save^.q, save^.lab, 0);
	    end; {else}
         if short then
	    GenNative(m_rep, immediate, 32, nil, 0);
         end; {if}
      end {else}
   end {if}
else if op^.optype in [cgLong,cgULong] then begin
   if SameLoc(op^.left, save) and (save^.p = 0) then begin
      lab1 := GenLabel;
      if size = 1 then begin
	 if opcode = pc_inc then begin
	    DoOp(0, m_inc_abs, m_inc_dir, op^.left, 0);
	    GenNative(m_bne, relative, lab1, nil, 0);
	    DoOp(0, m_inc_abs, m_inc_dir, op^.left, 2);
	    GenLab(lab1);
	    end {if}
	 else {if opcode = pc_dec then} begin
	    DoOp(m_lda_imm, m_lda_abs, m_lda_dir, op^.left, 0);
	    GenNative(m_bne, relative, lab1, nil, 0);
	    DoOp(0, m_dec_abs, m_dec_dir, op^.left, 2);
	    GenLab(lab1);
	    DoOp(0, m_dec_abs, m_dec_dir, op^.left, 0);
	    end; {else}
	 end {if}
      else if opcode = pc_inc then begin
	 GenImplied(m_clc);
	 DoOp(m_lda_imm, m_lda_abs, m_lda_dir, op^.left, 0);
	 GenNative(m_adc_imm, immediate, size, nil, 0);
	 DoOp(0, m_sta_abs, m_sta_dir, op^.left, 0);
	 GenNative(m_bcc, relative, lab1, nil, 0);
	 DoOp(0, m_inc_abs, m_inc_dir, op^.left, 2);
	 GenLab(lab1);
	 end {else if}
      else begin
	 GenImplied(m_sec);
	 DoOp(m_lda_imm, m_lda_abs, m_lda_dir, op^.left, 0);
	 GenNative(m_sbc_imm, immediate, size, nil, 0);
	 DoOp(0, m_sta_abs, m_sta_dir, op^.left, 0);
	 GenNative(m_bcs, relative, lab1, nil, 0);
	 DoOp(0, m_dec_abs, m_dec_dir, op^.left, 2);
	 GenLab(lab1);
	 end; {else}
      end {if}
   else begin
      if save <> nil then
	 gLong.preference := A_X
      else
	 gLong.preference := gLong.preference & (A_X | inpointer);
      if opcode = pc_dec then
	 gLong.preference := gLong.preference & A_X;
      GenTree(op^.left);
      if opcode = pc_inc then
	 IncAddr(size)
      else begin
	 lab1 := GenLabel;
	 if gLong.where = A_X then begin
	    GenImplied(m_sec);
	    GenNative(m_sbc_imm, immediate, size, nil, 0);
	    GenNative(m_bcs, relative, lab1, nil, 0);
	    GenImplied(m_dex);
	    end {if}
	 else begin
	    GenImplied(m_sec);
	    GenNative(m_lda_s, direct, 1, nil, 0);
	    GenNative(m_sbc_imm, immediate, size, nil, 0);
	    GenNative(m_sta_s, direct, 1, nil, 0);
	    GenNative(m_bcs, relative, lab1, nil, 0);
	    GenNative(m_lda_s, direct, 3, nil, 0);
	    GenImplied(m_dea);
	    GenNative(m_sta_s, direct, 3, nil, 0);
	    end; {else}
	 GenLab(lab1);
	 end; {else}
      if save <> nil then
	 if save^.opcode = pc_str then begin
	    disp := localLabel[save^.r] + save^.q;
            if save^.p <> 0 then begin
	       if gLong.where = A_X then begin
                  GenImplied(m_phx);
                  GenImplied(m_pha);
                  end; {if}
	       StaticLink(save^.p, false, false);
	       GenImplied(m_pla);
	       GenNative(m_sta_longX, longAbsolute, disp, nil, 0);
	       GenImplied(m_pla);
	       GenNative(m_sta_longX, longAbsolute, disp+2, nil, 0);
               end {if}
	    else if disp < 254 then begin
	       if gLong.where = onStack then
		  GenImplied(m_pla);
	       GenNative(m_sta_dir, direct, disp, nil, 0);
	       if gLong.where = onStack then
		  GenImplied(m_plx);
	       GenNative(m_stx_dir, direct, disp+2, nil, 0);
	       end {else if}
	    else begin
	       if gLong.where = A_X then
		  GenImplied(m_txy);
	       GenNative(m_ldx_imm, immediate, disp, nil, 0);
	       if gLong.where = onStack then
		  GenImplied(m_pla);
	       GenNative(m_sta_dirX, direct, 0, nil, 0);
	       if gLong.where = onStack then
		  GenImplied(m_pla)
	       else
		  GenImplied(m_tya);
	       GenNative(m_sta_dirX, direct, 2, nil, 0);
	       end; {else}
	    end {else if}
	 else {if save^.opcode = pc_sro then} begin
	    if gLong.where = onStack then
	       GenImplied(m_pla);
	    if smallMemoryModel then
	       GenNative(m_sta_abs, absolute, save^.q, save^.lab, 0)
	    else
	       GenNative(m_sta_long, longabsolute, save^.q, save^.lab, 0);
	    if smallMemoryModel then begin
	       if gLong.where = onStack then
		  GenImplied(m_plx);
	       GenNative(m_stx_abs, absolute, save^.q+2, save^.lab, 0)
	       end {if}
	    else begin
	       if gLong.where = onStack then
		  GenImplied(m_pla)
	       else
		  GenImplied(m_txa);
	       GenNative(m_sta_long, longabsolute, save^.q+2, save^.lab, 0);
	       end; {else}
	    end; {else}
      end; {else}
   end; {else if}
end; {GenIncDec}


procedure GenInd (op: icptr);

{ Generate code for a pc_ind					}

var
   lab1: integer;			{label}
   lLong: longType;			{requested address type}
   optype: baseTypeEnum; 		{op^.optype}
   q: integer;				{op^.q}

begin {GenInd}
optype := op^.optype;
q := op^.q;
case optype of
   cgReal,cgDouble,cgComp,cgExtended: begin
      gLong.preference := onStack;
      GenTree(op^.left);
      if q <> 0 then
	 IncAddr(q);
      if optype = cgReal then
	 GenCall(25)
      else if optype = cgDouble then
	 GenCall(18)
      else if optype = cgComp then
	 GenCall(163)
      else if optype = cgExtended then
	 GenCall(164);
      end; {case cgReal,cgDouble,cgComp,cgExtended}

   cgLong,cgULong: begin
      lLong := gLong;
      GetPointer(op^.left);
      if gLong.where = inPointer then begin
	 if q = 0 then begin
	    if gLong.fixedDisp then begin
	       GenNative(m_ldy_imm, immediate, 2, nil, 0);
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0);
	       if (A_X & lLong.preference) <> 0 then
		  GenImplied(m_tax)
	       else
		  GenImplied(m_pha);
	       GenNative(m_lda_indl, direct, gLong.disp, nil, 0);
	       end {if}
	    else begin
	       GenImplied(m_iny);
	       GenImplied(m_iny);
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0);
	       if (A_X & lLong.preference) <> 0 then
		  GenImplied(m_tax)
	       else
		  GenImplied(m_pha);
	       GenImplied(m_dey);
	       GenImplied(m_dey);
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0);
	       end; {else}
	    if (A_X & lLong.preference) = 0 then
	       GenImplied(m_pha);
	    end {if q = 0}
	 else begin
	    if gLong.fixedDisp then begin
	       GenNative(m_ldy_imm, immediate, q+2, nil, 0);
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0);
	       if (A_X & lLong.preference) <> 0 then
		  GenImplied(m_tax)
	       else
		  GenImplied(m_pha);
	       GenNative(m_ldy_imm, immediate, q, nil, 0);
	       end {if}
	    else begin
	       GenImplied(m_tya);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, q+2, nil, 0);
	       GenImplied(m_tay);
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0);
	       if (A_X & lLong.preference) <> 0 then
		  GenImplied(m_tax)
	       else
		  GenImplied(m_pha);
	       GenImplied(m_dey);
	       GenImplied(m_dey);
	       end; {else}
	    GenNative(m_lda_indly, direct, gLong.disp, nil, 0);
	    if (A_X & lLong.preference) = 0 then
	       GenImplied(m_pha);
	    end; {else}
	 end {if glong.where = inPointer}
      else if gLong.where = localAddress then begin
	 gLong.disp := gLong.disp+q;
	 if gLong.fixedDisp then
	    if (gLong.disp < 254) and (gLong.disp >= 0) then begin
	       GenNative(m_lda_dir, direct, gLong.disp, nil, 0);
	       GenNative(m_ldx_dir, direct, gLong.disp+2, nil, 0);
	       end {if}
	    else begin
	       GenNative(m_ldx_imm, immediate, gLong.disp, nil, 0);
	       GenNative(m_lda_dirX, direct, 0, nil, 0);
	       GenNative(m_ldy_dirX, direct, 2, nil, 0);
	       GenImplied(m_tyx);
	       end {else}
	 else begin
	    if (gLong.disp >= 254) or (gLong.disp < 0) then begin
	       GenImplied(m_txa);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
	       GenImplied(m_tax);
	       gLong.disp := 0;
	       end; {if}
	    GenNative(m_ldy_dirX, direct, gLong.disp+2, nil, 0);
	    GenNative(m_lda_dirX, direct, gLong.disp, nil, 0);
	    GenImplied(m_tyx);
	    end; {else}
	 if (A_X & lLong.preference) = 0 then begin
	    GenImplied(m_phx);
	    GenImplied(m_pha);
	    end; {if}
	 end {else if gLong.where = localAddress}
      else {if gLong.where = globalLabel then} begin
	 gLong.disp := gLong.disp+q;
	 if gLong.fixedDisp then
	    if smallMemoryModel then begin
	       GenNative(m_lda_abs, absolute, gLong.disp, gLong.lab, 0);
	       GenNative(m_ldx_abs, absolute, gLong.disp+2, gLong.lab, 0);
	       end {if}
	    else begin
	       GenNative(m_lda_long, longAbs, gLong.disp+2, gLong.lab, 0);
	       GenImplied(m_tax);
	       GenNative(m_lda_long, longAbs, gLong.disp, gLong.lab, 0);
	       end {else}
	 else
	    if smallMemoryModel then begin
	       GenNative(m_ldy_absX, absolute, gLong.disp+2, gLong.lab, 0);
	       GenNative(m_lda_absX, absolute, gLong.disp, gLong.lab, 0);
	       GenImplied(m_tyx);
	       end {if}
	    else begin
	       GenNative(m_lda_longX, longAbs, gLong.disp+2, gLong.lab, 0);
	       GenImplied(m_tay);
	       GenNative(m_lda_longX, longAbs, gLong.disp, gLong.lab, 0);
	       GenImplied(m_tyx);
	       end; {else}
	 if (A_X & lLong.preference) = 0 then begin
	    GenImplied(m_phx);
	    GenImplied(m_pha);
	    end; {if}
	 end; {else}
      if (A_X & lLong.preference) <> 0 then
	 gLong.where := A_X
      else
	 gLong.where := onStack;
      end; {cgLong,cgULong}

   cgByte,cgUByte,cgWord,cgUWord: begin
      GetPointer(op^.left);
      if gLong.where = inPointer then begin
	 if q = 0 then
	    if gLong.fixedDisp then
	       GenNative(m_lda_indl, direct, gLong.disp, nil, 0)
	    else
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0)
	 else
	    if gLong.fixedDisp then begin
	       GenNative(m_ldy_imm, immediate, q, nil, 0);
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0)
	       end {if}
	    else begin
	       GenImplied(m_tya);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, q, nil, 0);
	       GenImplied(m_tay);
	       GenNative(m_lda_indly, direct, gLong.disp, nil, 0)
	       end; {else}
	 end {if}
      else if gLong.where = localAddress then begin
	 gLong.disp := gLong.disp+q;
	 if gLong.fixedDisp then
	    if (gLong.disp & $FF00) = 0 then
	       GenNative(m_lda_dir, direct, gLong.disp, nil, 0)
	    else begin
	       GenNative(m_ldx_imm, immediate, gLong.disp, nil, 0);
	       GenNative(m_lda_dirX, direct, 0, nil, 0);
	       end {else}
	 else
	    if (gLong.disp & $FF00) = 0 then
	       GenNative(m_lda_dirX, direct, gLong.disp, nil, 0)
	    else begin
	       GenImplied(m_txa);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
	       GenImplied(m_tax);
	       GenNative(m_lda_dirX, direct, 0, nil, 0);
	       end {else}
	 end {else if}
      else {if gLong.where = globalLabel then} begin
	 gLong.disp := gLong.disp+q;
	 if gLong.fixedDisp then
	    if smallMemoryModel then
	       GenNative(m_lda_abs, absolute, gLong.disp, gLong.lab, 0)
	    else
	       GenNative(m_lda_long, longAbs, gLong.disp, gLong.lab, 0)
	 else
	    if smallMemoryModel then
	       GenNative(m_lda_absX, absolute, gLong.disp, gLong.lab, 0)
	    else
	       GenNative(m_lda_longX, longAbs, gLong.disp, gLong.lab, 0)
	 end; {else}
      if optype in [cgByte,cgUByte] then begin
	 GenNative(m_and_imm, immediate, 255, nil, 0);
	 if optype = cgByte then begin
	    GenNative(m_cmp_imm, immediate, 128, nil, 0);
	    lab1 := GenLabel;
	    GenNative(m_bcc, relative, lab1, nil, 0);
	    GenNative(m_ora_imm, immediate, $FF00, nil, 0);
	    GenLab(lab1);
	    end; {if}
	 end; {if}
      end; {case cgByte,cgUByte,cgWord,cgUWord}

   cgSet: begin
      gLong.preference := onStack;
      GenTree(op^.left);
      if op^.r <> 0 then
	 IncAddr(op^.r);
      GenNative(m_pea, immediate, q, nil, 0);
      GenCall(28);
      end; {case cgSet}

   otherwise: ;
   end; {case}
end; {GenInd}


procedure GenIxa (op: icptr);

{ Generate code for a pc_ixa					}

var
   lab1: integer;			{branch label}
   lLong: longType;			{type of address}
   zero: boolean;			{is the index 0?}


   procedure Index;

   { Get the index size						}

   var
      lLong: longType;			{temp for preserving left node info}

   begin {Index}
   zero := false;
   with op^.right^ do begin
      if opcode = pc_ldc then begin
	 if q = 0 then
	    zero := true
	 else
	    GenNative(m_lda_imm, immediate, q, nil, 0);
	 end {if}
      else begin
	 lLong := gLong;
	 GenTree(op^.right);
	 gLong := lLong;
	 end; {else}
      end; {with}
   end; {Index}


begin {GenIxa}
if smallMemoryModel then begin
   lLong := gLong;
   gLong.preference := inPointer+localAddress+globalLabel;
   GenTree(op^.left);
   case gLong.where of

      onStack: begin
	 Index;
	 if not zero then begin
	    GenImplied(m_clc);
	    GenNative(m_adc_s, direct, 1, nil, 0);
	    GenNative(m_sta_s, direct, 1, nil, 0);
	    lab1 := GenLabel;
	    GenNative(m_bcc, relative, lab1, nil, 0);
	    GenNative(m_lda_s, direct, 3, nil, 0);
	    GenImplied(m_ina);
	    GenNative(m_sta_s, direct, 3, nil, 0);
	    GenLab(lab1);
	    end; {if}
	 end; {case onStack}

      inPointer: begin
	 if not gLong.fixedDisp then begin
	    if Complex(op^.right) then begin
	       GenImplied(m_phy);
	       Index;
	       if not zero then begin
		  GenImplied(m_clc);
		  GenNative(m_adc_s, direct, 1, nil, 0);
		  GenNative(m_sta_s, direct, 1, nil, 0);
		  end; {if}
	       GenImplied(m_ply);
	       end {if}
	    else begin
	       GenImplied(m_tya);
	       GenImplied(m_clc);
	       OperA(m_adc_imm, op^.right);
	       GenImplied(m_tay);
	       end; {else}
	    end {if}
	 else begin
	    Index;
	    if not zero then begin
	       GenImplied(m_tay);
	       gLong.fixedDisp := false;
	       end; {if}
	    end; {else}
	 if (inPointer & lLong.preference) = 0 then begin
	    if not gLong.fixedDisp then begin
	       GenImplied(m_tya);
	       GenImplied(m_clc);
	       GenNative(m_adc_dir, direct, gLong.disp, nil, 0);
	       GenNative(m_ldx_dir, direct, gLong.disp+2, nil, 0);
	       lab1 := GenLabel;
	       GenNative(m_bcc, relative, lab1, nil, 0);
	       GenImplied(m_inx);
	       GenLab(lab1);
	       end {if}
	    else begin
	       GenNative(m_ldx_dir, direct, gLong.disp+2, nil, 0);
	       GenNative(m_lda_dir, direct, gLong.disp, nil, 0);
	       end; {else}
	    GenImplied(m_phx);
	    GenImplied(m_pha);
	    gLong.where := onStack;
	    end; {if}
	 end; {case inPointer}

      localAddress,globalLabel: begin
	 if not gLong.fixedDisp then begin
	    if Complex(op^.right) then begin
	       GenImplied(m_phx);
	       Index;
	       if not zero then begin
		  GenImplied(m_clc);
		  GenNative(m_adc_s, direct, 1, nil, 0);
		  GenNative(m_sta_s, direct, 1, nil, 0);
		  end; {if}
	       GenImplied(m_plx);
	       end {if}
	    else begin
	       GenImplied(m_txa);
	       GenImplied(m_clc);
	       OperA(m_adc_imm, op^.right);
	       GenImplied(m_tax);
	       end; {else}
	    end {if}
	 else if Complex(op^.right) then begin
	    Index;
	    if not zero then begin
	       GenImplied(m_tax);
	       gLong.fixedDisp := false;
	       end; {if}
	    end {else if}
	 else begin
	    LoadX(op^.right);
	    gLong.fixedDisp := false;
	    end; {else}
	 if (lLong.preference & gLong.where) = 0 then begin
	    if (lLong.preference & inPointer) <> 0 then begin
	       if gLong.where = localAddress then begin
		  if not gLong.fixedDisp then begin
		     GenNative(m_stz_dir, direct, dworkLoc+2, nil, 0);
		     GenImplied(m_phx);
		     GenImplied(m_tdc);
		     GenImplied(m_clc);
		     if gLong.disp <> 0 then
			GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
		     GenNative(m_adc_s, direct, 1, nil, 0);
		     GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
		     GenImplied(m_plx);
		     end {if}
		  else begin
		     GenNative(m_stz_dir, direct, dworkLoc+2, nil, 0);
		     GenImplied(m_tdc);
		     GenImplied(m_clc);
		     GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
		     GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
		     end; {else}
		  end {if}
	       else begin
		  if not gLong.fixedDisp then begin
		     GenImplied(m_txa);
		     GenImplied(m_clc);
		     GenNative(m_adc_imm, immediate, gLong.disp, gLong.lab, 0);
		     GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
		     GenNative(m_ldx_imm, immediate, gLong.disp, gLong.lab, shift16);
		     lab1 := GenLabel;
		     GenNative(m_bcc, relative, lab1, nil, 0);
		     GenImplied(m_inx);
		     GenLab(lab1);
		     GenNative(m_stx_dir, direct, dworkLoc+2, nil, 0);
		     end {if}
		  else begin
		     GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, shift16);
		     GenNative(m_sta_dir, direct, dworkLoc+2, nil, 0);
		     GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, 0);
		     GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
		     end; {else}
		  end; {else}
	       gLong.where := inPointer;
	       gLong.fixedDisp := true;
	       gLong.disp := dworkLoc;
	       end {if}
	    else begin
	       if gLong.where = localAddress then begin
		  if not gLong.fixedDisp then begin
		     GenNative(m_pea, immediate, 0, nil, 0);
		     GenImplied(m_phx);
		     GenImplied(m_tdc);
		     GenImplied(m_clc);
		     GenNative(m_adc_s, direct, 1, nil, 0);
		     if gLong.disp <> 0 then
			GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
		     GenNative(m_sta_s, direct, 1, nil, 0);
		     end {if}
		  else begin
		     GenNative(m_pea, immediate, 0, nil, 0);
		     GenImplied(m_tdc);
		     GenImplied(m_clc);
		     GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
		     GenImplied(m_pha);
		     end; {else}
		  end {if}
	       else begin
		  if not gLong.fixedDisp then begin
		     GenImplied(m_txa);
		     GenImplied(m_clc);
		     GenNative(m_adc_imm, immediate, gLong.disp, gLong.lab, 0);
		     GenNative(m_ldx_imm, immediate, gLong.disp, gLong.lab, shift16);
		     lab1 := GenLabel;
		     GenNative(m_bcc, relative, lab1, nil, 0);
		     GenImplied(m_inx);
		     GenLab(lab1);
		     GenImplied(m_phx);
		     GenImplied(m_pha);
		     end {if}
		  else begin
		     GenNative(m_pea, immediate, gLong.disp, gLong.lab, shift16);
		     GenNative(m_pea, immediate, gLong.disp, gLong.lab, 0);
		     end; {else}
		  end; {else}
	       gLong.where := onStack;
	       end; {else}
	    end; {if}
	 end; {case localAddress,globalLabel}
      otherwise:
	 Error(cge1);
      end; {case}
   end {if smallMemoryModel or (op^.right^.opcode = pc_ldc)}
else begin
   gLong.preference := onStack;
   GenTree(op^.left);
   GenTree(op^.right);
   if op^.optype in [cgByte,cgWord] then begin
      lab1 := GenLabel;
      GenNative(m_ldx_imm, immediate, $0000, nil, 0);
      GenImplied(m_tay);
      GenNative(m_bpl, relative, lab1, nil, 0);
      GenImplied(m_dex);
      GenLab(lab1);
      GenImplied(m_phx);
      GenImplied(m_pha);
      end {else if}
   else begin
      GenNative(m_pea, immediate, 0, nil, 0);
      GenImplied(m_pha);
      end; {else}
   GenImplied(m_clc);
   GenImplied(m_pla);
   GenNative(m_adc_s, direct, 3, nil, 0);
   GenNative(m_sta_s, direct, 3, nil, 0);
   GenImplied(m_pla);
   GenNative(m_adc_s, direct, 3, nil, 0);
   GenNative(m_sta_s, direct, 3, nil, 0);
   gLong.where := onStack;
   end; {else}
end; {GenIxa}


procedure GenLogic (op: icptr);

{ generate a pc_and, pc_ior, pc_bnd, pc_bor or pc_bxr		}

var
   lab1,lab2: integer;			{label}
   nd: icptr;				{temp node pointer}
   opcode: pcodes;			{operation code}

begin {GenLogic}
opcode := op^.opcode;
if not Complex(op^.left) then
   if Complex(op^.right) then begin
      nd := op^.left;
      op^.left := op^.right;
      op^.right := nd;
      end; {if}
GenTree(op^.left);
if Complex(op^.right) then begin
   GenImplied(m_pha);
   GenTree(op^.right);
   case opcode of
      pc_and,pc_bnd: GenNative(m_and_s, direct, 1, nil, 0);
      pc_ior,pc_bor: GenNative(m_ora_s, direct, 1, nil, 0);
      pc_bxr: GenNative(m_eor_s, direct, 1, nil, 0);
      otherwise:
	 Error(cge1);
      end; {case}
   GenImplied(m_plx);
   GenImplied(m_tax);
   end {if}
else
   case opcode of
      pc_and,pc_bnd: OperA(m_and_imm, op^.right);
      pc_ior,pc_bor: OperA(m_ora_imm, op^.right);
      pc_bxr: OperA(m_eor_imm, op^.right);
      otherwise:
	 Error(cge1);
      end; {case}
end; {GenLogic}


procedure GenSroCpo (op: icptr);

{ Generate code for a pc_sro or pc_cpo			}

var
   lab: pStringPtr;			{op^.lab}
   lab1: integer;			{branch point}
   lval: longint;			{op^.left^.lval}
   opcode: pcodes;			{op^.opcode}
   optype: baseTypeEnum; 		{op^.optype}
   q: integer;				{op^.q}
   special: boolean;			{special save?}

begin {GenSroCpo}
opcode := op^.opcode;
optype := op^.optype;
q := op^.q;
lab := op^.lab;
case optype of
   cgByte, cgUByte: begin
      if (opcode = pc_sro) and (op^.left^.opcode in [pc_inc,pc_dec]) then
	 GenIncDec(op^.left, op)
      else begin
	 if smallMemoryModel and (op^.left^.opcode = pc_ldc)
	    and (op^.left^.q = 0) then begin
	    GenNative(m_sep, immediate, 32, nil, 0);
	    GenNative(m_stz_abs, absolute, q, lab, 0);
	    end {if}
	 else begin
	    if op^.opcode = pc_sro then
	       if op^.left^.opcode = pc_cnv then
		  if (op^.left^.q >> 4) in [ord(cgWord),ord(cgUWord)] then
		     op^.left := op^.left^.left;
	    if (op^.left^.opcode in [pc_ldc,pc_ldc,pc_lod])
               and (op^.left^.p = 0) then begin
	       GenNative(m_sep, immediate, 32, nil, 0);
	       GenTree(op^.left);
	       end {if}
	    else begin
	       GenTree(op^.left);
	       GenNative(m_sep, immediate, 32, nil, 0);
	       end; {else}
	    if smallMemoryModel then
	       GenNative(m_sta_abs, absolute, q, lab, 0)
	    else
	       GenNative(m_sta_long, longabsolute, q, lab, 0);
	    end; {else}
	 GenNative(m_rep, immediate, 32, nil, 0);
         end; {else}
      end;

   cgWord, cgUWord:
      if (opcode = pc_sro) and (op^.left^.opcode in [pc_inc,pc_dec]) then
	 GenIncDec(op^.left, op)
      else begin
	 if smallMemoryModel and (op^.left^.opcode = pc_ldc)
	    and (op^.left^.q = 0) then
	    GenNative(m_stz_abs, absolute, q, lab, 0)
	 else begin
	    GenTree(op^.left);
	    if smallMemoryModel then
	       GenNative(m_sta_abs, absolute, q, lab, 0)
	    else
	       GenNative(m_sta_long, longabsolute, q, lab, 0);
	    end; {else}
         end; {else}

   cgReal, cgDouble, cgComp, cgExtended: begin
      GenTree(op^.left);
      GenNative(m_pea, immediate, q, lab, shift16);
      GenNative(m_pea, immediate, q, lab, 0);
      if opcode = pc_sro then begin
	 if optype = cgReal then
	    GenCall(23)
	 else if optype = cgDouble then
	    GenCall(87)
	 else if optype = cgComp then
	    GenCall(157)
	 else {if optype = cgExtended then}
	    GenCall(158);
	 end {if}
      else {if opcode = pc_cpo then} begin
	 if optype = cgReal then
	    GenCall(159)
	 else if optype = cgDouble then
	    GenCall(160)
	 else if optype = cgComp then
	    GenCall(161)
	 else {if optype = cgExtended then}
	    GenCall(162);
	 end; {else}
      end;

   cgSet: begin
      GenTree(op^.left);
      GenNative(m_pea, immediate, op^.r, lab, shift16);
      GenNative(m_pea, immediate, op^.r, lab, 0);
      GenNative(m_pea, immediate, q, nil, 0);
      GenCall(24);
      end;

   cgLong, cgULong: begin
      if (opcode = pc_sro) and (op^.left^.opcode in [pc_adl,pc_sbl]) then
	 GenAdlSbl(op^.left, op)
      else if (opcode = pc_sro) and (op^.left^.opcode in [pc_inc,pc_dec]) then
	 GenIncDec(op^.left, op)
      else if smallMemoryModel and (op^.left^.opcode = pc_ldc) then begin
	 lval := op^.left^.lval;
	 if long(lval).lsw = 0 then
	    GenNative(m_stz_abs, absolute, q, lab, 0)
	 else begin
	    GenNative(m_lda_imm, immediate, long(lval).lsw, nil, 0);
	    GenNative(m_sta_abs, absolute, q, lab, 0)
	    end; {else}
	 if long(lval).msw = 0 then
	    GenNative(m_stz_abs, absolute, q+2, lab, 0)
	 else begin
	    GenNative(m_ldx_imm, immediate, long(lval).msw, nil, 0);
	    GenNative(m_stx_abs, absolute, q+2, lab, 0)
	    end; {else}
	 if op^.opcode = pc_cpo then
	    GenTree(op^.left);
	 end {if}
      else begin
	 if op^.opcode = pc_sro then
	    gLong.preference := A_X | inPointer | localAddress | globalLabel | constant
	 else
	    gLong.preference := gLong.preference &
	       (A_X | inPointer | localAddress | globalLabel | constant);
	 GenTree(op^.left);
	 case gLong.where of

	    A_X: begin
	       if smallMemoryModel then begin
		  GenNative(m_stx_abs, absolute, q+2, lab, 0);
		  GenNative(m_sta_abs, absolute, q, lab, 0);
		  end {if}
	       else begin
		  GenNative(m_sta_long, longabsolute, q, lab, 0);
		  if opcode = pc_cpo then
		     GenImplied(m_pha);
		  GenImplied(m_txa);
		  GenNative(m_sta_long, longabsolute, q+2, lab, 0);
		  if opcode = pc_cpo then
		     GenImplied(m_pla);
		  end; {else}
	       end;

	    onStack: begin
	       if opcode = pc_sro then
		  GenImplied(m_pla)
	       else {if opcode = pc_cpo then}
		  GenNative(m_lda_s, direct, 1, nil, 0);
	       if smallMemoryModel then
		  GenNative(m_sta_abs, absolute, q, lab, 0)
	       else
		  GenNative(m_sta_long, longabsolute, q, lab, 0);
	       if opcode = pc_sro then
		  GenImplied(m_pla)
	       else {if opcode = pc_cpo then}
		  GenNative(m_lda_s, direct, 3, nil, 0);
	       if smallMemoryModel then
		  GenNative(m_sta_abs, absolute, q+2, lab, 0)
	       else
		  GenNative(m_sta_long, longabsolute, q+2, lab, 0);
	       end;

	    inPointer: begin
	       GenNative(m_ldx_dir, direct, gLong.disp+2, nil, 0);
	       if gLong.fixedDisp then
		  GenNative(m_lda_dir, direct, gLong.disp, nil, 0)
	       else begin
		  GenImplied(m_tya);
		  GenImplied(m_clc);
		  GenNative(m_adc_dir, direct, gLong.disp, nil, 0);
		  if not smallMemoryModel then begin
		     lab1 := GenLabel;
		     GenNative(m_bcc, relative, lab1, nil, 0);
		     GenImplied(m_inx);
		     GenLab(lab1);
		     end; {if}
		  end; {else}
	       if smallMemoryModel then begin
		  GenNative(m_stx_abs, absolute, q+2, lab, 0);
		  GenNative(m_sta_abs, absolute, q, lab, 0);
		  end {if}
	       else begin
		  GenNative(m_sta_long, longabsolute, q, lab, 0);
		  if opcode = pc_cpo then
		     GenImplied(m_pha);
		  GenImplied(m_txa);
		  GenNative(m_sta_long, longabsolute, q+2, lab, 0);
		  if opcode = pc_cpo then
		     GenImplied(m_pla);
		  end; {else}
	       gLong.where := A_X;
	       end;

	    localAddress: begin
	       if smallMemoryModel then
		  GenNative(m_stz_abs, absolute, q+2, lab, 0)
	       else begin
		  GenNative(m_lda_imm, immediate, 0, nil, 0);
		  GenNative(m_sta_long, longabsolute, q+2, lab, 0);
		  end; {else}
	       GenImplied(m_tdc);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
	       if not gLong.fixedDisp then begin
		  GenImplied(m_phx);
		  GenNative(m_adc_s, direct, 1, nil, 0);
		  GenImplied(m_plx);
		  end; {if}
	       if smallMemoryModel then
		  GenNative(m_sta_abs, absolute, q, lab, 0)
	       else
		  GenNative(m_sta_long, longabsolute, q, lab, 0);
	       end;

	    globalLabel:
	       if gLong.fixedDisp then begin
		  if smallMemoryModel then begin
		     GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, 0);
		     GenNative(m_ldx_imm, immediate, gLong.disp, gLong.lab, shift16);
		     GenNative(m_stx_abs, absolute, q+2, lab, 0);
		     GenNative(m_sta_abs, absolute, q, lab, 0);
		     end {if}
		  else begin
		     GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, shift16);
		     GenNative(m_sta_long, longabsolute, q+2, lab, 0);
		     if opcode = pc_cpo then
			GenImplied(m_tax);
		     GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, 0);
		     GenNative(m_sta_long, longabsolute, q, lab, 0);
		     end; {else}
		  gLong.where := A_X;
		  end {if}
	       else begin
		  GenImplied(m_txa);
		  GenImplied(m_clc);
		  GenNative(m_adc_imm, immediate, gLong.disp, gLong.lab, 0);
		  if smallMemoryModel then
		     GenNative(m_sta_abs, absolute, q, lab, 0)
		  else
		     GenNative(m_sta_long, longabsolute, q, lab, 0);
		  GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, shift16);
		  GenNative(m_adc_imm, immediate, 0, nil, 0);
		  if smallMemoryModel then
		     GenNative(m_sta_abs, absolute, q+2, lab, 0)
		  else
		     GenNative(m_sta_long, longabsolute, q+2, lab, 0);
		  end; {else}

	    constant: begin
	       if gLong.lval = 0 then begin
		  if smallMemoryModel then begin
		     GenNative(m_stz_abs, absolute, q+2, lab, 0);
		     GenNative(m_stz_abs, absolute, q, lab, 0);
		     end {if}
		  else begin
		     GenNative(m_lda_imm, immediate, 0, nil, 0);
		     GenNative(m_sta_long, longabsolute, q+2, lab, 0);
		     GenNative(m_sta_long, longabsolute, q, lab, 0);
		     end; {else}
		  end {if}
	       else if not smallMemoryModel then begin
		  GenNative(m_lda_imm, immediate, long(gLong.lval).msw, nil, 0);
		  GenNative(m_sta_long, longabsolute, q+2, lab, 0);
		  GenNative(m_lda_imm, immediate, long(gLong.lval).lsw, nil, 0);
		  GenNative(m_sta_long, longabsolute, q, lab, 0);
		  end {else if}
	       else begin
		  if long(gLong.lval).msw = 0 then
		     GenNative(m_stz_abs, absolute, q+2, lab, 0)
		  else begin
		     GenNative(m_ldx_imm, immediate, long(gLong.lval).msw, nil, 0);
		     GenNative(m_stx_abs, absolute, q+2, lab, 0);
		     end; {else}
		  if long(gLong.lval).lsw = 0 then
		     GenNative(m_stz_abs, absolute, q, lab, 0)
		  else begin
		     GenNative(m_lda_imm, immediate, long(gLong.lval).lsw, nil, 0);
		     GenNative(m_sta_abs, absolute, q, lab, 0);
		     end; {else}
		  if (long(gLong.lval).lsw <> 0) and (long(gLong.lval).msw <> 0) then
		     gLong.where := A_X;
		  end; {else}
	       end; {case constant}

	    otherwise:
	       Error(cge1);
	    end; {case}
	 end; {else}
      end; {case CGLong, cgULong}

   end; {case}
end; {GenSroCpo}


procedure GenSto (op: icptr);

{ Generate code for a pc_sto          			}

var
   disp: integer;			{disp in stack frame}
   opcode: pcodes;			{temp storage for op code}
   optype: baseTypeEnum; 		{operand type}
   short: boolean;			{use short registers?}
   simple: boolean;			{is the load a simple load?}
   preference: integer;			{old preference}
   lLong: longType;			{address record for left node}
   zero: boolean;			{is the operand a constant zero?}


   procedure LoadLSW;

   { load the least significant word of a four byte value	}

   begin {LoadLSW}
   if lLong.where = onStack then
      if opcode = pc_sto then
	 GenImplied(m_pla)
      else
	 GenNative(m_lda_s, direct, 1, nil, 0)
   else if lLong.where <> A_X then
      GenNative(m_lda_imm, immediate, long(lLong.lval).lsw, nil, 0);
   end; {LoadLSW}


   procedure LoadMSW;

   { load the most significant word of a four byte value 	}
   {								}
   { Note: LoadLSW MUST be called first! 			}

   begin {LoadMSW}
   gLong.where := A_X;
   if lLong.where = onStack then
      if opcode = pc_sto then
	 GenImplied(m_pla)
      else begin
	 GenNative(m_lda_s, direct, 3, nil, 0);
	 gLong.where := onStack;
	 end {else}
   else if lLong.where = A_X then
      GenImplied(m_txa)
   else
      GenNative(m_lda_imm, immediate, long(lLong.lval).msw, nil, 0);
   end; {LoadMSW}


   procedure LoadWord;

   { Get the operand for a cgByte, cgUByte, cgWord or cgUWord	}
   { into the accumulator					}

   begin {LoadWord}
   if simple then begin
      with op^.right^ do
	 if opcode = pc_ldc then
	    GenNative(m_lda_imm, immediate, q, nil, 0)
	 else if opcode = pc_lod then
	    GenNative(m_lda_dir, direct, localLabel[r] + q, nil, 0)
	 else {if opcode = pc_ldo then}
	    if smallMemoryModel then
	       GenNative(m_lda_abs, absolute, q, lab, 0)
	    else
	       GenNative(m_lda_long, longAbs, q, lab, 0);
      end {if}
   else begin
      GenImplied(m_pla);
      if short then
	 GenNative(m_sep, immediate, 32, nil, 0);
      end {else}
   end; {LoadWord}


begin {GenSto}
opcode := op^.opcode;
optype := op^.optype;
case optype of

   cgReal,cgDouble,cgComp,cgExtended: begin
      GenTree(op^.right);
      gLong.preference := onStack;
      GenTree(op^.left);
      if optype = cgReal then begin
	 if opcode = pc_sto then
	    GenCall(23)
	 else
	    GenCall(159);
	 end {if}
      else if optype = cgDouble then begin
	 if opcode = pc_sto then
	    GenCall(87)
	 else
	    GenCall(160);
	 end {else if}
      else if optype = cgComp then begin
	 if opcode = pc_sto then
	    GenCall(157)
	 else
	    GenCall(161);
	 end {else if}
      else {if optype = cgExtended then} begin
	 if opcode = pc_sto then
	    GenCall(158)
	 else
	    GenCall(162);
	 end; {else}
      end; {case cgReal,cgDouble,cgComp,cgExtended}

   cgSet: begin
      gLong.preference := onStack;
      GenTree(op^.right);
      gLong.preference := onStack;
      GenTree(op^.left);
      GenNative(m_pea, immediate, op^.q, nil, 0);
      GenCall(24);
      end;

   cgLong,cgULong: begin
      preference := gLong.preference;
      gLong.preference := onStack+constant;
      GenTree(op^.right);
      lLong := gLong;
      gLong.preference := localAddress+inPointer+globalLabel+A_X;
      GenTree(op^.left);
      if gLong.where = onStack then begin
	 GenImplied(m_pla);
	 GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
	 GenImplied(m_pla);
	 GenNative(m_sta_dir, direct, dworkLoc+2, nil, 0);
	 LoadLSW;
	 GenNative(m_sta_indl, direct, dworkLoc, nil, 0);
	 GenNative(m_ldy_imm, immediate, 2, nil, 0);
	 LoadMSW;
	 GenNative(m_sta_indly, direct, dworkLoc, nil, 0);
	 end {if}
      else if gLong.where = A_X then begin
	 GenNative(m_sta_dir, direct, dworkLoc, nil, 0);
	 GenNative(m_stx_dir, direct, dworkLoc+2, nil, 0);
	 LoadLSW;
	 GenNative(m_sta_indl, direct, dworkLoc, nil, 0);
	 GenNative(m_ldy_imm, immediate, 2, nil, 0);
	 LoadMSW;
	 GenNative(m_sta_indly, direct, dworkLoc, nil, 0);
	 end {if}
      else if gLong.where = localAddress then begin
	 LoadLSW;
	 if gLong.fixedDisp then
	    if (gLong.disp & $FF00) = 0 then
	       GenNative(m_sta_dir, direct, gLong.disp, nil, 0)
	    else begin
	       GenNative(m_ldx_imm, immediate, gLong.disp, nil, 0);
	       GenNative(m_sta_dirX, direct, 0, nil, 0);
	       end {else}
	 else begin
	    if (gLong.disp >= 254) or (gLong.disp < 0) then begin
	       GenImplied(m_tay);
	       GenImplied(m_txa);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
	       GenImplied(m_tax);
	       GenImplied(m_tya);
	       gLong.disp := 0;
	       end; {if}
	    GenNative(m_sta_dirX, direct, gLong.disp, nil, 0);
	    end; {else}
	 LoadMSW;
	 if gLong.fixedDisp then
	    if ((gLong.disp+2) & $FF00) = 0 then
	       GenNative(m_sta_dir, direct, gLong.disp+2, nil, 0)
	    else begin
	       GenNative(m_ldx_imm, immediate, gLong.disp+2, nil, 0);
	       GenNative(m_sta_dirX, direct, 0, nil, 0);
	       end {else}
	 else begin
	    if (gLong.disp >= 254) or (gLong.disp < 0) then begin
	       GenImplied(m_tay);
	       GenImplied(m_txa);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
	       GenImplied(m_tax);
	       GenImplied(m_tya);
	       gLong.disp := 0;
	       end; {if}
	    GenNative(m_sta_dirX, direct, gLong.disp+2, nil, 0);
	    end; {else}
	 end {else if}
      else if gLong.where = globalLabel then begin
	 LoadLSW;
	 if gLong.fixedDisp then
	    if smallMemoryModel then
	       GenNative(m_sta_abs, absolute, gLong.disp, gLong.lab, 0)
	    else
	       GenNative(m_sta_long, longAbs, gLong.disp, gLong.lab, 0)
	 else
	    if smallMemoryModel then
	       GenNative(m_sta_absX, absolute, gLong.disp, gLong.lab, 0)
	    else
	       GenNative(m_sta_longX, longAbs, gLong.disp, gLong.lab, 0);
	 LoadMSW;
	 if gLong.fixedDisp then
	    if smallMemoryModel then
	       GenNative(m_sta_abs, absolute, gLong.disp+2, gLong.lab, 0)
	    else
	       GenNative(m_sta_long, longAbs, gLong.disp+2, gLong.lab, 0)
	 else
	    if smallMemoryModel then
	       GenNative(m_sta_absX, absolute, gLong.disp+2, gLong.lab, 0)
	    else
	       GenNative(m_sta_longX, longAbs, gLong.disp+2, gLong.lab, 0);
	 end {else if}
      else begin
	 LoadLSW;
	 if gLong.fixedDisp = true then begin
	    GenNative(m_sta_indl, direct, gLong.disp, nil, 0);
	    GenNative(m_ldy_imm, immediate, 2, nil, 0);
	    end {if}
	 else begin
	    GenNative(m_sta_indlY, direct, gLong.disp, nil, 0);
	    GenImplied(m_iny);
	    GenImplied(m_iny);
	    end; {else}
	 LoadMSW;
	 GenNative(m_sta_indly, direct, gLong.Disp, nil, 0);
	 end; {else}
      end; {case cgLong,cgULong}

   cgByte,cgUByte,cgWord,cgUWord: begin
      short := optype in [cgByte,cgUByte];
      simple := false;
      zero := false;
      if op^.opcode = pc_sto then begin
	 if short then
	    if op^.right^.opcode = pc_cnv then
	       if (op^.right^.q >> 4) in [ord(cgWord),ord(cgUWord)] then
		  op^.right := op^.right^.left;
	 with op^.right^ do begin
	    if opcode = pc_ldo then
	       simple := true
	    else if opcode = pc_lod then
	       simple := (localLabel[r] + q < 256) and (p = 0)
	    else if opcode = pc_ldc then begin
	       simple := true;
	       zero := q = 0;
	       end; {else if}
	    end; {with}
	 end; {if}
      if not (zero or simple) then begin
	 GenTree(op^.right);
	 GenImplied(m_pha);
	 end; {if}
      GetPointer(op^.left);
      if short then
	 if simple then
	    GenNative(m_sep, immediate, 32, nil, 0);
      if gLong.where = inPointer then begin
	 if zero then
	    GenNative(m_lda_imm, immediate, 0, nil, 0)
	 else
	    LoadWord;
	 if gLong.fixedDisp then
	    GenNative(m_sta_indl, direct, gLong.disp, nil, 0)
	 else
	    GenNative(m_sta_indlY, direct, gLong.disp, nil, 0);
	 end {if}
      else if gLong.where = localAddress then begin
	 if gLong.fixedDisp then
	    if (gLong.disp & $FF00) = 0 then
	       if zero then
		  GenNative(m_stz_dir, direct, gLong.disp, nil, 0)
	       else begin
		  LoadWord;
		  GenNative(m_sta_dir, direct, gLong.disp, nil, 0);
		  end {else}
	    else begin
	       if zero then begin
		  GenNative(m_ldx_imm, immediate, gLong.disp, nil, 0);
		  GenNative(m_stz_dirX, direct, 0, nil, 0);
		  end {if}
	       else begin
		  LoadWord;
		  GenNative(m_ldx_imm, immediate, gLong.disp, nil, 0);
		  GenNative(m_sta_dirX, direct, 0, nil, 0);
		  end; {else}
	       end {else}
	 else begin
	    if (gLong.disp & $FF00) <> 0 then begin
	       GenImplied(m_txa);
	       GenImplied(m_clc);
	       GenNative(m_adc_imm, immediate, glong.disp, nil, 0);
	       GenImplied(m_tax);
	       gLong.disp := 0;
	       end; {if}
	    if zero then
	       GenNative(m_stz_dirX, direct, gLong.disp, nil, 0)
	    else begin
	       LoadWord;
	       GenNative(m_sta_dirX, direct, gLong.disp, nil, 0);
	       end; {else}
	    end; {else}
	 end {else if}
      else {if gLong.where = globalLabel then} begin
	 if zero then begin
	    if not smallMemoryModel then
	       GenNative(m_lda_imm, immediate, 0, nil, 0);
	    end {if}
	 else
	    LoadWord;
	 if gLong.fixedDisp then
	    if smallMemoryModel then
	       if zero then
		  GenNative(m_stz_abs, absolute, gLong.disp, gLong.lab, 0)
	       else
		  GenNative(m_sta_abs, absolute, gLong.disp, gLong.lab, 0)
	    else
	       GenNative(m_sta_long, longAbs, gLong.disp, gLong.lab, 0)
	 else
	    if smallMemoryModel then
	       if zero then
		  GenNative(m_stz_absX, absolute, gLong.disp, gLong.lab, 0)
	       else
		  GenNative(m_sta_absX, absolute, gLong.disp, gLong.lab, 0)
	    else
	       GenNative(m_sta_longX, longAbs, gLong.disp, gLong.lab, 0);
	 end; {else}
      if short then
	 GenNative(m_rep, immediate, 32, nil, 0);
      end; {case cgByte,cgUByte,cgWord,cgUWord}

   otherwise:
      Error(cge1);
   end; {case}
end; {GenSto}


procedure GenStrCop (op: icptr);

{ Generate code for a pc_str or pc_cop				}

var
   disp: integer;			{store location}
   optype: baseTypeEnum; 		{op^.optype}
   special: boolean;			{use special processing?}
   zero: boolean;			{is the operand a constant zero?}

begin {GenStrCop}
disp := localLabel[op^.r] + op^.q;
optype := op^.optype;
case optype of
   cgByte, cgUByte, cgWord, cgUWord: begin
      if (op^.opcode = pc_str) and (op^.left^.opcode in [pc_inc,pc_dec]) then
	 GenIncDec(op^.left, op)
      else begin
	 zero := false;
	 if op^.left^.opcode = pc_ldc then
	    if op^.opcode = pc_str then
	       if op^.p = 0 then
		  if op^.left^.q = 0 then
	             zero := true;
	 if not zero then begin
	    if optype in [cgByte,cgUByte] then begin
	       if op^.opcode = pc_str then
		  if op^.left^.opcode = pc_cnv then
		     if (op^.left^.q >> 4) in [ord(cgWord),ord(cgUWord)] then
			op^.left := op^.left^.left;
	       if (op^.left^.opcode in [pc_ldc,pc_ldc,pc_lod])
                  and (op^.opcode = pc_str)
        	  and (op^.left^.p = 0) then begin
		  GenNative(m_sep, immediate, 32, nil, 0);
		  GenTree(op^.left);
		  end {if}
	       else begin
		  GenTree(op^.left);
		  GenNative(m_sep, immediate, 32, nil, 0);
		  end; {else}
	       end {if}
	    else
	       GenTree(op^.left);
	    end {if}
	 else
	    if optype in [cgByte,cgUByte] then
	       GenNative(m_sep, immediate, 32, nil, 0);
	 if op^.p <> 0 then begin
	    StaticLink(op^.p, true, false);
	    GenNative(m_sta_longx, longabsolute, disp, nil, 0);
	    end {if}
	 else if disp > 255 then begin
	    GenNative(m_ldx_imm, immediate, disp, nil, 0);
	    if zero then
	       GenNative(m_stz_dirx, direct, 0, nil, 0)
	    else
	       GenNative(m_sta_dirx, direct, 0, nil, 0);
	    end {else if}
	 else
	    if zero then
	       GenNative(m_stz_dir, direct, disp, nil, 0)
	    else
	       GenNative(m_sta_dir, direct, disp, nil, 0);
	 if optype in [cgByte,cgUByte] then
	    GenNative(m_rep, immediate, 32, nil, 0);
         end; {else}
      end;

   cgReal, cgDouble, cgComp, cgExtended: begin
      GenTree(op^.left);
      GenNative(m_pea, immediate, 0, nil, 0);
      if op^.p = 0 then
	 GenImplied(m_tdc)
      else
	 StaticLink(op^.p, false, true);
      GenImplied(m_clc);
      GenNative(m_adc_imm, immediate, disp, nil, 0);
      GenImplied(m_pha);
      if op^.opcode = pc_str then begin
	 if optype = cgReal then
	    GenCall(23)
	 else if optype = cgDouble then
	    GenCall(87)
	 else if optype = cgComp then
	    GenCall(157)
	 else {if optype = cgExtended then}
	    GenCall(158);
	 end {if}
      else begin
	 if optype = cgReal then
	    GenCall(159)
	 else if optype = cgDouble then
	    GenCall(160)
	 else if optype = cgComp then
	    GenCall(161)
	 else {if optype = cgExtended then}
	    GenCall(162);
	 end; {else}
      end;

   cgLong, cgULong: begin
      if (op^.opcode = pc_str) and (op^.left^.opcode in [pc_adl,pc_sbl]) then
	 GenAdlSbl(op^.left, op)
      else if (op^.opcode = pc_str) and (op^.left^.opcode in [pc_inc,pc_dec]) then
	 GenIncDec(op^.left, op)
      else begin
	 if op^.opcode = pc_str then
            if op^.p = 0 then
	       gLong.preference :=
		  A_X+onStack+inPointer+localAddress+globalLabel+constant
            else
	       gLong.preference :=
		  onStack+constant
	 else
	    gLong.preference := onStack;
	 GenTree(op^.left);
	 case gLong.where of

	    A_X:
	       if disp < 254 then begin
		  GenNative(m_stx_dir, direct, disp+2, nil, 0);
		  GenNative(m_sta_dir, direct, disp, nil, 0);
		  end {else if}
	       else begin
		  GenImplied(m_txy);
		  GenNative(m_ldx_imm, immediate, disp, nil, 0);
		  GenNative(m_sta_dirX, direct, 0, nil, 0);
		  GenNative(m_sty_dirX, direct, 2, nil, 0);
		  if op^.opcode = pc_cop then
		     GenImplied(m_tyx);
		  end; {else}

	    onStack:
	       if op^.p <> 0 then begin
	          StaticLink(op^.p, false, false);
		  if op^.opcode = pc_str then
		     GenImplied(m_pla)
		  else {if op^.opcode = pc_cop then}
		     GenNative(m_lda_s, direct, 1, nil, 0);
		  GenNative(m_sta_longX, longAbsolute, disp, nil, 0);
		  if op^.opcode = pc_str then
		     GenImplied(m_pla)
		  else {if op^.opcode = pc_cop then}
		     GenNative(m_lda_s, direct, 3, nil, 0);
		  GenNative(m_sta_longX, longAbsolute, disp+2, nil, 0);
                  end {if}
               else if disp < 254 then begin
		  if op^.opcode = pc_str then
		     GenImplied(m_pla)
		  else {if op^.opcode = pc_cop then}
		     GenNative(m_lda_s, direct, 1, nil, 0);
		  GenNative(m_sta_dir, direct, disp, nil, 0);
		  if op^.opcode = pc_str then
		     GenImplied(m_pla)
		  else {if op^.opcode = pc_cop then}
		     GenNative(m_lda_s, direct, 3, nil, 0);
		  GenNative(m_sta_dir, direct, disp+2, nil, 0);
		  end {else if}
	       else begin
		  GenNative(m_ldx_imm, immediate, disp, nil, 0);
		  if op^.opcode = pc_str then
		     GenImplied(m_pla)
		  else {if op^.opcode = pc_cop then}
		     GenNative(m_lda_s, direct, 1, nil, 0);
		  GenNative(m_sta_dirX, direct, 0, nil, 0);
		  if op^.opcode = pc_str then
		     GenImplied(m_pla)
		  else {if op^.opcode = pc_cop then}
		     GenNative(m_lda_s, direct, 3, nil, 0);
		  GenNative(m_sta_dirX, direct, 2, nil, 0);
		  end; {else}

	    inPointer: begin
	       if (disp < 254) and (gLong.disp < 254) and gLong.fixedDisp
		  and (disp >= 0) and (gLong.disp >= 0) then begin
		  GenNative(m_lda_dir, direct, gLong.disp, nil, 0);
		  GenNative(m_ldx_dir, direct, gLong.disp+2, nil, 0);
		  GenNative(m_sta_dir, direct, disp, nil, 0);
		  GenNative(m_stx_dir, direct, disp+2, nil, 0);
		  end {if}
	       else if (disp < 254) and (gLong.disp < 254)
		  and (disp >= 0) and (gLong.disp >= 0)
		  and (op^.opcode = pc_str) then begin
		  GenImplied(m_tya);
		  GenImplied(m_clc);
		  GenNative(m_adc_dir, direct, gLong.disp, nil, 0);
		  GenNative(m_sta_dir, direct, disp, nil, 0);
		  GenNative(m_lda_dir, direct, gLong.disp+2, nil, 0);
		  GenNative(m_adc_imm, immediate, 0, nil, 0);
		  GenNative(m_sta_dir, direct, disp+2, nil, 0);
		  end {else if}
	       else begin
		  GenNative(m_ldx_imm, immediate, disp, nil, 0);
		  if not gLong.fixedDisp then begin
		     GenImplied(m_tya);
		     GenImplied(m_clc);
		     GenNative(m_adc_dir, direct, gLong.disp, nil, 0);
		     end {if}
		  else
		     GenNative(m_lda_dir, direct, gLong.disp, nil, 0);
		  GenNative(m_sta_dirX, direct, 0, nil, 0);
		  GenNative(m_lda_dir, direct, gLong.disp+2, nil, 0);
		  if not gLong.fixedDisp then
		     GenNative(m_adc_imm, immediate, 0, nil, 0);
		  GenNative(m_sta_dirX, direct, 2, nil, 0);
		  end; {else}
	       end;

	    localAddress:
	       if disp < 254 then begin
		  GenNative(m_stz_dir, direct, disp+2, nil, 0);
		  GenImplied(m_tdc);
		  GenImplied(m_clc);
		  GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
		  if not gLong.fixedDisp then begin
		     GenImplied(m_phx);
		     GenNative(m_adc_s, direct, 1, nil, 0);
		     GenImplied(m_plx);
		     end; {if}
		  GenNative(m_sta_dir, direct, disp, nil, 0);
		  end {else if disp < 254}
	       else begin
		  if not gLong.fixedDisp then
		     GenImplied(m_phx);
		  GenNative(m_ldx_imm, immediate, disp, nil, 0);
		  GenImplied(m_tdc);
		  GenImplied(m_clc);
		  GenNative(m_adc_imm, immediate, gLong.disp, nil, 0);
		  if not gLong.fixedDisp then begin
		     GenNative(m_adc_s, direct, 1, nil, 0);
		     GenImplied(m_ply);
		     end; {if}
		  GenNative(m_sta_dirX, direct, 0, nil, 0);
		  GenNative(m_stz_dirX, direct, 2, nil, 0);
		  end; {else}

	    globalLabel: begin
	       if not gLong.fixedDisp then
		  GenImplied(m_txa)
	       else if disp > 253 then
		  GenNative(m_ldx_imm, immediate, disp, nil, 0);
	       if gLong.fixedDisp then
		  GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, 0)
	       else begin
		  GenImplied(m_clc);
		  GenNative(m_adc_imm, immediate, gLong.disp, gLong.lab, 0);
		  end; {else}
	       if disp < 254 then
		  GenNative(m_sta_dir, direct, disp, nil, 0)
	       else
		  GenNative(m_sta_dirX, direct, 0, nil, 0);
	       GenNative(m_lda_imm, immediate, gLong.disp, gLong.lab, shift16);
	       if not gLong.fixedDisp then
		  GenNative(m_adc_imm, immediate, 0, nil, 0);
	       if disp < 254 then
		  GenNative(m_sta_dir, direct, disp+2, nil, 0)
	       else
		  GenNative(m_sta_dirX, direct, 2, nil, 0);
	       end;

	    constant:
	       if op^.p <> 0 then begin
	          StaticLink(op^.p, false, false);
		  GenNative(m_lda_imm, immediate, long(gLong.lval).lsw, nil, 0);
		  GenNative(m_sta_longX, longAbsolute, disp, nil, 0);
		  GenNative(m_lda_imm, immediate, long(gLong.lval).msw, nil, 0);
		  GenNative(m_sta_longX, longAbsolute, disp+2, nil, 0);
                  end {if}
	       else if disp < 254 then begin
		  GenNative(m_lda_imm, immediate, long(gLong.lval).lsw, nil, 0);
		  GenNative(m_sta_dir, direct, disp, nil, 0);
		  GenNative(m_lda_imm, immediate, long(gLong.lval).msw, nil, 0);
		  GenNative(m_sta_dir, direct, disp+2, nil, 0);
		  end {else}
	       else begin
		  GenNative(m_ldx_imm, immediate, disp, nil, 0);
		  GenNative(m_lda_imm, immediate, long(gLong.lval).lsw, nil, 0);
		  GenNative(m_sta_dirX, direct, 0, nil, 0);
		  GenNative(m_lda_imm, immediate, long(gLong.lval).msw, nil, 0);
		  GenNative(m_sta_dirX, direct, 2, nil, 0);
		  end; {else}

	    otherwise:
	       Error(cge1);
	    end; {case}
	 end; {else}
      end;

   cgSet: begin
      GenTree(op^.left);
      GenNative(m_pea, immediate, 0, nil, 0);
      if op^.p = 0 then
	 GenImplied(m_tdc)
      else
	 StaticLink(op^.p, false, true);
      GenImplied(m_clc);
      GenNative(m_adc_imm, immediate, disp, nil, 0);
      GenImplied(m_pha);
      GenNative(m_pea, immediate, op^.s, nil, 0);
      GenCall(24);
      end;

   otherwise: ;

   end; {case}
end; {GenStrCop}


procedure DirEnp;

{ Generate code for a dc_enp					}

begin {DirEnp}
enpFound := true;
GenImplied(d_end);
EndSeg;
InitLabels;
end; {DirEnp}


{$optimize 15}

procedure GenTree {op: icptr};

{ generate code for op and its children				}
{								}
{ parameters:							}
{    op - opcode for which to generate code			}


   procedure GenAbiBntNgiNotOddSqi (op: icptr);

   { Generate code for a pc_abi, pc_bnt, pc_ngi pc_not, pc_odd, pc_sqi }

   var
      lab1: integer;

   begin {GenAbiBntNgiNotOddSqi}
   GenTree(op^.left);
   case op^.opcode of
      pc_abi: begin
	 lab1 := GenLabel;
         GenImplied(m_tax);
	 GenNative(m_bpl, relative, lab1, nil, 0);
	 GenNative(m_eor_imm, immediate, -1, nil, 0);
	 GenImplied(m_ina);
	 GenLab(lab1);
	 end;

      pc_bnt:
	 GenNative(m_eor_imm, immediate, -1, nil, 0);

      pc_ngi: begin
	 GenNative(m_eor_imm, immediate, -1, nil, 0);
	 GenImplied(m_ina);
	 end; {case pc_ngi}

      pc_not:
	 GenNative(m_eor_imm, immediate, 1, nil, 0);

      pc_odd:
	 GenNative(m_and_imm, immediate, 1, nil, 0);

      pc_sqi: begin
	 GenImplied(m_tax);
	 GenCall(32);
	 if rangeCheck then
	    GenCall(147);
	 end;
      end; {case}
   end; {GenAbiBntNgiNotOddSqi}


   procedure GenAblBnlNglOdlSql (op: icptr);

   { Generate code for a pc_abl, pc_bnl, pc_ngl, pc_odl, pc_sql	}

   var
      lab1: integer;			{branch point}

   begin {GenAblBnlNglOdlSql}
   gLong.preference := onStack;
   GenTree(op^.left);
   case op^.opcode of
      pc_abl: begin
	 lab1 := GenLabel;
	 GenNative(m_lda_s, direct, 3, nil, 0);
	 GenNative(m_bpl, relative, lab1, nil, 0);
	 GenImplied(m_sec);
	 GenNative(m_lda_imm, immediate, 0, nil, 0);
	 GenNative(m_sbc_s, direct, 1, nil, 0);
	 GenNative(m_sta_s, direct, 1, nil, 0);
	 GenNative(m_lda_imm, immediate, 0, nil, 0);
	 GenNative(m_sbc_s, direct, 3, nil, 0);
	 GenNative(m_sta_s, direct, 3, nil, 0);
	 GenLab(lab1);
	 end;

      pc_bnl: begin
	 GenNative(m_lda_s, direct, 1, nil, 0);
	 GenNative(m_eor_imm, immediate, -1, nil, 0);
	 GenNative(m_sta_s, direct, 1, nil, 0);
	 GenNative(m_lda_s, direct, 3, nil, 0);
	 GenNative(m_eor_imm, immediate, -1, nil, 0);
	 GenNative(m_sta_s, direct, 3, nil, 0);
	 end;

      pc_ngl: begin
	 GenImplied(m_sec);
	 GenNative(m_lda_imm, immediate, 0, nil, 0);
	 GenNative(m_sbc_s, direct, 1, nil, 0);
	 GenNative(m_sta_s, direct, 1, nil, 0);
	 GenNative(m_lda_imm, immediate, 0, nil, 0);
	 GenNative(m_sbc_s, direct, 3, nil, 0);
	 GenNative(m_sta_s, direct, 3, nil, 0);
	 end;

      pc_odl: begin
	 GenImplied(m_pla);
	 GenImplied(m_plx);
	 GenNative(m_and_imm, immediate, 1, nil, 0);
	 end;

      pc_sql: begin
	 GenNative(m_lda_s, direct, 3, nil, 0);
	 GenImplied(m_pha);
	 GenNative(m_lda_s, direct, 3, nil, 0);
	 GenImplied(m_pha);
	 GenCall(133);
	 end;
      end; {case}
   gLong.where := onStack;
   end; {GenAblBnlNglOdlSql}


   procedure GenAbrNgr (op: icptr);

   { generate a pc_abr or pc_ngr				}

   begin {GenAbrNgr}
   GenTree(op^.left);
   GenNative(m_lda_s, direct, 9, nil, 0);
   if op^.opcode = pc_abr then
      GenNative(m_and_imm, immediate, $7FFF, nil, 0)
   else {op^.opcode = pc_ngr}
      GenNative(m_eor_imm, immediate, $8000, nil, 0);
   GenNative(m_sta_s, direct, 9, nil, 0);
   end; {GenAbrNgr}


   procedure GenAdi (op: icptr);

   { generate a pc_adi						}

   var
      nd: icptr;

   begin {GenAdi}
   if not Complex(op^.left) then
      if Complex(op^.right) then begin
	 nd := op^.left;
	 op^.left := op^.right;
	 op^.right := nd;
	 end; {if}
   GenTree(op^.left);
   if Complex(op^.right) then begin
      GenImplied(m_pha);
      GenTree(op^.right);
      GenImplied(m_clc);
      GenNative(m_adc_s, direct, 1, nil, 0);
      GenImplied(m_plx);
      end {if}
   else begin
      GenImplied(m_clc);
      OperA(m_adc_imm, op^.right);
      end; {else}
   if rangeCheck then
      GenCall(147);
   end; {GenAdi}


   procedure GenAt2 (op: icptr);

   { Generate code for a pc_at2					}

   begin {GenAt2}
   GenTree(op^.left);
   GenTree(op^.right);
   GenCall(123);
   end; {GenAt2}


   procedure GenBinLong (op: icptr);

   { generate one of: pc_blr, pc_blx, pc_bal, pc_dvl, pc_mdl,	}
   {    pc_mpl, pc_sll, pc_slr, pc_udl, pc_ulm, pc_uml, pc_vsr	}

   var
      nd: icptr;			{for swapping left/right children}


      procedure GenOp (ops, opi: integer);

      { generate a binary operation				}
      {								}
      { parameters:						}
      {    ops - stack version of operation			}
      {    opi - immediate version of operation			}

      var
	 lab1: integer;			{label number}

      begin {GenOp}
      GenImplied(m_pla);
      if gLong.where = constant then begin
	 GenNative(opi, immediate, long(gLong.lval).lsw, nil, 0);
	 GenImplied(m_pha);
	 GenNative(m_lda_s, direct, 3, nil, 0);
	 GenNative(opi, immediate, long(gLong.lval).msw, nil, 0);
	 GenNative(m_sta_s, direct, 3, nil, 0);
	 end {if}
      else begin
	 GenNative(ops, direct, 3, nil, 0);
	 GenNative(m_sta_s, direct, 3, nil, 0);
	 GenImplied(m_pla);
	 GenNative(ops, direct, 3, nil, 0);
	 GenNative(m_sta_s, direct, 3, nil, 0);
	 end; {else}
      end; {GenOp}


   begin {GenBinLong}
   if (op^.left^.opcode = pc_ldc) and
      (op^.opcode in [pc_blr,pc_blx,pc_bal]) then begin
      nd := op^.left;
      op^.left := op^.right;
      op^.right := nd;
      end; {if}
   gLong.preference := onStack;
   GenTree(op^.left);
   if op^.opcode in [pc_blr,pc_blx,pc_bal] then begin
      gLong.preference := constant;
      GenTree(op^.right);
      end {if}
   else if op^.opcode in [pc_mdl,pc_uml,pc_udl,pc_ulm] then begin
      gLong.preference := A_X;
      GenTree(op^.right);
      if gLong.where = onStack then begin
         GenImplied(m_pla);
         GenImplied(m_plx);
         end; {if}
      end {else if}
   else begin
      gLong.preference := onStack;
      GenTree(op^.right);
      end; {else}
   case op^.opcode of

      pc_blr: GenOp(m_ora_s, m_ora_imm);

      pc_blx: GenOp(m_eor_s, m_eor_imm);

      pc_bal: GenOp(m_and_s, m_and_imm);

      pc_dvl: GenCall(134);

      pc_mdl: GenCall(135);

      pc_mpl: GenCall(133);

      pc_sll: GenCall(136);

      pc_slr: GenCall(171);

      pc_udl: GenCall(173);

      pc_ulm: GenCall(174);

      pc_uml: GenCall(172);

      pc_vsr: GenCall(170);

      otherwise: Error(cge1);
      end; {case}
   gLong.where := onStack;
   end; {GenBinLong}


   procedure GenBno (op: icptr);

   { Generate code for a pc_bno					}

   var
      lLong: longType;			{requested address type}

   begin {GenBno}
   lLong := gLong;
   GenTree(op^.left);
   gLong := lLong;
   GenTree(op^.right);
   end; {GenBno}


   procedure GenChk (op: icptr);

   { Generate code for a pc_chk					}

   begin {GenChk}
   gLong.preference := onStack;
   GenTree(op^.left);
   case op^.optype of
      otherwise:
         Error(cge1);
      cgByte,cgUByte,cgWord,cgUWord: begin
	 GenNative(m_ldx_imm, immediate, op^.r, nil, 0);
	 GenNative(m_ldy_imm, immediate, op^.q, nil, 0);
	 GenCall(33);
	 end;
      cgLong,cgULong:
         if (op^.lval = 1) and (op^.lval2 = maxaddr) then
            GenCall(34)
         else begin
	    GenNative(m_pea, immediate, long(op^.lval).msw, nil, 0);
	    GenNative(m_pea, immediate, long(op^.lval).lsw, nil, 0);
	    GenNative(m_pea, immediate, long(op^.lval2).msw, nil, 0);
	    GenNative(m_pea, immediate, long(op^.lval2).lsw, nil, 0);
            GenCall(179);
            end; {else}
     end; {case}
   end; {GenChk}


   procedure GenCsp (op: icptr);

   { Generate code for a pc_csp					}
   {								}
   { parameters:						}
   {    op - operation						}

   var
      lLong: longType;			   {used to reserve gLong}

   begin {GenCsp}
   lLong := gLong;
   gLong.preference := onStack;
   GenTree(op^.left);
   gLong := lLong;
   case op^.q of
      otherwise:
	 Error(cge1);
      1, {get from a file}
      2, {put to a file}
      3, {open}
      4, {close}
      5, {read an integer}
      6, {read a real}
      7, {read a character from a file}
      8, {write a character to a file}
      9, {write an integer to a file}
      10, {write real to a file}
      11, {new}
      13, {readln}
      14, {write an end of line}
      15, {write a form feed}
      17, {dispose}
      26, {writeln to stout}
      27, {writeln to errout}
      35, {clear an area of memory}
      44, {seek a file record}
      45, {write a string}
      46, {write a boolean}
      48, {eof(f)}
      49, {eoln(f)}
      58, {read character from input}
      59, {read int from input}
      60, {readln(input)}
      61, {read real from input}
      62, {write real to output}
     185, {eof(input)}
     186: {eoln(input)}
	 GenCall(op^.q);
      12: {writeln string}
	 GenCall(155);
      19: {write string}
	 GenCall(153);
      22: {writeln string to error out}
	 GenCall(156);
      23: {write string to error out}
	 GenCall(154);
      16,34,42,43: begin {variations on write integer}
	 GenNative(m_pea, immediate, ord((op^.q=34) or (op^.q=43)), nil, 0);
	 GenNative(m_pea, immediate, ord(op^.q>=42), nil, 0);
	 GenCall(21);
	 end;
      20,21,24,25: begin {variations on write constant string}
	GenNative(m_pea, immediate, ord(not odd(op^.q)), nil, 0);
	GenNative(m_pea, immediate, ord(op^.q>=24), nil, 0);
	GenCall(19);
	end;
      28,29,30,31: begin {variations on write boolean}
	GenNative(m_pea, immediate, ord(not odd(op^.q)), nil, 0);
	GenNative(m_pea, immediate, ord(op^.q>=30), nil, 0);
	GenCall(20);
	end;
      32: begin {form feed to standard out}
	GenNative(m_pea, immediate, 12, nil, 0);
	GenCall(151);
	end;
      33: begin {form feed to error out}
	GenNative(m_pea, immediate, 12, nil, 0);
	GenCall(152);
	end;
      36,37,38,39: begin {variations on write character}
	GenNative(m_pea, immediate, ord(not odd(op^.q)), nil, 0);
	GenNative(m_pea, immediate, ord(op^.q>=38), nil, 0);
	GenCall(22);
	end;
      40,41: {write a single character}
	GenCall(151+op^.q-40);
      50:
	GenCall(109);
      51, {pack}
      52: {unpack}
	GenCall(op^.q+74);
      53: {write real to error out}
	GenCall(128);
      66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,82,85,
      86,87,88,90,91,92,93:
	GenCall(op^.q+25);
      81, {cnvsl}
      83: {random int and longint} begin
	GenCall(op^.q+25);
	if op^.optype = cgLong then
	  if (gLong.preference & A_X) = 0 then begin
	    gLong.where := onStack;
	    GenImplied(m_phx);
	    GenImplied(m_pha);
	    end
	  else
	    gLong.where := A_X;
	end;
      84:
	GenCall(79);
      95: {nop};
      96, {new open record}
      97: {dispose open record}
	GenCall(op^.q+35);
      98, {read long from stin}
      99: {read long from file} begin
	GenCall(op^.q+42);
	gLong.where := onStack;
	end;
      102: {write long to file}
	GenCall(144);
      100, {write long to stout}
      101: {write long to errout} begin
	GenNative(m_pea, immediate, 0, nil, 0);
	GenNative(m_pea, immediate, ord(odd(op^.q)), nil, 0);
	GenCall(143);
	end;
      115: {redirect input/output}
	GenCall(148);
      116: {four-byte new}
	GenCall(180);
      117: {Member}
        GenCall(181);
      118: {NewObject}
        GenCall(182);
      119,120: begin {FixString}
        GenCall(op^.q + 64);
	gLong.where := onStack;
        end;
      end; {case}
   end; {GenCsp}


   procedure GenCui (op: icptr);

   { Generate code for a pc_cui					}

   var
      lab1: integer;			{return point}
      lLong: longType;			{used to reserve gLong}

   begin {GenCui}
   {generate parameters}
   lLong := gLong;			{place the operands on the stack}
   GenTree(op^.right);
   gLong.preference := onStack;		{get the address to call}
   GenTree(op^.left^.left);
   gLong := lLong;

   lab1 := GenLabel;			{create a return label}
   GenNative(m_lda_s, direct, 1, nil, 0); {place the call/return addrs on stack}
   GenImplied(m_dea);
   GenImplied(m_pha);
   GenNative(m_sep, immediate, 32, nil, 0);
   GenNative(m_lda_s, direct, 5, nil, 0);
   GenNative(m_sta_s, direct, 3, nil, 0);
   GenNative(m_lda_imm, genAddress, lab1, nil, shift16);
   GenNative(m_sta_s, direct, 6, nil, 0);
   GenNative(m_rep, immediate, 32, nil, 0);
   GenNative(m_lda_imm, genAddress, lab1, nil, sub1);
   GenNative(m_sta_s, direct, 4, nil, 0);

   GenTree(op^.left^.right);		{get the static level}
   GenImplied(m_tax);

   GenImplied(m_rtl);			{indirect call}
   GenLab(lab1);

   gLong.where := A_X;			{save the returned value}
   SaveRetValue(op^.optype);
   end; {GenCui}


   procedure GenCum (op: icptr);

   { Generate code for a pc_cum					}

   var
      lab1, lab2: integer;		{return point; jsl patch location}
      sDisp: unsigned;			{size of the parameters}


      function Size (op: icptr): unsigned;

      { Find the length of the parameters in the tree		}
      {								}
      { parameters:						}
      {    op - tree to scan					}
      {								}
      { returns: Length of the parameters			}

      begin {Size}
      if op^.opcode = pc_bno then
         Size := Size(op^.left) + Size(op^.right)
      else if op^.opcode = pc_stk then
         case op^.optype of
	    cgByte,cgUByte,cgWord,cgUWord: Size := cgWordSize;
            cgLong,cgULong,cgString,cgVoid: Size := cgLongSize;
	    cgReal,cgDouble,cgComp,cgExtended: Size := cgExtendedSize;
	    cgSet: Size := op^.left^.q;
            end {case}
      else
         Size := 0;
      end; {Size}


   begin {GenCum}
   {generate parameters}
   sDisp := Size(op^.left);		{find the disp of the SELF parm}
   GenTree(op^.left);			{place the operands on the stack}

   lab1 := GenLabel;			{create a return/jsl label}
   if jslOptimizations then begin

      {use self-modifying code for an indirect call}
      lab2 := GenLabel;
      GenImplied(m_phd);
      GenImplied(m_tsc);
      GenImplied(m_tcd);
      GenNative(m_ldy_imm, immediate, long(op^.lval).lsw + 1, nil, 0);
      GenNative(m_lda_indly, direct, sDisp - 1, nil, 0);
      GenNative(m_sta_long, longAbs, lab2, nil, 0);
      GenImplied(m_dey);
      GenNative(m_lda_indly, direct, sDisp - 1, nil, 0);
      GenNative(m_sta_long, longAbs, lab1, nil, 0);
      GenImplied(m_pld);
      GenImplied(m_jsl);
      GenLab(lab1);
      GenImplied(m_jsl);
      GenLab(lab2);
      GenImplied(m_jsl);
      GenImplied(m_jsl);
      end {if}        
   else begin

      {do a ROMable indirect call}

      {place the return addr on the stack}
      GenImplied(m_phk);
      GenNative(m_lda_imm, genAddress, lab1, nil, sub1);
      GenImplied(m_pha);

      {get the address to call}
      if op^.lval < maxint-2 then begin
	 GenNative(m_lda_s, direct, sDisp+2, nil, 0);
	 GenNative(m_sta_dir, direct, dWorkLoc+2, nil, 0);
	 GenNative(m_lda_s, direct, sDisp, nil, 0);
	 GenNative(m_sta_dir, direct, dWorkLoc, nil, 0);
	 GenNative(m_ldy_imm, immediate, long(op^.lval).lsw+2, nil, 0);
	 GenNative(m_sep, immediate, 32, nil, 0);
	 GenNative(m_lda_indly, direct, dWorkLoc, nil, 0);
	 GenImplied(m_pha);
	 GenNative(m_rep, immediate, 32, nil, 0);
	 GenNative(m_ldy_imm, immediate, long(op^.lval).lsw, nil, 0);
	 GenNative(m_lda_indly, direct, dWorkLoc, nil, 0);
	 GenImplied(m_dea);
	 GenImplied(m_pha);
	 end {if}
      else begin
	 GenImplied(m_clc);
	 GenNative(m_lda_s, direct, sDisp, nil, 0);
	 GenNative(m_adc_imm, immediate, long(op^.lval).lsw, nil, 0);
	 GenNative(m_sta_dir, direct, dWorkLoc, nil, 0);
	 GenNative(m_lda_s, direct, sDisp+2, nil, 0);
	 GenNative(m_adc_imm, immediate, long(op^.lval).msw, nil, 0);
	 GenNative(m_sta_dir, direct, dWorkLoc+2, nil, 0);
	 GenNative(m_ldy_imm, immediate, 2, nil, 0);
	 GenNative(m_sep, immediate, 32, nil, 0);
	 GenNative(m_lda_indly, direct, dWorkLoc, nil, 0);
	 GenImplied(m_pha);
	 GenNative(m_rep, immediate, 32, nil, 0);
	 GenNative(m_lda_indl, direct, dWorkLoc, nil, 0);
	 GenImplied(m_pha);
	 end; {else}

      {indirect call}
      GenImplied(m_rtl);
      GenLab(lab1);
      end; {else}

   gLong.where := A_X;			{save the returned value}
   SaveRetValue(op^.optype);
   end; {GenCum}


   procedure GenCup (op: icptr);

   { Generate code for a pc_cup					}

   var
      lLong: longType;			   {used to reserve gLong}

   begin {GenCup}
   {generate parameters}
   lLong := gLong;
   GenTree(op^.left);
   gLong := lLong;

   {create the static link}
   if (op^.lab = nil) or (not noGlobalLabels) then begin
      if op^.q = 0 then begin
	 GenImplied(m_tdc);
	 GenImplied(m_tax);
	 end {if}
      else
	 StaticLink(op^.q, false, false);
      end; {if}

   {generate the jsl}
   if op^.lab = nil then
      GenNative(m_jsl, longAbs, op^.r, nil, 0)
   else   
      GenNative(m_jsl, longAbs, 0, op^.lab, 0);

   {save the returned value}
   gLong.where := A_X;
   SaveRetValue(op^.optype);
   end; {GenCup}


   procedure GenDifIntUni (op: icptr);

   { Generate code for a pc_dif, pc_int, pc_uni			}

   var
      snum: integer;			{call number}

   begin {GenDifIntUni}
   GenTree(op^.left);
   GenTree(op^.right);
   case op^.opcode of
      pc_dif: snum := 38;
      pc_int: snum := 39;
      pc_uni: snum := 40;
      end; {case}
   GenCall(snum);
   end; {GenDifIntUni}


   procedure GenDviMod (op: icptr);

   { Generate code for a pc_dvi, pc_mod, pc_udi or pc_uim	}

   var
      opcode: pcodes;			{temp storage}

   begin {GenDviMod}
   if Complex(op^.right) then begin
      GenTree(op^.right);
      if Complex(op^.left) then begin
	 GenImplied(m_pha);
	 GenTree(op^.left);
	 GenImplied(m_plx);
	 end {if}
      else begin
	 GenImplied(m_tax);
	 GenTree(op^.left);
	 end; {else}
      end {if}
   else begin
      GenTree(op^.left);
      LoadX(op^.right);
      end; {else}
   opcode := op^.opcode;
   if opcode = pc_mod then
      GenCall(124)
   else if opcode = pc_dvi then
      GenCall(41)
   else {if opcode in [pc_udi,pc_uim] then} begin
      GenCall(165);
      if opcode = pc_uim then
	 GenImplied(m_txa);
      end; {else}
   if rangeCheck then
      GenCall(147);
   end; {GenDviMod}


   { Generate code for a pc_ent					}
   procedure GenEnt(op: icptr);
   var
     i: integer;
     len: integer;

   begin {GenEnt}

   if debugStrFlag then begin
     len := length(op^.lab^);
     CnOut(m_brl);
     CnOut2(len + 3);
     CnOut2($7771);
     CnOut(len);
     for i := 1 to len do
       CnOut(ord(op^.lab^[i]));
   end;

   if rangeCheck then begin		{if range checking is on, check for a stack overflow}
      GenNative(m_pea, immediate, localSize - returnSize - 1, nil, 0);
      GenCall(129);
      end; {if}

   if localSize = 0 then begin		{create the stack frame}
      if parameterSize <> 0 then begin
	 GenImplied(m_tsc);
	 GenImplied(m_phd);
	 GenImplied(m_tcd);
	 end; {if}
      end {if}
   else if localSize = 2 then begin
      GenImplied(m_phx);
      GenImplied(m_tsc);
      GenImplied(m_phd);
      GenImplied(m_tcd);
      end {else if}
   else begin
      GenImplied(m_tsc);
      GenImplied(m_sec);
      GenNative(m_sbc_imm, immediate, localSize, nil, 0);
      GenImplied(m_tcs);
      GenImplied(m_phd);
      GenImplied(m_tcd);
      end; {if}

   if staticLoc <> 0 then		{set up the static link}
      if localSize <> 2 then
         GenNative(m_stx_dir, direct, staticLoc, nil, 0);

   if dataBank then begin		{preserve and set data bank}
      GenImplied(m_phb);
      GenImplied(m_phb);
      GenImplied(m_pla);
      GenNative(m_sta_dir, direct, bankLoc, nil, 0);
      GenNative(m_pea, immediate, 0, @'~GLOBALS', shift8);
      GenImplied(m_plb);
      GenImplied(m_plb);
      end; {if}

   {no pc_nam (yet)}
   namePushed := false;
   end; {GenEnt}


   procedure GenFix (op: icptr);

   { Generate code for a pc_fix					}

   begin {GenFix}
   GenNative(m_pea, immediate, localLabel[op^.q], nil, 0);
   if op^.optype = cgReal then
      GenCall(83)
   else if op^.optype = cgDouble then
      GenCall(86)
   else if op^.optype = cgComp then
      GenCall(178)
   end; {GenFix}


   procedure GenFjpTjp (op: icptr);

   { Generate code for a pc_fjp or pc_tjp			}

   var
      lab1: integer;			{branch point}
      opcode: pcodes;			{op^.left^.opcode}

   begin {GenFjpTjp}
   if op^.left^.opcode in [pc_equ,pc_geq,pc_grt,pc_les,pc_leq,pc_neq] then
      if op^.left^.opcode in [pc_equ,pc_neq] then
	 GenEquNeq(op^.left, op^.opcode, op^.q)
      else
	 GenCmp(op^.left, op^.opcode, op^.q)
   else begin
      lab1 := GenLabel;
      GenTree(op^.left);
      opcode := op^.left^.opcode;
      if NeedsCondition(opcode) then
	 GenImplied(m_tax)
      else if opcode = pc_ind then
         if op^.left^.optype in [cgByte,cgUByte] then
	    GenImplied(m_tax);
      if op^.opcode = pc_fjp then                    
	 GenNative(m_bne, relative, lab1, nil, 0)
      else {if op^.opcode = pc_tjp then}
	 GenNative(m_beq, relative, lab1, nil, 0);
      GenNative(m_brl, longrelative, op^.q, nil, 0);
      GenLab(lab1);
      end; {else}
   end; {GenFjpTjp}


   procedure GenInn (op: icptr);

   { Generate code for a pc_inn					}

   label 1;

   const
      maxCard = 8;			{largest constant set cardinality to
					 use branches on}

   var
      lab1: integer;			{branch label}
      i,j: integer;			{loop counters}
      byte: integer;			{one byte of the set array}
      card: integer;			{cardinality of the set}
      constants: array[1..maxCard] of integer; {ord of set elements}
      done: boolean;			{used to see if the operation is done}
      lop: pcodes;			{op code of top of set tree}

   begin {GenInn}
   done := false;
   GenTree(op^.left);
   lop := op^.right^.opcode;
   if lop = pc_ldc then
      with op^.right^.setp^ do begin
	 card := 0;
	 for i := 1 to smax do begin
	    byte := ord(sval[i]);
	    if byte <> 0 then
	       for j := 0 to 7 do begin
		  if odd(byte) then begin
		     if card = maxCard then
			goto 1;
		     card := card+1;
		     constants[card] := (i-1)*8+j;
		     end; {if}
		  byte := byte >> 1;
		  end; {for}
	    end; {for}
	 lab1 := GenLabel;
	 GenNative(m_ldx_imm, immediate, 1, nil, 0);
	 for i := 1 to card do begin
	    GenNative(m_cmp_imm, immediate, constants[i], nil, 0);
	    GenNative(m_beq, relative, lab1, nil, 0);
	    end; {for}
	 GenImplied(m_dex);
	 GenLab(lab1);
	 GenImplied(m_txa);
	 done := true;
	 end; {with}
1: if not done then begin
      GenImplied(m_pha);
      if lop = pc_ldo then begin
	 with op^.right^ do begin
	    GenNative(m_pea, immediate, r, lab, shift16);
	    GenNative(m_pea, immediate, r, lab, 0);
	    GenNative(m_pea, immediate, q, nil, 0);
	    GenCall(130);
	    end; {with}
	 end {if}
      else if lop = pc_lod then begin
	 with op^.right^ do begin
	    GenNative(m_pea, immediate, 0, nil, 0);
	    if p = 0 then
	       GenImplied(m_tdc)
	    else
	       StaticLink(p, false, true);
	    GenImplied(m_clc);
	    GenNative(m_adc_imm, immediate, localLabel[r]+q, nil, 0);
	    GenImplied(m_pha);
	    GenNative(m_pea, immediate, s, nil, 0);
	    GenCall(130);
	    end; {with}
	 end{else if}
      else begin
	 GenTree(op^.right);
	 GenCall(42);
	 end; {else}
      end; {if}
   end; {GenInn}


   procedure GenLaoLad (op: icptr);

   { Generate code for a pc_lao, pc_lad				}

   var
      q: integer;			{displacement}

   begin {GenLaoLad}
   if op^.opcode = pc_lad then
      q := 0
   else
      q := op^.q;
   if (globalLabel & gLong.preference) <> 0 then begin
      gLong.fixedDisp := true;
      gLong.where := globalLabel;
      gLong.disp := q;
      gLong.lab := op^.lab;
      end {if}
   else if (A_X & gLong.preference) <> 0 then begin
      gLong.where := A_X;
      GenNative(m_ldx_imm, immediate, q, op^.lab, shift16);
      GenNative(m_lda_imm, immediate, q, op^.lab, 0);
      end {else if}
   else begin
      gLong.where := onStack;
      GenNative(m_pea, immediate, q, op^.lab, shift16);
      GenNative(m_pea, immediate, q, op^.lab, 0);
      end; {else}
   end; {GenLaoLad}


   procedure GenLca (op: icptr);

   { Generate code for a pc_lca					}

   var
      i: integer;			{loop/index variable}
      len: unsigned;			{string length}

   begin {GenLca}
   gLong.where := onStack;
   GenNative(m_pea, immediate, stringSize, nil, stringReference+shift16);
   GenNative(m_pea, immediate, stringSize, nil, stringReference);
   len := op^.q;
   if maxString-stringSize >= len then begin
      for i := 1 to op^.q do
	 stringSpace[i+stringSize] := op^.str^[i];
      stringSize := stringSize+len;
      end
   else
      Error(cge3);
   op^.optype := cgULong;
   end; {GenLca}


   procedure GenLda (op: icptr);

   { Generate code for a pc_lda					}

   begin {GenLda}
   if ((localAddress & gLong.preference) <> 0) and (op^.p = 0) then begin
      gLong.fixedDisp := true;
      gLong.where := localAddress;
      gLong.disp := localLabel[op^.s] + op^.q;
      end {if}
   else if (A_X & gLong.preference) <> 0 then begin
      gLong.where := A_X;
      if op^.p = 0 then
	 GenImplied(m_tdc)
      else
	 StaticLink(op^.p, false, true);
      GenImplied(m_clc);
      GenNative(m_adc_imm, immediate, localLabel[op^.s] + op^.q, nil, 0);
      GenNative(m_ldx_imm, immediate, 0, nil, 0);
      end {else if}
   else begin
      gLong.where := onStack;
      GenNative(m_pea, immediate, 0, nil, 0);
      if op^.p = 0 then
	 GenImplied(m_tdc)
      else
	 StaticLink(op^.p, false, true);
      GenImplied(m_clc);
      GenNative(m_adc_imm, immediate, localLabel[op^.s] + op^.q, nil, 0);
      GenImplied(m_pha);
      end; {else}
   end; {GenLda}


   procedure GenLdc (op: icptr);

   { Generate code for a pc_ldc					}

   type
      kind = (vint, vbyte, vreal);	{kinds of equivalenced data}

   var
      i: unsigned;			{loop/index variable}
      rec: realrec;			{conversion record}
      switch: packed record		{used for type conversion}
	 case rkind: kind of
	    vint: (i: integer);
	    vbyte: (b1, b2, b3, b4, b5, b6, b7, b8: byte);
	    vreal: (r: double);
	 end;

   begin {GenLdc}
   case op^.optype of
      cgByte: begin
	 if op^.q > 127 then
	    op^.q := op^.q | $FF00;
	 GenNative(m_lda_imm, immediate, op^.q, nil, 0);
	 end;

      cgUByte, cgWord, cgUWord:
	 GenNative(m_lda_imm, immediate, op^.q, nil, 0);

      cgReal, cgDouble, cgComp, cgExtended: begin
	 rec.itsReal := op^.rval;
	 CnvSX(rec);
	 i := 10;
	 while i <> 0 do begin
	    switch.b1 := rec.inSANE[i-1];
	    switch.b2 := rec.inSANE[i];
	    GenNative(m_pea, immediate, switch.i, nil, 0);
	    i := i-2;
	    end; {while}
	 end;

      cgLong, cgULong:
	 if (constant & gLong.preference) <> 0 then begin
	    gLong.where := constant;
	    gLong.lval := op^.lval;
	    end
	 else if (A_X & gLong.preference) <> 0 then begin
	    gLong.where := A_X;
	    GenNative(m_lda_imm, immediate, long(op^.lval).lsw, nil, 0);
	    GenNative(m_ldx_imm, immediate, long(op^.lval).msw, nil, 0);
	    end
	 else begin
	    gLong.where := onStack;
	    GenNative(m_pea, immediate, long(op^.lval).msw, nil, 0);
	    GenNative(m_pea, immediate, long(op^.lval).lsw, nil, 0);
	    end;

      cgSet: begin
	 with op^.setp^ do begin
	    if odd(smax) then begin
	      smax := smax+1;
	      sval[smax] := chr(0);
	      end; {if}
	    i := smax;
	    while i <> 0 do begin
	       switch.b1 := ord(sval[i-1]);
	       switch.b2 := ord(sval[i]);
	       GenNative(m_pea, immediate, switch.i, nil, 0);
	       i := i-2;
	       end; {while}
	    GenNative(m_pea, immediate, smax, nil, 0);
	    end; {with}     
	 end;

      otherwise:
	 Error(cge1);
      end; {case}
   end; {GenLdc}     


   procedure GenLdo (op: icptr);

   { Generate code for a pc_ldo					}

   var
      i: unsigned;			{set size}
      lab1: unsigned;			{branch point}

   begin {GenLdo}
   case op^.optype of
      cgWord, cgUWord:
	 if smallMemoryModel then
	    GenNative(m_lda_abs, absolute, op^.q, op^.lab, 0)
	 else
	    GenNative(m_lda_long, longAbs, op^.q, op^.lab, 0);

      cgByte, cgUByte: begin
	 if smallMemoryModel then
	    GenNative(m_lda_abs, absolute, op^.q, op^.lab, 0)
	 else
	    GenNative(m_lda_long, longAbs, op^.q, op^.lab, 0);
	 GenNative(m_and_imm, immediate, 255, nil, 0);
	 if op^.optype = cgByte then begin
	    GenNative(m_bit_imm, immediate, $0080, nil, 0);
	    lab1 := GenLabel;
	    GenNative(m_beq, relative, lab1, nil, 0);
	    GenNative(m_ora_imm, immediate, $FF00, nil, 0);
	    GenLab(lab1);
	    GenNative(m_cmp_imm, immediate, $0000, nil, 0);
	    end; {if}
	 end;

      cgReal, cgDouble, cgComp, cgExtended: begin
	 GenNative(m_pea, immediate, op^.q, op^.lab, shift16);
	 GenNative(m_pea, immediate, op^.q, op^.lab, 0);
	 if op^.optype = cgReal then
	    GenCall(25)
	 else if op^.optype = cgDouble then
	    GenCall(18)
	 else if op^.optype = cgComp then
	    GenCall(163)
	 else {if op^.optype = cgExtended then}
	    GenCall(164);
	 end;

      cgLong, cgULong: begin
	 if (A_X & gLong.preference) <> 0 then
	    gLong.where := A_X
	 else
	    gLong.where := onStack;
	 if smallMemoryModel then begin
	    GenNative(m_ldx_abs, absolute, op^.q+2, op^.lab, 0);
	    GenNative(m_lda_abs, absolute, op^.q, op^.lab, 0);
	    if gLong.where = onStack then begin
	       GenImplied(m_phx);
	       GenImplied(m_pha);
	       end; {if}
	    end {if}
	 else begin
	    GenNative(m_lda_long, longabsolute, op^.q+2, op^.lab, 0);
	    if gLong.where = onStack then
	       GenImplied(m_pha)
	    else
	       GenImplied(m_tax);
	    GenNative(m_lda_long, longabsolute, op^.q, op^.lab, 0);
	    if gLong.where = onStack then
	       GenImplied(m_pha);
	    end; {else}
	 end; {case cgLong,cgULong}

      cgSet: begin
	 if op^.q <= 8 then begin
	    i := op^.q;
	    if odd(i) then begin
	       i := i-1;
	       GenNative(m_sep, immediate, 32, nil, 0);
	       GenNative(m_lda_abs, absolute, op^.r+i, op^.lab, 0);
	       GenImplied(m_pha);
	       GenNative(m_rep, immediate, 32, nil, 0);
	       end; {if}
	    while i <> 0 do begin
	       i := i-2;
	       GenNative(m_lda_abs, absolute, op^.r+i, op^.lab, 0);
	       GenImplied(m_pha);
	       end; {while}
	    GenNative(m_pea, immediate, op^.q, nil, 0);
	    end {if}
	 else begin
	    GenNative(m_pea, immediate, op^.r, op^.lab, shift16);
	    GenNative(m_pea, immediate, op^.r, op^.lab, 0);
	    GenNative(m_pea, immediate, op^.q, nil,0);
	    GenCall(28);
	    end; {else}
	 end; {case cgSet}

      otherwise:
	 Error(cge1);
      end; {case}
   end; {GenLdo}


   procedure GenLla (op: icptr);

   { Generate code for a pc_lla					}

   begin {GenLla}
   gLong.where := onStack;
   GenNative(m_pea, genAddress, op^.q, nil, shift16);
   GenNative(m_pea, genAddress, op^.q, nil, 0);
   end; {GenLla}


   procedure GenLnm (op: icptr);

   { Generate code for a pc_lnm					}

   begin {GenLnm}
   if op^.left <> nil then
      GenTree(op^.left);
   if traceBack then begin
      GenNative(m_pea, immediate, op^.r, nil, 0);
      GenCall(75);
      end; {if}
   if debugFlag then begin
      GenNative(m_cop, immediate, op^.q, nil, 0);
      GenNative(d_wrd, special, op^.r, nil, 0);
      end; {if}
   end; {GenLnm}


   procedure GenLod (op: icptr);

   { Generate code for a pc_lod					}

   var
      disp: integer;			{load location}
      i: unsigned;			{loop/index variable}
      lab1: unsigned;			{branch point}
      optype: baseTypeEnum;		{op^.optype}

   begin {GenLod}
   disp := localLabel[op^.r] + op^.q;
   optype := op^.optype;
   case optype of
      cgReal, cgDouble, cgComp, cgExtended: begin
	 GenNative(m_pea, immediate, 0, nil, 0);
	 if op^.p = 0 then
	    GenImplied(m_tdc)
	 else
	    StaticLink(op^.p, false, true);
	 GenImplied(m_clc);
	 GenNative(m_adc_imm, immediate, disp, nil, 0);
	 GenImplied(m_pha);
	 if optype = cgReal then
	    GenCall(25)
	 else if optype = cgDouble then
	    GenCall(18)
	 else if optype = cgComp then
	    GenCall(163)
	 else {if optype = cgExtended then}
	    GenCall(164);
	 end;

      cgLong, cgULong: begin
	 if op^.p <> 0 then begin
	    gLong.where := onStack;
	    StaticLink(op^.p, false, false);
	    GenNative(m_lda_longx, longabsolute, disp+2, nil, 0);
	    GenImplied(m_pha);
	    GenNative(m_lda_longx, longabsolute, disp, nil, 0);
	    GenImplied(m_pha);
	    end {if}
         else if ((inPointer & gLong.preference) <> 0) and (disp < 254) then
	    begin
	    gLong.where := inPointer;
	    gLong.fixedDisp := true;
	    gLong.disp := disp;
	    end {else if}
	 else if ((A_X & gLong.preference) <> 0) and (disp < 254) then begin
	    gLong.where := A_X;
	    GenNative(m_ldx_dir, direct, disp+2, nil, 0);
	    GenNative(m_lda_dir, direct, disp, nil, 0);
	    end {else if}
	 else begin
	    gLong.where := onStack;
	    if disp >= 254 then begin
	       GenNative(m_ldx_imm, immediate, disp, nil, 0);
	       GenNative(m_lda_dirx, direct, 2, nil, 0);
	       GenImplied(m_pha);
	       GenNative(m_lda_dirx, direct, 0, nil, 0);
	       GenImplied(m_pha);
	       end {if}
	    else begin
	       GenNative(m_pei_dir, direct, disp+2, nil, 0);
	       GenNative(m_pei_dir, direct, disp, nil, 0);
	       end; {else}
	    end; {else}
	 end;

      cgByte, cgUByte, cgWord, cgUWord: begin
         if op^.p <> 0 then begin
	    StaticLink(op^.p, false, false);
	    GenNative(m_lda_longx, longabsolute, disp, nil, 0);
            end {if}
	 else if disp >= 256 then begin
	    GenNative(m_ldx_imm, immediate, disp, nil, 0);
	    GenNative(m_lda_dirx, direct, 0, nil, 0);
	    end {else if}
	 else
	    GenNative(m_lda_dir, direct, disp, nil, 0);
	 if optype in [cgByte,cgUByte] then begin
	    GenNative(m_and_imm, immediate, $00FF, nil, 0);
	    if optype = cgByte then begin
	       GenNative(m_bit_imm, immediate, $0080, nil, 0);
	       lab1 := GenLabel;
	       GenNative(m_beq, relative, lab1, nil, 0);
	       GenNative(m_ora_imm, immediate, $FF00, nil, 0);
	       GenLab(lab1);
	       GenNative(m_cmp_imm, immediate, $0000, nil, 0);
	       end; {if}
	    end;
	 end;

      cgSet:
	 if (op^.p = 0) and (disp < 248) and (op^.s <= 8) then begin
	    i := op^.s;
	    if odd(i) then begin
	       i := i-1;
	       GenNative(m_sep, immediate, 32, nil, 0);
	       GenNative(m_lda_dir, direct, disp+i, nil, 0);
	       GenImplied(m_pha);
	       GenNative(m_rep, immediate, 32, nil, 0);
	       end; {if}
	    while i <> 0 do begin
	       i := i-2;
	       GenNative(m_pei_dir, direct, disp+i, nil, 0);
	       end; {end}
	    GenNative(m_pea, immediate, op^.s, nil, 0);
	    end {if}
	 else begin
	    GenNative(m_pea, immediate, 0, nil, 0);
	    if op^.p = 0 then
	       GenImplied(m_tdc)
	    else
	       StaticLink(op^.p, false, true);
	    GenImplied(m_clc);
	    GenNative(m_adc_imm, immediate, disp, nil, 0);
	    GenImplied(m_pha);
	    GenNative(m_pea, immediate, op^.s, nil, 0);
	    GenCall(28);
	    end; {else}

      otherwise:
	 Error(cge1);

      end; {case}
   end; {GenLod}


   procedure GenLsl (op: icptr);

   { Generate code for a pc_lsl					}
   
   begin {GenLsl}
   if op^.q = 0 then
      GenImplied(m_tdc)
   else
      StaticLink(op^.q, false, true);
   end; {GenLsl}


   procedure GenMov (op: icptr; duplicate: boolean);

   { Generate code for a pc_mov					}
   {								}
   { parameters:						}
   {    op - pc_mov instruction					}
   {    duplicate - should the source address be left on the	}
   {       stack?						}

   var
      banks: integer;			{number of banks to move}


      procedure Load (opcode: integer; op: icptr);

      { generate a load immediate based on instruction type	}
      {								}
      { parameters:						}
      {    opcode - native code load operation			}
      {    op - node to load					}

      var
	 i: integer;

      begin {Load}
      if op^.opcode = pc_lao then
         GenNative(opcode, immediate, op^.q, op^.lab, 0)
      else begin
         GenNative(opcode, immediate, stringsize, nil, StringReference);
         if maxstring-stringsize >= op^.q then begin
            for i := 1 to op^.q do
               stringspace[i+stringsize] := op^.str^[i];
            stringsize := stringsize + op^.q;
            end {if}
         else
            Error(cge3);
         end; {else}
      end; {Load}


   begin {GenMov}
   {determine if the destination address must be left on the stack}
   if smallMemoryModel
      and (not duplicate)
      and (op^.left^.opcode in [pc_lao,pc_lca])
      and (op^.right^.opcode in [pc_lao,pc_lca]) then begin

      {take advantage of any available short cuts}
      Load(m_ldy_imm, op^.left);
      Load(m_ldx_imm, op^.right);
      GenNative(m_lda_imm, immediate, op^.q-1, nil, 0);
      GenImplied(m_phb);
      GenImplied(m_mvn);
      with op^.left^ do
	 if opcode = pc_lao then
            GenNative(d_bmov, immediate, q, lab, shift16)
	 else
            GenNative(d_bmov, immediate, 0, nil, stringReference+shift16);
      with op^.right^ do
	 if opcode = pc_lao then
            GenNative(d_bmov, immediate, q, lab, shift16)
	 else
            GenNative(d_bmov, immediate, 0, nil, stringReference+shift16);
      GenImplied(m_plb);
      end {if}
   else begin

      {no short cuts are available - do it the hard way}
      gLong.preference := onStack;
      GenTree(op^.left);
      gLong.preference := onStack;
      GenTree(op^.right);
      banks := op^.r;
      if banks <> 0 then
	 GenNative(m_pea, immediate, banks, nil, 0);
      GenNative(m_pea, immediate, op^.q, nil, 0);
      if banks = 0 then begin
	 if duplicate then
            GenCall(167)
	 else
            GenCall(80);
	 end {if}
      else
	 if duplicate then
            GenCall(169)
	 else
            GenCall(168);
      end; {else}
   end; {GenMov}


   procedure GenMpi (op: icptr);

   { Generate code for a pc_mpi or pc_umi			}
   
   var
      nd: icptr;

   begin {GenMpi}
   if not Complex(op^.left) then
      if Complex(op^.right) then begin
	 nd := op^.left;
	 op^.left := op^.right;
	 op^.right := nd;
	 end; {if}
   GenTree(op^.left);
   if Complex(op^.right) then begin
      GenImplied(m_pha);
      GenTree(op^.right);
      GenImplied(m_plx);
      end {if}
   else
      LoadX(op^.right);
   if op^.opcode = pc_mpi then
      GenCall(32)
   else {pc_umi}
      GenCall(142);
   if rangeCheck then
      GenCall(147);
   end; {GenMpi}


   procedure GenNam (op: icptr);                    

   { Generate code for a pc_nam					}

   var
      i: integer;			{loop/index variable}
      len: integer;			{length of the file name}


      function ToUpper (ch: char): char;

      { Return the uppercase equivalent of the input character	}

      begin {ToUpper}
      if (ch >= 'a') and (ch <= 'z') then
	 ch := chr(ord(ch)-ord('a')+ord('A'));
      ToUpper := ch;
      end; {ToUpper}


   begin {GenNam}
   {generate a call to install the name in the traceback facility}
   if traceBack then begin
      GenNative(m_pea, immediate, stringSize, nil, stringReference+shift16);
      GenNative(m_pea, immediate, stringSize, nil, stringReference);
      GenCall(76);
      namePushed := true;
      end; {if}

   {send the name to the profiler}
   if profileFlag then begin
      GenNative(m_cop, immediate, 3, nil, 0);
      GenNative(d_add, genaddress, stringSize, nil, stringReference);
      GenNative(d_add, genaddress, stringSize, nil, stringReference+shift16);
      end; {if}

   {place the name in the string buffer}
   len := length(op^.str^);
   if maxString-stringSize >= len+1 then begin
      stringSpace[stringSize+1] := chr(len);
      for i := 1 to len do
         stringSpace[i+stringSize+1] := op^.str^[i];
      stringSize := stringSize + len + 1;
      end {if}
   else
      Error(cge3);

   {send the file name to the debugger}
   if debugFlag then begin
      GenNative(m_cop, immediate, 6, nil, 0);
      GenNative(d_add, genaddress, stringSize, nil, stringReference);
      GenNative(d_add, genaddress, stringSize, nil, stringReference+shift16);
      len := fNameGS.theString.size;
      if len > 255 then
         len := 255;
      if maxString-stringSize >= len+1 then begin
         stringSpace[stringSize+1] := chr(len);
         for i := 1 to len do
            stringSpace[i+stringSize+1] :=
               ToUpper(fNameGS.theString.theString[i]);
         stringSize := stringSize + len + 1;
         end {if}
      else
         Error(cge3);
      end; {if}
   end; {GenNam}


   procedure GenPds (op: icptr);

   { Generate code for a pc_pds					}

   begin {GenPds}
   gLong.preference := A_X;
   GenTree(op^.left);
   if gLong.where = onStack then begin
      GenImplied(m_pla);
      GenImplied(m_plx);
      end; {if}
   GenNative(m_ldy_imm, immediate, op^.q, nil, 0);
   GenCall(47);
   end; {GenPds}


   procedure GenPrs (op: icptr);

   { Generate code for a pc_prs					}

   begin {GenPrs}
   GenNative(m_lda_dir, direct, staticLoc, nil, 0);
   GenImplied(m_tcd);
   GenImplied(m_dea);
   GenImplied(m_dea);
   GenImplied(m_tcs);
   end; {GenPrs}


   procedure GenPwr (op: icptr);

   { Generate code for a pc_pwr					}

   begin {GenPwr}
   GenTree(op^.left);
   GenTree(op^.right);
   GenCall(90);
   end; {GenPwr}


   procedure GenRealBinOp (op: icptr);

   { Generate code for a pc_adr, pc_dvr, pc_mpr, pc_sbr		}

   var
      nd: icptr;			{temp pointer}
      snum: integer;			{library subroutine numbers}
      ss,sd,sc,se: integer;		{sane call numbers}

   begin {GenRealBinOp}
   case op^.opcode of
      pc_adr: begin
	 snum := 50;
	 ss := $0200;
	 sd := $0100;
	 sc := $0500;
	 se := $0000;
	 end;

      pc_dvr: begin
	 snum := 51;
	 ss := $0206;
	 sd := $0106;
	 sc := $0506;
	 se := $0006;
	 end;

      pc_mpr: begin
	 snum := 52;
	 ss := $0204;
	 sd := $0104;
	 sc := $0504;
	 se := $0004;
	 end;

      pc_sbr: begin
	 snum := 53;
	 ss := $0202;
	 sd := $0102;
	 sc := $0502;
	 se := $0002;
	 end;
      end; {case}

   if op^.opcode in [pc_mpr,pc_adr] then
      if op^.left^.opcode in [pc_lod,pc_ldo] then begin
         nd := op^.left;
         op^.left := op^.right;
         op^.right := nd;
         end; {if}
   GenTree(op^.left);
   if (op^.right^.opcode in [pc_lod,pc_ldo]) and (floatCard = 0) then
      with op^.right^ do begin
	 if opcode = pc_lod then begin
            GenNative(m_pea, immediate, 0, nil, 0);
	    if p = 0 then
	       GenImplied(m_tdc)
	    else
	       StaticLink(p, false, true);
            GenImplied(m_clc);
            GenNative(m_adc_imm, immediate, localLabel[r] + q, nil, 0);
            GenImplied(m_pha);              
            end {if}
	 else begin
            GenNative(m_pea, immediate, q, lab, shift16);
            GenNative(m_pea, immediate, q, lab, 0);
            end; {else}
	 GenNative(m_pea, immediate, 0, nil, 0);
	 GenImplied(m_tsc);
	 GenImplied(m_clc);
	 GenNative(m_adc_imm, immediate, 7, nil, 0);
	 GenImplied(m_pha);
	 if optype = cgReal then
            sd := ss
	 else if optype = cgExtended then
            sd := se
	 else if optype = cgComp then
            sd := sc;
	 GenNative(m_pea, immediate, sd, nil, 0);
	 GenNative(m_ldx_imm, immediate, $090A, nil, 0);
	 GenNative(m_jsl, longAbs, 0, nil, toolCall);
	 end {with}
   else begin
      GenTree(op^.right);
      GenCall(snum);
      end; {else}
   end; {GenRealBinOp}


   procedure GenRealUnOp (op: icptr);

   { Generate code for a pc_sqr, pc_sqt, pc_sin, pc_cos,	}
   {    pc_atn, pc_log, pc_exp, pc_tan, pc_acs, pc_asn		}

   var
      snum: integer;

   begin {GenRealUnOp}
   GenTree(op^.left);
   case op^.opcode of
      pc_sqr: snum := 54;
      pc_sqt: snum := 55;
      pc_sin: snum := 63;
      pc_cos: snum := 64;
      pc_atn: snum := 65;
      pc_log: snum := 66;
      pc_exp: snum := 67;
      pc_tan: snum := 120;
      pc_acs: snum := 121;
      pc_asn: snum := 122;
      end; {case}
   GenCall(snum);
   end; {GenRealUnOp}


   procedure GenRet (op: icptr);

   { Generate code for a pc_ret					}

   var
      size: integer;			{localSize + parameterSize}

   begin {GenRet}
   {pop the name record}
   if namePushed then
      GenCall(77);

   {generate an exit code for the debugger's benefit}
   if debugFlag then
      GenNative(m_cop, immediate, 4, nil, 0);

   {if anything needs to be removed from the stack, move the return val}
   size := localSize + parameterSize;
   if parameterSize <> 0 then begin
      if localSize > 254 then begin
	 GenNative(m_ldx_imm, immediate, localSize+1, nil, 0);
	 GenNative(m_lda_dirx, direct, 0, nil, 0);
	 GenNative(m_ldy_dirx, direct, 1, nil, 0);
	 GenNative(m_ldx_imm, immediate,
	    localSize+parameterSize+1, nil, 0);
	 GenNative(m_sta_dirx, direct, 0, nil, 0);
	 GenNative(m_sty_dirx, direct, 1, nil, 0);
	 end {if}
      else begin
	 GenNative(m_lda_dir, direct, localSize+2, nil, 0);
	 if localSize+parameterSize > 254 then begin
	    GenNative(m_ldx_imm, immediate,
	       localSize+parameterSize+1, nil, 0);
	    GenNative(m_sta_dirx, direct, 1, nil, 0);
	    GenNative(m_lda_dir, direct, localSize+1, nil, 0);
	    GenNative(m_sta_dirx, direct, 0, nil, 0);
	    end {if}
	 else begin
	    GenNative(m_sta_dir, direct,
	       localSize+parameterSize+2, nil, 0);
	    GenNative(m_lda_dir, direct, localSize+1, nil, 0);
	    GenNative(m_sta_dir, direct,
	       localSize+parameterSize+1, nil, 0);
	    end; {else}
	 end; {else}
      end; {if}

   {load the value to return}
   case op^.optype of

      cgVoid: ;

      cgByte,cgUByte: begin
	 GenNative(m_lda_dir, direct, funLoc, nil, 0);
	 GenNative(m_and_imm, immediate, $00FF, nil, 0);
	 if size <> 2 then
	    GenImplied(m_tay);
	 end;

      cgWord,cgUWord:
	 if size = 2 then
	    GenNative(m_lda_dir, direct, funLoc, nil, 0)
	 else
	    GenNative(m_ldy_dir, direct, funLoc, nil, 0);

      cgReal,cgDouble,cgExtended,cgComp: begin
         GenNative(m_pea, immediate, 0, nil, 0);
	 GenImplied(m_tdc);
         GenImplied(m_clc);
         GenNative(m_adc_imm, immediate, funLoc, nil, 0);
         GenImplied(m_pha);              
         if op^.optype = cgReal then
	    GenCall(81)
         else if op^.optype = cgDouble then
	    GenCall(84)
         else if op^.optype = cgExtended then
	    GenCall(176)
         else {if op^.optype = cgComp then}
	    GenCall(177);
         end;

      cgLong,cgULong: begin
	 GenNative(m_ldx_dir, direct, funLoc+2, nil, 0);
	 GenNative(m_ldy_dir, direct, funLoc, nil, 0);
	 end;

      otherwise:
	 Error(cge1);
      end; {case}

   {restore data bank reg}
   if dataBank then begin
      GenNative(m_lda_dir, direct, bankLoc, nil, 0);
      GenImplied(m_pha);
      GenImplied(m_plb);
      GenImplied(m_plb);
      end; {if}

   {get rid of the stack frame space}
   if size <> 0 then
      GenImplied(m_pld);
   if size = 2 then
      GenImplied(m_ply)
   else if size <> 0 then begin
      GenImplied(m_tsc);
      GenImplied(m_clc);
      GenNative(m_adc_imm, immediate, size, nil, 0);
      GenImplied(m_tcs);
      end; {if}

   {put return value in correct place}
   case op^.optype of
      cgByte,cgUByte,cgWord,cgUWord: begin
	 if size <> 2 then
	    GenImplied(m_tya);
	 if toolParms then	  {save value on stack for tools}
	    GenNative(m_sta_s, direct, returnSize+1, nil, 0);
	 end;

      cgLong,cgULong,cgReal,cgDouble,cgComp,cgExtended: begin
	 GenImplied(m_tya);
	 if toolParms then begin  {save value on stack for tools}
	    GenNative(m_sta_s, direct, returnSize+1, nil, 0);
	    GenImplied(m_txa);
	    GenNative(m_sta_s, direct, returnSize+3, nil, 0);
	    end; {if}
	 end;

      cgVoid: ;

      otherwise:
	 Error(cge1);
      end; {case}

   {return to the caller}
   GenImplied(m_rtl);
   end; {GenRet}


   procedure GenRnd (op: icptr);

   { Generate code for a pc_rnd					}

   begin {GenRnd}
   GenTree(op^.left);
   GenCall(68);
   end; {GenRnd}


   procedure GenRn4 (op: icptr);

   { Generate code for a pc_rn4					}

   var
      lLong: longType;			   {used to reserve gLong}

   begin {GenRn4}
   lLong := gLong;
   GenTree(op^.left);
   GenCall(149);
   if (lLong.preference & A_X) <> 0 then
      gLong.where := A_X
   else begin
      gLong.where := onStack;
      GenImplied(m_phx);
      GenImplied(m_pha);
      end; {else}
   end; {GenRn4}


   procedure GenSbi (op: icptr);

   { Generate code for a pc_sbi					}
   
   begin {GenSbi}
   if Complex(op^.left) or Complex(op^.right) then begin
      GenTree(op^.right);
      if Complex(op^.left) then begin
	 GenImplied(m_pha);
	 GenTree(op^.left);
	 GenImplied(m_sec);
	 GenNative(m_sbc_s, direct, 1, nil, 0);
	 GenImplied(m_plx);
         end {if}
      else begin
         GenNative(m_eor_imm, immediate, $FFFF, nil, 0);
	 GenImplied(m_sec);
         OperA(m_adc_imm, op^.left);
         end; {else}
      end {if}
   else begin
      GenTree(op^.left);
      GenImplied(m_sec);
      OperA(m_sbc_imm, op^.right);
      end; {else}
   if rangeCheck then
      GenCall(147);
   end; {GenSbi}


   procedure GenShlShrUsr (op: icptr);

   { Generate code for a pc_shl, pc_shr or pc_usr		}

   var
      i,op1,op2,num: integer;		{temp variables}

   begin {GenShlShrUsr}
   {get the standard native operations}
   if op^.opcode = pc_shl then begin
      op1 := m_asl_a;
      op2 := m_lsr_a;
      end {if}
   else begin
      op1 := m_lsr_a;
      op2 := m_asl_a;
      end; {else}

   {take short cuts if they are legal}
   if (op^.right^.opcode = pc_ldc) and (op^.opcode <> pc_shr) then begin
      num := op^.right^.q;
      if (num > 16) or (num < -16) then
	 GenNative(m_lda_imm, immediate, 0, nil, 0)
      else if num > 0 then begin
	 GenTree(op^.left);
         if num >= 8 then begin
            GenImplied(m_xba);
            if op1 = m_lsr_a then
               i := $00FF
            else
               i := $FF00;
            GenNative(m_and_imm, immediate, i, nil, 0);
            num := num-8;
            end; {if}
	 for i := 1 to num do
            GenImplied(op1);
	 end {else if}
      else if num < 0 then begin
	 GenTree(op^.left);
         if num <= -8 then begin
            GenImplied(m_xba);
            if op2 = m_lsr_a then
               i := $00FF
            else
               i := $FF00;
            GenNative(m_and_imm, immediate, i, nil, 0);
            num := num+8;
            end; {if}    
	 for i := 1 to -num do
            GenImplied(op2);
	 end {else if}
      else
	 GenTree(op^.left);
      end {if}
   else begin
      GenTree(op^.left);
      if Complex(op^.right) then begin
	 GenImplied(m_pha);
	 GenTree(op^.right);
	 GenImplied(m_tax);
	 GenImplied(m_pla);
	 end {if}
      else
	 LoadX(op^.right);
      if op^.opcode = pc_shl then
	 GenCall(88)
      else if op^.opcode = pc_shr then
	 GenCall(89)
      else {if op^.opcode = pc_usr then}
	 GenCall(175);
      end; {else}
   end; {GenShlShrUsr}
   

   procedure GenSiz (op: icptr);

   { Generate code for a pc_siz					}

   const
      unknownSize = 999;		{used to indicate an unknown set size}

   var   
      size: integer;			{size of the set being passed}


      function SetSize (op: icptr): unsigned;

      { find the size of the set generated by the tree passed	}
      {								}
      { parameters:						}
      {    op - tree to examine					}
      {								}
      { returns: Size of set					}

      var
	 ls, rs: unsigned;		{temp set sizes}

      begin {SetSize}
      case op^.opcode of
	 pc_uni,pc_int,pc_dif: begin
	    ls := SetSize(op^.left);
	    rs := SetSize(op^.right);
	    if ls < rs then
	       SetSize := rs
	    else
	       SetSize := ls;
	    end;
	 pc_sgs,pc_ixa,pc_ind:
	    SetSize := unknownSize;
	 pc_ldo:
	    SetSize := op^.q;
	 pc_ldc: begin
	    ls := op^.setp^.smax;
	    if odd(ls) then
               ls := ls+1;
	    SetSize := ls;
	    end;
	 pc_lod:
	    SetSize := op^.s;
	 otherwise: begin
	    SetSize := unknownSize;
	    Error(cge1);
	    end;
	 end; {case}
      end; {SetSize}

      
   begin {GenSiz}
   size := SetSize(op^.left);
   if (size <> unknownSize) and (size <= op^.q) then begin
      if odd(size-op^.q) then begin
	 GenNative(m_pea, immediate, 0, nil, 0);
	 GenImplied(m_phb);
	 GenImplied(m_pla);
	 size := size+1;
	 end; {if}
      while size < op^.q do begin
	 GenNative(m_pea, immediate, 0, nil, 0);
	 size := size+2;
	 end; {while}
      GenTree(op^.left);
      GenImplied(m_pla);
      end {if}
   else begin
      GenTree(op^.left);
      GenNative(m_pea, immediate, op^.q, nil, 0);
      GenCall(78);
      end; {else}
   end; {GenSiz}


   procedure GenSgs (op: icptr);

   { Generate code for a pc_sgs					}
   {								}
   { (Convert an integer range into a set)			}

   begin {GenSgs}
   GenTree(op^.left);
   GenImplied(m_pha);
   GenTree(op^.right);
   GenImplied(m_pha);
   GenCall(16);
   end; {GenSgs}


   procedure GenStk (op: icptr);

   { Generate code for a pc_stk					}

   var
      lab1: integer;			{branch point}

   begin {GenStk}
   glong.preference := onStack;		{generate the operand}
   GenTree(op^.left);
   if op^.optype in			{do the stk}
      [cgByte, cgUByte, cgWord, cgUWord] then
      GenImplied(m_pha);
   end; {GenStk}


   procedure GenTl1 (op: icptr);

   { Generate code for a pc_tl1, pc_tl2				}

   type
      kind = (vint, vbyte);		{kinds of equivalenced data}

   var        
      lLong: longType;			{used to reserve gLong}
      str: pStringPtr;			{string constant pointer}
      switch: packed record		{used for type conversion}
	 case rkind: kind of
	    vint: (i: integer);
	    vbyte: (b1, b2: byte);
	 end;
   
   begin {GenTl1}
   {push space for the return value}
   if op^.optype in [cgByte,cgUByte,cgWord,cgUWord] then
      GenImplied(m_pha)
   else if op^.optype in [cgLong,cgULong] then begin
      GenImplied(m_pha);
      GenImplied(m_pha);
      end; {else if}

   {generate parameters}
   lLong := gLong;
   GenTree(op^.left);
   gLong := lLong;

   {generate the tool call}
   switch.b2 := op^.q;
   switch.b1 := op^.r;
   GenNative(m_ldx_imm,immediate,switch.i,nil,0);
   if op^.opcode = pc_tl1 then
      GenNative(m_jsl, longAbs, 0, nil, toolCall)
   else
      GenNative(m_jsl, longAbs, 0, nil, usertoolCall);
   str := @'~TOOLERROR';
   if smallMemoryModel then
      GenNative(m_sta_abs, absolute, 0, str, 0)
   else
      GenNative(m_sta_long, longAbs, 0, str, 0);
      
   {save the returned value}
   if op^.optype in [cgByte,cgUByte,cgWord,cgUWord] then
      GenImplied(m_pla)
   else if op^.optype in [cgLong,cgULong] then
      gLong.where := onStack;
   end; {GenTl1}


   procedure GenUjp (op: icptr);

   { Generate code for a pc_ujp					}

   begin {GenUjp}
   if op^.lab = nil then
      GenNative(m_brl, longrelative, op^.q, nil, 0)
   else
      GenNative(m_jml, longAbs, 0, op^.lab, 0);
   end; {GenUjp}


   procedure GenVct (op: icptr);

   { Generate code for a pc_vct					}

   type
      kind = (vint, vbyte);		{kinds of equivalenced data}

   var        
      lLong: longType;			{used to reserve gLong}
      str: pStringPtr;			{string constant pointer}
   
   begin {GenVct}
   {push space for the return value}
   if op^.optype in [cgByte,cgUByte,cgWord,cgUWord] then
      GenImplied(m_pha)
   else if op^.optype in [cgLong,cgULong] then begin
      GenImplied(m_pha);
      GenImplied(m_pha);
      end; {else if}

   {generate parameters}
   lLong := gLong;
   GenTree(op^.left);
   gLong := lLong;

   {generate the tool call}
   GenNative(m_ldx_imm,immediate,op^.q,nil,0);
   if op^.opcode = pc_tl1 then
      GenNative(m_jsl, longAbsolute, 0, op^.lval, constantOpnd)
   else
      GenNative(m_jsl, longAbsolute, 0, op^.lval, constantOpnd);
   str := @'~TOOLERROR';
   if smallMemoryModel then
      GenNative(m_sta_abs, absolute, 0, str, 0)
   else
      GenNative(m_sta_long, longAbs, 0, str, 0);
      
   {save the returned value}
   if op^.optype in [cgByte,cgUByte,cgWord,cgUWord] then
      GenImplied(m_pla)
   else if op^.optype in [cgLong,cgULong] then
      gLong.where := onStack;
   end; {GenVct}


   procedure GenXjp (op: icptr);

   { Generate code for a pc_xjp					}

   var
      lab1,lab2: integer;
      q: integer;

   begin {GenXjp}
   q := op^.q;
   lab1 := GenLabel;
   GenTree(op^.left);
   GenNative(m_cmp_imm, immediate, q, nil, 0);
   GenNative(m_bcc, relative, lab1, nil, 0);
   GenNative(m_lda_imm, immediate, q, nil, 0);
   GenLab(lab1);
   GenImplied(m_asl_a);
   GenImplied(m_tax);
   lab1 := GenLabel;
   lab2 := GenLabel;
   GenNative(m_lda_longx, longAbs, lab2, nil, 0);
   GenNative(m_beq,relative,lab1,nil,0);
   GenImplied(m_pha);
   GenImplied(m_rts);
   GenLab(lab1);
   GenCall(12);
   GenLab(lab2);
   end; {GenXjp}


   procedure DirLab (op: icptr);

   { Generate code for a dc_lab					}

   begin {DirLab}
   if op^.lab = nil then
      GenLab(op^.q)
   else
      GenNative(d_lab, gnrLabel, 0, op^.lab, isPrivate);
   end; {DirLab}


   procedure DirStr (op: icptr);

   { Generate code for a dc_str					}

   begin {DirStr}
   skipLoad := false;
   InitNative;
   Header(op^.lab, op^.r, op^.q);
   end; {DirStr}


   procedure DirSym (op: icptr);

   { Generate code for a dc_sym					}

   begin {DirSym}
   if debugFlag then
      GenNative(d_sym, special, op^.q, pointer(op^.lab), 0);
   end; {DirSym}


begin {GenTree}
{if printSymbols then begin write('GEN: '); WriteCode(op); end; {debug}
Spin;
case op^.opcode of
   dc_dst: GenNative(d_lab, gnrSpace, op^.q, nil, 0);
   dc_enp: DirEnp;
   dc_glb: GenNative(d_lab, gnrLabel, op^.r, op^.lab, isPrivate*op^.q);
   dc_lab: DirLab(op);
   dc_fun,dc_loc,dc_prm: ;
   dc_pin: GenNative(d_pin, special, 0, nil, 0);
   dc_str: DirStr(op);
   dc_sym: DirSym(op);

   pc_abi,pc_bnt,pc_ngi,pc_not,pc_odd,pc_sqi: GenAbiBntNgiNotOddSqi(op);
   pc_abl,pc_bnl,pc_ngl,pc_odl,pc_sql: GenAblBnlNglOdlSql(op);
   pc_abr,pc_ngr: GenAbrNgr(op);
   pc_add: GenNative(d_add, genaddress, op^.q, nil, sub1);
   pc_adi: GenAdi(op);
   pc_adl,pc_sbl: GenAdlSbl(op, nil);
   pc_adr,pc_dvr,pc_mpr,pc_sbr: GenRealBinOp(op);
   pc_and,pc_bnd,pc_bor,pc_bxr,pc_ior: GenLogic(op);
   pc_atn,pc_cos,pc_exp,pc_log,pc_sin,pc_sqr,pc_sqt,pc_tan,pc_acs,pc_asn:
      GenRealUnOp(op);
   pc_at2: GenAt2(op);
   pc_blr,pc_blx,pc_bal,pc_dvl,pc_mdl,pc_mpl,pc_sll,pc_slr,pc_udl,pc_ulm,
      pc_uml,pc_vsr: GenBinLong(op);
   pc_bno: GenBno(op);
   pc_chk: GenChk(op);
   pc_cnv: GenCnv(op);
   pc_csp: GenCsp(op);
   pc_cui: GenCui(op);
   pc_cum: GenCum(op);
   pc_cup: GenCup(op);
   pc_dec,pc_inc: GenIncDec(op, nil);
   pc_dif,pc_int,pc_uni: GenDifIntUni(op);
   pc_dvi,pc_mod,pc_udi,pc_uim: GenDviMod(op);
   pc_ent: GenEnt(op);
   pc_equ,pc_neq: GenEquNeq(op, op^.opcode, 0);
   pc_fix: GenFix(op);
   pc_fjp,pc_tjp: GenFjpTjp(op);
   pc_geq,pc_grt,pc_leq,pc_les: GenCmp(op, op^.opcode, 0);
   pc_ind: GenInd(op);
   pc_inn: GenInn(op);
   pc_ixa: GenIxa(op);
   pc_lao,pc_lad: GenLaoLad(op);
   pc_lca: GenLca(op);
   pc_lda: GenLda(op);  
   pc_ldc: GenLdc(op);
   pc_ldo: GenLdo(op);
   pc_lod: GenLod(op);
   pc_lla: GenLla(op);
   pc_lnm: GenLnm(op);
   pc_lsl: GenLsl(op);
   pc_mov: GenMov(op, false);
   pc_mpi,pc_umi: GenMpi(op);
   pc_nam: GenNam(op);
   pc_nop: ;     
   pc_pds: GenPds(op);
   pc_prs: GenPrs(op);
   pc_pwr: GenPwr(op);
   pc_ret: GenRet(op);
   pc_rnd: GenRnd(op);
   pc_rn4: GenRn4(op);
   pc_sbi: GenSbi(op);
   pc_shl,pc_shr,pc_usr: GenShlShrUsr(op);
   pc_siz: GenSiz(op);
   pc_sgs: GenSgs(op);
   pc_sro,pc_cpo: GenSroCpo(op);
   pc_stk: GenStk(op);
   pc_sto: GenSto(op);
   pc_str,pc_cop: GenStrCop(op);
   pc_tl1,pc_tl2: GenTl1(op);
   pc_ujp: GenUjp(op);
   pc_vct: GenVct(op);
   pc_xjp: GenXjp(op);

   otherwise: begin
      Error(cge1);
      writeln('Undefined in GenTree: ', ord(op^.opcode):1);
      end;
   end; {case}
end; {GenTree}

{$optimize -1}

{---------------------------------------------------------------}

procedure Gen {blk: blockPtr};

{ Generates native code for a list of blocks			}
{								}
{ parameters:							}
{    blk - first of the list of blocks				}

type
   sfPtr = ^sfRecord;			{stack frame record}
   sfRecord = record
      next: sfPtr;			{next record}
      bankLoc: integer;			{disp in dp where bank reg is stored}
      dworkLoc: integer;		{disp in dp of 4 byte work spage for cg}
      funLoc: integer;			{loc of fn ret value in stack frame}
      localSize: integer;		{local space for current proc}
      parameterSize: integer;		{# bytes of parameters for current proc}
      staticLoc: integer;		{loc of static link}
      end;

var
   gop: icptr;				{used to trace code lists}
   sfList: sfPtr;			{stack frame list}
   sfLast: sfPtr;			{stack frame temp variable}

   
   procedure StackFrame (blk: blockPtr; gop: icptr);

   { Set up a stack frame for a new pc_ent			}
   {								}
   { parameters:						}
   {    blk - starting block					}
   {    gop - starting pc_ent					}

   label 1, 2, 3;

   const
      locSize = 4;			{variables <= this size allocated first}

   var
      bk: blockPtr; 			{used to trace block lists}
      minSize: integer;			{location for the next local label}
      needScan2: boolean;		{do we need the 2nd dc_loc scan?}
      op: icptr;			{used to trace code lists}
      sf: sfPtr;			{new stack frame record}


      procedure DirLoc1 (op: icptr);

      { allocates stack frame locations for small dc_loc	}

      begin {DirLoc1}
      if op^.q <= locSize then begin
	 if op^.r < maxLocalLabel then begin
	    localLabel[op^.r] := minSize;
	    minSize := minSize + op^.q;
	    end {if}
	 else
	    Error(cge2);
	 end {if}
      else
         needScan2 := true;
      end; {DirLoc1}


      procedure DirLoc2 (op: icptr);

      { allocates stack frame locations for large dc_loc	}

      begin {DirLoc2}
      if op^.q > locSize then begin
	 if op^.r < maxLocalLabel then begin
	    localLabel[op^.r] := minSize;
	    minSize := minSize + op^.q;
	    end {if}
	 else
	    Error(cge2);
	 end; {if}
      end; {DirLoc2}


      procedure DirPrm (op: icptr);

      { allocates stack frame locations for parameters		}

      begin {DirPrm}
      if op^.s < maxLocalLabel then
	 localLabel[op^.s] := localSize + returnSize + 1 + op^.r
      else
	 Error(cge2);
      end; {DirPrm}


      procedure Scan (op: icptr);

      { scans the code stream for instructions that effect the	}
      { size of the stack frame					}
      {								}
      { parameters: 						}
      {	op - scan this opcode and its children			}

      var
	 opcode: pcodes;		{op^.opcode}
	 size: integer;			{function return value size}

      begin {Scan}
      if op^.left <> nil then
	 Scan(op^.left);
      if op^.right <> nil then
	 Scan(op^.right);
      opcode := op^.opcode;
      if ((opcode = pc_cup) and ((op^.lab = nil) or (not noGlobalLabels)))
         or (opcode = pc_prs)
         or (op^.p <> 0) then begin
         if staticLoc = 0 then begin
            staticLoc := 1;
	    if dworkLoc <> 0 then
	       dworkLoc := dworkLoc + 2;
	    minSize := minSize + 2;
	    localSize := localSize + 2;
            end; {if}      
         end; {if}
      if opcode = dc_loc then
	 localSize := localSize + op^.q
      else if opcode = dc_fun then
	 localSize := localSize + op^.q
      else if opcode = dc_prm then
	 parameterSize := parameterSize + op^.q
      else if opcode in [pc_les,pc_leq,pc_grt,pc_geq] then begin
         if op^.optype in [cgByte,cgWord,cgUByte,cgUWord] then
            if Complex(op^.left) or Complex(op^.right) then
	       if dworkLoc = 0 then begin
		  dworkLoc := minSize;
		  minSize := minSize + 4;
		  localSize := localSize + 4;
		  end; {if}                              
	 end {else if}
      else if opcode in [pc_sto,pc_ind,pc_lor,pc_lnd,pc_ixa,pc_cum]
	 then begin
	 if dworkLoc = 0 then begin
	    dworkLoc := minSize;
	    minSize := minSize + 4;
	    localSize := localSize + 4;
	    end; {if}                              
	 end; {else if}
      end; {Scan}


   begin {StackFrame}
   while blk <> nil do begin
      new(sf);				{allocate a new stack frame}
      if sfList = nil then
	 sfList := sf
      else
	 sfLast^.next := sf;
      sfLast := sf;
      sf^.next := nil;
      localSize := 0;			{determine the size of the stack frame}
      parameterSize := 0;
      staticLoc := 0;
      funLoc := 0;
      dworkLoc := 0;
      minSize := 1;
      bk := blk;
      op := gop^.next;
      repeat
	 while op <> nil do begin
            if op^.opcode = pc_ent then
               goto 1;
	    Scan(op);
	    op := op^.next;
	    end; {while}
	 while (op = nil) and (bk <> nil) do begin
	    bk := bk^.next;
	    if bk <> nil then
               op := bk^.code;
            end; {while}
      until op = nil;
   1: if dataBank then begin
	 bankLoc := minSize;
	 minSize := minSize + 2;
	 localSize := localSize + 2;
	 end; {if}
      needScan2 := false;			{allocate locations for the values}
      bk := blk;
      op := gop^.next;
      repeat
	 while op <> nil do begin
            if op^.opcode = pc_ent then
               goto 2
	    else if op^.opcode = dc_loc then
	       DirLoc1(op)
	    else if op^.opcode = dc_fun then begin
	       DirLoc1(op);
               funLoc := localLabel[op^.r];
               end {else if}
	    else if op^.opcode = dc_prm then
	       DirPrm(op);
	    op := op^.next;
	    end; {while}
	 while (op = nil) and (bk <> nil) do begin
	    bk := bk^.next;
	    if bk <> nil then
               op := bk^.code;
            end; {while}
      until op = nil;
   2: if needScan2 then begin
	 bk := blk;
	 op := gop^.next;
	 repeat
	    while op <> nil do begin
               if op^.opcode = pc_ent then
        	  goto 3
	       else if op^.opcode = dc_loc then
		  DirLoc2(op)
	       else if op^.opcode = dc_fun then begin
		  DirLoc2(op);
        	  funLoc := localLabel[op^.r];
        	  end; {else if}
	       op := op^.next;              
	       end; {while}
	    while (op = nil) and (bk <> nil) do begin
	       bk := bk^.next;
	       if bk <> nil then
        	  op := bk^.code;
               end; {while}
	 until op = nil;
	 end; {if}
3:    blk := bk;			{get ready for next scan}
      gop := op;
      sf^.localSize := localSize;	{record the stack frame info}
      sf^.parameterSize := parameterSize;
      sf^.staticLoc := staticLoc;
      sf^.funLoc := funLoc;
      sf^.dworkLoc := dworkLoc;
      sf^.bankLoc := bankLoc;
      end; {while}
   end; {StackFrame}


begin {Gen}
enpFound := false;			{dc_enp not found, yet}
sfList := nil;				{no stack frame list}
while blk <> nil do begin		{generate code for the block}
   gop := blk^.code;
   while gop <> nil do begin
      if gop^.opcode = pc_ent then begin
         if sfList = nil then
            StackFrame(blk, gop);
	 localSize := sfList^.localSize;
	 parameterSize := sfList^.parameterSize;
	 staticLoc := sfList^.staticLoc;
	 funLoc := sfList^.funLoc;
	 dworkLoc := sfList^.dworkLoc;
	 bankLoc := sfList^.bankLoc;
         sfLast := sfList;
         sfList := sfList^.next;
         dispose(sfLast);
         end; {if}
      GenTree(gop);
      gop := gop^.next;
      end; {while}
   blk := blk^.next;
   end; {while}
if not enpFound then			{if dc_enp was optimized out, fake one}
   DirEnp;
end; {Gen}

end.
