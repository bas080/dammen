#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

swipl \
  -l src/pdn.pl \
  -g 'run_tests.' \
  -t 'halt.' 2>&1 | diagnostics

test_success "Parse and stringified data equals input."
