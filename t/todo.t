#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

! grep -rinE '(todo|tbd|tdo|fixme)' ./src/ ./t/ | while read -t 5 line; do
  diagnostics <<< "$line"
done
test_success 'Did all the tasks'


