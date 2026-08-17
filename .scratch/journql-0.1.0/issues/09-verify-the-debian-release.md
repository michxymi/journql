# 09 — Verify the Debian release

**What to build:** Produce and verify the complete `journql` 0.1.0 Debian release for both supported architectures. The installed command gives the specified behavior on Linux and the package keeps its existing public structure and bundled DuckDB records.

**Blocked by:** 03 — Support Query Result formats and multiple statements; 04 — Control the Journal Selection; 05 — Handle abnormal and empty Journal Selections; 06 — Preserve diagnostics and failure statuses; 07 — Secure the Journal Selection snapshot; 08 — Complete operator documentation.

**Status:** ready-for-agent

- [ ] The package version is 0.1.0 and it bundles DuckDB 1.4.5.
- [ ] The existing Debian source structure, installed command, private DuckDB executable, license records, maintainer scripts, and journal-access message remain present.
- [ ] Packages build for `amd64` and `arm64` with the correct architecture-specific DuckDB executable.
- [ ] Package metadata and runtime dependencies are correct for both architectures.
- [ ] `make test` passes after all code changes.
- [ ] `make lint` passes after all packaging changes.
- [ ] Applicable CLI tests run in an Ubuntu Docker container with Journal Entry fixtures when no active systemd journal is available.
- [ ] Applicable package checks run in Ubuntu Docker for both supported architectures where the host can execute them.
- [ ] The installed package passes a basic Journal Query and help/version checks in its supported Linux environment.
