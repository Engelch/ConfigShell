#!/usr/bin/env bash
#
# j2
# abouit: jinja2 for the CLI
# installation:
#     pip install j2cli
#     source: https://github.com/kolypto/j2cli
# binary: j2
# Alternative: brew install jinja2-cli

export year="$(date +%y)"
export monthNumber="$(date +%m)"

j2 -e yearShort -e monthNumber Containerfile.j2 > Containerfile
