#!/usr/bin/env bash

set -euo pipefail

source /usr/lib/ublue/setup-services/libsetup.sh
version-script aurora-flatpak user 2 || exit 0

# https://github.com/ublue-os/aurora/issues/3038
migrate_fcitx() {
  LOCAL_UBLUE_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/ublue"
  ID="org.fcitx.Fcitx5"
  FCITX_CONFIG_DIR="${HOME}/.config/fcitx5"
  FCITX_DATA_DIR="${HOME}/.local/share/fcitx5"

  FCITX_FLATPAK="${HOME}/.var/app/${ID}"
  FCITX_DATA_DIR_FLATPAK="${FCITX_FLATPAK}/data"
  FCITX_CONFIG_DIR_FLATPAK="${FCITX_FLATPAK}/config"
  STAMP="aurora-fcitx-flatpak-migration"

  # this should only show it to the people who actually used fcitx
  if [[ ! -f "${LOCAL_UBLUE_DIR}/${STAMP}" ]] && [[ -d "${FCITX_CONFIG_DIR}" ]]; then

    if [[ -d "${FCITX_CONFIG_DIR}" ]]; then
      mkdir -p "${FCITX_CONFIG_DIR_FLATPAK}"
      cp -r "${FCITX_CONFIG_DIR}" "${FCITX_CONFIG_DIR_FLATPAK}"
    fi

    if [[ -d "${FCITX_DATA_DIR}" ]] && [[ -n "$(ls -A "${FCITX_DATA_DIR}" 2>/dev/null)" ]]; then
      mkdir -p "${FCITX_DATA_DIR_FLATPAK}"
      cp -r "${FCITX_DATA_DIR}" "${FCITX_DATA_DIR_FLATPAK}"
    fi

    TITLE="Fcitx has been removed from the system"
    MESSAGE="Please reinstall Fcitx from Bazaar so you can install all the necessary add-ons for your languages and make sure it is enabled in the Virtual Keyboard Settings."

    ACTION=$(notify-send \
      --app-name=Aurora \
      --icon=input-keyboard-virtual \
      --urgency=critical \
      "${TITLE}" \
      "${MESSAGE}" \
      --action="open=Install Fcitx" \
      --action="info=More Info/Help"
    )

    if [[ "$ACTION" = "open" ]]; then
      xdg-open appstream://${ID}
    elif [[ "$ACTION" = "info" ]]; then
      xdg-open "https://github.com/ublue-os/aurora/issues/3038"
    fi
    touch "${LOCAL_UBLUE_DIR}/${STAMP}"
  fi
}

migrate_fcitx

# More consistent Qt/GTK themes for Flatpaks
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
