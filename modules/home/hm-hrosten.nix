# Standalone home-manager configuration for hrosten
# Used via: home-manager switch --flake .#hrosten
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
    outputs.homeModules.bash
    outputs.homeModules.common-home
    outputs.homeModules.extras
    outputs.homeModules.git
    outputs.homeModules.ssh-conf
    outputs.homeModules.starship
    outputs.homeModules.vim
    outputs.homeModules.zsh
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.username = user.username;
}
