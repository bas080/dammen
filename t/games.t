#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

compile | diagnostics

find ./t/pdn/xx* | parallel \
  -v \
  -L 1 \
  --halt now,fail=1 \
  ./dammen | grep pdn | diagnostics;
test_success "Valid pdn can be validated"

# TODO: also check if invalid pdn files error.
