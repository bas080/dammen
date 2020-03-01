#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

! grep -rinE '(wip|todo|tbd|tdo|fixme)' ./src/ ./t/ | diagnostics
test_success 'No work in progress declarations.'


