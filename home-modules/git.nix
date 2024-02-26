{
  pkgs,
  user,
  ...
}: {
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
      credential.helper = "cache --timeout=3600";
    };
  };
}
