#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

plan 1

{
  compile
  ./t/wk2007_amrilloewm_vs_domcheva.pdn
} | diagnostics

success "Can execute a PDN file with a shebang pointing to dammen."
