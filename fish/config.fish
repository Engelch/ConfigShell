function err
    echo $argv 1>&2
end

function debug
    test "$DEBUG_Flag" = "TRUE"; and echo 1>&2 "DEBUG: $argv"
end

function debugSet
    set -g DEBUG_Flag TRUE
end

function debugUnset
    set -e DEBUG_Flag
end 

function setupAliases_Abbreviations
    debug in setupAliases_Abbreviations
    set -g -x GREP_OPTIONS "--color=auto"
    abbr -a -g l less
    alias j=jobs
    abbr -a -g ln-s 'ln -s'
    alias a=alias
    alias cp='cp -i'
    alias rm='rm -i'
    alias mv='mv -i'
    abbr -a -g  wh which

    # ls aliases, all others as scripts in /opt/ConfigShell/bin
    set -g -x LS_COLOUR '--color'
    alias ls    "/bin/ls    -hCF       \$LS_COLOUR"
    alias ls-bw "set -g -x LS_COLOUR '--color=none'"

    abbr -a -g cd.. 'cd ..'
    alias ..='cd ..'
    alias .2='cd ../..'
    alias .3='cd ../../..'
    alias .4='cd ../../../..'
    alias .5='cd ../../../../..'
    alias brmd='[ -f .DS_Store ] &&  /bin/rm -f .DS_Store ; set -l a $PWD ; cd .. ; rmdir "$a"; set -e a'
    alias mcd=mkcd
    function mkcd
        mkdir -p $argv[1] && cd $argv[1]
    end
    alias po=popd
    alias pu='pushd .'

    alias disp0='export DISPLAY=:0'
    alias disp1='export DISPLAY=:1'

    abbr -a -g e "grep -E"
    abbr -a -g ei 'grep -Ei'
    abbr -a -g eir 'grep -EiR'
    abbr -a -g er 'grep -ER'

    abbr -a -g enf 'env | grep -Ei'

    abbr -a -g fin 'find . -name'
    abbr -a -g fini 'find . -iname'

    abbr -a -g h "history --show-time"

    abbr --erase hf # delete the old hf #abbr -a -g hf 'history | grep -Ei '
    function hf
        history | grep -Ei $argv[1] | sort -r
    end
    abbr -a -g hs 'history search --reverse --contains' # new command from fish. If it is good, it shall replace/become hf
    abbr -a -g proc 'ps -ef | grep -Ei'

    abbr -a -g rl 'source ~/.config/fish/config.fish'
    abbr -a -g rlDebug 'debugSet ; source ~/.config/fish/config.fish ; debugUnset'
    alias rlFull=rlDebug
    abbr -a -g ssf ssh-grep

    abbr -a -g tm 'tmux new -s'
    abbr -a -g tj 'tmux join-pane -s'

    set -g -x KUBECTL kubectl
    command -q docker ; and set -g -x CONTAINER docker
    command -q podman ; and set -g -x CONTAINER podman
    debug "  set CONTAINER $CONTAINER"

    abbr -a -g k        $KUBECTL
    abbr -a -g k8       $KUBECTL
    abbr -a -g k8s      $KUBECTL
end

