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
    set -x GREP_OPTIONS "--color=auto"
    abbr -a l less
    alias f=fuck
    alias j=jobs
    abbr -a ln-s 'ln -s'
    alias a=alias
    alias cp='cp -i'
    alias rm='rm -i'
    alias rm~='rmbak' # not realised as script because the script is deleted by rm~ :-)
    alias mv='mv -i'
    alias o='open'
    abbr -a wh which

    # ls aliases, all others as scripts in /opt/ConfigShell/bin
    set -g -x LS_COLOUR '--color'

    if [ (uname) = "Darwin" ]
        alias ls "gls -hCF --group-directories-first \$LS_COLOUR"
    else
        alias ls "/bin/ls -hCF --group-directories-first \$LS_COLOUR"
    end
    # which eza &> /dev/null ;and begin     # 240812 eza as all cargo binaries not stable enough in rebuilts
    #     alias ls "eza -O"
    #     alias ll "eza -lO"
    # ; end

    alias ls-bw "set -g -x LS_COLOUR '--color=none'"
    functions -e la # delete default definition as fish/3.6.1/share/fish/functions/la.fish

    abbr -a cd.. 'cd ..'
    alias ..='cd ..'
    alias .2='cd ../..'
    alias .3='cd ../../..'
    alias .4='cd ../../../..'
    alias .5='cd ../../../../..'
    alias brmd='[ -f .DS_Store ] ;and  /bin/rm -f .DS_Store ; set -l a $PWD ; cd .. ; rmdir "$a"; set -e a'
    alias mcd=mkcd
    function mkcd
        mkdir -p $argv[1] ; and cd $argv[1]
    end
    alias po=popd
    alias pu=pushd

    alias disp0='export DISPLAY=:0'
    alias disp1='export DISPLAY=:1'

    alias cd=cdx
    function cdx
        set -g TMP_PWD "$PWD"
        if test "$argv" = '-'
            builtin cd "$OLD_PWD" ; and executeDirEnv
        else if test -z "$argv"
            if test -n "$HOME"
                builtin cd "$HOME" ; and executeDirEnv
            else
                echo 'OOPS, cannot execute empty cd without $HOME set' >/dev/stderr
            end
        else
            builtin cd "$argv" ; and executeDirEnv
        end
    end

    # executeDirEnv is a helper function for the improved cd, which is implemented
    # by the function cdx. If the change of a directory was successful, executeDirEnv
    # will be executed.
    # ALGORITHM
    #   As the cd was successful, store the last CWD directory in OLD_PWD.
    #   If a file 00DIR.txt exists, show it to stdout (terminal).
    #   If a file 00DDIR.fish exists, execute it in a sub-shell.
    #   If a file 00DIR.fishrc exists, execute/source it in the current shell.
    function executeDirEnv
        set -g OLD_PWD "$TMP_PWD"
        if test -f 00DIR.txt
            cat 00DIR.txt
        end
        if test -f 00DIR.fish
            fish 00DIR.fish
        end
        if test -f 00DIR.sh
            bash 00DIR.sh
        end
        if test -f 00DIR.fishrc
            source 00DIR.fishrc
        else if test -f 00DIR.rc
            echo "Here is your fish shell, I cannot execute 00DIR.rc"
        end
    end

    abbr -a e "grep -E"
    abbr -a ei 'grep -Ei'
    abbr -a eir 'grep -EiR'
    abbr -a er 'grep -ER'

    abbr -a h "history --show-time"

    abbr --erase hf # delete the old hf #abbr -a -g hf 'history | grep -Ei '
    function hf
        history | grep -Ei --colour $argv[1] | sort
    end
    abbr -a hs 'history search --reverse --contains' # new command from fish. If it is good, it shall replace/become hf

    abbr -a rl 'source /opt/ConfigShell/fish/config.fish'
    alias rlFull=rlDebug

    set -g -x KUBECTL kubectl
    command -q docker ; and set -g -x CONTAINER docker
    command -q podman ; and set -g -x CONTAINER podman
    debug "  set CONTAINER $CONTAINER"

    abbr -a k        $KUBECTL
    abbr -a k8       $KUBECTL
    abbr -a k8s      $KUBECTL
end

function rlDebug
    debugSet
    source /opt/ConfigShell/fish/config.fish
    debugUnset
end

