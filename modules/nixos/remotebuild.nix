# Remote build configuration for distributed Nix builds
# Requires SSH access to the build machines (hetzarm.vedenemo.dev, builder.vedenemo.dev)
{
  sshUser,
  sshKey,
  builders ? null,
}:
let
  # Default build machines - can be overridden via the builders parameter
  defaultBuilders = [
    {
      hostName = "hetzarm.vedenemo.dev";
      system = "aarch64-linux";
      maxJobs = 40;
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
    }
    {
      hostName = "builder.vedenemo.dev";
      system = "x86_64-linux";
      maxJobs = 48;
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG68NdmOw3mhiBZwDv81dXitePoc1w//p/LpsHHA8QRp";
    }
  ];

  actualBuilders = if builders == null then defaultBuilders else builders;

  commonOptions = {
    speedFactor = 1;
    supportedFeatures = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ];
    inherit sshUser sshKey;
  };

  mkBuildMachine =
    builder:
    {
      inherit (builder) hostName system maxJobs;
    }
    // commonOptions;

  mkKnownHost = builder: {
    name = builder.hostName;
    value.publicKey = builder.publicKey;
  };
in
{
  nix = {
    distributedBuilds = true;
    buildMachines = map mkBuildMachine actualBuilders;
  };

  programs.ssh.knownHosts = builtins.listToAttrs (map mkKnownHost actualBuilders);
}
