	mcopy	objout.macros
****************************************************************
*
*  Code Generator Output Routines
*
*  This module provides fast object module output for the code
*  generator.  Currently, the maximum size for a single object
*  segment is 64K.
*
*  By Mike Westerfield
*
*  Copyright July 1987
*  Byte Works, Inc.
*
****************************************************************
*
ObjData  privdata                       place with ~globals
;
;  Constants
;
!			NOTE: tokenBuffSize also defined in cgi.pas
tokenBuffSize equ 4095                  size of the token buffer
         end

****************************************************************
*
*  COut - write a code byte to the object file
*
*  Inputs:
*        b - byte to write (on stack)
*
****************************************************************
*
COut     start

         phb                            OutByte(b);
         pla
         ply
         plx
         phy
         pha
         plb
         jsr   OutByte
         inc   blkcnt                   blkcnt := blkcnt+1;
         inc4  pc                       pc := pc+1;
         rtl
         end

****************************************************************
*
*  CnOut - write a byte to the constant buffer
*
*  Inputs:
*        i - byte to write
*
****************************************************************
*
CnOut    start
maxCBuffLen equ 191                     max index into the constant buffer

         lda   cBuffLen                 if cBuffLen = maxCBuffLen then
         cmp   #maxCBuffLen
         bne   lb1
         jsl   Purge                       Purge;
lb1      phb                            cBuff[cBuffLen] := i;
         plx
         ply
         pla
         phy
         phx
         plb
         ldx   cBuffLen
         short M
         sta   cBuff,X
         long  M
         inc   cBuffLen                 cBuffLen := cBuffLen+1;
         rtl
         end

****************************************************************
*
*  CnOut2 - write a word to the constant buffer
*
*  Inputs:
*        i - word to write
*
****************************************************************
*
CnOut2   start
maxCBuffLen equ 191                     max index into the constant buffer

         lda   cBuffLen                 if cBuffLen+1 >= maxCBuffLen then
         inc   A
         cmp   #maxCBuffLen
         blt   lb1
         jsl   Purge                       Purge;
lb1      phb                            cBuff[cBuffLen] := i;
         plx
         ply
         pla
         phy
         phx
         plb
         ldx   cBuffLen
         sta   cBuff,X
         inx                            cBuffLen := cBuffLen+2;
         inx
         stx   cBuffLen
         rtl
         end

****************************************************************
*
*  GrowHandle - Grow the area occupied by a handle
*
*  Inputs:
*        size - new size for the buffer
*        haddr - address of the handle
*
*  Notes:
*        This subroutine must only be used if the handle is
*        grown.  It will fail if you try to shrink the handle.
*
****************************************************************
*
GrowHandle start
shandle  equ   1                        source handle
dhandle  equ   5                        destination handle
sptr     equ   9                        source pointer
dptr     equ   13                       destination pointer

         sub	(4:size,4:haddr),16

         ldy   #2                       recover the source handle
         lda   [haddr]
         sta   shandle
         lda   [haddr],Y
         sta   shandle+2
         ph4   shandle                  unlock the handle
         _HUnlock
         pha                            allocate a new area
         pha
         ph4   size
         ph2   >~User_ID
         ph2   #$8000
         ph4   #0
         _NewHandle
         bcc   lb0
         ph2   #3
	ph4	#0
         jsl   TermError
	
lb0      pl4   dhandle
         ph4   shandle                  lock the source handle
         _HLock
         ldy   #2                       dereference the dest handle
         lda   [dhandle]
         sta   dptr
         lda   [dhandle],Y
         sta   dptr+2
         lda   [shandle]                dereference the source handle
         sta   sptr
         lda   [shandle],Y
         sta   sptr+2
         pha                            get the size of the source handle
         pha
         ph4   shandle
         _GetHandleSize
         pl2   size
         plx                            move 64K chunks
         beq   lb2
         ldy   #0
lb1      lda   [sptr],Y
         sta   [dptr],Y
         dey
         dey
         bne   lb1
         inc   sptr+2
         inc   dptr+2
         dex
         bne   lb1
lb2      lda   size                     move the remaining bytes
         beq   lb5
         lsr   a
         bcc   lb2a
         short M
         lda   [sptr]
         sta   [dptr]
         long  M
         inc4  sptr
         inc4  dptr
         dec   size
         beq   lb5
lb2a     ldy   size
         bra   lb4