function build_path_by_config_files
    debug in build_path_by_config_files
    for pathfile in \
            $PROFILES_CONFIG_DIR/ShellPaths/path.prepend.txt \
            $PROFILES_CONFIG_DIR/ShellPaths/path.(uname).prepend.txt \
            $PROFILES_CONFIG_DIR/ShellPaths/path.(uname).(uname -m).prepend.txt \
            $PROFILES_CONFIG_DIR/ShellPaths/path.append.txt \
            $PROFILES_CONFIG_DIR/ShellPaths/path.(uname).append.txt \
            $PROFILES_CONFIG_DIR/ShellPaths/path.(uname).(uname -m).append.txt
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
    if test -f "$HOME/.rbenv/version"
        debug rbenv version file found
        set ruby_version (cat "$HOME/.rbenv/version" | head -n 1)
        debug "  ruby_version is $ruby_version"
        if test -d "$HOME/.rbenv/versions/$ruby_version/bin"
            fish_add_path -p "$HOME/.rbenv/versions/$ruby_version/bin"
            debug "  adding path for ruby version $ruby_version"
        else
            echo "  .rbenv/version file found with version $ruby_version, but appropriate directory with installation not found." &> /dev/stderr
        end
    end
end

function setupPath
    debug "in setupPath"
    [ -f /bin/id ] && set -g -x UID (/bin/id -u)
    [ -f /usr/bin/id ] && set -g -x UID (/usr/bin/id -u)
    [ -f /bin/id ] ;or  [ -f /usr/bin/id ] ;or echo "WARNING: id not found, function setupPath"
    if test "$UID" -eq 0
        debug "  UID is 0, root path setup"
        set fish_user_paths /bin /usr/bin/ /sbin /usr/sbin  # no /usr/local,... for root
    else
        debug "  UID is $UID, non root path setup"
        set fish_user_paths /bin /usr/bin/ /sbin /usr/sbin /usr/local/bin /usr/local/sbin
        build_path_by_config_files
    end
    set -g CDPATH '.:~/prj:/opt/ConfigShell' # specification with spaces did not work
end

# optSourceFile tries to read an optionally existing script file to be sourced into the current shell.
function optSourceFile
    debug in optSourceFile $argv
    if ! count $argv >/dev/null         # err no argument supplied to optSourceFile
        err "  ERROR: optSourceFile was called without an argument."
        return
    end
    if ! test -f $argv[1]               # ok, if the file is not existing that is to be sourced, no err msg
        return
    end
    if ! test -r $argv[1]               # err supplied plain file is not readable
        err "  ERROR: optSourceFile supplied argument :$argv[1]: not readable"
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
     else
        echo not in git
     end
 end

function fish_prompt_configshell -d "prompt for Configshell, toggable"
    set -l res $status
    if test "$res" -eq 0
        set resString (set_color white)"$res"
    else
        set resString (set_color -o red)"$res"(set_color white)
    end
    printf '[%s]%s · %s%s@%s%s · %s%s%s · %s%s%s · %s%s%s · %s%s%s\n>' \
        $resString (set_color blue) \
        (set_color white) $USER $hostname (set_color blue) \
        (set_color green) AWS:$AWS_PROFILE (set_color blue) \
        (set_color magenta) (watson status) (set_color blue) \
        (set_color red) (git_prompt_status) (set_color blue) \
        (set_color yellow) (pwd | sed -E "s,$HOME,~,") (set_color white)
end

function setPromptConfigShell -d 'set the prompt for ConfigShell'
    if not set -q fishPromptConfigShell ;or test "$fishPromptConfigShell" -eq 0
        functions -e fish_prompt_orig
        functions -c fish_prompt fish_prompt_orig
        functions -e fish_prompt
    end
    functions -e fish_prompt    # the next line copying to fish_prompt creates an error if fish_prompt already exists
    functions -c fish_prompt_configshell fish_prompt
    set -g fishPromptConfigShell 1
    touch "$HOME/.config/fish/configshellPrompt"
end 

function setPromptOrig -d 'set the prompt to the stored version'
    if functions -q fish_prompt_orig 
        functions -e fish_prompt
        functions -c fish_prompt_orig fish_prompt
        set -g fishPromptConfigShell 0 
        /bin/rm -f "$HOME/.config/fish/configshellPrompt"
    else
        echo No stored backup version. >&2
    end
end

function promptToggle -d 'toggle the current prompt setup with configShell prompt style'
    if not set -q fishPromptConfigShell
        echo ERROR variable fishPromptConfigShell not set
    else
        if test $fishPromptConfigShell -eq 0
            setPromptConfigShell
        else
            setPromptOrig
        end
    end
end

