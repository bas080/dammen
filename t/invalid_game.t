#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

dammen ./t/invalid.pdn 2>&1 | diagnostics
test_failure 'Dammen process fails when PDN is invalid.'
