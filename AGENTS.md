# h2o-zig

## Mission

Package H2O's built-in-event-loop C HTTP server as one position-independent static archive for FFI and shared-library consumers.

`README.adoc` is authoritative for installed outputs, supported features, unsupported integrations, and targets. Read its **Use as a dependency** section before changing or using the Zig package interface.

## Build contract

- Use Zig 0.17.0. On x86_64 Linux, enter `nix develop`; the flake exposes no other host system. The shell supplies Zig, Perl, CMake, and Ninja, and sets the `APPLE_SDK_PATH` required to cross-compile to macOS from a non-macOS host.
- `build.zig.zon` pins H2O and every Zig dependency; it is the source of truth for revisions.
- BoringSSL is the sole TLS backend.
- Brotli and Zstandard are always enabled. AEGIS is optional with `-Duse-aegis=true` and defaults off.
- Every archive must remain PIC because downstream projects embed it in shared libraries. Preserve `.pic`/`.pie` settings and `-fPIC` across H2O and all bundled dependencies.
- Perl generates `quicly-tracer.h` during every Zig build. There is no vendored-header fallback.
- For Linux targets, preserve both `-D_GNU_SOURCE` and `-U__gnu_linux__`; Zig defines `__gnu_linux__` for musl, which otherwise breaks H2O's `strerror_r` detection.

## Build and validate

```bash
nix develop
zig build
zig build test                         # required feature and symbol smoke test
zig build -Doptimize=ReleaseSafe
zig build -Duse-aegis=true            # optional AEGIS path
```

Validate all supported targets before landing build-system or dependency changes:

```bash
for target in x86_64-linux aarch64-linux x86_64-macos aarch64-macos; do
  zig build -Dtarget="$target" -Doptimize=ReleaseSafe
done
nix flake check --print-build-logs
```

## Local checkout safety

`h2o/` is an independent, ignored Git checkout for developing H2O patches, examples, and upstream PRs. It is not the source used by `zig build`; the Zig build fetches the revision pinned in `build.zig.zon`. Preserve its branches and untracked experiments—never clean or reset it casually.

`vendor/` contains similar independent checkouts used to develop or test dependency patches and upstream PRs. They are not package inputs unless `build.zig.zon` points to their published commits. Preserve their local state too.

## Project map

- `build.zig` — build graph, feature flags, PIC rules, archive bundling, and installed headers.
- `build.zig.zon`, `build.zig.zon2json-lock` — pinned package sources and the generated Nix dependency lock.
- `test/required_features.c` — required protocol, compression, and symbol smoke test.
- `flake.nix`, `pkgs/h2o-zig.nix` — development shell and Nix package/CI build.
- `archive/` — historical notes only; never treat them as current instructions.

## Agent references

- When working with local issues or specs, follow `docs/agents/issue-tracker.md`.
- When assigning or interpreting triage labels, follow `docs/agents/triage-labels.md`.
- When changing domain terminology or domain documentation, follow `docs/agents/domain.md`.
