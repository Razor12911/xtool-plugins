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
  lz4_decode: function(src: Pointer; dst: Pointer; src_size: integer;
    dst_size: Int64; dst_lim: integer): integer cdecl;
  fcp_encode: function(unp_buf: Pointer; compr_buf: Pointer;
    uncompr_size: Cardinal; pout_compr_buf: PPointer; compr_lvl: Cardinal)
    : integer cdecl;

function DuniaDecompress(source: Pointer; dest: Pointer;
  compressedSize: integer; DecompressedSize: integer): integer;
var
  delta: Cardinal;
  dest_size_type2: Cardinal;
  next_src, targ: PByte;
begin
  dest_size_type2 := PByte(source)^;
  next_src := PByte(source) + 1;
  if dest_size_type2 >= $80 then
  begin
    dest_size_type2 := (PByte(next_src)^ shr 7) + dest_size_type2 - $80;
    next_src := PByte(source) + 2;
    if dest_size_type2 >= $4000 then
    begin
      dest_size_type2 := (PByte(next_src)^ shr 14) + dest_size_type2 - $4000;
      next_src := PByte(source) + 3;
      if dest_size_type2 >= $200000 then
      begin
        dest_size_type2 := (PByte(next_src)^ shr 21) + dest_size_type2
          - $200000;
        next_src := PByte(source) + 4;
      end;
    end;
  end;
  delta := (next_src - PByte(source));
  targ := PByte(dest) + DecompressedSize - compressedSize;
  Move(source^, targ^, compressedSize);
  Result := lz4_decode(targ + delta, dest, compressedSize - delta,
    DecompressedSize, DecompressedSize - dest_size_type2);
end;

const
  Codecs: array of PChar = ['lz4dunia'];

function PrecompInit(Command: PChar; Count: integer; Funcs: PPrecompFuncs)
  : Boolean cdecl;
begin
  Result := True;
end;

procedure PrecompFree(Funcs: PPrecompFuncs)cdecl;
begin

end;

function PrecompCodec(Index: integer): PChar cdecl;
begin
  Result := nil;
  if Index in [integer(Low(Codecs)), integer(High(Codecs))] then
    Result := Codecs[Index];
end;

procedure PrecompScan1(Instance: integer; Input: PByte; Size, SizeEx: Cardinal;
  Output: TPrecompOutput; Add: TPrecompAdd; Funcs: PPrecompFuncs)cdecl;
begin

end;

procedure ShowMessage(Msg: string; Caption: string = '');
begin
  MessageBox(0, PChar(Msg), PChar(Caption), MB_OK or MB_TASKMODAL);
end;

function PrecompScan2(Instance: integer; Input: Pointer; Size: Cardinal;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
  Res: integer;
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo^.NewSize);
  Res := Funcs^.Decompress('lz4hc', Input, StreamInfo^.OldSize, Buffer,
    StreamInfo^.NewSize, nil, 0);
  if Res = StreamInfo^.NewSize then
  begin
    Output(Instance, Buffer, Res);
    WordRec(StreamInfo^.Option).Lo := 0;
    Result := True;
  end
  else if Res < StreamInfo^.NewSize then
  begin
    Res := Funcs^.Decompress('lz4hc', PByte(Input) + 1, StreamInfo^.OldSize,
      Buffer, StreamInfo^.NewSize, nil, 0);
    if Res > StreamInfo^.OldSize then
    begin
      Output(Instance, Buffer, Res);
      WordRec(StreamInfo^.Option).Lo := 1;
      Result := True;
    end;
  end;
  { Res := DuniaDecompress(Input, Buffer, StreamInfo^.OldSize,
    StreamInfo^.NewSize);
    ShowMessage(Res.ToString);
    if InRange(Res, Max(64, StreamInfo^.NewSize - 128), StreamInfo^.NewSize) then
    begin
    StreamInfo^.NewSize := Res;
    Output(Instance, Buffer, Res);
    Result := True;
    end; }
end;

function PrecompProcess(Instance: integer; OldInput, NewInput: Pointer;
  StreamInfo: PStrInfo2; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
  Res1: integer;
  Res2: NativeUInt;
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo^.NewSize);
  Res1 := Funcs^.Compress('lz4hc:l9', NewInput, StreamInfo^.NewSize, Buffer,
    StreamInfo^.NewSize, nil, 0);
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
    Res2 := Funcs^.EncodePatch(Buffer, Res1, OldInput, StreamInfo^.OldSize,
      Buffer + Res1, Max(StreamInfo^.OldSize, Res1));
    if (Res2 > 0) and ((Res2 / Min(StreamInfo^.OldSize, Res1)) <= 0.05) then
    begin
      WordRec(StreamInfo^.Option).Hi := 1;
      Output(Instance, Buffer + Res1, Res2);
      Result := True;
    end;
  end;
end;

function PrecompRestore(Instance: integer; Input, InputExt: Pointer;
  StreamInfo: TStrInfo3; Output: TPrecompOutput; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  Buffer: PByte;
  Res1: integer;
  Res2: NativeUInt;
begin
  Result := False;
  Buffer := Funcs^.Allocator(Instance, StreamInfo.NewSize);
  Res1 := Funcs^.Compress('lz4hc:l9', Input, StreamInfo.NewSize, Buffer,
    StreamInfo.NewSize, nil, 0);
  if WordRec(StreamInfo.Option).Hi = 1 then
  begin
    Buffer := Funcs^.Allocator(Instance, Res1 + StreamInfo.OldSize);
    Res2 := Funcs^.DecodePatch(InputExt, StreamInfo.ExtSize, Buffer, Res1,
      Buffer + Res1, StreamInfo.OldSize);
    if (Res2 > 0) then
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

var
  DLLStream: TResourceStream;
  DLLHandle: TMemoryModule;

begin
  DLLStream := TResourceStream.Create(HInstance, 'DUNIA_DLL', RT_RCDATA);
  DLLHandle := MemoryLoadLibary(DLLStream.Memory);
  @lz4_decode := MemoryGetProcAddress(DLLHandle, 'lz4_decode');
  Assert(@lz4_decode <> nil);
  @fcp_encode := MemoryGetProcAddress(DLLHandle, 'fcp_encode');
  Assert(@fcp_encode <> nil);

end.
