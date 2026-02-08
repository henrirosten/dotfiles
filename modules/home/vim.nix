{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      pathogen
    ];
    extraConfig = builtins.readFile ./vimrc;
  };
}
