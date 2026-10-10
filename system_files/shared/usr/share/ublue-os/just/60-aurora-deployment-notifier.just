# Toggle Aurora staged deployment desktop notifications.
[group('Aurora')]
aurora-update-notifier ACTION="prompt":
    #!/usr/bin/env bash
    set -euo pipefail

    action="{{ ACTION }}"
    user_path="aurora-deployment-notifier.path"

    current="disabled"
    if [[ "$(systemctl --user is-enabled "${user_path}" 2>/dev/null || true)" == "enabled" ]]; then
        current="enabled"
    fi
    echo "Aurora update notifications are currently ${current}."

    if [[ "${action}" == "prompt" ]]; then
        action="$(gum choose --header="Toggle Aurora update notifications?" "Enable" "Disable" "Status" "Cancel")"
        if [[ "${action}" == "Cancel" || -z "${action}" ]]; then
            exit 0
        fi
    fi

    case "${action}" in
      [Ee]nable|on)
        systemctl --user enable --now "${user_path}"
        echo "Aurora update notifications enabled."
        echo "You will be notified when a staged update is ready, until you reboot into it."
        ;;
      [Dd]isable|off)
        systemctl --user disable --now "${user_path}" || true
        rm -f "${XDG_STATE_HOME:-${HOME}/.local/state}/aurora/deployment-notifier/last-notified"
        echo "Aurora update notifications disabled."
        ;;
      [Ss]tatus)
        systemctl --user --no-pager status "${user_path}" || true
        if [[ -f /run/aurora/deployment-status.json ]] && command -v jq >/dev/null 2>&1; then
            jq -r '"Staged deployment ready: \(.staged_id) (via \(.source))"' /run/aurora/deployment-status.json
        else
            echo "No staged deployment pending."
        fi
        ;;
      *)
        echo "Usage: ujust aurora-update-notifier [enable|disable|status]"
        exit 2
        ;;
    esac
