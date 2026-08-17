#!/usr/bin/env bats

bats_require_minimum_version 1.5.0
load test_helper/bats-support/load
load test_helper/bats-assert/load

setup() {
  command_source_path="$BATS_TEST_DIRNAME/../debian/usr/bin/journql"
  fixture_path="$BATS_TEST_DIRNAME/fixtures/basic-journal.json"
  dependency_dir="$BATS_TEST_TMPDIR/dependencies"
  command_path="$BATS_TEST_TMPDIR/usr/bin/journql"
  bundled_dir="$BATS_TEST_TMPDIR/usr/lib/journql"
  dependency_marker="$BATS_TEST_TMPDIR/dependency-started"
  journalctl_args="$BATS_TEST_TMPDIR/journalctl-args"
  duckdb_args="$BATS_TEST_TMPDIR/duckdb-args"
  duckdb_input="$BATS_TEST_TMPDIR/duckdb-input"
  mkdir -p "$dependency_dir" "${command_path%/*}" "$bundled_dir"
  cp "$command_source_path" "$command_path"
  chmod 755 "$command_path"

  cat >"$dependency_dir/journalctl" <<'EOF'
#!/bin/sh
printf '%s\n' journalctl >>"$JOURNQL_TEST_DEPENDENCY_MARKER"
printf '%s\n' "$@" >"$JOURNQL_TEST_JOURNALCTL_ARGS"
cat "$JOURNQL_TEST_FIXTURE"
EOF
  chmod 755 "$dependency_dir/journalctl"

  cat >"$bundled_dir/duckdb" <<'EOF'
#!/bin/sh
printf '%s\n' duckdb >>"$JOURNQL_TEST_DEPENDENCY_MARKER"
printf '%s\n' "$@" >"$JOURNQL_TEST_DUCKDB_ARGS"
cat >"$JOURNQL_TEST_DUCKDB_INPUT"
printf '%s\n' 1
EOF
  chmod 755 "$bundled_dir/duckdb"

  export JOURNQL_TEST_DEPENDENCY_MARKER="$dependency_marker"
  export JOURNQL_TEST_FIXTURE="$fixture_path"
  export JOURNQL_TEST_JOURNALCTL_ARGS="$journalctl_args"
  export JOURNQL_TEST_DUCKDB_ARGS="$duckdb_args"
  export JOURNQL_TEST_DUCKDB_INPUT="$duckdb_input"
  export PATH="$dependency_dir:$PATH"
}

@test "--help describes the command contract without reading the journal" {
  run --separate-stderr "$command_path" --help

  assert_success || return 1
  assert_stderr '' || return 1
  assert_output --partial "Usage: journql [OPTIONS] -- [JOURNAL SELECTION] -- 'JOURNAL QUERY'" || return 1
  assert_output --partial 'The command needs two -- separators.' || return 1
  assert_output --partial '--help' || return 1
  assert_output --partial '--version' || return 1
  assert_output --partial '--format FORMAT' || return 1
  assert_output --partial 'table (default), csv, or json' || return 1
  assert_output --partial '--system, --user, --merge' || return 1
  assert_output --partial '--since, --until, --cursor, --after-cursor, --boot' || return 1
  assert_output --partial '--unit, --user-unit, --identifier, --priority, --facility' || return 1
  assert_output --partial '--grep, --ignore-case, --dmesg' || return 1
  assert_output --partial '--lines and --reverse' || return 1
  assert_output --partial 'FIELD=VALUE' || return 1
  assert_output --partial 'Short forms include -m, -b, -u, -t, -p, -g, -i, -k, -n, and -r.' || return 1
  assert_output --partial 'timestamp TIMESTAMPTZ' || return 1
  assert_output --partial 'entry JSON' || return 1
  assert_output --partial 'normal journalctl selection' || return 1
  assert_output --partial 'current user' || return 1
  assert_output --partial 'private temporary file' || return 1
  assert_output --partial 'Select fewer Journal Entries' || return 1
  assert_output --partial "journql -- -- 'SELECT count(*) FROM journal;'" || return 1
  [[ ! -e "$dependency_marker" ]]
}

