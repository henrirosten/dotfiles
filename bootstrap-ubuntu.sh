#!/bin/bash
set -ux

################################################################################

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
    # Fix https://github.com/nix-community/home-manager/issues/3734:
    sudo mkdir -m 0755 -p /nix/var/nix/{profiles,gcroots}/per-user/"$USER"
    sudo chown -R "$USER:nixbld" "/nix/var/nix/profiles/per-user/$USER"
    # Enable flakes
    extra_nix_conf="experimental-features = nix-command flakes\ntrusted-users = $(whoami)"
    sudo sh -c "printf '$extra_nix_conf\n'>>/etc/nix/nix.conf"
    # https://github.com/NixOS/nix/issues/1078#issuecomment-1019327751
    for f in /nix/var/nix/profiles/default/bin/nix*; do
        sudo ln -fs "$f" "/usr/bin/$(basename "$f")"
    done
}

restart_nix_daemon () {
    # Re-start nix-daemon
    if systemctl list-units | grep -iq "nix-daemon"; then
        sudo systemctl restart nix-daemon
        if ! systemctl status nix-daemon; then
            echo "Error: nix-daemon failed to start"
            exit 1
        fi
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
    sudo rm -rf /etc/profile.d/nix.sh
    if [ -d "/nix" ]; then
        sudo rm -rf /nix
    fi
    if [ -d "/etc/nix" ]; then
        sudo rm -fr /etc/nix.bak
        sudo mv /etc/nix /etc/nix.bak
    fi
    if [ -d "$HOME/.cache/nix" ]; then
        sudo rm -fr "$HOME/.cache/nix.bak"
        sudo mv  "$HOME/.cache/nix" "$HOME/.cache/nix.bak"
    fi
    sudo find /etc -iname "*backup-before-nix*" -delete
    sudo find -L /usr/bin -iname "nix*" -delete
    [ -f "$HOME/.profile" ] && sed -i "/\/nix/d" "$HOME/.profile"
    [ -f "$HOME/.bash_profile" ] && sed -i "/\/nix/d" "$HOME/.bash_profile"
    [ -f "$HOME/.bashrc" ] && sed -i "/\/nix/d" "$HOME/.bashrc"
    if systemctl list-units | grep -iq "nix-daemon"; then
        sudo systemctl stop nix-daemon nix-daemon.socket
        sudo systemctl disable nix-daemon nix-daemon.socket
        sudo find /etc/systemd -iname "*nix-daemon*" -delete
        sudo find /usr/lib/systemd -iname "*nix-daemon*" -delete
        sudo systemctl daemon-reload
        sudo systemctl reset-failed
    fi
    unset NIX_PATH
}

outro () {
    set +x
    echo ""
    nixpkgs_ver=$(nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version' 2>/dev/null)
    if [ -n "$nixpkgs_ver" ]; then
        echo "Installed nixpkgs version: $nixpkgs_ver"
    else
        echo "Failed reading installed nixpkgs version"
        exit 1
    fi
    echo ""
    echo "Open a new terminal for the changes to take impact"
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
    uninstall_nix
    install_nix "multi"
    restart_nix_daemon
    exit_unless_command_exists "nix-shell"
    outro
}

################################################################################

main "$@"

################################################################################
