# 08 — Complete operator documentation

**What to build:** Give operators complete and consistent instructions for installation, journal access, Journal Selection, Journal Queries, Query Result formats, relation columns, disk use, and supported limits.

**Blocked by:** 03 — Support Query Result formats and multiple statements; 04 — Control the Journal Selection; 05 — Handle abnormal and empty Journal Selections; 06 — Preserve diagnostics and failure statuses; 07 — Secure the Journal Selection snapshot.

**Status:** ready-for-agent

- [ ] Release documentation explains installation and the supported Debian-family Linux environment.
- [ ] Documentation explains current-user journal access and keeps the existing `systemd-journal` group message.
- [ ] Documentation gives examples with both separators, Journal Selection arguments, and quoted Journal Queries.
- [ ] Documentation lists Query Result formats and their default.
- [ ] Documentation lists every stable `journal` column, its SQL type, and the complete `entry` JSON column.
- [ ] Documentation explains `NULL` conversion for missing and abnormal stable fields.
- [ ] Documentation explains temporary disk use and tells operators to select fewer Journal Entries when necessary.
- [ ] Documentation states the applicable version 0.1.0 limits and non-goals.
- [ ] Command help and release documentation agree with implemented behavior.
- [ ] `make test` passes.
