# vim: set ft=make :
########################
### aurora-system.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Run a one minute system benchmark
[group('System')]
benchmark:
    #!/usr/bin/env bash
    if ! type -P "stress-ng" &>/dev/null ; then
        if gum confirm "Stress does not seem to be on your path, do you wish to install it?" ; then
            set -eu
            brew install stress-ng
            brew link stress-ng
            set +eu
        else
            exit 0
        fi
    fi

    echo 'Running a 1 minute benchmark ...'
    trap popd EXIT
    pushd $(mktemp -d)
    stress-ng --matrix 0 -t 1m --times

# Configure Aurora-CLI Terminal Experience with Brew
[group('System')]
aurora-cli:
    @ublue-bling
    brew bundle --file=/usr/share/ublue-os/homebrew/cli.Brewfile

# alias for install-fonts
aurora-fonts:
    @ujust install-fonts

# Install fonts from brew
[group('System')]
install-fonts:
    #!/usr/bin/bash
    echo "Installing extra fonts..."
    brew bundle --file /usr/share/ublue-os/homebrew/fonts.Brewfile

# alias for toggle-devmode
devmode:
    @ujust toggle-devmode

# Toggle between Aurora and the Developer Experience
[group('System')]
toggle-devmode:
    #!/usr/bin/env bash
    set -e
    IMAGE_INFO_FILE="${IMAGE_INFO_FILE:-/usr/share/ublue-os/image-info.json}"
    IMAGE_NAME="$(jq -rc '."image-name"' "${IMAGE_INFO_FILE}")"
    IMAGE_REF="$(jq -rc '."image-ref"' "${IMAGE_INFO_FILE}" | sed "s/.*ghcr/ghcr/")"
    CURRENT_IMAGE="${IMAGE_REF}:$(jq -rc '."image-tag"' "${IMAGE_INFO_FILE}")"
    IMAGE_BASE_NAME="$(cut -f1 -d\- <<< "${IMAGE_NAME}")"
    set +e

    if grep -q -- "-dx" <<< "${IMAGE_NAME}"; then
        gum confirm "Would you like to disable developer mode?" || exit 0
        echo "Rebasing to a non developer image"
        NEW_IMAGE="$(sed "s/\-dx//" <<< $CURRENT_IMAGE)"
        pkexec bootc switch --enforce-container-sigpolicy "${NEW_IMAGE}"
        exit 0
    fi

    gum confirm "Would you like to enable developer mode?" || exit 0
    echo "Rebasing to a developer image"
    NEW_IMAGE="$(sed "s/${IMAGE_BASE_NAME}/${IMAGE_BASE_NAME}-dx/" <<< "${CURRENT_IMAGE}")"
    pkexec bootc switch --enforce-container-sigpolicy "${NEW_IMAGE}"
    if gum confirm "Do you want to also install the default development flatpaks?" ; then
        ADD_DEVMODE=1 ujust install-system-flatpaks 0 1
    fi
    if gum confirm "Do you want to install extra monospace fonts?" ; then
        brew bundle install --file=/usr/share/ublue-os/homebrew/fonts.Brewfile
    fi
    echo "Use ujust dx-group to add your user to the correct groups and complete the installation after rebooting into the development image"

# Ptyxis terminal transparency
[group('System')]
ptyxis-transparency opacity="0.95":
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ -n "$(echo "{{ opacity }}" | grep -v '^[.0-9]*$')" ]]; then
        printf "Value must be numeric: %s.\n" "{{ opacity }}"
    elif [[ $(echo "0<{{ opacity }} && 1>={{ opacity }}" | bc -q) -eq 1 ]]; then
        raw="$(gsettings get org.gnome.Ptyxis profile-uuids)"
        uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
        for i in ${uuids}; do
            location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
            gsettings set "${location}" opacity "{{ opacity }}"; done
        printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
        printf "Value must be greater than 0 and less than or equal to 1: %s.\n" "{{ opacity }}"
    fi

# Configure docker,incus-admin,libvirt, container manager, serial permissions
[group('System')]
dx-group:
    #!/usr/bin/pkexec bash
    append_group() {
        local group_name="$1"
        if ! grep -q "^$group_name:" /etc/group; then
            echo "Appending $group_name to /etc/group"
            grep "^$group_name:" /usr/lib/group | sudo tee -a /etc/group > /dev/null
        fi
    }

    GROUPS_ADD=("docker" "incus-admin" "libvirt" "dialout")

    for GROUP_ADD in "${GROUPS_ADD[@]}" ; do
        append_group $GROUP_ADD
        usermod -aG $GROUP_ADD $USER
    done

    echo "Reboot system and log back in to use docker, libvirt, incus, and serial connections."

