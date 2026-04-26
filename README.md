# aurora-common

Shared OCI layer containing configuration files for Aurora and Aurora-DX variants.

## Repository Structure

This layer builds on top of `ghcr.io/projectbluefin/common` and `https://github.com/get-aurora-dev/branding` which includes:

- `system_files/shared/` - Configuration shared between Aurora and Aurora-DX
- `system_files/dx/` - Aurora-DX specific configuration
- `wallpapers/` - Aurora wallpapers from [artwork repo](https://github.com/ublue-os/artwork)
- `system_files/shared/usr/share/ublue-os/homebrew/` - Flatpak definitions used for including flatpaks for the ISOs and `ujust install-system-flatpaks` - [Yes, homebrew supports the installation of Flatpaks](https://github.com/Homebrew/brew/pull/21097)
- `logos/` - Aurora Logos used in SDDM/Plasma Kickoff etc.

Related work is on the [Fedora KDE-SIG](https://forge.fedoraproject.org/kde)

- [kde-settings](https://forge.fedoraproject.org/kde/kde-settings)

## Usage in Downstream Projects

Aurora images reference this layer in their Containerfiles:

```dockerfile
FROM ghcr.io/get-aurora-dev/aurora-common:latest AS aurora-common

# Copy shared configuration
COPY --from=aurora-common /system_files/shared /

# Copy DX-specific configuration (Aurora-DX only)
COPY --from=aurora-common /system_files/dx /

# Copy wallpapers
COPY --from=aurora-common /wallpapers /

# Copy other assets as needed
COPY --from=aurora-common /logos /tmp/logos
```

## Verify authenticity with cosign

`cosign.pub` has been used in the past to sign artifacts, we are using keyless OIDC signing now.

```
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp="github.com/get-aurora-dev/common/.github/workflows/*" \
  ghcr.io/get-aurora-dev/common:latest
```

## Building Locally

```bash
just build
```

## Additional Commands

```bash
# Check Just syntax
just check

# Fix Just formatting
just fix

# Inspect image structure
just tree

# Dump image contents to ./dump
just dump
```
