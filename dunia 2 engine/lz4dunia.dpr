library lz4dunia;

{$R *.res}
{$SETPEOSVERSION 6.0}
{$SETPESUBSYSVERSION 6.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$R *.dres}

uses
  WinAPI.Windows,
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  Utils in 'Utils.pas',
  FuncHook in 'Delphi_MemoryModule\FuncHook.pas',
  MemoryModule in 'Delphi_MemoryModule\MemoryModule.pas',
  MemoryModuleHook in 'Delphi_MemoryModule\MemoryModuleHook.pas';

var
  lz4_decode: function(src: Pointer; dst: Pointer; src_size: Integer;
    dst_size: Int64; dst_lim: Integer): Integer cdecl;
  decode1: function(src: Pointer; src_size: Integer; dst: Pointer;
    dst_size: Integer): Integer cdecl;
  decode2: function(src: Pointer; src_size: Integer; dst: Pointer;
    dst_size: Integer): Integer cdecl;
  decode3: function(src: Pointer; src_size: Integer; dst: Pointer;
    dst_size: Integer): Integer cdecl;

const
  Codecs: array of PChar = ['lz4dunia'];

function PrecompInit(Command: PChar; Count: Integer; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := True;
end;

procedure PrecompFree(Funcs: PPrecompFuncs)cdecl;
begin

end;

function PrecompCodec(Index: Integer): PChar cdecl;
begin
  Result := nil;
  if Index in [Integer(Low(Codecs)), Integer(High(Codecs))] then
    Result := Codecs[Index];
end;

procedure PrecompScan1(Instance: Integer; Input: PByte; Size, SizeEx: Cardinal;
  Output: TPrecompOutput; Add: TPrecompAdd; Funcs: PPrecompFuncs)cdecl;
begin

end;

function PrecompScan2(Instance: Integer; Input: Pointer; Size: Cardinal;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
  Res: Integer;
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo^.NewSize);
  Res := decode1(Input, StreamInfo^.OldSize, Buffer, StreamInfo^.NewSize);
  if InRange(Res, Max(64, Res - 128), StreamInfo^.NewSize) then
  begin
    StreamInfo^.NewSize := Res;
    Output(Instance, Buffer, Res);
    Funcs^.Transfer(Instance, 'lz4hc:l9');
    Result := True;
  end;
end;

function PrecompProcess(Instance: Integer; OldInput, NewInput: Pointer;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := False;
end;

function PrecompRestore(Instance: Integer; Input, InputExt: Pointer;
  StreamInfo: TStrInfo3; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := False;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1, PrecompScan2,
  PrecompProcess, PrecompRestore;

var
  DLLStream: TResourceStream;
  DLLHandle: TMemoryModule;

begin
  DLLStream := TResourceStream.Create(HInstance, 'DUNIA_DLL', RT_RCDATA);
  DLLHandle := MemoryLoadLibary(DLLStream.Memory);
  @lz4_decode := MemoryGetProcAddress(DLLHandle, 'lz4_decode');
  Assert(@lz4_decode <> nil);
  @decode1 := MemoryGetProcAddress(DLLHandle, 'decode1');
  Assert(@decode1 <> nil);
  @decode2 := MemoryGetProcAddress(DLLHandle, 'decode2');
  Assert(@decode2 <> nil);
  @decode3 := MemoryGetProcAddress(DLLHandle, 'decode3');
  Assert(@decode3 <> nil);

end.
