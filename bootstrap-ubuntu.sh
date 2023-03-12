#!/bin/bash
set -ux

################################################################################

NIX_ENV_PATH=""
MYDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

apt_update () {
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install -y ca-certificates curl xz-utils 
}

install_nix () {
    type="$1"
    if [ "$type" = "single" ]; then
        # Single-user
        sh <(curl -L https://nixos.org/nix/install) --yes --no-daemon
    elif [ "$type" = "multi" ]; then
        # Multi-user
        sh <(curl -L https://nixos.org/nix/install) --yes --daemon
    else
        echo "Error: unknown installation type: '$type'"
        exit 1
    fi

    mkdir -p "$HOME/.config/nix"
    if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        NIX_ENV_PATH="$HOME/.nix-profile/etc/profile.d/nix.sh"
        # shellcheck source=/dev/null
        source "$NIX_ENV_PATH" 
    fi
    if [ -f "/etc/profile.d/nix.sh" ]; then
        NIX_ENV_PATH="/etc/profile.d/nix.sh"
        # shellcheck source=/dev/null
        source "$NIX_ENV_PATH"
    fi
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    substituters="substituters = \
        https://cache.vedenemo.dev \
        https://cache.ssrcdevops.tii.ae \
        https://cache.nixos.org"
    trustedpublickeys="trusted-public-keys = \
        cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg= \
        cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk= \
        cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    experimentalfeatures="experimental-features = nix-command flakes"
    sudo bash -c "echo $substituters >>/etc/nix/nix.conf"
    sudo bash -c "echo $trustedpublickeys >>/etc/nix/nix.conf"
    sudo bash -c "echo $experimentalfeatures >>/etc/nix/nix.conf"
    if systemctl list-units | grep -iq "nix-daemon"; then
        sudo systemctl restart nix-daemon
    fi
}

uninstall_nix () {
    # https://github.com/NixOS/nix/issues/1402
    if grep -q nixbld /etc/passwd; then 
        grep nixbld /etc/passwd | awk -F ":" '{print $1}' | xargs -t -n 1 sudo userdel -r
    fi
    if grep -q nixbld /etc/group; then
        sudo groupdel nixbld
    fi
    rm -rf "$HOME/"{.nix-channels,.nix-defexpr,.nix-profile,.config/nixpkgs,.config/nix}
    if [ -d "/nix" ]; then
        sudo rm -rf /nix
    fi
    if [ -d "/etc/nix" ]; then
        sudo mv -f /etc/nix /etc/nix.bak
    fi
    sudo find /etc -iname "*backup-before-nix*" | sudo xargs rm -f
    sed -i "/\/nix/d" "$HOME/.profile"
    sed -i "/\/nix/d" "$HOME/.bash_profile"
    if systemctl list-units | grep -iq "nix-daemon"; then
        sudo systemctl stop nix-daemon nix-daemon.socket
        sudo systemctl disable nix-daemon nix-daemon.socket
        sudo find /etc/systemd -iname "*nix-daemon*" | sudo xargs rm
        sudo find /usr/lib/systemd -iname "*nix-daemon*" | sudo xargs rm
        sudo systemctl daemon-reload
        sudo systemctl reset-failed
    fi
}

install_dotfiles () {
    mv -f "$HOME/.config/nixpkgs" "$HOME/nixpkgs.bak" 2>/dev/null
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
    mv -f "$HOME/.bashrc" "$HOME/.bashrc.bak" 2>/dev/null
    mv -f "$HOME/.profile" "$HOME/.profile.bak" 2>/dev/null
    mv -f "$HOME/.vim" "$HOME/.vim.bak" 2>/dev/null
    mv -f "$HOME/.vimrc" "$HOME/.vimrc.bak" 2>/dev/null
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
    echo "  source $NIX_ENV_PATH; source $HOME/.bashrc"
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
    exit_unless_command_exists "apt-get"
    exit_unless_command_exists "systemctl"
    apt_update
    exit_unless_command_exists "curl"
    uninstall_nix
    install_nix "multi"
    exit_unless_command_exists "nix-shell"
    exit_unless_command_exists "nix-env"
    install_dotfiles
    outro
}

################################################################################

main "$@"

################################################################################
