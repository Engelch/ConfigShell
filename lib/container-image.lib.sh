declare -r _appVersion="2.6.0"

####################################################################################
########### set the container command
####################################################################################


# setContainerCmd determines whether podman (preferred) or docker shall be used
# An error is created if none of them could be found.
# EXIT 10
function setContainerCmd() {
    which docker &>/dev/null && containerCmd=docker
    which podman &>/dev/null && containerCmd=podman
    [ -z "$containerCmd" ] && errorExit 10 container command could not be found
    debug Container command is "$containerCmd"
}

# setContainerName determines the name of the container image to be created.
# An error is created if none of them could be found.
# EXIT 12
function setContainerName() {
    if [ "$(/bin/ls | grep -c '^_name_.*' )" -eq 1 ] ; then
        containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
    else
        containerName=$(dirname "$PWD" | xargs basename)
    fi
    [ -z "$containerName" ] && errorExit 12 Container name could not be determined
    debug "containerName is $containerName"
}


# setContainerFile determines the Containerfile or Dockerfile to be used.
# An error is created if none of them could be found.
# EXIT 11
# EXIT 13
function setContainerFile() {
    for file in Containerfile Dockerfile ; do
        [ -f "$file" ] && debug "Containerfile is $file" && containerFile="$file"
        break
    done
    [ -z "$containerFile" ] && errorExit 11 Could not find a Containerfile
    [ -f Containerfile.j2 ] && [ Containerfile.j2 -nt "$containerFile" ] && \
        if [ "${skipTestContainerfileJ2:-}" = TRUE ] ; then echo "Notice: Containerfile.j2 newer than $containerFile"1>&2 ; else \
          echo "Stopping: Containerfile.j2 is newer than $containerFile" && exit 13 ; fi
    debug "ok $containerFile"
}


# login2aws performs a login into AWS to make AWS ECR repositories available.
# The function is called by loginAwsIfInContainerfile
# EXIT 6    AWS_PROFILE not set
# EXIT 7    aws.cfg not found
# EXIT 8    AWS region not set
# EXIT 9    AWS registry not set
function login2aws() {
    if [ -z "${AWS_PROFILE}" ]  ; then
      _err=0
      [ -z "${AWS_ACCESS_KEY_ID}" ] && _err=6
      [ -z "${AWS_SECRET_ACCESS_KEY}" ] && _err=6
      [ -z "${AWS_SESSION_TOKEN}" ] && _err=6
      [ ${_err} = 6 ] && errorExit 6 "AWS_PROFILE environment variable is required, in order to login to the docker registry"
    fi 
    [ -n "$AWS_PROFILE"] && debug AWS_PROFILE set to "$AWS_PROFILE"
    [ -z "$AWS_PROFILE"] && debug AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN set

    # vars expected in aws.cfg
    #REGION=
    REGISTRY=
    ! [ -f aws.cfg ] && errorExit 7 "AWS Configuration aws.cfg not found"
    source "aws.cfg"

    [ -z "$REGION" ] && errorExit 8 "AWS Region not set"
    [ -z "$REGISTRY" ] && errorExit 9  "AWS Registry not set"

    debug "Login to AWS..."
    # login to AWS
    debug "aws ecr get-login-password --region ${REGION} | $containerCmd login --username AWS --password-stdin $REGISTRY"
    $DRY aws ecr get-login-password --region "${REGION}" | "$containerCmd" login --username AWS --password-stdin "$REGISTRY"
}

# EOF