@test "--version identifies journql and DuckDB without reading the journal" {
  run --separate-stderr "$command_path" --version

  assert_success || return 1
  assert_stderr '' || return 1
  assert_output --partial 'journql 0.1.0' || return 1
  assert_output --partial 'DuckDB 1.4.5' || return 1
  [[ ! -e "$dependency_marker" ]]
}

@test "a Journal Query with two separators and one argument is valid" {
  run --separate-stderr "$command_path" -- -- 'SELECT 1'

  assert_success || return 1
  assert_stderr ''
  assert_output '1'
}

@test "a valid Journal Selection stays between the separators" {
  run --separate-stderr "$command_path" -- --unit sshd.service -- 'SELECT 1'

  assert_success || return 1
  assert_stderr ''
  assert_equal "$(cat "$JOURNQL_TEST_JOURNALCTL_ARGS")" $'--unit\nsshd.service\n--output=json\n--all\n--no-pager'
}

@test "a basic Journal Query uses the complete fixture and stable relation" {
  export TMPDIR="$BATS_TEST_TMPDIR"

  run --separate-stderr "$command_path" -- -- 'SELECT timestamp, message, entry FROM journal;'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_output '1' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_JOURNALCTL_ARGS")" $'--output=json\n--all\n--no-pager' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_DEPENDENCY_MARKER")" $'journalctl\nduckdb' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_DUCKDB_INPUT")" 'SELECT timestamp, message, entry FROM journal;' || return 1

  grep -F -- '-table' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- ':memory:' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- "SET TimeZone='UTC';" "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'CREATE TABLE journal AS' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'read_json_objects' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  for column in timestamp message hostname systemd_unit user_unit identifier priority pid uid gid boot_id transport cursor entry; do
    grep -F -- "$column" "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  done
  [[ -z "$(find "$BATS_TEST_TMPDIR" -maxdepth 1 -name 'journql.*' -print -quit)" ]]
}

@test "format options accept separate and equals-value forms" {
  run --separate-stderr "$command_path" --format table -- -- 'SELECT 1'
  assert_success || return 1

  run --separate-stderr "$command_path" --format=csv -- -- 'SELECT 1'
  assert_success || return 1

  run --separate-stderr "$command_path" --format json -- -- 'SELECT 1'
  assert_success || return 1
}

@test "a Journal Query needs both separators" {
  run --separate-stderr "$command_path"
  assert_equal "$status" 2 || return 1
  assert_stderr --partial 'two -- separators' || return 1

  run --separate-stderr "$command_path" -- 'SELECT 1'
  assert_equal "$status" 2 || return 1
  assert_stderr --partial 'second -- separator' || return 1
}

@test "a Journal Query needs exactly one argument after the second separator" {
  run --separate-stderr "$command_path" -- --
  assert_equal "$status" 2 || return 1
  assert_stderr --partial 'exactly one Journal Query' || return 1

  run --separate-stderr "$command_path" -- -- 'SELECT 1' 'SELECT 2'
  assert_equal "$status" 2 || return 1
  assert_stderr --partial 'exactly one Journal Query' || return 1
}

@test "unknown journql options fail with status 2" {
  run --separate-stderr "$command_path" --unknown -- -- 'SELECT 1'

  assert_equal "$status" 2 || return 1
  assert_stderr --partial 'unknown option: --unknown'
}

@test "repeated and conflicting journql options fail with status 2" {
  run --separate-stderr "$command_path" --format table --format csv -- -- 'SELECT 1'
  assert_equal "$status" 2 || return 1
  assert_stderr --partial 'option --format can be used only once' || return 1

  run --separate-stderr "$command_path" --help --version
  assert_equal "$status" 2 || return 1
  assert_stderr --partial '--help and --version cannot be used together'
}

@test "invalid format options fail before journal access" {
  run --separate-stderr "$command_path" --format yaml -- -- 'SELECT 1'

  assert_equal "$status" 2 || return 1
  assert_stderr --partial 'invalid format: yaml' || return 1
  [[ ! -e "$dependency_marker" ]]
}
