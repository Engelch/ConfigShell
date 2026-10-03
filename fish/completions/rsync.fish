# rsync: offer hosts/users only for a remote-looking token (contains @)
# or once a first path argument has been given. Wraps the stock completion.
function __rsync_want_remote
    commandline -ct | string match -q '*@*'; and return 0
    test (count (commandline -opc | string match -v -- '-*')) -ge 2
end

# Locate the stock completion: embedded in the binary (fish >= 4.1),
# else in the data dir (/usr/share/fish, /usr/local/share/fish, /opt/homebrew/share/fish, ...).
set -l stock (status get-file completions/rsync.fish 2>/dev/null)
if not set -q stock[1]; and test -r "$__fish_data_dir/completions/rsync.fish"
    set stock (cat $__fish_data_dir/completions/rsync.fish)
end

if set -q stock[1]
    complete -c rsync -e    # drop rules already loaded, incl. the unconditional host rule
    string replace -- 'complete -c rsync -d Hostname -a' \
        'complete -c rsync -d Hostname -n __rsync_want_remote -a' $stock | source
end
