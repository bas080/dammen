#!/usr/bin/env bash

source <(./t/test-dependencies.sh)

send() {
  sleep 0.1
  curl -m 1 -s "http://127.0.0.1:8080/$1" -X POST --data-binary "$2"&
}

(sleep 1; curl -s "http://127.0.0.1:8080/started")&
curl -s "http://127.0.0.1:8080/started" || {
  printf '1..0 # skip Server is not started.\n'
  exit
}

plan 1

diff <(
  send game_other 'not_answered' # times out
  send game_id 'one'
  send game_some '@./t/pdn/xx00' # times out
  send game_id 'two'
  send game_id 'three'
  send game_id 'four'
  send game_id 'five' # times out
  wait
) <(printf 'twothreefourfive') | diagnostics
test_success 'Previous request receives the next one'
