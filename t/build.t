#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

compile | diagnostics; test_success "Compiled with success"
