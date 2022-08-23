library bsa;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas';

const
  Codecs: array of PChar = ['skyrim'];
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
const
  BSAARCHIVE_PATHNAMES = $0001;
  BSAARCHIVE_FILENAMES = $0002;
  BSAARCHIVE_COMPRESSFILES = $0004;
  BSAARCHIVE_BIGENDIAN = $0040;
  BSAARCHIVE_PREFIXFULLFILENAMES = $0100;
  BSAARCHIVE_XMEMCODEC = $0200;

type
  PStruct1 = ^TStruct1;

  TStruct1 = packed record
    FolderRecordOffset, ArchiveFlags, FolderCount, FileCount: Cardinal;
    totalFolderNameLength, totalFileNameLength, FileFlags: Cardinal;
  end;

  PStruct2 = ^TStruct2;

  TStruct2 = packed record
    Hash: Int64;
    Count, offset: Int64;
  end;

  PStruct3 = ^TStruct3;

  TStruct3 = packed record
    Hash: Int64;
    Count, offset: Cardinal;
  end;

  PStruct4 = ^TStruct4;

  TStruct4 = packed record
    Hash: Int64;
    Size, offset: Cardinal;
  end;

var
  Pos: NativeInt;
  LSize: NativeInt;
  I, J, X: Integer;
  FOLDERS_SIZE, FolderFilePos, FolderFileBlob, EndOfDirectory,
    FileNamePos: Integer;
  LStruct1: TStruct1;
  PtrStruct1, PtrStruct2: PByte;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - 36;
  while Pos < LSize do
  begin
    if (PInteger(Input + Pos)^ = $00415342) and
      (PInteger(Input + Pos + 4)^ > $67) then
    begin
      LStruct1 := PStruct1(Input + Pos + 8)^;
      if (LStruct1.ArchiveFlags and BSAARCHIVE_BIGENDIAN = BSAARCHIVE_BIGENDIAN)
        or (LStruct1.ArchiveFlags and
        BSAARCHIVE_XMEMCODEC = BSAARCHIVE_XMEMCODEC) then
      begin
        Inc(Pos);
        continue;
      end;
      FOLDERS_SIZE := 8 + 4 + 4;
      if PInteger(Input + Pos + 4)^ >= $69 then
        FOLDERS_SIZE := 8 + 8 + 8;
      FolderFilePos := LStruct1.FolderRecordOffset + LStruct1.FolderCount *
        FOLDERS_SIZE;
      FolderFileBlob := LStruct1.FolderCount * 1 +
        LStruct1.totalFolderNameLength + LStruct1.FileCount * (8 + 4 + 4);
      EndOfDirectory := LStruct1.FolderCount * FOLDERS_SIZE + FolderFileBlob +
        LStruct1.totalFileNameLength;
      FileNamePos := EndOfDirectory - LStruct1.totalFileNameLength;
      Inc(FileNamePos, LStruct1.FolderRecordOffset);
      PtrStruct1 := Input + Pos + LStruct1.FolderRecordOffset;
      PtrStruct2 := Input + Pos + FolderFilePos;
      if (LStruct1.ArchiveFlags and
        BSAARCHIVE_COMPRESSFILES = BSAARCHIVE_COMPRESSFILES) then
        for I := 0 to LStruct1.FolderCount - 1 do
        begin
          if LStruct1.ArchiveFlags and BSAARCHIVE_PATHNAMES = BSAARCHIVE_PATHNAMES
          then
            Inc(PtrStruct2, Succ(PtrStruct2^));
          if FOLDERS_SIZE = SizeOf(TStruct2) then
            X := (PStruct2(PtrStruct1) + I)^.Count
          else
            X := (PStruct3(PtrStruct1) + I)^.Count;
          for J := 0 to X - 1 do
          begin
            SI.Position := Pos + (PStruct4(PtrStruct2) + J)^.offset;
            SI.OldSize := (PStruct4(PtrStruct2) + J)^.Size;
            SI.NewSize := (PStruct4(PtrStruct2) + J)^.Size;
            WordRec(SI.Option).Bytes[0] := PByte(Input + Pos + 4)^;
            WordRec(SI.Option).Bytes[1] := 0;
            if (LStruct1.ArchiveFlags and
              BSAARCHIVE_FILENAMES = BSAARCHIVE_FILENAMES) and
              (LStruct1.ArchiveFlags and
              BSAARCHIVE_PREFIXFULLFILENAMES = BSAARCHIVE_PREFIXFULLFILENAMES)
            then
              WordRec(SI.Option).Bytes[1] := 1;
            Add(Instance, @SI, '', nil);
          end;
          Inc(PtrStruct2, X * SizeOf(TStruct4));
        end;
    end;
    Inc(Pos);
  end;
end;

