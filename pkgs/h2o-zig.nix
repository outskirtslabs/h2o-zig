{
  lib,
  perl,
  zig2nix,
  stdenv,
}:
let
  system = stdenv.hostPlatform.system;
  root = toString ../.;
  zig = zig2nix.packages.${system}."zig-0_17_0";
  # Keep dependency fetching on 0.16 until zig2nix supports 0.17's fetch API.
  fetchZig = zig2nix.packages.${system}."zig-0_16_0";
  zig2nixEnv = zig2nix.outputs.zig-env.${system} { zig = fetchZig; };
in
(zig2nixEnv.package {
  pname = "h2o-zig";
  version = "0.0.1";
  src = lib.cleanSourceWith {
    src = ../.;
    filter =
      path: _type:
      let
        rel = lib.removePrefix (root + "/") (toString path);
        base = builtins.baseNameOf path;
      in
      !(
        base == ".git"
        || rel == "result"
        || lib.hasPrefix ".zig-cache/" rel
        || lib.hasPrefix ".zig-cache-global/" rel
        || lib.hasPrefix "zig-out/" rel
        || lib.hasPrefix "vendor/boringssl/.zig-cache/" rel
        || lib.hasPrefix "vendor/boringssl/.zig-cache-global/" rel
        || lib.hasPrefix "vendor/boringssl/zig-out/" rel
      );
  };
  nativeBuildInputs = [ perl ];
  doCheck = true;
  zigBuildFlags = [ "-Doptimize=ReleaseSafe" ];
  postInstall = ''
    test -e "$out/lib/libh2o-evloop.a"
    test -e "$out/include/h2o.h"
    test -e "$out/include/openssl/ssl.h"
    test -e "$out/include/wslay/wslay.h"
    test ! -e "$out/lib/libssl.a"
    test ! -e "$out/lib/libcrypto.a"
    test ! -e "$out/lib/libwslay.a"
  '';
}).overrideAttrs (old: {
  # Compile and test with 0.17; only the fixed-output dependency fetches use 0.16.
  nativeBuildInputs = map (input: if input == fetchZig.hook then zig.hook else input) old.nativeBuildInputs;
})
