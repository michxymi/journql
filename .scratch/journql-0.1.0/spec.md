# journql 0.1.0

Status: ready-for-agent

## Problem Statement

An operator can read Linux Journal Entries with `journalctl`, but complex analysis is difficult with its selection and display controls. The operator needs one command that gets a local Journal Selection and makes it available to DuckDB. The command must have clear boundaries between its own options, `journalctl` selection options, and the Journal Query. It must preserve the complete Journal Entry, give stable columns for common work, keep diagnostics separate from the Query Result, and work as the existing Debian package on `amd64` and `arm64`.

## Solution

Release `journql` 0.1.0 as a one-shot Linux command. The operator supplies `journql` options, an allowed Journal Selection, and one quoted Journal Query. The command gets the complete Journal Selection as newline-delimited JSON, stores it in a private temporary file, creates a DuckDB `journal` relation, runs the Journal Query, sends the Query Result to standard output, and exits.

The command uses two required `--` separators. The first separator ends the `journql` options. The second separator ends the Journal Selection. The Journal Query is exactly one shell argument and can contain one or more SQL statements.

The `journal` relation gives stable, lower-case columns for common fields and an `entry` JSON column for the complete Journal Entry. Invalid or abnormal values do not stop the Journal Query. The package continues to bundle DuckDB 1.4.5 and supports Debian-family Linux systems with systemd.

## User Stories

1. As an operator, I want to analyze a Journal Selection with SQL, so that I can answer questions that `journalctl` display controls do not answer.
2. As an operator, I want one one-shot command, so that I do not have to prepare a database before analysis.
3. As an operator, I want clear separators between command languages, so that shell argument handling is predictable.
4. As an operator, I want to supply the Journal Query as one quoted argument, so that spaces and SQL punctuation stay in the query.
5. As an operator, I want to run more than one SQL statement, so that I can do multi-step analysis in one DuckDB session.
6. As an operator, I want the normal `journalctl` selection when I give no selection options, so that the command follows familiar behavior.
7. As an operator, I want to select system or user Journal Entries, so that I can analyze the applicable journal source.
8. As an operator, I want to select entries by time, cursor, or boot, so that I can analyze a precise period or position.
9. As an operator, I want to select entries by unit, user unit, identifier, priority, facility, text pattern, or kernel source, so that I can reduce the Journal Selection before analysis.
10. As an operator, I want to set limits and reverse order, so that I can control the size and order of the Journal Selection.
11. As an operator, I want to use native `FIELD=VALUE` matches and the `+` disjunction operator, so that I can use normal journal matching rules.
12. As an operator, I want unsafe or unrelated `journalctl` options to be rejected, so that the command stays a local, finite, read-only journal reader.
13. As an operator, I want complete field values in the Journal Selection, so that truncation does not change my analysis.
14. As an operator, I want paging to be disabled, so that the command can run without interaction.
15. As an operator, I want a table Query Result by default, so that interactive use is easy to read.
16. As an operator, I want CSV and JSON Query Result formats, so that other tools can process the result.
17. As an operator, I want column names in CSV results, so that the data has clear meaning.
18. As an operator, I want stable lower-case columns for common journal fields, so that common Journal Queries are simple.
19. As an operator, I want timestamps as UTC-aware SQL values, so that time comparisons are correct and repeatable.
20. As an operator, I want invalid stable-field values to become `NULL`, so that one abnormal Journal Entry does not stop the Journal Query.
21. As an operator, I want the complete Journal Entry in a JSON column, so that I can inspect application-defined and abnormal fields.
22. As an operator, I want an empty Journal Selection to create an empty relation, so that aggregate and schema queries can still run.
23. As an operator, I want only Query Results on standard output, so that scripts can consume them safely.
24. As an operator, I want command, `journalctl`, and DuckDB diagnostics on standard error, so that errors do not corrupt the Query Result.
25. As an operator, I want `journalctl` failures to stop DuckDB, so that I do not analyze incomplete data as if it were complete.
26. As an operator, I want useful exit statuses, so that scripts can distinguish syntax, journal, and query failures.
27. As an operator, I want the command to use my current journal access, so that it does not silently request more authority.
28. As an operator, I want a private Journal Selection snapshot, so that other users cannot read its temporary data.
29. As an operator, I want temporary data removed after success, failure, or a termination signal, so that Journal Entries do not remain on disk.
30. As an operator, I want complete help text, so that I can learn the grammar, allowed options, schema, access behavior, and limits from the command.
31. As an operator, I want exact version information for `journql` and DuckDB, so that I can report the installed components.
32. As a package user, I want the existing Debian package layout to stay stable, so that upgrades do not change installed interfaces.
33. As a package user, I want packages for `amd64` and `arm64`, so that I can use the command on both supported architectures.
34. As a maintainer, I want automated CLI tests at the command boundary, so that tests check external behavior and not shell implementation details.
35. As a maintainer, I want final checks in Ubuntu containers, so that macOS development does not hide Linux errors.
36. As a maintainer, I want fixture Journal Entries in containers without an active journal, so that verification is repeatable.
37. As a maintainer, I want package lint checks after package changes, so that the Debian artifact keeps the required quality.
38. As a maintainer, I want each commit to have one purpose, so that review and rollback stay clear.

