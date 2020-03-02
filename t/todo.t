#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

! grep -wrinE '(wip|todo|tbd|tdo|fixme)' ./src/ ./t/ | grep -vF -e 'RULE_IGNORE:WIP' | diagnostics # RULE_IGNORE:WIP
test_success 'No work in progress declarations.'
