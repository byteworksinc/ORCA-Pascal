	mcopy pcommon.macros
****************************************************************
*
*  MMCom - common data area for the memory manager
*
****************************************************************
*
MMCom	privdata
;
;  constants
;
maxBuffSize equ 16*1024	size of a buffer
;
;  data
;
buffSize ds	2	remaining bytes in the current buffer
currBuffHand ds 4	handle of current buffer
currBuffStart ds 4	pointer to start of current buffer
nextPtr	ds	4	pointer to next byte in current buffer
	end

****************************************************************
*
*  BRK - break into the debugger
*
*  Inputs:
*	4,S - break code
*
****************************************************************
*
BRK	start

	phb
	plx
	ply
	pla
	and	#$00FF
	xba
	sta	lb1
	phy
	phx
	plb
lb1	brk	$00
	rtl
	end

****************************************************************
*
*  Calloc - allocate and clear a new memory area
*
*  Inputs:
*	size - # bytes to allocate
*
*  Outputs:
*	X-A - pointer to memory
*
*  Notes:  Assumes size > 2
*
****************************************************************
*
Calloc	start
ptr	equ	1	pointer to memory

	sub	(2:size),4

	ph2	size	allocate the memory
	jsl	Malloc
	sta	ptr
	stx	ptr+2

	ldy	size	if there are an odd number of bytes then
	tya
	lsr	A
	bcc	lb1
	dey		  clear the last byte
	short	M
	lda	#0
	sta	[ptr],Y
	long	M
lb1	lda	#0	clear the memory, one word at a time
lb2	dey
	dey
	sta	[ptr],Y
	bne	lb2

	ret	4:ptr
	end

****************************************************************
*
*  CompNames - Compare two names
*
*  Inputs:
*	name1, name2 - addresses of the two strings to compare
*
*  Outputs:
*	int - 0 if equal, -1 if name1<name2, 1 if name1>name2
*
****************************************************************
*
CompNames start
result	equ	1

	sub	(4:name1,4:name2),2

	short	I,M  
	lda	[name1]	get the length of the shorter string
	cmp	[name2]
	blt	lb1
	lda	[name2]
lb1	tax
	beq	lb2a
	ldy	#1	compare the existing characters
lb2	lda	[name1],Y
	cmp	[name2],Y
	bne	lb4
	iny
	dex
	bne	lb2
lb2a	lda	[name1]	characters match -- compare the lengths
	cmp	[name2]
	bne	lb4

lb3	long	I,M
	lda	#0	strings match
	bra	lb6

lb4	long	I,M	strings don't match -- set condition code
	bge	lb5
	lda	#-1
	bra	lb6
lb5	lda	#1
lb6	sta	result

	ret	2:result
	end

****************************************************************
*
*  KeyPress - Has a key been presed?
*
*  If a key has not been pressed, this function returns
*  false.  If a key has been pressed, it clears the key
*  strobe.  If the key was an open-apple ., a terminal exit
*  is performed; otherwise, the function returns true.
*
****************************************************************
*
KeyPress start

	KeyPressGS kpRec
	lda	kpAvailable
	beq	rts
	ReadKeyGS rkRec
	lda	rkKey
	cmp	#'.'
	bne	lb1
	lda	rkModifiers
	and	#$0100
	beq	lb1
         ph2   #0
         ph4   #0
         jsl   TermError

lb1	lda	#1
rts	rtl

kpRec	dc	i'3'
kpKey	ds	2
kpModifiers ds	2
kpAvailable ds	2
                  
rkRec	dc	i'2'
rkKey	ds	2
rkModifiers ds	2
         end

****************************************************************
*
*  Mark - mark the stack
*
*  Inputs:
*	ptr - location to place mark
*
****************************************************************
*
Mark	start
	using MMCom

	sub	(4:ptr),0

	ldy	#2	ptr^ := nextPtr
	lda	nextPtr
	sta	[ptr]
	lda	nextPtr+2
	sta	[ptr],Y

	ret
	end

****************************************************************
*
*  MMInit - initialize the memory manager
*
****************************************************************
*
MMInit	start
	using MMCom

	stz	buffSize	no bytes in current buffer
	stz	currBuffHand	nil handle
	stz	currBuffHand+2
	rtl
	end

****************************************************************
*
*  Malloc - allocate a new memory area
*
*  Inputs:
*	size - # bytes to allocate
*
*  Outputs:
*	X-A - pointer to memory
*
****************************************************************
*
Malloc	start
	using MMCom
