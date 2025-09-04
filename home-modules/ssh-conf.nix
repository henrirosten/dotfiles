{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        controlMaster = "auto";
        controlPath = "~/.ssh/%C";
      };
    };
  };
}
