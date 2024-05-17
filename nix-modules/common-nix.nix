{
  pkgs,
  user,
  ...
}: let
  asGB = size: toString (size * 1024 * 1024 * 1024);
in {
  system.stateVersion = "23.11";
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  boot.blacklistedKernelModules = ["pcspkr"];
  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [user.username];
      # Ref:
      # https://nixos.wiki/wiki/Storage_optimization#Automation
      # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-min-free
      #
      # When free disk space in /nix/store drops below min-free during build,
      # perform a garbage-collection until max-free bytes are available or there
      # is no more garbage.
      min-free = asGB 20;
      max-free = asGB 100;
      # check the free disk space every 5 seconds
      min-free-check-interval = 5;
    };
    # Garbage collection, see:
    # https://search.nixos.org/options?type=packages&query=nix.gc
    # gc.automatic = true;
    # gc.options = pkgs.lib.mkDefault "--delete-older-than 30d";
  };

  # Sometimes it fails if a store path is still in use.
  # This should fix intermediate issues.
  systemd.services.nix-gc.serviceConfig = {
    Restart = "on-failure";
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  security = {
    sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
        Defaults passwd_timeout=0
      '';
    };
    audit.enable = true;
    auditd.enable = true;
  };

  programs.zsh.enable = true;
  environment = {
    pathsToLink = ["/share/zsh"];
    shells = [pkgs.zsh];
  };
  programs.bash.enableCompletion = true;
  users = {
    defaultUserShell = pkgs.bash;
    users."${user.username}" = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"];
      initialPassword = "changemeonfirstlogin";
      home = "/home/${user.username}";
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = user.keys;
    };
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
    enableIPv6 = false;
  };

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    vim
    wget
  ];
}
