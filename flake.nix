{
  description = "dev env for h2o zig";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # tracks nixpkgs unstable branch
    devshell.url = "github:numtide/devshell";
    devenv.url = "https://flakehub.com/f/ramblurr/nix-devenv/*";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    zig.url = "github:mitchellh/zig-overlay";
  };
  outputs =
    {
      self,
      devenv,
      devshell,
      zig,
      ...
    }:
    devenv.lib.mkFlake ./. {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      nixpkgs.config.allowUnsupportedSystem = true;
      legacyPackages = pkgs: pkgs;
      withOverlays = [
        devshell.overlays.default
        devenv.overlays.default
      ];
      packages = {
        apple-sdk =
          pkgs:
          pkgs.stdenv.mkDerivation {
            name = "apple-sdk_15.2";
            src = pkgs.fetchzip {
              url = "https://github.com/joseluisq/macosx-sdks/releases/download/15.2/MacOSX15.2.sdk.tar.xz";
              sha256 = "sha256:0fgj0pvjclq2pfsq3f3wjj39906xyj6bsgx1da933wyc918p4zi3";
            };
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p "$out"
              cp -r "$src"/* "$out"
              ls "$out"
            '';
          };

      };
      devShell =
        pkgs:
        let
          zigpkgs = zig.packages.${pkgs.system};
          apple-sdk = (self.packages.${pkgs.system}.apple-sdk);
        in
        pkgs.devshell.mkShell {
          imports = [
            devenv.capsules.base
            devenv.capsules.clojure
          ];
          # https://numtide.github.io/devshell
          commands = [
          ];
          packages = [
            # This is all we need for the zig build
            zigpkgs."0.15.2"
            pkgs.git

            #pkgs.perl540
            # H2O build dependencies
            # we need these when hacking on h2o with its original cmake build system
            pkgs.curl
            pkgs.cmake
            pkgs.ninja
            pkgs.pkg-config
            pkgs.makeWrapper
            pkgs.brotli
            pkgs.openssl
            pkgs.libcap
            pkgs.libuv
            pkgs.zlib
            pkgs.wslay
            pkgs.bison
            pkgs.ruby
            pkgs.liburing
            pkgs.zstd
            (pkgs.perl540.withPackages (ps: [
              ps.IOSocketSSL
              ps.IOAsyncSSL
              ps.ListAllUtils
              ps.ListMoreUtils
              ps.TestTCP
              ps.NetDNS
              ps.PathTiny
              ps.ProtocolHTTP2
              ps.ScopeGuard
              ps.Plack
              ps.Starlet
              ps.JSON
              ps.TestException
              ps.TestRequires
            ]))
          ];

          env = [
            {
              name = "APPLE_SDK_PATH";
              value = "${apple-sdk}";
            }
            {
              name = "ZIG_GLOBAL_CACHE_DIR";
              value = ".zig-cache-global";
            }
          ];
        };
    };
}
