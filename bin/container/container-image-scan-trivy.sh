#!/usr/bin/env bash
# container-image-scan-trivy.sh — Trivy scan of an image, result stored as trivy:<yymmdd>-<image>.txt
#
#   container-image-scan-trivy.sh [-c] [-t TAG] IMAGE:VERSION
#
# Default: the locally installed trivy.
# -c (or TRIVY_CONTAINER=1): run trivy from the container image aquasec/trivy instead — nothing to install
#    or update locally (:latest, or -t TAG to pin). The local image is handed over as a `docker save`
#    tarball (--input), so the container does not need the Docker socket. The vulnerability DB is kept in
#    the named volume trivy-cache, so only the first run downloads it (`docker volume rm trivy-cache` resets).
#
# Changelog
# 2.0  -c: containerized trivy (aquasec/trivy), DB cache volume, -t tag; exit codes documented
# 1.x  local trivy only
#
# EXIT 1 no image given / unknown option, 3 docker save failed, else the exit code of trivy

useContainer="${TRIVY_CONTAINER:-}"
trivyTag="${TRIVY_TAG:-latest}"
while getopts "ct:" opt; do
    case "$opt" in
        c) useContainer=1 ;;
        t) trivyTag="$OPTARG" ;;
        *) 1>&2 echo "usage: $0 [-c] [-t TAG] IMAGE:VERSION"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

containerimage="$1"
[ -z "$containerimage" ] && 1>&2 echo ERROR:containerImage:version must be specified && exit 1
current_date="$(date +%y%m%d)"
readonly outputFile="trivy:${current_date}-$containerimage.txt"
echo creating file "$outputFile"

if [ -n "$useContainer" ] ; then
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/trivy.XXXXXX")
    trap 'rm -rf "$tmpdir"' EXIT
    docker save -o "$tmpdir/image.tar" "$containerimage" || { 1>&2 echo "ERROR: docker save $containerimage failed"; exit 3; }
    echo "# $containerimage — aquasec/trivy:$trivyTag, scanned as docker save archive" | tee "$outputFile"
    docker run --rm \
        -v trivy-cache:/root/.cache/ \
        -v "$tmpdir/image.tar:/image.tar:ro" \
        "aquasec/trivy:$trivyTag" image --input /image.tar | tee -a "$outputFile"
else
    trivy image "$containerimage" | tee "$outputFile"
fi
rc=${PIPESTATUS[0]}
[ "$rc" -ne 0 ] && /bin/rm -f "$outputFile"
exit "$rc"