# Install system flatpaks for rebasers
[group('System')]
install-system-flatpaks $confirm="1" $dx_only="0":
    #!/usr/bin/env bash
    if [[ "$(jq '."image-flavor"' /usr/share/ublue-os/image-info.json)" =~ dx ]] ; then
        ADD_DEVMODE="${ADD_DEVMODE:-1}"
    fi
    if [ "${ADD_DEVMODE:-0}" == "1" ] ; then
        if [ "$confirm" != 0 ] ; then
            gum confirm "Install development flatpaks?" || exit 0
        fi
        brew bundle --file="${TARGET_FLATPAK_FILE:-/usr/share/ublue-os/homebrew/system-dx-flatpaks.Brewfile}"
    fi
    [ "$dx_only" == 1 ] && exit 0
    if [ "$confirm" != 0 ] ; then
        gum confirm "Install system flatpaks?" || exit 0
    fi
    brew bundle --file="${TARGET_FLATPAK_FILE:-/usr/share/ublue-os/homebrew/system-flatpaks.Brewfile}"

alias switch-stream := rebase-helper
alias switch-streams := rebase-helper
alias rollback-helper := rebase-helper

# Rebase assistant
[group('System')]
rebase-helper:
    @/usr/bin/ublue-rollback-helper

# Toggle tailscale
[group('System')]
toggle-tailscale:
    #!/bin/bash
    set -euo pipefail
    source /usr/lib/os-release

    TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"

    if [ "$TAILSCALED_STATUS" == "enabled" ] || [ "$TAILSCALED_STATUS" == "disabled" ]; then
        TAILSCALED="Installed"
    else
        TAILSCALED="Not Found"
        echo "Unable to enable or disable Tailscale."
        echo "The tailscaled service must be present and either enabled or disabled to run this script."
        echo "tailscaled service status: $TAILSCALED_STATUS"
    fi


    if [ "$TAILSCALED" == "Installed" ]; then
        echo "Enable or disable Tailscale?"
        TS_OPTION=$(gum choose "Enable" "Disable")

        if [ "$TS_OPTION" = "Enable" ]; then
            systemctl enable --now tailscaled
            TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
            if [ "$TAILSCALED_STATUS" == "enabled" ]; then
                echo "Tailscale is enabled."
                echo "If this is your first time using Tailscale, setup is necessary."
                echo "Refer to Tailscale's documentation at https://tailscale.com/kb/1346/start."
            fi
        elif [ "$TS_OPTION" = "Disable" ]; then
            systemctl disable --now tailscaled
            TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
            if [ "$TAILSCALED_STATUS" == "disabled" ]; then
                echo "Tailscale is disabled."
            fi
        fi
    fi

