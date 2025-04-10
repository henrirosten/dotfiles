# NixOS Flake

## Usage

Clone this repository:
```bash
❯ git clone https://github.com/henrirosten/dotfiles.git
❯ cd dotfiles
```

## NixOS

Bootstrap nix shell with `flakes` and `nix-command`:
```bash
❯ nix-shell
```

Build the configuration for host `hostname`:
```bash
❯ nixos-rebuild build --flake .#hostname
```

Install the configuration for host `hostname`:
```bash
❯ sudo nixos-rebuild switch --flake .#hostname
```

## Ubuntu

Install Nix package manager either following the instructions from https://nixos.org/download, or by running the bootstrap script from this repository:
```bash
❯ ./bootstrap-ubuntu.sh
```

Then, start a new shell and install your user configuration:

```bash
❯ nix-shell
❯ home-manager switch --flake .#hrosten
```
