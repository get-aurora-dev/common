# aurora-common

Shared OCI layer containing configuration files for Aurora and Aurora-DX variants.

## Repository Structure

This layer builds on top of `ghcr.io/projectbluefin/common` and includes:

- `system_files/shared/` - Configuration shared between Aurora and Aurora-DX
- `system_files/dx/` - Aurora-DX specific configuration
- `wallpapers/` - Aurora wallpapers from [artwork repo](https://github.com/ublue-os/artwork)
- `flatpaks/` - Flatpak definitions used for including flatpaks for the ISOs and `ujust install-system-flatpaks`
- `logos/` - Aurora branding assets

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
COPY --from=aurora-common /flatpaks /tmp/flatpaks
COPY --from=aurora-common /logos /tmp/logos
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
