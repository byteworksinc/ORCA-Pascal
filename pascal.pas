{$optimize -1}
{$stacksize $4000}
{------------------------------------------------------------}
{							     }
{  ORCA/Pascal 2.2					     }
{							     }
{  A native code compiler for the Apple IIGS.		     }
{							     }
{  By Mike Westerfield					     }
{							     }
{  Copyright March 1988					     }
{  By the Byte Works, Inc.				     }
{							     }
{------------------------------------------------------------}
{							     }
{  Version 2.2 prepared in March, 1996		     	     }
{  Version 2.1 prepared in July, 1994		     	     }
{  Version 2.0.1 prepared in June, 1993		     	     }
{  Version 2.0.0 prepared in March, 1993		     }
{  Version 1.4.2 prepared in October, 1992		     }
{  Version 1.4.1 prepared in October, 1991		     }
{  Version 1.4 prepared in September, 1991		     }
{  Version 1.3 prepared in September, 1990		     }
{							     }
{------------------------------------------------------------}
 
program pascal (output);

{$segment 'pascal'}

{$LibPrefix '0/obj/'}

uses PCommon, CGI, Scanner, Symbols, Parser;

begin
{initialization:}
MMInit;					{memory manager}
InitPCommon;				{common module}
InitScalars;				{global variables}
InitSets;     
CodeGenScalarInit;
scanner_init; 
enterstdtypes;
stdnames;     
entstdnames;  
EnterUndecl;  
if progress or list then begin
   writeln('ORCA/Pascal 2.2.0'); 	{write banner}
   writeln('Copyright 1987,1988,1991,1993,1994,1996, Byte Works, Inc.');
   writeln;
   end; {if}
level := 1;				{set the top symbol level}
top := 1;

{compile:}
InSymbol;				{get the first symbol}
programme(blockbegsys+statbegsys-[casesy]); {compile the program}
               
{termination:}
if codeGeneration then CodeGenFini;	{shut down code generator}
scanner_fini;				{shut down scanner}
StopSpin;
end.
