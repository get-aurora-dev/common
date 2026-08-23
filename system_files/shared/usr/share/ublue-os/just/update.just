# vim: set ft=make :

alias upgrade := update

# Update system, flatpaks and homebrew packages all at once
update:
    #!/usr/bin/env bash

    set -eou pipefail

    if systemctl cat -- uupd.timer &> /dev/null; then
        SERVICE="uupd.service"
    else
        SERVICE="rpm-ostreed-automatic.service"
    fi
    if systemctl is-active --quiet "$SERVICE"; then
        echo "automatic updates are currently running, use \`journalctl -fexu $SERVICE\` to see logs"
        exit 1
    fi

    # Yes, this runs as the regular, uupd ships a polkit rule
    systemctl start --verbose uupd-manual.service

alias auto-update := toggle-updates

# Turn automatic updates on or off
toggle-updates ACTION="prompt":
    #!/usr/bin/bash
    CURRENT_STATE="disabled"
    if systemctl is-enabled -q rpm-ostreed-automatic.timer; then
        CURRENT_STATE="enabled"
    elif systemctl is-enabled -q uupd.timer; then
        CURRENT_STATE="enabled"
    fi

    echo "Automatic updates are currently ${CURRENT_STATE}"
    SELECTED_OPTION="$(gum choose --header="Toggle automatic updates?" "Enable" "Disable" "Cancel")"
    [[ "${SELECTED_OPTION}" == "Cancel" || "${SELECTED_OPTION}" == "" ]] && exit 0

    if systemctl cat -- uupd.timer &> /dev/null; then
        TIMER="uupd.timer"
    else
        TIMER="rpm-ostreed-automatic.timer"
    fi
    if [ "${SELECTED_OPTION}" == "Enable" ] ; then
        sudo systemctl enable "$TIMER"
        echo "Updates have been enabled"
    elif [ "${SELECTED_OPTION}" == "Disable" ] ; then
        sudo systemctl disable "$TIMER"
        echo "Updates have been disabled"
    fi
