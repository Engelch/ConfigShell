# ---- Linux -----------------------------------------------------------------------

function setupLinux() {          # Linux-specific settings of aliases and shell-functions
   debug4 '>>>>' setupLinux
   eval $(dircolors)
   export LS_COLOUR='--color=auto'
   common.aliases.ls             # realias ls commands to reflect colour mode
   alias proc='ps -ef | grep -i '
   alias o=xdg-open
   alias open=o
   alias xlock='xlock -remote -mode blank -allowroot'
   alias xl=xlock

   if [[ $(uname -r) =~ Microsoft ]] ; then  # WSL
      debug Microsoft environment detected
      alias docker=docker.exe
      alias kubectl=kubectl.exe
      alias k=kubectl.exe
   fi

   # systemd ; always load them, as likelihodd is high that it exists :-(
   function sylt() { systemctl list-timers $* ; }
   function sylu() { systemctl list-units $* ; }
   function syrestart() { systemctl restart $* ; systemctl --no-pager status $* ; }
   alias restat=syrestart
   function systart() { systemctl start $* ; systemctl --no-pager status $* ; }
   alias systat='systemctl status'
   function systop() { systemctl stop $* ; systemctl --no-pager status $* ; }

   function pkgU() {
      local found=0
      [ -e /etc/debian_version ] && found=1 && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade && sudo apt-get autoremove
      command -v dnf &>/dev/null && found=1 && sudo dnf -y upgrade && sudo dnf -y clean packages
      command -v dnf &>/dev/null || command -v yum &>/dev/null && found=1 && sudo yum -y update && sudo yum -y clean packages
      [ $found -eq 0 ] && error pkgU not supported for this OS && return 1
      touch ~/.pkgU
   }
}

function os.Linux.init() {
   debug4 os.Linux.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   setupLinux
}

function os.Linux.del() {
   debug4 os.Linux.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}

# EOF
