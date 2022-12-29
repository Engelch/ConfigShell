function ansibleListTags
    for i in $argv
        ansible-playbook --list-tags $i 2>&1
    end | grep "TASK TAGS" | cut -d":" -f2 | awk '{sub(/\[/, "")sub(/\]/, "")}1' | sed -e 's/,//g' | xargs -n 1 | sort -u
end