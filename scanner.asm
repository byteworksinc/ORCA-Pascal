	mcopy	scanner.macros
****************************************************************
*
*  GetCom - Common Data for Get Character Module
*
****************************************************************
*
GetCom	data
;
;  Constants
;
autoGo	gequ	$06	auto-Go key code
breakPoint gequ $07	breakpoint key code
maxCnt	gequ	256	# chars on a line + 1
maxPath	gequ	255	max length of a path name
return	equ	$0D	RETURN key code
tab	equ	$09	tab key code
;
;  Size of pascal structures
;
constantSize equ 258	size of a constantRec
constantSize_longC   equ 6
constantSize_reel    equ 10
constantSize_pset    equ 260
constantSize_chset   equ 258
constantSize_strg    equ 258

displaySize equ 28	size of an element of the display array
ltypeSize equ 10	size of an ltype record
;
;  Displacements into records, by record-name_field-name
;
constant_rval equ 2	disp in constant of real value
constant_lval equ 2	disp in constant of longint value
constant_sval gequ 2	disp in constant of string characters

identifier_llink equ 4	disp in identifier of left link
identifier_rlink equ 8	disp in identifier of right link
identifier_klass equ 22	disp in identifier of klass record

display_ispacked equ 0	disp in display of ispacked field
display_labsused equ 2	disp in display of labsused
display_fname equ 6	disp in display of fname

ltype_next equ 0	disp in ltype of next
ltype_name equ 4	disp in ltype of name
ltype_disx equ 8	disp in ltype of disx

valu_ival equ	0	disp in valu of integer value
valu_valp equ	0	disp in valu of value pointer
;
;  Variables
;
digit	ds	maxCnt	string for building numeric constants
endOfUses ds	2	at end of a uses file?
test	ds	2
tInSymbol ds	3	first 3 bytes of InSymbol
;
;  Enumerations
;
bools	enum	(false,true),0
symbol	enum	(ident,intconst,realconst,stringconst,notsy,mulop,addop,relop),0
	enum	(lparent,rparent,lbrack,rbrack,comma,semicolon,period,arrow)
	enum	(colon,dotdot,becomes,labelsy,constsy,typesy,varsy,funcsy,progsy)
	enum	(procsy,setsy,packedsy,arraysy,recordsy,filesy,nilsy)
	enum	(beginsy,ifsy,casesy,repeatsy,whilesy,forsy,withsy)
	enum	(gotosy,endsy,elsesy,untilsy,ofsy,dosy,tosy,downtosy)
	enum	(thensy,othersy,otherwisesy,powersy,bitnot,usessy,stringsy)
	enum	(atsy,longintconst,unitsy,interfacesy,implementationsy)
	enum	(univsy,objectsy,inheritedsy)
operator enum	(noop,mul,rdiv,andop,idiv,imod,plus,minus,orop,ltop,leop,geop),0
	enum	(gtop,neop,eqop,inop,band,bor,xor,rshift,lshift)
cstclass enum	(reel,pset,strg,chset,long),0
chtp	enum	(letter,number,special,illegal,underLine),0
	enum	(chLComt,chStrQuo,chColon,chPeriod,chlt,chgt)
	enum	(chLParen,chSpace,chAsterisk,chDollar,chAt)
;
;  Structured constants
;
charTp	entry		character types
	dc	8i1'illegal'
	dc	i1'illegal,chSpace',6I1'illegal'
	dc	8i1'illegal'
	dc	8i1'illegal'
	dc	i1'chSpace,special,illegal,illegal,chDollar,illegal,special,chStrQuo'
	dc	i1'chLParen,special,chAsterisk,special,special,special,chPeriod,special'
	dc	8i1'number'
	dc	i1'number,number,chColon,special,chlt,special,chgt,illegal'
	dc	i1'chAt',7I1'letter'
	dc	8i1'letter'
	dc	8i1'letter'
	dc	3i1'letter',I1'special,illegal,special,special,underLine'
	dc	8i1'illegal'
	dc	8i1'illegal'
	dc	8i1'illegal'
	dc	3i1'illegal',I1'chLComt,special,illegal,special,illegal'

	dc	8i1'letter'	$80
	dc	8i1'letter'
	dc	8i1'letter'	$90
	dc	8i1'letter'
	dc	7i1'illegal',i1'letter'	$A0
	dc	5i1'illegal',i1'special',2i1'letter'
	dc	2i1'illegal',2i1'special',4i1'letter'	$B0
	dc	i1'letter,letter,illegal,letter,letter,letter,letter,letter'
	dc	i1'illegal,illegal,illegal,illegal,letter,illegal,letter,special'
	dc	i1'special,illegal,chSpace',5i1'letter'
	dc	6i1'illegal',i1'special',i1'illegal'	$D0
	dc	i1'letter,illegal,illegal,illegal,illegal,illegal,letter,letter'
	dc	8i1'illegal'	$E0
	dc	8i1'illegal'
	dc	8i1'illegal'	$F0
	dc	8i1'illegal'

uppercase anop
 dc i1'$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F'
 dc i1'$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F'
 dc i1'$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F'
 dc i1'$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F'
 dc c'@ABCDEFGHIJKLMNO'
 dc c'PQRSTUVWXYZ[\]^_'
 dc c'`ABCDEFGHIJKLMNO'
 dc c'PQRSTUVWXYZ{|}~',i1'$7F'
 dc i1'$80,$81,$82,$83,$84,$85,$86,$87,$CB,$89,$80,$CC,$81,$82,$83,$8F'
 dc i1'$90,$91,$92,$93,$94,$95,$84,$97,$98,$99,$85,$CD,$9C,$9D,$9E,$86'
 dc i1'$A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF'
 dc i1'$B0,$B1,$B2,$B3,$B4,$B5,$C6,$B7,$B8,$B8,$BA,$BB,$BC,$BD,$AE,$AF'
 dc i1'$C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CE'
 dc i1'$D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF'
 dc i1'$E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF'
 dc i1'$F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF'
;
;  DCB's
;
st_dcb	anop		stop dcb
st_flag	ds	2
	end

****************************************************************
*
*  EndDigit - Flag the end of a digit
*
*  Inputs:
*	Y - disp in line
*	X - disp in digit
*
****************************************************************
*
EndDigit private
	using GetCom

	stz	digit,X
	sty	chCnt
	jsl	NextCh
	rts
	end

****************************************************************
*
*  EndOfLine - Read in the next source line
*
*  Inputs:
*	chPtr - pointer to the next line to read
*
*  Outputs:
*	LINECOUNT - updated; # lines read
*	chPtr - updated
*	LINE - characters in this line
*	ERRINX - # errors in this line; set to 0
*	chCnt - # characters read from the line; set to 0
*
****************************************************************
*
EndOfLine private
	using GetCom
cPtr	equ	1	local copy of chPtr

         sub	,4

	move4	chPtr,cPtr	cPtr := chPtr
	stop	st_dcb	if user flagged an abort then
	lda	st_flag	  TermError(0, nil);
	beq	st1
	ph2	#0
	ph4	#0
	jsl	TermError
st1	jsl	ListLine	ListLine;
	inc	LINECOUNT	linecount := linecount+1;
	clc		<skip to end of old line>
	lda	cPtr
	adc	chCnt
	sta	cPtr
	bcc	lb1
	inc	cPtr+2
lb1	stz	chCnt	chCnt := 0;
	stz	ERRINX	ERRINX := 0;
	stz	debugType	DEBUGTYPE := 0;
	lda	[cPtr]	if cPtr^ in [autoGo,breakPoint] then
	and	#$00FF	  begin
	cmp	#breakPoint
	beq	lb2
	cmp	#autoGo
	bne	lb4	  if cPtr^ = autoGo then
	lda	#2	    debugType := 2
	bra	lb3	  else
