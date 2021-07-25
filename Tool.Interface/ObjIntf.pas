{********************************************************
*
*  Object Interface
*
*  Other USES Files Needed: - None -
*
*  Copyright 1993
*  By the Byte Works, Inc.
*  All Rights Reserved
*
*********************************************************}

{$keep 'ObjIntf'}

unit ObjIntf;

interface

type
   tObject = object
      function ShallowClone: tObject;
      function Clone: tObject;
      procedure ShallowFree;
      procedure Free;
      end;

implementation

end.
