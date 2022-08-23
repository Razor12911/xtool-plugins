library hpk;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas',
  lz4 in 'lz4.pas';

const
  Codecs: array of PChar = ['hpk'];
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

procedure PrecompScan1(Instance: Integer; Input: PByte; Size, SizeEx: Cardinal;
  Output: TPrecompOutput; Add: TPrecompAdd; Funcs: PPrecompFuncs)cdecl;
var
  Buffer: PByte;
  Pos: NativeInt;
  LSize: NativeInt;
  P: Integer;
  ISize, Block, Start: Integer;
  CSize, DSize: Integer;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - 12;
  while Pos < LSize do
  begin
    if (PInteger(Input + Pos)^ = $20345A4C) then
    begin
      P := 0;
      Inc(P, 4); // ident
      ISize := PInteger(Input + Pos + P)^;
      Inc(P, 4); // inflated size
      Block := PInteger(Input + Pos + P)^;
      Inc(P, 4); // block size
      if Block <= 524288 then
      begin
        Start := PInteger(Input + Pos + P)^ - $10;
        Inc(P, 4); // block start position
        Inc(P, Start);
        Buffer := Funcs^.Allocator(Instance, Block);
        while ISize > 0 do
        begin
          DSize := Min(ISize, Block);
          CSize := LZ4_decompress_generic((Input + Pos + P), Buffer, Block,
            DSize, Integer(endOnOutputSize), Integer(partial), 0,
            Integer(noDict), nil, nil, 0);
          if CSize <= 0 then
            break;
          if DSize > CSize then
          begin
            Output(Instance, Buffer, DSize);
            SI.Position := Pos + P;
            SI.OldSize := CSize;
            SI.NewSize := DSize;
            SI.Option := 0;
            Add(Instance, @SI, 'lz4hc:l9', nil);
          end;
          Inc(P, CSize);
          Dec(ISize, DSize);
        end;
        Inc(Pos, P);
        continue;
      end;
    end;
    Inc(Pos);
  end;

end;

function PrecompScan2(Instance: Integer; Input: Pointer; Size: Cardinal;
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
