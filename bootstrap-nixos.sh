#!/bin/sh
set -ux

################################################################################

MYDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

################################################################################

install_dotfiles () {
    rm -fr "$HOME/nixpkgs.bak" 2>/dev/null
    cp -r "$HOME/.config/nixpkgs" "$HOME/nixpkgs.bak" && rm -fr "$HOME/.config/nixpkgs" 2>/dev/null
    if [ -f "$MYDIR/home.nix" ]; then
        mkdir -p "$HOME/.config/nixpkgs"
        cp  "$MYDIR/home.nix" "$HOME/.config/nixpkgs/"
    else
        nix-shell -p git --run "git clone https://github.com/henrirosten/dotfiles \"$HOME/.config/nixpkgs\""
    fi
    if [ ! -f "$HOME/.config/nixpkgs/home.nix" ]; then
        echo "Error: failed to clone the dotfiles"
        exit 1
    fi
    nix-env -e '*'
    mv -f "$HOME/.bashrc" "$HOME/.bashrc.bak" 2>/dev/null
    mv -f "$HOME/.profile" "$HOME/.profile.bak" 2>/dev/null
    substituters="nix.settings.substituters = [\
        \"https://cache.vedenemo.dev\" \
        \"https://cache.ssrcdevops.tii.ae\" \
        \"https://cache.nixos.org\" ];"
    trustedpublickeys="nix.settings.trusted-public-keys = [\
        \"cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg=\" \
        \"cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk=\" \
        \"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=\" ];"
    nix_conf="/etc/nixos/configuration.nix"
    # Last occurence of '}' in $nix_conf
    line=$(grep -n '}' $nix_conf | tail -1 | cut -d: -f1)
    # Replace line if $match is found, otherwise append on $line
    match="substituters"
    if grep -q "$match" "$nix_conf"; then
        sudo sed -i "s|.*$match.*|$substituters|" "$nix_conf"
    else
        # Append to linenumber $line
        sudo sed -i "$line i $substituters" "/etc/nixos/configuration.nix"
    fi
    # Replace line if $match is found, otherwise append on $line
    match="trusted-public-keys"
    if grep -q "$match" "$nix_conf"; then
        sudo sed -i "s|.*$match.*|$trustedpublickeys|" "$nix_conf"
    else
        # Append to linenumber $line
        sudo sed -i "$line i $trustedpublickeys" "/etc/nixos/configuration.nix"
    fi
    if ! nix-shell '<home-manager>' -A install; then
        set +x
        echo "Error: home-manager installation failed."
        echo "Typically, the failure is due to conflicting cofiguration files."
        echo "Manually re-install following the fix proposal from home-manager."
        exit 1
    fi
    sudo nixos-rebuild switch
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
    if ! command -v "$1" 2> /dev/null; then
        echo "Error: command '$1' is not installed" >&2
        exit 1
    fi
}

################################################################################

main () {
    if ! uname -a | grep -q "nixos"; then
        "Error: current system is not NixOS"
        exit 1
    fi
    exit_unless_command_exists "nix-channel"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    install_dotfiles
    outro
}

################################################################################

main "$@"

################################################################################
