library unreal;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.Math,
  Utils in 'Utils.pas';

const
  Codecs: array of PChar = ['ue3', 'ue4'];
  CODEC_COUNT = 2;
  UE3_CODEC = 0;
  UE4_CODEC = 1;
  MinSize = 256;

var
  CodecEnabled: TArray<Boolean>;
  KeyBytes: TBytes;
  UE3Method: Byte;

function PrecompInit(Command: PChar; Count: Integer; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  S, KeyString: String;
  I: Integer;
  X: Integer;
begin
  Result := False;
  for I := Low(Codecs) to High(Codecs) do
    CodecEnabled[I] := False;
  X := 0;
  while Funcs^.GetCodec(Command, X, False) <> '' do
  begin
    S := String(Funcs^.GetCodec(Command, X, False));
    if (CompareText(S, String(Codecs[UE3_CODEC])) = 0) then
    begin
      UE3Method := 1;
      if Funcs^.GetParam(Command, 0, 'm') <> '' then
        UE3Method := String(Funcs^.GetParam(Command, 0, 'm')).ToInteger;
      CodecEnabled[UE3_CODEC] := True;
    end
    else if (CompareText(S, String(Codecs[UE4_CODEC])) = 0) then
    begin
      SetLength(KeyBytes, 32);
      if Funcs^.GetParam(Command, 0, 'k') <> '' then
      begin
        KeyString := String(Funcs^.GetParam(Command, 0, 'k'));
        if KeyString.StartsWith('0x', True) then
          I := 2
        else if KeyString.StartsWith('$') or KeyString.StartsWith('#') then
          I := 1
        else
          I := 0;
        SetLength(KeyBytes, HexToBin(BytesOf(KeyString), I, KeyBytes, 0,
          Length(KeyBytes)));
      end;
      CodecEnabled[UE4_CODEC] := True;
    end;
    Inc(X);
  end;
  for I := Low(Codecs) to High(Codecs) do
    if CodecEnabled[I] then
    begin
      Result := True;
      break;
    end;
end;

procedure PrecompFree(Funcs: PPrecompFuncs)cdecl;
begin

end;

function PrecompCodec(Index: Integer): PWideChar cdecl;
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

  PUE3Struct1 = ^TUE3Struct1;

  TUE3Struct1 = packed record
    CompressedSize, DecompressedSize: Int64;
  end;

  PUE3Struct2 = ^TUE3Struct2;

  TUE3Struct2 = packed record
    CompressedSize, DecompressedSize: Integer;
  end;

  PUE4HdrStruct1 = ^TUE4HdrStruct1;

  TUE4HdrStruct1 = packed record
    ZeroHeader: Int64;
    CompressedSize, DecompressedSize: Int64;
    CompressionType8: Byte;
    CompressionType24: array [0 .. 2] of Byte;
    Hash: TSHA1Digest;
  end;

  PUE4HdrStruct2 = ^TUE4HdrStruct2;

  TUE4HdrStruct2 = packed record
    ZeroHeader: Int64;
    CompressedSize, DecompressedSize: Int64;
    CompressionType: Byte;
    Hash: TSHA1Digest;
  end;

  PUE4BlkStruct1 = ^TUE4BlkStruct1;

  TUE4BlkStruct1 = packed record
    StartPos: Int64;
    EndPos: Int64;
  end;

  PUE4FtrStruct1 = ^TUE4FtrStruct1;

  TUE4FtrStruct1 = packed record
    Encrypted: Byte;
    BlockSize: Integer;
  end;

var
  X: Integer;
  Pos: NativeInt;
  LSize: NativeInt;
  I, J: Integer;
  CompressedSize, DecompressedSize: Int64;
  A, B: Int64;
  CompressionType: Integer;
  Checksum1: TSHA1Digest;
  Checksum2: PSHA1Digest;
  BlockCount, BlockSize: Integer;
  BlockInfo: PUE4BlkStruct1;
  StreamPos: Integer;
  SI: TStrInfo1;
begin
  for X := Low(Codecs) to High(Codecs) do
  begin
    if not CodecEnabled[X] then
      continue;
    case X of
      UE3_CODEC:
        begin
          case UE3Method of
            1:
              begin
                Pos := 0;
                LSize := Size - 56;
                while Pos < LSize do
                begin
                  if (PUInt64(Input + Pos)^ = $000000009E2A83C1) and
                    (PUInt64(Input + Pos + 8)^ = $0000000000020000) then
                  begin
                    CompressedSize := PInt64(Input + Pos + 16)^;
                    DecompressedSize := PInt64(Input + Pos + 24)^;
                    A := 0;
                    B := 0;
                    BlockCount := 0;
                    StreamPos := 32;
                    while (B < DecompressedSize) do
                    begin
                      if (PUE3Struct1(Input + Pos + 32) + BlockCount)
                        ^.DecompressedSize > $0000000000020000 then
                      begin
                        Inc(Pos);
                        continue;
                      end;
                      Inc(A, (PUE3Struct1(Input + Pos + 32) + BlockCount)
                        ^.CompressedSize);
                      Inc(B, (PUE3Struct1(Input + Pos + 32) + BlockCount)
                        ^.DecompressedSize);
                      Inc(BlockCount);
                      Inc(StreamPos, SizeOf(TUE3Struct1));
                    end;
                    if (A = CompressedSize) and (B = DecompressedSize) then
                    begin
                      for I := 0 to BlockCount - 1 do
                      begin
                        SI.Position := Pos + StreamPos;
                        SI.OldSize := (PUE3Struct1(Input + Pos + 32) + I)
                          ^.CompressedSize;
                        SI.NewSize := (PUE3Struct1(Input + Pos + 32) + I)
                          ^.DecompressedSize;
                        SI.Option := 0;
                        Add(Instance, @SI, 'lzna:l7', nil);
                        Inc(StreamPos, SI.OldSize);
                      end;
                      Inc(Pos, StreamPos);
                      continue;
                    end;
                  end;
                  Inc(Pos);
                end;
              end;
            2:
              begin
                Pos := 0;
                LSize := Size - 28;
                while Pos < LSize do
                begin
                  if (PCardinal(Input + Pos)^ = $9E2A83C1) and
                    (PCardinal(Input + Pos + 4)^ = $00040000) then
                  begin
                    CompressedSize := PInteger(Input + Pos + 8)^;
                    DecompressedSize := PInteger(Input + Pos + 12)^;
                    A := 0;
                    B := 0;
                    BlockCount := 0;
                    StreamPos := 16;
                    while (B < DecompressedSize) do
                    begin
                      if (PUE3Struct2(Input + Pos + 16) + BlockCount)
                        ^.DecompressedSize > $00040000 then
                      begin
                        Inc(Pos);
                        continue;
                      end;
                      Inc(A, (PUE3Struct2(Input + Pos + 16) + BlockCount)
                        ^.CompressedSize);
                      Inc(B, (PUE3Struct2(Input + Pos + 16) + BlockCount)
                        ^.DecompressedSize);
                      Inc(BlockCount);
                      Inc(StreamPos, SizeOf(TUE3Struct2));
                    end;
                    if (A = CompressedSize) and (B = DecompressedSize) then
                    begin
                      for I := 0 to BlockCount - 1 do
                      begin
                        SI.Position := Pos + StreamPos;
                        SI.OldSize := (PUE3Struct2(Input + Pos + 16) + I)
                          ^.CompressedSize;
                        SI.NewSize := (PUE3Struct2(Input + Pos + 16) + I)
                          ^.DecompressedSize;
                        SI.Option := 0;
                        Add(Instance, @SI, 'leviathan:l4', nil);
                        Inc(StreamPos, SI.OldSize);
                      end;
                      Inc(Pos, StreamPos);
                      continue;
                    end;
                  end;
                  Inc(Pos);
                end;
              end;
          end;
        end;
      UE4_CODEC:
        begin
          Pos := 0;
          LSize := Size - SizeOf(TUE4HdrStruct2);
          while Pos < LSize do
          begin
            CompressedSize := PInt64(Input + Pos + 8)^;
            DecompressedSize := PInt64(Input + Pos + 16)^;
            if (PInt64(Input + Pos)^ = 0) and InRange(CompressedSize, MinSize,
              DecompressedSize) then
            begin
              J := 0;
              Move(PUE4HdrStruct1(Input + Pos)^.CompressionType24, J, 3);
              if (J = 0) then
                I := 1
              else
                I := 2;
              case I of
                1:
                  begin
                    BlockInfo :=
                      PUE4BlkStruct1(Input + Pos + SizeOf(TUE4HdrStruct1) +
                      SizeOf(BlockCount));
                    Checksum2 := @PUE4HdrStruct1(Input + Pos)^.Hash;
                    CompressionType := PUE4HdrStruct1(Input + Pos)
                      ^.CompressionType8;
                    if CompressionType = 0 then
                    begin
                      if CompressedSize <> DecompressedSize then
                      begin
                        Inc(Pos);
                        continue;
                      end;
                      BlockCount := 0;
                      StreamPos := SizeOf(TUE4HdrStruct1) +
                        SizeOf(TUE4FtrStruct1);
                    end
                    else
                    begin
                      BlockCount :=
                        PInteger(Input + Pos + SizeOf(TUE4HdrStruct1))^;
                      StreamPos := SizeOf(TUE4HdrStruct1) + BlockCount.Size +
                        SizeOf(TUE4BlkStruct1) * BlockCount +
                        SizeOf(TUE4FtrStruct1);
                    end;
                  end;
                2:
                  begin
                    BlockInfo :=
                      PUE4BlkStruct1(Input + Pos + SizeOf(TUE4HdrStruct2) +
                      SizeOf(BlockCount));
                    Checksum2 := @PUE4HdrStruct2(Input + Pos)^.Hash;
                    CompressionType := PUE4HdrStruct2(Input + Pos)
                      ^.CompressionType;
                    if CompressionType = 0 then
                    begin
                      if CompressedSize <> DecompressedSize then
                      begin
                        Inc(Pos);
                        continue;
                      end;
                      BlockCount := 0;
                      StreamPos := SizeOf(TUE4HdrStruct2) +
                        SizeOf(TUE4FtrStruct1);
                    end
                    else
                    begin
                      BlockCount :=
                        PInteger(Input + Pos + SizeOf(TUE4HdrStruct2))^;
                      StreamPos := SizeOf(TUE4HdrStruct2) + BlockCount.Size +
                        SizeOf(TUE4BlkStruct1) * BlockCount +
                        SizeOf(TUE4FtrStruct1);
                    end;
                  end;
              else
                begin
                  Inc(Pos);
                  continue;
                end;
              end;
              if InRange(Pos + StreamPos + CompressedSize, Pos, SizeEx) then
              begin
                BlockSize := PUE4FtrStruct1(Input + Pos + StreamPos -
                  SizeOf(TUE4FtrStruct1))^.BlockSize;
                if (PUE4FtrStruct1(Input + Pos + StreamPos -
                  SizeOf(TUE4FtrStruct1))^.Encrypted = 1) and
                  (InRange(BlockSize, 64, $00100000) or
                  (CompressionType = BlockSize)) then
                begin
                  if Funcs^.Hash('sha1', (Input + Pos + StreamPos),
                    CompressedSize, @Checksum1, SizeOf(Checksum1)) then
                    if CompareMem(@Checksum1, Checksum2, SizeOf(TSHA1Digest))
                    then
                    begin
                      Output(Instance, (Input + Pos + StreamPos),
                        CompressedSize);
                      SI.Position := Pos + StreamPos;
                      SI.OldSize := CompressedSize;
                      SI.NewSize := CompressedSize;
                      SI.Option := 0;
                      Add(Instance, @SI, nil, nil);
                      Inc(Pos, StreamPos + CompressedSize);
                      continue;
                    end;
                end;
              end;
            end;
            Inc(Pos);
          end;
        end;
    end;
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
  Result := Funcs^.Decrypt('aes', NewInput, StreamInfo^.NewSize, @KeyBytes[0],
    Length(KeyBytes));
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
  if Funcs^.Encrypt('aes', Buffer, StreamInfo.NewSize, @KeyBytes[0],
    Length(KeyBytes)) then
  begin
    Output(Instance, Buffer, StreamInfo.OldSize);
    Result := True;
  end;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1,
  PrecompScan2, PrecompProcess, PrecompRestore;

begin
  SetLength(CodecEnabled, Length(Codecs));

end.
