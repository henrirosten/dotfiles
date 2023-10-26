# Dotfiles

Dotfiles for Ubuntu (Debian) and NixOS using [Nix Home Manager](https://nixos.wiki/wiki/Home_Manager).

## Usage

Clone this repository:
```bash
$ git clone https://github.com/henrirosten/dotfiles.git
$ cd dotfiles
```

### Ubuntu

Install Nix package manager either following the instructions from https://nixos.org/download, or by running the bootstrap script from this repository:
```bash
$ ./bootstrap-ubuntu.sh
```

Then, start a new shell and follow the instructions from the [NixOS](.#nixos) section.

### NixOS

Bootstrap nix shell with `flakes` and `nix-command`:
```
nix-shell
```

Install your user configuration:
```bash
$ home-manager switch --flake .#hrosten
```


## Acknowledgements

Inspired by https://github.com/Misterio77/nix-starter-configs.
