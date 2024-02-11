{pkgs, ...}: {
  # show what package provides a commands when it's not found
  programs = {
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # run commands without installing them
    # , <cmd>
    nix-index-database.comma.enable = true;
  };

  programs.zsh = {
    enable = true;

    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableCompletion = true;

    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };

    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
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
