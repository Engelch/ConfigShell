function common.path.ruby.init() {
    debug4 common.path.ruby.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ $(uname) = Darwin ] && _chruby=$(brew --prefix)/opt/chruby/share/chruby/chruby.sh && \
        [ -f $_chruby ] && debug8 sourcing chruby && source $_chruby
}

function common.path.ruby.del() {
    debug4 common.path.ruby.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}

# EOF
