# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` defines inputs/outputs, NixOS configs, home-manager configs, checks, and formatter.
- `hosts/` contains per-machine configs (`x1`, `t480`) with `configuration.nix` and `hardware-configuration.nix`.
- `modules/nixos/` holds reusable NixOS modules (e.g., `host-common.nix`, `gui.nix`).
- `modules/home/` holds reusable home-manager modules (e.g., `git.nix`, `vim.nix`, `shell-common.nix`).
- `users/` contains user-specific data (e.g., `users/hrosten/hrosten.nix`).
- `users/hrosten/home.nix` defines the home-manager profile composition.
- `bootstrap-nix.sh` bootstraps Nix for home-manager usage.

## Build, Test, and Development Commands
- `nix-shell`: enter the dev shell with pre-commit hooks enabled.
- `nix fmt`: run formatter and linters via the flake formatter.
- `nix flake check --option allow-import-from-derivation false`: run flake checks (pre-commit hooks).
- `nixos-rebuild build --flake .#hostname`: build a host config (use `x1` or `t480`).
- `sudo nixos-rebuild switch --flake .#hostname`: apply a host config.
- `home-manager switch --flake .#hrosten`: apply the standalone home-manager config.
- `./bootstrap-nix.sh`: install Nix, then use home-manager.

## Coding Style & Naming Conventions
- Nix: use `nixfmt` formatting; keep module files small and focused.
- Bash: format with `shfmt` using 2-space indentation; lint with `shellcheck`.
- Nix linting uses `statix` (with `fix`) and `deadnix`.
- Spell-checking via `typos`; commit messages are linted by `gitlint`.
- File/module naming is kebab-case (e.g., `shell-common.nix`, `host-common.nix`).

## Testing Guidelines
There is no standalone unit-test suite; validation is check-driven.
- Run `nix fmt` to catch formatting/lint issues early.
- Run `nix flake check --option allow-import-from-derivation false --no-build` for checks.
- Validate changes by building a target host or switching home-manager when relevant.

## Commit & Pull Request Guidelines
- Commit messages are short and imperative (e.g., “Add vscode”, “Refactor home modules”, “Flake update”).
- Keep commits focused on a single change or theme.
- Include a `Signed-off-by:` trailer in commit messages.
- PRs should describe the affected hosts/modules, include the commands run (e.g., `nix flake check`), and link related issues if any.

## Agent-Specific Instructions
- If you use automated tools, prefer `nix fmt` and `nix flake check` to validate changes.
- See `CLAUDE.md` for additional workflow details and architecture notes.
