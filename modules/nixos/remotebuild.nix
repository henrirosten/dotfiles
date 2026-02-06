_:
let
  user = (import ../../users/hrosten.nix).user;
in
{
  nix = {
    distributedBuilds = true;
    buildMachines =
      let
        commonOptions = {
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          sshUser = user.username;
          sshKey = "${user.homedir}/.ssh/id_ed25519";
        };
      in
      [
        (
          {
            hostName = "hetzarm.vedenemo.dev";
            system = "aarch64-linux";
            maxJobs = 40;
          }
          // commonOptions
        )
        (
          {
            hostName = "builder.vedenemo.dev";
            system = "x86_64-linux";
            maxJobs = 48;
          }
          // commonOptions
        )
      ];
  };

  programs.ssh.knownHosts = {
    "hetzarm.vedenemo.dev".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
    "builder.vedenemo.dev".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG68NdmOw3mhiBZwDv81dXitePoc1w//p/LpsHHA8QRp";
  };
}
