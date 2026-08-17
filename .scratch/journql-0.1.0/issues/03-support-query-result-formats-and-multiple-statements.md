# 03 — Support Query Result formats and multiple statements

**What to build:** Let an operator select table, CSV, or JSON Query Results and run one or more SQL statements in the same Journal Query. The command sends each result set in the selected DuckDB format without post-processing it.

**Blocked by:** 02 — Run a basic Journal Query.

**Status:** ready-for-agent

- [ ] The default Query Result format is table.
- [ ] `--format table`, `--format csv`, and `--format json` select the applicable DuckDB formatter.
- [ ] CSV Query Results include column names.
- [ ] An unknown format or a repeated `--format` option returns status 2 before journal access.
- [ ] One Journal Query argument can contain multiple semicolon-separated SQL statements.
- [ ] The selected format applies to every result set, and `journql` does not change the DuckDB Query Result.
- [ ] Bats tests check each format, the default, invalid formats, and multiple SQL statements through the public command.
- [ ] `make test` passes.
