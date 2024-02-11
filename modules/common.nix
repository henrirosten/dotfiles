{
  pkgs,
  user,
  ...
}: {
  system.stateVersion = "23.11";
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  boot.blacklistedKernelModules = ["pcspkr"];
  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      substituters = [
        "https://ghaf-dev.cachix.org?priority=20"
        "https://cache.vedenemo.dev"
      ];
      trusted-public-keys = [
        "ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY="
        "cache.vedenemo.dev:8NhplARANhClUSWJyLVk4WMyy1Wb4rhmWW2u8AejH9E="
      ];
      experimental-features = ["nix-command" "flakes"];
    };
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
  };

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    nix-info
    vim
    wget
  ];
}
