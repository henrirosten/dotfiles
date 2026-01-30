{
  pkgs,
  config,
  ...
}:
{
  imports = [ ./shell-common.nix ];

  programs.zsh = {
    enable = true;

    dotDir = "${config.home.homeDirectory}/.config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;

    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    sessionVariables = {
      LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate dracula)";
    };

    history = {
      path = "$HOME/.bash_eternal_history";
      size = 1000000;
      save = 1000000;
      extended = false;
      share = false;
    };

    defaultKeymap = "emacs";

    initContent = ''
      # Source shared shell functions
      [ -f "$HOME/.local/share/shell-functions.sh" ] && source "$HOME/.local/share/shell-functions.sh"
    '';
  };
}
