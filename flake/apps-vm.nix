{
  inputs,
  forAllSystems,
  mkPkgs,
  nixosConfigurations,
}:
forAllSystems (
  system:
  let
    lib = inputs.nixpkgs.lib;
    pkgs = mkPkgs system;
    hrosten = import ../users/hrosten/hrosten.nix;
    username = hrosten.user.username;
    sameSystemNixosConfigurations = lib.filterAttrs (
      _: nixosConfig: nixosConfig.pkgs.stdenv.hostPlatform.system == system
    ) nixosConfigurations;
  in
  lib.mapAttrs' (
    name: nixosConfig:
    let
      isGeneric = name == "generic";
      vcpus = if isGeneric then 4 else 1;
      ramGb = if isGeneric then 16 else 1;
      diskGb = if isGeneric then 100 else 8;
      vmConfig = nixosConfig.extendModules {
        modules = [
          (
            { lib, ... }:
            (
              {
                virtualisation.vmVariant.virtualisation = {
                  graphics = lib.mkForce true;
                  cores = lib.mkForce vcpus;
                  memorySize = lib.mkForce (ramGb * 1024);
                  diskSize = lib.mkForce (diskGb * 1024);
                  writableStore = lib.mkForce true;
                  useNixStoreImage = lib.mkForce false;
                  mountHostNixStore = lib.mkForce true;
                  writableStoreUseTmpfs = lib.mkForce false;
                  qemu.consoles = lib.mkForce [ "ttyS0,115200n8" ];
                  qemu.options = lib.mkAfter [
                    "-display none"
                    "-serial mon:stdio"
                    "-device virtio-balloon"
                    "-enable-kvm"
                  ];
                };
                services.getty.autologinUser = lib.mkForce (if isGeneric then username else "root");
                # Keep codex-cli available in VM even when HM activation is disabled.
                environment.systemPackages = lib.mkAfter [
                  inputs.codex-cli-nix.packages.${system}.default
                ];
              }
              // lib.optionalAttrs (!isGeneric) {
                # Home Manager activation can take minutes in VM boot; disable it for fast test boots.
                systemd.services."home-manager-${username}".enable = lib.mkForce false;
              }
              // lib.optionalAttrs isGeneric {
                security.sudo.wheelNeedsPassword = lib.mkForce false;
              }
            )
          )
        ];
      };
      vmRunner = "${vmConfig.config.system.build.vm}/bin/run-${name}-vm";
      vmAppRunner = pkgs.replaceVarsWith {
        src = ../scripts/run-vm.sh;
        name = "run-${name}-vm";
        dir = "bin";
        isExecutable = true;
        replacements = {
          vmName = name;
          defaultRamMb = toString (ramGb * 1024);
          defaultCpus = toString vcpus;
          defaultDiskSize = "${toString diskGb}G";
          defaultDiskImage = "./${name}.qcow2";
          defaultCleanupDisk = if isGeneric then "0" else "1";
          defaultCleanupBehavior = if isGeneric then "kept" else "deleted";
          mktemp = "${pkgs.coreutils}/bin/mktemp";
          qemuImg = "${pkgs.qemu}/bin/qemu-img";
          mkfsExt4 = "${pkgs.e2fsprogs}/bin/mkfs.ext4";
          inherit vmRunner;
        };
      };
    in
    lib.nameValuePair "${name}-vm" {
      type = "app";
      program = "${vmAppRunner}/bin/run-${name}-vm";
      meta = {
        description = "Run ${name} VM - 'nix run .#${name}-vm -- --help'";
      };
    }
  ) sameSystemNixosConfigurations
)
