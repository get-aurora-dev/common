#!/usr/bin/env bash

set -euo pipefail

source /usr/lib/ublue/setup-services/libsetup.sh
version-script aurora-flatpak user 1 || exit 0

# More consistent Qt/GTK themes for Flatpaks
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
