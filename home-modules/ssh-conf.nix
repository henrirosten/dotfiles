{
  programs.ssh = {
    enable = true;
    controlMaster = "auto";
    controlPath = "~/.ssh/%C";
    matchBlocks = {
      ci-server = {
        hostname = "172.18.20.100";
      };
      build1 = {
        hostname = "172.18.20.102";
      };
      build2 = {
        hostname = "172.18.20.103";
      };
      build3 = {
        hostname = "172.18.20.104";
      };
      build4 = {
        hostname = "172.18.20.105";
      };
      monitoring = {
        hostname = "172.18.20.108";
      };
      awsarm = {
        hostname = "13.51.226.233";
        port = 20220;
      };
      jenkins2 = {
        hostname = "172.18.16.32";
        user = "tc-agent02";
      };
    };
  };
}
