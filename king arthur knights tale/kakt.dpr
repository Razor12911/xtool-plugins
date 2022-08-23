library kakt;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas';

const
  Codecs: array of PChar = ['kakt'];

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
  Header = $656C646F6F;
  Version = $0D;

type
  PStruct = ^TStruct;

  TStruct = packed record
    Header, Unk1, Unk2: Int64;
    Version, Unk3: Integer;
    DecompSize, CompSize: Int64;
    StreamCount, BlockSize: Integer;
    Unk4, Unk5: Int64;
  end;
var
  Pos: NativeInt;
  LSize: NativeInt;
  I: Integer;
  X, Y: Integer;
  LStr: PStruct;
  P1, P2: NativeInt;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - SizeOf(TStruct);
  while Pos < LSize do
  begin
    if (PInt64(Input + Pos)^ = Header) then
    begin
      LStr := PStruct(Input + Pos);
      if LStr^.Version = Version then
      begin
        X := LStr^.CompSize;
        Y := LStr^.DecompSize;
        P1 := SizeOf(TStruct);
        P2 := SizeOf(TStruct);
        for I := 0 to LStr^.StreamCount - 1 do
          Inc(P2, Integer.Size);
        for I := 0 to LStr^.StreamCount - 1 do
        begin
          SI.Position := Pos + P2;
          SI.OldSize := PInteger(Input + Pos + P1)^;
          SI.NewSize := Min(Y, LStr^.BlockSize);
          SI.Resource := 0;
          SI.Option := 0;
          if SI.NewSize > SI.OldSize then
            Add(Instance, @SI, 'leviathan', nil);
          Inc(P1, Integer.Size);
          Inc(P2, SI.OldSize);
          Dec(Y, SI.NewSize);
        end;
        Inc(Pos, P2);
        continue;
      end;
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