lb2	lda	#1	    debugType := 1;
lb3	sta	debugType
	inc4	cPtr	  cPtr := pointer(ord4(cPtr)+1);
lb4	anop		  end; {if}

	move4	cPtr,chPtr	chPtr := cPtr
	ret
	end

****************************************************************
*
*  FakeInsymbol - install the uses file InSymbol patch
*
****************************************************************
*
FakeInsymbol private
	using GetCom

	lda	InSymbol	set up fake InSymbol
	sta	tInSymbol
	lda	InSymbol+1
	sta	tInSymbol+1
	lda	jmp
	sta	InSymbol
	lda	jmp+1
	sta	InSymbol+1
	rtl

jmp	jmp	UsesInSymbol
	end

****************************************************************
*
*  InSymbol - Read the next symbol from the source file
*
*  Outputs:
*	SY - kind of symbol found
*	OP - classification of symbol
*	VAL - value of last constant
*	LGTH - length of last string constant
*	ID - last identifier
*
****************************************************************
*
InSymbol start
	using GetCom
rwLen	equ	15	# bytes in a reserved word

cPtr	equ	1	local copy of chPtr
lvp	equ	5	constant record
count	equ	9	loop counter
aindex	equ	11	array index
k	equ	13	temp index variable

	sub	,14

lb1	lda	endOfUses	if endOfUses then
	beq	lab1
	lda	#othersy	  sy := othersy;
	sta	SY
	stz	endOfUses	  endOfUses := false;
	brl	end	  return;

lab1	anop		1:
	lda	CH	  while (charTp[ch] = chSpace) and
	cmp	#' '	    not eofl do
	beq	lb2	    nextch;
	cmp	#$CA
	beq	lb2
	cmp	#tab
	bne	lb4
lb2	lda	EOFL
	bne	lb3
	jsl	NextCh
	bra	lb1
lb3	lda	CH	  case charTp[ch] of
lb4	tax
	lda	charTp,X
	and	#$00FF
	asl	A
	tax
	jmp	(caseTable,X)

caseTable anop		jump table for the case statement
	dc	a'lr1'	letter
	dc	a'nm1'	number
	dc	a'sp1'	special
	dc	a'il1'	illegal
	dc	a'un1'	underLine
	dc	a'cm1'	clLComt
	dc	a'qt1'	chStrQuo
	dc	a'cl1'	colon
	dc	a'dt1'	period
	dc	a'lt1'	chlt
	dc	a'gt1'	chgt
	dc	a'lp1'	chLParen
	dc	a'bl1'	chSpace
	dc	a'as1'	chAsterisk
	dc	a'dl1'	chDollar
	dc	a'at1'	chAt
;
;  Flag and skip illegal characters
;
il1	anop		    illegal: begin
	listerror #6	      error(6);
	jsl	NextCh	      nextch;
	brl	lab1	      goto 1;
;			      end;
;
;  Skip leading white space
;
bl1	anop		    chSpace:
	lda	#otherSy	      sy := othersy;
	sta	SY
	brl	end
;
;  Handle identifiers and reserved words
;
un1	anop		    underline,
lr1	anop		    letter: begin
	move4	chPtr,cPtr
!			      k := 0;
!			      id[0] := chr(0);
	stz	id
	ldy	chCnt
	dey
	ldx	#0
	short M
lr2	anop		      repeat
	lda	[cPtr],Y		if iso then
	cmp	#'_'		  if (ch = '_')
	beq	lr2a
	cmp	#$80		    or (ord(ch) > $7F) then
	blt	lr4
lr2a	pha
	lda	ISO
	beq	lr3
	long	M		    error(112);
	phx
	phy
	listerror #112
	ply
	plx
	lda	#0
	short M
lr3	pla
!				k := k+1;
lr4	stx	k		if k <= maxcnt then
	tax			  id[k] := ch;
	lda	upperCase,X
	tax
	lda	charTp,X
	cmp	#letter
	beq	lr6
	cmp	#number
	beq	lr6
	cmp	#underLine
	bne	lr7
lr6	txa
	ldx	k
	sta	id+1,X
	iny			nextch;
	inx
	bra	lr2	      until not
!				(charTp[ch] in
!				[letter,number,underscore]);
lr7	sty	chCnt
	lda	k	      id[0] := chr(k);
	sta	id
	long	M
	jsr	LNextCh
	lda	k	      if k < rwLen then begin
	cmp	#rwLen
	jge	lr9a
	lda	id+1		index := ord(id[1])-ord('a');
	and	#$00FF
	asl	a
	tax
	lda	nrw-'A'*2,X		for i := frw[index] to
	jeq	lr9a		  frw[index+1] - 1 do
	sta	count
	lda	arw-'A'*2,X
	sta	aindex
	tax
lr8	lda	|0,X		  if rw[i] = id then begin
	cmp	id
	bne	lr9
	and	#$00FF
	dec	A
	tay
	phx
	clc
	adc	1,S
	plx
	tax
	short	M
