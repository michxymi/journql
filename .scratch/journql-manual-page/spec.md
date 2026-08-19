# Add the journql manual page

Status: ready-for-agent

## Problem Statement

A person who installs the Debian package gets the `journql` command but does not get a manual page. The package therefore produces the Lintian `no-manual-page` warning for the installed command. The person must use repository documentation or command help instead of the standard Linux manual system.

## Solution

Add a complete `journql(1)` manual page to the Debian package. The page will be self-contained and will document only the implemented command behavior. It will explain the command syntax, the two separators, Journal Selection controls, Journal Queries, Query Result formats, the `journal` relation, status values, temporary storage, limits, and examples.

Keep an uncompressed, hand-maintained manual source in the Debian package source structure. During package staging, compress it reproducibly and install it in the standard section 1 manual directory. Verify the installed artifact at the Debian package boundary and use Lintian to confirm that the package no longer produces the missing-manual warning.

## User Stories

1. As a package user, I want `man journql` to open a manual page, so that I can learn how to use the installed command.
2. As a package user, I want the manual page in section 1, so that it is in the standard location for a user command.
3. As an operator, I want a short description of `journql`, so that I can understand its purpose before I run it.
4. As an operator, I want the complete command syntax, so that I can form a valid invocation.
5. As an operator, I want the two `--` separators explained, so that I can keep `journql` options, the Journal Selection, and the Journal Query separate.
6. As an operator, I want all `journql` options documented, so that I can select the required Query Result format and use command information options.
7. As an operator, I want supported Journal Selection controls documented, so that I can choose the applicable Journal Entries.
8. As an operator, I want unsupported Journal Selection behavior explained, so that I do not expect arbitrary `journalctl` arguments to work.
9. As an operator, I want the Journal Query argument rules documented, so that quoting and multiple SQL statements work as expected.
10. As an operator, I want table, CSV, and JSON Query Result formats documented, so that I can select a format for a person or another program.
11. As an operator, I want every stable `journal` column and SQL type documented, so that I can write correct Journal Queries.
12. As an operator, I want the complete `entry` JSON column documented, so that I can use fields that do not have stable columns.
13. As an operator, I want abnormal and missing field behavior documented, so that I understand when a stable column contains `NULL`.
14. As an operator, I want environment and temporary-file behavior documented, so that I can control temporary storage and understand its security properties.
15. As an operator, I want installed file locations documented, so that I can identify the private DuckDB executable used by the command.
16. As an operator, I want exit statuses documented, so that scripts can identify command, journal, and query failures.
17. As an operator, I want limits and nonfeatures documented, so that I do not depend on unsupported behavior.
18. As an operator, I want examples with the two separators, so that I can adapt a valid command quickly.
19. As an operator, I want an example with Journal Selection controls, so that I can restrict the Journal Entries before analysis.
20. As an operator, I want an example with JSON Query Results, so that I can use the command in a data-processing workflow.
21. As an operator, I want an example that reads the raw Journal Entry, so that I can analyze application-defined fields.
22. As an operator, I want references to the applicable systemd manuals, so that I can learn more about Journal Selection and journal fields.
23. As a maintainer, I want a readable uncompressed manual source, so that I can review changes in version control.
24. As a maintainer, I want reproducible manual compression, so that build timestamps do not change the package artifact.
25. As a maintainer, I want package verification to check the installed manual page, so that a staging error cannot silently remove it.
26. As a maintainer, I want Lintian to accept the package without an override for the missing manual, so that the package meets the applicable Debian quality check.
27. As a maintainer, I want the manual to contain only implemented behavior, so that it does not promise planned features.
28. As a maintainer, I want the manual to use the domain glossary terms, so that it agrees with command help and operator documentation.
29. As a maintainer, I want the current changelog entry to record this packaging change, so that the release history explains why the package changed.
30. As a maintainer on macOS, I want final checks to run in Ubuntu Docker, so that the manual and package are verified in the supported Linux environment.

## Implementation Decisions

