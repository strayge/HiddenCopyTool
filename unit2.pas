unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

implementation

procedure test123();
Var Info : TSearchRec;
    Count : Longint;
Begin
  Count:=0;
  If FindFirst ('*',faAnyFile and faDirectory,Info)=0 then
    begin
    Repeat
      Inc(Count);
      With Info do
        begin
        If (Attr and faDirectory) = faDirectory then
          Write('Dir : ');
        Writeln (Name:40,Size:15);
        end;
    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  Writeln ('Finished search. Found ',Count,' matches');
end;

end.

