	mcopy	cgc.macros
****************************************************************
*
*  CnvSX - Convert floating point to SANE extended
*
*  Inputs:
*        rec - pointer to a record
*
****************************************************************
*
CnvSX    start
rec      equ   4                        record containing values
rec_real equ   0                        disp to real value
rec_ext  equ   8                        disp to extended (SANE) value

         tsc                            set up DP
         phd
         tcd
         ph4   rec                      push addr of real number
         clc                            push addr of SANE number
         lda   rec
         adc   #rec_ext
         tax
         lda   rec+2
         adc   #0
         pha
         phx
         fd2x                           convert TOS to extended
         move4 0,4                      return
         pld
         pla
         pla
         rtl
         end
