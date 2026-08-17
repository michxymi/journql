#!/usr/bin/env bats

@test "journql runs" {
  run ./debian/usr/bin/journql
  [[ "$status" -eq 0 ]]
}
