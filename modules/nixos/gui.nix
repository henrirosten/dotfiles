{
  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xserver = {
      enable = true;
      xkb.layout = "fi";
      autoRepeatDelay = 200;
      autoRepeatInterval = 20;
    };
  };

  # use X keyboard options in console
  console.useXkbConfig = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
