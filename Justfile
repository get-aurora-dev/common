# Build the aurora-common container locally
build:
    buildah build -t common:latest -f ./Containerfile .
