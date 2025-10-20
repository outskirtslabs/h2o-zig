# libh2o for zig

This is [libh2o][h2o], packaged for Zig with cross-compilation support for Linux and macos.

- all dependencies are statically linked into the output
- output is a static library (`.a`) for embedding into other projects

The intended usage is for building language bindings and FFI wrappers that need to expose all h2o and SSL symbols in a final shared library.

Included features:

- http 1
- http 2
- quic + http3
- brotli
- zstd

h2o features explicitly excluded:

- mruby
- memcached integration
- redis integration
- libuv

[h2o]: https://h2o.examp1e.net/


## Quick start

1. Install [zig][zig]
2. `zig build`

## Prerequisites

You need the following installed:

- [Zig][zig] 0.15.2
- Perl (for an h2o build step)

If you have nix you can use the dev shell provided by the flake in this repo.

[zig]: https://ziglang.org/


## Use as a dependency

First, update your `build.zig.zon`:

```
zig init # if you don't have a build.zig already
zig fetch --save git+https://github.com/outskirtslabs/h2o-zig.git
```

You can then import `h2o` in your `build.zig` with:

```zig
const h2o_dependency = b.dependency("h2o", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(h2o_dependency.artifact("h2o-evloop"));
```

### Build Options

The following build-time flags are available:

- `-Duse-boringssl=<bool>` - Use BoringSSL instead of OpenSSL (default: `true`)
- `-Duse-external-brotli=<bool>` - Use external brotli dependency instead of vendored sources (default: `true`). The vendored one is from upstream h2o and is a much older version than the external one.

Example usage:

```zig
const h2o_dependency = b.dependency("h2o", .{
    .target = target,
    .optimize = optimize,
    .@"use-boringssl" = true, // default
});
your_exe.linkLibrary(h2o_dependency.artifact("h2o-evloop"));
```

Or via command line when building:

```bash
zig build -Duse-boringssl=true
```

### Cross-Compilation to macOS

When cross-compiling from Linux to macOS targets (x86_64-macos or aarch64-macos), the build requires the `APPLE_SDK_PATH` environment variable to be set.
This points to the macOS SDK that provides system headers and libraries.

**Using Nix (Recommended)**

The provided nix flake automatically sets up `APPLE_SDK_PATH` when you enter the development shell:

```bash
nix develop
zig build -Dtarget=aarch64-macos
zig build -Dtarget=x86_64-macos
```

**Manual Setup**

If not using nix, you'll need to obtain a macOS SDK and set the environment variable:

```bash
export APPLE_SDK_PATH=/path/to/MacOSX.sdk
zig build -Dtarget=x86_64-macos
```

The SDK must contain `usr/include` with macOS system headers. Without this, cross-compilation to macOS will fail with an error about the missing `APPLE_SDK_PATH` environment variable.

**Note**: Cross-compilation to macOS from macOS does not require `APPLE_SDK_PATH` as the system SDK is used automatically.

## Notes

Supported targets

- linux x86_64
- linux aarch64
- macos x86_64
- macos aarch64


## License: MIT License

Copyright © 2025 Casey Link <casey@outskirtslabs.com>
Distributed under the [MIT](https://spdx.org/licenses/MIT.html).