## Implementation Decisions

- Implement version 0.1.0 as the existing POSIX shell command and Debian package.
- Use this command contract: `journql` options, the first `--`, zero or more allowed `journalctl` selection arguments, the second `--`, and exactly one Journal Query argument.
- Require both separators for a Journal Query. Treat a missing query or an additional argument after the query as invalid syntax.
- Permit no short aliases for `journql` options in version 0.1.0.
- Support `--format` with `table`, `csv`, and `json`. Use `table` as the default. Map these values directly to the applicable DuckDB formatter. Do not post-process a Query Result.
- Make `--help` and `--version` complete successfully without reading the journal.
- Make the help text describe the command grammar, separators, options, allowed Journal Selection controls, formats, stable columns, default Journal Selection, temporary disk use, access behavior, and examples.
- Make the version text identify `journql` 0.1.0 and DuckDB 1.4.5.
- Reject unknown, repeated, or conflicting `journql` options with status 2.
- Use the normal `journalctl` default when the operator supplies no Journal Selection options. Do not add a time or size limit.
- Allow the documented short, long, separate-value, and `--option=value` forms for these Journal Selection groups: system and user sources; time, cursor, and boot position; unit, identifier, priority, facility, text pattern, case handling, and kernel selection; line limits and reverse order.
- Allow a positional match only in `FIELD=VALUE` form. Allow `+` as the journal disjunction operator. Reject path matches and other positional forms.
- Reject remote, machine, directory, file, root, image, and namespace sources. Reject output controls, field controls, paging, follow mode, cursor files, maintenance commands, state-changing commands, and information commands that do not return Journal Entries.
- Invoke `journalctl` with forced newline-delimited JSON, complete field values, and no pager. Do not let an operator override these controls.
- Run `journalctl` with the current user's authority. Do not elevate authority and do not change group membership. Preserve `journalctl` warnings and errors on standard error.
- Get the complete Journal Selection before DuckDB starts. Check the `journalctl` status before DuckDB starts.
- Store the Journal Selection in a non-predictable file under the configured temporary directory, or the standard temporary directory when it is not configured. Give access only to the current user.
- Remove the temporary file after success, after failure, and after `HUP`, `INT`, or `TERM`. Do not retain it for caching or diagnosis.
- Use the bundled DuckDB 1.4.5 executable and an in-memory database. Do not create a persistent database.
- Set the DuckDB session time zone to UTC and create the `journal` relation before the Journal Query runs.
- Pass the supplied SQL text to DuckDB without classification or restriction. The SQL has the current user's file and process authority. Version 0.1.0 does not promise read-only SQL.
- Expose these stable `journal` columns: `timestamp` as `TIMESTAMPTZ`; `message`, `hostname`, `systemd_unit`, `user_unit`, `identifier`, `boot_id`, `transport`, and `cursor` as `VARCHAR`; `priority` as `INTEGER`; `pid`, `uid`, and `gid` as `BIGINT`; and `entry` as `JSON`.
- Map the stable columns to `__REALTIME_TIMESTAMP`, `MESSAGE`, `PRIORITY`, `_HOSTNAME`, `_SYSTEMD_UNIT`, `_SYSTEMD_USER_UNIT`, `SYSLOG_IDENTIFIER`, `_PID`, `_UID`, `_GID`, `_BOOT_ID`, `_TRANSPORT`, and `__CURSOR`.
- Convert `__REALTIME_TIMESTAMP` from Unix epoch microseconds to `TIMESTAMPTZ`.
- Convert each valid scalar stable field to its stable SQL type. Use `NULL` when the source field is missing, repeated, binary, or invalid. Do not stop the Journal Query for a conversion error.
- Preserve the complete JSON object in `entry`, including application-defined fields and abnormal values.
- Create an empty `journal` relation with the stable schema when the Journal Selection is empty. Run the Journal Query against this relation.
- Send only Query Results to standard output. Send `journql`, `journalctl`, and DuckDB diagnostics to standard error.
- Return status 0 after a successful Journal Query. Return status 2 for invalid command syntax or an unsupported Journal Selection option. Return the `journalctl` status when it fails. Return the DuckDB status when it fails.
- Preserve the existing Debian source and installed package structure, the bundled DuckDB and license records, both package architectures, and the current build and lint process.
- Permit packaging corrections when reliable CLI behavior needs them.
- Support Debian-family Linux systems with systemd, `journalctl`, and a readable local system or user journal. Make no support claim for macOS, Linux without systemd, containers without an active journal, or other operating systems.
- This design follows the ADR that requires stable columns plus the complete raw Journal Entry. It also follows the ADR that separates `journql` options, Journal Selection arguments, and the Journal Query.

