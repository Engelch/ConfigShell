#! /usr/bin/env fish

set a (fish -i -c 'cd /opt/ConfigShell/lib/tests/fish/Output00DIR/; ' | grep -c (head -n1 /opt/ConfigShell/lib/tests/fish/Output00DIR/00DIR.txt))
# echo a is $a
if test "$a" = '1'
    echo ok: passed (dirname (pwd) | xargs basename)
else
    echo FAIL: test (dirname (pwd) | xargs basename):output was $a
end

# eof
