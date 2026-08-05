---
name: h2o-zig-cut-release
description: Prepares, validates, tags, and publishes date-based h2o-zig releases and their versioned Antora documentation. Use when cutting or publishing an h2o-zig release.
---

# Cut an h2o-zig release

Follow the build contract and local-checkout safety rules in `AGENTS.md`. Release tags use `v0.YYYYMMDD.N`, where the date is UTC and `N` starts at `0` for each day.

Published tags are immutable. Never move, replace, or delete one to correct a release. Cut a new release instead.

## 1. Establish the release commit

Start from a clean `main` whose `HEAD` equals `origin/main`. Fetch `origin` and its tags. Do not stash, clean, reset, or overwrite local work to satisfy this requirement.

Choose the version from the current UTC date and remote release tags:

- Use `v0.YYYYMMDD.0` when no release exists for that date.
- Otherwise increment the greatest same-day `N`.
- Abort if the candidate already exists or does not sort after the newest release.
- Recompute the version before publication if the UTC date changes.

Update the unprefixed version (`0.YYYYMMDD.N`) in exactly these release metadata fields:

- `build.zig.zon` — `.version`
- `pkgs/h2o-zig.nix` — `version`
- `doc/manifest.edn` — `[:project :version]`

Finalize `CHANGELOG.adoc`: create a fresh `Unreleased` section and move its current entries under `v0.YYYYMMDD.N` with the ISO release date. Use that section as the primary GitHub release notes. Run `bb gen-docs` so the Antora changelog matches the top-level file.

Keep `doc/antora.yml` and `doc/manifest.edn` docs metadata on `next` with `prerelease: true` on `main`. Inspect the diff, then commit it with the scoped subject `release: prepare 0.YYYYMMDD.N` through the project's normal integration path.

**Complete when:** the intended release commit is clean, is available as `origin/main`, and contains one consistent release version.

## 2. Validate the exact commit

Run every command under **Build and validate** in `AGENTS.md` on the exact release commit. This includes all feature configurations, all four supported targets, and the Nix flake check. Push the commit through the normal workflow and require Nixbot to pass for that SHA.

Record the release version, exact SHA, previous release, completed checks, H2O revision, BoringSSL release, and minimum Zig version. Confirm that these details and every notable change appear in the release's changelog section.

**Complete when:** all local checks and CI pass for the exact commit that will be tagged.

## 3. Publish the source release

Before pushing a tag, present the proposed tag, exact SHA, validation evidence, and release-note summary and obtain explicit go/no-go approval.

Create an annotated tag named `v0.YYYYMMDD.N` at the approved SHA and push that exact tag ref. Create a draft GitHub release with the title `h2o-zig v0.YYYYMMDD.N`, the matching `CHANGELOG.adoc` section, and the dependency/version summary. Generated notes may supplement the changelog with pull requests and contributors. Review the notes, call out breaking changes explicitly, and obtain approval before publishing the draft.

If GitHub release creation fails after the tag is pushed, retry against the existing tag. Do not recreate the tag.

**Complete when:** the remote annotated tag points to the approved SHA and the GitHub release is published.

## 4. Publish versioned documentation

Create the exact docs branch `v0.YYYYMMDD.N` from the release tag. A branch and tag intentionally share the same short name, so use fully qualified refs whenever Git could resolve the name ambiguously.

On the docs branch:

1. Set `doc/antora.yml` `version` to the unprefixed `0.YYYYMMDD.N` and remove `prerelease`.
2. Set `doc/manifest.edn` `[:docs :version]` to `0.YYYYMMDD.N` and `[:docs :prerelease]` to `false`.
3. Run `bb gen-docs`.
4. Commit the generated documentation with `docs: publish 0.YYYYMMDD.N`.
5. Push the fully qualified branch ref and return to `main`.

Do not edit or deploy the sibling docs-site repository as part of this release. Verify that the h2o-zig webhook produces the expected docs-site update workflow or PR, and report any missing docs-site branch configuration for separate handling.

**Complete when:** the remote docs branch exists, `main` is checked out again, and the docs-site follow-up is identified.

## 5. Verify the release

Verify all of the following:

- the remote tag resolves to the approved SHA;
- `gh release view v0.YYYYMMDD.N` succeeds;
- Zig can resolve the repository using the exact tag;
- the versioned docs branch contains release metadata rather than `next` metadata;
- after the docs-site update lands, `/h2o-zig/0.YYYYMMDD.N/` is available.

Report any docs deployment lag separately from source-release success.
