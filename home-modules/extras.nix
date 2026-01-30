{
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  home = {
    packages = with pkgs; [
      claude-code
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
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "org.gnome.Terminal.desktop"
        "google-chrome.desktop"
        "vscode.desktop"
        "keepass.desktop"
      ];
    };
  };
}
