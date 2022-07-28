debug4 LOADING bash.prompt.sh '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'

function bashPrompt() {
   debug8 bashPrompt ...
   # Save and reload the history after each command finishes. Synchronises different shells
   export PROMPT_COMMAND="history -a; history -c; history -r" # ; $PROMPT_COMMAND"

   if [ $(id -u) -eq 0 ] ; then
      debug8 bash ROOT shell
      PATH=/sbin:/bin:/usr/sbin:/usr/bin:"$PATH" # security: no enhanced PATHs first
      PS1='[$?] \033[0;31m\t | \u@\h | $(pwd) \033[0m##########################\n'
   else
      debug8 bash non-root shell
      unalias watson 2>/dev/null    # echo watson is $(which watson)
      [ $(which watson | wc -l) -eq 0 ] && debug12 watson not found && alias watson='echo -- > /dev/null'
      if [ "$WATSON_PROMPT" = TRUE ] ; then # opt in
         PS1='[$?] \033[34m\t\033[0m|\033[32m\u@\h\033[0m|\033[34m$(watson status)\033[0m|\033[0;31m$(gitContents)\033[0m|$AWS_PROFILE|\033[0;33m\w\e[0m\n'
      else
         PS1='[$?] \033[34m\t\033[0m|\033[32m\u@\h\033[0m|\033[0;31m$(gitContents)\033[0m|$AWS_PROFILE|\033[0;33m\w\e[0m\n'
      fi
   fi
}

function enableBashCaseInsensitiveCompletion() {
   _enableCICompl='set completion-ignore-case'   # must be in ~/.inputrc and set to on
   _inputRcFile="$HOME/.inputrc"
   if [ ! -f $_inputRcFile -o $(grep "$_enableCICompl" "$_inputRcFile" | wc -l) -eq 0 ] ; then
      echo $_enableCICompl on >> $_inputRcFile ; res=$?
      [ $res -ne 0 ] && 2> echo error setting enableBashCaseInsensitiveCompletion && return $res
   fi
   return 0
}

function bash.prompt_version.init() {
   debug4 bash.prompt_version.init '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
   alias root='sudo -i bash'        # CALCSHELL removed, should not be in .bash{rc,profile}
   [ -z $NO_enableBashCaseInsensitiveCompletion ] && enableBashCaseInsensitiveCompletion
   bashPrompt
   #####################################
   export BASH_RC_VERSION="4.18.1"
   #####################################
   debug BASH_RC_VERSION is $BASH_RC_VERSION
   [ ! -z $BASH_MMONRC_VERSION ] && [ $BASH_MMONRC_VERSION != $BASH_RC_VERSION ] && echo new commonrc version $BASH_RC_VERSION. 1>&2
   BASH_MMONRC_VERSION=$BASH_RC_VERSION
}

function bash.prompt_version.del() {
   debug4 bash.prompt_version.del '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
}

# EOF

