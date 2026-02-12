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

#### Testing host configuration in VM

Start a host configuration in a headless test VM (getty autologin as `root`):
```bash
nix run .#x1-vm
nix run .#t480-vm
```

By default the VM disk image is removed on exit. Keep it with:
```bash
nix run .#x1-vm -- --keep-disk
```

You can also choose CPU/RAM/disk size and disk path:
```bash
nix run .#x1-vm -- --ram-mb 2048 --cpus 2 --disk-size 16G --disk-image ./x1.qcow2 --keep-disk
```

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
