{
  pkgs,
  inputs,
  lib,
  user,
  ...
}: {
  home = {
    homeDirectory = user.homedir;
    packages = with pkgs; [
      bat
      # burpsuite
      chromium
      csvkit
      curl
      firefox
      flameshot
      gedit
      gnome.gnome-terminal
      gnome.gnome-tweaks
      google-chrome
      htop
      jq
      keepass
      libreoffice
      meld
      nix-info
      openfortivpn
      openvpn
      sbomnix
      tree
      wget
    ];
    sessionVariables = {
      NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
    };
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
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = lib.hm.gvariant.mkUint32 180;
      repeat-interval = lib.hm.gvariant.mkUint32 20;
    };
    "org/gnome/desktop/sound" = {
      event-sounds = lib.hm.gvariant.mkBoolean false;
    };
    "org/gnome/desktop/notifications" = {
      show-banners = lib.hm.gvariant.mkBoolean false;
    };
    "org/gnome/desktop/interface" = {
      show-battery-percentage = lib.hm.gvariant.mkBoolean true;
    };
    "org/gnome/desktop/calendar" = {
      show-weekday = lib.hm.gvariant.mkBoolean true;
    };
    "org/gnome/shell" = {
      favorite-apps = ["org.gnome.Nautilus.desktop" "org.gnome.Terminal.desktop" "google-chrome.desktop" "codium.desktop" "keepass.desktop"];
    };
  };
  xdg.configFile."nix/nix.conf".text = ''
    substituters = https://cache.nixos.org/ https://ghaf-dev.cachix.org?priority=20 https://cache.vedenemo.dev
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY= cache.vedenemo.dev:8NhplARANhClUSWJyLVk4WMyy1Wb4rhmWW2u8AejH9E=
  '';
}
