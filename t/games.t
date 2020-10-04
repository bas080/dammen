#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

BIN="$(compile)"

printf '%s\n' ./t/pdn/xx* | shuf | head -n 10 | parallel \
  --jobs 20 \
  -v \
  -L 1 \
  --halt now,fail=1 \
  $BIN | grep pdn | diagnostics;
test_success 'Valid pdn can be validated.'
