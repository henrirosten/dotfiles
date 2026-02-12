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
        description = "Run the ${name} NixOS configuration in a headless VM";
      };
    }
  ) sameSystemNixosConfigurations
)