- Create a complete, self-contained section 1 manual page. Do not make the installed page depend on access to the repository README.
- Maintain the manual source by hand. Do not add a documentation generator or a new documentation build dependency.
- Keep the uncompressed source in the Debian package source tree at the location that matches the installed manual hierarchy.
- During package staging, compress the source with maximum gzip compression and without storing the original name or timestamp. Do not commit a generated compressed file.
- Install the compressed page in the standard `man1` directory with the name `journql.1.gz`.
- Use a stable manual header without an application version or release date. This prevents stale header data and avoids build-time substitution.
- Include these sections: `NAME`, `SYNOPSIS`, `DESCRIPTION`, `OPTIONS`, `JOURNAL SELECTION`, `JOURNAL QUERY`, `RESULT FORMATS`, `JOURNAL RELATION`, `ENVIRONMENT`, `FILES`, `EXIT STATUS`, `LIMITS`, `EXAMPLES`, and `SEE ALSO`.
- Use the canonical terms Journal Entry, Journal Selection, Journal Query, and Query Result.
- Document only behavior that the current command implements. The command help and operator documentation are the factual source for the manual content.
- Describe the complete command grammar and the requirement that the Journal Query is exactly one shell argument.
- Describe all supported Journal Selection groups and explain that other `journalctl` arguments are rejected.
- Describe the stable columns and the complete raw Journal Entry as required by the applicable domain decision.
- Preserve the decision that separates `journql` options, Journal Selection arguments, and the Journal Query with two separators.
- Include a small example set that covers a basic query, Journal Selection controls, JSON Query Results, and raw Journal Entry access.
- Reference `journalctl(1)` and `systemd.journal-fields(7)`. Do not reference a DuckDB manual page because the package does not install one for its private DuckDB executable.
- Add one short manual-page bullet to the current changelog entry. Preserve all existing uncommitted changelog text.
- Do not add a Lintian override for `no-manual-page`.
- Preserve the existing Debian package structure and both supported architectures.
- Do not add a domain glossary entry. This feature introduces no new domain concept.
- Do not add an ADR. The change is conventional, easy to reverse, and does not select a surprising architecture.

## Testing Decisions

- Test the built Debian package as the principal and highest seam. Tests must check external package contents and installed documentation, not private build-rule details.
- Extend the existing release-package verification instead of creating a new low-level test framework.
- Confirm that the package contains the standard installed path for `journql.1.gz`.
- Confirm that the installed gzip stream is valid and can be decompressed.
- Confirm that the decompressed page contains the public command syntax and its principal sections. Do not lock the complete prose into an exact-text test.
- Run the existing repository test target after the change.
- Run the package lint target because the manual page changes package contents.
- Confirm that Lintian no longer reports `no-manual-page` for the installed command. Do not hide the warning with an override.
- Run final tests and package checks in an Ubuntu Docker container because development occurs on macOS.
- Use existing Journal Entry fixtures if an applicable command test needs journal data in a container without an active systemd journal.
- Use the current release verification and installed-package smoke checks as prior art.
- A good test opens or inspects the built package and checks what a package user receives. It does not depend on the internal order of staging commands.

## Out of Scope

- Generating the manual page from the README, command help, Markdown, or another source format.
- Adding Pandoc, help2man, or another documentation generator.
- Adding a DuckDB manual page.
- Changing the `journql` command interface or runtime behavior.
- Adding new Journal Selection controls, Journal Query features, Query Result formats, or relation columns.
- Documenting planned or unimplemented features.
- Changing the existing domain glossary or ADRs.
- Adding a Lintian override for the missing manual page.
- Installing repository documentation as a requirement for using the manual page.
- Adding support for an operating system or package architecture that the project does not currently support.

## Further Notes

- The current command help and README already contain the information required for the manual page. The implementation must reconcile any accidental difference against actual command behavior.
- The worktree already contains user changes in the Debian changelog. Preserve them and add only the agreed bullet.
- The manual source must use roff escaping that does not turn command options into typographic hyphens or interpret SQL punctuation as formatting instructions.
- Keep the implementation commit limited to this manual-page purpose.
- There are no open design questions.
