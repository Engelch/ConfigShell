[ "$(uname)" != Darwin ] && 1>&2 echo "script to test different architectures makes only sense on Darwin alias OSX." && exit 1

echo "date --202306"
echo podman has the behaviour to keep the last architeture
echo which was used with the previous podman command.
echo "Let's test it..."
echo ""
echo 1. podman with explicit architecdture arm64 executes...
podman run -q --rm --arch=arm64 ubuntu uname -m 
echo 2. podman without an architecture set executes....
podman run -q --rm ubuntu uname -m 
echo 3. podman with explicit architecdture amd64  executes...
podman run -q --rm --arch=amd64 ubuntu uname -m
echo 4. podman without an architecture set executes....
podman run -q --rm ubuntu uname -m
