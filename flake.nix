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
    inputs@{
      self,
      devenv,
      devshell,
      zig,
      ...
    }:
    devenv.lib.mkFlake ./. {
      inherit inputs;
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
              hash = "sha256:0fgj0pvjclq2pfsq3f3wjj39906xyj6bsgx1da933wyc918p4zi3";
            };
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p "$out"
              cp -r "$src"/* "$out"
              ls "$out"
            '';
          };
        libaegis =
          pkgs:
          pkgs.stdenv.mkDerivation {
            pname = "libaegis";
            version = "0.9.0";
            src = pkgs.fetchFromGitHub {
              owner = "aegis-aead";
              repo = "libaegis";
              rev = "0.9.0";
              hash = "sha256-+Uilyqn/M9IjQ9Qa8fsiYuEIG91WkgziMrHcXJ9/q4E=";
            };
            nativeBuildInputs = [ pkgs.cmake ];
            cmakeFlags = [ "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}" ];
          };
        h2o-zig = pkgs: pkgs.callPackage ./pkgs/h2o-zig.nix { inherit zig; };
      };
      devShell =
        pkgs:
        let
          zigpkgs = zig.packages.${pkgs.system};
          apple-sdk = (self.packages.${pkgs.system}.apple-sdk);
          libaegis = (self.packages.${pkgs.system}.libaegis);
          # Libraries needed for h2o cmake build
          libs = [
            pkgs.zlib
            pkgs.openssl
            pkgs.brotli
            pkgs.liburing
            pkgs.zstd
            pkgs.libcap
            pkgs.libuv
            pkgs.wslay
            pkgs.bison
            pkgs.ruby
            libaegis
          ];
          # Get .dev output if available, otherwise main output (for pkgconfig)
          getDev = lib: if lib ? dev then lib.dev else lib;
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

            # H2O build dependencies (cmake build system)
            pkgs.pkg-config
            pkgs.curl
            pkgs.cmake
            pkgs.ninja
            pkgs.makeWrapper
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
          ]
          # Add both main (libraries) and .dev (headers) outputs for CMake
          ++ libs
          ++ (map getDev libs);

          env = [
            {
              name = "APPLE_SDK_PATH";
              value = "${apple-sdk}";
            }
            {
              name = "ZIG_GLOBAL_CACHE_DIR";
              value = ".zig-cache-global";
            }
            {
              name = "PKG_CONFIG_PATH";
              value = pkgs.lib.makeSearchPath "lib/pkgconfig" (map getDev libs);
            }
            {
              name = "CMAKE_PREFIX_PATH";
              value = "${libaegis}";
            }
            {
              name = "AEGIS_INCLUDE_DIR";
              value = "${libaegis}/include";
            }
          ];
        };
    };
}
