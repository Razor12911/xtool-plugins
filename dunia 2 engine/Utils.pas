unit Utils;

interface

const
  PRECOMP_FCOUNT = 128;

type
  PPrecompStr = ^TPrecompStr;

  TPrecompStr = array [0 .. 255] of Char;

  PDepthInfo = ^TDepthInfo;

  TDepthInfo = packed record
    Codec: array [0 .. 31] of Char;
    OldSize: Integer;
    NewSize: Integer;
  end;

  PStrInfo1 = ^TStrInfo1;

  TStrInfo1 = packed record
    Position: Int64;
    OldSize, NewSize: Integer;
    Resource: Integer;
    Option: Word;
  end;

  PStrInfo2 = ^TStrInfo2;

  TStrInfo2 = packed record
    OldSize, NewSize: Integer;
    Resource: Integer;
    Option: Word;
  end;

  PStrInfo3 = ^TStrInfo3;

  TStrInfo3 = packed record
    OldSize, NewSize, ExtSize: Integer;
    Resource: Integer;
    Option: Word;
  end;

  PExecOutput = ^TExecOutput;

  TExecOutput = reference to procedure(Instance: Integer; const Buffer: Pointer;
    Size: Integer)cdecl;

  PPrecompFuncs = ^TPrecompFuncs;

  TPrecompFuncs = record
    Allocator: function(Index: Integer; Size: Integer): Pointer cdecl;
    GetCodec: function(Cmd: PChar; Index: Integer; Param: Boolean)
      : TPrecompStr cdecl;
    GetParam: function(Cmd: PChar; Index: Integer; Param: PChar)
      : TPrecompStr cdecl;
    GetDepthInfo: function(Index: Integer): TDepthInfo cdecl;
    Compress: function(Codec: PChar; InBuff: Pointer; InSize: Integer;
      OutBuff: Pointer; OutSize: Integer; DictBuff: Pointer; DictSize: Integer)
      : Integer cdecl;
    Decompress: function(Codec: PChar; InBuff: Pointer; InSize: Integer;
      OutBuff: Pointer; OutSize: Integer; DictBuff: Pointer; DictSize: Integer)
      : Integer cdecl;
    Encrypt: function(Codec: PChar; InBuff: Pointer; InSize: Integer;
      KeyBuff: Pointer; KeySize: Integer): Boolean cdecl;
    Decrypt: function(Codec: PChar; InBuff: Pointer; InSize: Integer;
      KeyBuff: Pointer; KeySize: Integer): Boolean cdecl;
    Hash: function(Codec: PChar; InBuff: Pointer; InSize: Integer;
      HashBuff: Pointer; HashSize: Integer): Boolean cdecl;
    EncodePatch: function(OldBuff: Pointer; OldSize: Integer; NewBuff: Pointer;
      NewSize: Integer; PatchBuff: Pointer; PatchSize: Integer): Integer cdecl;
    DecodePatch: function(PatchBuff: Pointer; PatchSize: Integer;
      OldBuff: Pointer; OldSize: Integer; NewBuff: Pointer; NewSize: Integer)
      : Integer cdecl;
    AddResource: function(FileName: PChar): Integer cdecl;
    GetResource: function(ID: Integer; Data: Pointer; Size: PInteger)
      : Boolean cdecl;
    SearchBinary: function(SrcMem: Pointer; SrcPos, SrcSize: NativeInt;
      SearchMem: Pointer; SearchSize: NativeInt; ResultPos: PNativeInt)
      : Boolean cdecl;
    SwapBinary: procedure(Source, Dest: Pointer; Size: NativeInt)cdecl;
    Swap16: function(Value: ShortInt): ShortInt cdecl;
    Swap32: function(Value: Integer): Integer cdecl;
    Swap64: function(Value: Int64): Int64 cdecl;
    FileOpen: function(FileName: PChar; Create: Boolean): THandle cdecl;
    FileClose: procedure(Handle: THandle)cdecl;
    FileSeek: function(Handle: THandle; Offset: Int64; Origin: Integer)
      : Int64 cdecl;
    FileSize: function(Handle: THandle): Int64 cdecl;
    FileRead: function(Handle: THandle; Buffer: Pointer; Count: Integer)
      : Integer cdecl;
    FileWrite: function(Handle: THandle; Buffer: Pointer; Count: Integer)
      : Integer cdecl;
    IniRead: function(Section, Key, Default, FileName: PChar)
      : TPrecompStr cdecl;
    IniWrite: procedure(Section, Key, Value, FileName: PChar)cdecl;
    Exec: function(Executable, CommandLine, WorkDir: PChar): Boolean cdecl;
    ExecStdin: function(Executable, CommandLine, WorkDir: PChar;
      InBuff: Pointer; InSize: Integer): Boolean cdecl;
    ExecStdout: function(Instance: Integer;
      Executable, CommandLine, WorkDir: PChar; Output: TExecOutput)
      : Boolean cdecl;
    ExecStdio: function(Instance: Integer;
      Executable, CommandLine, WorkDir: PChar; InBuff: Pointer; InSize: Integer;
      Output: TExecOutput): Boolean cdecl;
    ExecStdioSync: function(Instance: Integer;
      Executable, CommandLine, WorkDir: PChar; InBuff: Pointer; InSize: Integer;
      Output: TExecOutput): Boolean cdecl;
    GetDepthCodec: function(Cmd: PChar): TPrecompStr cdecl;
    ReadFuture: function(Index: Integer; Position: NativeInt; Buffer: Pointer;
      Count: Integer): Integer cdecl;
    LogScan1: procedure(Codec: PChar; Position: Int64;
      InSize, OutSize: Integer)cdecl;
    LogScan2: procedure(Codec: PChar; InSize, OutSize: Integer)cdecl;
    LogProcess: procedure(Codec, Method: PChar;
      OriginalSize, InSize, OutSize: Integer; Status: Boolean)cdecl;
    LogRestore: procedure(Codec, Method: PChar;
      OriginalSize, InSize, OutSize: Integer; Status: Boolean)cdecl;
    LogPatch1: procedure(OldSize, NewSize, PatchSize: Integer;
      Status: Boolean)cdecl;
    LogPatch2: procedure(OldSize, NewSize, PatchSize: Integer;
      Status: Boolean)cdecl;
    AcceptPatch: function(OldSize, NewSize, PatchSize: Integer): Boolean cdecl;
    Transfer: procedure(Instance: Integer; Codec: PChar)cdecl;
    Reserved: array [0 .. (PRECOMP_FCOUNT - 1) - 41] of Pointer;
  end;

  TPrecompOutput = procedure(Instance: Integer; const Buffer: Pointer;
    Size: Integer)cdecl;
  TPrecompAdd = procedure(Instance: Integer; Info: PStrInfo1; Codec: PChar;
    DepthInfo: PDepthInfo)cdecl;

implementation

end.
