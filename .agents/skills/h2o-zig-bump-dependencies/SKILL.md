---
name: h2o-zig-bump-dependencies
description: Bumps dependencies pinned in build.zig.zon. Use when updating H2O, BoringSSL, or any other dependency in h2o-zig.
---

# Bump dependencies

Follow the build contract and checkout-safety rules in `AGENTS.md`.

## 1. Establish the new pin

Identify the manifest name, official upstream, current immutable revision, and intended release or revision. Refresh the relevant local source checkout and compare the old and new trees for source layout, build API, exported artifacts, and PIC behavior.

Use the existing checkout for source and fork work:

- `h2o/` — H2O fork with the official upstream remote
- `vendor/boringssl` — BoringSSL Zig wrapper fork
- `vendor/boringssl-src` — official BoringSSL source
- `vendor/brotli.zig` — Brotli Zig wrapper fork
- `vendor/googletest` — googletest package checkout
- `vendor/libaegis` — libaegis source checkout
- `vendor/picotls` — picotls fork
- `vendor/wslay` — wslay source checkout

**Complete when:** the intended official revision is immutable and every compatibility-relevant change is accounted for.

## 2. Prepare the dependency

Use the matching branch:

- **H2O:** fetch `upstream/master` from `h2o/h2o`; re-fetch immediately before finalizing the pin. Check source paths, build metadata, public headers, and required symbols. Keep unmodified official upstream unless the comparison proves a patch necessary. Run the upstream examples when the diff affects built-in-event-loop integration, examples, or their build metadata. When H2O work requires a local build, upstream tests, or examples, read [local-h2o.md](local-h2o.md) before continuing.
- **BoringSSL:** select the release from the official GitHub Releases. When the user requests the latest release, resolve it with:

  ```bash
  version=$(gh release view --repo google/boringssl --json tagName --jq '.tagName')
  ```

  When the user specifies a release, set `version` to that value and verify it with:

  ```bash
  gh release view "$version" --repo google/boringssl
  ```

  Fetch the official tags and peel the selected release to its source commit:

  ```bash
  git -C vendor/boringssl-src fetch origin --tags
  boringssl_commit=$(git -C vendor/boringssl-src rev-parse "refs/tags/$version^{}")
  ```

  Use the peeled commit in the source archive URL. In `vendor/boringssl`, base `update/boringssl-$version` on wrapper `upstream/main` and keep it version-only. Stack `h2o-zig/boringssl-$version-pic` on that branch with only h2o-zig's PIC support. Keep reading `gen/sources.json` from the source dependency. Validate both branches, obtain review, publish them, and verify the approved PIC commit exists remotely. Pin the outer h2o-zig package to that published PIC commit.
- **Other dependencies:** inspect the upstream release diff and preserve the existing artifact, feature, target, and PIC contract. When a maintained fork is required, preserve its existing upstream/project patch split and publish the exact reviewed commit that h2o-zig will consume.

**Complete when:** the upstream or wrapper commit that h2o-zig will consume is final and, for a fork, reviewed and available remotely.

## 3. Update the package

Update the pin from the repository root:

```bash
zig fetch --save-exact=<name> <url>
zig2nix zon2lock build.zig.zon
```

Inspect the complete `build.zig.zon` and `build.zig.zon2json-lock` diffs, including every transitive change. Make URL and hash changes only through `zig fetch`.

**Complete when:** both files identify the intended immutable source and every lock change is explained by the bump.

## 4. Validate and review

Run every command under **Build and validate** in `AGENTS.md`. Resolve failures at the changed dependency boundary and carry a downstream patch only when the evidence requires one. Review the final focused diff and resolve its findings.

**Complete when:** the full Zig/Nix matrix passes and the final review approves the bump.
