# journql 0.1.0

`journql` reads a systemd Journal Selection and runs a Journal Query with
DuckDB. It gives the Journal Query a stable `journal` relation and keeps the
complete Journal Entry in the `entry` column.

## Supported environment

This release supports Debian-family Linux systems with `systemd` and
`journalctl`. Packages are available for `amd64` and `arm64`. The package
includes DuckDB 1.4.5.

This release does not support macOS, other operating systems, or a non-systemd
journal source.

## Installation

Install the package for your architecture. For example:

```sh
sudo dpkg -i journql_0.1.0_amd64.deb
```

If `dpkg` reports missing dependencies, install them and run the package
installation again:

```sh
sudo apt-get -f install
sudo dpkg -i journql_0.1.0_amd64.deb
```

The package depends on `systemd` and `libc6`.

## Journal access

`journql` runs `journalctl` with the authority of the current user. It does
not run `sudo` and it does not raise the user's authority.

The package keeps its existing access message. The message includes this
command:

```text
sudo usermod -aG systemd-journal $USER
```

If access is denied, add the current user to the `systemd-journal` group, then
start a new login session. The group can be checked with `id`.

## Command form

The command has three sections. Use two `--` separators:

```text
journql [OPTIONS] -- [JOURNAL SELECTION] -- 'JOURNAL QUERY'
```

The first separator ends `journql` options. The second separator ends the
Journal Selection. The Journal Query is exactly one shell argument. Put the
Journal Query in single quotes so that the shell passes the SQL text as one
argument.

Examples:

```sh
# Use the normal Journal Selection and return a table Query Result.
journql -- -- 'SELECT count(*) FROM journal;'

# Select entries for one systemd unit and return CSV.
journql --format csv -- --unit sshd.service -- \
  'SELECT timestamp, message FROM journal ORDER BY timestamp;'

# Select recent entries and run more than one SQL statement.
journql -- --since '1 hour ago' --lines 100 -- \
  'CREATE TABLE recent AS SELECT * FROM journal; SELECT count(*) FROM recent;'
```

`--help` shows the command form and all supported controls. `--version` shows
the journql and DuckDB versions. Both options must be used alone.

## Journal Selection

With no Journal Selection arguments, `journql` uses the normal `journalctl`
selection. It does not add a time limit or a size limit.

The supported selection controls are:

- `--system`, `--user`, and `--merge` (`-m`)
- `--since` (`-S`), `--until` (`-U`), `--cursor` (`-c`),
  `--after-cursor`, and `--boot` (`-b`)
- `--unit` (`-u`), `--user-unit`, `--identifier` (`-t`),
  `--priority` (`-p`), and `--facility`
- `--grep` (`-g`), `--ignore-case` (`-i`),
  `--case-sensitive[=BOOLEAN]`, and `--dmesg` (`-k`)
- `--lines` (`-n`) and `--reverse` (`-r`)
- native journal field matches such as `MESSAGE=failed` and the `+`
  disjunction operator

Value options accept a separate value or the documented `--option=value` form
where applicable. The command accepts the documented short forms. Use a
separate value, such as `-u sshd.service`, when in doubt.

`journql` always controls the journalctl data and execution mode. It requests
complete newline-delimited JSON, disables the pager, and does not let the
Journal Selection change the Query Result format. Path matches are not
supported. The command rejects output controls, paging, follow mode, cursor
files, remote or alternate journal sources, maintenance commands, and other
commands that do not only select Journal Entries.

## Journal Query and Query Result

The Journal Query is SQL for DuckDB. One Journal Query argument can contain
one or more SQL statements. `journql` passes the SQL text to DuckDB and does
not rewrite the Query Result.

Use `--format` once to select the Query Result format:

| Format | Meaning |
| --- | --- |
| `table` | Table format. This is the default. |
| `csv` | CSV format with column names. |
| `json` | JSON format. |

Only Query Results go to standard output. `journql`, `journalctl`, and DuckDB
diagnostics go to standard error. A successful command returns status `0`.
Invalid command syntax and unsupported Journal Selection arguments return
status `2`. A failure from `journalctl` or DuckDB returns that command's
failure status.

## `journal` relation

The `journal` relation always has these stable columns, including for an empty
Journal Selection:

| Column | SQL type | Source Journal Entry field |
| --- | --- | --- |
| `timestamp` | `TIMESTAMPTZ` | `__REALTIME_TIMESTAMP` |
| `message` | `VARCHAR` | `MESSAGE` |
| `hostname` | `VARCHAR` | `_HOSTNAME` |
| `systemd_unit` | `VARCHAR` | `_SYSTEMD_UNIT` |
| `user_unit` | `VARCHAR` | `_SYSTEMD_USER_UNIT` |
| `identifier` | `VARCHAR` | `SYSLOG_IDENTIFIER` |
| `priority` | `INTEGER` | `PRIORITY` |
| `pid` | `BIGINT` | `_PID` |
| `uid` | `BIGINT` | `_UID` |
| `gid` | `BIGINT` | `_GID` |
| `boot_id` | `VARCHAR` | `_BOOT_ID` |
| `transport` | `VARCHAR` | `_TRANSPORT` |
| `cursor` | `VARCHAR` | `__CURSOR` |
| `entry` | `JSON` | Complete Journal Entry |

The stable columns use non-throwing conversion. A missing, repeated, binary,
or invalid stable source value becomes `NULL`. For example, an invalid
numeric value does not stop the Journal Query. The `entry` JSON column keeps
the complete original Journal Entry, including application-defined fields and
values that cannot convert to a stable column.

## Temporary disk use and limits

Before DuckDB starts, `journql` writes the complete Journal Selection to a
private file in `$TMPDIR`. If `TMPDIR` is empty or not set, it uses `/tmp`.
The file contains newline-delimited JSON, has permissions for the current user
only, and is removed after normal completion, command failure, or `HUP`,
`INT`, or `TERM`.

The temporary file can use disk space approximately equal to the JSON size of
the Journal Selection. The DuckDB database is in memory. If disk or memory is
limited, select fewer Journal Entries with controls such as `--since`,
`--until`, `--lines`, or a narrower field match.

Version 0.1.0 does not set a maximum number of Journal Entries, a maximum
Journal Selection size, or a maximum Journal Query size. The practical limits
come from `journalctl`, the temporary file system, available memory, DuckDB,
and the operating system.

Version 0.1.0 is read-only. It does not write to the systemd journal, provide a
persistent cache, infer application-defined SQL columns, or support remote
journals, journal maintenance, interactive paging, or follow mode.
