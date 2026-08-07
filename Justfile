just := just_executable()

# Not a buildsystem, only convenience commands

# Build the aurora-common container locally
build:
    git submodule update --init --recursive
    git submodule update --remote
    podman build \
      --rewrite-timestamp \
      --source-date-epoch=$(git log -1 --pretty=%ct) \
      -t localhost/aurora-common:latest -f ./Containerfile .

# Check the syntax of all Justfiles in the repository
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	{{ just }} --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
        {{ just }} --unstable --fmt --check -f Justfile

# Fix the Just formatting
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Fixing syntax: $file"
    	{{ just }} --unstable --fmt -f $file
    done
    echo "Fixing syntax: Justfile"
    {{ just }} --unstable --fmt -f Justfile || { exit 1; }

# Inspect the directory structure of an OCI image
tree IMAGE="localhost/aurora-common:latest":
    echo "FROM alpine:latest" > TreeContainerfile
    echo "RUN apk add --no-cache tree" >> TreeContainerfile
    echo "COPY --from={{ IMAGE }} / /mnt/root" >> TreeContainerfile
    echo "CMD tree /mnt/root" >> TreeContainerfile
    podman build -t tree-temp -f TreeContainerfile .
    podman run --rm tree-temp
    rm TreeContainerfile
    podman rmi tree-temp

dump IMAGE="localhost/aurora-common:latest":
    #!/usr/bin/bash
    set -euo pipefail

    cid=$(podman create {{ IMAGE }})
    echo "Created container $cid from {{ IMAGE }}"
    mkdir -p dump
    podman cp "$cid:/." dump/
    podman rm "$cid"

# Validate Brewfiles
brew-lint dir="system_files/shared/usr/share/ublue-os/homebrew":
    #!/usr/bin/env bash
    set -eou pipefail

    system_files/shared/usr/libexec/ublue-brew-trust-brewfile system_files/shared/usr/share/ublue-os/homebrew/*.Brewfile

    STATUS_FILE=$(mktemp)
    echo "PASS" > "$STATUS_FILE"

    while IFS= read -r -d '' brewfile ; do
      echo "::group:: ===$(basename $brewfile)==="

      grep -E -e "^tap" "$brewfile" > taps.Brewfile || true
      echo "Syncing taps..."
      brew bundle --file=./taps.Brewfile > /dev/null 2>&1 || true

      # Extract combined list for parallel check
      FORMULAS=$(grep -E '^\s*brew\s+["'\'']' "$brewfile" | sed -E 's/^\s*brew\s+["'\'']([^"'\'']+)["'\''].*/formula \1/' || true)
      CASKS=$(grep -E '^\s*cask\s+["'\'']' "$brewfile" | sed -E 's/^\s*cask\s+["'\'']([^"'\'']+)["'\''].*/cask \1/' || true)

      ENTRIES=$(printf "%s\n%s" "$FORMULAS" "$CASKS" | grep -v '^\s*$' || true)

      if [ -n "$ENTRIES" ]; then
        echo "$ENTRIES" | xargs -P 8 -I {} bash -c '
          TYPE=$(echo "{}" | cut -d" " -f1)
          NAME=$(echo "{}" | cut -d" " -f2)
          if ! brew info --$TYPE "$NAME" &> /dev/null; then
            echo "✗ $TYPE \"$NAME\" is invalid or missing tap"
            echo "FAIL" >> "'"$STATUS_FILE"'"
          else
            echo "✓ $TYPE \"$NAME\" is valid"
          fi
        '
      else
        echo "No formulas or casks found."
      fi

      echo "::endgroup::"
    done < <(find "{{ dir }}" -iname '*\.Brewfile*' -print0)

    rm -f taps.Brewfile

    if grep -q "FAIL" "$STATUS_FILE"; then
      echo "Validation complete. Some Brewfiles FAILED."
      exit 1
    else
      echo "Validation complete. All Brewfiles PASSED."
      exit 0
    fi
