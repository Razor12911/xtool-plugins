library sr22;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas';

const
  Codecs: array of PChar = ['sr22'];

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

  function LZ4BlockSize(BlockSize: Integer): Integer;
  var
    I: Integer;
  begin
    Result := 4;
    I := BlockSize shr 17;
    while I > 0 do
    begin
      I := I shr 2;
      Inc(Result);
    end;
  end;

const
  Header = $1151890ACE;

type
  PStruct1 = ^TStruct1;

  TStruct1 = packed record
    Header: Int64;
    Unk1, Unk2: Integer;
    StreamCount, Unk3: Integer;
    BlockInfoSize, FilenamesSize: Integer;
    Unk4, Unk5, Unk6, Unk7: Int64;
    StartPos: Int64;
    Unk8: array [0 .. 55] of Byte;
  end;

  PStruct2 = ^TStruct2;

  TStruct2 = packed record
    Unk1, StreamPos: Int64;
    DecompSize, CompSize: Int64;
    BlockInfo, Unk3: Integer;
    Unk4: Int64;
  end;
var
  Pos: NativeInt;
  LSize: NativeInt;
  I: Integer;
  X: Integer;
  LStr1: PStruct1;
  LStr2: PStruct2;
  P: NativeInt;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - 16;
  while Pos < LSize do
  begin
    if (PInt64(Input + Pos)^ = Header) then
    begin
      LStr1 := PStruct1(Input + Pos);
      for I := 0 to LStr1^.StreamCount - 1 do
      begin
        LStr2 := PStruct2(Input + Pos + SizeOf(TStruct1)) + I;
        X := LZ4BlockSize(LStr2^.BlockInfo - 1);
        if (LongRec(LStr2^.BlockInfo).Bytes[0] = 1) and (X in [4 .. 7]) then
        begin
          SI.Position := Pos + LStr1^.StartPos + LStr2^.StreamPos;
          SI.OldSize := LStr2^.CompSize;
          SI.NewSize := LStr2^.DecompSize;
          SI.Resource := 0;
          SI.Option := 0;
          if (SI.NewSize > SI.OldSize) then
            Add(Instance, @SI, PChar('lz4f:l9:b' + X.ToString), nil);
        end;
      end;
      Inc(Pos, LStr1^.StartPos);
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
