#!/usr/bin/env bash
# verified with shellcheck
# © 2025 Christian ENGEL engel-ch@outlook.com
# LICENSE: MIT
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
# and associated documentation files (the “Software”), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# -----------------------------------------------
# CHANGELOG
# 1.4
# - individual rules for established connection are only created if allow_all_established connections 
#   is not set
# 1.3
# - more limited exposure of DNS and NTP as problems with iptable-kernel tables seems to be fixed
# - shellcheck_ok: true
# 1.2.0
# - shellcheck: ok
# - configuration settings can be overwritten by environment variables, all starting with IPT_
# - default settings: allow incoming TCP 22, outgoing TCP all; limit UDP to outgoing DNS, NTP
# 1.1.0
# - version number integrated + both options tested manually (incl exit-code)
# - added the ALL option for TCP INCOMING/OUTGOING calls
# - tested on Debian 12 machine: ok
# 1.0.0
# - change to sequence of port numbers
# - ok tested on local machine Debian 12 
# - ok tested on remote cloud machine Ubu22.04
# - ok tested for OS default rules
# - rules persisted with `sudo netfilter-persistent save` which was installed as `sudo apt install iptables-persistent
# 0.8.0
# - shellcheck: ok. Required some changes echo shell output
# 0.7.0
# - testing basic rule settings: ok
# - adding verbose functionality, tested: OK
# - ok tested working for systemd-timesyncd by modified /var/lib/systemd/timesync/clock and /run/systemd/timesync/synchronized after last reboot
#   - both are individual, regular files with different iNumbers
# - ok tested DNS by running `uall`
# -----------------------------------------------
# TODO
# - testing if port numbers are numbers in an allowed range
# - UDP incoming: can it conflict with UDP outgoing rules?
# - allow INCOMING/OUTGOING calls to specific IP ranges only
# - implement ALL option for UDP INCOMING/OUTGOING
# - add environment-variable support to override the configuration variables

readonly _flush_existing_rules="${IPT_FLUSH_EXISTING_RULES:-TRUE}"                      # normally TRUE, also resetting counters,...
readonly _default_policy="${IPT_DEFAULT_POLICY:-DROP}"                                  # usually DROP can be allow
readonly _allow_loopback="${IPT_ALLOW_LOOPBACK:-TRUE}"                                  # normally TRUE
readonly _allow_established_connections="${IPT_ALLOW_ESTABLISHED_CONNECTIONS:-TRUE}"    # depends
readonly _udp_incoming="${IPT_UDP_INCOMING:-}"                                          # usually empty
readonly _udp_outgoing="${IPT_UDP_OUTGOING:-53 123}"                                    # at least DNS, NTP
readonly _tcp_incoming="${IPT_TCP_INCOMING:-22}"                                        # ALL, or usually at least 22. ALL might be required for some debugging
readonly _tcp_outgoing="${IPT_TCP_OUTGOING:-22 80 443}"                                       # or ALL. Some ports might be required for OS upgrades,...

# OS default := all open, no rules is
# _flush_existing_rules="TRUE"           # normally TRUE, also resetting counters,...
# _default_policy="ACCEPT"               # usually DROP can be allow
# _allow_loopback=""                     # normally TRUE
# _allow_established_connections=""      # depends
# _udp_incoming=""                       # usually empty
# _udp_outgoing=""                       # at least DNS, NTP
# _tcp_incoming=""                       # ALL, or usually at least 22. ALL might be required for some debugging
# _tcp_outgoing=""                       # or ALL. Some ports might be required for OS upgrades,...

###########################################################
# helper
VERBOSE_FLAG=''
function verbose() 
{ 
    [ -n "$VERBOSE_FLAG" ] && echo "$*"
    return 0
}

[ "$1" = "-v" ]         && shift && VERBOSE_FLAG=TRUE
[ "$1" = "--verbose" ]  && shift && VERBOSE_FLAG=TRUE

readonly VERSION="1.4.0"
[ "$1" = "-V" ] && 1>&2 echo "$VERSION" && exit 1
[ "$1" = "--version" ] && 1>&2 echo "$VERSION" && exit 1

###########################################################
# FLUSH all existing rules
if [ "$_flush_existing_rules" = TRUE ] ; then 
    verbose flushing existing rules
    sudo iptables -F
    # Delete all Iptables Chains
    sudo iptables -X
    # Flush all counters too
    sudo iptables -Z 
    # Flush and delete all nat and  mangle
    sudo iptables -t nat -F
    sudo iptables -t nat -X
    sudo iptables -t mangle -F
    sudo iptables -t mangle -X
    sudo iptables -t raw -F
    sudo iptables -t raw -X
