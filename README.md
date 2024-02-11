# NixOS Flake

## Usage

Clone this repository:
```bash
$ git clone https://github.com/henrirosten/dotfiles.git
$ cd dotfiles
```

### NixOS

Bootstrap nix shell with `flakes` and `nix-command`:
```
$ nix-shell
```

Build `hostname` configuration:
```bash
$ nixos-rebuild build --flake .#hostname
```

Install `hostname` configuration:
```bash
$ sudo nixos-rebuild switch --flake .#hostname
```

## Acknowledgements

- https://github.com/joinemm/snowflake
- https://github.com/Misterio77/nix-starter-configs
