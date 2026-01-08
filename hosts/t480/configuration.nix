{
  inputs,
  outputs,
  user,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    (with outputs.nixosModules; [
      (common-nix { inherit pkgs user; })
      laptop
      gui
      ssh-access
    ])
    (with inputs.nixos-hardware.nixosModules; [
      lenovo-thinkpad-t480
    ])
    (import ./home.nix {
      inherit
        inputs
        outputs
        user
        pkgs
        lib
        ;
    })
    ./hardware-configuration.nix
  ];

  boot = {
    # force S3 sleep mode
    kernelParams = [ "mem_sleep_default=deep" ];

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
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    flake = "${inputs.self.outPath}#t480";
    flags = [
      "--update-input"
      "nixpkgs"
      "-L"
      "--cores 2"
    ];
    dates = "02:00";
    persistent = true;
  };
}
