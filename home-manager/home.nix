{ inputs, pkgs, user, ... }:

{
  imports = [ 
    ./vim.nix 
    ./bash.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = rec {
     username = user.username;
     homeDirectory = user.homeDirectory;
     packages = with pkgs; [
        bat
        curl
        htop
        nix-info
        wget
        meld
        csvkit
        fish
      ];
    sessionVariables = {
      EDITOR = "vim";
      NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
    };
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "23.05";
    language = {
      base =     "en_US.utf8";
      ctype =    "en_US.utf8";
    };
  };
  programs.man.enable = true;
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };
  programs.fish.enable = true;
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = user.name;
    userEmail = user.email;
    extraConfig = {
      core = { 
        whitespace = "trailing-space,space-before-tab"; 
        editor = "vim";
      };
      commit.sign = true;
      merge.tool = "meld";
      mergetool."meld".cmd = "meld $LOCAL $MERGED $REMOTE --output $MERGED";
      difftool."meld".cmd = "meld $LOCAL $REMOTE";
      init.defaultBranch = "main";
    };
  };
  programs.home-manager.enable = true;
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
    ];
  };
  xdg.configFile."nix/nix.conf".text = ''
    build-users-group = nixbld
    experimental-features = nix-command flakes
  '';
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
