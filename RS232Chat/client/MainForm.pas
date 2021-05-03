unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.OleCtrls, SHDocVw_TLB, Vcl.Buttons, sBitBtn, CPort;

type
  TMain = class(TForm)
    Panel1: TPanel;
    WebBrowser: TWebBrowser;
    StartButton: TButton;
    SendEdit: TEdit;
    SendButton: TsBitBtn;
    StopButton: TButton;
    SettingsButton: TButton;
    ComPort: TComPort;

    procedure SendButtonClick(Sender: TObject);
    procedure SendEditKeyPress(Sender: TObject; var Key: Char);
    procedure SettingsButtonClick(Sender: TObject);
    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure StartButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
  private
    FChatText:String;
    procedure AddText(LocalText, RemoteText:String);
    procedure RenderTextInBrowser();
    //InQueue:TQueue<String>
  public
    { Public declarations }
  end;

var
  Main: TMain;

implementation

{$R *.dfm}

procedure TMain.ComPortRxChar(Sender: TObject; Count: Integer);
var
  Str: String;
begin
  ComPort.ReadStr(Str, Count);
  //showmessage(Str);
  AddText('',Str);
  RenderTextInBrowser();
end;

//procedure TMain.FormShow(Sender: TObject);
//var
//  Doc: Variant;
//  html:String;
//begin
//  if NOT Assigned(WebBrowser.Document) then
//    WebBrowser.Navigate('about:blank');
//
//  Doc := WebBrowser.Document;
//  Doc.Clear;
//  Doc.Write(FChatText);
//  Doc.Close;
//end;
procedure TMain.AddText(LocalText, RemoteText:String);
begin
   if(LocalText<>'')then begin
    FChatText:=FChatText+ '<div style="text-align:right;color: green;margin-right:5px;">'+LocalText+'</div>';

   end;
   if(RemoteText<>'')then begin
    FChatText:=FChatText+ '<div style="text-align:left;margin-left:5px;">'+RemoteText+'</div>';
   end;


end;
procedure TMain.RenderTextInBrowser();
var content:String;
  Doc: Variant;
begin
  if NOT Assigned(WebBrowser.Document) then
    WebBrowser.Navigate('about:blank');

   Doc := WebBrowser.Document;
   Doc.Clear;

   content:='<!DOCTYPE html><html lang="en"><head></head><body><strong>';
   content:=content+FChatText;
   content:=content+'<script>';
   content:=content+'    window.scrollTo(0, document.body.scrollHeight || document.documentElement.scrollHeight);';
   content:=content+'</script>';
   content:=content+'</html></strong></html>';

   Doc.Write(content);
   Doc.Close;
end;


procedure TMain.SendButtonClick(Sender: TObject);
begin
if(SendEdit.Text<>'')then begin
    AddText(SendEdit.Text,'');
    SendEdit.Text:='';
    RenderTextInBrowser();
end;

end;

procedure TMain.SendEditKeyPress(Sender: TObject; var Key: Char);
var
  Str: String;
begin
  if Key = #13 then
  begin
    Key := #0;
    //send RS232
    Str := SendEdit.Text;
    Str := Str + #13#10;
    ComPort.WriteStr(Str);
    self.SendButtonClick(nil);
  end;
end;

procedure TMain.SettingsButtonClick(Sender: TObject);
begin
ComPort.ShowSetupDialog;
end;

procedure TMain.StartButtonClick(Sender: TObject);
begin
 StopButton.Enabled:=true;
 StartButton.Enabled:=false;
 SettingsButton.Enabled:=false;
 ComPort.Open;
end;

procedure TMain.StopButtonClick(Sender: TObject);
begin
 StopButton.Enabled:=false;
 StartButton.Enabled:=true;
 SettingsButton.Enabled:=true;
 ComPort.Close;
end;

end.