cp1	lda	|1,X
	cmp	id+1,Y
	bne	lr9
	dex
	dey
	bne	cp1
	long	M
	ldx	aindex
	lda	|rwLen,X		    sy := rsy[i];
	sta	SY
	lda	|rwLen+2,X		    op := rop[i];
	sta	OP
	lda	ISO		    if not (iso and
	beq	lr8a
	lda	SY		      ((sy = otherwisesy)
	cmp	#otherwisesy
	beq	lr9a
	cmp	#stringsy		      or (sy = stringsy)
	beq	lr9a
	cmp	#unitsy		      or (sy = unitsy)
	beq	lr9a
	cmp	#interfacesy		      or (sy = interfacesy)
	beq	lr9a
	cmp	#implementationsy		      or (sy = implementationsy)
	beq	lr9a
	cmp	#univsy		      or (sy = univsy)
	beq	lr9a
	cmp	#usessy		      or (sy = usessy)))
	beq	lr9a
	cmp	#objectsy		      or (sy = objectsy)))
	beq	lr9a
	cmp	#inheritedsy		      or (sy = inheritedsy)))
	beq	lr9a		      then
lr8a	brl	end		      goto 2;
lr9	long	M		    end;
	clc
	lda	aindex
	adc	#rwLen+4
	sta	aindex
	tax
	dec	count
	jne	lr8
!				end;
lr9a	lda	#ident	      sy := ident;
	sta	SY
	lda	#noop	      op := noop;
	sta	OP
	brl	end	2:    end;
;
;  Handle numeric constants
;
nm1	anop		    number: begin
	move4	chPtr,cPtr
	lda	#noop	      op := noop;
	sta	OP
	ldy	chCnt	      k := 0;
	dey
	ldx	#0
	jsr	SaveDigits2	      repeat
!				savedigit;
!			      until charTp[ch] <> number;
	lda	#intconst	      sy := intconst;
	sta	SY
	lda	[cPtr],Y	      if ((ch = '.') and
	and	#$00FF		(line[chCnt+1] <> ')') and
	cmp	#'e'		(line[chCnt+1] <> '.')) or
	beq	nm2		(ch = 'e') then begin
	cmp	#'E'
	beq	nm2
	cmp	#'.'
	bne	nm12a
	lda	[cPtr],Y
	cmp	#').'
	beq	nm12a
	cmp	#'..'
	bne	nm2
nm12a	brl	nm12
nm2	lda	[cPtr],Y		if ch = '.' then begin
	and	#$00FF
	cmp	#'.'
	bne	nm5
	sta	digit,X		  savedigit;
	inx
	iny
	jsr	SaveDigits		  if charTp[ch] <> number then
!				    error(103)
!				  else
!				    repeat
!				      savedigit
!				    until charTp[ch] <> number;
nm5	anop			  end;
	lda	[cPtr],Y		if ch = 'e' then begin
	and	#$00FF
	cmp	#'e'
	beq	nm6
	cmp	#'E'
	bne	nm9
nm6	sta	digit,X		  savedigit;
	iny
	inx
	lda	[cPtr],Y		  if (ch = '+') or (ch ='-')
	and	#$00FF
	cmp	#'+'
	beq	nm7
	cmp	#'-'
	bne	nm8
nm7	sta	digit,X		    then savedigit;
	iny
	inx
nm8	jsr	SaveDigits		  if charTp[ch] <> number then
!				    error(103)
!				  else
!				    repeat
!				      savedigit
!				    until charTp[ch] <> number;
!				  end;
nm9	jsr	EndDigit		{finish reading number}
	ph2	#constantSize_reel		new(lvp,reel);
	jsl	Malloc
	sta	lvp
	stx	lvp+2
	lda	#realconst		sy:= realconst;
	sta	SY
	lda	#reel		lvp^.cclass := reel;
	sta	[lvp]
	ph4	#digit		lvp^.rval := cnvsr(digit);
	ph4	#index		{convert from ascii to decform}
	ph4	#decrec
	ph4	#valid
	stz	index
	stz	index+2
	fcstr2dec
	lda	valid		{flag an error if SANE said to}
	beq	nm10
	ldy	index
	lda	digit,Y
	and	#$00FF
	bne	nm10
	ph4	#decrec		{convert decform to real}
	ph4	#realvalue
	fdec2d
	bcs	nm10
	lda	realvalue		{save the result}
	ldy	#constant_rval
	sta	[lvp],Y
	lda	realvalue+2
	iny
	iny
	sta	[lvp],Y
	lda	realvalue+4
	iny
	iny
	sta	[lvp],Y
	lda	realvalue+6
	iny
	iny
	sta	[lvp],Y
	bra	nm11		if syserr then
nm10	listerror #105		  error(105);
nm11	move4 lvp,VAL+valu_valp		val.valp := lvp
	bra	nm15		end
nm12	anop		      else begin
	ph4	#0		lval := cnvs4(digit);
	ph4	#digit		if syserr then
	phx			  error(105);
	jsr	EndDigit		  {finish reading number}
	ph2	#1
	_dec2long
	bcc	nm13
	listerror #105
nm13	lda	3,S		if istwobyte(lval) then
	tax
	lda	1,S
	bpl	nm14
	inx
nm14	txa
	bne	nm14a
	pla			  ival := lval
	sta	VAL+valu_ival
	pla
	bra	nm15		else begin

nm14a	ph2	#constantSize_longC	          lvp := pointer(Malloc(sizeof(constantRec)));
	jsl	Malloc
	sta	lvp
	stx	lvp+2
	lda	#longintconst		  sy := longintconst;
	sta	SY
	lda	#long		  lvp^.cclass := long;
	sta	[lvp]
	pla
	ldy	#constant_lval
	sta	[lvp],Y
	pla
	iny
	iny
	sta	[lvp],Y
	move4 lvp,VAL+valu_valp		  val.valp := lvp
!				  end;
!				end;
nm15	lda	CH	      if charTp[ch] = letter then
	cmp	#'A'
	blt	nm16
	cmp	#'Z'+1
	bge	nm16
	listerror #103		error(103);
nm16	brl	end	      end;
;
;  Handle hex constants
;
dl1	anop		    number: begin
	lda	#noop	      op := noop;
	sta	OP
	lda	#intconst	      sy := intconst;
	sta	SY
	jsl	NextCh	      nextch;

	pea	0	      t := 0;
	pea	0
	ldy	#0	      chCnt := 0;
dl2	lda	CH	      while isHex(ch) do
	cmp	#'0'
	blt	dl7
	cmp	#'F'+1
	bge	dl7
	cmp	#'9'+1
	blt	dl3
	cmp	#'A'
	blt	dl7
dl3	iny			chCnt := chCnt+1;
	lda	3,S		if t > $FFFFFFF then begin
	cmp	#$1000
	blt	dl4
	phy
	listError #105		  error(105);
	ply
	brl	dl7		  goto 1;
dl4	anop			  end;
	ldx	#4		t := t<<4 | hexVal(ch);
dl5	pla
	asl	a
	pha
	lda	3,S
	rol	a
	sta	3,S
	dex
	bne	dl5
	lda	CH
	cmp	#'A'
	blt	dl6
	sbc	#7
dl6	and	#$000F
	ora	1,S
	sta	1,S
	phy			NextCh;
	jsl	NextCh
	ply
	bra	dl2		end;
dl7	cpy	#5	      if chCnt <= 4 then
	bge	dl8
	lda	1,S		if ord(t) < 0 then
	bpl	dl8
	lda	#$FFFF		  t := t | $FFFF0000;
	sta	3,S
dl8	brl	nm13
;
;  Handle string and character constants
;
qt1	anop		    chStrQuo: begin
	move4	chPtr,cPtr
	lda	#stringconst	      sy := stringconst;
	sta	SY
	lda	#noop	      op := noop;
	sta	OP
	ldx	#0	      lgth := 0;
	ldy	chCnt
	dey
	short M
qt2	anop		      repeat
qt3	anop			repeat
	iny			  nextch;
	lda	[cPtr],Y		  lgth := lgth + 1;
	sta	lString+1,X		  lString[lgth] := ch;
	inx
	cmp	#RETURN		until (eol) or (ch = '''');
	beq	qt4
	cmp	#''''
	bne	qt3
!				if not eol then
	iny			  nextch
	bra	qt5		else
qt4	long	M
	phy			  error(104)
	listerror #104
	ply
	ldx	#2
	bra	qt6
qt5	longa off
	lda	[cPtr],Y	      until ch <> '''';
	cmp	#''''
	beq	qt3
	long	M
qt6	dex
	stx	LGTH
	sty	chCnt
	jsr	LNextCh
!			      lgth := lgth - 1;
!			      {now lgth = nr of chars in string}
	lda	LGTH	      if (lgth = 0) and iso then begin
	bne	qt7
	lda	ISO
	beq	qt7
	listerror #106		error(106);
	lda	#1		lgth := 1;
	sta	LGTH
qt7	anop			end;
	short	M	      lString[0] := chr(lgth);
	lda	LGTH
	sta	lString
	long	M
	jsl	SaveString	      if lgth = 1 then
!				val.ival := ord(lString[1])
!			      else begin
!				new(lvp,strg);
!				lvp^.cclass:=strg;
!				lvp^.slgth := lgth;
!				for i := 1 to lgth do
!				  lvp^.sval[i] := lString[i];
!				val.valp := lvp;
!				end
	brl	end	      end;
;
;  Handle : and :=
;
cl1	anop		    chColon: begin
	lda	#noop	      op := noop;
	sta	OP
	jsl	NextCh	      nextch;
	lda	CH	      if ch = '=' then begin
	cmp	#'='
	bne	cl2
	lda	#becomes		sy := becomes;
	sta	SY
	jsl	NextCh		nextch;
	brl	end		end
cl2	anop		      else
	lda	#colon		sy := colon
	sta	SY
	brl	end	      end;
;
;  Handle * and **
;
as1	anop		    chAsterisk: begin
	jsl	NextCh	      nextch;
	lda	CH	      if ch = '*' then begin
	cmp	#'*'
	bne	as2
	lda	#powersy		sy := powersy;
	sta	SY
	lda	#noop		op := noop;
	sta	OP
	jsl	NextCh		nextch;
	brl	end		end
as2	anop		      else
	lda	#mulop		sy := mulop;
	sta	SY
	lda	#mul		op := mul;
	sta	OP
	brl	end	      end;
;
;  Handle ., .. and .) -- .) substitutes for ]
;
dt1	anop		    chPeriod: begin
	lda	#noop	      op := noop;
	sta	OP
	jsl	NextCh	      nextch;
	lda	CH	      if ch = '.' then begin
	cmp	#'.'
	bne	dt2
	lda	#dotdot		sy := dotdot;
	sta	SY
	jsl	NextCh		nextch;
	brl	end		end
