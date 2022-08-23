library madness;

{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$POINTERMATH ON}

uses
  System.SysUtils,
  System.Math,
  System.ZLib,
  Utils in 'Utils.pas';

function EndianSwap(A: Single): Single overload;
var
  C: array [0 .. 3] of Byte absolute Result;
  d: array [0 .. 3] of Byte absolute A;
begin
  C[0] := d[3];
  C[1] := d[2];
  C[2] := d[1];
  C[3] := d[0];
end;

function EndianSwap(A: double): double overload;
var
  C: array [0 .. 7] of Byte absolute Result;
  d: array [0 .. 7] of Byte absolute A;
begin
  C[0] := d[7];
  C[1] := d[6];
  C[2] := d[5];
  C[3] := d[4];
  C[4] := d[3];
  C[5] := d[2];
  C[6] := d[1];
  C[7] := d[0];
end;

{$IFDEF PUREPASCAL}

function EndianSwap(A: Int64): Int64 overload;
asm
  {$IF DEFINED(CPUX64)}
  .NOFRAME
  {$IFDEF win64}
  mov rax, rcx
  {$ELSE}
  mov rax, rdi
  {$ENDIF win64}
  bswap rax
  {$ELSE}
  mov edx, A.Int64Rec.Lo
  mov eax, A.Int64Rec.Hi
  bswap edx
  bswap eax
  {$ENDIF}
end;

function EndianSwap(A: UInt64): UInt64 overload;
asm
  {$IF DEFINED(CPUX64)}
  .NOFRAME
  {$IFDEF win64}
  mov rax, rcx
  {$ELSE}
  mov rax, rdi
  {$ENDIF win64}
  bswap rax
  {$ELSE}
  mov edx, A.Int64Rec.Lo
  mov eax, A.Int64Rec.Hi
  bswap edx
  bswap eax
  {$ENDIF}
end;

function EndianSwap(A: Int32): Int32 overload;
asm
  {$IF DEFINED(CPUX64)}
  .NOFRAME
  {$IF DEFINED(WIN64)}
  mov eax, ecx
  {$ELSE}
  mov eax, edi
  {$ENDIF}
  bswap eax
  {$ELSEIF DEFINED(CPUX86)}
  bswap eax
  {$ENDIF}
end;

function EndianSwap(A: UInt32): UInt32 overload;
asm
  {$IF DEFINED(CPUX64)}
  .NOFRAME
  {$IF DEFINED(WIN64)}
  mov eax, ecx
  {$ELSE}
  mov eax, edi
  {$ENDIF}
  bswap eax
  {$ELSEIF DEFINED(CPUX86)}
  bswap eax
  {$ENDIF}
end;

function EndianSwap(A: Int16): Int16 overload;
asm
  {$IF DEFINED(CPUX64)}
  .NOFRAME
  {$IF DEFINED(WIN64)}
  mov ax, cx
  {$ELSE}
  mov ax, di
  {$ENDIF}
  rol ax,8
  {$ELSEIF DEFINED(CPUX86)}
  rol ax,8
  {$ENDIF}
end;

function EndianSwap(A: UInt16): UInt16 overload;
asm
  {$IF DEFINED(CPUX64)}
  .NOFRAME
  {$IF DEFINED(WIN64)}
  mov ax, cx
  {$ELSE}
  mov ax, di
  {$ENDIF}
  rol ax,8
  {$ELSEIF DEFINED(CPUX86)}
  rol ax,8
  {$ENDIF}
end;

{$ELSE}

function EndianSwap(A: Int64): Int64 overload;
var
  C: array [0 .. 7] of Byte absolute Result;
  d: array [0 .. 7] of Byte absolute A;
begin
  C[0] := d[7];
  C[1] := d[6];
  C[2] := d[5];
  C[3] := d[4];
  C[4] := d[3];
  C[5] := d[2];
  C[6] := d[1];
  C[7] := d[0];
end;

function EndianSwap(A: UInt64): UInt64 overload;
var
  C: array [0 .. 7] of Byte absolute Result;
  d: array [0 .. 7] of Byte absolute A;
begin
  C[0] := d[7];
  C[1] := d[6];
  C[2] := d[5];
  C[3] := d[4];
  C[4] := d[3];
  C[5] := d[2];
  C[6] := d[1];
  C[7] := d[0];
end;

function EndianSwap(A: Int32): Int32 overload;
var
  C: array [0 .. 3] of Byte absolute Result;
  d: array [0 .. 3] of Byte absolute A;
begin
  C[0] := d[3];
  C[1] := d[2];
  C[2] := d[1];
  C[3] := d[0];
end;

