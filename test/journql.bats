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
case "$(cat "$JOURNQL_TEST_DUCKDB_INPUT")" in
  'SELECT entry FROM journal;')
    cat "$JOURNQL_TEST_FIXTURE"
    ;;
  'SELECT count(*) FROM journal;')
    if [ -s "$JOURNQL_TEST_FIXTURE" ]; then
      printf '%s\n' 1
    else
      printf '%s\n' 0
    fi
    ;;
  *)
    printf '%s\n' 1
    ;;
esac
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
  grep -F -- 'CREATE TABLE journal (' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'read_json_objects' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  for column in timestamp message hostname systemd_unit user_unit identifier priority pid uid gid boot_id transport cursor entry; do
    grep -F -- "$column" "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  done
  [[ -z "$(find "$BATS_TEST_TMPDIR" -maxdepth 1 -name 'journql.*' -print -quit)" ]]
}

@test "missing Journal Entry fields keep the stable relation and entry JSON" {
  JOURNQL_TEST_FIXTURE="$BATS_TEST_DIRNAME/fixtures/missing-journal-fields.json"

  run --separate-stderr "$command_path" -- -- 'SELECT entry FROM journal;'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_output --partial 'preserved-missing' || return 1
  for column_definition in \
    'timestamp TIMESTAMPTZ' 'message VARCHAR' 'hostname VARCHAR' \
    'systemd_unit VARCHAR' 'user_unit VARCHAR' 'identifier VARCHAR' \
    'priority INTEGER' 'pid BIGINT' 'uid BIGINT' 'gid BIGINT' \
    'boot_id VARCHAR' 'transport VARCHAR' 'cursor VARCHAR' 'entry JSON'; do
    grep -F -- "$column_definition" "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  done
  grep -F -- 'INSERT INTO journal' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'APP_DEFINED' "$JOURNQL_TEST_FIXTURE" >/dev/null || return 1
}

@test "repeated and binary stable source values become NULL-compatible" {
  local fixture
  for fixture in repeated-journal-fields.json binary-journal-fields.json; do
    JOURNQL_TEST_FIXTURE="$BATS_TEST_DIRNAME/fixtures/$fixture"

    run --separate-stderr "$command_path" -- -- 'SELECT count(*) FROM journal;'

    assert_success || return 1
    assert_stderr '' || return 1
    assert_output '1' || return 1
    grep -F -- "json_type(json" "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
    grep -F -- "= 'VARCHAR'" "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  done
}

@test "invalid timestamp and numeric source values do not stop the Journal Query" {
  JOURNQL_TEST_FIXTURE="$BATS_TEST_DIRNAME/fixtures/invalid-journal-fields.json"

  run --separate-stderr "$command_path" -- -- 'SELECT timestamp, priority, pid, uid, gid, entry FROM journal;'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_output '1' || return 1
  grep -F -- 'try_cast' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'try(to_timestamp' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'CASE' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'APP_DEFINED' "$JOURNQL_TEST_FIXTURE" >/dev/null || return 1
}

@test "an empty Journal Selection creates the stable relation" {
  JOURNQL_TEST_FIXTURE="$BATS_TEST_DIRNAME/fixtures/empty-journal.json"

  run --separate-stderr "$command_path" -- -- 'SELECT count(*) FROM journal;'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_output '0' || return 1
  grep -F -- 'CREATE TABLE journal' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
  grep -F -- 'INSERT INTO journal' "$JOURNQL_TEST_DUCKDB_ARGS" >/dev/null || return 1
}

@test "the default and selected formats use the matching DuckDB formatter" {
  run --separate-stderr "$command_path" -- -- 'SELECT 1'
  assert_success || return 1
  assert_equal "$(sed -n '1p' "$JOURNQL_TEST_DUCKDB_ARGS")" '-table' || return 1

  run --separate-stderr "$command_path" --format table -- -- 'SELECT 1'
  assert_success || return 1
  assert_equal "$(sed -n '1p' "$JOURNQL_TEST_DUCKDB_ARGS")" '-table' || return 1

  run --separate-stderr "$command_path" --format=csv -- -- 'SELECT 1'
  assert_success || return 1
  assert_equal "$(sed -n '1p' "$JOURNQL_TEST_DUCKDB_ARGS")" '-csv' || return 1

  run --separate-stderr "$command_path" --format json -- -- 'SELECT 1'
  assert_success || return 1
  assert_equal "$(sed -n '1p' "$JOURNQL_TEST_DUCKDB_ARGS")" '-json' || return 1
}

