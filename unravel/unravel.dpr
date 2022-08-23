library unravel;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas',
  LZ4DLL in 'LZ4DLL.pas';

function UnravelEncode(InBuff: Pointer; InSize: Integer; OutBuff: Pointer;
  OutSize: Integer): Integer;
const
  BlockSize = 65536;
var
  Ctx: PLZ4_streamHC_t;
  Pos1, Pos2, Res: Integer;
  X, Y: Integer;
begin
  Result := 0;
  Ctx := LZ4_createStreamHC;
  LZ4_resetStreamHC(Ctx, 9);
  Pos1 := 0;
  Pos2 := 0;
  try
    while (Pos1 < InSize) do
    begin
      X := Min(InSize - Pos1, BlockSize);
      Y := OutSize - (Pos2 + Integer.Size);
      Res := LZ4_compress_HC_continue(Ctx, PByte(InBuff) + Pos1,
        PByte(OutBuff) + Pos2 + Integer.Size, X, Y);
      if Res <= 0 then
      begin
        LZ4_freeStreamHC(Ctx);
        exit(-Pos2);
      end;
      PInteger(PByte(OutBuff) + Pos2)^ := Res;
      Inc(Pos1, X);
      Inc(Pos2, Res + Integer.Size);
    end;
  finally
    LZ4_freeStreamHC(Ctx);
  end;
  Result := Pos2;
end;

function UnravelDecode(InBuff: Pointer; InSize: Integer; OutBuff: Pointer;
  OutSize: Integer): Integer;
const
  BlockSize = 65536;
var
  Ctx: PLZ4_streamDecode_t;
  Pos1, Pos2, Res: Integer;
begin
  Result := 0;
  Ctx := LZ4_createStreamDecode;
  Pos1 := 0;
  Pos2 := 0;
  try
    while (Pos1 < InSize) and (Pos2 < OutSize) do
    begin
      Res := LZ4_decompress_safe_continue(Ctx, PByte(InBuff) + Pos1 +
        Integer.Size, PByte(OutBuff) + Pos2, PInteger(PByte(InBuff) + Pos1)^,
        Min(OutSize - Pos2, BlockSize));
      if Res <= 0 then
      begin
        LZ4_freeStreamDecode(Ctx);
        exit(-Pos2);
      end;
      Inc(Pos1, PInteger(PByte(InBuff) + Pos1)^ + Integer.Size);
      Inc(Pos2, Res);
    end;
  finally
    LZ4_freeStreamDecode(Ctx);
  end;
  Result := Pos2;
end;

const
  Codecs: array of PChar = ['unravel'];

function PrecompInit(Command: PChar; Count: Integer; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := LZ4DLL.DLLLoaded;
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
begin

end;

function PrecompScan2(Instance: Integer; Input: Pointer; Size: NativeInt;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
  Res: Integer;
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo^.NewSize);
  Res := UnravelDecode(Input, StreamInfo^.OldSize, Buffer, StreamInfo^.NewSize);
  if Res = StreamInfo^.NewSize then
  begin
    Output(Instance, Buffer, StreamInfo^.NewSize);
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
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo^.NewSize);
  Res1 := UnravelEncode(NewInput, StreamInfo^.NewSize, Buffer,
    StreamInfo^.NewSize);
  Result := (Res1 = StreamInfo^.OldSize) and CompareMem(OldInput, Buffer,
    StreamInfo^.OldSize);
  if Result then
  begin
    StreamInfo^.Option := 0;
    exit;
  end;
  if Result = False then
  begin
    Buffer := Funcs^.Allocator(Instance, Res1 + Max(StreamInfo^.OldSize, Res1));
    Res2 := Funcs^.EncodePatch(OldInput, StreamInfo^.OldSize, Buffer, Res1,
      Buffer + Res1, Max(StreamInfo^.OldSize, Res1));
    if (Res2 > 0) and ((Res2 / Max(StreamInfo^.OldSize, Res1)) <= 0.05) then
    begin
      Output(Instance, Buffer + Res1, Res2);
      StreamInfo^.Option := 1;
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
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo.NewSize);
  Res1 := UnravelEncode(Input, StreamInfo.NewSize, Buffer, StreamInfo.NewSize);
  if StreamInfo.Option = 1 then
  begin
    Buffer := Funcs^.Allocator(Instance, Res1 + StreamInfo.OldSize);
    Res2 := Funcs^.DecodePatch(InputExt, StreamInfo.ExtSize, Buffer, Res1,
      Buffer + Res1, StreamInfo.OldSize);
    if Res2 > 0 then
    begin
      Output(Instance, Buffer + Res1, StreamInfo.OldSize);
      Result := True;
    end;
    exit;
  end;
  if Res1 = StreamInfo.OldSize then
  begin
    Output(Instance, Buffer, StreamInfo.OldSize);
    Result := True;
  end;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1, PrecompScan2,
  PrecompProcess, PrecompRestore;

begin

end.
