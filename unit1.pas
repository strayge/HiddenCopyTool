unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Menus, StdCtrls, Windows, ShellAPI;

type

  { TForm1 }

  TForm1 = class(TForm)
      btnHide: TButton;
      btnSelectFolder: TButton;
      Button1: TButton;
      edtFind: TEdit;
      edtCopyFilter: TEdit;
      edtFolder: TEdit;
      Label1: TLabel;
      Label2: TLabel;
      Label3: TLabel;
      Memo1: TMemo;
      menuExit: TMenuItem;
      menuShow: TMenuItem;
      PopupMenu1: TPopupMenu;
      dlgSelect: TSelectDirectoryDialog;
      Timer1: TTimer;
      TrayIcon1: TTrayIcon;
      procedure btnHideClick(Sender: TObject);
      procedure btnSelectFolderClick(Sender: TObject);
      procedure Button1Click(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure FormShow(Sender: TObject);
      procedure menuExitClick(Sender: TObject);
      procedure menuShowClick(Sender: TObject);
      procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { private declarations }
  end;

var
  Form1: TForm1;
  list: DWORD;
  first_show:boolean=true;

const
  MIN_FREE_SPACE = 200*1024*1024;
  WAIT_AFTER_FINDED = 15*1000;
  WAIT_BETWEEN_SCAN = 60*1000;
  HIDE_AT_START = true;

implementation

{$R *.lfm}

{ TForm1 }

function GetDiskSize(drive: Char; var free_size, total_size: Int64): Boolean;
var
  RootPath: array[0..4] of Char;
  RootPtr: PChar;
  current_dir: string;
begin
  RootPath[0] := Drive;
  RootPath[1] := ':';
  RootPath[2] := '\';
  RootPath[3] := #0;
  RootPtr := RootPath;
  current_dir := GetCurrentDir;
  if SetCurrentDir(drive + ':\') then
  begin
    GetDiskFreeSpaceEx(RootPtr, Free_size, Total_size, nil);
    // this to turn back to original dir
    SetCurrentDir(current_dir);
    Result := True;
  end
  else
  begin
    Result := False;
    Free_size  := -1;
    Total_size := -1;
  end;
end;


function CopyAllFiles(sFrom, sTo: string; Protect: boolean): boolean;
{ Copies files or directory to another directory. }
var
  F: TShFileOpStruct;
  ResultVal: integer;
  tmp1, tmp2: string;
begin
  FillChar(F{%H-}, SizeOf(F), #0);
  Screen.Cursor := crHourGlass;

  try
    F.Wnd := 0;
    F.wFunc := FO_COPY;
    { Add an extra null char }
    tmp1 := sFrom + #0;
    tmp2 := sTo + #0;
    F.pFrom := PChar(tmp1);
    F.pTo := PChar(tmp2);

    if Protect then
      F.fFlags := FOF_SIMPLEPROGRESS or FOF_NOCONFIRMATION or
                  FOF_SILENT or FOF_NOERRORUI //or FOF_RENAMEONCOLLISION
    else
      F.fFlags := FOF_SIMPLEPROGRESS;

    F.fAnyOperationsAborted := False;
    F.hNameMappings := nil;
    Resultval := ShFileOperation(F);
    Result := (ResultVal = 0);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TForm1.menuExitClick(Sender: TObject);
begin
  Form1.Close();
end;

procedure TForm1.menuShowClick(Sender: TObject);
begin
  Form1.Show;
end;

function check1bit(ld: DWORD; i: integer):boolean;
begin
  if (ld and (1 shl i)) <> 0 then
    Result:=true
  else
    Result:=false;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  ld: DWORD;
  i: integer;
  tsr: TSearchRec;
  finded: boolean;
  free_size_read, total_size_read: Int64;
  free_size_write, total_size_write: Int64;
  cur_disk_letter: Char;
  copyPath, copyFilter, findFilter: String;
begin
  Timer1.Enabled:=false;
  //Memo1.Lines.Add('work in');
  ld:= GetLogicalDrives;
  copyPath := UTF8ToAnsi(edtFolder.Text);
  copyFilter := UTF8ToAnsi(edtCopyFilter.Text);
  findFilter := UTF8ToAnsi(edtFind.Text);
  for i:= 0 to 25 do begin
    if (check1bit(ld,i) and (not check1bit(list,i))) then begin
      cur_disk_letter:=Char(Ord('A')+i);

      Memo1.Lines.Add( 'Added ' + cur_disk_letter + ':\' );

      Memo1.Lines.Add('wait '+FloatToStr(WAIT_AFTER_FINDED / 1000)+' sec');
      sleep(WAIT_AFTER_FINDED);

      finded:=false;
      if FindFirst( cur_disk_letter + ':\' + findFilter, faAnyFile,tsr) = 0
      then begin
        finded:=true;
      end;
      SysUtils.FindClose(tsr);
      if finded then begin
        if GetDiskSize(cur_disk_letter,free_size_read{%H-},total_size_read{%H-})
        and GetDiskSize(copyPath[1],free_size_write{%H-},total_size_write{%H-})
        then begin
          if (free_size_write-MIN_FREE_SPACE) < (total_size_read-free_size_read)
          then begin
            Memo1.Lines.Add('disk is full, stopped');
            Timer1.Enabled:=false;
          end;
        end
        else begin
          Memo1.Lines.Add('error at get space at disk '+cur_disk_letter);
        end;
        //copy
        if CopyAllFiles( cur_disk_letter + ':\' + copyFilter, copyPath, true)
        then Memo1.Lines.Add('ok')
        else Memo1.Lines.Add('fail');
      end;
    end;
  end;
  list:=ld;
  //Memo1.Lines.Add('work out');
  Timer1.Enabled:=true;
end;

procedure TForm1.btnSelectFolderClick(Sender: TObject);
begin
  if dlgSelect.Execute then
    edtFolder.Caption:=dlgSelect.FileName;
end;


procedure TForm1.Button1Click(Sender: TObject);
var
  ld: DWORD;
  i: integer;
begin
  ld:= GetLogicalDrives;
  for i:= 0 to 25 do begin
    if (ld and (1 shl i)) <> 0 then
      Memo1.Lines.Text:=Memo1.Lines.Text+Char(Ord('A') + i);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  list:=GetLogicalDrives;
  edtFolder.Text:=AnsiToUTF8(ExtractFilePath(Application.ExeName));
  Timer1.Interval:=WAIT_BETWEEN_SCAN;
  Timer1.Enabled:=true;
end;

procedure TForm1.FormShow(Sender: TObject);

begin
  if first_show then begin
    if HIDE_AT_START then Form1.Hide;
    first_show:=false;
  end;
end;

procedure TForm1.btnHideClick(Sender: TObject);
begin
  Form1.Hide;
end;

end.

