# 02 — Run a basic Journal Query

**What to build:** Let an operator run one Journal Query against the default Journal Selection. The command gets the Journal Entries as complete JSON, creates the stable DuckDB `journal` relation, returns a table Query Result, and exits.

**Blocked by:** 01 — Define command grammar, help, and version.

**Status:** ready-for-agent

- [ ] With no selection arguments, the command uses the normal `journalctl` Journal Selection without an added time or size limit.
- [ ] The command forces newline-delimited JSON, complete field values, and no pager when it starts `journalctl`.
- [ ] The command runs `journalctl` with the current user's authority and gets the complete Journal Selection before DuckDB starts.
- [ ] The DuckDB session uses DuckDB 1.4.5, an in-memory database, and the UTC time zone.
- [ ] The `journal` relation exposes all stable columns and the complete Journal Entry in the `entry` JSON column, as defined in the specification.
- [ ] A normal scalar source value converts to its specified stable SQL type, including epoch-microsecond conversion for `timestamp`.
- [ ] A valid Journal Query returns its table Query Result on standard output and status 0.
- [ ] The Journal Query text passes to DuckDB as supplied and is not classified or restricted.
- [ ] The initial Journal Selection snapshot has private permissions and is removed after successful use.
- [ ] Bats tests use fixture Journal Entries and check the complete path through the public command.
- [ ] `make test` passes.
