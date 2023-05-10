#!/usr/bin/env bash
# shellcheck disable=SC2155 disable=SC2046 disable=SC2001

# Changelog
# 2.3.:
#  - move to ConfigShell/lib
# 2.2.:
# - -r mode   accepts now http(s)?://bla.com/jdlssjlkj and filters bla.com

#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################

function tlsCert2LeafCn2() {
   for file in "$@" ; do
	   [ ! -f "$file" ] && error Supplied argument "$file" is not a file && exit 1
	   "$AppLibDir"/tls-cert-file "$file" | grep 'subject=' | head -n 1 | sed -e 's/^.*CN = //' -e 's/,.*//'
   done
}

function tlsCert2LeafSubject2() {
   for file in "$@" ; do
	   [ ! -f "$file" ] && error Supplied argument "$file" is not a file && return
	   "$AppLibDir"/tls-cert-file "$file" | grep 'subject=' | head -n 1 | sed -e 's/^.*subject=//'
   done
}

function tlsCert2LeafIssuer2() {
   for file in "$@" ; do
      [ ! -f "$file" ] && error Supplied argument "$file" is not a file && return
      "$AppLibDir"/tls-cert-file "$file" | grep 'issuer=' | head -n 1 | sed -e 's/^.*issuer=//'
   done
}

# output fingerprint for a cert
function tlsCertFingerprint3() {
   input="$1"
   [ -z "$input" ] && input='-'
   msg=$(openssl x509 -text -modulus -noout -in "$input" 2>/dev/null)
   if [ "${PIPESTATUS[0]}" != "0" ]; then
   echo ERROR
   exit 1
   else
      echo "$msg" | grep -E --color=never '(^Modulus=|Exponent:)' | \
         sed -E 's/^.*Exponent:.*\(//' | \
         sed 's/)//' | sed 's/Modulus=//' | sed 's/0x//' | \
         tr  '\n' ',' | sed -E 's/.$//' | openssl sha256 | sed 's/.*stdin)= //' | sed "s/$/ $input/"
   fi
}

function fingerprint2() {
   debug "${FUNCNAME[0]}"............
   unset found
   debug working on file "$file"
   [[ "$file" =~ .*\.crt$  ]] && found=TRUE && debug calling tlsCertFingerprint3 && tlsCertFingerprint3 "$file"
   [[ "$file" =~ .*\.pem$  ]] && found=TRUE && debug calling tlsCertFingerprint3 && tlsCertFingerprint3 "$file"
   [[ "$file" =~ .*\.pub$  ]] && found=TRUE && debug calling tls-rsa-pub-fingerprint && tls-rsa-pub-fingerprint.sh -v "$file"
   [[ "$file" =~ .*\.prv$  ]] && found=TRUE && debug calling tls-rsa-prv-fingerprint && tls-rsa-prv-fingerprint.sh -v "$file"
   [[ "$file" =~ .*\.key$  ]] && found=TRUE && debug calling tls-rsa-prv-fingerprint && tls-rsa-prv-fingerprint.sh -v "$file"
   [[ "$file" =~ .*\.csr$  ]] && found=TRUE && debug calling tlsCsr && tlsCsr -v -f "$file"
   [[ "$file" =~ .*\.p7b$  ]] && found=TRUE && debug calling tls-p7b-to-pem && tls-p7b-to-pem.sh "$file" | tlsCertFingerprint3
   [ -z "$found" ] && errorExit 20 ERROR file "$file" not supported
}

