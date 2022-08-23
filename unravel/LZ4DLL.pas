unit LZ4DLL;

interface

uses
  WinAPI.Windows,
  System.SysUtils;

type
  PLZ4_streamDecode_t = ^LZ4_streamDecode_t;
  LZ4_streamDecode_t = array [0 .. 1 shl 9 - 1] of byte;

  PLZ4_streamHC_t = ^LZ4_streamHC_t;
  LZ4_streamHC_t = array [0 .. 1 shl 9 - 1] of byte;

var
  LZ4_decompress_safe: function(source: Pointer; dest: Pointer;
    compressedSize: integer; maxDecompressedSize: integer): integer cdecl;
  LZ4_decompress_fast: function(source: Pointer; dest: Pointer;
    originalSize: integer): integer cdecl;
  LZ4_compress_default: function(src, dst: Pointer;
    srcSize, dstCapacity: integer): integer cdecl;
  LZ4_compress_fast: function(src, dst: Pointer; srcSize, dstCapacity: integer;
    acceleration: integer): integer cdecl;
  LZ4_compress_HC: function(const src: Pointer; dst: Pointer; srcSize: integer;
    maxDstSize: integer; compressionLevel: integer): integer cdecl;
  LZ4_createStreamDecode: function: PLZ4_streamDecode_t cdecl;
  LZ4_freeStreamDecode: function(LZ4_stream: PLZ4_streamDecode_t)
    : integer cdecl;
  LZ4_decompress_safe_continue: function(LZ4_stream: PLZ4_streamDecode_t;
    const src: Pointer; dst: Pointer; srcSize: integer; dstCapacity: integer)
    : integer cdecl;
  LZ4_createStreamHC: function: PLZ4_streamHC_t cdecl;
  LZ4_freeStreamHC: function(streamHCPtr: PLZ4_streamHC_t): integer cdecl;
  LZ4_resetStreamHC: procedure(streamHCPtr: PLZ4_streamHC_t;
    compressionLevel: integer)cdecl;
  LZ4_compress_HC_continue: function(streamHCPtr: PLZ4_streamHC_t;
    const src: Pointer; dst: Pointer; srcSize: integer; maxDstSize: integer)
    : integer cdecl;
  DLLLoaded: Boolean = False;

implementation

var
  DLLHandle: THandle;

procedure Init;
begin
  if DLLLoaded then
    Exit;
  DLLHandle := 0;
  DLLHandle := LoadLibrary(PWideChar(ExtractFilePath(ParamStr(0)) +
    'liblz4.dll'));
  if DLLHandle >= 32 then
  begin
    DLLLoaded := True;
    @LZ4_decompress_safe := GetProcAddress(DLLHandle, 'LZ4_decompress_safe');
    Assert(@LZ4_decompress_safe <> nil);
    @LZ4_decompress_fast := GetProcAddress(DLLHandle, 'LZ4_decompress_fast');
    Assert(@LZ4_decompress_fast <> nil);
    @LZ4_compress_default := GetProcAddress(DLLHandle, 'LZ4_compress_default');
    Assert(@LZ4_compress_default <> nil);
    @LZ4_compress_fast := GetProcAddress(DLLHandle, 'LZ4_compress_fast');
    Assert(@LZ4_compress_fast <> nil);
    @LZ4_compress_HC := GetProcAddress(DLLHandle, 'LZ4_compress_HC');
    Assert(@LZ4_compress_HC <> nil);
    @LZ4_createStreamDecode := GetProcAddress(DLLHandle,
      'LZ4_createStreamDecode');
    Assert(@LZ4_createStreamDecode <> nil);
    @LZ4_freeStreamDecode := GetProcAddress(DLLHandle, 'LZ4_freeStreamDecode');
    Assert(@LZ4_freeStreamDecode <> nil);
    @LZ4_decompress_safe_continue := GetProcAddress(DLLHandle,
      'LZ4_decompress_safe_continue');
    Assert(@LZ4_decompress_safe_continue <> nil);
    @LZ4_createStreamHC := GetProcAddress(DLLHandle, 'LZ4_createStreamHC');
    Assert(@LZ4_createStreamHC <> nil);
    @LZ4_freeStreamHC := GetProcAddress(DLLHandle, 'LZ4_freeStreamHC');
    Assert(@LZ4_freeStreamHC <> nil);
    @LZ4_resetStreamHC := GetProcAddress(DLLHandle, 'LZ4_resetStreamHC');
    Assert(@LZ4_resetStreamHC <> nil);
    @LZ4_compress_HC_continue := GetProcAddress(DLLHandle,
      'LZ4_compress_HC_continue');
    Assert(@LZ4_compress_HC_continue <> nil);
  end
  else
    DLLLoaded := False;
end;

procedure Deinit;
begin
  if not DLLLoaded then
    Exit;
  FreeLibrary(DLLHandle);
end;

initialization

Init;

finalization

Deinit;

end.
