#!/usr/bin/env bash

cleanup_disk=1
ram_mb="@defaultRamMb@"
cpus="@defaultCpus@"
disk_size="@defaultDiskSize@"
disk_image="${NIX_DISK_IMAGE:-@defaultDiskImage@}"
override_ram=0
override_cpus=0
override_disk_size=0

if [ -n "${VM_KEEP_DISK:-}" ]; then
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
  --help | -h)
    cat <<'EOF'
Usage: nix run .#@vmName@-vm -- [OPTIONS] [-- RUNNER_ARGS...]

Options:
  --keep-disk        Keep disk image after VM exits
  --delete-disk      Remove disk image on VM exit (default)
  --ram-mb MB        RAM in MiB (default: @defaultRamMb@)
  --cpus N           Number of CPUs (default: @defaultCpus@)
  --disk-size SIZE   Disk size (e.g. 8G, 16384M; default: @defaultDiskSize@)
  --disk-image PATH  Disk image path (default: @defaultDiskImage@)

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
  export QEMU_OPTS="${QEMU_OPTS:+$QEMU_OPTS }-m $ram_mb"
fi
if [ "$override_cpus" -eq 1 ]; then
  export QEMU_OPTS="${QEMU_OPTS:+$QEMU_OPTS }-smp $cpus"
fi
if [ "$override_disk_size" -eq 1 ]; then
  if [ ! -e "$disk_image" ]; then
    tmp_raw="$(@mktemp@ -t @vmName@-disk.XXXXXX)"
    @qemuImg@ create -f raw "$tmp_raw" "$disk_size"
    @mkfsExt4@ -L nixos "$tmp_raw" >/dev/null
    @qemuImg@ convert -f raw -O qcow2 "$tmp_raw" "$disk_image"
    rm -f -- "$tmp_raw"
  else
    @qemuImg@ resize "$disk_image" "$disk_size" >/dev/null
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

"@vmRunner@" "$@"
