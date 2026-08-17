# 07 — Secure the Journal Selection snapshot

**What to build:** Protect the on-disk Journal Selection for its complete lifetime. The snapshot uses the configured temporary area, is accessible only to the current user, and does not remain after any supported exit path.

**Blocked by:** 02 — Run a basic Journal Query.

**Status:** ready-for-agent

- [ ] The snapshot uses the configured temporary directory, or the standard temporary directory when none is configured.
- [ ] The snapshot name is non-predictable and the file is accessible only to the current user.
- [ ] The command removes the snapshot after successful completion.
- [ ] The command removes the snapshot after a `journalctl` or DuckDB failure.
- [ ] The command removes the snapshot after `HUP`, `INT`, or `TERM`.
- [ ] The command never retains the snapshot for caching or diagnosis.
- [ ] Bats tests check the directory choice, permissions, normal cleanup, failure cleanup, and signal cleanup through the public command.
- [ ] `make test` passes.
