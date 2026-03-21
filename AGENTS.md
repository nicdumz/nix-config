# Agent Best Practices

This document outlines best practices for AI agents working on this NixOS/home-manager flake
configuration.

## Version Control

### Use Jujutsu (jj) for Commits

This repository uses [Jujutsu](https://github.com/jc-vcs/jj) (jj) instead of git for version
control.

**Create commits with conventional commit messages:**

```sh
jj commit -m "feat: add new feature"
jj commit -m "fix: resolve bug in module"
jj commit -m "docs: update README"
jj commit -m "refactor: simplify configuration"
jj commit -m "chore: update dependencies"
```

Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools and libraries

### Breaking Changes

For breaking changes, add `!` after the type or add `BREAKING CHANGE:` in the commit body:

```sh
jj commit -m "feat!: change module interface"
jj commit -m "feat: change API

BREAKING CHANGE: the old API is no longer supported"
```

## Pre-Commit Checks

### Required Commands Before Committing

Always run these commands before creating a commit:

```sh
# Format all code (runs nixfmt, deadnix, statix, fish_indent, mdformat, yamlfmt)
nix fmt
```

## Building and Validating Configurations

### Comprehensive Syntax Validation

```sh
# Check all flake outputs (builds, checks, and validates)
nix flake check

# Run pre-commit hooks check
nix build .#checks.x86_64-linux.git-hooks
```

### Build Specific NixOS Configurations

```sh
# Build all hosts (using colmena) -- this takes quite a while.
colmena build

# Build a specific host configuration (is faster)
nix build .#nixosConfigurations.bistannix.config.system.build.toplevel
nix build .#nixosConfigurations.qemu.config.system.build.toplevel
nix build .#nixosConfigurations.jonsnow.config.system.build.toplevel
```

Consider that building single configurations is faster than building all hosts, and should be
preferred for fast iteration.

### Available NixOS Configurations

Based on [flake.nix](flake.nix), the following configurations are available:

- **bistannix**: Main host (allows local deployment)
- **jonsnow**: Remote host
- **lethargyfamily**: Remote host
- **liveusb**: Live USB configuration
- **nixosvm**: VM configuration
- **qemu**: QEMU test VM

### Build Home-Manager Configurations

```sh
# List available home configurations
nix flake show | grep homeConfigurations

# Build a specific home-manager configuration
nix build .#homeConfigurations.<username>.activationPackage
```

### Deployment

```sh
# Build all hosts
colmena build

# Deploy to local host
colmena apply-local --sudo test

# Deploy to specific host
colmena apply --on jonsnow
```

### Quick Validation Workflow

A recommended validation workflow before committing:

```sh
# 1. Format code
nix fmt

# 2. Run comprehensive checks
nix flake check

# 3. Build all configurations (optional but recommended)
colmena build

# 4. Create commit with conventional commit message
jj commit -m "feat: add new feature"
```

### Troubleshooting Builds

```sh
# Build with verbose output
nix build .#nixosConfigurations.bistannix.config.system.build.toplevel --show-trace

# Check specific package evaluation
# Note that you can 
nix eval .#nixosConfigurations.bistannix.config.system.build.toplevel --show-trace
```

## Development Environment

This repository uses `direnv` for automatic environment setup. When you `cd` into the repository,
the development environment is automatically activated with all necessary tools.

## CI/CD Integration

Pull requests are automatically validated by [Garnix](https://garnix.io/), which:

- Builds all host configurations
- Runs all checks
- Validates the flake structure

Agents should ensure all changes pass local validation before suggesting commits, as the same checks
will run in CI.

## Module Structure

This flake uses [snowfall-lib](https://snowfall.org/guides/lib/quickstart/) for organization.
Familiarize yourself with the structure:

```
nix/
├── modules/       # NixOS and home-manager modules
├── systems/       # Host-specific configurations
├── packages/      # Custom packages
└── overlays/      # Package overlays
```

## Best Practices Summary

1. ✅ Use `jj commit` with conventional commit messages
1. ✅ Run `nix fmt` before every commit
1. ✅ Run `nix flake check` to validate configurations
1. ✅ Test builds with `colmena build` or specific config builds
1. ✅ Follow snowfall-lib structure conventions
1. ✅ Ensure changes pass locally before committing (CI will run the same checks)
