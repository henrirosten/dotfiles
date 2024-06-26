{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

  services.libinput = {
    # touchpad
    enable = true;
    touchpad = {
      tapping = true;
      disableWhileTyping = true;
    };
  };

  # battery life improvements
  powerManagement.enable = true;
  # powerManagement.powertop.enable = true;

  # conflicts with services.power-profiles-daemon.enable enabled by Gnome:
  # services.tlp.enable = true;
}
