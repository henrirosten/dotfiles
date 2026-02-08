{
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./vscode.nix
  ];

  home = {
    packages = with pkgs; [
      burpsuite
      chromium
      firefox
      google-chrome
      libreoffice
      wireshark
    ];
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    # Keyboard repeat settings are configured system-wide in nix-modules/gui.nix
    # via services.xserver.autoRepeatDelay and autoRepeatInterval
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
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "org.gnome.Terminal.desktop"
        "google-chrome.desktop"
        "keepass.desktop"
      ];
    };
  };
}
