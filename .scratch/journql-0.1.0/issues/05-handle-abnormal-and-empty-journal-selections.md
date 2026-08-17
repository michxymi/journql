# 05 — Handle abnormal and empty Journal Selections

**What to build:** Keep the `journal` relation stable when Journal Entries contain missing or abnormal values and when the Journal Selection is empty. Operators can continue their Journal Query and can inspect the original JSON value.

**Blocked by:** 02 — Run a basic Journal Query.

**Status:** ready-for-agent

- [ ] A missing stable source field becomes `NULL` with the specified stable SQL type.
- [ ] A repeated, binary, or invalid stable source value becomes `NULL` and does not stop the Journal Query.
- [ ] The `entry` JSON column preserves application-defined fields and abnormal values from the complete Journal Entry.
- [ ] An empty Journal Selection creates an empty `journal` relation with every specified stable column and SQL type.
- [ ] A Journal Query runs successfully against the empty relation.
- [ ] Timestamp conversion and stable numeric conversions do not throw for invalid source values.
- [ ] Bats tests use fixtures for missing, repeated, binary, invalid, application-defined, and empty cases.
- [ ] `make test` passes.
