#!/usr/bin/env bash
# shellcheck disable=SC2155

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && $*; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'$* 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' $* 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' $* 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' $* 1>&2 ; return 0; }

function errorExit()                { EXITCODE=$1 ; shift; error "$*" ; exit "$EXITCODE"; }
function exitIfBinariesNotFound()   { for file in "$@"; do [ $(command -v "${file}") ] || errorExit 253 binary not found: "$file"; done }

function tlsCert2() {
   local a=$(mktemp /tmp/tlsCert.XXXXXXXX)
   trap "rm -f ${a}" EXIT
   cat >> "$a" <<EOF
#!/usr/bin/env ruby
VERSION="v2.1.24"
args    = ARGV.join(" ")
count   = -1
outarr  = Array.new()
# read lines beginning with BEGIN CERTIFICATE and the following into an outarr
IO.foreach(args) do | name |
    if name.include? "----BEGIN CERTIFICATE"
        count += 1
    end
    outarr[count] = outarr[count].to_s + name if count >= 0
end
print "############################################################\n"
print "Certificate: ", args, "\n"
print "Number of certificates (#{VERSION}): ", count+1, "\n"
print "============================================================\n"
(count+1).times do |val|
    IO.popen("openssl x509 -subject -email -issuer -dates -sha256 -serial -noout -ext 'subjectAltName,authorityKeyIdentifier,subjectKeyIdentifier' 2>/dev/null", "w+") do |proc|
         proc.write(outarr[val])
         proc.close_write
         puts "--------------------------------------------------------------" if val > 0

         proc.readlines.each { |x|
            if x.length > 1
               print (x.to_s.gsub("\n", ""))
               print ("\n") if not [ "Identifier", "Alternative Name" ].any?{ |s| x.include? s }
            end
         }
    end
end
EOF
   ruby "$a" "$@"
}

function tlsCert2LeafCn2() {
   for file in "$@" ; do
	   [ ! -f "$file" ] && error Supplied argument "$file" is not a file && exit 1
	   tlsCert2 "$file" | grep 'subject=' | head -n 1 | sed -e 's/^.*CN = //' -e 's/,.*//'
   done
}

function tlsCert2LeafSubject2() {
   for file in "$@" ; do
	   [ ! -f "$file" ] && error Supplied argument "$file" is not a file && return
	   tlsCert2 "$file" | grep 'subject=' | head -n 1 | sed -e 's/^.*subject=//'
   done
}

