# Journal Analysis

This context describes how a person selects Linux journal entries and analyzes them with SQL.

## Language

**Journal Entry**:
A record from the systemd journal that contains standard fields and can contain application-defined fields.
_Avoid_: Log line, log message, event

**Journal Selection**:
The set of Journal Entries that a person chooses for analysis.
_Avoid_: Filter, journal subset

**Journal Query**:
A SQL program, supplied as one command argument, that analyzes a Journal Selection. It can contain one or more SQL statements.
_Avoid_: Search, command

**Query Result**:
The data that a Journal Query returns.
_Avoid_: Output, report
