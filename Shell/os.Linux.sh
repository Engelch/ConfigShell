# ---- Linux -----------------------------------------------------------------------

function setupLinux() {          # Linux-specific settings of aliases and shell-functions
   debug4 '>>>>' setupLinux
   eval $(dircolors)
   export LS_COLOUR='--color=auto'
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
      [ -e /etc/debian_version ] && found=1 && apt-get update && apt-get dist-upgrade && apt-get autoremove
      command -v dnf &>/dev/null && found=1 && dnf -y upgrade && dnf -y clean packages
      command -v dnf &>/dev/null || command -v yum &>/dev/null && found=1 && yum -y update && yum -y clean packages
      [ $found -eq 0 ] && error pkgU not supported for this OS && return 1
      touch ~/.pkgU
   }
}

function setupLinuxPath() {
   # only check for WSL, could also be cached
   debug4 in setupLinuxPath ..................
   if [ -f $LinuxPath ] ; then
      debug4 cached linux.path file found, sourcing...
      sourcePaths $LinuxPath
   elsif [ -d /mnt/c/ ] && debug4 build up linux path file... && for _POTENTIAL_DIR in \
      /mnt/c/Windows/System32 /mnt/c/Windows /mnt/c/Windows/System32/wbem \
      /mnt/c/Windows/System32/WindowsPowerShell/v1.0 /mnt/c/Users/$USER/AppData/Local/Microsoft/WindowsApps \
      /mnt/c/go/bin /mnt/c/Program\ Files/Microsoft\ VS\ Code/bin \
      /mnt/c/Program\ Files/dotnet/ /mnt/c/Program\ Files/Haskell\ Platform/actual/bin \
      /mnt/c/Program\ Files/Haskell\ Platform/actual/winghci $HOME/$USER/AppData/Roaming/local/bin \
      /mnt/c/Program\ Files/Docker/Docker/resources/bin /mnt/c/Program\ Files/7-Zip \
      /mnt/c/Program\ Files/Affinity/Designer /mnt/c/Program\ Files/Affinity/Photo \
      /mnt/c/Program\ Files/MiKTeX\ 2.9/miktex/bin/x64 /mnt/c/Program\ Files/PDFCreator /mnt/c/Program\ Files/PDFsam\ Basic \
      /mnt/c/Program\ Files/VueScan /mnt/c/Program\ Files/VeraCrypt /mnt/c/Program\ Files/Wireshark \
      /mnt/c/Program\ Files/draw.io /mnt/c/Program\ Files/Mozilla\ Firefox /snap/bin/
      do
         debug8 checking for dir $_POTENTIAL_DIR
         [ -d "$_POTENTIAL_DIR/." ] && debug8 adding path element $_POTENTIAL_DIR && echo $_POTENTIAL_DIR >> $LinuxPath      
      done
      sourcePaths $LinuxPath
   else
      debug4 /mnt/c/ not found
   fi
}

function os.Linux.init() {
   debug4 LOADING os.Linux.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   setupLinux
   setupLinuxPath
}

function os.Linux.del() {
   debug4 LOADING os.Linux.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   LinuxPath=$HOME/.bash.$uname.path
   [ -f $LinuxPath ] && /bin/rm $LinuxPath
}

# EOF
