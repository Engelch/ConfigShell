# ---- Linux -----------------------------------------------------------------------

function setupLinuxPath() {
   # only check for WSL, could also be cached
   debug8 in setupLinuxPath ..................

   [ -d /mnt/c/ ] && debug4 build up linux path file... && for _POTENTIAL_DIR in \
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
}

LinuxPath=$HOME/.env.os.$uname.path

function env.os.Linux.init() {
   debug4 env.Linux.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   [ -f "$LinuxPath" ] && debug8 cached .env.Linux.path file found && return
   setupLinuxPath
}

function env.os.Linux.del() {
   debug4 env.os.Linux.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   [ -f "$LinuxPath" ] && /bin/rm "$LinuxPath"
}

# EOF
