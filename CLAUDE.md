# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake-based configuration repository for:
- NixOS hosts (`x1`, `t480`, and a VM-focused `generic` profile)
- Standalone home-manager configuration (`.#hrosten`) for non-NixOS systems

## Commands

**Enter development shell** (flake):
```bash
nix develop
```

**Enter alternative shell** (includes `home-manager` from `shell.nix`):
```bash
nix-shell
```

**Format and lint all files**:
```bash
nix fmt
```

**Run flake checks**:
```bash
nix flake check --option allow-import-from-derivation false
```

**Run flake checks without builds**:
```bash
nix flake check --option allow-import-from-derivation false --no-build
```

**Build NixOS configuration**:
```bash
nixos-rebuild build --flake .#x1
nixos-rebuild build --flake .#t480
```

**Apply NixOS configuration**:
```bash
sudo nixos-rebuild switch --flake .#x1
sudo nixos-rebuild switch --flake .#t480
```

**Apply standalone home-manager configuration** (for non-NixOS like Ubuntu):
```bash
home-manager switch --flake .#hrosten
```

**Run VM apps**:
```bash
nix run .#x1-vm
nix run .#t480-vm
nix run .#generic-vm
```

## Architecture

- `flake.nix` - Main entry point defining inputs, outputs, NixOS configurations, and home-manager configurations
- `hosts/` - Per-machine configurations (`x1`, `t480`, `generic`), each with `configuration.nix` and `hardware-configuration.nix`
- `users/` - User-specific NixOS modules defining user accounts (name, username, email, ssh keys, shell, groups)
- `modules/nixos/` - Reusable NixOS modules (`common-nix`, `gui`, `host-common`, `laptop`, `ssh`, `remotebuild`)
- `modules/home/` - Reusable home-manager modules (`bash`, `zsh`, `git`, `vim`, `starship`, `ssh-conf`, `gui-extras`, `vscode`, `shell-common`, `codex-cli`)
- `users/hrosten/home.nix` - User profile composition for hrosten home-manager setup

NixOS modules are exported via `outputs.nixosModules`. Home-manager modules are exported via `outputs.homeModules`.

## Linting/Formatting

The flake uses git-hooks-nix for pre-commit checks including:
- `nixfmt` - Nix formatter
- `deadnix` - Removes dead Nix code
- `statix` - Nix linter (runs with `fix` argument)
- `shellcheck` - Bash linter
- `shfmt` - Bash formatter (2-space indent)
- `typos` - Spell checker
- `gitlint` - Commit message linter
