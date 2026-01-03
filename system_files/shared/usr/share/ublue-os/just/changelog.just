alias changelog := changelogs

# Show the changelog

changelogs:
    #!/usr/bin/bash
    CONTENT=$(curl -s https://api.github.com/repos/ublue-os/aurora/releases/latest | jq -r '.body')
      echo "$CONTENT" | glow -

changelogs-fedora:
    rpm-ostree db diff --changelogs
