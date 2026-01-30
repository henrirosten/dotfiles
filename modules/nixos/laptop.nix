{ pkgs, ... }:
{
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

  # Battery life improvements

  powerManagement.enable = true;
  # powerManagement.powertop.enable = true;

  # conflicts with services.power-profiles-daemon.enable enabled by Gnome:
  # services.tlp.enable = true;

  # https://www.reddit.com/r/linux/comments/1em8biv/psa_pipewire_has_been_halving_your_battery_life/
  services.pipewire = {
    wireplumber.extraConfig."10-disable-camera.conf" = {
      "wireplumber.profiles".main."monitor.libcamera" = "disabled";
    };
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };
}