# Automatically download Bluefin's monthly dinosaur wallpapers
[group('System')]
toggle-dinosaurs hemisphere="north":
    #!/bin/bash
    if [[ "{{ hemisphere }}" != "north" && "{{ hemisphere }}" != "south" ]]; then
        echo "Error: Invalid hemisphere '{{ hemisphere }}'. Must be 'north' or 'south'."
        exit 1
    fi

    DINOSAUR_STATUS="$(systemctl --user is-enabled bluefin-wallpaper@{{ hemisphere }}.service 2>/dev/null || echo 'disabled')"

    echo "Bluefin dinosaur wallpapers ({{ hemisphere }}ern hemisphere) are currently: $DINOSAUR_STATUS"

    if [ "$DINOSAUR_STATUS" == "enabled" ]; then
        echo "Disable Bluefin dinosaur wallpapers?"
        OPTION=$(gum choose "Disable" "Cancel")
        if [ "$OPTION" = "Disable" ]; then
            systemctl --user disable --now bluefin-wallpaper@{{ hemisphere }}.service

            # set the default wallpaper again when disabling
            qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                var allDesktops = desktops();
                for (var i = 0; i < allDesktops.length; i++) {
                    var d = allDesktops[i];
                    d.wallpaperPlugin = \"org.kde.image\";
                    d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");
                    d.writeConfig(\"Image\", \"file:///usr/share/backgrounds/default.jxl\");
                }
              "
            echo "Bluefin dinosaur wallpapers ({{ hemisphere }}ern hemisphere) disabled."
            echo "Disabling Dinosaurs. Deploying Coneheads again."
            echo "Wallpaper files remain in ~/.local/share/wallpapers/Bluefin/"
        fi
    else
        echo "Enable Bluefin dinosaur wallpapers for the {{ hemisphere }}ern hemisphere?"
        OPTION=$(gum choose "Enable" "Cancel")
        if [ "$OPTION" = "Enable" ]; then
            mkdir -p ~/.local/share/wallpapers/Bluefin
            systemctl --user enable --now bluefin-wallpaper@{{ hemisphere }}.service

            sleep 1
            if systemctl --user is-active --quiet bluefin-wallpaper@{{ hemisphere }}.service; then
                echo "Bluefin dinosaur wallpapers ({{ hemisphere }}ern hemisphere) enabled!"
                echo "Wallpapers will be downloaded to ~/.local/share/wallpapers/Bluefin/"
                echo "The wallpaper will update automatically each month."
                filename="$HOME/.local/share/wallpapers/Bluefin/{{ hemisphere }}.avif"

                qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                    var allDesktops = desktops();
                    for (var i = 0; i < allDesktops.length; i++) {
                        var d = allDesktops[i];
                        d.wallpaperPlugin = \"com.github.zzag.dynamic\";
                        d.currentConfigGroup = Array(\"Wallpaper\", \"com.github.zzag.dynamic\", \"General\");
                        d.writeConfig(\"Image\", \"file:///${filename}\");
                    }
                "
            else
                echo "Failed to start bluefin-wallpaper service."
                echo "Check the service status with:"
                echo "  systemctl --user status bluefin-wallpaper@{{ hemisphere }}.service"
            fi
        fi
    fi

# Configure Boot to Windows desktop entry
[group('System')]
configure-boot-to-windows:
    mkdir -p $HOME/.local/share/applications
    cp -r /usr/share/applications/boot-to-windows.desktop $HOME/.local/share/applications
    sed -i 's/Hidden=true/Hidden=false/' $HOME/.local/share/applications/dev.getaurora.boot-to-windows.desktop

# Toggle IWD
[group('System')]
toggle-iwd:
    #!/usr/bin/bash
    echo -e "This script manages enabling or disabling iwd as a replacement for wpa_supplicant for Wi-Fi networking."
    echo -e "Enabling this can improve throughput, mesh networking, and reduce latency increases when scanning for networks"
    echo -e "Disabling this can improve corporate or eduroam network compatibility"
    echo -e ""
    echo -e "WARNING: Changing this will remove all saved wifi networks"
    get_current_status() {
      if [[ -f "/etc/NetworkManager/conf.d/iwd.conf" ]]; then
        echo "Enabled"
      else
        echo "Disabled"
      fi
    }
    remove_saved_networks() {
      nmcli -t -f NAME connection show | while read -r line; do sudo nmcli connection delete "$line"; done
    }
    enable_iwd() {
      sudo mkdir -p "/etc/NetworkManager/conf.d/"
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      printf "[device]\nwifi.backend=iwd" | sudo tee /etc/NetworkManager/conf.d/iwd.conf > /dev/null
      remove_saved_networks
      echo -e "iwd enabled. Reboot required to apply changes."
    }
    disable_iwd() {
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      remove_saved_networks
      echo -e "iwd disabled. Reboot required to apply changes."
    }
    # Display current status
    current_status=$(get_current_status)
    echo -e "\nCurrent iwd status: $current_status\n"
    # Prompt user for action
    CHOICE=$(gum choose "Enable iwd" "Disable iwd" "Exit without changes")
    case "$CHOICE" in
      "Enable iwd")
        enable_iwd
        ;;
      "Disable iwd")
        disable_iwd
        ;;
      "Exit without changes")
        echo "No changes made."
        ;;
      *)
        echo "Invalid choice. Exiting without changes."
        ;;
    esac

# Setup and configure Sunshine Game Streaming host
[group('Apps')]
setup-sunshine ACTION="":
    #!/usr/bin/bash
    SERVICE_STATE="$(systemctl is-enabled --user sunshine.service)"
    OPTION={{ ACTION }}
    if [ "$SERVICE_STATE" == "enabled" ]; then
        SERVICE_STATE="Enabled"
    else
        SERVICE_STATE="Disabled"
    fi
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust setup-sunshine <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'enable' to enable the Sunshine service"
      echo "  Use 'disable' to disable the Sunshine service"
      echo "  Use 'portal' to open the Sunshine management portal"
      echo "  Use 'exit' to exit without making changes"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "Service is $SERVICE_STATE"
      OPTION=$(gum choose "Enable" "Disable" "Open Portal" "Exit")
    fi
    if [[ "${OPTION,,}" =~ ^enable ]]; then
      systemctl enable --user --now sunshine.service
    elif [[ "${OPTION,,}" =~ ^(remove|uninstall|disable) ]]; then
      systemctl disable --user --now sunshine.service
    elif [[ "${OPTION,,}" =~ ^(portal|open) ]]; then
      echo "Opening Sunshine management portal..."
      xdg-open https://localhost:47990
    elif [[ "${OPTION,,}" =~ ^exit ]]; then
      echo "Exiting without making changes."
      exit 0
    fi