function build_path_by_config_files
    debug in build_path_by_config_files
    for pathfile in \
            $PROFILES_CONFIG_DIR/Shell/path.prepend.txt \
            $PROFILES_CONFIG_DIR/Shell/path.(uname).prepend.txt \
            $PROFILES_CONFIG_DIR/Shell/path.(uname).(uname -m).prepend.txt \
            $PROFILES_CONFIG_DIR/Shell/path.append.txt \
            $PROFILES_CONFIG_DIR/Shell/path.(uname).append.txt \
            $PROFILES_CONFIG_DIR/Shell/path.(uname).(uname -m).append.txt
        if test -r "$pathfile"
            debug "  Pathfile $pathfile existing"
            grep -v '^$' "$pathfile" | while read -l line 
                set line (echo "$line" | xargs | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME,")
                if test -d "$line"
                   if string match -r '\.prepend\.txt$' "$pathfile" >/dev/null
                       debug "    Prepending path with $line"
                       fish_add_path -p "$line"
                   else if string match -r '\.append\.txt$' "$pathfile" >/dev/null
                       debug "    Appending path with $line"
                       fish_add_path -a "$line"
                   else
                       echo 1>&2 ERROR path file not matching specifications
                   end
                else
                   debug "    NOT found $line on system"
                end
           end
        else
            debug "  NOT existing Pathfile $pathfile"
        end
    end
end
    
function setupPath
    debug in setupPath
    set -g -x UID (id -u)
    if test "$UID" -eq 0
        debug "  UID is 0, root path setup"
        set fish_user_paths /bin /usr/bin/ /sbin /usr/sbin  # no /usr/local,... for root
    else
        debug "  UID is $UID, non root path setup"
        set fish_user_paths /bin /usr/bin/ /sbin /usr/sbin /usr/local/bin /usr/local/sbin
        build_path_by_config_files
    end
end

function optSourceFile
    debug in optSourceFile $argv
    if ! count $argv >/dev/null         #err no argument supplied to optSourceFile
        return
    end
    if ! test -r $argv[1]               #err supplied plain file is not readable
        return
    end
    debug "  sourcing $argv[1]"
    source $argv[1]
end

 function git_prompt_status
     if [ (git rev-parse --is-inside-work-tree 2>&1 | grep fatal | wc -l) -eq 0  ]
         set -l _gitBranch (git status -s -b | head -1 | sed 's/^##.//')
         set -l _gitStatus (git status -s -b | tail -n +2 | sed 's/^\(..\).*/\1/' | sort | uniq | tr "\n" " " | sed -e 's/ //g' -e 's/??/?/' -e 's/^[ ]*//')
         echo $_gitStatus $_gitBranch
     end
 end

function fish_prompt
    set -l res $status
    if test "$res" -eq 0
        set resString "$(set_color white)$res"
    else
        set resString "$(set_color -o red)$res$(set_color white)"
    end
    echo resString is $resString
    printf '[%s] · %s@%s · %s%s%s · %s%s%s · %s%s%s · %s%s%s\n>' $resString $USER $hostname \
        (set_color green) AWS:$AWS_PROFILE (set_color normal) \
        (set_color magenta) (watson status) (set_color normal) \
        (set_color red) (git_prompt_status) (set_color blue) \
        (set_color yellow) (pwd | sed -E "s,$HOME,~,") (set_color normal) 
end

function setupCompletion
    debug in setupCompletion
    if test -r ~/.ssh/completion.lst
        complete -F -c rsync -a ~/.ssh/completion.lst
        complete -x -c ssh -a ~/.ssh/completion.lst
    end
end

function start_ssh_agent
    debug in start_ssh_agent
    set -l ssh_agent_output (ssh-agent)    # start the ssh-agent and store the variable for ssh-add in a file for next shells
    set -e -g SSH_AUTH_SOCK
    set -x -U SSH_AUTH_SOCK (echo $ssh_agent_output | grep SSH_AUTH_SOCK | sed 's/^.*SSH_AUTH_SOCK=//' | sed 's/;.*//')
    ssh-add
end

function setupSsh
    debug in setupSsh
    [ -n "$SSH_AUTH_SOCK" ] && [ -n "$SSH_TTY" ] && return

    ssh-add -l 2>/dev/null 1>&2 ; set -l res $status
    switch $res
    case 0
        debug "  ssh agent found, keys loaded (status 0)"
        return
    case 1
        debug "  ssh-agent loaded, but no identities loaded (status 1)"
        ssh-add
    case 2
        debug "  ssh-agent could not be contacted, starting (status 2)"
        start_ssh_agent $ssh_auth_sock_file
    case '*'
        debug "  ssh-agent unknown return status ($res)"
        err "setupSsh unknown answer from ssh-add $res"
    end
end

function hadmRealUser
    debug in hadmRealUser
    if test (id -un) = "hadm" ; and test -z "$HADM_LAST_LOGIN_FINGERPRINT" ; and command -q journalctl
        set -g HADM_LAST_LOGIN_FINGERPRINT (sudo journalctl -r -u ssh -g 'Accepted publickey' -n 1 -q 2>&1 | awk '{ print $NF }')
        debug "  HADM_LAST_LOGIN_FINGERPRINT $HADM_LAST_LOGIN_FINGERPRINT"
        debug "  SSH_CLIENT $SSH_CLIENT"
        if ! test -z "$SSH_CLIENT"
            for file in ~/.ssh/*.pub
                if test (ssh-keygen -lf $file | grep -c $HADM_LAST_LOGIN_FINGERPRINT) -eq 1
                    set -x -g HADM_LAST_LOGIN_USER (basename $file .pub)
                    logger "You are user $HADM_LAST_LOGIN_USER logging in as hadm. Welcome."
                    echo You are user "$HADM_LAST_LOGIN_USER" logging in as hadm. Welcome.
                    break
                end # if
            end # for
        end # if
    end # if test (id -un)...        
end

function setupExportVars
    debug in setupExportVars
    umask 0022
    set -g -x LESS '-iR'
    set -g -x RSYNC_FLAGS "-rltHpDvu" # Windows FS updates file-times only every 2nd second
    set -g -x RSYNC_Add_Windows "--modfiy-window=1" # Windows FS updates file-times only every 2nd second
    set -g -x RSYNC_Add_RemoveSLinks "--copy-links"  # convert links into fi    les
    set -g -x VISUAL vim
    set -g -x EDITOR vim       # bsroot has no notion about VISUAL
    set -g -x BLOCKSIZE 1K
    set -g -x PROFILES_CONFIG_DIR /opt/ConfigShell
    set -g -x FISH_RC_VERSION "5.0.0-rc6"
    if test -n "$_current_FISH_RC_VERSION" -a "$FISH_RC_VERSION" != "$_current_FISH_RC_VERSION"
        echo New FISH_RC_VERSION "$FISH_RC_VERSION"
    end
    set -g _current_FISH_RC_VERSION "$FISH_RC_VERSION"
end

if status is-interactive # main code
    debug main - is-interactive case
    optSourceFile ~/.config/fish/pre.fish

    for file in $HOME/.config/fish/conf.d/*.sh $HOME/.bashrc.d/*.sh
        debug "  executing $file"
        command -q bash ; and bash $file
    end
    setupExportVars
    command -v watson &>/dev/null ; or alias watson 'echo >/dev/null' # required for setupPath
    set -g fish_greeting 'Welcome to the ConfigShell fish setup'
    setupPath
    setupAliases_Abbreviations
    setupCompletion
    setupSsh

    optSourceFile ~/.config/fish/post.fish
    hadmRealUser
end

# EOF