fi

###########################################################
# must be BEFORE default policy and AFTER flushing
if [ "$_allow_established_connections" = TRUE ] ; then
    verbose allow established connections to be continued
    sudo iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT     # Allowing Established and Related Incoming Connections
    sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED         -j ACCEPT     # Allowing Established Outgoing Connections
else
    verbose NOT allowing to continue established connections
fi

###########################################################
# set default policy
if [ -n  "$_default_policy" ] ; then
    verbose setting default policy to "$_default_policy"
    sudo iptables -P INPUT    "${_default_policy}"
    sudo iptables -P FORWARD  "${_default_policy}"
    sudo iptables -P OUTPUT   "${_default_policy}"
else
    verbose NOT setting default policy
fi

###########################################################
if [ "$_allow_loopback" = TRUE ] ; then
    verbose allowing loopback communication
    sudo iptables -A INPUT  -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
else
    verbose NOT allowing loopback communications    
fi

###########################################################
verbose drop invalid packets
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

###########################################################
for port in $_udp_incoming ; do 
    # currently, only allowing requests from unprivileged ports
    verbose allow UDP incoming on "p$port"
    sudo iptables -A INPUT   -p udp --sport 1024:65535 --dport "$port"    -m state --state NEW,ESTABLISHED   -j ACCEPT
    sudo iptables -A INPUT   -p udp --sport "$port"    --dport "$port"    -m state --state NEW,ESTABLISHED   -j ACCEPT
    if [ "$_allow_established_connections" != TRUE ] ; then
       sudo iptables -A OUTPUT  -p udp --sport "$port"    --dport 1024:65535 -m state --state ESTABLISHED       -j ACCEPT
       sudo iptables -A OUTPUT  -p udp --sport "$port"    --dport "$port"    -m state --state ESTABLISHED       -j ACCEPT
    fi
done
[ -z "$_udp_incoming" ] && verbose NO UDP incoming

###########################################################
for port in $_udp_outgoing ; do 
    verbose allow UDP outgoing on "p$port"
    sudo iptables -A OUTPUT -p udp --sport 1024:65535 --dport "$port" -m state --state NEW,ESTABLISHED -j ACCEPT
    sudo iptables -A OUTPUT -p udp --sport "$port"    --dport "$port" -m state --state NEW,ESTABLISHED -j ACCEPT
    if [ "$_allow_established_connections" != TRUE ] ; then
      sudo iptables -A INPUT  -p udp --sport 1024:65535 --dport "$port" -m state --state ESTABLISHED -j ACCEPT
      sudo iptables -A INPUT  -p udp --sport "$port"    --dport "$port" -m state --state ESTABLISHED -j ACCEPT
    fi
done    
[ -z "$_udp_outgoing" ] && verbose NO UDP outgoing

###########################################################
if [ "$_tcp_incoming" = ALL ] ; then
    verbose Allow all TCP outgoing 
    sudo iptables -A INPUT  -p tcp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    if [ "$_allow_established_connections" != TRUE ] ; then
      sudo iptables -A OUTPUT -p tcp -m conntrack --ctstate ESTABLISHED -j ACCEPT
    fi
else 
    for port in $_tcp_incoming ; do
        verbose allow TCP incoming on "p$port"
        sudo iptables -A INPUT  -p tcp --dport "$port" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        if [ "$_allow_established_connections" != TRUE ] ; then
         sudo iptables -A OUTPUT -p tcp --sport "$port" -m conntrack --ctstate ESTABLISHED -j ACCEPT
        fi
    done
    [ -z "$_tcp_incoming" ] && verbose NO TCP incoming
fi

###########################################################
if [ "$_tcp_outgoing" = ALL ] ; then
    verbose Allow all TCP outgoing 
    sudo iptables -A OUTPUT -p tcp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    if [ "$_allow_established_connections" != TRUE ] ; then
      sudo iptables -A INPUT -p tcp  -m conntrack --ctstate ESTABLISHED -j ACCEPT
    fi
else
    for port in $_tcp_outgoing ; do 
        verbose allow TCP outgoing on "p$port"
        sudo iptables -A OUTPUT -p tcp --dport "$port" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        if [ "$_allow_established_connections" != TRUE ] ; then
           sudo iptables -A INPUT  -p tcp --sport "$port" -m conntrack --ctstate ESTABLISHED -j ACCEPT
        fi
    done    
    [ -z "$_tcp_outgoing" ] && verbose NO TCP outgoing
fi

# EOF
