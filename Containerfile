FROM docker.io/library/alpine:latest@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412 AS builder

RUN apk add --no-cache curl jq zstd tar coreutils

COPY --from=ghcr.io/ublue-os/aurora-wallpapers:latest / /wallpapers

RUN set -xeuo pipefail && \
    cd /wallpapers && \
    rm -rf kde/*/gnome-background-properties/ && \
    mkdir -p /output/usr/share/wallpapers /output/usr/share/backgrounds && \
    mv kde/ /output/usr/share/backgrounds/aurora/ && \
    cd /output/usr/share/backgrounds && \
    for dir in aurora/*; do \
      ln -sr "/output/usr/share/backgrounds/${dir}" /output/usr/share/wallpapers/; \
    done && \
    ln -sr /output/usr/share/backgrounds/aurora/aurowa-wallpaper-6/ /output/usr/share/backgrounds/aurora/aurora-wallpaper-1 && \
    ln -sr /output/usr/share/backgrounds/aurora/aurora-wallpaper-1/ /output/usr/share/wallpapers/ && \
    rm -rf /wallpapers

FROM scratch AS ctx

COPY --from=builder /output/ /wallpapers

COPY /brew /brew
COPY /flatpaks /flatpaks
COPY /just /just
COPY /logos /logos
COPY /system_files /system_files