tlsCheckCertExpiry2() {
    debug in tlsCheckCertExpiry2
    exitIfBinariesNotFound openssl awk
    if ! [[ "$1" =~ ^[0-9]+ ]] ; then
        echo arg to checkCertExpiry is no number
        return 100
    fi
    days_expiring="$1"
    epoch_warning=$(( "$1" * 86400 ))
    debug4 warning duration in days is "$1", in second it is "$epoch_warning"
    shift
    # check file file
    [ ! -f "$1" ] && echo No plain file specified to checkCertExpiry && return 101
    debug4 working on file "$1"
    local _gdate=date
    if [ "$(uname)" = Darwin ] ; then
        exitIfBinariesNotFound gdate
        _gdate=gdate
        debug4 gdate is used as date command
    fi
    # use epoch times for calcs/compares
    today_epoch="$($_gdate +%s)"
    debug4 now in epoch is "$today_epoch"

    expire_date=$(openssl x509 -in "$1" -noout -dates 2>/dev/null | \
                  awk -F= '/^notAfter/ { print $2; exit }')
    if [[ -n $expire_date ]]; then # -> found date-process it:
        debug4 expiry_date of cert is "$expire_date"
        expire_epoch=$($_gdate +%s -d "$expire_date")
        debug4 expiry_date in epoch is "$expire_epoch"
        timeleft=$(("$expire_epoch" - "$today_epoch"))
        debug4 seconds left before expiry is "$timeleft"

        if [[ "$today_epoch" -ge "$expire_epoch" ]]; then #EXPIRE
            echo "certificate is expired."
            return 2
        fi

        if [[ "$timeleft" -le "$epoch_warning" ]]; then #WARN
            echo "certificate expiring in" "$(( timeleft / 86400 ))" days
            return 1
        fi

        debug4 All ok
        echo "certificate not expiring in ${days_expiring} days ($(( timeleft / 86400 )) days)"
        # not expiring in $epoch_warning days
        return 0
    else
        echo could not determine expiry date of the file/certificate.
        return 99
    fi
}

function tlsServerCert2() {
   # tlsServerCert expects a hostname as its first argument. The argument can contain http:// or https:// which will
   # be removed from the call.
    [ -z "$1" ] && 1>&2 echo no argument specified && return 1
    url="$1"
    # strip potential leading ^http.?:// and strip /... after the FQDN or IP-address
    url=$(echo "$url" | sed -E 's,http(s)?://,,' | sed -E 's,/.*,,')
    debug url: "$url"
    gnutls-cli --print-cert --no-ca-verification "$url"  < /dev/null
}

function usage() {
   cat <<HERE
DESCRIPTION
   Show certificate information. The default it to output the complete
   chain if existing.

SYNOPSIS
   $App -h
   $App -V
   $App [<<file>>]
   $App [-D] -c [<<file>>]
   $App [-D] -s [<<file>>]
   $App [-D] -i [<<file>>]
   $App [-D] -f [<<file>>...]
   $App [-D] -x [<<file>>...]
   $App [-D] -e <<expirationInDays>> [<<file>>]
   $App [-D] -r [<<[https://]remoteHost/...>>]

OPTIONS
   -h                    ::= help
   -V                    ::= show version
   -D                    ::= enable debug

   -c                    ::= just show leaf CN field
   -i                    ::= just show issuer of leaf certificate
   -s                    ::= just show leaf subject field
   -f                    ::= show the fingerprint for certificates, private,
                             and public keys, and CSRs
   -r remoteHost         ::= show certificate of remote server, remote server
                             can be an IP-address, URL, or an FQDN
   -x                    ::= show validity/expiry start and stop dates
   -e <<expiry in days>> ::= show if the certificate expired in the specified
                             amount of days

EXIT CODES
             0 certificate not expiring in the next specified days
             1 certificate is expiring in the specified timeframe
             2 certificate is already expired
             3 unknown option
            99 error, the certificate could not be read
           100 expiryInDays is not a number
           101 specified file is not a plain file
HERE
}

function deleteOptionalTempfile() {
   debug in deleteOptionalTempfile
   [ -n "$tempFile" ] && debug deleting temp file && /bin/rm -f "$tempFile"
   #[ -n "$tempFile2" ] && debug deleting temp file2 && /bin/rm -f "$tempFile2"
}
trap deleteOptionalTempfile EXIT

# handlePipeMode provides handling for receiving input from stdin aka as pipe-mode. If no argument is specified, pipe-mode is assumed.
# handlePipeMode will copy stdin into a temporary file and offer the filename back to to caller
# handlePipeMode exits with 99 in case of pipe-mode. As this function is run in a sub-shell, the removal of the temporary file must be
# done from the parent process. Otherwise the file is deleted when finishing the client process with handlePipeMode and the parent
# could not access the file anymore.
# It is not the most pretty form to solve it but all the existing code could be reused by this kind of wrapper.
# CAVEAT: does not work with files containing spaces
function handlePipeMode() {
   # returns its output by the args variable. It cannot be run in a sub-shell. Bloody shell :-)
   if [ -n "$1" ] ; then
      arg="$*"
   else
      declare -g tempFile=$(mktemp /tmp/$(basename "$App" .sh).XXXXXXXX)
      debug tempFile created "$tempFile"
      cat > "$tempFile"
      arg="$tempFile"
   fi
}

# EXIT 1 usage
# EXIT 2 wrong option
# EXIT 3 version
function parseCLIOptions() {
   mode= # mode selected by CLI options
   while getopts "DVce:fhirsx" options; do         # Loop: Get the next option;
      case "${options}" in                    # TIMES=${OPTARG}
         D) debugSet; debug debug enabled
            ;;
         V) # version #
            echo 1>&2 "2.2.0"
            exit 3
            ;;
         c) # show leaf CN field
            [ -n "$mode" ] && errorExit 4 resetting mode not allowed
            mode=c
            ;;
         e) # expiry in n days
            [ -n "$mode" ] && errorExit 4 resetting mode not allowed
            declare -g expiry=${OPTARG}
            mode=e
            ;;
         f) # fingerprint mode
            [ -n "$mode" ] && errorExit 4 resetting mode not allowed
            mode=f
            ;;
         h) usage
            exit 1
            ;;
         i) # show issuer of leaf certificate
            [ -n "$mode" ] && errorExit 4 resetting mode not allowed
            mode=i
            ;;
         r) # remote server cert
            [ -n "$mode" ] && errorExit 4 resetting mode not allowed
            mode=r
            ;;
         s) # show leaf subject field
            [ -n "$mode" ] && errorExit 4 resetting mode not allowed
            mode=s
            ;;
         x) # validity range
            [ -n "$mode" ] && errorExit 4 resetting mode not allowed
            mode=x
            ;;
         *) err Help with "$App" -h
            exit 2
            ;;
      esac
   done
}

