#!/usr/bin/env -S bash --norc --noprofile

openssl rsa -pubin -text -noout -in "$1"
