{
  inputs,
  outputs,
  user,
  lib,
  pkgs,
  ...
}: {
  imports = lib.flatten [
    (with outputs.nixosModules; [
      (common {inherit user pkgs outputs;})
      laptop
      gui
      ssh-access
    ])
    (with inputs.nixos-hardware.nixosModules; [
      lenovo-thinkpad-x1-11th-gen
    ])
    (import ./home.nix {inherit inputs outputs user pkgs lib;})
    ./hardware-configuration.nix
  ];

  boot = {
    # force S3 sleep mode
    kernelParams = ["mem_sleep_default=deep"];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
    };
  };

  # disable ssh askpass
  programs.ssh.askPassword = "";

  services = {
    fwupd.enable = true;

    # fingerprint scanner daemon
    # to enroll a finger, use sudo fprintd-enroll $USER
    # fprintd.enable = true;
  };
}
