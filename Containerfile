FROM docker.io/library/alpine:latest AS builder

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
    ln -sr /output/usr/share/backgrounds/aurora/aurora-wallpaper-6/ /output/usr/share/backgrounds/aurora/aurora-wallpaper-1 && \
    ln -sr /output/usr/share/backgrounds/aurora/aurora-wallpaper-1/ /output/usr/share/wallpapers/ && \
    rm -rf /wallpapers

FROM scratch AS ctx
COPY --from=ghcr.io/projectbluefin/common:latest /system_files/shared /system_files/shared
COPY --from=builder /output/ /wallpapers
COPY /flatpaks /flatpaks
COPY /logos /logos
COPY /system_files /system_files