lb3      lda   [sptr],Y
         sta   [dptr],Y
lb4      dey
         dey
         bne   lb3
         lda   [sptr]
         sta   [dptr]
lb5      ph4   shandle                  dispose of the source handle
         _DisposeHandle
         ldy   #2                       save the new handle
         lda   dhandle
         sta   [haddr]
         lda   dhandle+2
         sta   [haddr],Y

         ret
         end

****************************************************************
*
*  Out - write a byte to the output file
*
*  Inputs:
*        b - byte to write (on stack)
*
****************************************************************
*
Out      start

         phb                            OutByte(b);
         pla
         ply
         plx
         phy
         pha
         plb
         jsr   OutByte
         inc   blkcnt                   blkcnt := blkcnt+1;
         rtl
         end

****************************************************************
*
*  Out2 - write a word to the output file
*
*  Inputs:
*        w - word to write (on stack)
*
****************************************************************
*
Out2     start

         phb                            OutWord(w);
         pla
         ply
         plx
         phy
         pha
         plb
         jsr   OutWord
         inc   blkcnt                   blkcnt := blkcnt+2;
         inc   blkcnt
         rtl
         end

****************************************************************
*
*  OutByte - write a byte to the object file
*
*  Inputs:
*        X - byte to write
*
****************************************************************
*
OutByte  private

         lda   objLen                   if objLen+segDisp = buffSize then
         clc
         adc   segDisp
         bcc   lb2
	phx		   PurgeObjBuffer;
	jsl	PurgeObjBuffer
	plx
	lda	objLen	   check for segment overflow
	clc
	adc	segDisp
	bcs	lb2a
lb2      ph4   objPtr                   p := pointer(ord4(objPtr)+segDisp);
         tsc                            p^ := b;
         phd
         tcd
         ldy   segDisp
         short M
         txa
         sta   [1],Y
         long  M
         inc   segDisp                  segDisp := segDisp+1;

	pld
         tsc
         clc
         adc   #4
         tcs
         rts

lb2a     lda   #$8000	handle a segment overflow
         sta   segDisp
         ph2   #112
         jsl   Error
	rts
         end

****************************************************************
*
*  OutWord - write a word to the object file
*
*  Inputs:
*        X - word to write
*
****************************************************************
*
OutWord  private

         lda   objLen                   if objLen+segDisp+1 = buffSize then
         sec
         adc   segDisp
         bcc   lb2
	phx		   PurgeObjBuffer;
	jsl	PurgeObjBuffer
	plx
	lda	objLen	   check for segment overflow
	sec
	adc	segDisp
	bcs	lb3
lb2      ph4   objPtr                   p := pointer(ord4(objPtr)+segDisp);
         tsc                            p^ := b;
         phd
         tcd
         ldy   segDisp
         txa
         sta   [1],Y
         iny                            segDisp := segDisp+2;
         iny
	sty   segDisp                  save new segDisp

         pld
         tsc
         clc
         adc   #4
         tcs
         rts

lb3      ph2   #112                     flag segment overflow error
         jsl   Error
         lda   #$8000
	sta	segDisp
	rts
         end

****************************************************************
*
*  TokenOut - write a byte to the interface file
*
*  Inputs:
*        4,s - byte to write (in a word)
*
****************************************************************
*
TokenOut start
         using ObjData
ptr      equ   1                        pointer to token buffer

         sub	(2:byte),4

         lda   codeGeneration           quit if no keep
         jeq   lb2
         ldy   tokenDisp                if at end of buffer then
         cpy   #tokenBuffSize
         bne   lb1
         add4  tokenLen,#tokenBuffSize    update tokenLen
         clc                              expand the token buffer
         lda   tokenLen
         adc   #tokenBuffSize+1
         tax
         lda   tokenLen+2
         adc   #0
         pha
         phx
         ph4   #tokenHandle
         jsl   GrowHandle
         move4 tokenHandle,ptr            dereference the pointer
         clc
         lda   [ptr]
         adc   tokenLen
         sta   tokenPtr
         ldy   #2
         lda   [ptr],Y
         adc   tokenLen+2
         sta   tokenPtr+2
         stz   tokenDisp                  set the disp back to 0
lb1      anop                           endif
         move4 tokenPtr,ptr             set the buffer pointer
         ldy   tokenDisp
         lda   byte                     save the byte
         sta   [ptr],Y
         inc   tokenDisp                inc disp in buffer
lb2      ret
         end
