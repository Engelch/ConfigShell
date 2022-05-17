function setupBSD() { 
   debug4 setupBSD
   alias proc='ps auxww | egrep -i '
   alias o=xdg-open
   alias open=o
   alias xlock='xlock -remote -mode blank -allowroot'
   alias xl=xlock
}

function os.FreeBSD.init() {
   debug4 LOADING os.FreeBSD.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   setupBSD
}

function os.FreeBSD.init() {
   debug4 LOADING os.FreeBSD.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}

# EOF
