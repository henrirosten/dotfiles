{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      vim-pathogen
    ];
    extraConfig = builtins.readFile ./vimrc;
  };
}
