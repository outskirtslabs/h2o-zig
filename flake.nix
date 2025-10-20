{
  description = "dev env for h2o zig";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # tracks nixpkgs unstable branch
    flakelight.url = "github:nix-community/flakelight";
    flakelight.inputs.nixpkgs.follows = "nixpkgs";
    zig.url = "github:mitchellh/zig-overlay";
  };
  outputs =
    {
      self,
      flakelight,
      zig,
      ...
    }:
    flakelight ./. {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      nixpkgs.config.allowUnsupportedSystem = true;
      legacyPackages = pkgs: pkgs;
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
        {
          packages = [
            pkgs.git
            pkgs.perl
            zigpkgs."0.15.2"
          ];
          env.APPLE_SDK_PATH = "${apple-sdk}";
          env.ZIG_GLOBAL_CACHE_DIR = ".zig-cache-global";
        };
      flakelight.builtinFormatters = false;
    };
}
