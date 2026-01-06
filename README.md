# libh2o for zig

This is [libh2o][h2o], packaged for Zig with cross-compilation support for Linux and macos.

- all dependencies are statically linked into the output
- output is a static library (`.a`) for embedding into other projects

The intended usage is for building language bindings and FFI wrappers that need to expose all h2o and SSL symbols in a final shared library.

Included h2o features:

- http 1
- http 2
- picotls
- quic + http3
- brotli
- zstd
- [libaegis][aegis] for [draft-irtf-cfrg-aegis-aead-18][aegis-id]

features explicitly excluded:

- mruby
- memcached integration
- redis integration
- libuv

Supported targets:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-macos`
- `aarch64-macos`


## Quick start

1. Install [zig][zig]
2. `zig build` or `zig build -Dtarget=<target>` (where `<target>` is from the above list)

## Prerequisites

You need the following installed:

- [Zig][zig] 0.15.2
- Perl (for an h2o build step)

If you have nix you can use the dev shell provided by the flake in this repo.


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

## Hacking on H2O

This project also serves as a reproducible dev environment for h2o thanks to the nix flake's devshell.

Simply activate the nix devshell then:

``` bash
git clone https://github.com/h2o/h2o.git h2o
cd h2o
cmake -B build -S .  -DDISABLE_LIBUV=ON -DWITH_MRUBY=OFF
cmake --build build -j$(nproc)
cmake --build build --target check
```

### Building picotls (with AEGIS support)

To build and test picotls (the TLS library used by h2o) with AEGIS cipher support:

``` bash
git clone https://github.com/h2o/picotls.git picotls
cd picotls
nix develop ../   # enter devshell from picotls directory

cmake -B build -S . \
  -DWITH_AEGIS=ON \
  -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
  -DAEGIS_INCLUDE_DIR=$AEGIS_INCLUDE_DIR

cmake --build build -j$(nproc)

./build/test-openssl.t
```

## License: MIT License

h2o-zig is distributed under the [MIT](https://spdx.org/licenses/MIT.html).

Copyright © 2025 Casey Link <casey@outskirtslabs.com>

Binary distributions (JAR files on Clojars and GitHub releases) may bundle the following third-party projects:

- [h2o](https://github.com/h2o/h2o) is licensed under the MIT License and copyright [DeNA Co., Ltd.](http://dena.com/), [Kazuho Oku](https://github.com/kazuho/), and contributors.

- [brotli](https://github.com/google/brotli) is licensed under the MIT License and copyright (c) 2009, 2010, 2013-2016 by the Brotli Authors.

- [zstd](https://github.com/facebook/zstd) is licensed under the BSD License and copyright (c) Meta Platforms, Inc.

- [OpenSSL](https://github.com/openssl/openssl) is licensed under the Apache 2.0 License and copyright (c) 1998-2025 The OpenSSL Project Authors, and copyright (c) 1995-1998 Eric A. Young, Tim J. Hudson.

- [BoringSSL](https://github.com/google/boringssl) is licensed under the Apache 2.0 License and copyright [a bunch of folks](https://github.com/google/boringssl/blob/58da9b0d721fd807279f4e3898741c92cf43bdbd/AUTHORS#)

- [libaegis][aegis] is licensed under the MIT license and copyright (c) 2023-2026 Frank Denis


[h2o]: https://h2o.examp1e.net/
[zig]: https://ziglang.org/

[aegis]: https://github.com/aegis-aead/libaegis
[aegis-id]: https://datatracker.ietf.org/doc/draft-irtf-cfrg-aegis-aead/
