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
    experimentalfeatures="experimental-features = nix-command flakes"
    sudo bash -c "echo $experimentalfeatures >>/etc/nix/nix.conf"
    if systemctl list-units | grep -iq "nix-daemon"; then
        sudo systemctl restart nix-daemon
    fi
    if ! nix-shell '<home-manager>' -A install; then
        set +x
        echo "Error: home-manager installation failed."
        echo "Manually re-install following the fix proposal from home-manager."
        exit 1
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
    rm -rf "$HOME/"{.nix-channels,.nix-defexpr,.nix-profile,.config/nixpkgs,.config/nix,.config/home-manager,.local/state/nix,.local/state/home-manager}
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

outro () {
    set +x
    echo ""
    nixpkgs_ver=$(nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version' 2>/dev/null)
    if [ -n "$nixpkgs_ver" ]; then
        echo "Installed nixpkgs version: $nixpkgs_ver"
    else
        echo "Failed reading installed nixpkgs version"
    fi
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
    outro
}

################################################################################

main "$@"

################################################################################
