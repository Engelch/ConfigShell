# --------------------------------------------------------------------------- Functionality block, alphabetically sorted
# ---- ansible -----------------------------------------------------------------------

function ansibleListTags() {
   for i in $* ; do ansible-playbook --list-tags $i 2>&1 ; done | grep "TASK TAGS" | cut -d":" -f2 | awk '{sub(/\[/, "")sub(/\]/, "")}1' | sed -e 's/,//g' | xargs -n 1 | sort -u
}

# iho searches hosts.yml files. It can be called in 2 modes:
# iho inventoryXYZ         # This will open all hosts*.yml files in less 
# iho inventoryXYZ bla     # This will output all lines in the hosts*.yml files 
#                          # that match bla (case-insensitive)

export IHO_SURROUNDING_LINES=3 # can be adjusted in ~/.profile.post
# search in ansible inventory files for hosts
# If only one argument is supplied, search for the given directory (first argument) on.
# Otherwise, use the 2nd argument as a search pattern in the found hosts*.yml files.
function ansibleInventory() {
    if [ -z $2 ] ; then
        find "$1/." -name hosts\*.yml -print | xargs cat | less 
    else 
        echo "find $1/. -name hosts\*.yml -print | xargs cat | egrep -i -C $IHO_SURROUNDING_LINES $2"
        find "$1/." -name hosts\*.yml -print | xargs cat | egrep -i -C $IHO_SURROUNDING_LINES "$2"
    fi
}

# ---- LaTeX -----------------------------------------------------------------------

function lat() { # better latex call
    local file
    for file in $*
    do
        CURRENT_FILE=$(basename "$file" .tex)
        CURRENT_FILE=$(basename "$CURRENT_FILE" .)
        latex "${CURRENT_FILE}" && latex "${CURRENT_FILE}" && latex "${CURRENT_FILE}" && dvips "${CURRENT_FILE}"    # 3 times to get all references right
    done
}

# ---- Processes -----------------------------------------------------------------------

function killUser() { # kill all processes of a user $*
    local user
    for user in $*
    do
        echo killing user $user... 1>&2
        ps -ef | grep $user | awk '{print $2}' | xargs kill -9
    done
}

# ---- COMMON  -----------------------------------------------------------------------
# ---- COMMON  -----------------------------------------------------------------------
# ---- COMMON  -----------------------------------------------------------------------

function rlFull() {
    debugSet
    debug START rlFull ========================================================
    case "$SHELL" in
    *bash)  rmCache
            _otherFiles=$(ls $HOME/.*.path 2>&-) ; res=$?
            [ "$res" -eq 0 ] && err Missed path files found: echo $_otherFiles
            debug RELOAD STARTING ========================================================
            source ~/.bash_profile
            ;;
    *zsh)   for file in ~/.zshenv ~/.zshrc ; do source $file; done
            ;;
    *)      error rlFull shell not support, SHELL is set to $SHELL
            ;;
    esac
    debug STOP rlFull ========================================================
    debugUnset
}

# rmCache deletes cache files and calls the destructor functions
function rmCache() {
    for file in $PROFILES_CONFIG_DIR/Shell/{common*,bash*,env.path*,env.os.$(uname)*,os.$(uname)*} ; do
        [ -f "$file" ] && $(basename $file .sh).del
    done
    setupPathDel # todo can we remove special handling here
}

# If multiple users log in as user hadm, determine the real user logging in by identifying her/his SSH finger-print
function realUserForHadm() {
   debug realUserForHadm ...........
   if [[ $(id -un) == hadm && $(uname) = Linux && ! $(uname -r) =~ Microsoft && $(id -Gn) =~ wheel ]] ; then
      export HADM_LAST_LOGIN_FINGERPRINT=${HADM_LAST_LOGIN_FINGERPRINT:-$(sudo journalctl -r -u ssh -g 'Accepted publickey' -n 1 -q 2&>/dev/null| awk '{ print $NF }')}

      if [ "$SSH_CLIENT" != "" -a ! -z "$HADM_LAST_LOGIN_FINGERPRINT" ] ; then
         for file in ~/.ssh/*.pub
         do
            if [ $(ssh-keygen -lf $file | grep $HADM_LAST_LOGIN_FINGERPRINT | wc -l) -eq 1 ] ; then
               export HADM_LAST_LOGIN_USER=$(basename $file .pub)
               echo You are $HADM_LAST_LOGIN_USER. Welcome.
               break
            fi
         done
      fi
   fi
}

function common.diverse.init() {
    debug4 common.diverse.init '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
}

function common.diverse.del() {
    debug4 common.diverse.del '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
}

# EOF
