# ---- Crypto -----------------------------------------------------------------------

# ---- SSH  -----------------------------------------------------------------------

# ssf finds a host entry in ssh configuration files in ~/.ssh/config.d/*.config. Earlier versions used ~/.ssh/config.d/* but
# this makes it complex to disable files and keep them for a while.
export SSF_SURROUNDING_LINES='--colour -A 3' # variable to be adjusted in .profile.post
function ssf() { egrep -rv '^[[:space:]]*#' $(find ~/.ssh/ -name Config.d -type d -print  | tr '\n' ' ') | egrep -v ProxyJump | eval egrep -i $SSF_SURROUNDING_LINES --colour=auto "$*" ; }

function start_ssh_agent() {
   # start the ssh-agent and store the variable for ssh-add in a file for next shells
   eval $(ssh-agent)
   env | grep SSH_AUTH_SOCK >| $1
   chmod 600 $1
   ssh-add
}

function sshagent_init {
   #  ssh agent sockets can be attached to a ssh daemon process or an ssh-agent process.
   debug8 common.crypto.sh sshagent_init

   [ -n "${SSH_AUTH_SOCK}" ] && [ -n "${SSH_TTY}" ] && return

   local -r ssh_auth_sock_file=$HOME/.ssh_auth_sock
   if [ -r $ssh_auth_sock_file ] ; then
      source $ssh_auth_sock_file # SSH_AUTH_SOCK to be read by this file
      export SSH_AUTH_SOCK
      ssh-add -l 2>/dev/null 1>&2 ; res=$?
      case $res in
      0) # ssh-agent loaded, keys loaded
         debug8 ... ssh-agent and keys found
         return 0
         ;;
      1) # ssh-agent loaded, but no identities loaded
         debug8 ... ssh-agent found but no keys
         ssh-add
         ;;
      2) # ssh-agent could not be contacted, starting
         debug8 ... ssh-agent not found
         start_ssh_agent $ssh_auth_sock_file
         ;;
      *) error unhandled error in sshagent_init
         debug8 ... error in sshagent_init, unknown return value
         ;;
      esac
   else
      start_ssh_agent $ssh_auth_sock_file
   fi
}

function sshSetup() {
   debug8 zcommonsh.crypto.sh sshSetup
    [ ! -x "$(which ssh-add)" ] && 1>&2 echo "ssh-add is not available; agent testing aborted" && return 1
   sshagent_init
}

function TRAPEXIT() {
   debug8 THIS IS TRAPEXIT
   [ $(id -u) -eq 0 ] && test -n "$SSH_AGENT_PID" && eval `/usr/bin/ssh-agent -k`  # kill agent if leaving root
}

# ---- TLS  -----------------------------------------------------------------------

# ------ Certs
# create fingerprint of certificate
function tlsCertFingerprint() {  local output="/dev/null" ; [ "$1" = -v ] &&  output="/dev/stdout" && shift ; local file; for file in $*; do /bin/echo -n "$file:" > $output; openssl x509 -modulus -noout -in "$file" | openssl sha256 | sed 's/.*stdin)= //' ; done;  }

# split -p not existing under Linux .... > switch to simple ruby as existing on most plaforms
# show certificate (replacing the package version tlsCertView) - removed awk against split
# function tlsCert() {
#    setopt +o nomatch ;
#    local file
#    local infile
#    local tmpCertDir=$(mktemp -d tmpx.XXXXXX); trap "rm -fr $tmpCertDir" INT TERM EXIT;

#    for file in $* ; do
#       split -p "-----BEGIN CERTIFICATE" $file $tmpCertDir/$file.
#       for infile in $tmpCertDir/$file*; do
#          openssl x509 -in "$infile" -subject -email -issuer -dates -sha256 -serial -noout -ext 'subjectAltName' 2>/dev/null | sed -e "s,^,$(basename $infile .in):,"; openssl x509 -in "$infile" -modulus -noout 2>/dev/null | openssl sha256 |  sed -e "s,^.*= ,$(basename $infile .in):SHA256 Fingerprint=,";
#       done;
#    done
#    setopt -o nomatch;
# }

