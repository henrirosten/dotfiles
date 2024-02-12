{
  inputs,
  outputs,
  user,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.users."${user.username}" = {lib, ...}: {
    imports = pkgs.lib.flatten [
      (with outputs.homeManagerModules; [
        bash
        codium
        (git {inherit pkgs user;})
        ssh-conf
        starship
        vim
        zsh
        common-home
      ])
      inputs.nixvim.homeManagerModules.nixvim
      inputs.nix-index-database.hmModules.nix-index
    ];
  };
}
