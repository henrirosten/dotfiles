{pkgs, ...}: {
  programs.zsh = {
    enable = true;

    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;

    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };

    sessionVariables = {
      EDITOR = "vim";
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
  };
}
