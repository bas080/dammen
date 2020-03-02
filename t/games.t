#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

compile | diagnostics

./dammen ./t/invalid.pdn 2>&1 | diagnostics
test_failure 'Dammen process fails when PDN is invalid.'

printf '%s\n' ./t/pdn/xx* | parallel \
  -v \
  -L 1 \
  --halt now,fail=1 \
  ./dammen | grep pdn | diagnostics;
test_success 'Valid pdn can be validated.'
