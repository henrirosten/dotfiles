# Common host configuration shared between all NixOS machines
{ inputs }:
{ config, ... }:
{
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    efi.canTouchEfiVariables = true;
  };

  # disable ssh askpass
  programs.ssh.askPassword = "";

  services.fwupd.enable = true;

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    flake = "${inputs.self.outPath}#${config.networking.hostName}";
    flags = [
      "--update-input"
      "nixpkgs"
      "-L"
      "--cores 2"
    ];
    # Override in host config: dates = "02:00" or "weekly"
    persistent = true;
  };
}
