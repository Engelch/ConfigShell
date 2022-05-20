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
      PS1='[$?] \033[34m\t\033[0m|\033[32m\u@\h\033[0m|\033[34m$(watson status -p)$(watson status -t)\033[0m|\033[0;31m$(gitContents)\033[0m|$AWS_PROFILE|\033[0;33m\w\e[0m\n'
   fi
}

function bash.prompt.init() {
   alias root='sudo -i bash'        # CALCSHELL removed, should not be in .bash{rc,profile}
   bashPrompt
}

function bash.prompt.del() {
   :
}

# EOF