function main() {
   exitIfBinariesNotFound ruby
   declare -r App=$(basename "$0")
   declare -r AppDir=$(dirname "$0")
   declare -r AppLibDir=$(dirname "$AppDir")/lib
   unset tempFile
   parseCLIOptions "$@"
   shift $((OPTIND - 1))

   handlePipeMode "$@"

   case "$mode" in
   c)    for file in $arg ; do
            tlsCert2LeafCn2 "$file" | sed -e "s ^ $file: " # as space in filenames is not supported, let's use it for the sed substiturion role
         done
         ;;
   e)    # expiry in n days
         debug expiry is "$expiry"
         res=0
         for file in $arg ; do
            tlsCheckCertExpiry2 "$expiry" "$file" | sed -e "s ^ $file: " # as space in filenames is not supported, let's use it for the sed substiturion role
            tmpRes="${PIPESTATUS[0]}"  # keep the first exit code unequal zero and return it, else return 0
            [ "$tmpRes" -ne 0 ] && [ "$res" -eq 0 ] && res="$tmpRes"
         done
         return "$res"
         ;;
   f)    for file in $arg ; do
            fingerprint2 "$file"
         done
         ;;
   i)    # show issuer of leaf cert
         for file in $arg ; do
            tlsCert2LeafIssuer2 "$file" | sed -e "s ^ $file: " # as space in filenames is not supported, let's use it for the sed substiturion role
         done
         ;;
   r)    # remote server cert
         exitIfBinariesNotFound gnutls-cli
         for file in $arg ; do
            tlsServerCert2 "$file"  | $App #| sed -e "s ^ $file: " # as space in filenames is not supported, let's use it for the sed substiturion role
         done
         ;;
   s)    # show leaf subject
         for file in $arg ; do   # no double-quotes around $arg!
            debug working on file "$file"
            tlsCert2LeafSubject2 "$file" | sed -e "s ^ $file: " # as space in filenames is not supported, let's use it for the sed substiturion role
         done
         ;;
   x)    # show validity of certs
         for file in $arg ; do
            "$AppLibDir"/tls-cert-file "$file" | grep -E 'notBefore=|notAfter=' | sed -e "s ^ $file: " # as space in filenames is not supported, let's use it for the sed substiturion role
         done
         ;;
   *)    # default, show cert info
         debug default mode, show cert
         for file in $arg ; do   # no double-quotes around $arg!
            debug working on file "$file"
            "$AppLibDir"/tls-cert-file "$file"
         done
         ;;
   esac
}

main "$@"

# EOF
