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

    if systemd-detect-virt --container -q; then
      echo "Running inside a container environment, nothing to upgrade"
      exit 1
    elif grep -q -E "(^|\s)composefs=.*\S" /proc/cmdline; then
      IS_COMPOSEFS="true"
      IS_OSTREE="false"
    elif grep -q -E "(^|\s)ostree=.*\S" /proc/cmdline; then
      IS_COMPOSEFS="false"
      IS_OSTREE="true"
    else
      echo "Not booted, nothing to upgrade."
      exit 1
    fi

    if [[ "${IS_COMPOSEFS}" == "true" ]]; then
        sudo bootc upgrade

    elif [[ "${IS_OSTREE}" == "true" ]]; then
      # Without password would be nice
      # https://github.com/bootc-dev/bootc/issues/409
      # https://github.com/get-aurora-dev/common/issues/270
      # bootc status can might prefix the output from `mount`
      STATUS=$(sudo bootc status --json 2> /dev/null | jq ".status")

      STAGED_INCOMPAT=$(echo "${STATUS}" | jq ".staged.incompatible")
      BOOTED_INCOMPAT=$(echo "${STATUS}" | jq ".booted.incompatible")

      if [[ "${STAGED_INCOMPAT}" == "true" || ( "${BOOTED_INCOMPAT}" == "true" && -z "${STAGED_INCOMPAT}" ) || "${BOOTED_INCOMPAT}" == "true" ]]; then
          INCOMPAT="true"
      else
          INCOMPAT="false"
      fi

        if [[ "${INCOMPAT}" == "true" ]]; then
            rpm-ostree upgrade
        else
            sudo bootc upgrade
        fi
    fi

    # Updates system Flatpaks
    if flatpak remotes | grep -q system; then
        flatpak update -y
    fi
    # Update user Flatpaks
    if flatpak remotes | grep -q user; then
        flatpak update --user -y
    fi
    # Guard Brew if the user does not own brew/doesn't exist
    if [[ -O /var/home/linuxbrew/.linuxbrew/bin/brew ]]; then
        # Upgrade will run brew update if needed
        /var/home/linuxbrew/.linuxbrew/bin/brew upgrade -y
    fi

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
