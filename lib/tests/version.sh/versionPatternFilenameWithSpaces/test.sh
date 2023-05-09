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

testStdout "test1 version.sh"     "version.sh"      "1.2.3"
testStdout "test2 version.sh -v"  "version.sh -v"   "./bla xx.go:1.2.3"