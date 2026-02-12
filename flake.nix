{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, ... }:
    let
      inherit (self) outputs;
      stateVersion = "23.11";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      defaultSystem = "x86_64-linux";
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
      mkPkgs = system: inputs.nixpkgs.legacyPackages.${system};

      specialArgs = {
        inherit
          inputs
          outputs
          stateVersion
          ;
      };

      mkPreCommitCheck =
        system:
        inputs.git-hooks-nix.lib.${system}.run {
          src = self.outPath;
          # default_stages = ["pre-commit" "pre-push"];
          hooks = {
            # lint commit messages
            gitlint.enable = true;
            # fix end-of-files
            end-of-file-fixer.enable = true;
            # spell check
            typos.enable = true;
            # nix formatter
            nixfmt.enable = true;
            # removes dead nix code
            deadnix.enable = true;
            # prevents use of nix anti-patterns
            statix = {
              enable = true;
              args = [
                "fix"
              ];
            };
            # bash linter
            shellcheck.enable = true;
            # bash formatter
            shfmt = {
              enable = true;
              args = [
                "--indent"
                "2"
              ];
            };
          };
        };

      nixosConfigurations = {
        x1 = inputs.nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [ ./hosts/x1/configuration.nix ];
        };
        t480 = inputs.nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [ ./hosts/t480/configuration.nix ];
        };
      };
    in
    {
      nixosModules = import ./modules/nixos;
      homeModules = import ./modules/home;

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager switch --flake .#hrosten'
      # Cross-system entries are also exported as:
      # - hrosten-x86_64-linux
      # - hrosten-aarch64-linux
      homeConfigurations =
        (builtins.listToAttrs (
          map (system: {
            name = "hrosten-${system}";
            value = inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = mkPkgs system;
              extraSpecialArgs = specialArgs;
              modules = [ ./users/hrosten/home.nix ];
            };
          }) systems
        ))
        // {
          "hrosten" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = mkPkgs defaultSystem;
            extraSpecialArgs = specialArgs;
            modules = [ ./users/hrosten/home.nix ];
          };
        };

      inherit nixosConfigurations;

      apps = forAllSystems (
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
                  }
                )
              ];
            };
            vmRunner = "${vmConfig.config.system.build.vm}/bin/run-${name}-vm";
          in
          lib.nameValuePair "${name}-vm" {
            type = "app";
            program = toString (
              pkgs.writeShellScript "run-${name}-vm" ''
                cleanup_disk=1
                ram_mb="${toString (ramGb * 1024)}"
                cpus="${toString vcpus}"
                disk_size="${toString diskGb}G"
                disk_image="''${NIX_DISK_IMAGE:-./${name}.qcow2}"
                override_ram=0
                override_cpus=0
                override_disk_size=0

                if [ -n "''${VM_KEEP_DISK:-}" ]; then
                  cleanup_disk=0
                fi

                while [ "$#" -gt 0 ]; do
                  case "$1" in
                    --keep-disk)
                      cleanup_disk=0
                      shift
                      ;;
                    --delete-disk)
                      cleanup_disk=1
                      shift
                      ;;
                    --disk-image)
                      disk_image="$2"
                      shift 2
                      ;;
                    --ram-mb)
                      ram_mb="$2"
                      override_ram=1
                      shift 2
                      ;;
                    --cpus)
                      cpus="$2"
                      override_cpus=1
                      shift 2
                      ;;
                    --disk-size)
                      disk_size="$2"
                      override_disk_size=1
                      shift 2
                      ;;
                    --help|-h)
                      cat <<'EOF'
                Usage: nix run .#${name}-vm -- [OPTIONS] [-- RUNNER_ARGS...]

                Options:
                  --keep-disk        Keep disk image after VM exits
                  --delete-disk      Remove disk image on VM exit (default)
                  --ram-mb MB        RAM in MiB (default: ${toString (ramGb * 1024)})
                  --cpus N           Number of CPUs (default: ${toString vcpus})
                  --disk-size SIZE   Disk size (e.g. 8G, 16384M; default: ${toString diskGb}G)
                  --disk-image PATH  Disk image path (default: ./${name}.qcow2)

                Environment:
                  VM_KEEP_DISK=1     Keep disk image after VM exits
                  NIX_DISK_IMAGE     Override disk image path
                EOF
                      exit 0
                      ;;
                    --)
                      shift
                      break
                      ;;
                    *)
                      break
                      ;;
                  esac
                done

                export NIX_DISK_IMAGE="$disk_image"
                if [ "$override_ram" -eq 1 ]; then
                  export QEMU_OPTS="''${QEMU_OPTS:+$QEMU_OPTS }-m $ram_mb"
                fi
                if [ "$override_cpus" -eq 1 ]; then
                  export QEMU_OPTS="''${QEMU_OPTS:+$QEMU_OPTS }-smp $cpus"
                fi
                if [ "$override_disk_size" -eq 1 ]; then
                  if [ ! -e "$disk_image" ]; then
                    tmp_raw="$(${pkgs.coreutils}/bin/mktemp -t ${name}-disk.XXXXXX)"
                    ${pkgs.qemu}/bin/qemu-img create -f raw "$tmp_raw" "$disk_size"
                    ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L nixos "$tmp_raw" >/dev/null
                    ${pkgs.qemu}/bin/qemu-img convert -f raw -O qcow2 "$tmp_raw" "$disk_image"
                    rm -f -- "$tmp_raw"
                  else
                    ${pkgs.qemu}/bin/qemu-img resize "$disk_image" "$disk_size" >/dev/null
                  fi
                fi

                cleanup() {
                  status="$?"
                  if [ "$cleanup_disk" -eq 1 ] && [ -f "$disk_image" ]; then
                    rm -f -- "$disk_image"
                  fi
                  exit "$status"
                }

                trap cleanup EXIT INT TERM

                ${vmRunner} "$@"
              ''
            );
            meta = {
              description = "Run the ${name} NixOS configuration in a headless VM with optional RAM/CPU/disk flags and auto-cleaned disk image support";
            };
          }
        ) sameSystemNixosConfigurations
      );

      formatter = forAllSystems (
        system:
        let
          inherit (outputs.checks.${system}.pre-commit-check.config) package configFile;
          pkgs = mkPkgs system;
        in
        pkgs.writeShellScriptBin "pre-commit-run" ''
          ${pkgs.lib.getExe package} run --all-files --config ${configFile}
        ''
      );

      checks = forAllSystems (system: {
        pre-commit-check = mkPreCommitCheck system;
      });

      devShells = forAllSystems (system: {
        default = (mkPkgs system).mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });
    };
}
