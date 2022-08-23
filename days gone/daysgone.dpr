library daysgone;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  WinAPI.Windows,
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas';

procedure ShowMessage(Msg: string; Caption: string = '');
begin
  MessageBox(0, PChar(Msg), PChar(Caption), MB_OK or MB_TASKMODAL);
end;

const
  Codecs: array of PAnsiChar = ['daysgone'];
  MinSize = 256;

function PrecompInit(Command: PAnsiChar; Count: Integer; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := True;
end;

procedure PrecompFree(Funcs: PPrecompFuncs)cdecl;
begin

end;

function PrecompCodec(Index: Integer): PAnsiChar cdecl;
begin
  Result := nil;
  if Index in [Integer(Low(Codecs)), Integer(High(Codecs))] then
    Result := Codecs[Index];
end;

procedure PrecompScan1(Instance: Integer; Input: PByte; Size, SizeEx: NativeInt;
  Output: TPrecompOutput; Add: TPrecompAdd; Funcs: PPrecompFuncs)cdecl;
type
  PSHA1Digest = ^TSHA1Digest;

  TSHA1Digest = array [0 .. 19] of Byte;

  PDGStruct = ^TDGStruct;

  TDGStruct = packed record
    StartOffset, EndOffset: Int64;
  end;

var
  Pos: NativeInt;
  LSize: NativeInt;
  LTotalCSize, LTotalDSize: Int64;
  LSHA1: TSHA1Digest;
  LCount, LMaxBlockSize: Integer;
  LStartPos: NativeInt;
  LDGStrPtr: PByte;
  LDGStruct: TDGStruct;
  I: Integer;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - 28;
  while Pos < LSize do
  begin
    if (PInt64(Input + Pos)^ = $0) and (PInteger(Input + Pos + 24)^ = $4) then
    begin
      LTotalCSize := PInt64(Input + Pos + 8)^;
      LTotalDSize := PInt64(Input + Pos + 16)^;
      Move((Input + Pos + 28)^, LSHA1, SizeOf(TSHA1Digest));
      LCount := PInteger(Input + Pos + 48)^;
      LDGStrPtr := Input + Pos + 52;
      LMaxBlockSize :=
        PInteger(Input + Pos + 52 + (LCount * SizeOf(TDGStruct)) + 1)^;
      LStartPos := 52 + (LCount * SizeOf(TDGStruct)) + 5;
      for I := 0 to LCount - 1 do
      begin
        LDGStruct := PDGStruct(LDGStrPtr)^;
        SI.Position := Pos + LStartPos;
        SI.OldSize := LDGStruct.EndOffset - LDGStruct.StartOffset;
        SI.NewSize := Min(LMaxBlockSize, LTotalDSize);
        SI.Option := 0;
        Add(Instance, @SI, 'kraken:l4:t384');
        Inc(LDGStrPtr, SizeOf(TDGStruct));
        Inc(LStartPos, SI.OldSize);
        Dec(LTotalCSize, SI.OldSize);
        Dec(LTotalDSize, SI.NewSize);
      end;
      Inc(Pos, 28);
      continue;
    end;
    Inc(Pos);
  end;
end;

function PrecompScan2(Instance: Integer; Input: Pointer; Size: NativeInt;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := False;
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
var
  Buffer: PByte;
begin
  Result := False;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1, PrecompScan2,
  PrecompProcess, PrecompRestore;

begin

end.
