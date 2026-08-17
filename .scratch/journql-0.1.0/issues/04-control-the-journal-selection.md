# 04 — Control the Journal Selection

**What to build:** Let an operator use the specified safe `journalctl` selection controls while `journql` keeps control of data format and execution mode. Reject selection arguments that can change state, select unsupported sources, cause interaction, or do work other than returning Journal Entries.

**Blocked by:** 02 — Run a basic Journal Query.

**Status:** ready-for-agent

- [ ] The command accepts the specified system, user, and merge source controls.
- [ ] The command accepts the specified time, cursor, and boot position controls.
- [ ] The command accepts the specified unit, user unit, identifier, priority, facility, text pattern, case, and kernel selection controls.
- [ ] The command accepts the specified line limit and reverse-order controls.
- [ ] Documented short, long, separate-value, and equals-value forms work where applicable.
- [ ] Positional `FIELD=VALUE` matches and the `+` journal disjunction operator work.
- [ ] Path matches and other positional arguments return status 2.
- [ ] Unsupported sources, output controls, field controls, paging, follow mode, cursor files, maintenance commands, state-changing commands, and non-entry information commands return status 2.
- [ ] An operator cannot override forced JSON, complete-value, or no-pager controls.
- [ ] Bats tests check each allowed and rejected option class at the public command boundary.
- [ ] `make test` passes.
