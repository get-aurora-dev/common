# Build the aurora-common container locally
build:
    buildah build -t localhost/aurora-common:latest -f ./Containerfile .

check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
        just --unstable --fmt --check -f Justfile

# Inspect the directory structure of an OCI image
tree IMAGE="localhost/aurora-common:latest":
    echo "FROM alpine:latest" > TreeContainerfile
    echo "RUN apk add --no-cache tree" >> TreeContainerfile
    echo "COPY --from={{IMAGE}} / /mnt/root" >> TreeContainerfile
    echo "CMD tree /mnt/root" >> TreeContainerfile
    podman build -t tree-temp -f TreeContainerfile .
    podman run --rm tree-temp
    rm TreeContainerfile
    podman rmi tree-temp
