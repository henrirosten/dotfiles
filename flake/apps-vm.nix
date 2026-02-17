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
            lib.mkMerge [
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
                    forwardPorts = [
                      {
                        from = "host";
                        host.address = "127.0.0.1";
                        host.port = 2222;
                        guest.port = 22;
                      }
                    ];
                    qemu.consoles = lib.mkForce [ "ttyS0,115200n8" ];
                    qemu.options = lib.mkAfter ([
                      "-display none"
                      "-serial mon:stdio"
                      "-device virtio-balloon"
                      "-enable-kvm"
                      # Ask QEMU to self-restrict host-side capabilities.
                      "-sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny"
                    ]);
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
                            source = ''"''${CODEX_VM_BOOTSTRAP_DIR:-$TMPDIR/xchg}"'';
                            target = "/mnt/codex-bootstrap";
                            securityModel = "none";
                          };
                        }
                      else
                        { };
                  };
                };
                services.getty.autologinUser = lib.mkForce username;
                services.openssh.settings.X11Forwarding = lib.mkForce true;
                programs.ssh.setXAuthLocation = lib.mkForce true;
                # Keep VM boot logs deterministic for CI/smoke runs: auditd emits
                # spurious startup errors in these ephemeral QEMU guests and we do
                # not rely on kernel audit trails inside test VMs.
                security.audit.enable = lib.mkForce false;
                security.auditd.enable = lib.mkForce false;
                # Laptop-oriented throttling service can fail in QEMU guests and
                # cause degraded boot state; keep it disabled in VM variants.
                services.throttled.enable = lib.mkForce false;
                security.sudo.wheelNeedsPassword = lib.mkForce false;
                # Disable systemd-ssh-generator auto sockets to avoid AF_VSOCK probe errors in VM logs.
                boot.kernelParams = lib.mkAfter [ "systemd.ssh_auto=0" ];
                # VM-friendly free-space thresholds to avoid activation stalls
                # with tmpfs-backed writable store overlays.
                nix.settings = {
                  min-free = lib.mkForce (128 * 1024 * 1024);
                  max-free = lib.mkForce (512 * 1024 * 1024);
                };
                systemd.tmpfiles.rules = [
                  "d /mnt/host-share 0755 ${username} users -"
                ]
                ++ lib.optionals isGeneric [
                  "d /mnt/codex-bootstrap 0755 root root -"
                ];
                systemd.services.host-share-mount = {
                  description = "Mount optional host share at /mnt/host-share";
                  after = [ "local-fs.target" ];
                  wants = [ "local-fs.target" ];
                  before = [ "getty.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig.Type = "oneshot";
                  script = ''
                    if ${pkgs.util-linux}/bin/mountpoint -q /mnt/host-share; then
                      exit 0
                    fi

                    for tag in /sys/bus/virtio/drivers/9pnet_virtio/virtio*/mount_tag; do
                      if [ -r "$tag" ] && [ "$(${pkgs.coreutils}/bin/cat "$tag")" = "host-share" ]; then
                        ${pkgs.util-linux}/bin/mount -t 9p \
                          -o trans=virtio,version=9p2000.L,rw,msize=104857600,nosuid,nodev \
                          host-share /mnt/host-share
                        user_group="$(${pkgs.coreutils}/bin/id -gn ${username} 2>/dev/null || echo users)"
                        ${pkgs.coreutils}/bin/chown ${username}:"$user_group" /mnt/host-share || true
                        exit 0
                      fi
                    done
                  '';
                };
                environment.loginShellInit = lib.mkAfter ''
                  if [ "$USER" = "${username}" ] && [ -z "''${SSH_CONNECTION:-}" ]; then
                    tty_path="$(tty 2>/dev/null || true)"
                    case "$tty_path" in
                      /dev/tty1|/dev/ttyS0)
                        if ${pkgs.util-linux}/bin/mountpoint -q /mnt/host-share; then
                          cd /mnt/host-share || true
                        fi
                        ;;
                    esac
                  fi
                '';
              }
              (lib.optionalAttrs isGeneric {
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
              })
            ]
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
          defaultCleanupDisk = "1";
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
