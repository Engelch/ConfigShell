# ChangeLog fish Configuration

## version 5.14

- CDPATH environment variable introduced pointing to $HOME
- looking for directory $HOME/.fishrc.d
  - if *.fish file inside, execute it as a subshell
  - if *.fishrc file inside, source it into the current shell
