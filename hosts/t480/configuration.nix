{
  inputs,
  outputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (with outputs.nixosModules; [
      common-nix
      (host-common { inherit inputs; })
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
        ;
    })
    ./hardware-configuration.nix
  ];

  networking.hostName = "t480";

  boot.kernelParams = [ "mem_sleep_default=deep" ]; # force S3 sleep mode

  services = {
    # fingerprint scanner daemon
    # to enroll a finger, use sudo fprintd-enroll $USER
    # fprintd.enable = true;
  };

  system.autoUpgrade.dates = "02:00";
}
