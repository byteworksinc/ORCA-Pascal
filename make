unset exit
set flags +t +e

Newer obj/pascal pascal.rez
if {status} != 0
   set exit on
   echo compile -e pascal.rez keep=obj/Pascal
   compile -e pascal.rez keep=obj/Pascal
   unset exit
end

if {#} == 0 then

   Newer obj/gen.a gen.pas
   if {Status} != 0
      set gen gen
      set dag dag
   end                   

   Newer obj/cgc.a cgc.pas cgc.asm cgc.macros
   if {Status} != 0
      set cgc cgc
      set dag dag
      set gen gen
      set objout objout
      set native native
      set symbols symbols
   end                   

   Newer obj/dag.a dag.pas dag.asm dag.macros
   if {Status} != 0
      set dag dag
   end                   

   Newer obj/pascal.a pascal.pas
   if {Status} != 0
      set pascal pascal
   end                   

   Newer obj/parser.a parser.pas
   if {Status} != 0
      set parser parser
      set pascal pascal
   end                   

   Newer obj/call.a call.pas
   if {Status} != 0
      set call call
      set parser parser
   end                   

   Newer obj/objout.a objout.pas objout.asm objout.macros
   if {Status} != 0
      set objout objout
      set symbols symbols
      set native native
      set gen gen
   end                   

   Newer obj/native.a native.pas native.asm native.pas
   if {Status} != 0
      set native native
      set symbols symbols
      set gen gen
   end                   

   Newer obj/cgi.a cgi.pas cgi.asm
   if {Status} != 0
      set cgi cgi
      set call call
      set native native
      set scanner scanner
      set symbols symbols
      set parser parser
      set pascal pascal
      set dag dag
      set cgc cgc
      set gen gen
      set objout objout
   end                   

   Newer obj/scanner.a scanner.pas scanner.asm scanner.macros
   if {Status} != 0
      set scanner scanner
      set symbols symbols
      set call call
      set parser parser
      set pascal pascal
   end                   

   Newer obj/symbols.a symbols.pas symbols.asm symbols.macros
   if {Status} != 0
      set symbols symbols
      set call call
      set parser parser
      set pascal pascal
   end                 

   Newer obj/pcommon.a pcommon.pas pcommon.asm pcommon.macros
   if {Status} != 0
      set pcommon pcommon
      set call call
      set symbols symbols
      set cgi cgi
      set native native
      set objout objout
      set parser parser
      set dag dag
      set cgc cgc
      set gen gen
   end                   

   set exit on
   set list {pcommon} {cgi} {cgc} {objout} {native} {gen} {dag} {scanner} {symbols} {call} {parser} {pascal}
   for i in {list}
      echo compile {flags} {i}.pas keep=obj/{i}
      compile {flags} {i}.pas keep=obj/{i}
   end

else

   set exit on
   for i in {parameters}
      echo compile {flags} {i}.pas keep=obj/{i}
      compile {flags} {i}.pas keep=obj/{i}
   end
end

* echo purge
* purge >.null
echo linkit
linkit
echo copy -c obj/pascal 16/Pascal
copy -c obj/pascal 16/Pascal
