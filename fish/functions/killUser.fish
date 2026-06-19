function killUser
    for user in $argv
        echo killing user $user... 1>&2
        ps -ef | grep $user | awk '{print $2}' | xargs sudo kill -9
    end
end