function tlsCert() {
   local a=$(mktemp /tmp/tlsCert.XXXXXXXX)
   trap "rm -f $a" EXIT
   cat >> $a <<EOF
#!/usr/bin/env ruby
VERSION="v2.1.23"
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
print "Number of certificates (#{VERSION}): ", count+1, "\n"
print "================================\n"
(count+1).times do |val|
    IO.popen("openssl x509 -subject -email -issuer -dates -sha256 -serial -noout -ext 'subjectAltName,authorityKeyIdentifier,subjectKeyIdentifier' 2>/dev/null", "w+") do |proc|
         proc.write(outarr[val])
         proc.close_write
         puts "--------------------------------" if val > 0

         proc.readlines.each { |x|
            if x.length > 1
               print (x.to_s.gsub("\n", ""))
               print ("\n") if not [ "Identifier", "Alternative Name" ].any?{ |s| x.include? s }
            end
         }
    end
end
print "================================\n"
EOF
   ruby $a $*
   unset a
}

function tlsCert2LeafCn() {
	[ ! -f "$1" ] && error Supplied argument $1 is not a file && return
	tlsCert $1 | grep 'subject=' | head -n 1 | sed -e 's/^.*CN = //' -e 's/,.*//'
}

function tlsCert2LeafSubject() {
	[ ! -f "$1" ] && error Supplied argument $1 is not a file && return
	tlsCert $1 | grep 'subject=' | head -n 1 | sed -e 's/^.*subject=//'
}

alias  tlsSrvCrt=tlsServerCert
alias  tlsSrvCert=tlsServerCert
function tlsServerCert() {
   # tlsServerCert expects a hostname as its first argument. The argument can contain http:// or https:// which will
   # be removed from the call.
    [ -z $1 ] && 1>&2 echo no argument specified && return 1
    url=$1
    # strip potential leading ^http.?://
    [[ $url =~ ^http.?:// ]] && url=$(echo $url | sed 's,^.*://,,')
    debug url: $url
    gnutls-cli --print-cert --no-ca-verification $url  < /dev/null
}

# ------ Keys
# show fingerprint of private RSA key
#function tlsRsaPrvFingerprint() { local output="/dev/null" ; [ "$1" = -v ] &&  output="/dev/stdout" && shift ; local file; for file in $*; do /bin/echo -n "$file:" > $output; openssl rsa -modulus -noout -in "$file" | openssl sha256 | sed 's/.*stdin)= //'; done; }
function tlsRsaPrvFingerprint() {
    openssl  rsa  -noout -modulus -text -in $1 | \
        egrep '(Modulus=|Exponent:)' | \
        sed -E 's/Exponent: [0-9]+ \(//' | \
        sed 's/)//' | \
        sed 's/Modulus=//' | \
        sed 's/0x//' | \
        tr  '\n' ',' | \
        sed -E 's/.$//' | \
        sed 's/^public//' | \
        sed 's/,privateExponent://' | \
        sha256sum | \
        awk '{ print $1 }'
}

# show fingerprint of public RSA key
#function tlsRsaPubFingerprint() { local output="/dev/null" ; [ "$1" = -v ] &&  output="/dev/stdout" && shift ; local file; for file in $*; do /bin/echo -n "$file:" > $output; openssl rsa -modulus -noout -pubin -in "$file" | openssl sha256 | sed 's/.*stdin)= //'; done; }
function tlsRsaPubFingerprint() {
       openssl rsa -modulus -text -noout -pubin -in $1  | \
        egrep '^(Modulus=|Exponent:)' | sed -E 's/Exponent: [0-9]+ \(//' | \
        sed 's/)//' | sed 's/Modulus=//' | sed 's/0x//' | \
        tr  '\n' ',' | sed -E 's/.$//' | \
        sha256sum | \
        awk '{ print $1 }'
}

function tlsRsaPrv2PubKey() { openssl rsa -in $1 -pubout; }

# ------ CSR
function tlsCsr() { local file; for file in $*; do openssl req -in "$file"  -noout -utf8 -text | sed "s,^,$file:," | egrep -v '.*:.*:.*:'; done; }
function tlsCsrPubKeyFingerprint() {
   local file
   for file in $*; do
      openssl req -in "$file" -noout -pubkey | openssl rsa -modulus -pubin -noout | openssl sha256 | sed 's/.*stdin)= //' | egrep -v '.*:.*:.*:'
   done
}


##########################################

function common.crypto.init() {
   debug4 common.crypto.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   [ ! -z $NO_commonCrypto ] && debug exiting common.crypto.sh && return
   sshSetup # from zsh.common.crypto.sh
}

function common.crypto.del() {
   debug4 common.crypto.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}

# EOF
