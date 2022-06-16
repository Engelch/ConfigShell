function env.path.ruby.init() {
    debug4 env.path.ruby.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ $(uname) = Darwin ] && _chruby=$(brew --prefix)/opt/chruby/share/chruby/chruby.sh && \
        [ -f $_chruby ] && debug8 sourcing chruby && source $_chruby
}

function env.path.ruby.del() {
    debug4 env.path.ruby.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}

# EOF
