library hitman;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  Utils in 'Utils.pas';

const
  XorKey: array of Byte = [$DC, $45, $A6, $9C, $D3, $72, $4C, $AB];

const
  Codecs: array of PChar = ['hitman3'];
  MinSize = 256;

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
type
  PHM3Struct1 = ^THM3Struct1;

  THM3Struct1 = packed record
    Hash: UInt64;
    Offset: Cardinal;
    Unknown: Cardinal;
    OrigSize: Cardinal;
  end;

  PHM3Struct2 = ^THM3Struct2;

  THM3Struct2 = packed record
    FileType: array [0 .. 3] of AnsiChar;
    Overhead: Cardinal;
    Unknown: Cardinal;
    UnpSize: Cardinal;
  end;

var
  Pos: NativeInt;
  LSize: NativeInt;
  I: Integer;
  Count: Integer;
  LHM3Struct1: THM3Struct1;
  LHM3Struct2: THM3Struct2;
  Struct2Ptr: PByte;
  Compressed, Encrypted: Boolean;
  SI: TStrInfo1;
  DI: TDepthInfo;
  _DI: PDepthInfo;
begin
  Pos := 0;
  LSize := Size - 25;
  while Pos < LSize do
  begin
    if (PInteger(Input + Pos)^ = $52504B32) and
      (PWord(Input + Pos + 11)^ = $7878) then
    begin
      Count := PInteger(Input + Pos + 13)^;
      if Pos + 25 + PInteger(Input + Pos + 17)^ <= SizeEx then
      begin
        Struct2Ptr := Input + Pos + 25 + PInteger(Input + Pos + 17)^;
        for I := 0 to Count - 1 do
        begin
          LHM3Struct1 := (PHM3Struct1((Input + Pos + 25)) + I)^;
          LHM3Struct2 := PHM3Struct2(Struct2Ptr)^;
          SI.Position := Pos + LHM3Struct1.Offset;
          SI.OldSize := LHM3Struct1.OrigSize and $3FFFFFFF;
          SI.NewSize := LHM3Struct2.UnpSize;
          SI.Option := 0;
          Compressed := SI.OldSize > 0;
          Encrypted := LHM3Struct1.OrigSize and $80000000 = $80000000;
          Inc(Struct2Ptr, 24 + LHM3Struct2.Overhead);
          if Encrypted then
          begin
            if not Compressed then
              SI.OldSize := LHM3Struct2.UnpSize;
            SI.NewSize := SI.OldSize;
          end;
          if SI.OldSize < MinSize then
            continue;
          if Encrypted then
          begin
            if Compressed then
            begin
              FillChar(DI, SizeOf(TDepthInfo), 0);
              DI.Codec := 'lz4hc:l12';
              DI.OldSize := SI.OldSize;
              DI.NewSize := LHM3Struct2.UnpSize;
              _DI := @DI
            end
            else
              _DI := nil;
            Add(Instance, @SI, '', _DI);
          end
          else if Compressed then
            Add(Instance, @SI, 'lz4hc:l12', nil);
        end;
      end;
      Inc(Pos, 25);
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
  if StreamInfo^.NewSize <= Size then
  begin
    Output(Instance, Input, StreamInfo^.NewSize);
    Result := True;
  end;
end;

function PrecompProcess(Instance: Integer; OldInput, NewInput: Pointer;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := Funcs^.Decrypt('xor', NewInput, StreamInfo^.NewSize, @XorKey[0],
    Length(XorKey));
end;

function PrecompRestore(Instance: Integer; Input, InputExt: Pointer;
  StreamInfo: TStrInfo3; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo.NewSize);
  Move(Input^, Buffer^, StreamInfo.NewSize);
  if Funcs^.Encrypt('xor', Buffer, StreamInfo.NewSize, @XorKey[0],
    Length(XorKey)) then
  begin
    Output(Instance, Buffer, StreamInfo.OldSize);
    Result := True;
  end;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1, PrecompScan2,
  PrecompProcess, PrecompRestore;

begin

end.
