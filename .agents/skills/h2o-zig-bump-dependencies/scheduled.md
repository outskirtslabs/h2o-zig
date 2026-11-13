# Scheduled dependency run

A T3 schedule starts this run daily at 05:00 in a fresh thread. No human answers: decide from these rules, and report anything they do not cover instead of guessing.

## 1. Find updates

Check every entry in `build.zig.zon`, including lazy ones:

- H2O: latest `upstream/master`.
- Everything else: latest stable release, never a prerelease.
- Wrapper forks, which package someone else's library for Zig (`Ramblurr/boringssl`): also any upstream wrapper commit the fork lacks that changes a file in the fork's `build.zig.zon` `.paths`. Commits outside `.paths`, such as README or CI changes, do not count.
- Library forks, which fork the library itself (`Ramblurr/libaegis`): stable releases only.

Update every flake input except `zig2nix`, which selects the Zig version:

```bash
nix flake update $(nix flake metadata --json | jq -r '.locks.nodes.root.inputs | keys[] | select(. != "zig2nix")')
```

If nothing is new, report `No updates.` and stop.

Complete when: every dependency has a current and a target revision.

## 2. Set up the workspace

1. Run `git fetch --multiple upstream origin`.
2. If `gh pr list --repo outskirtslabs/h2o-zig --state open --search "head:deps/"` finds a PR, work on its branch. If `upstream/main` has moved, rebase the branch onto it; PRs merge by fast-forward only.
3. Otherwise run `git worktree add .worktrees/deps-YYYY-MM-DD -b deps/YYYY-MM-DD upstream/main`.
4. For a fork, add a worktree beside its checkout: `git -C vendor/<fork> worktree add ../<fork>-deps-YYYY-MM-DD <base>`.

Edit only run worktrees, never the root, `h2o/`, or `vendor/*` checkouts. Stage files by name: the devshell writes `.zig-cache-global/` into the working directory, and `git add -A` or `git add .` would commit it.

Complete when: every edit happens in a run worktree.

## 3. Bump and classify

Follow steps 1 to 4 of [SKILL.md](SKILL.md) for each update, with one scoped commit each, such as `h2o: update upstream to <short-sha>` or `nix: update flake inputs`. Finish with a `docs:` commit that adds the new versions to `CHANGELOG.adoc`; record versions only, not upstream behaviour.

For a fork, rebase its downstream commits onto the new base and compare them with `git range-diff <old-base>..<old-tip> <new-base>..<new-tip>`. The rebase is clean when every downstream commit adds and removes the same lines as before; differences in context lines are fine, including conflicts caused only by neighbouring upstream edits. If clean, push the fork branch before pinning it, because `zon2lock` and Nix need a published commit:

- Use a new branch name that follows the fork conventions in [SKILL.md](SKILL.md). If the name is taken, append the next `-vN`, such as `h2o-zig/boringssl-0.20261105.0-pic-v2`.
- Never move an existing fork branch. Confirm the commit exists remotely before pinning it.

Change Zig only when an update fails to build with the current version. A higher `minimum_zig_version` is not a reason, because Zig does not enforce it. Pick the oldest tagged release every dependency builds with, and update `minimum_zig_version`, `AGENTS.md`, `README.adoc`, and `CHANGELOG.adoc`. Never move to `zig-master`.

An update is straightforward when all of these hold; otherwise it is complicated:

- The full validation matrix passes.
- `zon2lock` succeeds unaided, and the bump explains every lock change. Never hand-edit lock files.
- h2o-zig changes only pins, the lock, version strings, `build.zig` source lists for files upstream added or removed, and the changelog.
- Fork changes are version strings plus a clean rebase.
- Zig is unchanged or moves to a tagged release.

If flake input updates are complicated, also propose updating them less often.

Complete when: every update is committed and classified.

## 4. Publish

Push the `deps/` branch to `upstream` and open a PR against `main` on `outskirtslabs/h2o-zig`, or comment on the existing one. Include only straightforward updates. List each dependency as old to new revision, every fork commit (the PR is their review), validation results, and anything held back. Mention `@Ramblurr`.

Leave complicated h2o-zig work unpushed in its worktree. Never push to `main`, merge, or delete remote branches. Force-push only this run's `deps/` branch after a step 2 rebase, with `--force-with-lease`.

Complete when: the PR has every straightforward update, and no complicated h2o-zig work left the machine.

## 5. Report and clean up

Remove the worktrees of published work; keep those holding complicated updates.

End with `No updates.`, or with: the PR URL; one line per dependency (old to new, straightforward or complicated); validation results; and for each complicated update, its blocker, worktree path, and proposed fix.