## Testing Decisions

- Test external command behavior. Do not test private shell functions or exact internal command construction unless that construction is visible at the command boundary.
- Use the existing Bats command test as the highest test seam. Extend it to start the packaged command with controlled `journalctl` and DuckDB dependencies and then check arguments, standard streams, status, temporary-file behavior, and Query Results.
- Use fixtures for Journal Entries because a standard Ubuntu container has no active systemd journal.
- Cover the command grammar, both separators, missing and additional query arguments, known options, unknown options, repeated options, and conflicting options.
- Cover help and version behavior without journal access.
- Cover table, CSV, and JSON Query Result formats and the default format.
- Cover the default Journal Selection and each class of allowed selection option. Cover separate-value and equals-value forms where `journalctl` documents both forms.
- Cover rejected source, output, paging, follow, cursor-file, maintenance, state-changing, and information options.
- Cover valid native field matches, the `+` operator, invalid positional arguments, and path matches.
- Cover the stable column names and SQL types, timestamp conversion, UTC session behavior, and the complete `entry` JSON value.
- Cover missing, repeated, binary, and invalid stable-field values. Confirm that these values become `NULL` and do not stop a Journal Query.
- Cover an empty Journal Selection and confirm that the stable relation exists.
- Cover `journalctl` and DuckDB failures. Confirm that DuckDB does not start after a `journalctl` failure.
- Cover standard-output and standard-error separation and the required exit statuses.
- Cover private temporary-file permissions and cleanup after success, failure, `HUP`, `INT`, and `TERM`.
- Use the current small Bats smoke test as prior art for command invocation. Keep all project tests and fixtures in the repository test area.
- Run the repository test target after each code change.
- Use the Debian package build and lint process as the package seam. Run the package lint target after each packaging change.
- Perform final Linux verification in an Ubuntu Docker container. Run the applicable tests and package checks in the container for both supported architectures where the host can execute them.
- A good test gives a controlled Journal Selection to the public command and checks only behavior that an operator or calling process can observe.

## Out of Scope

- An interactive DuckDB session.
- A persistent database or cached Journal Selection.
- Live or follow-mode Journal Queries.
- Remote, machine, container, directory, file, root, image, or namespace journal sources.
- Arbitrary `journalctl` options.
- SQL from a file or standard input.
- Short aliases for `journql` options.
- Direct use of the systemd library.
- Stable SQL columns for application-defined journal fields.
- A promise that a Journal Query is read-only.
- A formal time, memory, or Journal Selection size promise.
- Support for systems without systemd.
- A macOS support claim.
- A manual page for version 0.1.0.

## Further Notes

- A large Journal Selection can use temporary disk space equal to its JSON representation. The help text must tell operators to select fewer Journal Entries when necessary.
- A successful `journalctl` status does not prove that the current user could read every Journal Entry. Keep the existing package message about the `systemd-journal` group.
- Release documentation must include installation, journal access, examples, relation schema, result formats, and limits.
- Keep each commit limited to one purpose.
- There are no open questions.
