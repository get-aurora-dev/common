FROM docker.io/library/alpine:latest AS builder

RUN apk add curl jq zstd tar

ENV URL="https://api.github.com/repos/ublue-os/artwork/releases"

RUN sh <<'EOF'
# tagged with date of aurora-wallpaper creation
set -xeuo pipefail
TARBALL=$(curl -s ${URL} | jq -r 'first(.[] | .assets[]? | select(.name == "aurora-wallpapers.tar.zstd") .browser_download_url)')

curl -L $TARBALL -o /tmp/aurora-wallpapers.tar.zstd
EOF

RUN sh <<'EOF'
mkdir -p /output/
mkdir -p /tmp/aurora-wallpapers
tar -xvf /tmp/aurora-wallpapers.tar.zstd -C /tmp/aurora-wallpapers

cd /tmp/aurora-wallpapers
# We don't need gnome metadata
rm -rf kde/*/gnome-background-properties/

mkdir -p /output/usr/share/backgrounds
mkdir -p /output/usr/share/wallpapers
mv /tmp/aurora-wallpapers/kde/ /output/usr/share/backgrounds/aurora/

# make relative symlinks so wallpapers are actually in
# /usr/share/backgrounds/aurora/name1 but accessible also accesible
# in /usr/share/wallpapers/name1
cd /output/usr/share/backgrounds
for dir in ../backgrounds/aurora/*; do
  ln -s "${dir}" ../wallpapers/
done

# FIXME
# symlink the deleted AI slop with it's replacement
#cd /output/usr/share
#ln -s backgrounds/aurora/aurora-wallpaper-6 ../backgrounds/aurora/aurora-wallpaper-1
## same reason as above
#ln -s backgrounds/aurora/aurora-wallpaper-1/ wallpapers/aurora-wallpaper-1

EOF

FROM scratch AS ctx

COPY --from=builder /output/ /wallpapers

COPY /brew /brew
COPY /flatpaks /flatpaks
COPY /just /just
COPY /logos /logos
COPY /system_files /system_files

