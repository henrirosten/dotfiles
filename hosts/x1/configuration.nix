{
  inputs,
  outputs,
  lib,
  ...
}:
let
  remoteBuildUser = (import ../../users/hrosten.nix).user;
in
{
  imports = lib.flatten [
    (with outputs.nixosModules; [
      common-nix
      (host-common { inherit inputs; })
      laptop
      gui
      ssh-access
      (remotebuild {
        sshUser = remoteBuildUser.username;
        sshKey = "${remoteBuildUser.homedir}/.ssh/id_ed25519";
      })
      user-hrosten
    ])
    (with inputs.nixos-hardware.nixosModules; [
      lenovo-thinkpad-x1-11th-gen
    ])
    (import ./home.nix {
      inherit
        inputs
        outputs
        ;
    })
    ./hardware-configuration.nix
  ];

  networking.hostName = "x1";

  boot.kernelParams = [ "mem_sleep_default=deep" ]; # force S3 sleep mode

  services.avahi.enable = false;

  system.autoUpgrade.dates = "weekly";
}
