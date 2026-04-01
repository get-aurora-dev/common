# Aurora-Common Copilot Instructions

This document provides essential information for coding agents working with the aurora-common repository.

## Repository Overview

**Aurora-Common** is a shared OCI layer containing configuration files for Aurora and Aurora-DX variants.

- **Type**: OCI container layer built on top of projectbluefin/common
- **Purpose**: Provide Aurora-specific configuration and assets while inheriting shared Bluefin configuration
- **Base**: Multi-stage build pulling from aurora-wallpapers, projectbluefin/common, and local files
- **Languages**: Configuration files (JSON, shell scripts, markdown)
- **Build System**: GitHub Actions with podman/buildah, Just for local convenience

## Repository Structure

### Root Directory Files
- `Containerfile` - Multi-stage build pulling wallpapers, projectbluefin/common, and local files
- `Justfile` - Convenience commands for building and inspecting the image
- `cosign.pub` - Container signing public key
- `image-versions.yml` - Version tracking for dependencies
- `README.md` - Repository documentation
- `.pre-commit-config.yaml` - Pre-commit hooks configuration

### Key Directories
- `system_files/` - Configuration files organized by variant
  - `shared/` - Configuration shared between Aurora and Aurora-DX
    - `etc/` - System-level configuration (bazaar, dconf, geoclue, profile.d, skel, systemd, ublue-os, zsh)
    - `usr/` - User-space configuration (bin, lib, libexec, share)
  - `dx/` - Aurora-DX specific configuration
    - `etc/` - DX system-level configuration
    - `usr/` - DX user-space configuration
- `flatpaks/` - Flatpak definitions for Aurora images
- `logos/` - Aurora branding and logo assets

### GitHub Actions
- `.github/workflows/build.yml` - Build workflow using podman/buildah

## Build Instructions

### Prerequisites
- **podman** and **buildah** for building containers
- **just** for convenience commands (optional)
- **pre-commit** for development hooks (optional)

### Build Commands

**Build locally:**
```bash
# Using Just
just build

# Or directly with podman
podman build -t localhost/aurora-common:latest -f ./Containerfile .
```

**Inspect the image:**
```bash
# View directory structure
just tree

# Dump all contents to ./dump directory
just dump
```

**Validate Just syntax:**
```bash
# Check syntax
just check

# Fix formatting
just fix
```

### Build Process
1. Builder stage pulls aurora-wallpapers and processes them
2. Scratch stage pulls projectbluefin/common shared files
3. Local files (flatpaks, logos, system_files) are added
4. Final image is pushed to `ghcr.io/ublue-os/aurora-common:latest`
5. Aurora and Aurora-DX images reference this layer in their builds

## Usage in Downstream Projects

Aurora images use this layer in their Containerfiles:

```dockerfile
FROM ghcr.io/ublue-os/aurora-common:latest AS aurora-common

# Copy shared configuration
COPY --from=aurora-common /system_files/shared /

# Aurora-DX also copies DX-specific configuration
COPY --from=aurora-common /system_files/dx /

# Copy wallpapers and other assets
COPY --from=aurora-common /wallpapers /
COPY --from=aurora-common /flatpaks /tmp/flatpaks
COPY --from=aurora-common /logos /tmp/logos
```

## Making Changes

### Modifying Configuration Files

1. **Edit files in `system_files/`** - Maintain the existing directory structure
2. **Test locally** with `just build` to ensure no syntax errors
3. **Create PR** - GitHub Actions will build and validate

### Adding New Configuration Files

1. Determine if the configuration is shared or DX-specific
2. Place files in the appropriate subdirectory:
   - Shared configs: `system_files/shared/`
   - DX-specific: `system_files/dx/`
3. Follow the existing path structure (etc/ or usr/)
4. Ensure file permissions are correct (executables for scripts)

### Common Modification Patterns
- **Shared system configs**: Edit files in `system_files/shared/etc/`
- **Shared user configs**: Edit files in `system_files/shared/usr/`
- **DX-specific configs**: Edit files in `system_files/dx/`
- **Flatpak definitions**: Modify `flatpaks/` directory
- **Branding assets**: Update `logos/` directory

## Validation

### Manual Validation
```bash
# Build locally to check for errors
just build

# Check Just syntax
just check

# Validate JSON files
find system_files -name "*.json" -exec sh -c 'echo "Checking {}"; cat {} | jq . > /dev/null' \;

# Check shell script syntax
find system_files -name "*.sh" -exec bash -n {} \;

# Inspect built image
just tree
```

### GitHub Actions
The build workflow automatically:
- Builds the container with podman/buildah
- Pushes to GHCR on merge to main
- Validates build succeeds on PRs

## Development Guidelines

### Making Changes
1. **Understand shared vs DX** - Place configs in the correct system_files subdirectory
2. **Maintain structure** - Follow existing directory patterns
3. **Test locally** - Build with `just build` before pushing
4. **Use pre-commit hooks** - Run before committing if configured

### File Editing Best Practices
- **JSON files**: Validate syntax with `jq` before committing
- **Shell scripts**: Check syntax with `bash -n script.sh`
- **Just files**: Use `just check` and `just fix` for syntax validation
- **Keep files small** - Each file should have a single, clear purpose
- **Document changes** - Update comments in configuration files

## Trust These Instructions

**This repository structure:**
- Configuration files in `system_files/shared/` and `system_files/dx/`
- Flatpak definitions in `flatpaks/`
- Branding assets in `logos/`
- Multi-stage Containerfile pulling from aurora-wallpapers and projectbluefin/common
- Justfile with convenience commands
- GitHub Actions workflow for automated builds

## Other Rules

- Use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) for all commits and PR titles
- Keep changes minimal and surgical
- This layer is used by Aurora and Aurora-DX
- Changes to `system_files/shared/` affect both variants
- Changes to `system_files/dx/` only affect Aurora-DX

## Attribution Requirements

AI agents must disclose what tool and model they are using in the "Assisted-by" commit footer:

```text
Assisted-by: [Model Name] via [Tool Name]
```

Example:

```text
Assisted-by: Claude 3.5 Sonnet via GitHub Copilot
```
