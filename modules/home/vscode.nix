{ pkgs, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "vscode" ];
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    # https://github.com/nix-community/nix-vscode-extensions/blob/master/data/cache/open-vsx-latest.json
    profiles.default.extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      bbenoist.nix
      ms-python.python
      mechatroner.rainbow-csv
      shardulm94.trailing-spaces
    ];
  };
}
