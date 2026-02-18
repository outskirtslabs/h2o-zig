# This package isn't meant for distrubution/consumption
# it is a smoke test to ensure out build is working.
{
  stdenv,
  fetchurl,
  git,
  perl,
  zig,
}:
let
  zigpkgs = zig.packages.${stdenv.hostPlatform.system};
  h2oSrc = fetchurl {
    url = "https://github.com/ramblurr/h2o/archive/7c1e7f54faa8b008a503c13e87b254005866b956.tar.gz";
    hash = "sha256-A4pGtZAMTuWII6voz8M5qVcoWNhdpI9i1bxYTzocEu8=";
  };
  wslaySrc = fetchurl {
    url = "https://github.com/tatsuhiro-t/wslay/archive/refs/tags/release-1.1.1.tar.gz";
    hash = "sha256-e59LnfCa2qbgfsMJtoqzdsDbLP2RZhMCO1Kket/aIko=";
  };
  zlibSrc = fetchurl {
    url = "https://github.com/allyourcodebase/zlib/archive/3599c16d41dbe749ae51b0ff7ab864c61adc779a.tar.gz";
    hash = "sha256-e0kjBEQQAAgFRumRXKHCq9AzCObPP3RJ9FZ7+LDLA8A=";
  };
  zlibUpstreamSrc = fetchurl {
    url = "https://github.com/madler/zlib/archive/refs/tags/v1.3.1.tar.gz";
    hash = "sha256-F+iIY/NgBnKrSRgvIXKBtvxNPHYr3jYZNeQ2qVIU0Fw=";
  };
  opensslZigSrc = fetchurl {
    url = "https://github.com/dzfrias/openssl-zig/archive/8f9dd2791a5ec743c85e57fb1ef9c59e99c5d222.tar.gz";
    hash = "sha256-hs5R4585giYGwBGXCwarEXH5xP0smvsq3L+IFhVpVZU=";
  };
  opensslSrc = fetchurl {
    url = "https://github.com/openssl/openssl/releases/download/openssl-3.6.0/openssl-3.6.0.tar.gz";
    hash = "sha256-tqX0S362nj+jXb8VUkQFtEg3pIHUPYHa3d4/8h/LuOk=";
  };
in
stdenv.mkDerivation {
  pname = "h2o-zig";
  version = "0.0.1";
  src = ../.;
  strictDeps = true;

  nativeBuildInputs = [
    zigpkgs."0.15.2"
    git
    perl
  ];

  dontConfigure = true;
  postPatch = ''
        mkdir -p .nix-deps

        tar -xzf ${h2oSrc} -C .nix-deps
        mv .nix-deps/h2o-* .nix-deps/h2o

        tar -xzf ${wslaySrc} -C .nix-deps
        mv .nix-deps/wslay-* .nix-deps/wslay

        tar -xzf ${zlibSrc} -C .nix-deps
        mv .nix-deps/zlib-* .nix-deps/zlib

        tar -xzf ${zlibUpstreamSrc} -C .nix-deps
        mv .nix-deps/zlib-1.3.1 .nix-deps/zlib-upstream

        tar -xzf ${opensslZigSrc} -C .nix-deps
        mv .nix-deps/openssl-zig-* .nix-deps/openssl-zig

        tar -xzf ${opensslSrc} -C .nix-deps
        mv .nix-deps/openssl-3.6.0 .nix-deps/openssl

        cat > .nix-deps/zlib/build.zig.zon <<'EOF'
    .{
        .name = .zlib,
        .version = "1.3.1",
        .fingerprint = 0x73887d3a953b9465,
        .minimum_zig_version = "0.15.2",
        .dependencies = .{
            .zlib = .{
                .path = "../zlib-upstream",
            },
        },
        .paths = .{
            "LICENSE",
            "README.md",
            "build.zig",
            "build.zig.zon",
        },
    }
    EOF

        cat > .nix-deps/openssl-zig/build.zig.zon <<'EOF'
    .{
        .name = .openssl,
        .version = "3.6.0",
        .minimum_zig_version = "0.15.2",
        .fingerprint = 0x773a47f13ea12963,
        .dependencies = .{
            .openssl = .{
                .path = "../openssl",
            },
        },
        .paths = .{
            "build.zig",
            "build.zig.zon",
            "generate.sh",
            "LICENSE",
            "README.md",
        },
    }
    EOF

        cat > build.zig.zon <<'EOF'
    .{
        .name = .h2o,
        .version = "0.0.1",
        .minimum_zig_version = "0.15.2",
        .fingerprint = 0x89f86b3231b16f73,
        .dependencies = .{
            .h2o = .{ .path = ".nix-deps/h2o", },
            .wslay = .{ .path = ".nix-deps/wslay", },
            .openssl = .{ .path = ".nix-deps/openssl-zig", .lazy = true, },
            .zlib = .{ .path = ".nix-deps/zlib", },
        },
        .paths = .{
            "build.zig",
            "build.zig.zon",
        },
    }
    EOF
  '';

  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR"
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_LOCAL_CACHE_DIR"

    zig build install --prefix "$out" \
      -Duse-boringssl=false \
      -Duse-external-brotli=false \
      -Duse-external-zstd=false

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    test -e "$out/lib/libh2o-evloop.a"
    runHook postInstall
  '';
}
