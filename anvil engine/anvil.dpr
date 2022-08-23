library anvil;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  Utils in 'Utils.pas';

const
  Codecs: array of PChar = ['anvil'];

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
  Header = $1004FA9957FBAA33;
var
  Pos: NativeInt;
  LSize: NativeInt;
  I: Integer;
  X, Y: Integer;
  P1, P2: NativeInt;
  C: Integer;
  SI: TStrInfo1;
begin
  Pos := 0;
  LSize := Size - 16;
  while Pos < LSize do
  begin
    if (PInt64(Input + Pos)^ = Header) then
    begin
      P1 := 15;
      if PWord(Input + Pos + 17)^ > 0 then
        C := PSmallInt(Input + Pos + 15)^
      else
        C := PInteger(Input + Pos + 15)^;
      P2 := P1;
      case PSmallInt(Input + Pos + 8)^ of
        1:
          begin
            if PWord(Input + Pos + 17)^ = 0 then
              Inc(P1, Word.Size);
            for Y := 0 to C - 1 do
              Inc(P1, Integer.Size);
            Inc(P1, Word.Size);
          end;
        2, 3:
          begin
            for Y := 0 to C - 1 do
              Inc(P1, Int64.Size);
            Inc(P1, Integer.Size);
          end;
      end;
      if PWord(Input + Pos + 17)^ = 0 then
        case PSmallInt(Input + Pos + 8)^ of
          1:
            Inc(P2, Word.Size);
        end;
      for Y := 0 to C - 1 do
      begin
        Inc(P1, Integer.Size);
        case PSmallInt(Input + Pos + 8)^ of
          1:
            begin
              Inc(P2, Word.Size);
              SI.NewSize := PWord(Input + Pos + P2)^;
              Inc(P2, Word.Size);
              SI.OldSize := PWord(Input + Pos + P2)^;
            end;
          2, 3:
            begin
              Inc(P2, Integer.Size);
              SI.NewSize := PInteger(Input + Pos + P2)^;
              Inc(P2, Integer.Size);
              SI.OldSize := PInteger(Input + Pos + P2)^;
            end;
        end;
        if SI.NewSize > SI.OldSize then
          if PByte(Input + Pos + 10)^ in [0, 1, 2, 5, 8] then
          begin
            SI.Position := Pos + P1;
            SI.Resource := 0;
            SI.Option := 0;
            case PByte(Input + Pos + 10)^ of
              0, 1:
                Add(Instance, @SI, 'lzo1x', nil);
              2:
                Add(Instance, @SI, 'lzo2a', nil);
              5:
                Add(Instance, @SI, 'lzo1c', nil);
              8:
                if PSmallInt(Input + Pos + 8)^ = 2 then
                  Add(Instance, @SI, 'mermaid:l6', nil)
                else
                  Add(Instance, @SI, 'mermaid:l7', nil);
            end;
          end;
        Inc(P1, SI.OldSize);
      end;
      Inc(Pos, P1);
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
