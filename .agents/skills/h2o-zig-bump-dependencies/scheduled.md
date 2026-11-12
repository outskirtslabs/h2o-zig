# Scheduled dependency run

A T3 schedule starts this run every day at 05:00 local time in a new thread with no earlier context. No human answers during the run: decide from these rules, and report anything they do not cover instead of guessing.

## 1. Find updates

Check every dependency, not a fixed list:

- Every entry in `build.zig.zon`, including lazy ones. H2O tracks `upstream/master`; every other dependency tracks its latest stable upstream release, never a prerelease.
- The upstream of every wrapper fork pinned there. A wrapper fork packages someone else's library for Zig, such as `Ramblurr/boringssl` on `allyourcodebase/boringssl`; it tracks its upstream's main branch. A fork of the library itself, such as `Ramblurr/libaegis` on `aegis-aead/libaegis`, tracks the library's latest stable release instead, so unreleased commits on its main branch are not updates. For wrapper forks, an upstream commit the fork lacks is an update only if it changes a file inside the `.paths` of the fork's `build.zig.zon`; those are the only files h2o-zig downloads. Ignore commits that touch only other files, such as a README or CI configuration.

Never update the Zig toolchain on its own, and never move it to the latest `zig-master`. Change it only when an update from this step fails to build with our Zig. A higher `minimum_zig_version` alone is not a reason: Zig does not enforce dependency minimums, and some upstream wrappers declare dev snapshots they do not need. Then select the oldest Zig version that every dependency accepts, preferring a tagged release over a dev snapshot. The toolchain change also updates `minimum_zig_version` and every place that names the pinned Zig version (`AGENTS.md`, `README.adoc`, `CHANGELOG.adoc`).

Update every flake input except `zig2nix`, whose revision selects the Zig snapshot:

```bash
nix flake update $(nix flake metadata --json | jq -r '.locks.nodes.root.inputs | keys[] | select(. != "zig2nix")')
```

Commit flake input updates as `nix: update flake inputs`. If they break validation, they are complicated; also propose updating them less often.

If nothing is new, end the run with the one-line report from step 5.

**Complete when:** every dependency has a current and a target revision.

## 2. Set up the workspace

1. Run `git fetch --multiple upstream origin` in the repository root.
2. Check for an open PR from a `deps/` branch: `gh pr list --repo outskirtslabs/h2o-zig --state open --search "head:deps/"`. If one exists, continue on its branch and add commits to it; do not open a second PR. If `upstream/main` has moved past the branch's base, rebase the branch onto `upstream/main` first. PRs merge only by fast-forward, so a `deps/` branch must always sit directly on top of `upstream/main`.
3. Otherwise create a worktree: `git worktree add .worktrees/deps-YYYY-MM-DD -b deps/YYYY-MM-DD upstream/main`.
4. For fork work, add a worktree next to the fork's checkout, for example `git -C vendor/boringssl worktree add ../boringssl-deps-YYYY-MM-DD <base>`.

Never edit the working trees of the repository root, `h2o/`, or `vendor/*`. Always stage files by name. Never use `git add -A` or `git add .`, because the devshell writes `.zig-cache-global/` into the current directory.

**Complete when:** all edits happen in run-owned worktrees.

## 3. Bump and validate

Follow steps 1 to 4 of [SKILL.md](SKILL.md) for each update. One scoped commit per dependency, for example `h2o: update upstream to <short-sha>`. Update `CHANGELOG.adoc` in a final `docs:` commit; it records dependency versions only, not upstream behaviour changes that affect consumers.

Classify each update:

- Straightforward: the full matrix passes; `zon2lock` completed by itself; h2o-zig changes are limited to pins, the lock, version strings, `build.zig` source lists for files upstream added or removed, and the changelog; fork changes are limited to version bumps and rebasing existing downstream commits without conflicts.
- Complicated: anything else, including a Zig toolchain change to a dev snapshot, a new patch or workaround, a rebase conflict, other `build.zig` changes, a failing check, a network failure, or a transitive dependency change the bump does not explain. Never hand-edit lock files; a failed `zon2lock` makes the update complicated.

**Complete when:** each update is committed and classified.

## 4. Publish

Publish only straightforward updates:

1. Push fork branches to new branch names that follow the fork conventions in [SKILL.md](SKILL.md). If a branch for the same version already exists, append the next `-vN` suffix, for example `h2o-zig/boringssl-0.20261105.0-pic-v2`. Never move an existing fork branch. Verify the pushed commit exists remotely before pinning it. In this run, the h2o-zig PR is the review that [SKILL.md](SKILL.md) requires before publishing a fork, so the PR body lists every fork commit.
2. Push the `deps/` branch to `upstream` (GitHub) and open a PR against `main` on `outskirtslabs/h2o-zig`, or add a comment on the existing PR. The body lists each dependency as old revision to new revision, the validation results, and any update held back. Mention `@Ramblurr`.

Never push to `main`, merge a PR, or delete remote branches. Never force-push, except `git push --force-with-lease` of this run's own `deps/` branch after the rebase in step 2. Leave complicated updates unpushed in their worktree.

**Complete when:** the PR contains every straightforward update, and nothing complicated left the machine.

## 5. Report and clean up

Remove the worktrees of published work. Keep worktrees that hold complicated updates.

End the thread with:

- No updates: `No updates.`
- Otherwise: the PR URL; one line per dependency (old to new, straightforward or complicated); validation results; for each complicated update, the blocker, the worktree path, and a proposed fix.