ptr	equ	1	pointer to memory
handle	equ	5	new memory handle
lptr	equ	9	work pointer

	sub	(2:size),12

	lda	buffSize	if buffSize < size then begin
	cmp	size
	bge	lb2
	ph4	#0	  handle := AppleNew(maxBuffSize);
	ph4	#maxBuffSize
	ph2	>~User_ID
	ph2	#$C010
	ph4	#0
	_NewHandle
	bcc	lb1
	ph2	#3
	ph4	#0
	jsl	TermError

lb1	pl4	handle
	ldy	#2	  lptr := handle^;
	lda	[handle],Y	  currBuffStart := handle^;
	sta	lptr+2
	sta	currBuffStart+2
	lda	[handle]
	sta	lptr
	sta	currBuffStart
	lda	currBuffHand+2	  lptr[0] := currBuffHand;
	sta	[lptr],Y
	lda	currBuffHand
	sta	[lptr]
	move4 handle,currBuffHand	  currBuffHand := handle;
	add4	lptr,#4,nextPtr	  nextPtr := lptr+4;
	lda	#maxBuffSize-4	  buffSize := maxBuffSize-4;
	sta	buffSize
lb2	anop		  end;
	clc		ptr := nextPtr;
	lda	nextPtr	nextPtr := nextPtr+size;
	sta	ptr
	adc	size
	sta	nextPtr
	lda	nextPtr+2
	sta	ptr+2
	adc	#0
	sta	nextPtr+2
	sub2	buffSize,size	buffSize := buffSize-size;

	ret	4:ptr
	end

****************************************************************
*
*  ~Move - move some bytes
*
*  Inputs:
*        source - pointer to source bytes
*        dest - pointer to destination bytes
*        len - number of bytes to move
*
*  Notes:
*        Also used to copy strings via CopyString entry point
*
****************************************************************
*
~Move    start
CopyString entry

         sub	(4:dest,4:source,2:len),0
	
         lda   len                      move one byte if the move length is odd
         lsr   a
         bcc   lb1
         short M
         lda   [source]
         sta   [dest]
         long  M
         inc4  source
         inc4  dest
         dec   len
lb1      ldy   len                      move the bytes
         beq   lb4
         dey
         dey
         beq   lb3
lb2      lda   [source],Y
         sta   [dest],Y
         dey
         dey
         bne   lb2
lb3      lda   [source]
         sta   [dest]

lb4      ret
         end

****************************************************************
*
*  Release - release previously marked memory
*
*  Inputs:
*	ptr - pointer supplied by Mark
*
****************************************************************
*
Release	start
	using MMCom
lptr	equ	1	local work pointer
handle	equ	5	work handle

	sub	(4:ptr),8

lb1	lda	ptr+2	while not ((ptr >= currBuffStart)
	cmp	currBuffStart+2	  and (ptr <= nextPtr)) do begin
	bne	lb2
	lda	ptr
	cmp	currBuffStart
lb2	blt	lb4
	lda	ptr+2
	cmp	nextPtr+2
	bne	lb3
	lda	ptr
	cmp	nextPtr
lb3	ble	lb5
lb4	move4 currBuffStart,lptr	  handle := currBuffStart[0];
	ldy	#2
	lda	[lptr]
	sta	handle
	lda	[lptr],Y
	sta	handle+2
	ph4	currBuffHand	  AppleDispose(currBuffHand);
	_DisposeHandle
	move4 handle,currBuffHand	  currBuffHand := handle;
	ldy	#2	  currBuffStart := handle^;
	lda	[handle]
	sta	currBuffStart
	lda	[handle],Y
	sta	currBuffStart+2
!			  nextPtr := currBuffStart+maxBuffSize;
	add4	currBuffStart,#maxBuffSize,nextPtr
	stz	buffSize	  buffSize := 0;
	bra	lb1	  end;
lb5	sec		buffSize := buffSize-ptr+nextPtr;
	lda	nextPtr
	sbc	ptr
	clc
	adc	buffSize
	sta	buffSize
	move4 ptr,nextPtr	nextPtr := ptr;

	ret
	end

****************************************************************
*
*  StdNames - Initialize the standard names array
*
*  Outputs:
*	NA - set to addresses of appropriate strings
*
****************************************************************
*
StdNames start
ptrSize	equ	4	size of a pointer
maxNA	equ	77	# elements in NA array

	move	lNA,NA,#ptrSize*maxNA
	rtl


