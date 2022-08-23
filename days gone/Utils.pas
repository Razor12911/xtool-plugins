unit Utils;

interface

const
  PRECOMP_FCOUNT = 128;

type
  PStrInfo1 = ^TStrInfo1;

  TStrInfo1 = packed record
    Position: Int64;
    OldSize, NewSize: Integer;
    Resource: Integer;
    Option: Word;
    Reserved: Word;
  end;

  PStrInfo2 = ^TStrInfo2;

  TStrInfo2 = packed record
    OldSize, NewSize: Integer;
    Resource: Integer;
    Option: Word;
    Reserved: Word;
  end;

  PStrInfo3 = ^TStrInfo3;

  TStrInfo3 = packed record
    OldSize, NewSize, ExtSize: Integer;
    Resource: Integer;
    Option: Word;
    Reserved: Word;
  end;

  PPrecompFuncs = ^TPrecompFuncs;

  TPrecompFuncs = record
    Allocator: function(Index: Integer; Size: Integer): Pointer cdecl;
    GetCodec: function(Cmd: PAnsiChar; Index: Integer; Param: Boolean)
      : PAnsiChar cdecl;
    GetParam: function(Cmd: PAnsiChar; Index: Integer; Param: PAnsiChar)
      : PAnsiChar cdecl;
    GetDepthInfo: function(Index: Integer; OldSize: PInteger; NewSize: PInteger)
      : PAnsiChar cdecl;
    SetDepthInfo: procedure(Index: Integer; Codec: PAnsiChar; OldSize: Integer;
      NewSize: Integer)cdecl;
    Compress: function(Codec: PAnsiChar; InBuff: Pointer; InSize: Integer;
      OutBuff: Pointer; OutSize: Integer; DictBuff: Pointer; DictSize: Integer)
      : Integer cdecl;
    Decompress: function(Codec: PAnsiChar; InBuff: Pointer; InSize: Integer;
      OutBuff: Pointer; OutSize: Integer; DictBuff: Pointer; DictSize: Integer)
      : Integer cdecl;
    Encrypt: function(Codec: PAnsiChar; InBuff: Pointer; InSize: Integer;
      OutBuff: Pointer; OutSize: Integer; KeyBuff: Pointer; KeySize: Integer)
      : Boolean cdecl;
    Decrypt: function(Codec: PAnsiChar; InBuff: Pointer; InSize: Integer;
      OutBuff: Pointer; OutSize: Integer; KeyBuff: Pointer; KeySize: Integer)
      : Boolean cdecl;
    Hash: function(Codec: PAnsiChar; InBuff: Pointer; InSize: Integer;
      HashBuff: Pointer; HashSize: Integer): Boolean cdecl;
    EncodePatch: function(OldBuff: Pointer; OldSize: Integer; NewBuff: Pointer;
      NewSize: Integer; PatchBuff: Pointer; PatchSize: Integer): Integer cdecl;
    DecodePatch: function(PatchBuff: Pointer; PatchSize: Integer;
      OldBuff: Pointer; OldSize: Integer; NewBuff: Pointer; NewSize: Integer)
      : Integer cdecl;
    AddResource: function(FileName: PAnsiChar): Integer cdecl;
    GetResource: function(Index: Integer; Data: Pointer; Size: PInteger)
      : Boolean cdecl;
    BinarySearch: function(SrcMem: Pointer; SrcPos, SrcSize: NativeInt;
      SearchMem: Pointer; SearchSize: NativeInt; ResultPos: PNativeInt)
      : Boolean cdecl;
    Reserved: array [0 .. (PRECOMP_FCOUNT - 1) - 15] of Pointer;
  end;

  TPrecompOutput = procedure(Instance: Integer; const Buffer: Pointer;
    Size: Integer)cdecl;
  TPrecompAdd = procedure(Instance: Integer; Info: PStrInfo1;
    Codec: PAnsiChar)cdecl;

implementation

end.
