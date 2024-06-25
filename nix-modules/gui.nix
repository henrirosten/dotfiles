_: {
  services.xserver = {
    enable = true;
    xkb.layout = "fi";
    autoRepeatDelay = 180;
    autoRepeatInterval = 20;

    # gnome
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # use X keyboard options in console
  console.useXkbConfig = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
