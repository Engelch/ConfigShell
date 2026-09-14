#!/usr/bin/env bash
# container-image-scan-snyk.sh — Snyk container test of an image, result stored as snyk:<yymmdd>-<image>.txt
#
#   container-image-scan-snyk.sh [-c] [-t TAG] IMAGE:VERSION
#
# Default: the locally installed snyk CLI (authenticated with `snyk auth`).
# -c (or SNYK_CONTAINER=1): run the CLI from the container image snyk/snyk instead — nothing to install or
#    update locally (:linux, or -t TAG to pin, e.g. linux@sha256:... ). The container needs the API token:
#      SNYK_TOKEN   from the environment, else sourced from ./snyk.pws (NAME=value; by our convention a
#                   symlink to an encrypted .pw outside the repo). `snyk config get api` prints the token of
#                   a locally authenticated CLI.
#    The local image is handed over as a `docker save` tarball (docker-archive:), so the container does
#    not need the Docker socket.
#
# Changelog
# 2.0.1 --platform linux/amd64 for the container (snyk/snyk has no arm64 images; SNYK_PLATFORM overrides)
# 2.0  -c: containerized snyk CLI (snyk/snyk), snyk.pws token, -t tag; exit codes documented
# 1.x  local snyk only
#
# EXIT 1 no image given / unknown option, 2 token missing (-c), 3 docker save failed,
#      else the exit code of snyk (1 = vulnerabilities found — the report is kept in that case)

useContainer="${SNYK_CONTAINER:-}"
snykTag="${SNYK_CLI_TAG:-linux}"
while getopts "ct:" opt; do
    case "$opt" in
        c) useContainer=1 ;;
        t) snykTag="$OPTARG" ;;
        *) 1>&2 echo "usage: $0 [-c] [-t TAG] IMAGE:VERSION"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

containerimage="$1"
[ -z "$containerimage" ] && 1>&2 echo ERROR:containerImage:version must be specified && exit 1
current_date="$(date +%y%m%d)"
readonly outputFile="snyk:${current_date}-$containerimage.txt"
echo creating file "$outputFile"

if [ -n "$useContainer" ] ; then
    if [ -f snyk.pws ] && [ -z "${SNYK_TOKEN:-}" ] ; then
        set -a          # auto-export: `docker run -e NAME` forwards exported variables only
        source ./snyk.pws
        set +a
    fi
    export SNYK_TOKEN
    if [ -z "${SNYK_TOKEN:-}" ] ; then
        1>&2 echo "ERROR: SNYK_TOKEN is required for -c; set it or provide ./snyk.pws"
        exit 2
    fi
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/snyk.XXXXXX")
    trap 'rm -rf "$tmpdir"' EXIT
    docker save -o "$tmpdir/image.tar" "$containerimage" || { 1>&2 echo "ERROR: docker save $containerimage failed"; exit 3; }
    echo "# $containerimage — snyk/snyk:$snykTag, scanned as docker save archive" | tee "$outputFile"
    # snyk/snyk is published for amd64 only (no arm64 tags on Docker Hub): on an arm64 Mac the container
    # runs under emulation (Docker Desktop uses Rosetta; the CLI is a Node.js app and works fine, just slower)
    docker run --rm --platform "${SNYK_PLATFORM:-linux/amd64}" \
        -e SNYK_TOKEN \
        -v "$tmpdir/image.tar:/image.tar:ro" \
        "snyk/snyk:$snykTag" snyk container test "docker-archive:/image.tar" 2>&1 | tee -a "$outputFile"
else
    snyk container test "$containerimage" 2>&1 | tee "$outputFile"
fi
# snyk exits 1 when it found vulnerabilities: that report is the point, keep it (as before)
exit ${PIPESTATUS[0]}