dt2	cmp	#')'	      else if ch = ')' then begin
	bne	dt3
	lda	#rbrack		sy := rbrack;
	sta	SY
	jsl	NextCh		nextch;
	brl	end		end
dt3	anop		      else
	lda	#period		sy := period;
	sta	SY
	brl	end	      end;
;
;  Handle <, <<, <= and <>
;
lt1	anop		    chlt: begin
	jsl	NextCh	      nextch;
	lda	#relop	      sy := relop;
	sta	SY
	lda	CH	      if ch = '=' then begin
	cmp	#'='
	bne	lt2
	lda	#leop		op := leop;
	sta	OP
	jsl	NextCh		nextch;
	brl	end		end
lt2	cmp	#'>'	      else if ch = '>' then begin
	bne	lt3
	lda	#neop		op := neop;
	sta	OP
	jsl	NextCh		nextch;
	brl	end		end
lt3	cmp	#'<'	      else if ch = '<' then begin
	bne	lt4
	lda	#mulop		sy := mulop;
	sta	SY
	lda	#lshift		op := lshift;
	sta	OP
	jsl	NextCh		nextch;
	brl	end		end
lt4	anop		      else
	lda	#ltop		op := ltop;
	sta	OP
	brl	end	      end;
;
;  Handle >, >> and >=
;
gt1	anop		    chgt: begin
	jsl	NextCh	      nextch;
	lda	#relop	      sy := relop;
	sta	SY
	lda	CH	      if ch = '=' then begin
	cmp	#'='
	bne	gt2
	lda	#geop		op := geop;
	sta	OP
	jsl	NextCh		nextch;
	brl	end		end
gt2	cmp	#'>'	      else if ch = '>' then begin
	bne	gt3
	lda	#mulop		sy := mulop;
	sta	SY
	lda	#rshift		op := rshift;
	sta	OP
	jsl	NextCh		nextch;
	brl	end		end
gt3	anop		      else
	lda	#gtop		op := gtop;
	sta	OP
	brl	end	      end;
