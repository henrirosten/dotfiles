_: {
  services.xserver = {
    enable = true;
    xkb.layout = "fi";
    autoRepeatDelay = 150;
    autoRepeatInterval = 30;

    # gnome
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # use X keyboard options in console
  console.useXkbConfig = true;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
}
