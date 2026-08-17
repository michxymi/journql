# 06 — Preserve diagnostics and failure statuses

**What to build:** Give operators and calling scripts reliable standard streams and exit statuses. A failed Journal Selection never becomes an incomplete DuckDB relation, and diagnostics never corrupt the Query Result.

**Blocked by:** 02 — Run a basic Journal Query.

**Status:** ready-for-agent

- [ ] Only Query Results go to standard output.
- [ ] `journql`, `journalctl`, and DuckDB diagnostics go to standard error.
- [ ] A successful Journal Query returns status 0.
- [ ] Invalid `journql` syntax or an unsupported Journal Selection argument returns status 2.
- [ ] A `journalctl` failure returns the `journalctl` status and does not start DuckDB.
- [ ] A DuckDB failure returns the DuckDB status.
- [ ] `journalctl` warnings remain visible on standard error when journal access otherwise succeeds.
- [ ] Bats tests check standard streams, statuses, and process ordering through the public command.
- [ ] `make test` passes.
