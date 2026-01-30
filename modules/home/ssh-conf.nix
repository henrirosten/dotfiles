{
  programs.ssh = {
    enableDefaultConfig = false;
    enable = true;
    matchBlocks = {
      "*" = {
        controlMaster = "auto";
        controlPath = "~/.ssh/%C";
      };
    };
  };
}
