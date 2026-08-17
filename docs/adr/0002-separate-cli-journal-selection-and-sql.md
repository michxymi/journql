# Separate CLI options, Journal Selection, and SQL

The `journql` command uses two `--` separators: `journql [options] -- [journalctl selection options] -- 'SQL'`. The three sections belong to different command languages, and the separators let the POSIX shell wrapper validate each section without rebuilding or evaluating command text. The Journal Query is exactly one shell argument, but that argument can contain multiple DuckDB SQL statements.
