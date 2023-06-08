#!/usr/bin/env sh
# $ version.sh -v
# bla.go:1.2.3
# $ version.sh
# 1.2.3
#

testStdout() {
  output=$(eval $2)
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

testExitCode "test1 version.sh"     "version.sh"      "10"
testExitCode "test2 version.sh -v"  "version.sh -v"   "10"

