# dotfiles

Nix flake-based configurations for NixOS systems and standalone home-manager on Ubuntu.

## Hosts

| Host | Description |
|------|-------------|
| x1   | ThinkPad X1 Carbon |
| t480 | ThinkPad T480 |

## Quick Start

Clone this repository:
```bash
git clone https://github.com/henrirosten/dotfiles.git
cd dotfiles
```

### NixOS

Build and apply configuration:
```bash
nix develop
nixos-rebuild build --flake .#hostname
sudo nixos-rebuild switch --flake .#hostname
```

Replace `hostname` with `x1` or `t480`.

### Ubuntu (standalone home-manager)

Install Nix package manager either via https://nixos.org/download or the bootstrap script:
```bash
./bootstrap-ubuntu.sh
```

Then start a new shell and apply home-manager configuration:
```bash
nix-shell
home-manager switch --flake .#hrosten
```

## Development

Enter dev shell (enables pre-commit hooks):
```bash
nix develop
```

Format and lint all files:
```bash
nix fmt
```

Run flake checks:
```bash
nix flake check
```

## Structure

```
flake.nix           # Main entry point
hosts/              # Per-machine configs
users/              # User account modules
modules/
  nixos/            # NixOS modules
  home/             # home-manager modules
```