@test "one Journal Query can contain multiple SQL statements" {
  run --separate-stderr "$command_path" -- -- 'CREATE TABLE result AS SELECT 1 AS value; SELECT value FROM result;'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_DUCKDB_INPUT")" 'CREATE TABLE result AS SELECT 1 AS value; SELECT value FROM result;' || return 1
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

@test "allowed Journal Selection controls pass to journalctl in order" {
  run --separate-stderr "$command_path" -- \
    --system --user -m \
    --since '2026-08-17 00:00:00' --until='2026-08-17 23:59:59' \
    -c cursor-value --after-cursor=after-value -b -1 \
    --unit sshd.service --user-unit session-1.scope \
    -t sshd -p 3 --facility=auth -g failed --case-sensitive=no -k \
    --lines=25 -n 10 -r MESSAGE=failed + _SYSTEMD_UNIT=sshd.service \
    -- 'SELECT 1'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_JOURNALCTL_ARGS")" $'--system\n--user\n-m\n--since\n2026-08-17 00:00:00\n--until=2026-08-17 23:59:59\n-c\ncursor-value\n--after-cursor=after-value\n-b\n-1\n--unit\nsshd.service\n--user-unit\nsession-1.scope\n-t\nsshd\n-p\n3\n--facility=auth\n-g\nfailed\n--case-sensitive=no\n-k\n--lines=25\n-n\n10\n-r\nMESSAGE=failed\n+\n_SYSTEMD_UNIT=sshd.service\n--output=json\n--all\n--no-pager' || return 1
}

@test "native field matches and the disjunction operator are allowed" {
  run --separate-stderr "$command_path" -- \
    'MESSAGE=failed' + '_SYSTEMD_UNIT=sshd.service' -- 'SELECT 1'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_JOURNALCTL_ARGS")" $'MESSAGE=failed\n+\n_SYSTEMD_UNIT=sshd.service\n--output=json\n--all\n--no-pager' || return 1
}

@test "legacy ignore-case selection forms use the supported journalctl control" {
  run --separate-stderr "$command_path" -- -i --case-sensitive=yes -- 'SELECT 1'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_JOURNALCTL_ARGS")" $'--case-sensitive=no\n--case-sensitive=yes\n--output=json\n--all\n--no-pager' || return 1

  run --separate-stderr "$command_path" -- --ignore-case -- 'SELECT 1'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_JOURNALCTL_ARGS")" $'--case-sensitive=no\n--output=json\n--all\n--no-pager' || return 1
}

@test "optional Journal Selection controls accept long and separate-value forms" {
  run --separate-stderr "$command_path" -- \
    --boot --lines 12 --case-sensitive -- 'SELECT 1'

  assert_success || return 1
  assert_stderr '' || return 1
  assert_equal "$(cat "$JOURNQL_TEST_JOURNALCTL_ARGS")" $'--boot\n--lines\n12\n--case-sensitive\n--output=json\n--all\n--no-pager' || return 1
}

@test "unsupported Journal Selection arguments fail before journal access" {
  local rejected_argument
  for rejected_argument in \
    --machine=container --directory=/var/log/journal --file=/var/log/messages \
    --root=/ --image=container --namespace=name \
    --output=short --output-fields=MESSAGE --all --full --no-pager --pager \
    --follow --cursor-file=/tmp/cursor --list-boots --header --fields=MESSAGE \
    --disk-usage --verify --sync --flush --rotate --vacuum-time=1s \
    --vacuum-size=1K --vacuum-files=1 --catalog --update-catalog --new-id128 \
    /var/log/messages; do
    run --separate-stderr "$command_path" -- "$rejected_argument" -- 'SELECT 1'

    assert_equal "$status" 2 || return 1
    assert_stderr --partial 'unsupported Journal Selection argument' || return 1
  done
  [[ ! -e "$dependency_marker" ]]
}

@test "a path match and other positional arguments fail with status 2" {
  for positional_argument in /var/log/messages sshd.service; do
    run --separate-stderr "$command_path" -- "$positional_argument" -- 'SELECT 1'

    assert_equal "$status" 2 || return 1
    assert_stderr --partial 'unsupported Journal Selection argument' || return 1
  done
  [[ ! -e "$dependency_marker" ]]
}

@test "selection options that need values reject missing values" {
  for missing_value_option in --since --until --cursor --after-cursor --unit \
    --user-unit --identifier --priority --facility --grep -S -U -c -u -t -p -g; do
    run --separate-stderr "$command_path" -- "$missing_value_option" -- 'SELECT 1'

    assert_equal "$status" 2 || return 1
    assert_stderr --partial 'needs a value' || return 1
  done
  [[ ! -e "$dependency_marker" ]]
}
