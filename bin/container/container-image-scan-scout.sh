#!/usr/bin/env bash
# container-image-scan-scout.sh — Docker Scout quickview of an image, result stored as scout:<yymmdd>-<image>.txt
#
#   container-image-scan-scout.sh [-c] [-t TAG] IMAGE:VERSION
#
# Default: the locally installed plugin (~/.docker/scout/docker-scout or `docker scout`).
# -c (or SCOUT_CONTAINER=1): run the CLI from the container image docker/scout-cli instead — nothing to
#    install or update locally, the :latest tag is always the current release (-t TAG pins one, e.g. 1.24.0).
#    The container needs Docker Hub credentials (it cannot use the host's `docker login`/keychain):
#      DOCKER_SCOUT_HUB_USER      Docker Hub user name
#      DOCKER_SCOUT_HUB_PASSWORD  a Docker Hub personal access token (PAT)
#    taken from the environment, else sourced from ./scout.pws (NAME=value lines; by our convention a
#    symlink to an encrypted .pw outside the repo). The local image is handed over as a `docker save`
#    tarball (archive://), so the container does not need the Docker socket.
#
# Changelog
# 2.0.2 report header with the image name; scout's engine-connect notice filtered (archive mode needs no socket)
# 2.0.1 credentials from scout.pws are exported (docker run -e NAME forwards exported variables only)
# 2.0  -c: containerized scout CLI (docker/scout-cli), scout.pws credentials, -t tag; exit codes documented
# 1.x  local plugin only
#
# EXIT 1 no image given / unknown option, 2 credentials missing (-c), 3 docker save failed,
#      else the exit code of scout

useContainer="${SCOUT_CONTAINER:-}"
scoutTag="${SCOUT_CLI_TAG:-latest}"
while getopts "ct:" opt; do
    case "$opt" in
        c) useContainer=1 ;;
        t) scoutTag="$OPTARG" ;;
        *) 1>&2 echo "usage: $0 [-c] [-t TAG] IMAGE:VERSION"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

containerimage="$1"
[ -z "$containerimage" ] && 1>&2 echo ERROR:containerImage:version must be specified && exit 1
current_date="$(date +%y%m%d)"
readonly outputFile="scout:${current_date}-$containerimage.txt"
echo creating file "$outputFile"

if [ -n "$useContainer" ] ; then
    if [ -f scout.pws ] && [ -z "${DOCKER_SCOUT_HUB_USER:-}" ] ; then
        set -a          # auto-export: `docker run -e NAME` forwards exported variables only
        source ./scout.pws
        set +a
    fi
    export DOCKER_SCOUT_HUB_USER DOCKER_SCOUT_HUB_PASSWORD   # also when set in the shell without export
    if [ -z "${DOCKER_SCOUT_HUB_USER:-}" ] || [ -z "${DOCKER_SCOUT_HUB_PASSWORD:-}" ] ; then
        1>&2 echo "ERROR: DOCKER_SCOUT_HUB_USER and DOCKER_SCOUT_HUB_PASSWORD (a Docker Hub PAT) are required for -c; set them or provide ./scout.pws"
        exit 2
    fi
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/scout.XXXXXX")
    trap 'rm -rf "$tmpdir"' EXIT
    docker save -o "$tmpdir/image.tar" "$containerimage" || { 1>&2 echo "ERROR: docker save $containerimage failed"; exit 3; }
    # the report names the archive as target, so record the image here; scout's "Failed to connect to
    # Docker Engine" is informational (it falls back to the archive) — no socket is mounted on purpose
    echo "# $containerimage — docker/scout-cli:$scoutTag, scanned as docker save archive" | tee "$outputFile"
    docker run --rm \
        -e DOCKER_SCOUT_HUB_USER -e DOCKER_SCOUT_HUB_PASSWORD \
        -v "$tmpdir/image.tar:/image.tar:ro" \
        "docker/scout-cli:$scoutTag" quickview "archive:///image.tar" | grep -v 'Failed to connect to Docker Engine' | tee -a "$outputFile"
elif [ -f "$HOME/.docker/scout/docker-scout" ] ; then
    "$HOME/.docker/scout/docker-scout" quickview "$containerimage" | tee  "$outputFile"
else
    docker scout quickview "$containerimage" | tee  "$outputFile"
fi
rc=${PIPESTATUS[0]}
[ "$rc" -ne 0 ] && /bin/rm -f "$outputFile"
exit "$rc"
