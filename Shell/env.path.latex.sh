# LaTeX setup might still be a bit Darwin-specific
function setupLaTeX() {
        debug8 creating $1...........
        _latex=$(find /usr/local/texlive -maxdepth 4 -name universal-darwin 2>&- | sort | tail -n1)
        [ ! -z $_latex ] && debug8 found latex path $_latex
        echo $_latex >| $1

        # +o nomatch ::= by default, if a command line contains a globbing expression which doesn't match anything, Zsh will print the error message you're seeing, and not run the command at all. 
        if [ -d /mnt/c/ ] ; then
            debug8 latex bins WSL..... 
            _jdk=$(find /mnt/c/Program\ Files/Java/jdk* -maxdepth 2 -name bin &>/dev/null | sort -n | tail -n1)
            [ ! -z $_jdk ] && echo $_jdk >> $1
        fi
    
        # TEXBASEDIR=${TEXBASEDIR:-/usr/local/texlive}
        # debug4 TEXBASEDIR $TEXBASEDIR
        # TEXPATHFILE="$1"
        # if [ -f "$TEXPATHFILE" ] ; then
        #     for _line in $(egrep -v '^[[:space:]]*$' $TEXPATHFILE) ; do
        #         debug4 loading PATH from LaTeX cache file...
        #         PATH=$PATH:"$_line"
        #     done
        # else
        #     debug4 latex found but no cache file, building cache file...
        #     # executing the finds takes time. So, let's cache the result.
        #     if [ -d "$TEXBASEDIR" -a ! -f "$TEXPATHFILE" ] ; then
        #         debug4 creating TEXPATHFILE $TEXPATHFILE...
        #         # determine current distribution (just for a century :-)
        #         TEX_DISTRIB_DIR=$(find /usr/local/texlive -type d -mindepth 1 -maxdepth 1 | grep /20 | tail -n 1)
        #         debug4 TEX_DISTRIB_DIR is $TEX_DISTRIB_DIR
        #         # determine non-annual TeX-directories (not required at the moment)
        #         # TEX_OTHER_DIRS=$(ls -d1 /usr/local/texlive/* | egrep -v '.*20[[:digit:]][[:digit:]]')
        #         _os=$(uname | tr '[A-Z]' '[a-z]')
        #         # limit depth for speed purposes
        #         find "$TEX_DISTRIB_DIR" -type d -maxdepth 4 -name 'bin' | egrep '/bin$'  >| $TEXPATHFILE
        #         find "$TEX_DISTRIB_DIR" -type d -maxdepth 4 -name "\*$_os"   >> $TEXPATHFILE
        #     fi
        # fi
}

LATEX_PATH=$HOME/.env.latex.path

function env.path.latex.init() {
    debug4 env.path.latex.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ -f $LATEX_PATH ] && debug8 $LATEX_PATH found, returning && return 
    debug8 $LATEX_PATH not found, creating it
    setupLaTeX $LATEX_PATH
}

function env.path.latex.del() {
    debug4 env.path.to.latex.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ -f $LATEX_PATH ] && \
        debug8 env.path.latex.del: $LATEX_PATH found, removing it && \
        /bin/rm $LATEX_PATH && \
        return
    debug8 env.path.latex.del: No LATEX_PATH $LATEX_PATH found.
}

# EOF
