# requires OS_PATHFILE to be set

function setupOSXPaths() {
   debug8 'in setupOSXPaths...........'
   for _POTENTIAL_DIR in \
      /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/opt/gnu-getopt/bin /usr/local/opt/gnu-getopt/bin /opt/homebrew/opt/ \
      /usr/local/homebrew/bin /usr/local/homebrew/sbin \
      /opt/homebrew/opt/openssl\@1.1/bin /usr/local/opt/openssl\@1.1/bin \
      /opt/homebrew/opt/curl/bin  /usr/local/opt/curl/bin/ /usr/local/opt/gnu-getopt/bin \
      /opt/homebrew/opt/java/bin /usr/local/opt/java/bin /Library/Java/JavaVirtualMachines/current/bin \
      /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin \
      /Applications/Visual\ Studio\ Code.app//Contents/Resources/app/bin/ \
      /Applications/Sublime\ Text.app/Contents/MacOS/
   do
        debug8 checking for dir $_POTENTIAL_DIR
        [ -d "$_POTENTIAL_DIR/." ] && debug8 found path element $_POTENTIAL_DIR && echo $_POTENTIAL_DIR >> $OS_PATHFILE
    done
}

##################################

OS_PATHFILE=$HOME/.env.os.Darwin.path

function env.os.Darwin.init() {
   debug4 env.os.Darwin.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   [ -f $OS_PATHFILE ] && debug8 $OS_PATHFILE found, returning && return # caching
   setupOSXPaths
}

function env.os.Darwin.del() {
   debug4 env.os.Darwin.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   [ -f $OS_PATHFILE ] && debug8 $OS_PATHFILE found, deleting it && /bin/rm $OS_PATHFILE # remove cache
}

# EOF
