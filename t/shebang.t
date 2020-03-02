#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

{
  compile
  tmp="$(mktemp)"
  cp <({
    printf '#!%s\n\n' "$BIN"
    cat ./t/pdn/xx00
  }) $tmp
  chmod +x $tmp
  $tmp
} | diagnostics

success "Can execute a PDN file with a shebang pointing to dammen."
