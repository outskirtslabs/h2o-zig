{
  lib,
  perl,
  zig2nix,
  stdenv,
}:
let
  system = stdenv.hostPlatform.system;
  root = toString ../.;
  zig2nixEnv = zig2nix.outputs.zig-env.${system} { };
in
zig2nixEnv.package {
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
  zigBuildFlags = [
    "-Doptimize=ReleaseSafe"
    "-Duse-boringssl=true"
    "-Duse-external-brotli=true"
    "-Duse-external-zstd=true"
  ];
  postInstall = ''
    test -e "$out/lib/libh2o-evloop.a"
    test -e "$out/lib/libssl.a"
    test -e "$out/lib/libcrypto.a"
  '';
}
