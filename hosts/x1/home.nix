{
  inputs,
  outputs,
  user,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.users."${user.username}" = {lib, ...}: {
    imports = pkgs.lib.flatten [
      (with outputs.homeManagerModules; [
        bash
        codium
        (git {inherit pkgs user;})
        ssh-conf
        starship
        vim
        zsh
      ])
      inputs.nixvim.homeManagerModules.nixvim
      inputs.nix-index-database.hmModules.nix-index
      {
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
        programs.home-manager.enable = true;
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
      }
    ];
  };
}
