#!/usr/bin/env bats

bats_require_minimum_version 1.5.0
load test_helper/bats-support/load
load test_helper/bats-assert/load

setup() {
  command_path="$BATS_TEST_DIRNAME/../debian/usr/bin/journql"
  dependency_dir="$BATS_TEST_TMPDIR/dependencies"
  dependency_marker="$BATS_TEST_TMPDIR/dependency-started"
  mkdir -p "$dependency_dir"

  for dependency in journalctl duckdb; do
    dependency_path="$dependency_dir/$dependency"
    printf '%s\n' \
      '#!/bin/sh' \
      "printf '%s\\n' '$dependency' >> '$dependency_marker'" \
      'exit 97' >"$dependency_path"
    chmod 755 "$dependency_path"
  done

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
}

@test "a valid Journal Selection stays between the separators" {
  run --separate-stderr "$command_path" -- --unit sshd.service -- 'SELECT 1'

  assert_success || return 1
  assert_stderr ''
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
