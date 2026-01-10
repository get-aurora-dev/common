FROM docker.io/library/alpine:latest AS builder

RUN apk add --no-cache curl jq zstd tar coreutils imagemagick rsvg-convert

COPY --from=ghcr.io/ublue-os/aurora-wallpapers:latest / /wallpapers

COPY /logos /logos

RUN set -xeuo pipefail && \
    cd /wallpapers && \
    rm -rf kde/*/gnome-background-properties/ && \
    mkdir -p /out/wallpapers/usr/share/wallpapers /out/wallpapers/usr/share/backgrounds && \
    mv kde/ /out/wallpapers/usr/share/backgrounds/aurora/ && \
    cd /out/wallpapers/usr/share/backgrounds && \
    for dir in aurora/*; do \
      ln -sr "/out/wallpapers/usr/share/backgrounds/${dir}" /out/wallpapers/usr/share/wallpapers/; \
    done && \
    ln -sr /out/wallpapers/usr/share/backgrounds/aurora/aurora-wallpaper-6/ /out/wallpapers/usr/share/backgrounds/aurora/aurora-wallpaper-1 && \
    ln -sr /out/wallpapers/usr/share/backgrounds/aurora/aurora-wallpaper-1/ /out/wallpapers/usr/share/wallpapers/ && \
    rm -rf /wallpapers

# Here we set our default wallpaper
RUN set -xeuo pipefail && \
    ln -sr /out/wallpapers/usr/share/backgrounds/aurora/aurora-wallpaper-9/contents/images/3840x2160.jxl /out/wallpapers/usr/share/backgrounds/default.jxl && \
    ln -sr /out/wallpapers/usr/share/backgrounds/aurora/aurora-wallpaper-9/contents/images/3840x2160.jxl /out/wallpapers/usr/share/backgrounds/default-dark.jxl && \
    ln -sr /out/wallpapers/usr/share/backgrounds/aurora/aurora.xml /out/wallpapers/usr/share/backgrounds/default.xml

RUN set -xeuo pipefail && \
    mkdir -p /out/logos/usr/share/icons/hicolor/scalable/apps && \
    mkdir -p /out/logos/usr/share/icons/hicolor/scalable/places && \
    mkdir -p /out/logos/usr/share/pixmaps && \
    cp /logos/distributor-logo.svg /out/logos/usr/share/icons/hicolor/scalable && \
    cp \
      /logos/auroralogo-white.svg \
      /logos/distributor-logo-symbolic.svg \
      /logos/auroralogo-circle-symbolic.svg \
      /logos/auroralogo-pride.svg \
      /logos/auroralogo-pride-trans.svg \
      /out/logos/usr/share/icons/hicolor/scalable/places/ && \

    cp /logos/aurora-banner.svg /out/logos/usr/share/pixmaps/ && \
    ln -sr /out/logos/usr/share/pixmaps/aurora-banner.svg /out/logos/usr/share/pixmaps/fedora-logo.svg && \

    magick -background none /logos/aurora-banner.svg -quality 90 -resize $((400-10*2))x100 -gravity center -extent 400x100 /out/logos/usr/share/pixmaps/fedora-logo.png && \
    magick -background none /logos/aurora-banner.svg -quality 90 -resize $((128-3*2))x32 -gravity center -extent 128x32 /out/logos/usr/share/pixmaps/fedora-logo-small.png && \
    magick -background none /logos/aurora-banner.svg -quality 90 -resize $((200-5*2))x50 -gravity center -extent 200x100 /out/logos/usr/share/pixmaps/fedora_logo_med.png  && \
    magick -background none /logos/distributor-logo.svg -quality 90 -resize 256x256! /out/logos/usr/share/pixmaps/system-logo.png  && \
    magick -background none /logos/distributor-logo.svg -quality 90 -resize 128x128! /out/logos/usr/share/pixmaps/fedora-logo-sprite.png  && \
    magick -background none /logos/distributor-logo.svg -quality 90 -resize 256x256! /out/logos/usr/share/pixmaps/system-logo-white.png  && \

    ln -sr /out/logos/usr/share/pixmaps/aurora-banner.svg /out/logos/usr/share/pixmaps/fedora_whitelogo.svg && \
    ln -sr /out/logos/usr/share/icons/hicolor/scalable/distributor-logo.svg /out/logos/usr/share/pixmaps/fedora-logo-sprite.svg && \
    ln -sr /out/logos/usr/share/icons/hicolor/scalable/distributor-logo.svg /out/logos/usr/share/icons/hicolor/scalable/places/distributor-logo.svg && \
    ln -sr /out/logos/usr/share/icons/hicolor/scalable/distributor-logo.svg /out/logos/usr/share/icons/hicolor/scalable/places/auroralogo-gradient.svg && \
    ln -sr /out/logos/usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /out/logos/usr/share/icons/hicolor/scalable/places/auroralogo-symbolic.svg && \
    ln -sr /out/logos/usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /out/logos/usr/share/icons/hicolor/scalable/places/distributor-logo-white.svg && \
    ln -sr /out/logos/usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /out/logos/usr/share/icons/hicolor/scalable/places/start-here.svg && \
    ln -sr /out/logos/usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /out/logos/usr/share/icons/hicolor/scalable/apps/start-here.svg

RUN set -xeuo pipefail && \
  mkdir -p /out/logos/usr/share/plymouth/themes/spinner/ && \
  magick -background none /out/logos/usr/share/pixmaps/aurora-banner.svg -quality 90 -resize $((128-3*2))x32 -gravity center -extent 128x32 /out/logos/usr/share/plymouth/themes/spinner/watermark.png && \
  cp /out/logos/usr/share/plymouth/themes/spinner/watermark.png /out/logos/usr/share/plymouth/themes/spinner/kinoite-watermark.png && \
  mkdir -p /out/logos/usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop/contents/splash/images/ && \
  gzip -c /out/logos/usr/share/icons/hicolor/scalable/distributor-logo.svg > /out/logos//usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop/contents/splash/images/aurora_logo.svgz && \
  mkdir -p /out/logos/usr/share/sddm/themes/01-breeze-aurora/ && \
  ln -sr /out/logos/usr/share/icons/hicolor/scalable/places/distributor-logo.svg /out/logos/usr/share/sddm/themes/01-breeze-aurora/default-logo.svg

FROM scratch AS ctx
COPY --from=ghcr.io/projectbluefin/common:latest /system_files/shared /system_files/shared
COPY --from=builder /out/wallpapers /wallpapers
COPY --from=builder /out/logos /logos
COPY /system_files /system_files