function EndianSwap(A: UInt32): UInt32 overload;
var
  C: array [0 .. 3] of Byte absolute Result;
  d: array [0 .. 3] of Byte absolute A;
begin
  C[0] := d[3];
  C[1] := d[2];
  C[2] := d[1];
  C[3] := d[0];
end;

function EndianSwap(A: Int16): Int16 overload;
var
  C: array [0 .. 1] of Byte absolute Result;
  d: array [0 .. 1] of Byte absolute A;
begin
  C[0] := d[1];
  C[1] := d[0];
end;

function EndianSwap(A: UInt16): UInt16 overload;
var
  C: array [0 .. 1] of Byte absolute Result;
  d: array [0 .. 1] of Byte absolute A;
begin
  C[0] := d[1];
  C[1] := d[0];
end;
{$ENDIF}

function IsValidZLib(ZStream: z_streamp; Input: PByte; Size: Integer): Boolean;
const
  BuffSize = 65536;
var
  Buff: array [0 .. BuffSize - 1] of Byte;
  Res: Integer;
begin
  Result := False;
  ZStream^.next_in := Input;
  ZStream^.avail_in := Size;
  ZStream^.next_out := @Buff[0];
  ZStream^.avail_out := BuffSize;
  inflateReset(ZStream^);
  Res := inflate(ZStream^, Z_SYNC_FLUSH);
  if (Res in [Z_OK, Z_STREAM_END]) then
  begin
    while Res <> Z_STREAM_END do
    begin
      ZStream^.next_out := @Buff[0];
      ZStream^.avail_out := BuffSize;
      Res := inflate(ZStream^, Z_SYNC_FLUSH);
      if not(Res in [Z_OK, Z_STREAM_END]) then
        break;
    end;
  end;
  Result := ZStream^.total_in = Size;
end;

function GetZLibSize(ZStream: z_streamp; Input: PByte; Size: Integer): Integer;
const
  BuffSize = 4096;
var
  Buff: array [0 .. BuffSize - 1] of Byte;
  Res: Integer;
begin
  Result := 0;
  ZStream^.next_in := Input;
  ZStream^.avail_in := Size;
  ZStream^.next_out := @Buff[0];
  ZStream^.avail_out := BuffSize;
  inflateReset(ZStream^);
  Res := inflate(ZStream^, Z_SYNC_FLUSH);
  if (Res in [Z_OK, Z_STREAM_END]) then
  begin
    while Res <> Z_STREAM_END do
    begin
      ZStream^.next_out := @Buff[0];
      ZStream^.avail_out := BuffSize;
      Res := inflate(ZStream^, Z_SYNC_FLUSH);
      if Res = Z_OK then
        Result := -Integer(ZStream^.total_in);
      if not(Res in [Z_OK, Z_STREAM_END]) then
        exit;
    end;
    Result := ZStream^.total_in;
  end;
end;

type
  POodleSI = ^TOodleSI;

  TOodleSI = record
    CSize, DSize: Integer;
    Codec: Integer;
    HasCRC: Boolean;
  end;

procedure GetOodleSI(Buff: PByte; Size: Integer; StreamInfo: POodleSI;
  MaxBlocks: Integer = Integer.MaxValue; First: Boolean = True);
const
  MinSize = 64;
  BlkSize = 262144;
var
  I, J, K: Integer;
  Compressed: Boolean;
