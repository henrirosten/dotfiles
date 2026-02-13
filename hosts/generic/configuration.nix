{
  inputs,
  outputs,
  stateVersion,
  ...
}:
let
  hrosten = import ../../users/hrosten/hrosten.nix;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
  ]
  ++ (with outputs.nixosModules; [
    common-nix
    host-common
    ssh
    hrosten.nixosModule
  ]);

  networking.hostName = "generic";

  services.getty.autologinUser = hrosten.user.username;
  security.sudo.wheelNeedsPassword = false;
  system.autoUpgrade.dates = "weekly";

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
        ../../users/hrosten/home.nix
        (
          { lib, ... }:
          {
            programs.starship.settings = {
              format = lib.mkForce "\${custom.vm_indicator}$all";
              custom.vm_indicator = {
                when = true;
                command = "echo vm";
                format = "[[$output](bold yellow)]($style) ";
                style = "bold yellow";
              };
            };
          }
        )
      ];
    };
}
