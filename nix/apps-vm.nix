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
    sameSystemNixosConfigurations = lib.filterAttrs (
      _: nixosConfig: nixosConfig.pkgs.stdenv.hostPlatform.system == system
    ) nixosConfigurations;
  in
  lib.mapAttrs' (
    name: nixosConfig:
    let
      vcpus = 1;
      ramGb = 1;
      diskGb = 8;
      vmConfig = nixosConfig.extendModules {
        modules = [
          (
            { lib, ... }:
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
              services.getty.autologinUser = lib.mkForce "root";
              # Home Manager activation can take minutes in VM boot; disable it for fast test boots.
              systemd.services."home-manager-hrosten".enable = lib.mkForce false;
              # Keep codex-cli available in VM even when HM activation is disabled.
              environment.systemPackages = lib.mkAfter [
                inputs.codex-cli-nix.packages.${system}.default
              ];
            }
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
        description = "Run the ${name} NixOS configuration in a headless VM";
      };
    }
  ) sameSystemNixosConfigurations
)
