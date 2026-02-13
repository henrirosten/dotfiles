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
    homeDir = hrosten.user.homedir;
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
                virtualisation.vmVariant = {
                  virtualisation = {
                    graphics = lib.mkForce true;
                    cores = lib.mkForce vcpus;
                    memorySize = lib.mkForce (ramGb * 1024);
                    diskSize = lib.mkForce (diskGb * 1024);
                    writableStore = lib.mkForce true;
                    useNixStoreImage = lib.mkForce false;
                    mountHostNixStore = lib.mkForce true;
                    writableStoreUseTmpfs = lib.mkForce false;
                    restrictNetwork = lib.mkForce false;
                    qemu.consoles = lib.mkForce [ "ttyS0,115200n8" ];
                    qemu.options = lib.mkAfter (
                      [
                        "-display none"
                        "-serial mon:stdio"
                        "-device virtio-balloon"
                        "-enable-kvm"
                      ]
                      ++ lib.optionals isGeneric [
                        # Ask QEMU to self-restrict host-side capabilities.
                        "-sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny"
                      ]
                    );
                    sharedDirectories =
                      if isGeneric then
                        lib.mkForce {
                          nix-store = {
                            source = builtins.storeDir;
                            target = "/nix/.ro-store";
                            securityModel = "none";
                          };
                          # Keep only bootstrap auth as a transient host share.
                          codex-bootstrap = {
                            # One-way bootstrap source prepared by run-vm.sh.
                            source = ''"''${CODEX_BOOTSTRAP_DIR:-$TMPDIR/xchg}"'';
                            target = "/mnt/codex-bootstrap";
                            securityModel = "none";
                          };
                        }
                      else
                        { };
                  };
                };
                services.getty.autologinUser = lib.mkForce (if isGeneric then username else "root");
                # Keep codex-cli available in VM even when HM activation is disabled.
                environment.systemPackages = lib.mkAfter [
                  inputs.codex-cli-nix.packages.${system}.default
                ];
                systemd.tmpfiles.rules = lib.optionals isGeneric [
                  "d /mnt/codex-bootstrap 0755 root root -"
                ];
              }
              // lib.optionalAttrs (!isGeneric) {
                # Home Manager activation can take minutes in VM boot; disable it for fast test boots.
                systemd.services."home-manager-${username}".enable = lib.mkForce false;
              }
              // lib.optionalAttrs isGeneric {
                security.sudo.wheelNeedsPassword = lib.mkForce false;
                # VM-friendly free-space thresholds to avoid activation stalls
                # with tmpfs-backed writable store overlays.
                nix.settings = {
                  min-free = lib.mkForce (128 * 1024 * 1024);
                  max-free = lib.mkForce (512 * 1024 * 1024);
                };
                # Keep bootstrap share read-only and non-executable in guest.
                fileSystems."/mnt/codex-bootstrap".options = lib.mkAfter [
                  "ro"
                  "nosuid"
                  "nodev"
                  "noexec"
                ];
                systemd.services.codex-bootstrap-auth = {
                  description = "Copy Codex auth from bootstrap share";
                  after = [ "local-fs.target" ];
                  wants = [ "local-fs.target" ];
                  before = [ "getty.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig.Type = "oneshot";
                  script = ''
                    if ${pkgs.util-linux}/bin/mountpoint -q /mnt/codex-bootstrap \
                      && [ -f /mnt/codex-bootstrap/auth.json ]; then
                      user_group="$(${pkgs.coreutils}/bin/id -gn ${username} 2>/dev/null || echo users)"
                      ${pkgs.coreutils}/bin/install -d -m 0700 ${homeDir}/.codex
                      ${pkgs.coreutils}/bin/install -m 0600 \
                        /mnt/codex-bootstrap/auth.json \
                        ${homeDir}/.codex/auth.json
                      ${pkgs.coreutils}/bin/chown ${username}:"$user_group" ${homeDir}/.codex ${homeDir}/.codex/auth.json
                      # Remove host-provided token copy as soon as it is consumed.
                      ${pkgs.coreutils}/bin/rm -f /mnt/codex-bootstrap/auth.json || true
                    fi
                    # Drop live host mount after bootstrap to reduce host interaction surface.
                    if ${pkgs.util-linux}/bin/mountpoint -q /mnt/codex-bootstrap; then
                      ${pkgs.util-linux}/bin/umount /mnt/codex-bootstrap || true
                    fi
                  '';
                };
              }
            )
          )
        ];
      };
      vmRunner = "${vmConfig.config.virtualisation.vmVariant.system.build.vm}/bin/run-${name}-vm";
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
          bootstrapCodexAuth = if isGeneric then "1" else "0";
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
