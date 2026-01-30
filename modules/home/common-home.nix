{
  pkgs,
  inputs,
  ...
}:
let
  user = import ../../users/hrosten.nix;
in
{
  fonts.fontconfig.enable = true;
  home = {
    homeDirectory = user.homedir;
    packages = with pkgs; [
      bat
      # burpsuite
      cantarell-fonts
      csvkit
      curl
      dig.dnsutils
      file
      flameshot
      gedit
      gnome-terminal
      gnome-tweaks
      htop
      jq
      keepass
      meld
      net-tools
      nix-info
      openconnect
      openfortivpn
      openvpn
      sbomnix
      tree
      wget
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      pstree
      source-code-pro
    ];
    sessionVariables = {
      NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
      # Centralized EDITOR setting for all shells
      EDITOR = "vim";
    };
    # home.stateVersion for home-manager configuration
    # (separate from system.stateVersion in nix-modules/common-nix.nix which is for home-manager)
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "23.11";
  };
  systemd.user.startServices = "sd-switch";
  programs = {
    home-manager.enable = true;
    # show what package provides a commands when it's not found
    nix-index = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
    # run commands without installing them
    # , <cmd>
    nix-index-database.comma.enable = true;
  };
  xdg.configFile."nix/nix.conf".text = ''
    substituters = https://cache.nixos.org/
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
  '';
  # Ref: https://github.com/nix-community/home-manager/issues/5552
  # Workaround for HM passing a nonexistent units dir to sd-switch
  xdg.configFile."systemd/user/.hm-keep".text = "";
}