lNA	dc	a4'l01,l02,l03,l04,l05,l06,l07,l08,l09,l10'
	dc	a4'l11,l12,l13,l14,l15,l16,l17,l18,l19,l20'
	dc	a4'l21,l22,l23,l24,l25,l26,l27,l28,l29,l30'
	dc	a4'l31,l32,l33,l34,l35,l36,l37,l38,l39,l40'
	dc	a4'l41,l42,l43,l44,l45,l46,l47,l48,l49,l50'
	dc	a4'l51,l52,l53,l54,l55,l56,l57,l58,l59,l60'
	dc	a4'l61,l62,l63,l64,l65,l66,l67,l68,l69,l70'
	dc	a4'l71,l72,l73,l74,l75,l76,l77'

l01	dw	'FALSE'
l02	dw	'TRUE'
l03	dw	'INPUT'
l04	dw	'OUTPUT'
l05	dw	'GET'
l06	dw	'PUT'
l07	dw	'OPEN'
l08	dw	'CLOSE'
l09	dw	'RESET'
l10	dw	'REWRITE'
l11	dw	'READ'
l12	dw	'WRITE'
l13	dw	'PACK'
l14	dw	'UNPACK'
l15	dw	'NEW'
l16	dw	'@B1'
l17	dw	'READLN'
l18	dw	'WRITELN'
l19	dw	'PAGE'
l20	dw	'@B2'
l21	dw	'DISPOSE'
l22	dw	'@B3'
l23	dw	'SEEK'
l24	dw	'ABS'
l25	dw	'SQR'
l26	dw	'TRUNC'
l27	dw	'ROUND'
l28	dw	'ODD'
l29	dw	'ORD'
l30	dw	'CHR'
l31	dw	'PRED'
l32	dw	'SUCC'
l33	dw	'EOF'
l34	dw	'EOLN'
l35	dw	'SIN'
l36	dw	'COS'
l37	dw	'EXP'
l38	dw	'SQRT'
l39	dw	'LN'
l40	dw	'ARCTAN'
l41	dw	'HALT'
l42	dw	'SEED'
l43	dw	'DELETE'
l44	dw	'INSERT'
l45	dw	'SHELLID'
l46	dw	'COMMANDLINE'
l47	dw	'STARTGRAPH'
l48	dw	'STARTDESK'
l49	dw	'ENDGRAPH'
l50	dw	'ENDDESK'
l51	dw	'ORD4'
l52	dw	'CNVDS'
l53	dw	'CNVIS'
l54	dw	'CNVSR'
l55	dw	'CNVSI'
l56	dw	'CNVSL'
l57	dw	'RANDOM'
l58	dw	'RANDOMINTEGER'
l59	dw	'RANDOMLONGINT'
l60	dw	'CONCAT'
l61	dw	'COPY'
l62	dw	'LENGTH'
l63	dw	'POS'
l64	dw	'RANDOMDOUBLE'
l65	dw	'CNVRS'
l66	dw	'CNVSD'
l67	dw	'USERID'
l68	dw	'POINTER'
l69	dw	'TAN'
l70	dw	'ARCCOS'
l71	dw	'ARCSIN'
l72	dw	'ARCTAN2'
l73	dw	'TOOLERROR'
l74	dw	'SIZEOF'
l75	dw	'TRUNC4'
l76	dw	'ROUND4'
l77	dw	'MEMBER'
	end

****************************************************************
*
*  WaitForKeyPress - If necessary, wait for a keypress
*
*  This routine is called after reporting non-terminal errors.
*  If the user has flagged all errors as terminal (+T), a
*  terminal exit is made.  If the user has not, but has requested
*  that the compiler wait for a keypress after printeing an error
*  (+W), it waits for a keypress.
*
*  Inputs:
*	r0 - long address of the error message
*	wait - wait for a keypress?
*	allTerm - are all errors terminal?
*
****************************************************************
*
WaitForKeyPress start
	using GetCom

	lda	allTerm	if allTerm then
	beq	lb1
	ph2	#0	  do a terminal error exit;
	ph4	#0
	jsl	TermError
lb1	lda	wait	if wait then begin
	beq	lb3
	jsl	DrawHourglass	  draw the wait symbol
lb1a	jsl	KeyPress	  get a keypress
	tay
	beq	lb1a
	jsl	ClearHourglass	  clear the wait symbol
lb3	rtl
	end
