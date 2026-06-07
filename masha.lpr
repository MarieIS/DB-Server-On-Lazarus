program masha;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, Sockets, ssockets;

type

  { TMasha }

  TMasha = class(TCustomApplication)
  private
    FServerSocket : TInetServer;
    FPort : Word;
    procedure OnClientConnect(Sender: TObject; Data: TSocketStream);
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TMasha }

procedure TMasha.DoRun;
var
  ErrorMsg: String;
  ClientSocket: TInetSocket;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h', 'help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  // парсим порт из командной строки (если указан)
  if HasOption('p', 'port')
   then FPort := StrToIntDef(GetOptionValue('p', 'port'), 3003);

  // запуск сервера
  writeln('[Server] Starting database server on port', FPort);

  try
   // создаем сервер
   FServerSocket := TInetServer.Create(FPort);
   // назначаем обработчик события
   FServerSocket.OnConnect := @OnClientConnect;
   writeln('[Server] Listening for connections...');
   // запускаем сервер (неблокирующий режим)
   FServerSocket.StartAccepting;
   // держим программу активной
   while not Terminated do Sleep(100);
   writeln('[Server] Shutting down...');
   FServerSocket.StopAccepting;
   Sleep(500);
  except
    on E: Exception do
     writeln('[Server] Error: ', E.Message);
  end;

  // stop program loop
  Terminate;
end;

procedure TMasha.OnClientConnect(Sender: TObject; Data: TSocketStream);
var
  ReceivedData, Response : string;
  ch : Char;
begin
  writeln('[Server] Client connected');
  ReceivedData := '';
  // устанавливаем таймаут на чтение
  Data.IOTimeout:= 100;
  while not Terminated do
   begin
     // читаем данные, пока клиент не отключится
     if Data.Read(ch, 1) = 1 then
      begin
        ReceivedData := ReceivedData + ch;
        // если получили нулевой байт (#0) - отвечаем
        if ch = #0 then
         begin
           writeln('[Server] Received: ', ReceivedData);
           // формируем ответ с нулевым байтом
           Response := 'Query received' + #0;
           // отправляем ответ
           Data.Write(Response[1], Length(Response));
           // очищаем буфер для следующего сообщения
           ReceivedData := '';
         end;
      end
     else
      begin
        Sleep(10);
      end;
   end;

  // здесь Data - это уже установленное соединение
  // взаимодействовать с клиентом через Data.Read и Data.Write
  writeln('[Server] Client disconnected');
  Data.Free;
end;

constructor TMasha.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
  FPort := 3003; // port in default
  FServerSocket := nil;
end;

destructor TMasha.Destroy;
begin
  FServerSocket.Free;
  inherited Destroy;
end;

procedure TMasha.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' [options]');
  writeln('Options:');
  writeln('  -h, --help      Show this help');
  writeln('  -p, --port=PORT Set port number (default: 3003)');
end;

var
  Application: TMasha;
begin
  Application:=TMasha.Create(nil);
  Application.Title:='My DB Server';
  Application.Run;
  Application.Free;
end.

