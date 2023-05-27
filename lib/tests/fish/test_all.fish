#!/usr/bin/env fish
#

function goAndExec
    set odir (pwd) # fish puts output with spaces/lines into one variable, newlines are replaced by spaces
    set ndir (dirname "$argv[1]")
    echo ndir $ndir
    builtin cd "$ndir" ; or exit 99
    set testscript ./(basename "$argv[1]")
    fish $testscript
    builtin cd "$odir"
end

find . -name '*test.fish' -print0 | while read -z  file;
    goAndExec "$file"
end
find . -name '*test.fishrc' -print0 | while read -z  file;
    source "$file"
end
