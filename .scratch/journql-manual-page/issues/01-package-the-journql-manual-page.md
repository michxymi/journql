# 01 — Package the journql(1) manual page

**What to build:** Give a Debian package user a complete `journql(1)` manual page through the standard Linux manual system. The package must install a reproducibly compressed page that documents the implemented command, and package verification must prevent its accidental removal.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The Debian package installs a valid `journql(1)` page in the standard section 1 manual location.
- [ ] The manual page is complete and self-contained. It documents the command purpose, syntax, options, Journal Selection, Journal Query, Query Result formats, `journal` relation, environment, files, exit statuses, limits, examples, and applicable systemd references.
- [ ] The manual uses the canonical terms Journal Entry, Journal Selection, Journal Query, and Query Result.
- [ ] The manual documents only current implemented behavior and agrees with the command help and operator documentation.
- [ ] The manual explains the two required separators and that the Journal Query is exactly one shell argument.
- [ ] The manual documents all supported Journal Selection groups and states that unsupported `journalctl` arguments are rejected.
- [ ] The manual documents all stable relation columns, their SQL types, abnormal-value conversion to `NULL`, and the complete raw Journal Entry in the `entry` JSON column.
- [ ] The examples cover a basic query, Journal Selection controls, JSON Query Results, and access to the raw Journal Entry.
- [ ] The manual references `journalctl(1)` and `systemd.journal-fields(7)` and does not reference a private DuckDB manual page.
- [ ] The uncompressed source is hand-maintained in the Debian package source structure. No documentation generator or generated gzip file is added to version control.
- [ ] Package staging compresses the page with maximum gzip compression and without an embedded original name or timestamp.
- [ ] The manual header has no application version or release date that can become stale.
- [ ] Release-package verification confirms that the compressed page is present, valid, decompressible, and contains the public syntax and principal sections.
- [ ] Lintian does not report `no-manual-page` for the installed command, and no override hides this warning.
- [ ] The current changelog entry contains one short manual-page bullet, and all existing uncommitted changelog text is preserved.
- [ ] The existing Debian package structure and supported architectures remain unchanged.
- [ ] `make test` passes.
- [ ] `make lint` passes after the packaging change.
- [ ] Final applicable tests and package checks pass in an Ubuntu Docker container, with Journal Entry fixtures if no active systemd journal is available.
