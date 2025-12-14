set allow-duplicate-recipes := true
set ignore-comments := true

_default:
    #!/usr/bin/bash
    source /usr/lib/ujust/libformatting.sh
    echo "$(Urllink "https://docs.getaurora.dev/guides/basic-usage/#using-ujust-in-aurora" "Click here to view the Aurora ujust documentation")"
    /usr/bin/ujust --list --list-heading $'Available commands:\n' --list-prefix $' - '

# Imports
# shared with bluefin
import "/usr/share/ublue-os/just/default.just"

import "/usr/share/ublue-os/just/update.just"
import "/usr/share/ublue-os/just/apps.just"
import "/usr/share/ublue-os/just/system.just"
import? "/usr/share/ublue-os/just/60-custom.just"
