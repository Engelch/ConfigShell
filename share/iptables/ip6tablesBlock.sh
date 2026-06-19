#!/usr/bin/env bash

sudo ip6tables -A INPUT  -i lo -j ACCEPT
sudo ip6tables -A OUTPUT -o lo -j ACCEPT

_default_policy=DROP
sudo ip6tables -P INPUT    "${_default_policy}"
sudo ip6tables -P FORWARD  "${_default_policy}"
sudo ip6tables -P OUTPUT   "${_default_policy}"
