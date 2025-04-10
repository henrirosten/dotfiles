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
        (common-home {inherit pkgs inputs lib user;})
        extras
        (git {inherit pkgs user;})
        ssh-conf
        starship
        vim
        zsh
      ])
      inputs.nix-index-database.hmModules.nix-index
    ];
  };
}
