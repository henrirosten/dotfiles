{
  inputs,
  outputs,
  ...
}:
let
  user = import ../../users/hrosten.nix;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  home-manager.users."${user.username}" =
    { lib, ... }:
    {
      imports = lib.flatten [
        (with outputs.homeModules; [
          bash
          vscode
          common-home
          extras
          git
          ssh-conf
          starship
          vim
          zsh
        ])
        inputs.nix-index-database.homeModules.nix-index
      ];
    };
}
