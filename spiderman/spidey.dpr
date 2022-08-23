library spidey;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas';

const
  Codecs: array of PChar = ['spidey'];

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

procedure PrecompScan1(Instance: Integer; Input: PByte; Size, SizeEx: NativeInt;
  Output: TPrecompOutput; Add: TPrecompAdd; Funcs: PPrecompFuncs)cdecl;
const
  Header = $1000352415344;

type
  PStruct = ^TStruct;

  TStruct = packed record
    DecompPos, CompPos: Int64;
    DecompSize, CompSize: Integer;
    Padding: Int64;
  end;
var
  Pos: NativeInt;
  LSize: NativeInt;
  I: Integer;
  X, Y: Integer;
  Count, HeaderSize: Integer;
  LStr: PStruct;
  P: NativeInt;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - 16;
  while Pos < LSize do
  begin
    if (PInt64(Input + Pos)^ = Header) then
    begin
      P := 8;
      Count := PInteger(Input + Pos + P)^;
      Inc(P, Count.Size);
      HeaderSize := PInteger(Input + Pos + P)^;
      Inc(P, Count.Size);
      Inc(P, 16);
      for I := 0 to Count - 1 do
      begin
        LStr := PStruct(Input + Pos + P);
        SI.Position := Pos + LStr^.CompPos;
        SI.OldSize := LStr^.CompSize;
        SI.NewSize := LStr^.DecompSize;
        SI.Resource := 0;
        SI.Option := 0;
        if SI.NewSize > SI.OldSize then
          Add(Instance, @SI, 'lz4', nil);
        Inc(P, SizeOf(TStruct));
      end;
      Inc(Pos, HeaderSize);
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
begin
  Result := False;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1, PrecompScan2,
  PrecompProcess, PrecompRestore;

begin

end.
