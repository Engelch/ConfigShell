#!/usr/bin/env bash
# test.sh V2.0.0
# ok:shellcheck

# testStdout compares with the stdout of the command
function testStdout() {
  output=$(eval "$2")
  if [ "$output" = "$3" ] ; then
    echo "ok:$(pwd | xargs basename):$1"
  else
    echo "ERROR:$(pwd | xargs basename):$1 should return $3 but returned $output"
  fi
}

# testExitCode checks the exit code of the supplied command
function testExitCode() {
  eval "$2" &>/dev/null
  res=$?
  [ "$res" -eq "$3" ] && echo "ok:$(pwd | xargs basename):$1" && return
  echo "ERROR:$(pwd | xargs basename):$1 should return exit code $3 but returned $res"
}

testExitCode "test1 version.sh"     "version.sh"      "12"
testExitCode "test1 version.sh -v"  "version.sh -v"   "12"

# EOF