function setupPrompt -d "fish prompt controlled by ~/.config/fish/configshellPrompt"
    debug "default prompt mode for bobthefish, should do not harm for other shells"
    set -g theme_show_exit_status yes
    set -g theme_newline_cursor yes

    set -g theme_display_git yes
    set -g theme_display_git_dirty yes
    set -g theme_display_git_untracked yes
    set -g theme_display_git_dirty_verbose yes
    set -g theme_display_git_ahead_verbose yes
    set -g theme_display_git_stashed_verbose yes
    set -g theme_display_git_default_branch yes

    set -g theme_display_sudo_user yes
    set -g theme_display_user ssh
    set -g theme_display_hostname ssh
    
    set -g fish_prompt_pwd_dir_length 0
    
    set -g theme_powerline_fonts yes
    set -g theme_display_ruby yes
    set -g theme_display_docker_machine yes
    set -g theme_display_k8s_context yes
    set -g theme_display_k8s_namespace yes
    set -g theme_display_go verbose
    set -g theme_display_node yes
    set -g theme_display_nix no
    
    if test -f "$HOME/.config/fish/configshellPrompt"
        setPromptConfigShell
    else
        set -g fishPromptConfigShell 0 
    end
    if not test -f "$HOME/.config/fish/configshellSupport"
        set_color red
        echo You can change/toggle to the ConfigShell prompt using promptToggle.
        set_color normal
        touch "$HOME/.config/fish/configshellSupport"
    end
end

function setupCompletion -d "load completion for rsync and ssh"
    debug in setupCompletion
    if test -r ~/.ssh/completion.lst
        complete -F -c rsync -a ~/.ssh/completion.lst
        complete -x -c ssh -a ~/.ssh/completion.lst
    else
        err 'Cannot find ~/.ssh/completion.lst. Cannot load completions for ssh and rsync.'
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
    [ -n "$SSH_AUTH_SOCK" ] ;and [ -n "$SSH_TTY" ] ; and return

    ssh-add -l 2>/dev/null 1>&2 ; set -l res $status
    switch $res
        case 0
            debug '  ssh agent found, keys loaded (status 0)'
        case 1
            debug '  ssh-agent loaded, but no identities loaded (status 1)'
            ssh-add
        case 2
            debug '  ssh-agent could not be contacted, starting (status 2)'
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
    set -g -x RSYNC_Add_Windows "--modify-window=1" # Windows FS updates file-times only every 2nd second
    set -g -x RSYNC_Add_RemoveSLinks "--copy-links"  # convert links into fi    les
    set -g -x VISUAL vim
    set -g -x EDITOR $VISUAL       # bsroot has no notion about VISUAL
    set -g -x BLOCKSIZE 1K
    set -g -x COLUMNS
    set -g -x PROFILES_CONFIG_DIR /opt/ConfigShell
    set -g -x CONFIGSHELL_FISH_VERSION ($SHELL -c 'cd /opt/ConfigShell/fish ; /opt/ConfigShell/bin/version.sh')
    if test -n "$_current_CONFIGSHELL_FISH_VERSION" -a "$CONFIGSHELL_FISH_VERSION" != "$_current_CONFIGSHELL_FISH_VERSION"
        echo New CONFIGSHELL_FISH_VERSION "$CONFIGSHELL_FISH_VERSION"
    end
    set -g _current_CONFIGSHELL_FISH_VERSION "$CONFIGSHELL_FISH_VERSION"
    export LC_ALL=en_US.UTF-8 # required for ansible-vault -> git gee
end

if status is-interactive # main code
    debug "main - is-interactive case"
    optSourceFile ~/.config/fish/pre.fish

    setupExportVars
    command -v watson &>/dev/null ; or alias watson 'echo >/dev/null' # required for prompt
    set -g fish_greeting "Welcome to ConfigShell's fish setup"
    setupPath
    setupAliases_Abbreviations
    setupCompletion
    setupSsh

    for file in $HOME/.config/fish/conf.d/*.sh $HOME/.sh.d/*.sh
        debug "  executing $file"
        command -q bash ; and bash $file
        command -q bash ; or echo bash not found >&2
    end
    for file in $HOME/.fishrc.d/*.fish $HOME/.fishrc.d/*.sh
        debug "  executing $file"
        fish $file
    end
    for file in $HOME/.fishrc.d/*.fishrc $HOME/.fishrc.d/*.rc
        debug "  sourcing $file"
        source $file
    end

    optSourceFile ~/.config/fish/post.fish

    hadmRealUser
    command -q thefuck ; and thefuck --alias | source
    command -q thefuck ; or debug thefuck not found >&2
    #    command -q starship ; and starship init fish | source ; or setupPrompt
    #command -q starship ; or debug starship not found >&2
    command -q zoxide ; and zoxide init fish | source
    command -q zoxide ; or debug zoxide not found >&2
end

# EOF
