# dotfiles

Nix flake-based configuration repo for:
- NixOS hosts
- standalone Home Manager (e.g. Ubuntu)

## Managed Hosts

| Host | Description |
|------|-------------|
| `x1` | ThinkPad X1 Carbon |
| `t480` | ThinkPad T480 |

## Quick Start

```bash
git clone https://github.com/henrirosten/dotfiles.git
cd dotfiles
```

## Common Commands

Enter development shell:
```bash
nix develop
```

Format and lint:
```bash
nix fmt
```

Run flake checks (eval/build checks):
```bash
nix flake check --option allow-import-from-derivation false
```

## NixOS Usage

Build host config:
```bash
nixos-rebuild build --flake .#x1
nixos-rebuild build --flake .#t480
```

Apply host config:
```bash
sudo nixos-rebuild switch --flake .#x1
sudo nixos-rebuild switch --flake .#t480
```

## VM Host Testing

Run host config in a headless VM (autologin as `root`):
```bash
nix run .#x1-vm
nix run .#t480-vm
```

Keep VM disk image:
```bash
nix run .#x1-vm -- --keep-disk
```

Override VM resources and disk:
```bash
nix run .#x1-vm -- --ram-mb 2048 --cpus 2 --disk-size 16G --disk-image ./x1.qcow2 --keep-disk
```

## Standalone Home Manager (Ubuntu)

Install Nix either from <https://nixos.org/download> or with:
```bash
./bootstrap-nix.sh
```

Then apply home-manager profile:
```bash
nix develop
home-manager switch --flake .#hrosten
```

## CI and Automation

- `.github/workflows/check.yml`
  - runs formatting/lint checks and host builds on pushes to `main`
- `.github/workflows/flake-update.yml`
  - scheduled flake input update at `04:00 UTC` (about `06:00 EET`)
  - can also be triggered manually via `workflow_dispatch`
  - validates `.#checks.x86_64-linux.x1-vm-codex-smoke` before PR creation

## Repository Layout

```text
flake.nix                    # Flake entrypoint
flake/                       # Split flake output builders
  apps-vm.nix
  checks.nix
  dev-shells.nix
  formatter.nix
  home-configurations.nix
  nixos-configurations.nix
  pre-commit-check.nix
hosts/                       # Per-host NixOS configs
modules/
  nixos/                     # Reusable NixOS modules
  home/                      # Reusable Home Manager modules
users/                       # User-specific modules and HM composition
scripts/
  run-vm.sh                  # VM runner template used by flake VM apps
bootstrap-nix.sh             # Nix bootstrap helper script
```