begin
  if MaxBlocks <= 0 then
    exit;
  I := 0;
  if First then
  begin
    StreamInfo^.CSize := 0;
    StreamInfo^.DSize := 0;
    StreamInfo^.Codec := 0;
    StreamInfo^.HasCRC := False;
    if Size < 8 then
      exit;
    if ((Buff^ in [$8C, $CC]) = False) then
      exit;
    Compressed := Buff^ = $8C;
    if Compressed then
    begin
      case (Buff + 1)^ of
        { $02:
          if not(((Buff + 2)^ shr 4 = 0) and (((Buff + 4)^ shr 4 = $F) or
          ((Buff + 4)^ and $F = $F))) then
          exit; }
        $06, $0A, $0C:
          begin
            I := EndianSwap(PInteger(Buff + 2)^) shr 8 + 6;
            J := ((EndianSwap(PInteger(Buff + 5)^) shr 8) and $7FFFF) + 8;
            if I > J then
            begin
              K := ((EndianSwap(PInteger(Buff + J)^) shr 8) and $7FFFF) + 3;
              if I <> (J + K) then
                exit;
            end
            else if I <> J then
              exit;
          end;
        $86, $8A, $8C:
          begin
            StreamInfo^.HasCRC := True;
            I := EndianSwap(PInteger(Buff + 2)^) shr 8 + 9;
            J := ((EndianSwap(PInteger(Buff + 8)^) shr 8) and $7FFFF) + 11;
            if I > J then
            begin
              K := ((EndianSwap(PInteger(Buff + J)^) shr 8) and $7FFFF) + 3;
              if I <> (J + K) then
                exit;
            end
            else if I <> J then
              exit;
          end;
      else
        exit;
      end;
    end
    else
    begin
      if not(Buff + 1)^ in [ { $02, } $06, $0A, $0C] then
        exit;
    end;
    case (Buff + 1)^ of
      { $02:
        StreamInfo^.Codec := 0; // Old oodle }
      $06, $86:
        StreamInfo^.Codec := 1; // Kraken
      $0A, $8A:
        StreamInfo^.Codec := 2; // Mermaid/Selkie
      $0C, $8C:
        StreamInfo^.Codec := 3; // Leviathan
    end;
  end
  else
  begin
    if not(Buff^ in [$0C, $4C]) then
      exit;
    Compressed := Buff^ = $0C;
    if Compressed then
    begin
      case (Buff + 1)^ of
        { $02:
          if not(((Buff + 2)^ shr 4 = 0) and (((Buff + 4)^ shr 4 = $F) or
          ((Buff + 4)^ and $F = $F))) then
          exit; }
        $06, $0A, $0C:
          if not(Buff + 5)^ shr 4 in [3, 8] then
            exit;
        $86, $8A, $8C:
          if not(Buff + 8)^ shr 4 in [3, 8] then
            exit;
      end;
    end
    else
    begin
      if not(Buff + 1)^ in [$06, $0A, $0C] then
        exit;
    end;
  end;
  if Compressed then
  begin
    case (Buff + 1)^ of
      { $02:
        I := EndianSwap(PWord(Buff + 2)^) + 5; }
      $06, $0A, $0C:
        I := EndianSwap(PInteger(Buff + 2)^) shr 8 + 6;
      $86, $8A, $8C:
        I := EndianSwap(PInteger(Buff + 2)^) shr 8 + 9;
    else
      exit;
    end;
    if First and (I < MinSize) then
      exit;
    if StreamInfo^.CSize + I > Size then
    begin
      StreamInfo^.CSize := 0;
      StreamInfo^.DSize := 0;
      exit;
    end;
    if I = $00080005 then
      I := 6;
    Inc(StreamInfo^.CSize, I);
    Inc(StreamInfo^.DSize, BlkSize);
    Dec(MaxBlocks);
    GetOodleSI(Buff + I, Size, StreamInfo, MaxBlocks, False);
  end
  else
  begin
    case (Buff + 1)^ of
      $06, $0A, $0C:
        begin
          if StreamInfo^.CSize + BlkSize + 2 <= Size then
          begin
            if (PWord(Buff + BlkSize + 2)^ = (((Buff + 1)^ shl 8) + $4C)) or
              ((First = True) and ((Buff + BlkSize + 2)^ in [$0C, $4C])) then
            begin
              Inc(StreamInfo^.CSize, BlkSize + 2);
              Inc(StreamInfo^.DSize, BlkSize);
            end;
          end
          else
            I := BlkSize + 2 - Size;
          if StreamInfo^.CSize + I > Size then
          begin
            StreamInfo^.CSize := 0;
            StreamInfo^.DSize := 0;
            exit;
          end;
          Inc(StreamInfo^.CSize, Abs(I));
          Inc(StreamInfo^.DSize, Abs(I) - 2);
          Dec(MaxBlocks);
          if I > 0 then
            GetOodleSI(Buff + I, Size, StreamInfo, MaxBlocks, False);
        end;
    else
      exit;
    end;
  end;
end;

type
  TEncryptedHdrs = array of array of Word;

  TStartPos = record
    Count: Integer;
    Positions: array of NativeInt;
  end;

const
  Codecs: array of PChar = ['madness'];
  ZlibHeader = $9C78;
  OodleHeader = $068C;
  Keys: array of PAnsiChar = ['N5[Z)XD^w{1u_b]?2@HTA4',
    'VbU4H!GZfYVdXAY+6(muS4', 'vNva6iM!Cj3DWbVf0OKA0v',
    '5B{7NUE~)Q-e+8V%HA24*i', 'OdcerxQtQJIbxoLBKV7pPe',
    'dGfOiCdfS2MlHVUzyzcHIe', 'Pjr6*b6#*?qw{LqzO?1HS$',
    'Ekkug2CwAhYQJ2hvnpFsB1', 'ZugTkzkOXWoYTvqXpDLJtn',
    '5RHFHER9G72eQGlkxhFMln', '0hwDZ1$s(yPZ]t@BLDJVq8',
    '}Z.c+lk%3jY8p4QC0_2`x6', '4AmRyL4lJJcBVs7r6vjOvW',
    'WK8wQXRqWpSwGYZCSxxIvo', 'yX#jkHDet]t?*3SMniL68!',
    '9x+Q0xg+v69.f|b-PKD2kD', 'Fk|?mR[1QDfK6(r$-*y]{b',
    'EVjo6FF{6Qdp[w|_,f`KV$]'];

var
  Hdrs: TEncryptedHdrs;
  SPos: array of TStartPos;
  ZStream: array of z_stream;

function PrecompInit(Command: PChar; Count: Integer; Funcs: PPrecompFuncs)
  : Boolean cdecl;
var
  I: Integer;
begin
  SetLength(Hdrs, 2, Length(Keys));
  for I := Low(Keys) to High(Keys) do
  begin
    Hdrs[0][I] := ZlibHeader;
    Hdrs[1][I] := OodleHeader;
    Funcs^.Encrypt('rc4', @Hdrs[0][I], Hdrs[0][I].Size, @Keys[I][0],
      Length(Keys[I]));
    Funcs^.Encrypt('rc4', @Hdrs[1][I], Hdrs[1][I].Size, @Keys[I][0],
      Length(Keys[I]));
  end;
  SetLength(SPos, Count);
  for I := Low(SPos) to High(SPos) do
  begin
    SPos[I].Count := 0;
    SetLength(SPos[I].Positions, 0);
  end;
  SetLength(ZStream, Count);
  for I := Low(ZStream) to High(ZStream) do
  begin
    FillChar(ZStream[I], SizeOf(z_stream), 0);
    inflateInit(ZStream[I]);
  end;
  Result := True;
end;

procedure PrecompFree(Funcs: PPrecompFuncs)cdecl;
var
  I: Integer;
begin
  for I := Low(ZStream) to High(ZStream) do
    inflateEnd(ZStream[I]);
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
  MinSize = 256;
var
  Buffer: PByte;
  Pos, EndPos: NativeInt;
  LSize, SSize: NativeInt;
  Res: Integer;
  I, J: Integer;
  X, Y: Integer;
  Found: Boolean;
  SI: TStrInfo1;
begin
  for I := 0 to 0 do
    for J := Low(Hdrs[I]) to High(Hdrs[I]) do
    begin
      Pos := 0;
      LSize := Size - MinSize;
      SPos[Instance].Count := 0;
      while Pos < LSize do
      begin
        if PWord(Input + Pos)^ = Hdrs[I][J] then
        begin
          Found := False;
          EndPos := Pos + 16;
          X := Pos mod 16;
          Buffer := Funcs^.Allocator(Instance, MinSize);
          Move((Input + Pos)^, Buffer^, MinSize);
          Funcs^.Decrypt('rc4', Buffer, MinSize, @Keys[J][0], Length(Keys[J]));
          if IsValidZLib(@ZStream[Instance], Buffer, MinSize) then
          begin
            Inc(SPos[Instance].Count);
            if Length(SPos[Instance].Positions) < SPos[Instance].Count then
              Insert(Pos, SPos[Instance].Positions,
                Length(SPos[Instance].Positions))
            else
              SPos[Instance].Positions[Pred(SPos[Instance].Count)] := Pos;
          end;
        end;
        Inc(Pos);
      end;
      for X := 0 to SPos[Instance].Count - 1 do
      begin
        if X = SPos[Instance].Count - 1 then
          SSize := SizeEx - SPos[Instance].Positions[X]
        else
          SSize := SPos[Instance].Positions[Succ(X)] - SPos[Instance]
            .Positions[X];
        Buffer := Funcs^.Allocator(Instance, SSize);
        Move((Input + SPos[Instance].Positions[X])^, Buffer^, SSize);
        Funcs^.Decrypt('rc4', Buffer, SSize, @Keys[J][0], Length(Keys[J]));
        Res := GetZLibSize(@ZStream[Instance], Buffer, SSize);
        if Res >= MinSize then
        begin
          Output(Instance, Buffer, Res);
          SI.Position := SPos[Instance].Positions[X];
          SI.OldSize := Res;
          SI.NewSize := Res;
          SI.Option := J;
          Add(Instance, @SI, nil, nil);
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
  Result := True;
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
  if Funcs^.Encrypt('rc4', Buffer, StreamInfo.NewSize,
    @Keys[StreamInfo.Option][0], Length(Keys[StreamInfo.Option])) then
  begin
    Output(Instance, Buffer, StreamInfo.OldSize);
    Result := True;
  end;
end;

exports PrecompInit, PrecompFree, PrecompCodec, PrecompScan1,
  PrecompScan2, PrecompProcess, PrecompRestore;

begin

end.
