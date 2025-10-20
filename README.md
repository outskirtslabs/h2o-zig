# h2o / libh2o for zig

This is [h2o and libh2o][h2o], packaged for Zig with cross-compilation support for Linux and macos.

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
