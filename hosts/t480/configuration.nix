{
  inputs,
  outputs,
  stateVersion,
  ...
}:
let
  hrosten = (import ../../users/hrosten.nix);
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ]
  ++ (with outputs.nixosModules; [
    common-nix
    host-common
    laptop
    gui
    ssh
    hrosten.nixosModule
  ]);

  networking.hostName = "t480";

  system.autoUpgrade.dates = "02:00";

  home-manager.extraSpecialArgs = {
    inherit
      inputs
      outputs
      stateVersion
      ;
  };

  home-manager.users.${hrosten.user.username} =
    { ... }:
    {
      imports = [
        outputs.homeModules.hm-hrosten
        outputs.homeModules.gui-extras
      ];
    };
}
