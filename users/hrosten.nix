# User configuration for hrosten
let
  user = {
    name = "Henri Rosten";
    username = "hrosten";
    homedir = "/home/hrosten";
    email = "henri.rosten@unikie.com";
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFuB+uEjhoSdakwiKLD3TbNpbjnlXerEfZQbtRgvdSz"
    ];
  };
in
{
  inherit user;

  nixosModule =
    { pkgs, ... }:
    {
      users.users."${user.username}" = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        initialPassword = "changemeonfirstlogin";
        home = user.homedir;
        shell = pkgs.bash;
        openssh.authorizedKeys.keys = user.keys;
      };
    };
}
