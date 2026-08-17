# 01 — Define command grammar, help, and version

**What to build:** Give operators a clear command contract before the command reads any Journal Entries. The operator can request complete help or exact version information. Invalid command forms fail with a clear diagnostic and status 2.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `--help` describes the two required separators, all `journql` options, the allowed Journal Selection controls, formats and their default, stable relation columns, default Journal Selection, access behavior, temporary disk use, and examples.
- [ ] `--help` returns status 0 without starting `journalctl` or DuckDB.
- [ ] `--version` identifies `journql` 0.1.0 and DuckDB 1.4.5, returns status 0, and does not start `journalctl` or DuckDB.
- [ ] A Journal Query requires two `--` separators and exactly one shell argument after the second separator.
- [ ] Unknown, repeated, or conflicting `journql` options return status 2 with a diagnostic on standard error.
- [ ] Bats tests check the public command behavior for help, version, valid grammar, missing arguments, additional arguments, and invalid options.
- [ ] `make test` passes.
