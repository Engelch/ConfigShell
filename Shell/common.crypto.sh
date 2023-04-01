# ---- Crypto -----------------------------------------------------------------------

# ---- SSH  -----------------------------------------------------------------------

function start_ssh_agent() {
   # start the ssh-agent and store the variable for ssh-add in a file for next shells
   eval $(ssh-agent)
   env | grep SSH_AUTH_SOCK >| $1
   chmod 600 $1
   ssh-add
}

function sshagent_init {
   #  ssh agent sockets can be attached to a ssh daemon process or an ssh-agent process.
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}"
   [ -n "${SSH_AUTH_SOCK}" ] && [ -n "${SSH_TTY}" ] && return

   local -r ssh_auth_sock_file=$HOME/.ssh_auth_sock
   debug12 ssh_auth_sock_file set to "$ssh_auth_sock_file"
   if [ -r $ssh_auth_sock_file ] ; then
      # 230401 file contained also escape sequences
      # source $ssh_auth_sock_file # SSH_AUTH_SOCK to be read by this file
      export SSH_AUTH_SOCK=$(grep = "$ssh_auth_sock_file" | sed -e 's/^.*=//')
      debug12 Variable from $ssh_auth_sock_file is set to $SSH_AUTH_SOCK
      debug12 checking loaded keys
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
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}"
   [ ! -x "$(which ssh-add)" ] && 1>&2 echo "ssh-add is not available; agent testing aborted" && return 1
   sshagent_init
}

function TRAPEXIT() {
   debug8 THIS IS TRAPEXIT
   [ $(id -u) -eq 0 ] && test -n "$SSH_AGENT_PID" && eval `/usr/bin/ssh-agent -k`  # kill agent if leaving root
}

# ---- TLS  -----------------------------------------------------------------------

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
