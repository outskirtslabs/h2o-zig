# libh2o for zig

This is [libh2o][h2o], packaged for Zig with cross-compilation support for Linux and macos.

- all dependencies are statically linked
- output is a single shared library

The intended usage is for libh2o language bindings.

Included features:

- http 1
- http 2
- quic + http3
- brotli
- zstd

h2o features explictly excluded:

- mruby
- memcached integration
- redis integration
- libuv

[h2o]: https://h2o.examp1e.net/

## Installation

First, update your `build.zig.zon`:

```
# Initialize a `zig build` project if you haven't already
zig init
zig fetch --save git+https://github.com/outskirtslabs/h2o-zig.git
```

You can then import `h2o` in your `build.zig` with:

```zig
const h2o_dependency = b.dependency("h2o", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(h2o_dependency.artifact("h2o"));
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
    .@"use-boringssl" = true,
    .@"use-external-brotli" = true,
});
your_exe.linkLibrary(h2o_dependency.artifact("h2o"));
```

Or via command line when building:

```bash
zig build -Duse-boringssl=true -Duse-external-brotli=true
```

And use the library like this:
```zig
const TODO = @cImport({
    @cInclude("TODO");
});

const todo = ... libh2o example...
...
...
```

## Notes

Supported targets

- linux x86_64
- linux aarch64
- macos x86_64
- macos aarch64

### Zig Version

The target zig version is 0.15.2

## License: MIT License

Copyright © 2025 Casey Link <casey@outskirtslabs.com>
Distributed under the [MIT](https://spdx.org/licenses/MIT.html).
