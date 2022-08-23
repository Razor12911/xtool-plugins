library unity;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  Utils in 'Utils.pas';

const
  Codecs: array of PChar = ['unity'];

var
  Method: String;

function PrecompInit(Command: PChar; Count: Integer; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  I: Integer;
  S: String;
begin
  Method := '';
  S := Command;
  I := Pos(':', S);
  if I > 0 then
    Method := S.Substring(I);
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
  PStruct = ^TStruct;

  TStruct = packed record
    DecompressedSize, CompressedSize: Integer;
    Flags: SmallInt;
  end;
var
  Buffer: PByte;
  Pos: NativeInt;
  LSize: NativeInt;
  I: Integer;
  S: String;
  P1, P2: NativeInt;
  FullSize, I64: Int64;
  X, Y: Integer;
  FileVer, Flags, Count: Integer;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - 8;
  while Pos < LSize do
  begin
    if (PInteger(Input + Pos)^ = $74696E55) then
    begin
      P1 := 0;
      S := String(PAnsiChar(Input + Pos + P1));
      if S = 'UnityFS' then
      begin
        Inc(P1, Succ(Length(S)));
        FileVer := Funcs^.Swap32(PInteger(Input + Pos + P1)^);
        Inc(P1, Integer.Size);
        S := String(PAnsiChar(Input + Pos + P1));
        if S <> '5.x.x' then
        begin
          Inc(Pos);
          continue;
        end;
        Inc(P1, Succ(Length(S)));
        S := String(PAnsiChar(Input + Pos + P1));
        Inc(P1, Succ(Length(S)));
        FullSize := Funcs^.Swap64(PInt64(Input + Pos + P1)^);
        Inc(P1, Int64.Size);
        X := Funcs^.Swap32(PInteger(Input + Pos + P1)^);
        Inc(P1, Integer.Size);
        Y := Funcs^.Swap32(PInteger(Input + Pos + P1)^);
        Inc(P1, Integer.Size);
        Flags := Funcs^.Swap32(PInteger(Input + Pos + P1)^);
        Inc(P1, Integer.Size);
        if (Flags and $3F) in [2, 3] then
        begin
          if FileVer >= 7 then
            Inc(P1, 14);
          Buffer := Funcs^.Allocator(Instance, Y);
          if Funcs^.Decompress('lz4', (Input + Pos + P1), X, Buffer, Y, nil,
            0) = Y then
          begin
            Inc(P1, X);
            P2 := 16;
            Count := Funcs^.Swap32(PInteger(Buffer + P2)^);
            Inc(P2, Integer.Size);
            I64 := 0;
            for I := 0 to Count - 1 do
            begin
              Inc(I64, Funcs^.Swap32(PStruct(Buffer + P2)^.CompressedSize));
              Inc(P2, SizeOf(TStruct));
            end;
            P1 := FullSize - I64;
            P2 := 16;
            Inc(P2, Integer.Size);
            for I := 0 to Count - 1 do
            begin
              SI.Position := Pos + P1;
              SI.OldSize := Funcs^.Swap32(PStruct(Buffer + P2)^.CompressedSize);
              SI.NewSize := Funcs^.Swap32(PStruct(Buffer + P2)
                ^.DecompressedSize);
              if SI.NewSize > SI.OldSize then
              begin
                if Method <> '' then
                  Add(Instance, @SI, PChar(Method), nil)
                else if (Flags and $3F) = 3 then
                  Add(Instance, @SI, 'lz4hc', nil)
                else
                  Add(Instance, @SI, 'lz4', nil);
              end;
              Inc(P2, SizeOf(TStruct));
              Inc(P1, SI.OldSize);
            end;
            Inc(Pos, P1);
            continue;
          end
          else
          begin
            Inc(Pos);
            continue;
          end;
        end;
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

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1,
  PrecompScan2, PrecompProcess, PrecompRestore;

begin

end.
