#!/bin/sh
set -ux

################################################################################

install_dotfiles () {
    nix-shell -p git --run 'git clone https://github.com/henrirosten/dotfiles "$HOME/.config/nixpkgs"'
    if [ ! -f "$HOME/.config/nixpkgs/bootstrap-nixos.sh" ]; then
        echo "Error: failed to clone the dotfiles"
        exit 1
    fi
    mv "$HOME/.bashrc" "$HOME/.bashrc.bak" 2>/dev/null
    mv "$HOME/.profile" "$HOME/.profile.bak" 2>/dev/null
    nix-env -e bat curl git htop less meld nix-info shellcheck tree vim vscode wget 
    if ! nix-shell '<home-manager>' -A install; then
        set +x
        echo "Error: home-manager installation failed."
        echo "Typically, the failure is due to conflicting cofiguration files."
        echo "Manually re-install following the fix proposal from home-manager."
        exit 1
    fi
}

outro () {
    set +x
    echo ""
    echo "nix-info:"
    if ! nix-info -m; then
        echo "Error: nix-info failed, check the shell output for errors"
        exit 1
    fi
    nixpkgs_ver=$(nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version' 2>/dev/null)
    if [ -n "$nixpkgs_ver" ]; then
        echo "nixpkgs:"
        echo " - nixpkgs version: $nixpkgs_ver"
    fi
    echo ""
    echo "All done!"
    echo "For the new environment to take impact, either start a new shell or run:"
    echo ""
    echo "  . $HOME/.bashrc"
    echo ""
}

exit_unless_command_exists () {
    if ! [ -x "$(command -v "$1")" ]; then
        echo "Error: command '$1' is not installed" >&2
        exit 1
    fi
}

################################################################################

main () {
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    install_dotfiles
    outro
}

################################################################################

main "$@"

################################################################################