function tlsCert2LeafIssuer2() {
   for file in "$@" ; do
      [ ! -f "$file" ] && error Supplied argument "$file" is not a file && return
      tlsCert2 "$file" | grep 'issuer=' | head -n 1 | sed -e 's/^.*issuer=//'
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
   declare -l output="/dev/null"

   [ "$1" = -v ] &&  output="/dev/stdout" && shift

   declare -l  file
   if [ $# -eq 0 ] ; then
      tlsCertFingerprint3
   else
      for file in "$@"; do
         /bin/echo -n "$file:" > $output
         unset found
         [[ "$file" =~ .*\.crt$  ]] && found=TRUE && tlsCertFingerprint3 "$file"
         [[ "$file" =~ .*\.pem$  ]] && found=TRUE && tlsCertFingerprint3 "$file"
         [[ "$file" =~ .*\.pub$  ]] && found=TRUE && tls-rsa-pub-fingerprint.sh -v "$file"
         [[ "$file" =~ .*\.prv$  ]] && found=TRUE && tls-rsa-prv-fingerprint.sh -v "$file"
         [[ "$file" =~ .*\.key$  ]] && found=TRUE && tls-rsa-prv-fingerprint.sh -v "$file"
         [[ "$file" =~ .*\.csr$  ]] && found=TRUE && tlsCsr -v -f "$file"
         [[ "$file" =~ .*\.p7b$  ]] && found=TRUE && tls-p7b-to-pem.sh "$file" | tlsCertFingerprint3
         [ -z "$found" ] && err ERROR file "$file" not supported && exit 20
      done
   fi
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
    if ! [[ -z $expire_date ]]; then # -> found date-process it:
        debug4 expiry_date of cert is $expire_date
        expire_epoch=$($_gdate +%s -d "$expire_date")
        debug4 expiry_date in epoch is "$expire_epoch"
        timeleft=`expr "$expire_epoch" - "$today_epoch"`
        debug4 seconds left before expiry is "$timeleft"

        if [[ "$today_epoch" -ge "$expire_epoch" ]]; then #EXPIRE
            echo "Certificate is expired."
            return 2
        fi

        if [[ "$timeleft" -le "$epoch_warning" ]]; then #WARN
            echo "Certificate expiring in" "$(( timeleft / 86400 ))" days
            return 1
        fi

        debug4 All ok
        echo "Certificate not expiring in ${days_expiring} days ($(( timeleft / 86400 )) days)"
        # not expiring in $epoch_warning days
        return 0
    else
        echo Could not determine expiry date of the file/certificate.
        return 99
    fi
}

function tlsServerCert2() {
   # tlsServerCert expects a hostname as its first argument. The argument can contain http:// or https:// which will
   # be removed from the call.
    [ -z $1 ] && 1>&2 echo no argument specified && return 1
    url=$1
    # strip potential leading ^http.?://
    [[ $url =~ ^http.?:// ]] && url=$(echo $url | sed 's,^.*://,,')
    debug url: $url
    gnutls-cli --print-cert --no-ca-verification $url  < /dev/null
}

function err() { 1>&2 echo "$@"; }

function usage() {
   err Show certificate information. The default it to output the complete chain if existing.
   err
   err "$(basename "$0")" '-h'
   err "$(basename "$0")" '-V'
   err "$(basename "$0")" '[<<file>>]'
   err "$(basename "$0")" '[-D] -c [<<file>>]'
   err "$(basename "$0")" '[-D] -s [<<file>>]'
   err "$(basename "$0")" '[-D] -i [<<file>>]'
   err "$(basename "$0")" '[-D] -f [<<file>>...]'
   err "$(basename "$0")" '[-D] -x [<<file>>...]'
   err "$(basename "$0")" '[-D] -e <<expirationInDays>> [<<file>>]'
   err "$(basename "$0")" '[-D] -r [<<[https://]remoteServer>>]'
   err
   err '-h ::= help'
   err '-V ::= show version'
   err '-D ::= enable debug'
   err '-c ::= just show leaf CN field'
   err '-i ::= just show issuer of leaf certificate'
   err '-s ::= just show leaf subject field'
   err '-f ::= show the fingerprint for certificates, private, and public keys, and CSRs'
   err '-e ::= show if the certificate expired in the specified amount of days'
   err '       Exit codes'
   err '             0 certificate not expiring in the next specified days'
   err '             1 certificate is expiring in the specified timeframe'
   err '             2 certificate is already expired'
   err '            99 error, the certificate could not be read'
   err '           100 expiryInDays is not a number'
   err '           101 specified file is not a plain file'
}

# fixArg provides handling for receiving input from stdin aka as pipe-mode. If no argument is specified, pipe-mode is assumed.
# fixArg will copy stdin into a temporary file and offer the filename back to to caller
# fixArg exits with 99 in case of pipe-mode. As this function is run in a sub-shell, the removal of the temporary file must be
# done from the parent process. Otherwise the file is deleted when finishing the client process with fixArg and the parent
# could not access the file anymore.
function fixArg() {
   if [ -n "$1" ] ; then
      echo "$@"
   else
      local b=$(mktemp /tmp/tlsCert.XXXXXXXX)
      cat > "$b"
      echo "$b"
      exit 99
   fi
}

function main() {
   exitIfBinariesNotFound ruby
   unset VERBOSE
   if [ "$1" = -h ] ; then
      usage
      exit 10
   elif [ "$1" = -V ] ; then
      echo 1.3.0
      exit 11
   elif [ "$1" = -D ] ; then
      debugSet
      shift
   elif [ "$1" = -c ] ; then
      shift
      arg=$(fixArg "$@")
      [ $? -eq 99 ] && trap "/bin/rm -f ${arg}" EXIT
      tlsCert2LeafCn2 $arg
   elif [ "$1" = -s ] ; then
      shift
      arg=$(fixArg "$@")
      [ $? -eq 99 ] && trap "/bin/rm -f ${arg}" EXIT
      tlsCert2LeafSubject2 $arg
   elif [ "$1" = -i ] ; then
      shift
      arg=$(fixArg "$@")
      [ $? -eq 99 ] && trap "/bin/rm -f ${arg}" EXIT
      tlsCert2LeafIssuer2 "$arg"
   elif [ "$1" = -f ] ; then
      shift
      fingerprint2 "$@"
   elif [ "$1" = -x ] ; then
      shift
      arg=$(fixArg "$@")
      [ $? -eq 99 ] && trap "/bin/rm -f ${arg}" EXIT
      for file in $arg ; do
         tlsCert "$file" | grep -E 'notBefore=|notAfter='
      done
   elif [ "$1" = -e ] ; then
      shift
      expiry="$1"
      shift
      arg=$(fixArg "$@")
      # echo expiry $expiry arg $arg
      [ $? -eq 99 ] && trap "/bin/rm -f ${arg}" EXIT
      tlsCheckCertExpiry2 "$expiry" $arg
   elif [ "$1" = -r ] ; then
      exitIfBinariesNotFound gnutls-cli
      shift
      arg=$(fixArg "$@")
      res=$?
      if [ $res -eq 99 ] ; then
         trap "/bin/rm -f ${arg}" EXIT
         for host in $(grep -v '^$' "$arg") ; do
            tlsServerCert2 "$host"
         done
      else
         tlsServerCert2 $arg
      fi
   else
      arg=$(fixArg "$@")
      [ $? -eq 99 ] && trap "/bin/rm -f ${arg}" EXIT
      for file in "$arg" ; do
         mainFound=
         [[ "$file" =~ .*\.csr$  ]] && mainFound=TRUE && tlsCsr "$file"
         [[ -z "$mainFound" ]] && tlsCert2 $arg
      done
   fi
   # done
}

main "$@"

# EOF