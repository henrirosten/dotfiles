# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake-based dotfiles repository for NixOS and standalone home-manager configurations. It manages system and user configurations for multiple hosts (x1, t480) and supports Ubuntu via home-manager.

## Commands

**Enter development shell** (enables pre-commit hooks):
```bash
nix-shell
```

**Format and lint all files**:
```bash
nix fmt
```

**Run flake checks** (pre-commit hooks):
```bash
nix flake check
```

**Build NixOS configuration** (replace `hostname` with x1 or t480):
```bash
nixos-rebuild build --flake .#hostname
```

**Apply NixOS configuration**:
```bash
sudo nixos-rebuild switch --flake .#hostname
```

**Apply standalone home-manager configuration** (for non-NixOS like Ubuntu):
```bash
home-manager switch --flake .#hrosten
```

## Architecture

- `flake.nix` - Main entry point defining inputs, outputs, NixOS configurations, and home-manager configurations
- `hosts/` - Per-machine configurations (x1, t480), each with `configuration.nix`, `hardware-configuration.nix`, and `home.nix`
- `users/` - User-specific data (name, username, email, ssh keys)
- `modules/nixos/` - Reusable NixOS modules (common-nix, gui, laptop, ssh-access, remotebuild, host-common)
- `modules/home/` - Reusable home-manager modules (bash, zsh, git, vim, starship, ssh-conf, extras, vscode, shell-common)

Modules are exported via `outputs.nixosModules` and `outputs.homeModules`, then imported in host configurations.

## Linting/Formatting

The flake uses git-hooks-nix for pre-commit checks including:
- `nixfmt` - Nix formatter
- `deadnix` - Removes dead Nix code
- `statix` - Nix linter (runs with `fix` argument)
- `shellcheck` - Bash linter
- `shfmt` - Bash formatter (2-space indent)
- `typos` - Spell checker
- `gitlint` - Commit message linter
