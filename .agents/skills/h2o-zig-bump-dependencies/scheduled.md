# Scheduled dependency run

A T3 schedule starts this run daily at 05:00 in a fresh thread. No human answers: decide from these rules, and report anything they do not cover instead of guessing.

## 1. Find updates

Run `git fetch --multiple upstream origin`. If `main` is behind `upstream/main` by a fast-forward only, run `git -C <root> merge --ff-only upstream/main` (`<root>` is the main checkout: `dirname "$(git rev-parse --git-common-dir)"`) and `git push origin upstream/main:main`; if the root checkout is dirty or not on `main`, report it instead.

Compare against the pins on `upstream/main`, not the current checkout. Check every entry in `build.zig.zon`, including lazy ones, and the flake inputs:

- H2O: latest `upstream/master`.
- Everything else: latest stable release, never a prerelease.
- Wrapper forks, which package someone else's library for Zig (`Ramblurr/boringssl`): also upstream wrapper commits the fork lacks that change a file in the fork's `build.zig.zon` `.paths`. Only `git -C vendor/<fork> log <pin>..upstream/HEAD -- <paths>` output counts.
- Library forks, which fork the library itself (`Ramblurr/libaegis`): stable releases only.
- Flake inputs: all except `zig2nix`, which selects Zig:

  ```bash
  lock=$(mktemp)
  nix flake update --output-lock-file "$lock" $(nix flake metadata --json | jq -r '.locks.nodes.root.inputs | keys[] | select(. != "zig2nix")')
  git show upstream/main:flake.lock | diff -q - "$lock"
  ```

If nothing is new, report only `No updates` and stop.

Complete when: every dependency has a current and a target revision.

## 2. Set up the workspace

1. If `gh pr list --repo outskirtslabs/h2o-zig --state open --search "head:deps/"` finds a PR, continue on its branch, rebased onto `upstream/main` if that has moved; PRs merge by fast-forward only. Otherwise run `git worktree add .worktrees/deps-YYYY-MM-DD -b deps/YYYY-MM-DD upstream/main`.
2. For a fork, add a worktree beside its checkout: `git -C vendor/<fork> worktree add ../<fork>-deps-YYYY-MM-DD <base>`.

Edit only run worktrees, never the root, `h2o/`, or `vendor/*` checkouts. Stage files by name; `git add -A` or `git add .` would commit the devshell's `.zig-cache-global/`.

Complete when: every edit happens in a run worktree.

## 3. Bump and classify

Follow steps 1 to 4 of [SKILL.md](SKILL.md) for each update, one scoped commit each, such as `h2o: update upstream to <short-sha>` or `nix: update flake inputs`. Finish with a `docs:` commit that adds only the new versions to `CHANGELOG.adoc`.

The h2o-zig PR is the fork review SKILL.md requires. A fork rebase is clean when `git range-diff <old-base>..<old-tip> <new-base>..<new-tip>` shows every downstream commit adding and removing the same lines as before; changed context lines are fine, including conflicts caused only by neighbouring upstream edits. Publish a clean fork branch before pinning it, because `zon2lock` and Nix need a published commit.

Change Zig only when an update fails to build with the current version; a higher `minimum_zig_version` is not a reason, because Zig does not enforce it. Pick the oldest tagged release every dependency builds with, and update `minimum_zig_version`, `AGENTS.md`, `README.adoc`, and `CHANGELOG.adoc`. If only a dev snapshot works, the update is complicated. Never use `zig-master`.

An update is straightforward when all of these hold; otherwise it is complicated:

- SKILL.md steps 3 and 4 complete, with `zon2lock` succeeding unaided. Never hand-edit lock files.
- h2o-zig changes only pins, the lock, version strings, `build.zig` source lists for files upstream added or removed, the Zig version, and the changelog.
- Fork changes are version strings plus a clean rebase.

If flake input updates are complicated, also propose updating them less often.

Complete when: every update is committed and classified.

## 4. Publish

Push the `deps/` branch to `upstream` and open a PR against `main` on `outskirtslabs/h2o-zig`, or comment on the existing one. Include only straightforward updates. List each dependency as old to new revision, every fork commit, validation results, and anything held back. Mention `@Ramblurr`.

Leave complicated h2o-zig work unpushed in its worktree. Never push to `main` except the step 1 fast-forward, merge, or delete remote branches. Force-push only this run's `deps/` branch after a step 2 rebase, with `--force-with-lease`.

Complete when: the PR has every straightforward update, and no complicated h2o-zig work left the machine.

## 5. Report and clean up

Remove the worktrees of published work; keep those holding complicated updates. Also remove earlier runs' `t3/daily-dependency-bump*` worktrees and branches that have no changes besides `.zig-cache*` and no commits beyond `upstream/main`; keep any others and report them. End with the PR URL; one line per dependency (old to new, straightforward or complicated); validation results; and each complicated update's blocker, worktree path, and proposed fix.