function PrecompScan2(Instance: Integer; Input: Pointer; Size: NativeInt;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
type
  TDummyBytes = array [0 .. 10] of Byte;
var
  Buffer: PByte;
  Ptr: PByte;
  CSize, DSize: Integer;
begin
  Result := False;
  Ptr := Input;
  StreamInfo^.NewSize := 0;
  if WordRec(StreamInfo^.Option).Bytes[1] = 1 then
  begin
    Output(Instance, Ptr, Succ(Ptr^));
    Inc(StreamInfo^.NewSize, Succ(Ptr^));
    Inc(Ptr, Succ(Ptr^));
  end;
  DSize := PInteger(Ptr)^;
  Output(Instance, PInteger(Ptr), SizeOf(Integer));
  Inc(StreamInfo^.NewSize, SizeOf(Integer));
  Inc(Ptr, SizeOf(Integer));
  if WordRec(StreamInfo^.Option).Bytes[0] >= $69 then
  begin
    Output(Instance, Ptr, SizeOf(TDummyBytes));
    Inc(StreamInfo^.NewSize, SizeOf(TDummyBytes));
    Inc(Ptr, SizeOf(TDummyBytes));
  end;
  Buffer := Funcs^.Allocator(Instance, DSize);
  CSize := StreamInfo^.OldSize - Integer(Ptr - PByte(Input)) - SizeOf(Integer);
  if Funcs^.Decompress('lz4hc', Ptr, CSize, Buffer, DSize, nil, 0) = DSize then
  begin
    StreamInfo^.Option := Ptr - PByte(Input);
    Output(Instance, Buffer, DSize);
    Inc(StreamInfo^.NewSize, DSize);
    Inc(Ptr, CSize);
    Output(Instance, Ptr, SizeOf(Integer));
    Inc(StreamInfo^.NewSize, SizeOf(Integer));
    Inc(Ptr, SizeOf(Integer));
    Result := True;
  end;
end;

function PrecompProcess(Instance: Integer; OldInput, NewInput: Pointer;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
  Res1: Integer;
  Res2: NativeUInt;
  CSize, DSize: Integer;
begin
  Result := False;
  CSize := StreamInfo^.OldSize - StreamInfo^.Option - SizeOf(Integer);
  DSize := StreamInfo^.NewSize - StreamInfo^.Option - SizeOf(Integer);
  Buffer := Funcs^.Allocator(Instance, DSize);
  Res1 := Funcs^.Compress('lz4hc:l9', PByte(NewInput) + StreamInfo^.Option,
    DSize, Buffer, DSize, nil, 0);
  Result := (Res1 = CSize) and CompareMem(PByte(OldInput) + StreamInfo^.Option,
    Buffer, CSize);
  if Result then
    exit;
  if Result = False then
  begin
    Buffer := Funcs^.Allocator(Instance, Res1 + Max(CSize, Res1));
    Res2 := Funcs^.EncodePatch(Buffer, Res1,
      PByte(OldInput) + StreamInfo^.Option, CSize, Buffer + Res1,
      Max(CSize, Res1));
    if (Res2 > 0) and ((Res2 / Min(CSize, Res1)) <= 0.05) then
    begin
      StreamInfo^.Option := StreamInfo^.Option or 32768;
      Output(Instance, Buffer + Res1, Res2);
      Result := True;
    end;
  end;
end;

function PrecompRestore(Instance: Integer; Input, InputExt: Pointer;
  StreamInfo: TStrInfo3; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
  Res1: Integer;
  Res2: NativeUInt;
  CSize, DSize: Integer;
  HSize: Integer;
begin
  Result := False;
  if StreamInfo.Option >= 32768 then
    HSize := StreamInfo.Option xor 32768
  else
    HSize := StreamInfo.Option;
  CSize := StreamInfo.OldSize - HSize - SizeOf(Integer);
  DSize := StreamInfo.NewSize - HSize - SizeOf(Integer);
  Buffer := Funcs^.Allocator(Instance, DSize);
  Res1 := Funcs^.Compress('lz4hc:l9', PByte(Input) + HSize, DSize, Buffer,
    DSize, nil, 0);
  if StreamInfo.Option and 32768 = 32768 then
  begin
    Buffer := Funcs^.Allocator(Instance, Res1 + CSize);
    Res2 := Funcs^.DecodePatch(InputExt, StreamInfo.ExtSize, Buffer, Res1,
      Buffer + Res1, CSize);
    if (Res2 > 0) then
    begin
      Output(Instance, Input, HSize);
      Output(Instance, Buffer + Res1, CSize);
      Output(Instance, PByte(Input) + HSize + DSize, SizeOf(Integer));
      Result := True;
    end;
    exit;
  end;
  if Res1 = CSize then
  begin
    Output(Instance, Input, HSize);
    Output(Instance, Buffer, CSize);
    Output(Instance, PByte(Input) + HSize + DSize, SizeOf(Integer));
    Result := True;
  end;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1, PrecompScan2,
  PrecompProcess, PrecompRestore;

begin

end.
