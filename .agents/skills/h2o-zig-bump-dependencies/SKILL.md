---
name: h2o-zig-bump-dependencies
description: Bumps dependencies pinned in build.zig.zon. Use when updating H2O, BoringSSL, or any other dependency in h2o-zig, including the scheduled daily dependency run.
---

# Bump dependencies

Follow the build contract and checkout-safety rules in `AGENTS.md`. For the scheduled daily run, read [scheduled.md](scheduled.md) first; it decides what to update, publish, and report.

## 1. Establish the new pin

Identify the manifest name, official upstream, current immutable revision, and target release or revision. Refresh the matching checkout in `h2o/` or `vendor/` (`git remote -v` shows which are forks; `vendor/boringssl-src` is official BoringSSL). Compare the old and new trees for source layout, build API, exported artifacts, and PIC behavior.

Complete when: the target revision is immutable and every compatibility-relevant change is accounted for.

## 2. Prepare the dependency

- H2O: fetch `upstream/master` from `h2o/h2o`, and re-fetch just before finalizing the pin. Check source paths, build metadata, public headers, and required symbols. Use unmodified upstream unless the comparison proves a patch necessary. Run the upstream examples when the diff touches built-in-event-loop integration, the examples, or their build metadata. Before any local H2O build, test, or example run, read [local-h2o.md](local-h2o.md).
- BoringSSL: take `version` from the google/boringssl GitHub Releases. Resolve the latest with `gh release view --repo google/boringssl --json tagName --jq .tagName`, or verify a requested one with `gh release view "$version" --repo google/boringssl`. Peel it to the source commit used in the archive URL:

  ```bash
  git -C vendor/boringssl-src fetch origin --tags
  boringssl_commit=$(git -C vendor/boringssl-src rev-parse "refs/tags/$version^{}")
  ```

  In `vendor/boringssl`, base the version-only branch `update/boringssl-$version` on wrapper `upstream/main`. Stack `h2o-zig/boringssl-$version-pic` on it with exactly two downstream commits: PIC support, and removal of the translate-c patch step and its `patch` dependency, which downloads GNU patch from `mirrors.kernel.org`. Keep reading `gen/sources.json` from the source dependency. Validate both branches.
- Other dependencies: inspect the upstream release diff and preserve the artifact, feature, target, and PIC contract. A fork keeps its split between upstream and h2o-zig commits.

Publish fork branches only after review, under new names; if a name is taken, append the next `-vN`, such as `h2o-zig/boringssl-0.20261105.0-pic-v2`. Never move an existing fork branch. Confirm the reviewed commit exists remotely, then pin h2o-zig to it.

Complete when: the commit h2o-zig will consume is final and, for a fork, reviewed and published.

## 3. Update the package

From the repository root, change URLs and hashes only through `zig fetch`:

```bash
zig fetch --save-exact=<name> <url>
zig2nix zon2lock build.zig.zon
```

Inspect the full `build.zig.zon` and `build.zig.zon2json-lock` diffs, including transitive changes.

Complete when: both files pin the intended immutable source and the bump explains every lock change.

## 4. Validate and review

Run every command under Build and validate in `AGENTS.md`. Fix failures at the changed dependency's boundary; add a downstream patch only when the evidence requires one. Review the final diff and resolve its findings.

Complete when: the full Zig/Nix matrix passes and the review approves the bump.