;
;  Handle comments and ( and (. tokens -- (. substitutes for [
;
lp1	anop		    chLComt,chLParen: begin
!			      if charTp[ch] = chLParen then
	jsl	NextCh		nextch
!			      else
!				ch := '*';
	lda	CH	      if ch = '*' then begin
	cmp	#'*'
	bne	cm6
cm1	jsl	NextCh		nextch;
	lda	CH		if ch = '$' then
	cmp	#'$'
	bne	cm2
	jsl	options		  options;
	lsr	A
	bcs	cm2
	lda	#' '		  {for append, copy, don't}
	sta	CH		  {scan for end of comment}
	brl	lab1
cm2	jsl	SkipComment		  skipcomment;
	brl	lab1		goto 1
cm6	anop			end;
	cmp	#'.'	      if ch = '.' then begin
	bne	cm7
	jsl	NextCh		nextch;
	lda	#lbrack		sy := lbrack;
	bra	cm8		end
cm7	anop		      else
	lda	#lparent		sy := lparent;
cm8	sta	SY
	lda	#noop	      op := noop;
	sta	OP
	brl	end	      end;
;
;  Handle the @ character.
;
at1	anop		    begin
	jsl	NextCh	      NextCh;
	lda	ISO	      if iso then
	beq	at2
	lda	#arrow		sy := arrow
	bra	at3	      else
at2	lda	#atsy		sy := atsy;
at3	sta	SY
	lda	#noop	      op := noop;
	sta	OP
	brl	end	      end;
;
;  Set the symbol and operation for special symbols from two arrays.
;
sp1	anop		    special: begin
	lda	ISO	      if iso then
	beq	sp2
	lda	CH	        if ord(ch) >= 128 then
	and	#$0080
	beq	sp2
	listerror #112	          error(112);

sp2	lda	CH	      sy := ssy[ch];
	tax
	lda	ssy-' ',X
	and	#$00FF
	sta	SY
	lda	sop-' ',X	      op := sop[ch];
	and	#$00FF
	sta	OP
	jsl	NextCh	      nextch;
!			      end;
end	anop		  end {case}
;
;  If in an interface file, write the token to it
;
	lda	DOINGINTERFACE	if doingInterface
	beq	if0	  and not doingOption then begin
	lda	doingOption
	beq	if0a
if0	brl	if7
if0a	ph2	SY	  TokenOut(sy);
	jsl	TokenOut
	lda	SY	  if sy in [mulop,addop,relop] then
	cmp	#mulop
	beq	if0b
	cmp	#addop
	beq	if0b
	cmp	#relop
	bne	if0c
if0b	ph2	OP	    TokenOut(op);
	jsl	TokenOut
	brl	if7
if0c	cmp	#ident	  else if sy = ident then begin
	bne	if2
	ldx	#0	    for i := 1 to length(id) do
	lda	id
	and	#$00FF
	tay
if1	lda	id+1,X	      TokenOut(ord(id[i]));
	and	#$00FF
	phx
	phy
	pha
	jsl	TokenOut
	ply
	plx
	inx
	dey
	bne	if1
	pea	' '	    TokenOut(' ');
	jsl	TokenOut
	brl	if7	    end
if2	cmp	#intconst	  else if sy = intconst then begin
	bne	if3
	ph2	VAL+valu_ival	    TokenOut(ival);
	jsl	TokenOut
	lda	VAL+valu_ival	    TokenOut(ival >> 8);
	xba
	pha
	jsl	TokenOut
	brl	if7	    end
if3	cmp	#longintconst	  else if sy = longintconst then begin
	bne	if4
	ldy	#constant_lval	    TokenOut(lvp^.lval);
	lda	[lvp],Y	    TokenOut(lvp^.lval >> 8);
	xba
	pha
	xba
	pha
	jsl	TokenOut
	jsl	TokenOut
	ldy	#constant_lval+2	    TokenOut(lvp^.lval >> 16);
	lda	[lvp],Y	    TokenOut(lvp^.lval >> 24);
	xba
	pha
	xba
	pha
	jsl	TokenOut
	jsl	TokenOut
	bra	if7	    end
if4	cmp	#realconst	  else if sy = realconst then begin
	bne	if5
	ph2	realvalue	    for i := 0 to 7 do begin
	jsl	TokenOut	      ptr := pointer(@realvalue+i);
	ph2	realvalue+1	      TokenOut(ptr^);
	jsl	TokenOut	      end;
	ph2	realvalue+2
	jsl	TokenOut
	ph2	realvalue+3
	jsl	TokenOut
	ph2	realvalue+4
	jsl	TokenOut
	ph2	realvalue+5
	jsl	TokenOut
	ph2	realvalue+6
	jsl	TokenOut
	ph2	realvalue+7
	jsl	TokenOut
	bra	if7	    end
if5	cmp	#stringconst	  else if sy = stringconst then begin
	bne	if7
	ph2	lgth	    TokenOut(lgth);
	jsl	TokenOut
	ldx	#0	    for i := 1 to lgth do
if6	lda	lString+1,X	      TokenOut(ord(lString[i]));
	phx
	pha
	jsl	TokenOut
	plx
	inx
	cpx	lgth
	bne	if6
!			    end;
if7	anop		  end;
	ret	 	end; {insymbol}
;
;  LNextCh - call NextCh, then reset cPtr
;
LNextCh	jsl	NextCh
	move4	chPtr,cPtr
	rts
;
;  Local data areas
;
ssy	anop		special character symbol definitions
	dc	i1'0,addop,0,0,0,0,mulop,0'
	dc	i1'lparent,rparent,0,addop,comma,addop,0,mulop'
	dc	8i1'0'
	dc	i1'0,0,0,semicolon,0,relop,0,0'
	dc	i1'0,0,0,0,0,0,0,0'
	dc	8i1'0'
	dc	8i1'0'
	dc	i1'0,0,0,lbrack,0,rbrack,arrow,0'
	dc	8i1'0'
	dc	8i1'0'
	dc	8i1'0'
	dc	i1'0,0,0,0,addop,0,bitnot,0'
	dc	8i1'0'				$80
	dc	8i1'0'
	dc	8i1'0'				$90
	dc	8i1'0'
	dc	8i1'0'				$A0
	dc	i1'0,0,0,0,0,relop,0,0'
	dc	i1'0,0,relop,relop,0,0,0,0'			$B0
	dc	8i1'0'
	dc	i1'0,0,0,0,0,0,0,mulop'				$C0
	dc	i1'mulop,0,0,0,0,0,0,0'
	dc	i1'0,0,0,0,0,0,mulop,0'				$D0
;	dc	8i1'0'
sop	dc	i1'0,xor,0,0,0,0,band,0'
	dc	i1'0,0,0,plus,0,minus,0,rdiv'
	dc	8i1'0'
	dc	i1'0,0,0,0,0,eqop,0,0'
	dc	8i1'0'
	dc	8i1'0'
	dc	8i1'0'
	dc	8i1'0'
	dc	8i1'0'
	dc	8i1'0'
	dc	8i1'0'
	dc	i1'0,0,0,0,bor,0,0,0'
	dc	8i1'0'				$80
	dc	8i1'0'
	dc	8i1'0'				$90
	dc	8i1'0'
	dc	8i1'0'				$A0
	dc	i1'0,0,0,0,0,neop,0,0'
	dc	i1'0,0,leop,geop,0,0,0,0'			$B0
	dc	8i1'0'
	dc	i1'0,0,0,0,0,0,0,lshift'				$C0
	dc	i1'rshift,0,0,0,0,0,0,0'
	dc	i1'0,0,0,0,0,0,idiv,0'				$D0
;	dc	8i1'0'
nrw	dc	i'2,1,2,3,2,3,1,0,5,0'	number of reserved words starting with
	dc	i'0,1,1,2,4,3,0,2,2,3'	 each letter of the alphabet
	dc	i'4,1,2,0,0,0'
	dc	i'0,0,0,0,0'		[\]^_ (_ is an allowed identifier prefix)
arw	dc	a'rwa,rwb,rwc,rwd,rwe'	address of first reserved word for each
	dc	a'rwf,rwg,rwh,rwi,rwj'	 letter of the alphabet
	dc	a'rwk,rwl,rwm,rwn,rwo'
	dc	a'rwp,rwq,rwr,rws,rwt'
	dc	a'rwu,rwv,rww,rwx,rwy'
	dc	a'rwz'
!
rwa	dc	i1'3',c'AND           ',i'mulop,andop'    reserved words, old rsy &
	dc	i1'5',c'ARRAY         ',i'arraysy,0'	      rop arrays
rwb	dc	i1'5',c'BEGIN         ',i'beginsy,0'
rwc	dc	i1'4',c'CASE          ',i'casesy,0'
	dc	i1'5',c'CONST         ',i'constsy,0'
rwd	dc	i1'2',c'DO            ',i'dosy,0'
	dc	i1'3',c'DIV           ',i'mulop,idiv'
	dc	i1'6',c'DOWNTO        ',i'downtosy,0'
rwe	dc	i1'3',c'END           ',i'endsy,0'
	dc	i1'4',c'ELSE          ',i'elsesy,0'
rwf	dc	i1'3',c'FOR           ',i'forsy,0'
	dc	i1'8',c'FUNCTION      ',i'funcsy,0'
	dc	i1'4',c'FILE          ',i'filesy,0'
rwg	dc	i1'4',c'GOTO          ',i'gotosy,0'
rwh	anop
rwi	dc	i1'2',c'IF            ',i'ifsy,0'
	dc	i1'2',c'IN            ',i'relop,inop'
	dc	i1'9',c'INTERFACE     ',i'interfacesy,0'
	dc	i1'14',c'IMPLEMENTATION',i'implementationsy,0'
	dc	i1'9',c'INHERITED     ',i'inheritedsy,0'
rwj	anop
rwk	anop
rwl	dc	i1'5',c'LABEL         ',i'labelsy,0'
rwm	dc	i1'3',c'MOD           ',i'mulop,imod'
rwn	dc	i1'3',c'NIL           ',i'nilsy,0'
	dc	i1'3',c'NOT           ',i'notsy,0'
rwo	dc	i1'2',c'OF            ',i'ofsy,0'
	dc	i1'2',c'OR            ',i'addop,orop'
	dc	i1'9',c'OTHERWISE     ',i'otherwisesy,0'
	dc	i1'6',c'OBJECT        ',i'objectsy,0'
rwp	dc	i1'9',c'PROCEDURE     ',i'procsy,0'
	dc	i1'6',c'PACKED        ',i'packedsy,0'
	dc	i1'7',c'PROGRAM       ',i'progsy,0'
rwq	anop
rwr	dc	i1'6',c'REPEAT        ',i'repeatsy,0'
	dc	i1'6',c'RECORD        ',i'recordsy,0'
rws	dc	i1'3',c'SET           ',i'setsy,0'
	dc	i1'6',c'STRING        ',i'stringsy,0'
rwt	dc	i1'4',c'THEN          ',i'thensy,0'
	dc	i1'2',c'TO            ',i'tosy,0'
	dc	i1'4',c'TYPE          ',i'typesy,0'
rwu	dc	i1'5',c'UNTIL         ',i'untilsy,0'
	dc	i1'4',c'USES          ',i'usessy,0'
	dc	i1'4',c'UNIT          ',i'unitsy,0'
	dc	i1'4',c'UNIV          ',i'univsy,0'
rwv	dc	i1'3',c'VAR           ',i'varsy,0'
rww	dc	i1'4',c'WITH          ',i'withsy,0'
	dc	i1'5',c'WHILE         ',i'whilesy,0'
rwx	anop
rwy	anop
rwz	anop

index	ds	4	index into string
decrec	ds	33	decimal record for conversion
valid	ds	4	valid prefix flag
realvalue ds	8	binary format real number
	end

****************************************************************
*
*  ListLine - List the current line and any errors found
*
*  Inputs:
*	LIST - source listing on?
*	ERRINX - # errors in this line
*	LINE - source line to list
*	errList - array of error numbers
*
****************************************************************
*
ListLine private
	using GetCom
errtype_nmr equ 0	disps in errtype record
errtype_pos equ 2

i	equ	1
k	equ	3
cPtr	equ	5	local copy of chPtr
r0	equ	9	work register
lch	equ	11	temp character

	sub	,12

	jsl	KeyPress	if <a key has been pressed> then begin
	tay
	beq	kp1
	jsl	DrawHourglass	  DrawHourglass;
kp0	jsl	Keypress	  repeat
	tay
	beq	kp0	  until KeyPress;
	jsl	ClearHourglass	  ClearHourglass;
kp1	anop		  end;
	lda	LIST	if (list or (errinx > 0)) and
	ora	ERRINX	  linecount then begin
	jeq	lb9
	lda	LINECOUNT
	jeq	lb9
	put2	LINECOUNT,#4	  write(linecount:4,' ');
	putc	#' '
	move4	chPtr,cPtr	  while line[i] <> return do begin
	ldy	#0
lb1	lda	[cPtr],Y
	and	#$00FF
	cmp	#return
	beq	lb2
	phy		    write(line[i]);
	sta	lch
	putc	lch
	ply
	iny		    i := i+1;
	bra	lb1	    end;
lb2	jsl	LineFeed	  LineFeed;
	ldx	#1	  for i := 1 to errinx do begin
	stx	i
lb3	lda	i
	cmp	ERRINX
	jgt	lb8
	puts	#'****'	    write('****');
	lda	i	    for k := 1 to errlist[i].pos-1 do
	asl	A
	asl	A
	tax
	lda	errList-4+errtype_pos,X
	dec	a
	beq	lb5
	bmi	lb5
	cmp	#maxcnt
	bge	lb5
	sta	k
lb4	putc	#' '	      write(' ');
	dbne	k,lb4
lb5	puts	#'^ '	    write('^ ');
	lla	r0,msgs	    <find error message>
	lda	i
	asl	A
	asl	A
	tax
	lda	errList-4+errtype_nmr,X
	sta	k
lb6	dbeq	k,lb7
	lda	(r0)
	and	#$00FF
	sec
	adc	r0
	sta	r0
	bra	lb6
lb7	dec	r0	    <write the error message>
	puts	{r0}
	inc	r0
	jsl	LineFeed	    LineFeed;
	lda	allTerm	    if allTerm then
	beq	lb7a
	lda	i	      chCnt := errlist[i].pos-2;
	asl	A
	asl	A
	tax
	lda	errList-4+errtype_pos,X
	dec	a
	dec	a
	sta	chCnt
	ph2	#0	      TermError(0, r0);
	ph2	#msgs|(-16)
	ph2	r0
	jsl	TermError
lb7a	inc	i	    end;
	brl	lb3
lb8	lda	ERRINX	  if (errinx > 0) and 
	beq	lb9	    (not printer) then
	lda	printer
	bne	lb9
	jsl	WaitForKeyPress	    WaitForKeyPress;
lb9	anop		  end;
	jsl	Spin	  Spin;
	ret

msgs	dw	'error in simple type'	1
	dw	'identifier expected'
	dw	'''program'' expected'
	dw	''')'' expected'
	dw	''':'' expected'
	dw	'illegal symbol'
	dw	'error in parameter list'
	dw	'''of'' expected'
	dw	'''('' expected'
	dw	'error in type'	10
	dw	'''['' expected'
	dw	''']'' expected'
	dw	'''end'' expected'
	dw	''';'' expected'
	dw	'integer expected'
	dw	'''='' expected'
	dw	'''begin'' expected'
	dw	'error in declaration part'
	dw	'error in field-list'
	dw	''','' expected'	20
	dw	'''.'' expected'
	dw	'error in constant'
	dw	''':='' expected'
	dw	'''then'' expected'
	dw	'''until'' expected'
	dw	'''do'' expected'
	dw	'''to'' expected'
	dw	'error in factor'
	dw	'error in variable'
	dw	'identifier declared twice' 30
	dw	'low bound exceeds high bound'
	dw	'identifier is not of appropriate class'
	dw	'identifier not declared'
	dw	'sign not allowed'
	dw	'number expected'
	dw	'incompatible subrange types'
	dw	'quoted file name expected'
	dw	'type must not be real'
	dw	'tagfield type must be scalar or subrange'
	dw	'incompatible with tagfield type' 40
	dw	'index type must be scalar or subrange'
	dw	'base type must not be real'
	dw	'base type must be scalar or subrange'
	dw	'error in type of standard procedure parameter'
	dw	'forward declared; repitition of parameter list not allowed'
	dw	'function result type must be scalar, subrange or pointer'
	dw	'file value parameter not allowed'
	dw	'forward declared function; cannot repeat type'
	dw	'missing result type in function declaration'
	dw	'F-format for real only' 50
	dw	'error in type of standard function parameter'
	dw	'number of parameters does not agree with declaration'
	dw	'result type of function does not agree with declaration'
	dw	'type conflict of operands'
	dw	'expression is not of set type'
	dw	'only tests on equality allowed'
	dw	'strict inclusion not allowed'
	dw	'file comparison not allowed'
	dw	'illegal type of operand(s)'
	dw	'type of operand must be boolean' 60
	dw	'set element type must be scalar or subrange'
	dw	'set element types not compatible'
	dw	'type of variable is not array'
	dw	'index type is not compatible with declaration'
	dw	'type of variable is not record'
	dw	'type of variable must be file or pointer'
	dw	'illegal parameter substitution'
	dw	'illegal type of loop control variable'
	dw	'illegal type of expression'
	dw	'type conflict'	70
	dw	'assignment of files not allowed'
	dw	'label type incompatible with selecting expression'
	dw	'subrange bounds must be scalar'
	dw	'74'
	dw	'assignment to standard function is not allowed'
	dw	'assignment to formal function is not allowed'
	dw	'no such field in this record'
	dw	'actual parameter must be a variable'
	dw	'control var must be declared at this level'
	dw	'multidefined case label' 80
	dw	'only extern, forward, ProDOS or tool allowed in uses'
	dw	'missing corresponding variant declaration'
	dw	'''..'' expected'
	dw	'previous declaration was not forward'
	dw	'again forward declared'
	dw	'parameter size must be constant'
	dw	'multidefined label'
	dw	'multideclared label'
	dw	'undeclared label'
	dw	'error in base set'	90
	dw	'missing ''input'' in program heading'
	dw	'missing ''output'' in program heading'
	dw	'assignment to function identifier not allowed here'
	dw	'multidefined record variant'
	dw	'cannot use as formal parameter'
	dw	'no assignment to function found'
	dw	'cannot modify control variable'
	dw	'wrong number of selectors'
	dw	'illegal goto'
	dw	'misplaced directive'	100
	dw	'extern allowed at program level only'
	dw	'label space exhausted'
	dw	'digit expected'
	dw	'string constant must not exceed source line'
	dw	'integer constant exceeds range'
	dw	'zero string not allowed'
	dw	'too many nested scopes of identifiers'
	dw	'too many nested procedures and/or functions'
	dw	'further errors supressed'
	dw	'element expression out of range' 110
	dw	'implementation restriction'
	dw	'not iso standard'
	dw	'compiler error'
	dw	'114'
	dw	'uses allowed at program level only'
	dw	'error in uses'
	dw	'file cannot contain another file'
	dw	'''implementation'' expected'
	dw	'''interface'' expected'
	dw	'body must appear in implementation part' 120
	dw	'casted expression must be scalar or pointer'
	dw	'use memory model 1 for memory blocks larger than 64K'
	dw	'objects cannot have a variant part'
	dw	'undeclared method'
	dw	'not a known object'
	dw	'methods must be declared at the program level'
	dw	'objects must be declared as a named type'
	dw	'object expected'
	dw	'type of variable must be object'
	dw	'there is no method to inherit' 130
	dw	'string expected'
	dw	'implementation restriction: string space exhausted'
	dw	'Unexpected end of file'
	end    

****************************************************************
*
*  Match - Insure that the next symbol is the one requested
*
*  Inputs:
*	sym - symbol to match
*	ern - number of error of there is no match
*
****************************************************************
*
Match	start
	using GetCom

	sub	(2:sym,2:ern),0
	lda	sym	if sy = sym then
	cmp	SY
	bne	lb1
	jsl	InSymbol	  insymbol
	bra	lb2	else
lb1	lda	ern	  error(ern);
	pha
	jsl	Error
lb2	ret
	end

****************************************************************
*
*  NextCH - Get Next Character
*
*  Inputs:
*	EOFL - at end of file?
*	eol - at end of line?
*	fHeadGS - head of copied files list
*	chCnt - number of character read from the line so far
*
*  Outputs:
*	EOFL - set if at end of file
*	eol - set if at end of line
*	chCnt - updated
*	CH - next character to process
*
****************************************************************
*
NextCH	private
	using GetCom
cPtr	equ	1	local copy of chPtr
fPtr	equ	5	local copy of fHeadGS

	sub	,8

	move4	chPtr,cPtr	cPtr := chPtr;
	lda	EOFL	if not eofl then begin
	beq	ef1
	lda	#' '
	sta	CH
	brl	ret

ef1	lda	eol	  if eol then begin
	jeq	lb8
lab1	clc		1:  if eof(prd) then begin
	lda	chCnt
	adc	cPtr
	tax
	lda	cPtr+2
	adc	#0
	cmp	chEndPtr+2
	bne	ef2
	cpx	chEndPtr
ef2	jlt	lb5
lb0	jsl	PurgeSource	      <purge the file>;
	lda	fHeadGS	      if fHeadGS = nil then begin
	ora	fHeadGS+2
	bne	lb1
	lda	eofDisable		if not eofDisable then begin
	bne	lb0a
	ph2	#133		  <flag the error>;
	jsl	Error
	inc	NUMERR		  numerr := numerr+1
lb0a	anop			  end;
	la	EOFL,true		eofl := true;
	stz	TEST		test := false;
	lda	#' '		ch := ' ';
	sta	CH
	brl	ret	      else
lb1	add4	fHeadGS,#4,cPtr		with fHeadGS^ do begin
	short M		  fName := name;
	ldy	#maxPath+4-1
lb2	lda	[cPtr],Y
	sta	fNameGS,Y
	dbpl	Y,lb2
	long	M
	jsl	OpenGS		  <open the file>;
	move4	fHeadGS,fPtr
	ldy	#maxPath+4+4		  seek(prd,pos);
	clc
	lda	[fPtr],Y
	adc	filePtr
	sta	cPtr
	iny
	iny
	lda	[fPtr],Y
	adc	filePtr+2
	sta	cPtr+2
	stz	chCnt
	ldy	#maxPath+4+4+4		  <push uses flag>
	lda	[fPtr],Y
	pha
	ldy	#maxPath+4+4+4+2		  lineCount := fHeadGS^.lineCount;
	lda	[fPtr],Y
	sta	lineCount
	ldy	#2		  fHeadGS := fHeadGS^.next;
	lda	[fPtr],Y
	sta	fHeadGS+2
	lda	[fPtr]
	sta	fHeadGS
	dispose fPtr		  dispose(fPtr);
	pla			  {if this is a uses, mark it}
	beq	lb3
	lda	#' '
	sta	CH
	lda	#true
	sta	endOfUses
	stz	eol
	bra	ret
lb3	brl	lab1		  goto 1;
;				  end;
;			      end
lb5	anop		    else begin
	move4	cPtr,chPtr	      EndOfLine;
	jsl	EndOfLine
	move4	chPtr,cPtr
lb5a	ldy	#0	      while (line[chCnt+1]<>return) and
	short M		(charTp[line[chCnt+1]]=chSpace) do
lb6	lda	[cPtr],Y	      chCnt := chCnt+1;
	cmp	#' '
	beq	lb6A
	cmp	#tab
	beq	lb6A
	cmp	#$CA
	bne	lb6B
	lda	#' '
lb6A	iny
	bra	lb6
lb6B	long	M
	tya
	sta	chCnt
lb7	anop		    end;
lb8	anop		  end;
	lda	#0
	short M
	ldy	chCnt	eol := line[chCnt] = return;
	tax
	lda	[cPtr],Y
	cmp	#return
	bne	lb9
	inx
	lda	#' '
lb9	stx	eol
	tax		ch := line[chCnt];
	lda	upperCase,X	if (ch >= 'a') and (ch <= 'z') then
	sta	CH	  ch := chr(ord(ch)-ord('a')+ord('A');
	stz	CH+1
	long	M
	inc	chCnt	chCnt := chCnt+1;
lb11	anop
	anop		end;

ret	move4	cPtr,chPtr
	ret
	end

****************************************************************
*
*  SaveDigits - Save a sequence of digits
*
*  Inputs:
*	X - disp in digit
*	Y - disp in input line
*
*  Outputs:
*	digit - contains any digits read
*
*  Notes:
*	Entry at SaveDigits2 skips the check that insures
*	some digits exist.
*
*	Assumes cPtr has been set up in a valid DP area at 1
*
****************************************************************
*
SaveDigits private
	using GetCom
cPtr	equ	1	copy of chPtr

	lda	[cPtr],Y	if charTp[ch] <> number then
	and	#$00FF
	cmp	#'0'
	blt	lb1
	cmp	#'9'+1
	blt	SaveDigits2
lb1	phx		  error(103)
	phy
	listerror #103
	ply
	plx
	rts

SaveDigits2 entry	else
	short M
	anop		  repeat
	lda	[cPtr],Y	    savedigit
lb2	sta	digit,X
	iny
	inx
	lda	[cPtr],Y	  until charTp[ch] <> number;
	cmp	#'0'
	blt	lb3
	cmp	#'9'+1
	blt	lb2
lb3	long	M
	rts		  end;
	end

****************************************************************
*
*  SaveString - does the work for InSymbol and UsesInsymbol
*
*  Notes: Assumes that a constant record is a word followed by
*	a p-string.
*
****************************************************************
*
SaveString private
	using GetCom

	aif	constant_sval=2,.OK
	mnote	'constant_sval assumed to be 2',16
.OK

lvp	equ	1	new constant record pointer

	sub	,4

	lda	LGTH	if lgth = 1 then
	dec	a
	bne	qt8
	lda	lString+1	  val.ival := ord(lString[1])
	and	#$00FF
	sta	VAL+valu_ival
	bra	end	else begin

qt8	lda	lgth	  lvp := pointer(Malloc(lgth+5)));
	clc		  {extra 2 bytes leave room for
	adc	#5	   possible expansion in LoadString}
	pha
	jsl	Malloc
	sta	lvp
	stx	lvp+2
	lda	#strg	  lvp^.cclass:=strg;
	sta	[lvp]
	lda	lgth	  lvp^.sval := lString;
	and	#$00FF
	tax
	ldy	#constant_sval
	short	M
	sta	[lvp],Y
	cpx	#0
	beq	lb2
lb1	iny
	lda	lString-constant_sval,Y
	sta	[lvp],Y
	dex
	bne	lb1
lb2	long	M
	move4 lvp,VAL+valu_valp	  val.valp := lvp;
!			  end; {else}
end	ret
	end

****************************************************************
*
*  Scanner_Init - Initialize the scanner
*
****************************************************************
*
Scanner_Init start
	using GetCom
;
;  Initialize volitile variables
;
	stz	title+1	delete any old title
	stz	intPrefixGS+2	wipe out old interface prefix
	stz	chCnt	no characters read from current line
	lda	#true	at end of line
	sta	eol
	stz	LIST	listing defaults to off
	stz	doingOption	not compiling an option (directive)
	stz	fHeadGS	fHeadGS := nil
	stz	fHeadGS+2
	stz	lCnt	no lines on printed page
	stz	langNum	language number not yet determined
	stz	eofDisable	enable eofl error check
	stz	endOfUses	not at end of a uses
	stz	didKeep	no $keep found, yet
;
;  Find out how long a page is.
;
	la	pageSize,60	assume a size of 60
	ReadVariableGS rvRec	read the actual size, if any
	bcs	pl1
	lda	variable+2	if there is a variable then
	beq	pl1
	ph2	#0	  find its value
	ph4	#variable+2
	ph2	variable+2
	ph2	#0
	_dec2int
	pla
	sta	pageSize	  save the value
pl1	anop		endif
;
;  Set printer to true if output has been redirected.
;
	direction dr_dcb
	lda	direction
	sta	printer
;
;  Get the inputs and open the initial file.
;
	jsl	InitFile	get shell interface stuff
	jsl	OpenGS	open the file
;
;  Set up the partial compile name list.
;
	jsl	GetPartialNames
;
;  Read the first character.
;
	jsl	NextCh
	rtl
;
;  Local data
;
rvRec	dc	i'3'	ReadVariableGS record
	dc	a4'name,variable'
	ds	2

name	dosw	PrinterLines	name of the printer line variable
variable dc	i'9,0',c'     '	value of PrinterLines

dr_dcb	anop		direction dcb
	dc	i'1'	find direction of standard out
direction ds	2	direction of standard out
	end

****************************************************************
*
*  UsesInSymbol - returns a symbol from an interface file
*
*  Inputs:
*	tInSymbol - bytes to restore InSymbol with after the
*		file is processed
*	usesLength - bytes remaining in file
*	usesPtr - pointer to next byte in file
*
*  Outputs:
*	sy - symbol
*	op - operator
*	id - identifier name
*	val - constant value
*
****************************************************************
*
UsesInSymbol start
	using GetCom
uPtr	equ	1	local copy of usesPtr
lvp	equ	5	constant pointer

	sub	,8

	jsl	Spin	Spin;
	move4	usesPtr,uPtr	uPtr := usesPtr;
	lda	[uPtr]	SY := uPtr^;
	and	#$00FF
	sta	SY
	inc4	uPtr	++uPtr;
	dec4	usesLength	--usesLength;
	stz	OP	op := noop;
	lda	SY	if sy in [addop,mulop,relop] then begin
	cmp	#addop
	beq	la1
	cmp	#mulop
	beq	la1
	cmp	#relop
	bne	la2
la1	lda	[uPtr]	  OP := uPtr^;
	and	#$00FF
	sta	OP
	inc4	uPtr	  ++uPtr;
	dec4	usesLength	  --usesLength;
la2	anop		  end;
	lda	SY	if sy = ident then begin
	cmp	#ident
	bne	lb2
	ldy	#0	  y := 0;
lb1	anop		  while X >= 0 do begin
	lda	[uPtr]	    id[y+1] := uPtr^;
	and	#$00FF
	cmp	#' '
	beq	lb1a
	short	M
	sta	id+1,Y
	long	M
	iny		    y := y+1;
	inc4	uPtr	    uPtr++;
	dec4	usesLength	    usesLength--;
	bpl	lb1	    end
lb1a	short	I	  id[0] := chr(y);
	sty	id
	long	I
	inc4	uPtr	  uPtr++;
	dec4	usesLength	  usesLength--;
	brl	lb7	  end
lb2	cmp	#intconst	else if sy = intconst then begin
	bne	lb3
	lda	[uPtr]	  val.ival := uPtr^;
	sta	VAL+valu_ival
	add4	uPtr,#2	  uPtr += 2;
	sub4	usesLength,#2	  usesLength -= 2;
	brl	lb7	  end
lb3	cmp	#longintconst	else if sy = longintconst then begin
	bne	lb4
	ph2	#constantSize_longC	  lvp := pointer(Malloc(sizeof(constantRec)));
	jsl	Malloc
	sta	lvp
	stx	lvp+2
	lda	#long	  lvp^.cclass := long;
	sta	[lvp]
	ldy	#2	  lvp^.lval := uPtr^;
	lda	[uPtr],Y
	ldy	#constant_lval+2
	sta	[lvp],Y
	dey
	dey
	lda	[uPtr]
	sta	[lvp],Y
	move4 lvp,VAL+valu_valp	  val.valp := lvp;
	add4	uPtr,#4	  uPtr += 4;
	sub4	usesLength,#4	  usesLength -= 4;
	brl	lb7	  end
lb4	cmp	#realconst	else if sy = realconst then begin
	bne	lb5
	ph2	#constantSize_reel	  lvp := pointer(Malloc(sizeof(constantRec)));
	jsl	Malloc
	sta	lvp
	stx	lvp+2
	lda	#reel	  lcp^.cclass := reel;
	sta	[lvp]
	move4 lvp,VAL+valu_valp	  val.valp := lvp;
	add4	lvp,#valu_valp	  lvp^.rval := uPtr^;
	ldy	#2
	lda	[uPtr]
	sta	[lvp]
	lda	[uPtr],Y
	sta	[lvp],Y
	iny
	iny
	lda	[uPtr],Y
	sta	[lvp],Y
	iny
	iny
	lda	[uPtr],Y
	sta	[lvp],Y
	add4	uPtr,#8	  uPtr += 8;
	sub4	usesLength,#8	  usesLength -= 8;
	bra	lb7	  end
lb5	cmp	#stringconst	else if sy = stringconst then begin
	bne	lb7
	lda	[uPtr]	  lgth := uPtr^;
	and	#$00FF
	sta	lgth
	tay
	ldx	#0	  for x := 1 to lgth do begin
lb6	lda	[uPtr]	    lString[x] := uPtr^;
	and	#$00FF
	sta	lString,X
	inc4	uPtr	    uPtr++;
	dec4	usesLength	    usesLength--;
	inx		    end;
	dey
	bpl	lb6
	jsl	SaveString	  if lgth = 1 then
;			    val.ival := lString[1]
;			  else begin
;			    new(lvp,strg);
;			    lvp^.cclass := strg;
;			    lvp^.slgth := lgth;
;			    for i := 1 to lgth do
;			      lvp^.sval[i] := lString[i];
;			    val.valp := lvp;
;			    end;
;			  end;
lb7	lda	usesLength+2	if usesLength <= 0 then
	bmi	lb8
	ora	usesLength
	bne	lb9
lb8	lda	tInSymbol	  <fix InSymbol>
	sta	InSymbol
	lda	tInSymbol+1
	sta	InSymbol+1
	lla	ffPathname,usesFileNameGS  purge the uses file
	FastFileGS ffDCB
lb9	anop		  end;

	move4	uPtr,usesPtr	usesPtr := uPtr;
	ret

ffDCB	anop
	dc	i'5'	pCount
	dc	i'7'	action
	dc	i'0'	index
	dc	i'$C000'	flags
	dc	a4'0'	fileHandle
ffPathName ds	4	pathName
	end