# Toggle between Bazaar and Discover software stores
[group('Apps')]
_toggle-software-store ACTION="":
    #!/usr/bin/env bash

    discover_apps=(
        "org.kde.discover.desktop"
        "org.kde.discover.flatpak.desktop"
        "org.kde.discover.urlhandler.desktop"
    )

    mkdir -p "$HOME/.local/share/applications"

    discover_active=false
    for app in "${discover_apps[@]}"; do
        if [ -f "$HOME/.local/share/applications/${app}" ]; then
            discover_active=true
            break
        fi
    done

    if [ "$discover_active" = true ]; then
        CURRENT_STATE="discover"
        CURRENT_STATE_PRETTY="Discover"
    else
        CURRENT_STATE="bazaar"
        CURRENT_STATE_PRETTY="Bazaar"
    fi

    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        echo "Usage: ujust toggle-software-store <option>"
        echo "  <option>: Specify the quick option to skip the prompt"
        echo "  Use 'bazaar' to enable Bazaar (hide Discover)"
        echo "  Use 'discover' to enable Discover (hide Bazaar)"
        exit 0
    elif [ "$OPTION" == "" ]; then
        echo "${bold}Software Store Toggle${normal}"
        echo "Currently active: $CURRENT_STATE_PRETTY"
        if [ "$CURRENT_STATE" == "discover" ]; then
            OPTION=$(gum choose "Switch to Bazaar" "Cancel")
        else
            OPTION=$(gum choose "Switch to Discover" "Cancel")
        fi
    fi

    if [[ "${OPTION,,}" =~ ^(switch.*bazaar|bazaar) ]]; then
        echo "$Switching to Bazaar..."
        # Remove Discover files from ~/.local (hides them)
        for app in "${discover_apps[@]}"; do
            if [ -f "$HOME/.local/share/applications/${app}" ]; then
                rm "$HOME/.local/share/applications/${app}"
            fi
        done

        # Remove discover notifier (might still exist from before we removed it from the image)
        if [ -f "$HOME/.config/autostart/org.kde.discover.notifier.desktop" ]; then
            rm "$HOME/.config/autostart/org.kde.discover.notifier.desktop"
        fi

        # Remove Bazaar override if it exists (shows Bazaar)
        if [ -f "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop" ]; then
            rm "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        fi

        # discover could still be running
        pkill -f DiscoverNotifier

        # enable bazaar in krunner
        kwriteconfig6 --file krunnerrc --group Plugins --key krunner_appstreamEnabled false
        kwriteconfig6 --file krunnerrc --group Plugins --key bazaarrunnerEnabled true
        systemctl --user restart plasma-krunner.service plasma-plasmashell.service

        echo "Bazaar is now active"

    elif [[ "${OPTION,,}" =~ ^(switch.*discover|discover) ]]; then
        echo "Switching to Discover..."
        # Copy Discover files from /usr to ~/.local (shows them)
        for app in "${discover_apps[@]}"; do
            if [ -f "/usr/share/applications/${app}.disabled" ]; then
                cp "/usr/share/applications/${app}.disabled" "$HOME/.local/share/applications/${app}"
            fi
        done

        # bazaar is probably still running
        pkill -f bazaar

        # enable discover in krunner
        kwriteconfig6 --file krunnerrc --group Plugins --key krunner_appstreamEnabled true
        kwriteconfig6 --file krunnerrc --group Plugins --key bazaarrunnerEnabled false
        systemctl --user restart plasma-krunner.service plasma-plasmashell.service

        # Hide Bazaar by creating NoDisplay override
        cp /usr/share/applications/io.github.kolunmi.Bazaar.desktop "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        desktop-file-edit --set-key=NoDisplay --set-value=true "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        echo "Discover is now active"

    elif [[ "${OPTION,,}" =~ ^cancel ]]; then
        echo "No changes made."
        exit 0
    fi
